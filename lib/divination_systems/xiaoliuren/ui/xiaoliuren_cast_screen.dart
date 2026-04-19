import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lunar/lunar.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/services/last_cast_method_service.dart';
import '../../../presentation/widgets/antique/antique.dart';
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
              _buildQuestionSection(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildMethodSelector()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPalaceModeSelector()),
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

  Widget _buildQuestionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('占问事项', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueTextField(
          controller: _questionController,
          hint: '请输入您想占问的事项...',
          maxLines: 2,
          minLines: 1,
        ),
      ],
    );
  }

  Widget _buildMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('起课方式', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueDropdown<CastMethod>(
          value: _selectedMethod,
          items: _availableMethods
              .map(
                (m) => AntiqueDropdownItem<CastMethod>(
                  value: m,
                  label: _methodLabels[m] ?? m.displayName,
                ),
              )
              .toList(),
          onChanged: (m) {
            if (m != null) {
              setState(() => _selectedMethod = m);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPalaceModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('盘式', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueDropdown<XiaoLiuRenPalaceMode>(
          value: _palaceMode,
          items: XiaoLiuRenPalaceMode.values
              .map(
                (m) => AntiqueDropdownItem<XiaoLiuRenPalaceMode>(
                  value: m,
                  label: m.displayName,
                ),
              )
              .toList(),
          onChanged: (m) {
            if (m != null) {
              setState(() => _palaceMode = m);
            }
          },
        ),
      ],
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

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '当前时辰'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Text(
            ganZhi,
            style: AppTextStyles.antiqueTitle.copyWith(
              fontSize: 15,
              color: AppColors.xiaoliurenColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lunarDate,
            style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
          ),
          const SizedBox(height: 6),
          Text(
            '取农历月数、农历日数、时支序数作为三段起数',
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberTripleBody({
    required String title,
    required List<String> labels,
    required List<TextEditingController> controllers,
    required String note,
  }) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(title: title),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Expanded(
                  child: _buildNumberField(
                    label: labels[i],
                    controller: controllers[i],
                  ),
                ),
                if (i < 2) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border.all(color: AppColors.danjin),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.antiqueBody,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '正整数',
              hintStyle: AppTextStyles.antiqueBody.copyWith(
                color: AppColors.qianhe,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
