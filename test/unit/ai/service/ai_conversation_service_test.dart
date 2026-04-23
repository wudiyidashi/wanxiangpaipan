import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wanxiang_paipan/ai/config/ai_config_manager.dart';
import 'package:wanxiang_paipan/ai/llm_provider.dart';
import 'package:wanxiang_paipan/ai/llm_provider_registry.dart';
import 'package:wanxiang_paipan/ai/model/ai_chat_message.dart';
import 'package:wanxiang_paipan/ai/output/structured_output.dart';
import 'package:wanxiang_paipan/ai/service/ai_conversation_service.dart';
import 'package:wanxiang_paipan/ai/service/chat_repository.dart';
import 'package:wanxiang_paipan/ai/service/prompt_assembler.dart';
import 'package:wanxiang_paipan/data/secure/secure_storage.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

class _MockProvider extends Mock implements LLMProvider {}
class _MockRegistry extends Mock implements LLMProviderRegistry {}
class _MockAssembler extends Mock implements PromptAssembler {}
class _MockConfig extends Mock implements AIConfigManager {}

class _MockSecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};
  @override
  Future<bool> containsKey(String key) async => _storage.containsKey(key);
  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }
  @override
  Future<void> deleteAll() async => _storage.clear();
  @override
  Future<String?> read(String key) async => _storage[key];
  @override
  Future<Map<String, String>> readMultiple(List<String> keys) async {
    final result = <String, String>{};
    for (final k in keys) {
      final v = _storage[k];
      if (v != null) result[k] = v;
    }
    return result;
  }
  @override
  Future<Map<String, String>> readAll() async => Map.unmodifiable(_storage);
  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }
}

class _FakeResult implements DivinationResult {
  @override
  final String id;
  _FakeResult(this.id);
  @override
  DivinationType get systemType => DivinationType.liuYao;
  @override
  DateTime get castTime => DateTime.utc(2026, 4, 23);
  @override
  CastMethod get castMethod => CastMethod.coin;
  @override
  LunarInfo get lunarInfo => const LunarInfo(
        yueJian: '辰',
        riGan: '甲',
        riZhi: '子',
        riGanZhi: '甲子',
        kongWang: ['戌', '亥'],
        yearGanZhi: '丙午',
        monthGanZhi: '壬辰',
      );
  @override
  String getSummary() => '测试摘要';
  @override
  Map<String, dynamic> toJson() => {};
}

AssembledPrompt _fakePrompt({
  String systemPrompt = 'SYS',
  String userPrompt = 'CAST',
}) {
  return AssembledPrompt(
    systemPrompt: systemPrompt,
    userPrompt: userPrompt,
    structuredOutput: StructuredDivinationOutput(
      systemType: 'liuyao',
      temporal: TemporalInfo(
        solarTime: DateTime.utc(2026, 4, 23),
        yearGanZhi: '丙午',
        monthGanZhi: '壬辰',
        dayGanZhi: '甲子',
        kongWang: const ['戌', '亥'],
      ),
      coreData: const {},
      sections: const [],
    ),
    metadata: AssembledPromptMetadata(
      timestamp: DateTime.utc(2026, 4, 23),
      systemType: 'liuyao',
    ),
  );
}

AIConversationService _makeService({
  required LLMProvider provider,
  required ChatRepository repo,
  required PromptAssembler assembler,
  required AIConfigManager config,
}) {
  final registry = _MockRegistry();
  when(() => registry.getAvailableProvider()).thenReturn(provider);
  when(() => registry.getProvider(any())).thenReturn(provider);
  when(() => registry.hasConfiguredProvider).thenReturn(true);
  return AIConversationService(
    providerRegistry: registry,
    promptAssembler: assembler,
    configManager: config,
    chatRepository: repo,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ChatRequest(messages: []));
    registerFallbackValue(_FakeResult('x'));
    registerFallbackValue(AnalysisType.comprehensive);
  });

  group('AIConversationService.startConversation', () {
    late _MockProvider provider;
    late _MockAssembler assembler;
    late _MockConfig config;
    late ChatRepository repo;
    late _MockSecureStorage storage;

    setUp(() {
      provider = _MockProvider();
      assembler = _MockAssembler();
      config = _MockConfig();
      storage = _MockSecureStorage();
      repo = ChatRepository(secureStorage: storage);

      when(() => provider.id).thenReturn('openai_compatible');
      when(() => provider.isConfigured).thenReturn(true);
      when(() => provider.getConfigInfo()).thenReturn({'model': 'gpt-4'});
      when(() => assembler.assemble(
            any(),
            question: any(named: 'question'),
            analysisType: any(named: 'analysisType'),
            customVariables: any(named: 'customVariables'),
          )).thenAnswer((_) async => _fakePrompt());
    });

    test('流式成功：messages[0].content 累加每个 chunk，结束后 status=sent', () async {
      when(() => provider.chatStream(any())).thenAnswer(
        (_) => Stream.fromIterable(['Hel', 'lo', ' 卦象']),
      );

      final service = _makeService(
        provider: provider,
        repo: repo,
        assembler: assembler,
        config: config,
      );

      final result = _FakeResult('r1');
      await service.startConversation(result);

      final conv = service.conversationOf('r1');
      expect(conv, isNotNull);
      expect(conv!.messages, hasLength(1));
      expect(conv.messages[0].role, ChatRole.assistant);
      expect(conv.messages[0].content, 'Hello 卦象');
      expect(conv.messages[0].status, ChatMessageStatus.sent);
      expect(conv.castSnapshot, isNotNull);
      expect(conv.castSnapshot!.systemPrompt, 'SYS');
      expect(conv.castSnapshot!.castUserPrompt, 'CAST');
    });

    test('provider 抛异常：status=failed + error 信息', () async {
      when(() => provider.chatStream(any())).thenAnswer(
        (_) => Stream.error(Exception('API down')),
      );

      final service = _makeService(
        provider: provider,
        repo: repo,
        assembler: assembler,
        config: config,
      );

      final result = _FakeResult('r2');
      await service.startConversation(result);

      final conv = service.conversationOf('r2');
      expect(conv!.messages[0].status, ChatMessageStatus.failed);
      expect(service.errorOf('r2'), contains('API down'));
    });

    test('未配置 provider：抛错误状态', () async {
      when(() => provider.isConfigured).thenReturn(false);

      final service = _makeService(
        provider: provider,
        repo: repo,
        assembler: assembler,
        config: config,
      );

      await service.startConversation(_FakeResult('r3'));
      expect(service.errorOf('r3'), isNotNull);
    });
  });

  group('AIConversationService.sendFollowUp', () {
    late _MockProvider provider;
    late _MockAssembler assembler;
    late _MockConfig config;
    late ChatRepository repo;
    late _MockSecureStorage storage;

    setUp(() {
      provider = _MockProvider();
      assembler = _MockAssembler();
      config = _MockConfig();
      storage = _MockSecureStorage();
      repo = ChatRepository(secureStorage: storage);
      when(() => provider.id).thenReturn('openai_compatible');
      when(() => provider.isConfigured).thenReturn(true);
      when(() => provider.getConfigInfo()).thenReturn({'model': 'gpt-4'});
      when(() => assembler.assemble(any(),
              question: any(named: 'question'),
              analysisType: any(named: 'analysisType'),
              customVariables: any(named: 'customVariables')))
          .thenAnswer((_) async => _fakePrompt());
    });

    Future<AIConversationService> _startService() async {
      when(() => provider.chatStream(any())).thenAnswer(
        (_) => Stream.fromIterable(['初始分析']),
      );
      final service = _makeService(
        provider: provider,
        repo: repo,
        assembler: assembler,
        config: config,
      );
      await service.startConversation(_FakeResult('r1'));
      return service;
    }

    test('正常追问：追加 user + assistant，流式内容累加', () async {
      final service = await _startService();
      when(() => provider.chatStream(any())).thenAnswer(
        (_) => Stream.fromIterable(['回', '复']),
      );

      await service.sendFollowUp('r1', '为什么？');

      final conv = service.conversationOf('r1');
      expect(conv!.messages, hasLength(3));
      expect(conv.messages[1].role, ChatRole.user);
      expect(conv.messages[1].content, '为什么？');
      expect(conv.messages[1].status, ChatMessageStatus.sent);
      expect(conv.messages[2].role, ChatRole.assistant);
      expect(conv.messages[2].content, '回复');
      expect(conv.messages[2].status, ChatMessageStatus.sent);
    });

    test('流式失败：user 和 assistant 都标记 failed', () async {
      final service = await _startService();
      when(() => provider.chatStream(any())).thenAnswer(
        (_) => Stream.error(Exception('boom')),
      );

      await service.sendFollowUp('r1', '追问');

      final conv = service.conversationOf('r1');
      expect(conv!.messages[1].status, ChatMessageStatus.failed);
      expect(conv.messages[2].status, ChatMessageStatus.failed);
      expect(service.errorOf('r1'), contains('boom'));
    });

    test('castSnapshot 为 null 时（legacy 恢复）先重新组装再发请求', () async {
      // 直接注入 legacy 状态
      storage = _MockSecureStorage();
      await storage.write('interpretation_r1', 'legacy 初始分析');
      repo = ChatRepository(secureStorage: storage);
      final service = _makeService(
        provider: provider,
        repo: repo,
        assembler: assembler,
        config: config,
      );
      await service.loadIfNeeded('r1',
          legacySystemType: DivinationType.liuYao);
      // 此时 castSnapshot 为 null

      // 模拟 follow-up
      when(() => provider.chatStream(any()))
          .thenAnswer((_) => Stream.fromIterable(['ok']));

      // sendFollowUp 需要 DivinationResult 以便组装 prompt
      await service.sendFollowUp('r1', '再问',
          fallbackResult: _FakeResult('r1'));

      final conv = service.conversationOf('r1');
      expect(conv!.castSnapshot, isNotNull);
      expect(conv.messages, hasLength(3));
    });
  });
}
