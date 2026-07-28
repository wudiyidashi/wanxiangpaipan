import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../viewmodels/divination_viewmodel.dart';
import '../models/qimen_enums.dart';
import '../models/qimen_pan_params.dart';
import '../models/qimen_result.dart';
import '../qimen_system.dart';

/// Product-level phases for a Qimen submission.
///
/// [CastState] only covers calculation. Qimen navigation must also wait for
/// persistence, so this state remains loading through the save boundary.
enum QimenSubmissionPhase {
  idle,
  validating,
  casting,
  saving,
  success,
  error,
}

class QimenViewModel extends DivinationViewModel<QimenResult> {
  QimenViewModel({
    required QimenSystem system,
    required DivinationRepository repository,
  }) : super(system: system, repository: repository);

  QimenSubmissionPhase _submissionPhase = QimenSubmissionPhase.idle;
  QimenSubmissionPhase get submissionPhase => _submissionPhase;

  String? _submissionError;
  String? get submissionError => _submissionError;

  bool _operationInProgress = false;
  bool _disposed = false;

  bool get isSubmitting =>
      _submissionPhase == QimenSubmissionPhase.validating ||
      _submissionPhase == QimenSubmissionPhase.casting ||
      _submissionPhase == QimenSubmissionPhase.saving;

  @override
  CastState get state => switch (_submissionPhase) {
        QimenSubmissionPhase.idle => super.state,
        QimenSubmissionPhase.validating ||
        QimenSubmissionPhase.saving =>
          CastState.calculating,
        QimenSubmissionPhase.casting => CastState.casting,
        QimenSubmissionPhase.success => CastState.success,
        QimenSubmissionPhase.error => CastState.error,
      };

  @override
  bool get isLoading => isSubmitting || super.isLoading;

  @override
  bool get hasError =>
      _submissionPhase == QimenSubmissionPhase.error || super.hasError;

  @override
  String? get errorMessage => _submissionError ?? super.errorMessage;

  QimenPanParams? get panParams => result?.panParams;

  /// Calculates a time-based pan without saving it.
  ///
  /// Product screens should normally use [submitByTime], which keeps the
  /// duplicate-submission lock held until persistence completes.
  Future<void> castByTime({
    required DateTime castTime,
    required QimenPanParams params,
  }) async {
    if (_operationInProgress) return;
    _operationInProgress = true;
    _prepareOperation(QimenSubmissionPhase.casting);
    try {
      await _castByTimeUnchecked(castTime: castTime, params: params);
      _finishCastOnly();
    } catch (error) {
      _fail(error);
    } finally {
      _operationInProgress = false;
    }
  }

  /// Calculates a manually calibrated pan without saving it.
  Future<void> castByManual({
    required String yearGanZhi,
    required String monthGanZhi,
    required String dayGanZhi,
    required String hourGanZhi,
    required String solarTerm,
    required QimenDun dun,
    required int juNumber,
    required QimenYuan yuan,
    required QimenPanParams params,
    DateTime? castTime,
  }) async {
    if (_operationInProgress) return;
    _operationInProgress = true;
    _prepareOperation(QimenSubmissionPhase.casting);
    try {
      await _castByManualUnchecked(
        yearGanZhi: yearGanZhi,
        monthGanZhi: monthGanZhi,
        dayGanZhi: dayGanZhi,
        hourGanZhi: hourGanZhi,
        solarTerm: solarTerm,
        dun: dun,
        juNumber: juNumber,
        yuan: yuan,
        params: params,
        castTime: castTime,
      );
      _finishCastOnly();
    } catch (error) {
      _fail(error);
    } finally {
      _operationInProgress = false;
    }
  }

  /// Runs calculation and persistence as one guarded operation.
  Future<bool> submitByTime({
    required DateTime castTime,
    required QimenPanParams params,
    String? question,
  }) =>
      _submit(
        castAction: () =>
            _castByTimeUnchecked(castTime: castTime, params: params),
        question: question,
      );

  /// Runs manual calculation and persistence as one guarded operation.
  Future<bool> submitByManual({
    required String yearGanZhi,
    required String monthGanZhi,
    required String dayGanZhi,
    required String hourGanZhi,
    required String solarTerm,
    required QimenDun dun,
    required int juNumber,
    required QimenYuan yuan,
    required QimenPanParams params,
    DateTime? castTime,
    String? question,
  }) =>
      _submit(
        castAction: () => _castByManualUnchecked(
          yearGanZhi: yearGanZhi,
          monthGanZhi: monthGanZhi,
          dayGanZhi: dayGanZhi,
          hourGanZhi: hourGanZhi,
          solarTerm: solarTerm,
          dun: dun,
          juNumber: juNumber,
          yuan: yuan,
          params: params,
          castTime: castTime,
        ),
        question: question,
      );

  Future<bool> _submit({
    required Future<void> Function() castAction,
    required String? question,
  }) async {
    if (_operationInProgress) return false;
    _operationInProgress = true;
    _prepareOperation(QimenSubmissionPhase.validating);

    try {
      _setSubmissionPhase(QimenSubmissionPhase.casting);
      await castAction();
      if (super.hasError || result == null) {
        _fail(super.errorMessage ?? '奇门起局失败');
        return false;
      }

      _setSubmissionPhase(QimenSubmissionPhase.saving);
      final normalizedQuestion = question?.trim();
      await super.saveRecord(
        question: normalizedQuestion == null || normalizedQuestion.isEmpty
            ? null
            : normalizedQuestion,
      );
      _setSubmissionPhase(QimenSubmissionPhase.success);
      return true;
    } catch (error) {
      _fail(error);
      return false;
    } finally {
      _operationInProgress = false;
    }
  }

  Future<void> _castByTimeUnchecked({
    required DateTime castTime,
    required QimenPanParams params,
  }) =>
      super.cast(
        method: CastMethod.time,
        input: <String, dynamic>{'params': _timeParamsPayload(params)},
        castTime: castTime,
      );

  Future<void> _castByManualUnchecked({
    required String yearGanZhi,
    required String monthGanZhi,
    required String dayGanZhi,
    required String hourGanZhi,
    required String solarTerm,
    required QimenDun dun,
    required int juNumber,
    required QimenYuan yuan,
    required QimenPanParams params,
    required DateTime? castTime,
  }) =>
      super.cast(
        method: CastMethod.manual,
        input: <String, dynamic>{
          'yearGanZhi': yearGanZhi,
          'monthGanZhi': monthGanZhi,
          'dayGanZhi': dayGanZhi,
          'hourGanZhi': hourGanZhi,
          'solarTerm': solarTerm,
          'dun': dun.id,
          'juNumber': juNumber,
          'yuan': yuan.id,
          // The manual contract deliberately excludes juMethod. The engine
          // owns promotion to QimenJuMethod.manual after validation.
          'params': _manualParamsPayload(params),
        },
        castTime: castTime,
      );

  Map<String, dynamic> _timeParamsPayload(QimenPanParams params) =>
      <String, dynamic>{
        'juMethod': params.juMethod.id,
        'timeBasis': params.timeBasis.id,
        'sourceUtcOffsetMinutes': params.sourceUtcOffsetMinutes,
        'longitude': params.timeBasis == QimenTimeBasis.trueSolar
            ? params.longitude
            : null,
        'dayBoundary': params.dayBoundary.id,
        'hostingMode': params.hostingMode.id,
        'hiddenStemMode': params.hiddenStemMode.id,
        'questionCategory': params.questionCategory.id,
      };

  Map<String, dynamic> _manualParamsPayload(QimenPanParams params) =>
      <String, dynamic>{
        'timeBasis': params.timeBasis.id,
        'sourceUtcOffsetMinutes': params.sourceUtcOffsetMinutes,
        'longitude': params.timeBasis == QimenTimeBasis.trueSolar
            ? params.longitude
            : null,
        'dayBoundary': params.dayBoundary.id,
        'hostingMode': params.hostingMode.id,
        'hiddenStemMode': params.hiddenStemMode.id,
        'questionCategory': params.questionCategory.id,
      };

  void _prepareOperation(QimenSubmissionPhase phase) {
    _submissionError = null;
    _submissionPhase = phase;
    super.reset();
  }

  void _finishCastOnly() {
    if (super.hasError || result == null) {
      _fail(super.errorMessage ?? '奇门起局失败');
      return;
    }
    _setSubmissionPhase(QimenSubmissionPhase.success);
  }

  void _fail(Object error) {
    _submissionError = _readableError(error);
    _setSubmissionPhase(QimenSubmissionPhase.error);
  }

  String _readableError(Object error) {
    final message = error.toString();
    return message
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^ArgumentError:\s*'), '');
  }

  void _setSubmissionPhase(QimenSubmissionPhase phase) {
    _submissionPhase = phase;
    notifyListeners();
  }

  @override
  void reset() {
    if (_operationInProgress) return;
    _submissionPhase = QimenSubmissionPhase.idle;
    _submissionError = null;
    super.reset();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
