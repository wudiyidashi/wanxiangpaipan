import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:uuid/uuid.dart';

import '../config/ai_config_manager.dart';
import '../llm_provider.dart';
import '../llm_provider_registry.dart';
import '../model/ai_chat_message.dart';
import '../model/ai_conversation.dart';
import '../model/cast_snapshot.dart';
import 'chat_repository.dart';
import 'prompt_assembler.dart';
import '../../domain/divination_system.dart';

/// 管理所有排盘记录对应的 AI 对话状态
class AIConversationService extends ChangeNotifier {
  final LLMProviderRegistry _providerRegistry;
  final PromptAssembler _promptAssembler;
  // ignore: unused_field  // 保留用于未来非流式回退判断
  final AIConfigManager _configManager;
  final ChatRepository _chatRepository;

  final Map<String, AIConversation> _cache = {};
  final Map<String, String?> _errors = {};
  final Map<String, StreamSubscription<String>> _activeStreams = {};

  static const _uuid = Uuid();

  AIConversationService({
    required LLMProviderRegistry providerRegistry,
    required PromptAssembler promptAssembler,
    required AIConfigManager configManager,
    required ChatRepository chatRepository,
  })  : _providerRegistry = providerRegistry,
        _promptAssembler = promptAssembler,
        _configManager = configManager,
        _chatRepository = chatRepository;

  // ==================== 访问器 ====================

  AIConversation? conversationOf(String resultId) => _cache[resultId];
  String? errorOf(String resultId) => _errors[resultId];
  bool isStreaming(String resultId) {
    final conv = _cache[resultId];
    if (conv == null) return false;
    return conv.messages.any((m) =>
        m.status == ChatMessageStatus.streaming ||
        m.status == ChatMessageStatus.sending);
  }

  /// 从存储加载（若内存已有则直接返回缓存）
  Future<AIConversation?> loadIfNeeded(
    String resultId, {
    DivinationType? legacySystemType,
  }) async {
    if (_cache.containsKey(resultId)) return _cache[resultId];
    final loaded = await _chatRepository.load(
      resultId,
      legacySystemType: legacySystemType,
    );
    if (loaded != null) {
      _cache[resultId] = loaded;
      notifyListeners();
    }
    return loaded;
  }

  // ==================== startConversation ====================

  Future<void> startConversation(
    DivinationResult result, {
    String? question,
  }) async {
    await _cancelStream(result.id);
    _errors.remove(result.id);

    final provider = _providerRegistry.getAvailableProvider();
    if (provider == null || !provider.isConfigured) {
      _errors[result.id] = '没有可用的 AI 服务，请先配置 API';
      notifyListeners();
      return;
    }

    // 组装初始 prompt
    late final AssembledPrompt prompt;
    try {
      prompt = await _promptAssembler.assemble(result, question: question);
    } catch (e) {
      _errors[result.id] = '组装 prompt 失败: $e';
      notifyListeners();
      return;
    }

    final modelName = (provider.getConfigInfo()?['model'] as String?) ?? '';
    final snapshot = CastSnapshot(
      systemPrompt: prompt.systemPrompt,
      castUserPrompt: prompt.userPrompt,
      model: modelName,
      assembledAt: DateTime.now(),
    );

    // 初始化 assistant 占位消息
    final placeholder = AIChatMessage(
      id: _newId(),
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      status: ChatMessageStatus.streaming,
    );

    var conv = AIConversation(
      version: 1,
      resultId: result.id,
      systemType: result.systemType,
      castSnapshot: snapshot,
      messages: [placeholder],
      updatedAt: DateTime.now(),
    );
    _cache[result.id] = conv;
    notifyListeners();

    // 发起请求
    final stream = provider.chatStream(ChatRequest(
      messages: [
        ProviderChatMessage.system(snapshot.systemPrompt),
        ProviderChatMessage.user(snapshot.castUserPrompt),
      ],
    ));

    if (stream == null) {
      try {
        final resp = await provider.chat(ChatRequest(
          messages: [
            ProviderChatMessage.system(snapshot.systemPrompt),
            ProviderChatMessage.user(snapshot.castUserPrompt),
          ],
        ));
        conv = _updateMessage(conv, placeholder.id,
            content: resp.content, status: ChatMessageStatus.sent);
        _cache[result.id] = conv;
        await _chatRepository.save(conv);
        _safeNotify();
      } catch (e) {
        conv = _updateMessage(conv, placeholder.id,
            status: ChatMessageStatus.failed,
            errorMessage: e.toString());
        _cache[result.id] = conv;
        _errors[result.id] = e.toString();
        await _chatRepository.save(conv);
        _safeNotify();
      }
      return;
    }

    final completer = Completer<void>();
    final buffer = StringBuffer();

    _activeStreams[result.id] = stream.listen(
      (chunk) {
        buffer.write(chunk);
        conv = _updateMessage(conv, placeholder.id,
            content: buffer.toString(),
            status: ChatMessageStatus.streaming);
        _cache[result.id] = conv;
        _safeNotify();
      },
      onDone: () async {
        conv = _updateMessage(conv, placeholder.id,
            content: buffer.toString(), status: ChatMessageStatus.sent);
        _cache[result.id] = conv;
        _activeStreams.remove(result.id);
        await _chatRepository.save(conv);
        _safeNotify();
        if (!completer.isCompleted) completer.complete();
      },
      onError: (Object err) async {
        conv = _updateMessage(conv, placeholder.id,
            content: buffer.toString(),
            status: ChatMessageStatus.failed,
            errorMessage: err.toString());
        _cache[result.id] = conv;
        _errors[result.id] = err.toString();
        _activeStreams.remove(result.id);
        await _chatRepository.save(conv);
        _safeNotify();
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  // ==================== 辅助 ====================

  AIConversation _updateMessage(
    AIConversation conv,
    String messageId, {
    String? content,
    ChatMessageStatus? status,
    String? errorMessage,
  }) {
    final updated = conv.messages.map((m) {
      if (m.id != messageId) return m;
      return m.copyWith(
        content: content ?? m.content,
        status: status ?? m.status,
        errorMessage: errorMessage ?? m.errorMessage,
      );
    }).toList();
    return conv.copyWith(messages: updated, updatedAt: DateTime.now());
  }

  Future<void> _cancelStream(String resultId) async {
    final sub = _activeStreams.remove(resultId);
    if (sub != null) {
      await sub.cancel();
    }
  }

  String _newId() => _uuid.v4();

  void _safeNotify() {
    // SchedulerBinding may not be initialized in unit tests
    try {
      final phase = SchedulerBinding.instance.schedulerPhase;
      if (phase == SchedulerPhase.persistentCallbacks ||
          phase == SchedulerPhase.midFrameMicrotasks) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return;
      }
    } catch (_) {
      // Not in a Flutter binding context (e.g., unit tests); fall through
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _activeStreams.values) {
      sub.cancel();
    }
    _activeStreams.clear();
    super.dispose();
  }
}
