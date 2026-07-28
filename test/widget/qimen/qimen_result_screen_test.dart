import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/ui/qimen_result_screen.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/ui/qimen_result_sections.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/ui/widgets/qimen_nine_palace_grid.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_projection.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_analyzer.dart';
import 'package:wanxiang_paipan/presentation/widgets/ai_analysis_widget.dart';

import '../../unit/services/qimen/analysis/helpers/qimen_analysis_fixtures.dart';

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
    expect(find.textContaining('QMV1-E-UNSUPPORTED-PAN-SCHEMA'), findsWidgets);
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
    expect(aiWidget.unavailableReason, contains('QMV1-E-EMPTY-RESULT-ID'));
    expect(find.textContaining('AI 分析已暂停'), findsOneWidget);
    expect(find.byTooltip('开始分析'), findsNothing);
    expect(find.text('重新分析'), findsNothing);
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
      contains('QMV1-E-EMPTY-RESULT-ID'),
    );
    expect(find.text('分析兼容诊断'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
