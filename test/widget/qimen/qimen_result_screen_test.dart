import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wanxiang_paipan/ai/config/ai_config_manager.dart';
import 'package:wanxiang_paipan/ai/llm_provider.dart';
import 'package:wanxiang_paipan/ai/llm_provider_registry.dart';
import 'package:wanxiang_paipan/ai/output/formatters/qimen_formatter.dart';
import 'package:wanxiang_paipan/ai/output/structured_output_formatter.dart';
import 'package:wanxiang_paipan/ai/service/ai_analysis_service.dart';
import 'package:wanxiang_paipan/ai/service/ai_conversation_service.dart';
import 'package:wanxiang_paipan/ai/service/chat_repository.dart';
import 'package:wanxiang_paipan/ai/service/prompt_assembler.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/ui/qimen_analysis_presentation.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/ui/qimen_result_screen.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/ui/qimen_result_sections.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/ui/widgets/qimen_nine_palace_grid.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_projection.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_analyzer.dart';
import 'package:wanxiang_paipan/presentation/widgets/ai_analysis_widget.dart';

import '../../unit/services/qimen/analysis/helpers/qimen_analysis_fixtures.dart';
import '../../unit/data/repositories/divination_repository_test.dart'
    show MockSecureStorage;

class _FakeQimenProvider implements LLMProvider {
  _FakeQimenProvider(this.content);

  final String content;
  int requestCount = 0;
  ChatRequest? lastRequest;

  @override
  String get id => 'fake-qimen-provider';
  @override
  String get displayName => '奇门测试服务';
  @override
  String get description => '奇门集成测试';
  @override
  List<String> get supportedModels => const <String>['fake-model'];
  @override
  String get defaultModel => 'fake-model';
  @override
  bool get isConfigured => true;
  @override
  LLMProviderStatus get status => LLMProviderStatus.valid;

  @override
  Future<AnalysisResponse> analyze(AnalysisRequest request) async =>
      AnalysisResponse(
        content: content,
        tokensUsed: 0,
        latency: Duration.zero,
        model: defaultModel,
        providerId: id,
      );

  @override
  Stream<String>? analyzeStream(AnalysisRequest request) =>
      Stream<String>.value(content);

  @override
  Future<ChatResponse> chat(ChatRequest request) async {
    requestCount++;
    lastRequest = request;
    return ChatResponse(
      content: content,
      tokensUsed: 0,
      latency: Duration.zero,
      model: defaultModel,
      providerId: id,
    );
  }

  @override
  Stream<String>? chatStream(ChatRequest request) {
    requestCount++;
    lastRequest = request;
    return Stream<String>.value(content);
  }

  @override
  void clearConfig() {}
  @override
  Map<String, dynamic>? getConfigInfo() => <String, dynamic>{
        'model': defaultModel,
      };
  @override
  void updateConfig(LLMConfig config) {}
  @override
  Future<bool> validateConfig() async => true;
}

void main() {
  final result = fixedQimenAnalysisResult();

  Future<void> pumpResult(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: QimenResultScreen(result: result),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpPalaces(
    WidgetTester tester, {
    Size size = const Size(390, 760),
    double textScale = 1,
    QimenResult? palaceResult,
  }) async {
    final renderedResult = palaceResult ?? result;
    final renderedReport = QimenAnalyzer.analyze(renderedResult);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: QimenPalaceSection(
              result: renderedResult,
              report: renderedReport,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('assembles product sections in the frozen order', (tester) async {
    await pumpResult(tester, size: const Size(390, 844));

    final sectionTypes = find
        .byWidgetPredicate(
          (widget) =>
              widget is QimenBasisSection ||
              widget is QimenDutySection ||
              widget is QimenPalaceSection ||
              widget is QimenMarkersSection ||
              widget is QimenVerdictSection ||
              widget is QimenFactsSection ||
              widget is QimenTimingSection,
        )
        .evaluate()
        .map((element) => element.widget.runtimeType)
        .toList(growable: false);

    expect(
      sectionTypes,
      <Type>[
        QimenBasisSection,
        QimenDutySection,
        QimenPalaceSection,
        QimenMarkersSection,
        QimenVerdictSection,
        QimenFactsSection,
        QimenTimingSection,
      ],
    );
    expect(
      tester
          .widget<AIAnalysisWidget>(find.byType(AIAnalysisWidget))
          .unavailableReason,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the complete result without overflow at target sizes',
      (tester) async {
    const cases = <({Size size, double scale})>[
      (size: Size(320, 740), scale: 1),
      (size: Size(390, 844), scale: 1),
      (size: Size(600, 900), scale: 1),
      (size: Size(900, 500), scale: 1),
      (size: Size(390, 844), scale: 2.1),
    ];

    for (final testCase in cases) {
      await pumpResult(
        tester,
        size: testCase.size,
        textScale: testCase.scale,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'overflow at ${testCase.size} scale ${testCase.scale}',
      );
    }
  });

  testWidgets('uses the fixed Luo Shu order independently of input order',
      (tester) async {
    final reversedJson = result.toJson();
    reversedJson['palaces'] =
        (reversedJson['palaces'] as List).reversed.toList(growable: false);
    final reversedResult = QimenResult.fromJson(reversedJson);
    expect(
      reversedResult.palaces.map((palace) => palace.number),
      <int>[9, 8, 7, 6, 5, 4, 3, 2, 1],
    );

    await pumpPalaces(
      tester,
      size: const Size(600, 900),
      palaceResult: reversedResult,
    );

    const order = QimenNinePalaceGrid.palaceOrder;
    final positions = <int, Offset>{
      for (final number in order)
        number: tester.getTopLeft(find.byKey(ValueKey('qimen-palace-$number'))),
    };

    for (final row in const <List<int>>[
      <int>[4, 9, 2],
      <int>[3, 5, 7],
      <int>[8, 1, 6],
    ]) {
      expect(positions[row[0]]!.dy, closeTo(positions[row[1]]!.dy, 0.1));
      expect(positions[row[1]]!.dy, closeTo(positions[row[2]]!.dy, 0.1));
      expect(positions[row[0]]!.dx, lessThan(positions[row[1]]!.dx));
      expect(positions[row[1]]!.dx, lessThan(positions[row[2]]!.dx));
    }
    expect(positions[4]!.dy, lessThan(positions[3]!.dy));
    expect(positions[3]!.dy, lessThan(positions[8]!.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens complete details for every palace', (tester) async {
    await pumpPalaces(tester);

    for (final palace in result.palaces) {
      final cell = find.byKey(ValueKey('qimen-palace-${palace.number}'));
      await tester.ensureVisible(cell);
      await tester.tap(cell);
      await tester.pumpAndSettle();

      expect(find.text('盘面事实'), findsOneWidget);
      expect(find.text('${palace.name} · ${palace.direction}'), findsOneWidget);
      expect(find.text('寄宫事实'), findsOneWidget);
      expect(find.text('专业标记'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('命中规则与来源'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('命中规则与来源'), findsOneWidget);
      expect(find.textContaining('QMV1-'), findsNothing);
      expect(find.textContaining('QMS-'), findsNothing);
      if (palace.number == 4) {
        expect(find.textContaining('求测者 · 戊 · 主焦点'), findsOneWidget);
      }

      await tester.tap(find.byTooltip('关闭宫位详情'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows controlled compatibility diagnostics', (tester) async {
    final futurePan = fixedQimenAnalysisPanMap()..['schemaVersion'] = 2;
    final diagnosticReport = QimenAnalyzer.analyzePersisted(futurePan);
    final projection = QimenAnalysisProjection.fromReport(diagnosticReport);
    expect(
      projection.status,
      QimenAnalysisStatus.unsupportedPanSchema,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QimenVerdictSection(projection: projection),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('趋势不明'), findsOneWidget);
    expect(find.text('分析兼容诊断'), findsOneWidget);
    expect(find.textContaining('排盘版本暂不支持'), findsOneWidget);
    expect(find.textContaining('QMV1-E-UNSUPPORTED-PAN-SCHEMA'), findsNothing);
    await tester.tap(find.text('技术详情'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('QMV1-E-UNSUPPORTED-PAN-SCHEMA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compatibility diagnostics disable AI on the full result page',
      (tester) async {
    final invalidPan = fixedQimenAnalysisPanMap()..['id'] = '';
    final invalidResult = QimenResult.fromJson(invalidPan);
    expect(
      QimenAnalyzer.analyze(invalidResult).status,
      QimenAnalysisStatus.invalidPanFacts,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QimenResultScreen(result: invalidResult),
      ),
    );
    await tester.pumpAndSettle();

    final aiWidget =
        tester.widget<AIAnalysisWidget>(find.byType(AIAnalysisWidget));
    expect(aiWidget.unavailableReason, contains('排盘记录缺少有效标识'));
    expect(aiWidget.unavailableReason, isNot(contains('QMV1-E-')));
    expect(find.textContaining('AI 分析已暂停'), findsOneWidget);
    expect(find.byTooltip('开始分析'), findsNothing);
    expect(find.text('重新分析'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('current v2 resolves Jia-day focus and enables AI',
      (tester) async {
    final unresolved = mutatedQimenAnalysisResult((json) {
      final context = Map<String, dynamic>.from(
        json['temporalContext'] as Map,
      )..['dayGanZhi'] = '甲子';
      json['temporalContext'] = context;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: QimenResultScreen(result: unresolved),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('分析兼容诊断'), findsNothing);
    expect(find.textContaining('求测者 · 戊落4宫'), findsOneWidget);
    expect(find.text('洛书九宫'), findsOneWidget);
    expect(
      tester
          .widget<AIAnalysisWidget>(find.byType(AIAnalysisWidget))
          .unavailableReason,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicit v1 keeps Jia-day compatibility gate', (tester) async {
    final unresolved = mutatedQimenAnalysisResult((json) {
      final context = Map<String, dynamic>.from(
        json['temporalContext'] as Map,
      )..['dayGanZhi'] = '甲子';
      json['temporalContext'] = context;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: QimenResultScreen(
          result: unresolved,
          ruleSetVersion: 'v1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('分析兼容诊断'), findsOneWidget);
    expect(find.textContaining('日干焦点无法定位'), findsWidgets);
    expect(
      tester
          .widget<AIAnalysisWidget>(find.byType(AIAnalysisWidget))
          .unavailableReason,
      isNotNull,
    );
    expect(find.byTooltip('开始分析'), findsNothing);
  });

  testWidgets('Jia-day v2 invokes configured AI and renders its response',
      (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final configManager = AIConfigManager(
      database: database,
      secureStorage: MockSecureStorage(),
    );
    await configManager.initializeBuiltInTemplates();
    final formatterRegistry = StructuredOutputFormatterRegistry.instance;
    final previousFormatters = <StructuredOutputFormatter>[
      for (final type in formatterRegistry.registeredTypes)
        formatterRegistry.getFormatter(type),
    ];
    formatterRegistry
      ..clear()
      ..register(QimenStructuredFormatter());
    final providerRegistry = LLMProviderRegistry.instance;
    final previousProviders = providerRegistry.providers;
    final previousDefaultProviderId = providerRegistry.defaultProviderId;
    providerRegistry.clear();
    final fakeProvider = _FakeQimenProvider('甲日奇门 AI 分析已完成');
    providerRegistry.register(fakeProvider);
    final promptAssembler = PromptAssembler(
      configManager: configManager,
      formatterRegistry: formatterRegistry,
    );
    final conversationService = AIConversationService(
      providerRegistry: providerRegistry,
      promptAssembler: promptAssembler,
      configManager: configManager,
      chatRepository: ChatRepository(secureStorage: MockSecureStorage()),
    );
    final analysisService = AIAnalysisService(
      providerRegistry: providerRegistry,
      configManager: configManager,
      conversationService: conversationService,
    );
    addTearDown(() async {
      analysisService.dispose();
      conversationService.dispose();
      providerRegistry.clear();
      formatterRegistry.clear();
      for (final provider in previousProviders) {
        providerRegistry.register(provider);
      }
      if (previousDefaultProviderId != null &&
          providerRegistry.getProvider(previousDefaultProviderId) != null) {
        providerRegistry.setDefaultProvider(previousDefaultProviderId);
      }
      for (final formatter in previousFormatters) {
        formatterRegistry.register(formatter);
      }
      await database.close();
    });
    final jiaResult = mutatedQimenAnalysisResult((json) {
      final context = Map<String, dynamic>.from(
        json['temporalContext'] as Map,
      )..['dayGanZhi'] = '甲子';
      json['temporalContext'] = context;
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AIAnalysisService>.value(
            value: analysisService,
          ),
          ChangeNotifierProvider<AIConversationService>.value(
            value: conversationService,
          ),
        ],
        child: MaterialApp(home: QimenResultScreen(result: jiaResult)),
      ),
    );
    await tester.pumpAndSettle();

    final start = find.byTooltip('开始分析');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(fakeProvider.requestCount, 1);
    expect(fakeProvider.lastRequest, isNotNull);
    expect(
      fakeProvider.lastRequest!.messages.last.content,
      contains('qimen-shijia-zhuanpan-analysis/v2'),
    );
    expect(
      fakeProvider.lastRequest!.messages.last.content,
      contains('焦点 self：戊落4宫'),
    );
    expect(find.text('甲日奇门 AI 分析已完成'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('presentation fallbacks never echo unknown stable IDs', () {
    expect(
      QimenAnalysisPresentation.roleLabel('futureRoleId'),
      '未识别焦点',
    );
    expect(
      QimenAnalysisPresentation.ruleLabel('QMV9-F-FUTURE'),
      '未识别规则',
    );
    expect(
      QimenAnalysisPresentation.sourceLabel('QMS-FUTURE'),
      '未识别来源',
    );
    expect(
      QimenAnalysisPresentation.ruleSetLabel('v99'),
      '时家转盘奇门（未知版本）',
    );
  });

  testWidgets('supports current and explicit released rule-set selection',
      (tester) async {
    const screenKey = ValueKey<String>('versioned-qimen-result');
    await tester.pumpWidget(
      MaterialApp(
        home: QimenResultScreen(
          key: screenKey,
          result: result,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('分析规则 时家转盘奇门 v2'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QimenResultScreen(
          key: screenKey,
          result: result,
          ruleSetVersion: 'v1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('分析规则 时家转盘奇门 v1'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('audit sections render centralized Chinese labels without IDs',
      (tester) async {
    final projection = QimenAnalysisProjection.fromReport(
      QimenAnalyzer.analyze(result),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: QimenFactsSection(projection: projection),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final title in <String>[
      '全部格局与宫位事实（${projection.facts.length}）',
      '冲突与压制（${projection.conflicts.length}）',
      '完整推理链（${projection.trace.length}）',
      '规则来源（${projection.sources.length}）',
    ]) {
      final tile = find.text(title);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('求测者 · 戊落4宫'), findsOneWidget);
    expect(find.textContaining('时家转盘奇门 v2'), findsOneWidget);
    expect(find.textContaining('焦点定位'), findsWidgets);
    expect(find.textContaining('已命中'), findsWidgets);
    expect(find.textContaining('《奇门遁甲统宗》'), findsWidgets);
    expect(find.textContaining('QMV1-'), findsNothing);
    expect(find.textContaining('QMS-'), findsNothing);
    expect(find.textContaining('generalDutyStar'), findsNothing);
    expect(find.textContaining('qimen-shijia-zhuanpan-analysis'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recomputes analysis when the result widget is reused',
      (tester) async {
    const screenKey = ValueKey<String>('reused-qimen-result');
    await tester.pumpWidget(
      MaterialApp(
        home: QimenResultScreen(key: screenKey, result: result),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AIAnalysisWidget>(find.byType(AIAnalysisWidget))
          .unavailableReason,
      isNull,
    );

    final invalidPan = fixedQimenAnalysisPanMap()..['id'] = '';
    final invalidResult = QimenResult.fromJson(invalidPan);
    await tester.pumpWidget(
      MaterialApp(
        home: QimenResultScreen(key: screenKey, result: invalidResult),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AIAnalysisWidget>(find.byType(AIAnalysisWidget))
          .unavailableReason,
      contains('排盘记录缺少有效标识'),
    );
    expect(find.text('分析兼容诊断'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
