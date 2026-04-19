import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/services/last_cast_method_service.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../viewmodels/daliuren_viewmodel.dart';
import '../models/pan_params.dart';
import 'daliuren_cast_sections.dart';
import 'daliuren_result_screen.dart';

/// 大六壬统一起课界面（仿古风）
class DaLiuRenCastScreen extends StatefulWidget {
  const DaLiuRenCastScreen({super.key});

  @override
  State<DaLiuRenCastScreen> createState() => _DaLiuRenCastScreenState();
}

class _DaLiuRenCastScreenState extends State<DaLiuRenCastScreen> {
  static const List<CastMethod> _availableMethods = [
    CastMethod.time,
    CastMethod.reportNumber,
    CastMethod.manual,
    CastMethod.computer,
  ];

  static const Map<CastMethod, String> _methodNames = {
    CastMethod.time: '正时起课',
    CastMethod.reportNumber: '报数起课',
    CastMethod.manual: '指定干支',
    CastMethod.computer: '随机起课',
  };

  static const List<String> _tianGan = [
    '甲',
    '乙',
    '丙',
    '丁',
    '戊',
    '己',
    '庚',
    '辛',
    '壬',
    '癸',
  ];

  static const List<String> _diZhi = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥',
  ];

  CastMethod _selectedMethod = CastMethod.time;
  bool _isLoading = false;

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _birthYearController = TextEditingController();

  String _yearGan = '丙';
  String _yearZhi = '午';
  String _monthGan = '壬';
  String _monthZhi = '辰';
  String _dayGan = '壬';
  String _dayZhi = '戌';
  String _hourGan = '辛';
  String _hourZhi = '亥';

  DaLiuRenMonthGeneralMode _monthGeneralMode = DaLiuRenMonthGeneralMode.auto;
  String _manualMonthGeneral = '戌';
  DaLiuRenDayNightMode _dayNightMode = DaLiuRenDayNightMode.auto;
  DaLiuRenGuiRenVerse _guiRenVerse = DaLiuRenGuiRenVerse.classic;
  DaLiuRenXunShouMode _xunShouMode = DaLiuRenXunShouMode.day;
  bool _showSanChuanOnTop = true;

  @override
  void initState() {
    super.initState();
    final nowLunar = Lunar.fromDate(DateTime.now());
    _yearGan = nowLunar.getYearGan();
    _yearZhi = nowLunar.getYearZhi();
    _monthGan = nowLunar.getMonthGan();
    _monthZhi = nowLunar.getMonthZhi();
    _dayGan = nowLunar.getDayGan();
    _dayZhi = nowLunar.getDayZhi();
    _hourGan = nowLunar.getTimeGan();
    _hourZhi = nowLunar.getTimeZhi();
    _loadLastMethod();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _numberController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  Future<void> _loadLastMethod() async {
    final LastCastMethodService service;
    try {
      service = context.read<LastCastMethodService>();
    } catch (_) {
      return;
    }
    final method = await service.getLastMethod(
      DivinationType.daLiuRen,
      allowed: _availableMethods,
    );
    if (method != null && mounted) {
      setState(() => _selectedMethod = method);
    }
  }

  Future<void> _handleCast() async {
    if (_isLoading) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final viewModel = context.read<DaLiuRenViewModel>();
      final params = _buildPanParams();
      final now = DateTime.now();

      switch (_selectedMethod) {
        case CastMethod.time:
          await viewModel.castByTime(castTime: now, params: params);
        case CastMethod.reportNumber:
          final number = int.tryParse(_numberController.text.trim());
          if (number == null) {
            _showError('请输入有效的数字');
            setState(() => _isLoading = false);
            return;
          }
          await viewModel.castByReportNumber(
            number,
            castTime: now,
            params: params,
          );
        case CastMethod.manual:
          await viewModel.castByManual(
            yearGanZhi: '$_yearGan$_yearZhi',
            monthGanZhi: '$_monthGan$_monthZhi',
            dayGanZhi: '$_dayGan$_dayZhi',
            hourGanZhi: '$_hourGan$_hourZhi',
            params: params,
          );
        case CastMethod.computer:
          await viewModel.castByComputer(castTime: now, params: params);
        default:
          throw UnsupportedError('不支持的起课方式');
      }

      if (viewModel.hasError || !viewModel.hasResult) {
        _showError(viewModel.errorMessage ?? '起课失败');
        return;
      }

      await viewModel.saveRecord(
        question: _question.isEmpty ? null : _question,
      );

      if (!mounted) {
        return;
      }

      final result = viewModel.result!;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => DaLiuRenResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showError('起课失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _question => _questionController.text.trim();

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorDeep,
      ),
    );
  }

  DaLiuRenPanParams _buildPanParams() {
    final birthYearText = _birthYearController.text.trim();
    final birthYear =
        birthYearText.isEmpty ? null : int.tryParse(birthYearText);
    if (birthYearText.isNotEmpty && birthYear == null) {
      throw FormatException('生年必须为数字');
    }

    final forceManualMonthGeneral = _selectedMethod == CastMethod.manual;
    final monthGeneralMode = forceManualMonthGeneral
        ? DaLiuRenMonthGeneralMode.manual
        : _monthGeneralMode;

    return DaLiuRenPanParams(
      birthYear: birthYear,
      monthGeneralMode: monthGeneralMode,
      manualMonthGeneral: monthGeneralMode == DaLiuRenMonthGeneralMode.manual
          ? _manualMonthGeneral
          : null,
      dayNightMode: _dayNightMode,
      guiRenVerse: _guiRenVerse,
      xunShouMode: _xunShouMode,
      showSanChuanOnTop: _showSanChuanOnTop,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AntiqueScaffold(
      showCompass: true,
      appBar: const AntiqueAppBar(title: '大六壬起课'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DaLiuRenCastQuestionSection(controller: _questionController),
              const SizedBox(height: 16),
              DaLiuRenCastMethodSelector(
                selectedMethod: _selectedMethod,
                availableMethods: _availableMethods,
                methodNames: _methodNames,
                onChanged: (method) {
                  if (method != null) {
                    setState(() => _selectedMethod = method);
                  }
                },
              ),
              const SizedBox(height: 16),
              DaLiuRenCastPanParamsSection(
                selectedMethod: _selectedMethod,
                diZhiOptions: _diZhi,
                dayNightMode: _dayNightMode,
                onDayNightModeChanged: (value) {
                  setState(() => _dayNightMode = value);
                },
                xunShouMode: _xunShouMode,
                onXunShouModeChanged: (value) {
                  setState(() => _xunShouMode = value);
                },
                guiRenVerse: _guiRenVerse,
                onGuiRenVerseChanged: (value) {
                  setState(() => _guiRenVerse = value);
                },
                monthGeneralMode: _monthGeneralMode,
                onMonthGeneralModeChanged: (value) {
                  setState(() => _monthGeneralMode = value);
                },
                manualMonthGeneral: _manualMonthGeneral,
                onManualMonthGeneralChanged: (value) {
                  setState(() => _manualMonthGeneral = value);
                },
                birthYearController: _birthYearController,
                showSanChuanOnTop: _showSanChuanOnTop,
                onShowSanChuanOnTopChanged: (value) {
                  setState(() => _showSanChuanOnTop = value);
                },
              ),
              const SizedBox(height: 16),
              const AntiqueDivider(),
              const SizedBox(height: 20),
              _buildCastSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCastSection() {
    switch (_selectedMethod) {
      case CastMethod.time:
        final now = DateTime.now();
        final lunar = Lunar.fromDate(now);
        return DaLiuRenTimeCastSection(
          yearGanZhi: '${lunar.getYearGan()}${lunar.getYearZhi()}',
          monthGanZhi: '${lunar.getMonthGan()}${lunar.getMonthZhi()}',
          dayGanZhi: '${lunar.getDayGan()}${lunar.getDayZhi()}',
          timeGanZhi: '${lunar.getTimeGan()}${lunar.getTimeZhi()}',
          isLoading: _isLoading,
          onCast: _isLoading ? null : _handleCast,
        );
      case CastMethod.reportNumber:
        return DaLiuRenReportNumberCastSection(
          controller: _numberController,
          isLoading: _isLoading,
          onCast: _isLoading ? null : _handleCast,
        );
      case CastMethod.manual:
        return DaLiuRenManualCastSection(
          tianGanOptions: _tianGan,
          diZhiOptions: _diZhi,
          yearGan: _yearGan,
          yearZhi: _yearZhi,
          onYearGanChanged: (value) => setState(() => _yearGan = value),
          onYearZhiChanged: (value) => setState(() => _yearZhi = value),
          monthGan: _monthGan,
          monthZhi: _monthZhi,
          onMonthGanChanged: (value) => setState(() => _monthGan = value),
          onMonthZhiChanged: (value) => setState(() => _monthZhi = value),
          dayGan: _dayGan,
          dayZhi: _dayZhi,
          onDayGanChanged: (value) => setState(() => _dayGan = value),
          onDayZhiChanged: (value) => setState(() => _dayZhi = value),
          hourGan: _hourGan,
          hourZhi: _hourZhi,
          onHourGanChanged: (value) => setState(() => _hourGan = value),
          onHourZhiChanged: (value) => setState(() => _hourZhi = value),
          isLoading: _isLoading,
          onCast: _isLoading ? null : _handleCast,
        );
      case CastMethod.computer:
        return DaLiuRenComputerCastSection(
          isLoading: _isLoading,
          onCast: _isLoading ? null : _handleCast,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
