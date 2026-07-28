import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/services/last_cast_method_service.dart';
import '../../../domain/services/shared/tiangan_dizhi_service.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../../../presentation/widgets/cast/cast_form_sections.dart';
import '../models/qimen_enums.dart';
import '../models/qimen_pan_params.dart';
import '../qimen_system.dart';
import '../viewmodels/qimen_viewmodel.dart';
import 'qimen_cast_sections.dart';

class QimenCastScreen extends StatefulWidget {
  const QimenCastScreen({
    super.key,
    this.initialMethod = CastMethod.time,
    this.initialCastTime,
  });

  final CastMethod initialMethod;
  final DateTime? initialCastTime;

  @override
  State<QimenCastScreen> createState() => _QimenCastScreenState();
}

class _QimenCastScreenState extends State<QimenCastScreen> {
  static const List<CastMethod> _availableMethods = <CastMethod>[
    CastMethod.time,
    CastMethod.manual,
  ];

  static const Map<CastMethod, String> _methodLabels = <CastMethod, String>{
    CastMethod.time: '自动时间起局',
    CastMethod.manual: '手动校盘',
  };

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  late CastMethod _selectedMethod;
  QimenQuestionCategory _questionCategory = QimenQuestionCategory.general;
  late DateTime _castTime;
  QimenJuMethod _juMethod = QimenJuMethod.chaiBu;
  QimenTimeBasis _timeBasis = QimenTimeBasis.localCivil;
  QimenDayBoundary _dayBoundary = QimenDayBoundary.ziInitial;
  QimenHostingMode _hostingMode = QimenHostingMode.kunTwo;
  QimenHiddenStemMode _hiddenStemMode = QimenHiddenStemMode.dutyDoorHourStem;

  String? _yearGanZhi;
  String? _monthGanZhi;
  String? _dayGanZhi;
  String? _hourGanZhi;
  String? _solarTerm;
  QimenDun? _dun;
  int? _juNumber;
  QimenYuan? _yuan;

  bool _isProcessing = false;
  bool _methodChangedByUser = false;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialMethod;
    _castTime = widget.initialCastTime ?? DateTime.now();
    _loadLastMethod();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _loadLastMethod() async {
    try {
      final service = context.read<LastCastMethodService>();
      final method = await service.getLastMethod(
        DivinationType.qiMen,
        allowed: _availableMethods,
      );
      if (method != null &&
          mounted &&
          !_isProcessing &&
          !_methodChangedByUser) {
        setState(() => _selectedMethod = method);
      }
    } catch (_) {
      // Remembered-method lookup is optional; the legal default remains time.
    }
  }

  String get _question => _questionController.text.trim();

  void _changeMethod(CastMethod? method) {
    if (method == null || _isProcessing) return;
    _methodChangedByUser = true;
    if (method == CastMethod.manual && _timeBasis == QimenTimeBasis.trueSolar) {
      _longitudeController.clear();
    }
    setState(() => _selectedMethod = method);
  }

  void _changeTimeBasis(QimenTimeBasis value) {
    if (value != QimenTimeBasis.trueSolar) {
      _longitudeController.clear();
    }
    setState(() => _timeBasis = value);
  }

  String? _validateLongitude(String? rawValue) {
    if (_timeBasis != QimenTimeBasis.trueSolar) return null;
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return '请输入经度';
    final longitude = double.tryParse(value);
    if (longitude == null) return '经度必须是数字';
    if (!longitude.isFinite) return '经度必须是有限数';
    if (longitude < -180 || longitude > 180) {
      return '经度必须在 -180 至 180 之间';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _castTime,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _castTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _castTime.hour,
        _castTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_castTime),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _castTime = DateTime(
        _castTime.year,
        _castTime.month,
        _castTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _useCurrentTime() {
    if (_isProcessing) return;
    setState(() => _castTime = DateTime.now());
  }

  QimenPanParams _buildTimeParams() {
    final longitude = _timeBasis == QimenTimeBasis.trueSolar
        ? double.parse(_longitudeController.text.trim())
        : null;
    final sourceOffset = _timeBasis == QimenTimeBasis.beijing
        ? const Duration(hours: 8).inMinutes
        : _castTime.timeZoneOffset.inMinutes;

    // Construct a fresh value every time. QimenPanParams.copyWith cannot clear
    // nullable fields, so reusing it could leak a hidden solar longitude.
    return QimenPanParams(
      juMethod: _juMethod,
      timeBasis: _timeBasis,
      sourceUtcOffsetMinutes: sourceOffset,
      longitude: longitude,
      dayBoundary: _dayBoundary,
      hostingMode: _hostingMode,
      hiddenStemMode: _hiddenStemMode,
      questionCategory: _questionCategory,
    );
  }

  QimenPanParams _buildManualParams(DateTime castTime) => QimenPanParams(
        juMethod: QimenJuMethod.manual,
        timeBasis: QimenTimeBasis.localCivil,
        sourceUtcOffsetMinutes: castTime.timeZoneOffset.inMinutes,
        longitude: null,
        dayBoundary: QimenDayBoundary.ziInitial,
        hostingMode: _hostingMode,
        hiddenStemMode: _hiddenStemMode,
        questionCategory: _questionCategory,
      );

  Future<void> _handleSubmit() async {
    if (_isProcessing) return;
    FocusScope.of(context).unfocus();
    setState(() => _isProcessing = true);

    try {
      final isValid = _formKey.currentState?.validate() ?? false;
      if (!isValid) return;

      final viewModel = context.read<QimenViewModel>();
      final bool success;
      if (_selectedMethod == CastMethod.time) {
        success = await viewModel.submitByTime(
          castTime: _castTime,
          params: _buildTimeParams(),
          question: _question,
        );
      } else {
        final submissionTime = DateTime.now();
        success = await viewModel.submitByManual(
          yearGanZhi: _yearGanZhi!,
          monthGanZhi: _monthGanZhi!,
          dayGanZhi: _dayGanZhi!,
          hourGanZhi: _hourGanZhi!,
          solarTerm: _solarTerm!,
          dun: _dun!,
          juNumber: _juNumber!,
          yuan: _yuan!,
          params: _buildManualParams(submissionTime),
          castTime: submissionTime,
          question: _question,
        );
      }

      if (!mounted) return;
      if (!success || viewModel.result == null) {
        _showError(viewModel.errorMessage ?? '奇门起局失败');
        return;
      }

      final resultScreen =
          DivinationUIRegistry().buildResultScreen(viewModel.result!);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => resultScreen),
      );
    } catch (error) {
      if (mounted) _showError('奇门起局失败: $error');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorDeep,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<QimenViewModel>();
    final busy = _isProcessing || viewModel.isSubmitting;

    return AntiqueScaffold(
      showCompass: true,
      watermarkChar: '奇',
      appBar: const AntiqueAppBar(title: '奇门遁甲起局'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IgnorePointer(
                  ignoring: busy,
                  child: CastQuestionInputSection(
                    controller: _questionController,
                  ),
                ),
                const SizedBox(height: 16),
                IgnorePointer(
                  ignoring: busy,
                  child: CastLabeledDropdown<QimenQuestionCategory>(
                    key: const Key('qimen-question-category'),
                    label: '问事类型',
                    value: _questionCategory,
                    items: QimenQuestionCategory.values
                        .map(
                          (category) =>
                              AntiqueDropdownItem<QimenQuestionCategory>(
                            value: category,
                            label: qimenQuestionCategoryLabel(category),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _questionCategory = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                IgnorePointer(
                  ignoring: busy,
                  child: CastLabeledDropdown<CastMethod>(
                    key: const Key('qimen-cast-method'),
                    label: '起局方式',
                    value: _selectedMethod,
                    items: _availableMethods
                        .map(
                          (method) => AntiqueDropdownItem<CastMethod>(
                            value: method,
                            label: _methodLabels[method] ?? method.displayName,
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _changeMethod,
                  ),
                ),
                const SizedBox(height: 20),
                if (_selectedMethod == CastMethod.time)
                  QimenTimeCastSection(
                    castTime: _castTime,
                    juMethod: _juMethod,
                    timeBasis: _timeBasis,
                    longitudeController: _longitudeController,
                    enabled: !busy,
                    onPickDate: _pickDate,
                    onPickTime: _pickTime,
                    onUseCurrentTime: _useCurrentTime,
                    onJuMethodChanged: (value) {
                      setState(() => _juMethod = value);
                    },
                    onTimeBasisChanged: _changeTimeBasis,
                    longitudeValidator: _validateLongitude,
                  )
                else
                  QimenManualCastSection(
                    ganZhiOptions: TianGanDiZhiService.liuShiJiaZi,
                    solarTerms: QimenSystem.supportedSolarTerms,
                    yearGanZhi: _yearGanZhi,
                    monthGanZhi: _monthGanZhi,
                    dayGanZhi: _dayGanZhi,
                    hourGanZhi: _hourGanZhi,
                    solarTerm: _solarTerm,
                    dun: _dun,
                    juNumber: _juNumber,
                    yuan: _yuan,
                    enabled: !busy,
                    onYearGanZhiChanged: (value) {
                      setState(() => _yearGanZhi = value);
                    },
                    onMonthGanZhiChanged: (value) {
                      setState(() => _monthGanZhi = value);
                    },
                    onDayGanZhiChanged: (value) {
                      setState(() => _dayGanZhi = value);
                    },
                    onHourGanZhiChanged: (value) {
                      setState(() => _hourGanZhi = value);
                    },
                    onSolarTermChanged: (value) {
                      setState(() => _solarTerm = value);
                    },
                    onDunChanged: (value) => setState(() => _dun = value),
                    onJuNumberChanged: (value) {
                      setState(() => _juNumber = value);
                    },
                    onYuanChanged: (value) => setState(() => _yuan = value),
                  ),
                const SizedBox(height: 16),
                QimenAdvancedOptionsSection(
                  showDayBoundary: _selectedMethod == CastMethod.time,
                  dayBoundary: _dayBoundary,
                  hostingMode: _hostingMode,
                  hiddenStemMode: _hiddenStemMode,
                  enabled: !busy,
                  onDayBoundaryChanged: (value) {
                    setState(() => _dayBoundary = value);
                  },
                  onHostingModeChanged: (value) {
                    setState(() => _hostingMode = value);
                  },
                  onHiddenStemModeChanged: (value) {
                    setState(() => _hiddenStemMode = value);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 28,
                  child: Center(child: _buildStatus(viewModel)),
                ),
                const SizedBox(height: 8),
                AntiqueButton(
                  key: const Key('qimen-submit'),
                  label: _buttonLabel(viewModel.submissionPhase),
                  icon: Icons.auto_awesome,
                  onPressed: busy ? null : _handleSubmit,
                  fullWidth: true,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatus(QimenViewModel viewModel) {
    final String? text;
    final Color color;
    switch (viewModel.submissionPhase) {
      case QimenSubmissionPhase.idle:
        text = null;
        color = AppColors.guhe;
      case QimenSubmissionPhase.validating:
        text = '正在校验输入';
        color = AppColors.guhe;
      case QimenSubmissionPhase.casting:
        text = '正在排布九宫';
        color = AppColors.guhe;
      case QimenSubmissionPhase.saving:
        text = '正在保存记录';
        color = AppColors.guhe;
      case QimenSubmissionPhase.success:
        text = '记录已保存';
        color = AppColors.jishenGreen;
      case QimenSubmissionPhase.error:
        text = viewModel.errorMessage ?? '起局失败';
        color = AppColors.errorDeep;
    }
    if (text == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        key: const Key('qimen-submission-status'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.antiqueLabel.copyWith(color: color),
      ),
    );
  }

  String _buttonLabel(QimenSubmissionPhase phase) => switch (phase) {
        QimenSubmissionPhase.validating => '校验中...',
        QimenSubmissionPhase.casting => '起局中...',
        QimenSubmissionPhase.saving => '保存中...',
        _ => _selectedMethod == CastMethod.manual ? '按所选参数校盘' : '起局',
      };
}
