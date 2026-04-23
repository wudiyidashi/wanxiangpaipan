import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wanxiang_paipan/ai/config/ai_config_manager.dart';
import 'package:wanxiang_paipan/ai/llm_provider.dart';
import 'package:wanxiang_paipan/ai/llm_provider_registry.dart';
import 'package:wanxiang_paipan/ai/output/formatters/xiaoliuren_formatter.dart';
import 'package:wanxiang_paipan/ai/output/structured_output_formatter.dart';
import 'package:wanxiang_paipan/ai/service/ai_analysis_service.dart';
import 'package:wanxiang_paipan/ai/service/prompt_assembler.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/models/xiaoliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/xiaoliuren_system.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/repositories/divination_repository.dart';
import 'package:wanxiang_paipan/presentation/widgets/ai_analysis_widget.dart';

import '../../unit/data/repositories/divination_repository_test.dart'
    show MockSecureStorage;

class _FakeRepository implements DivinationRepository {
  final Map<String, String> encryptedFields = {};

  @override
  Future<void> deleteEncryptedField(String key) async {
    encryptedFields.remove(key);
  }

  @override
  Future<void> deleteEncryptedFieldsBatch(List<String> keys) async {
    for (final key in keys) {
      encryptedFields.remove(key);
    }
  }

  @override
  Future<String?> readEncryptedField(String key) async => encryptedFields[key];

  @override
  Future<Map<String, String?>> readEncryptedFieldsBatch(
      List<String> keys) async {
    return {
      for (final key in keys) key: encryptedFields[key],
    };
  }

  @override
  Future<void> saveEncryptedField(String key, String value) async {
    encryptedFields[key] = value;
  }

  @override
  Future<void> saveEncryptedFieldsBatch(Map<String, String> fields) async {
    encryptedFields.addAll(fields);
  }

  @override
  Future<int> deleteAllRecords() => throw UnimplementedError();

  @override
  Future<int> deleteRecord(String id) => throw UnimplementedError();

  @override
  Future<int> deleteRecordsBeforeTime(DateTime beforeTime) =>
      throw UnimplementedError();

  @override
  Future<int> deleteRecordsBySystemType(DivinationType systemType) =>
      throw UnimplementedError();

  @override
  Future<List<DivinationResult>> getAllRecords() => throw UnimplementedError();

  @override
  Future<DivinationResult?> getLatestRecord() => throw UnimplementedError();

  @override
  Future<int> getRecordCount() => throw UnimplementedError();

  @override
  Future<int> getRecordCountBySystemType(DivinationType systemType) =>
      throw UnimplementedError();

  @override
  Future<DivinationResult?> getRecordById(String id) =>
      throw UnimplementedError();

  @override
  Future<List<DivinationResult>> getRecordsByCastMethod(
          CastMethod castMethod) =>
      throw UnimplementedError();

  @override
  Future<List<DivinationResult>> getRecordsBySystemType(
    DivinationType systemType,
  ) =>
      throw UnimplementedError();

  @override
  Future<List<DivinationResult>> getRecordsByTimeRange(
    DateTime startTime,
    DateTime endTime,
  ) =>
      throw UnimplementedError();

  @override
  Future<List<DivinationResult>> getRecordsPaginated({
    required int limit,
    required int offset,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<DivinationResult>> getRecentRecords(int limit) =>
      throw UnimplementedError();

  @override
  Future<bool> recordExists(String id) => throw UnimplementedError();

  @override
  Future<String> saveRecord(DivinationResult result) =>
      throw UnimplementedError();

  @override
  Future<List<DivinationResult>> searchRecords({
    DivinationType? systemType,
    CastMethod? castMethod,
    DateTime? startTime,
    DateTime? endTime,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> updateRecord(DivinationResult result) =>
      throw UnimplementedError();
}

class _FakeStreamingProvider implements LLMProvider {
  _FakeStreamingProvider(this.responsesByResultId);

  final Map<String, String> responsesByResultId;

  @override
  String get id => 'fake_provider';

  @override
  String get defaultModel => 'fake-model';

  @override
  String get description => 'fake';

  @override
  String get displayName => 'Fake Provider';

  @override
  bool get isConfigured => true;

  @override
  LLMProviderStatus get status => LLMProviderStatus.valid;

  @override
  List<String> get supportedModels => const ['fake-model'];

  @override
  Future<AnalysisResponse> analyze(AnalysisRequest request) async {
    final content = responsesByResultId[request.result.id] ?? '默认分析';
    return AnalysisResponse(
      content: content,
      tokensUsed: 0,
      latency: Duration.zero,
      model: defaultModel,
      providerId: id,
    );
  }

  @override
  Stream<String>? analyzeStream(AnalysisRequest request) {
    final content = responsesByResultId[request.result.id] ?? '默认分析';
    return Stream<String>.fromIterable([content]);
  }

  @override
  Future<ChatResponse> chat(ChatRequest request) async {
    throw UnimplementedError(
        '_FakeStreamingProvider only exercises streaming via analyzeStream');
  }

  @override
  Stream<String>? chatStream(ChatRequest request) {
    throw UnimplementedError(
        '_FakeStreamingProvider only exercises streaming via analyzeStream');
  }

  @override
  void clearConfig() {}

  @override
  Map<String, dynamic>? getConfigInfo() => {'model': defaultModel};

  @override
  void updateConfig(LLMConfig config) {}

  @override
  Future<bool> validateConfig() async => true;
}

void main() {
  group('AIAnalysisWidget', () {
    late AppDatabase database;
    late MockSecureStorage secureStorage;
    late AIConfigManager configManager;
    late LLMProviderRegistry providerRegistry;
    late AIAnalysisService analysisService;
    late _FakeRepository repository;
    late XiaoLiuRenResult resultA;
    late XiaoLiuRenResult resultB;

    setUp(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      secureStorage = MockSecureStorage();
      configManager = AIConfigManager(
        database: database,
        secureStorage: secureStorage,
      );
      await configManager.initializeBuiltInTemplates();

      StructuredOutputFormatterRegistry.instance.clear();
      StructuredOutputFormatterRegistry.instance.register(
        XiaoLiuRenStructuredFormatter(),
      );

      final system = XiaoLiuRenSystem();
      resultA = await system.cast(
        method: CastMethod.time,
        input: const {},
        castTime: DateTime(2026, 4, 19, 9, 22),
      ) as XiaoLiuRenResult;
      resultB = await system.cast(
        method: CastMethod.reportNumber,
        input: const {
          'firstNumber': 4,
          'secondNumber': 18,
          'thirdNumber': 7,
        },
        castTime: DateTime(2026, 4, 19, 9, 22),
      ) as XiaoLiuRenResult;

      providerRegistry = LLMProviderRegistry.instance;
      providerRegistry.clear();
      providerRegistry.register(
        _FakeStreamingProvider({
          resultA.id: '结果A分析内容',
          resultB.id: '结果B分析内容',
        }),
      );

      analysisService = AIAnalysisService(
        providerRegistry: providerRegistry,
        promptAssembler: PromptAssembler(
          configManager: configManager,
          formatterRegistry: StructuredOutputFormatterRegistry.instance,
        ),
        configManager: configManager,
      );

      repository = _FakeRepository();
      await repository.saveEncryptedField(
          'interpretation_${resultB.id}', '历史B分析');
    });

    tearDown(() async {
      analysisService.dispose();
      providerRegistry.clear();
      StructuredOutputFormatterRegistry.instance.clear();
      await database.close();
    });

    testWidgets('切换排盘记录时应显示各自 AI 内容，并保存当前分析结果', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          analysisService: analysisService,
          repository: repository,
          result: resultA,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('结果A分析内容'), findsNothing);
      expect(find.text('历史B分析'), findsNothing);

      await tester.tap(find.byTooltip('开始分析'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('结果A分析内容'), findsOneWidget);
      expect(
        repository.encryptedFields['interpretation_${resultA.id}'],
        '结果A分析内容',
      );

      await tester.pumpWidget(
        _buildApp(
          analysisService: analysisService,
          repository: repository,
          result: resultB,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('历史B分析'), findsOneWidget);
      expect(find.text('结果A分析内容'), findsNothing);

      await tester.pumpWidget(
        _buildApp(
          analysisService: analysisService,
          repository: repository,
          result: resultA,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('结果A分析内容'), findsOneWidget);
      expect(find.text('历史B分析'), findsNothing);
    });
  });
}

Widget _buildApp({
  required AIAnalysisService analysisService,
  required DivinationRepository repository,
  required DivinationResult result,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AIAnalysisService>.value(value: analysisService),
      Provider<DivinationRepository>.value(value: repository),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: AIAnalysisWidget(result: result),
      ),
    ),
  );
}
