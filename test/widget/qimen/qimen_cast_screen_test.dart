import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_enums.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/qimen_system.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/ui/qimen_cast_screen.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/viewmodels/qimen_viewmodel.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/repositories/divination_repository.dart';
import 'package:wanxiang_paipan/domain/services/last_cast_method_service.dart';
import 'package:wanxiang_paipan/presentation/divination_ui_registry.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique.dart';

class _MockRepository extends Mock implements DivinationRepository {}

class _FakeResult extends Fake implements DivinationResult {}

class _HistoryResult extends Fake implements DivinationResult {
  _HistoryResult(this._method);

  final CastMethod _method;

  @override
  CastMethod get castMethod => _method;
}

class _RecordingQimenSystem extends QimenSystem {
  _RecordingQimenSystem(this.events);

  final List<String> events;
  int castCalls = 0;

  @override
  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  }) {
    castCalls += 1;
    events.add('cast');
    return super.cast(method: method, input: input, castTime: castTime);
  }
}

class _QimenTestUIFactory implements DivinationUIFactory {
  const _QimenTestUIFactory(this.events);

  final List<String> events;

  @override
  DivinationType get systemType => DivinationType.qiMen;

  @override
  Widget buildCastScreen(CastMethod method) => const SizedBox.shrink();

  @override
  Widget buildHistoryCard(DivinationResult result) => const SizedBox.shrink();

  @override
  Widget buildResultScreen(DivinationResult result) {
    events.add('build');
    return const Scaffold(body: Center(child: Text('奇门结果测试页')));
  }

  @override
  Color? getSystemColor() => null;

  @override
  IconData? getSystemIcon() => null;
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeResult()));

  late _MockRepository repository;
  late List<String> events;
  late _RecordingQimenSystem system;
  late QimenViewModel viewModel;

  setUp(() {
    DivinationUIRegistry().clear();
    events = <String>[];
    repository = _MockRepository();
    system = _RecordingQimenSystem(events);
    viewModel = QimenViewModel(system: system, repository: repository);
    when(() => repository.saveRecord(any())).thenAnswer((invocation) async {
      events.add('save');
      final result = invocation.positionalArguments.single as DivinationResult;
      return result.id;
    });
    when(() => repository.saveEncryptedFieldsBatch(any()))
        .thenAnswer((_) async => events.add('encrypted'));
  });

  tearDown(() {
    DivinationUIRegistry().clear();
    viewModel.dispose();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    LastCastMethodService? lastCastMethodService,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<QimenViewModel>.value(value: viewModel),
          if (lastCastMethodService != null)
            Provider<LastCastMethodService>.value(
              value: lastCastMethodService,
            ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: const QimenCastScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> chooseTimeBasis(
    WidgetTester tester,
    String label,
  ) async {
    final scope = find.byKey(const Key('qimen-time-basis'));
    await tester.ensureVisible(scope);
    await tester.tap(
      find.descendant(
        of: scope,
        matching: find.byType(DropdownButton<QimenTimeBasis>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> chooseCastMethod(
    WidgetTester tester,
    String label,
  ) async {
    final scope = find.byKey(const Key('qimen-cast-method'));
    await tester.ensureVisible(scope);
    await tester.tap(
      find.descendant(
        of: scope,
        matching: find.byType(DropdownButton<CastMethod>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> setManualValue<T>(
    WidgetTester tester,
    Key fieldKey,
    T value,
  ) async {
    final scope = find.byKey(fieldKey);
    await tester.ensureVisible(scope);
    final dropdown = tester.widget<DropdownButtonFormField<T>>(
      find.descendant(
        of: scope,
        matching: find.byType(DropdownButtonFormField<T>),
      ),
    );
    dropdown.onChanged!(value);
    await tester.pump();
  }

  testWidgets('exposes all eight question categories and automatic methods',
      (tester) async {
    await pumpScreen(tester);

    final categoryScope = find.byKey(const Key('qimen-question-category'));
    await tester.tap(
      find.descendant(
        of: categoryScope,
        matching: find.byType(DropdownButton<QimenQuestionCategory>),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in <String>[
      '综合',
      '事业',
      '财运',
      '感情',
      '健康',
      '学业',
      '出行',
      '诉讼',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('综合').last);
    await tester.pumpAndSettle();

    final juScope = find.byKey(const Key('qimen-ju-method'));
    await tester.ensureVisible(juScope);
    await tester.tap(
      find.descendant(
        of: juScope,
        matching: find.byType(DropdownButton<QimenJuMethod>),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('拆补法'), findsWidgets);
    expect(find.text('茅山法'), findsOneWidget);
    expect(find.text('置闰法'), findsOneWidget);
    await tester.tap(find.text('拆补法').last);
    await tester.pumpAndSettle();

    final basisScope = find.byKey(const Key('qimen-time-basis'));
    await tester.ensureVisible(basisScope);
    await tester.tap(
      find.descendant(
        of: basisScope,
        matching: find.byType(DropdownButton<QimenTimeBasis>),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('当地民用时间'), findsWidgets);
    expect(find.text('北京时间'), findsOneWidget);
    expect(find.text('真太阳时'), findsOneWidget);
    await tester.tap(find.text('当地民用时间').last);
    await tester.pumpAndSettle();

    final advanced = find.byKey(const Key('qimen-advanced-options'));
    await tester.ensureVisible(advanced);
    await tester.tap(advanced);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('qimen-day-boundary')), findsOneWidget);
    expect(find.byKey(const Key('qimen-hosting-mode')), findsOneWidget);
    expect(find.byKey(const Key('qimen-hidden-stem-mode')), findsOneWidget);

    final dayBoundary = tester.widget<AntiqueDropdown<QimenDayBoundary>>(
      find.descendant(
        of: find.byKey(const Key('qimen-day-boundary')),
        matching: find.byType(AntiqueDropdown<QimenDayBoundary>),
      ),
    );
    final hosting = tester.widget<AntiqueDropdown<QimenHostingMode>>(
      find.descendant(
        of: find.byKey(const Key('qimen-hosting-mode')),
        matching: find.byType(AntiqueDropdown<QimenHostingMode>),
      ),
    );
    final hiddenStem = tester.widget<AntiqueDropdown<QimenHiddenStemMode>>(
      find.descendant(
        of: find.byKey(const Key('qimen-hidden-stem-mode')),
        matching: find.byType(AntiqueDropdown<QimenHiddenStemMode>),
      ),
    );
    expect(
        dayBoundary.items.map((item) => item.value), QimenDayBoundary.values);
    expect(hosting.items.map((item) => item.value), QimenHostingMode.values);
    expect(
      hiddenStem.items.map((item) => item.value),
      QimenHiddenStemMode.values,
    );
  });

  testWidgets('true-solar longitude is validated and cleared when exited',
      (tester) async {
    await pumpScreen(tester);

    await chooseTimeBasis(tester, '真太阳时');
    expect(find.byKey(const Key('qimen-longitude')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('qimen-longitude')),
      '116.4074',
    );

    await chooseTimeBasis(tester, '北京时间');
    expect(find.byKey(const Key('qimen-longitude')), findsNothing);

    await chooseTimeBasis(tester, '真太阳时');
    final field = tester.widget<TextFormField>(
      find.byKey(const Key('qimen-longitude')),
    );
    expect(field.controller!.text, isEmpty);

    final submit = find.byKey(const Key('qimen-submit'));
    await tester.enterText(
      find.byKey(const Key('qimen-longitude')),
      '181',
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('经度必须在 -180 至 180 之间'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('qimen-longitude')),
      '12.3.4',
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('经度必须是数字'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('qimen-longitude')), '');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('请输入经度'), findsOneWidget);
    expect(system.castCalls, 0);
    verifyNever(() => repository.saveRecord(any()));
  });

  testWidgets('manual calibration starts empty and rejects omitted facts',
      (tester) async {
    await pumpScreen(tester);
    await chooseCastMethod(tester, '手动校盘');

    expect(find.byKey(const Key('qimen-year-pillar')), findsOneWidget);
    final submit = find.byKey(const Key('qimen-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('请选择年柱'), findsOneWidget);
    expect(find.text('请选择月柱'), findsOneWidget);
    expect(find.text('请选择日柱'), findsOneWidget);
    expect(find.text('请选择时柱'), findsOneWidget);
    expect(find.text('请选择节气'), findsOneWidget);
    expect(system.castCalls, 0);
  });

  testWidgets('complete manual calibration saves and navigates',
      (tester) async {
    DivinationUIRegistry().registerUI(_QimenTestUIFactory(events));
    await pumpScreen(tester);
    await chooseCastMethod(tester, '手动校盘');

    await setManualValue<String>(
      tester,
      const Key('qimen-year-pillar'),
      '丙午',
    );
    await setManualValue<String>(
      tester,
      const Key('qimen-month-pillar'),
      '甲午',
    );
    await setManualValue<String>(
      tester,
      const Key('qimen-day-pillar'),
      '丁卯',
    );
    await setManualValue<String>(
      tester,
      const Key('qimen-hour-pillar'),
      '丙午',
    );
    await setManualValue<String>(
      tester,
      const Key('qimen-solar-term'),
      '小暑',
    );
    await setManualValue<QimenDun>(
      tester,
      const Key('qimen-dun'),
      QimenDun.yin,
    );
    await setManualValue<int>(tester, const Key('qimen-ju-number'), 8);
    await setManualValue<QimenYuan>(
      tester,
      const Key('qimen-yuan'),
      QimenYuan.middle,
    );

    final submit = find.byKey(const Key('qimen-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('奇门结果测试页'), findsOneWidget);
    expect(events, <String>['cast', 'save', 'build']);
    expect(viewModel.result!.castMethod, CastMethod.manual);
    expect(viewModel.result!.panParams.juMethod, QimenJuMethod.manual);
  });

  testWidgets('successful flow casts, saves encrypted question, then navigates',
      (tester) async {
    DivinationUIRegistry().registerUI(_QimenTestUIFactory(events));
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField).first, '项目是否适合推进');
    final submit = find.byKey(const Key('qimen-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('奇门结果测试页'), findsOneWidget);
    expect(events, <String>['cast', 'save', 'encrypted', 'build']);
    expect(viewModel.submissionPhase, QimenSubmissionPhase.success);
  });

  testWidgets('save failure stays on cast screen and does not navigate',
      (tester) async {
    DivinationUIRegistry().registerUI(_QimenTestUIFactory(events));
    when(() => repository.saveRecord(any()))
        .thenThrow(StateError('storage unavailable'));
    await pumpScreen(tester);

    final submit = find.byKey(const Key('qimen-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('奇门遁甲起局'), findsOneWidget);
    expect(find.textContaining('storage unavailable'), findsWidgets);
    expect(events, isNot(contains('build')));
    expect(viewModel.submissionPhase, QimenSubmissionPhase.error);
  });

  testWidgets('restores the latest supported method from history',
      (tester) async {
    when(() => repository.getRecordsBySystemType(DivinationType.qiMen))
        .thenAnswer((_) async => <DivinationResult>[
              _HistoryResult(CastMethod.manual),
            ]);

    await pumpScreen(
      tester,
      lastCastMethodService: LastCastMethodService(repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qimen-year-pillar')), findsOneWidget);
    expect(find.text('手动校盘'), findsWidgets);
  });

  testWidgets('history lookup failure keeps the legal time default',
      (tester) async {
    when(() => repository.getRecordsBySystemType(DivinationType.qiMen))
        .thenThrow(StateError('history unavailable'));

    await pumpScreen(
      tester,
      lastCastMethodService: LastCastMethodService(repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qimen-time-basis')), findsOneWidget);
    expect(find.text('自动时间起局'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delayed history cannot overwrite a user method selection',
      (tester) async {
    final history = Completer<List<DivinationResult>>();
    when(() => repository.getRecordsBySystemType(DivinationType.qiMen))
        .thenAnswer((_) => history.future);

    await pumpScreen(
      tester,
      lastCastMethodService: LastCastMethodService(repository: repository),
    );
    await chooseCastMethod(tester, '手动校盘');

    history.complete(<DivinationResult>[_HistoryResult(CastMethod.time)]);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qimen-year-pillar')), findsOneWidget);
    expect(find.text('手动校盘'), findsWidgets);
  });

  testWidgets('manual form does not overflow at 320dp with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpScreen(tester, textScale: 1.5);
    await chooseCastMethod(tester, '手动校盘');
    await tester.ensureVisible(find.byKey(const Key('qimen-submit')));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
