import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_enums.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_pan_params.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/qimen_system.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/viewmodels/qimen_viewmodel.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/repositories/divination_repository.dart';
import 'package:wanxiang_paipan/viewmodels/divination_viewmodel.dart';

class _MockRepository extends Mock implements DivinationRepository {}

class _FakeResult extends Fake implements DivinationResult {}

class _RecordingQimenSystem extends QimenSystem {
  _RecordingQimenSystem({this.gate});

  final Completer<void>? gate;
  int castCalls = 0;
  CastMethod? lastMethod;
  Map<String, dynamic>? lastInput;
  DateTime? lastCastTime;
  Object? nextError;

  @override
  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  }) async {
    castCalls += 1;
    lastMethod = method;
    lastInput = input;
    lastCastTime = castTime;
    await gate?.future;
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
    return super.cast(method: method, input: input, castTime: castTime);
  }
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeResult()));

  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(() => repository.saveRecord(any())).thenAnswer((invocation) async {
      final result = invocation.positionalArguments.single as DivinationResult;
      return result.id;
    });
    when(() => repository.saveEncryptedFieldsBatch(any()))
        .thenAnswer((_) async {});
  });

  test('time submission builds typed payload, saves, then exposes success',
      () async {
    final system = _RecordingQimenSystem();
    final viewModel = QimenViewModel(system: system, repository: repository);
    final castTime = DateTime.utc(2025, 6, 8, 4);

    final submitted = await viewModel.submitByTime(
      castTime: castTime,
      params: const QimenPanParams(
        juMethod: QimenJuMethod.zhiRun,
        timeBasis: QimenTimeBasis.beijing,
        sourceUtcOffsetMinutes: 480,
        dayBoundary: QimenDayBoundary.midnight,
        hostingMode: QimenHostingMode.yangEightYinTwo,
        hiddenStemMode: QimenHiddenStemMode.doorOriginEarthStem,
        questionCategory: QimenQuestionCategory.career,
      ),
      question: '  工作调动  ',
    );

    expect(submitted, isTrue);
    expect(system.lastMethod, CastMethod.time);
    expect(system.lastCastTime, castTime);
    expect(system.lastInput, <String, dynamic>{
      'params': <String, dynamic>{
        'juMethod': 'zhiRun',
        'timeBasis': 'beijing',
        'sourceUtcOffsetMinutes': 480,
        'longitude': null,
        'dayBoundary': 'midnight',
        'hostingMode': 'yangEightYinTwo',
        'hiddenStemMode': 'doorOriginEarthStem',
        'questionCategory': 'career',
      },
    });
    expect(viewModel.submissionPhase, QimenSubmissionPhase.success);
    expect(viewModel.state, CastState.success);
    expect(viewModel.result, isNotNull);
    expect(viewModel.question, '工作调动');
    verify(() => repository.saveRecord(viewModel.result!)).called(1);
    verify(
      () => repository.saveEncryptedFieldsBatch(
        <String, String>{
          'question_${viewModel.result!.id}': '工作调动',
        },
      ),
    ).called(1);
  });

  test('manual submission constructs the frozen payload without juMethod',
      () async {
    final system = _RecordingQimenSystem();
    final viewModel = QimenViewModel(system: system, repository: repository);

    final submitted = await viewModel.submitByManual(
      yearGanZhi: '丙午',
      monthGanZhi: '甲午',
      dayGanZhi: '丁卯',
      hourGanZhi: '丙午',
      solarTerm: '小暑',
      dun: QimenDun.yin,
      juNumber: 8,
      yuan: QimenYuan.middle,
      params: const QimenPanParams(
        juMethod: QimenJuMethod.manual,
        timeBasis: QimenTimeBasis.localCivil,
        sourceUtcOffsetMinutes: 480,
        dayBoundary: QimenDayBoundary.ziInitial,
        hostingMode: QimenHostingMode.kunTwo,
        hiddenStemMode: QimenHiddenStemMode.dutyDoorHourStem,
        questionCategory: QimenQuestionCategory.relationship,
      ),
      castTime: DateTime.utc(2026, 7, 7, 4),
    );

    expect(submitted, isTrue);
    expect(system.lastMethod, CastMethod.manual);
    expect(system.lastInput, <String, dynamic>{
      'yearGanZhi': '丙午',
      'monthGanZhi': '甲午',
      'dayGanZhi': '丁卯',
      'hourGanZhi': '丙午',
      'solarTerm': '小暑',
      'dun': 'yin',
      'juNumber': 8,
      'yuan': 'middle',
      'params': <String, dynamic>{
        'timeBasis': 'localCivil',
        'sourceUtcOffsetMinutes': 480,
        'longitude': null,
        'dayBoundary': 'ziInitial',
        'hostingMode': 'kunTwo',
        'hiddenStemMode': 'dutyDoorHourStem',
        'questionCategory': 'relationship',
      },
    });
    final params = system.lastInput!['params'] as Map<String, dynamic>;
    expect(params, isNot(contains('juMethod')));
    expect(viewModel.result!.panParams.juMethod, QimenJuMethod.manual);
  });

  test('non-solar submissions clear stale typed longitude before casting',
      () async {
    final system = _RecordingQimenSystem();
    final viewModel = QimenViewModel(system: system, repository: repository);

    final submitted = await viewModel.submitByTime(
      castTime: DateTime.utc(2025, 6, 8, 4),
      params: const QimenPanParams(
        timeBasis: QimenTimeBasis.beijing,
        sourceUtcOffsetMinutes: 480,
        longitude: 116.4074,
      ),
    );

    expect(submitted, isTrue);
    final payload = system.lastInput!['params'] as Map<String, dynamic>;
    expect(payload['timeBasis'], 'beijing');
    expect(payload['longitude'], isNull);
    expect(viewModel.result!.panParams.longitude, isNull);
  });

  test('duplicate submit is rejected while calculation is in flight', () async {
    final gate = Completer<void>();
    final system = _RecordingQimenSystem(gate: gate);
    final viewModel = QimenViewModel(system: system, repository: repository);
    const params = QimenPanParams(
      timeBasis: QimenTimeBasis.beijing,
      sourceUtcOffsetMinutes: 480,
    );

    final first = viewModel.submitByTime(
      castTime: DateTime.utc(2025, 6, 8, 4),
      params: params,
    );
    final second = await viewModel.submitByTime(
      castTime: DateTime.utc(2025, 6, 8, 4),
      params: params,
    );

    expect(second, isFalse);
    expect(system.castCalls, 1);
    expect(viewModel.submissionPhase, QimenSubmissionPhase.casting);

    gate.complete();
    expect(await first, isTrue);
    verify(() => repository.saveRecord(any())).called(1);
  });

  test('save failure remains an error and never reports navigable success',
      () async {
    when(() => repository.saveRecord(any()))
        .thenThrow(StateError('storage unavailable'));
    final viewModel = QimenViewModel(
      system: _RecordingQimenSystem(),
      repository: repository,
    );

    final submitted = await viewModel.submitByTime(
      castTime: DateTime.utc(2025, 6, 8, 4),
      params: const QimenPanParams(
        timeBasis: QimenTimeBasis.beijing,
        sourceUtcOffsetMinutes: 480,
      ),
      question: '测试保存失败',
    );

    expect(submitted, isFalse);
    expect(viewModel.submissionPhase, QimenSubmissionPhase.error);
    expect(viewModel.state, CastState.error);
    expect(viewModel.hasError, isTrue);
    expect(viewModel.errorMessage, contains('storage unavailable'));
    verifyNever(() => repository.saveEncryptedFieldsBatch(any()));
  });

  test('encrypted question failure also withholds submission success',
      () async {
    when(() => repository.saveEncryptedFieldsBatch(any()))
        .thenThrow(StateError('secure storage unavailable'));
    final viewModel = QimenViewModel(
      system: _RecordingQimenSystem(),
      repository: repository,
    );

    final submitted = await viewModel.submitByTime(
      castTime: DateTime.utc(2025, 6, 8, 4),
      params: const QimenPanParams(
        timeBasis: QimenTimeBasis.beijing,
        sourceUtcOffsetMinutes: 480,
      ),
      question: '需要加密保存',
    );

    expect(submitted, isFalse);
    expect(viewModel.submissionPhase, QimenSubmissionPhase.error);
    expect(viewModel.errorMessage, contains('secure storage unavailable'));
    verify(() => repository.saveRecord(any())).called(1);
  });

  test('a failed second cast clears the prior successful result', () async {
    final system = _RecordingQimenSystem();
    final viewModel = QimenViewModel(system: system, repository: repository);
    const params = QimenPanParams(
      timeBasis: QimenTimeBasis.beijing,
      sourceUtcOffsetMinutes: 480,
    );

    expect(
      await viewModel.submitByTime(
        castTime: DateTime.utc(2025, 6, 8, 4),
        params: params,
      ),
      isTrue,
    );
    expect(viewModel.result, isNotNull);

    system.nextError = StateError('second cast failed');
    await viewModel.castByTime(
      castTime: DateTime.utc(2025, 6, 8, 5),
      params: params,
    );

    expect(viewModel.result, isNull);
    expect(viewModel.submissionPhase, QimenSubmissionPhase.error);
    expect(viewModel.errorMessage, contains('second cast failed'));
  });

  test('completion after disposal does not notify a disposed notifier',
      () async {
    final gate = Completer<void>();
    final viewModel = QimenViewModel(
      system: _RecordingQimenSystem(gate: gate),
      repository: repository,
    );

    final submission = viewModel.submitByTime(
      castTime: DateTime.utc(2025, 6, 8, 4),
      params: const QimenPanParams(
        timeBasis: QimenTimeBasis.beijing,
        sourceUtcOffsetMinutes: 480,
      ),
    );
    viewModel.dispose();
    gate.complete();

    await expectLater(submission, completion(isTrue));
  });
}
