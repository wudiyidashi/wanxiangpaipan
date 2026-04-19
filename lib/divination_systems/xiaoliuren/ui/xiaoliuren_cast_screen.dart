import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/services/last_cast_method_service.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../../../presentation/widgets/cast/cast_form_sections.dart';
import '../models/xiaoliuren_result.dart';
import '../viewmodels/xiaoliuren_viewmodel.dart';
import 'xiaoliuren_result_screen.dart';

class XiaoLiuRenCastScreen extends StatefulWidget {
  const XiaoLiuRenCastScreen({super.key});

  @override
  State<XiaoLiuRenCastScreen> createState() => _XiaoLiuRenCastScreenState();
}

class _XiaoLiuRenCastScreenState extends State<XiaoLiuRenCastScreen> {
  static const List<CastMethod> _availableMethods = [
    CastMethod.time,
    CastMethod.reportNumber,
    CastMethod.characterStroke,
  ];

  static const Map<CastMethod, String> _methodLabels = {
    CastMethod.time: '时间起课',
    CastMethod.reportNumber: '报数起课',
    CastMethod.characterStroke: '汉字笔画起',
  };

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _firstNumberController = TextEditingController();
  final TextEditingController _secondNumberController = TextEditingController();
  final TextEditingController _thirdNumberController = TextEditingController();
  final TextEditingController _firstStrokeController = TextEditingController();
  final TextEditingController _secondStrokeController = TextEditingController();
  final TextEditingController _thirdStrokeController = TextEditingController();

  CastMethod _selectedMethod = CastMethod.time;
  XiaoLiuRenPalaceMode _palaceMode = XiaoLiuRenPalaceMode.sixPalaces;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLastMethod();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _firstNumberController.dispose();
    _secondNumberController.dispose();
    _thirdNumberController.dispose();
    _firstStrokeController.dispose();
    _secondStrokeController.dispose();
    _thirdStrokeController.dispose();
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
      DivinationType.xiaoLiuRen,
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
      final viewModel = context.read<XiaoLiuRenViewModel>();
      switch (_selectedMethod) {
        case CastMethod.time:
          await viewModel.castByTime(
            palaceMode: _palaceMode,
            castTime: DateTime.now(),
          );
        case CastMethod.reportNumber:
          final first = int.tryParse(_firstNumberController.text.trim());
          final second = int.tryParse(_secondNumberController.text.trim());
          final third = int.tryParse(_thirdNumberController.text.trim());
          if (first == null || first <= 0) {
            _showError('请输入有效的数一');
            return;
          }
          if (second == null || second <= 0) {
            _showError('请输入有效的数二');
            return;
          }
          if (third == null || third <= 0) {
            _showError('请输入有效的数三');
            return;
          }
          await viewModel.castByReportNumbers(
            firstNumber: first,
            secondNumber: second,
            thirdNumber: third,
            palaceMode: _palaceMode,
            castTime: DateTime.now(),
          );
        case CastMethod.characterStroke:
          final first = int.tryParse(_firstStrokeController.text.trim());
          final second = int.tryParse(_secondStrokeController.text.trim());
          final third = int.tryParse(_thirdStrokeController.text.trim());
          if (first == null || first <= 0) {
            _showError('请输入有效的首字笔画');
            return;
          }
          if (second == null || second <= 0) {
            _showError('请输入有效的次字笔画');
            return;
          }
          if (third == null || third <= 0) {
            _showError('请输入有效的末字笔画');
            return;
          }
          await viewModel.castByCharacterStrokes(
            firstStroke: first,
            secondStroke: second,
            thirdStroke: third,
            palaceMode: _palaceMode,
            castTime: DateTime.now(),
          );
        default:
          _showError('小六壬不支持该起课方式');
          return;
      }

      if (viewModel.hasError) {
        _showError(viewModel.errorMessage ?? '起课失败');
        return;
      }
      if (!viewModel.hasResult) {
        _showError('起课失败');
        return;
      }

      final question = _questionController.text.trim();
      await viewModel.saveRecord(question: question.isEmpty ? null : question);
      final result = viewModel.result!;

      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => XiaoLiuRenResultScreen(result: result),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorDeep,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AntiqueScaffold(
      showCompass: true,
      appBar: const AntiqueAppBar(title: '小六壬起课'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CastQuestionInputSection(controller: _questionController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CastLabeledDropdown<CastMethod>(
                      label: '起课方式',
                      value: _selectedMethod,
                      items: _availableMethods
                          .map(
                            (method) => AntiqueDropdownItem<CastMethod>(
                              value: method,
                              label:
                                  _methodLabels[method] ?? method.displayName,
                            ),
                          )
                          .toList(),
                      onChanged: (method) {
                        if (method != null) {
                          setState(() => _selectedMethod = method);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CastLabeledDropdown<XiaoLiuRenPalaceMode>(
                      label: '盘式',
                      value: _palaceMode,
                      items: XiaoLiuRenPalaceMode.values
                          .map(
                            (mode) =>
                                AntiqueDropdownItem<XiaoLiuRenPalaceMode>(
                              value: mode,
                              label: mode.displayName,
                            ),
                          )
                          .toList(),
                      onChanged: (mode) {
                        if (mode != null) {
                          setState(() => _palaceMode = mode);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const AntiqueDivider(),
              const SizedBox(height: 20),
              _buildMethodBody(),
              const SizedBox(height: 24),
              AntiqueButton(
                label: _isLoading ? '起课中...' : '起课',
                onPressed: _isLoading ? null : _handleCast,
                variant: AntiqueButtonVariant.primary,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodBody() {
    switch (_selectedMethod) {
      case CastMethod.time:
        return _buildTimeBody();
      case CastMethod.reportNumber:
        return _buildNumberTripleBody(
          title: '报三数',
          labels: const ['数一', '数二', '数三'],
          controllers: [
            _firstNumberController,
            _secondNumberController,
            _thirdNumberController,
          ],
          note: '大安起第一数，首位上起第二数，次位上起第三数',
        );
      case CastMethod.characterStroke:
        return _buildNumberTripleBody(
          title: '三段笔画',
          labels: const ['首字笔画', '次字笔画', '末字笔画'],
          controllers: [
            _firstStrokeController,
            _secondStrokeController,
            _thirdStrokeController,
          ],
          note: '请先人工数好三段笔画再输入；当前底层不做自动汉字转笔画',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTimeBody() {
    final now = DateTime.now();
    final lunar = Lunar.fromDate(now);
    final ganZhi = '${lunar.getYearInGanZhi()}年 '
        '${lunar.getMonthInGanZhi()}月 '
        '${lunar.getDayInGanZhi()}日 '
        '${lunar.getTimeInGanZhi()}时';
    final lunarDate = '农历${lunar.getMonthInChinese()}月'
        '${lunar.getDayInChinese()} ${lunar.getTimeZhi()}时';

    return CastTimeSummaryCard(
      ganZhiText: ganZhi,
      lunarText: lunarDate,
      note: '取农历月数、农历日数、时支序数作为三段起数',
      accentColor: AppColors.xiaoliurenColor,
    );
  }

  Widget _buildNumberTripleBody({
    required String title,
    required List<String> labels,
    required List<TextEditingController> controllers,
    required String note,
  }) {
    return CastNumberTripleCard(
      title: title,
      labels: labels,
      controllers: controllers,
      note: note,
    );
  }
}
