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
import 'chat_request_builder.dart';
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

  // ==================== sendFollowUp ====================

  Future<void> sendFollowUp(
    String resultId,
    String userText, {
    DivinationResult? fallbackResult,
  }) async {
    final existing = _cache[resultId];
    if (existing == null) {
      _errors[resultId] = '对话不存在';
      notifyListeners();
      return;
    }

    await _cancelStream(resultId);
    _errors.remove(resultId);

    // 若 legacy 状态：重新组装 castSnapshot
    var conv = existing;
    if (conv.castSnapshot == null) {
      if (fallbackResult == null) {
        _errors[resultId] =
            '对话缺少 castSnapshot，需要 fallbackResult 重新组装';
        notifyListeners();
        return;
      }
      try {
        final prompt = await _promptAssembler.assemble(fallbackResult);
        final modelName =
            (_providerRegistry.getAvailableProvider()?.getConfigInfo()?['model']
                    as String?) ??
                '';
        conv = conv.copyWith(
          castSnapshot: CastSnapshot(
            systemPrompt: prompt.systemPrompt,
            castUserPrompt: prompt.userPrompt,
            model: modelName,
            assembledAt: DateTime.now(),
          ),
        );
      } catch (e) {
        _errors[resultId] = '组装 prompt 失败: $e';
        notifyListeners();
        return;
      }
    }

    final provider = _providerRegistry.getAvailableProvider();
    if (provider == null || !provider.isConfigured) {
      _errors[resultId] = '没有可用的 AI 服务';
      notifyListeners();
      return;
    }

    // 追加 user 消息 (sending)
    final userMsg = AIChatMessage(
      id: _newId(),
      role: ChatRole.user,
      content: userText,
      timestamp: DateTime.now(),
      status: ChatMessageStatus.sending,
    );
    // 追加 assistant 占位 (streaming)
    final assistantMsg = AIChatMessage(
      id: _newId(),
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      status: ChatMessageStatus.streaming,
    );
    conv = conv.copyWith(
      messages: [...conv.messages, userMsg, assistantMsg],
      updatedAt: DateTime.now(),
    );
    _cache[resultId] = conv;
    notifyListeners();

    // 组装 messages 发请求
    final chatMessages = ChatRequestBuilder.build(conv);
    final stream = provider.chatStream(ChatRequest(messages: chatMessages));

    if (stream == null) {
      try {
        final resp =
            await provider.chat(ChatRequest(messages: chatMessages));
        conv = _updateMessage(conv, userMsg.id,
            status: ChatMessageStatus.sent);
        conv = _updateMessage(conv, assistantMsg.id,
            content: resp.content, status: ChatMessageStatus.sent);
        _cache[resultId] = conv;
        await _chatRepository.save(conv);
        _safeNotify();
      } catch (e) {
        conv = _updateMessage(conv, userMsg.id,
            status: ChatMessageStatus.failed, errorMessage: e.toString());
        conv = _updateMessage(conv, assistantMsg.id,
            status: ChatMessageStatus.failed, errorMessage: e.toString());
        _cache[resultId] = conv;
        _errors[resultId] = e.toString();
        await _chatRepository.save(conv);
        _safeNotify();
      }
      return;
    }

    final completer = Completer<void>();
    final buffer = StringBuffer();

    _activeStreams[resultId] = stream.listen(
      (chunk) {
        buffer.write(chunk);
        conv = _updateMessage(conv, userMsg.id,
            status: ChatMessageStatus.sent);
        conv = _updateMessage(conv, assistantMsg.id,
            content: buffer.toString(),
            status: ChatMessageStatus.streaming);
        _cache[resultId] = conv;
        _safeNotify();
      },
      onDone: () async {
        conv = _updateMessage(conv, userMsg.id,
            status: ChatMessageStatus.sent);
        conv = _updateMessage(conv, assistantMsg.id,
            content: buffer.toString(), status: ChatMessageStatus.sent);
        _cache[resultId] = conv;
        _activeStreams.remove(resultId);
        await _chatRepository.save(conv);
        _safeNotify();
        if (!completer.isCompleted) completer.complete();
      },
      onError: (Object err) async {
        conv = _updateMessage(conv, userMsg.id,
            status: ChatMessageStatus.failed, errorMessage: err.toString());
        conv = _updateMessage(conv, assistantMsg.id,
            content: buffer.toString(),
            status: ChatMessageStatus.failed,
            errorMessage: err.toString());
        _cache[resultId] = conv;
        _errors[resultId] = err.toString();
        _activeStreams.remove(resultId);
        await _chatRepository.save(conv);
        _safeNotify();
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  // ==================== reset / delete / stop / retry ====================

  Future<void> reset(String resultId) async {
    await _cancelStream(resultId);
    final conv = _cache[resultId];
    if (conv == null || conv.messages.isEmpty) return;
    final kept = conv.messages.first;
    final updated = conv.copyWith(
      messages: [kept],
      updatedAt: DateTime.now(),
    );
    _cache[resultId] = updated;
    _errors.remove(resultId);
    await _chatRepository.save(updated);
    notifyListeners();
  }

  Future<void> delete(String resultId) async {
    await _cancelStream(resultId);
    _cache.remove(resultId);
    _errors.remove(resultId);
    await _chatRepository.delete(resultId);
    notifyListeners();
  }

  Future<void> stop(String resultId) async {
    await _cancelStream(resultId);
    final conv = _cache[resultId];
    if (conv == null) return;
    // 把 streaming/sending 的消息冻结为 sent（保留已到达内容）
    final updated = conv.messages.map((m) {
      if (m.status == ChatMessageStatus.streaming ||
          m.status == ChatMessageStatus.sending) {
        return m.copyWith(status: ChatMessageStatus.sent);
      }
      return m;
    }).toList();
    final newConv =
        conv.copyWith(messages: updated, updatedAt: DateTime.now());
    _cache[resultId] = newConv;
    await _chatRepository.save(newConv);
    notifyListeners();
  }

  Future<void> retry(
    String resultId,
    String failedUserMessageId, {
    DivinationResult? fallbackResult,
  }) async {
    final conv = _cache[resultId];
    if (conv == null) return;
    final idx = conv.messages.indexWhere((m) => m.id == failedUserMessageId);
    if (idx < 0) return;
    if (conv.messages[idx].role != ChatRole.user) return;
    final originalText = conv.messages[idx].content;

    // 截断到失败消息之前
    final truncated = conv.messages.sublist(0, idx);
    final reset = conv.copyWith(
      messages: truncated,
      updatedAt: DateTime.now(),
    );
    _cache[resultId] = reset;
    _errors.remove(resultId);
    notifyListeners();

    await sendFollowUp(resultId, originalText,
        fallbackResult: fallbackResult);
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
