import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lunar/lunar.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/services/last_cast_method_service.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../viewmodels/meihua_viewmodel.dart';
import 'meihua_result_screen.dart';

class MeiHuaCastScreen extends StatefulWidget {
  const MeiHuaCastScreen({super.key});

  @override
  State<MeiHuaCastScreen> createState() => _MeiHuaCastScreenState();
}

class _MeiHuaCastScreenState extends State<MeiHuaCastScreen> {
  static const List<CastMethod> _availableMethods = [
    CastMethod.time,
    CastMethod.number,
    CastMethod.manual,
  ];

  static const Map<CastMethod, String> _methodLabels = {
    CastMethod.time: '时间起卦',
    CastMethod.number: '数字起卦',
    CastMethod.manual: '手动输入',
  };

  static const List<String> _trigramNames = [
    '乾',
    '兑',
    '离',
    '震',
    '巽',
    '坎',
    '艮',
    '坤',
  ];

  static const Map<int, String> _movingLineLabels = {
    1: '初爻',
    2: '二爻',
    3: '三爻',
    4: '四爻',
    5: '五爻',
    6: '上爻',
  };

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _upperNumberController = TextEditingController();
  final TextEditingController _lowerNumberController = TextEditingController();

  CastMethod _selectedMethod = CastMethod.time;
  String _manualUpperTrigram = '乾';
  String _manualLowerTrigram = '坤';
  int _manualMovingLine = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLastMethod();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _upperNumberController.dispose();
    _lowerNumberController.dispose();
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
      DivinationType.meiHua,
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
      final viewModel = context.read<MeiHuaViewModel>();
      switch (_selectedMethod) {
        case CastMethod.time:
          await viewModel.castByTime(castTime: DateTime.now());
        case CastMethod.number:
          final upper = int.tryParse(_upperNumberController.text.trim());
          final lower = int.tryParse(_lowerNumberController.text.trim());
          if (upper == null || upper <= 0) {
            _showError('请输入有效的上卦数字');
            return;
          }
          if (lower == null || lower <= 0) {
            _showError('请输入有效的下卦数字');
            return;
          }
          await viewModel.castByNumbers(
            upperNumber: upper,
            lowerNumber: lower,
            castTime: DateTime.now(),
          );
        case CastMethod.manual:
          await viewModel.castByManual(
            upperTrigram: _manualUpperTrigram,
            lowerTrigram: _manualLowerTrigram,
            movingLine: _manualMovingLine,
            castTime: DateTime.now(),
          );
        default:
          _showError('梅花不支持该起卦方式');
          return;
      }

      if (viewModel.hasError) {
        _showError(viewModel.errorMessage ?? '起卦失败');
        return;
      }
      if (!viewModel.hasResult) {
        _showError('起卦失败');
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
          builder: (_) => MeiHuaResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showError('起卦失败: $e');
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
      appBar: const AntiqueAppBar(title: '梅花易数起卦'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuestionSection(),
              const SizedBox(height: 16),
              _buildMethodSelector(),
              const SizedBox(height: 16),
              const AntiqueDivider(),
              const SizedBox(height: 20),
              _buildMethodBody(),
              const SizedBox(height: 24),
              AntiqueButton(
                label: _isLoading ? '起卦中...' : '起卦',
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
        const Text('起卦方式', style: AppTextStyles.antiqueLabel),
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

  Widget _buildMethodBody() {
    switch (_selectedMethod) {
      case CastMethod.time:
        return _buildTimeBody();
      case CastMethod.number:
        return _buildNumberBody();
      case CastMethod.manual:
        return _buildManualBody();
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
    final lunarText =
        '农历${lunar.getMonthInChinese()}月${lunar.getDayInChinese()} ${lunar.getTimeZhi()}时';

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
              color: AppColors.meihuaColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lunarText,
            style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
          ),
          const SizedBox(height: 6),
          Text(
            '取农历年支数、月数、日数、时支数推上下卦与动爻',
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberBody() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '报两个数'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: '上卦数',
                  controller: _upperNumberController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  label: '下卦数',
                  controller: _lowerNumberController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '上数取上卦，下数取下卦，两数之和取动爻',
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
              hintText: '请输入正整数',
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

  Widget _buildManualBody() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AntiqueSectionTitle(title: '指定卦与动爻'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTrigramDropdown(
                  label: '上卦',
                  value: _manualUpperTrigram,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _manualUpperTrigram = v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrigramDropdown(
                  label: '下卦',
                  value: _manualLowerTrigram,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _manualLowerTrigram = v);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMovingLineDropdown(),
          const SizedBox(height: 8),
          Text(
            '动爻决定体用：动爻在 1–3 爻则上为体下为用；在 4–6 爻则反之',
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTrigramDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 4),
        AntiqueDropdown<String>(
          value: value,
          items: _trigramNames
              .map((n) => AntiqueDropdownItem<String>(value: n, label: n))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMovingLineDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('动爻', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 4),
        AntiqueDropdown<int>(
          value: _manualMovingLine,
          items: _movingLineLabels.entries
              .map(
                (e) => AntiqueDropdownItem<int>(
                  value: e.key,
                  label: e.value,
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _manualMovingLine = v);
            }
          },
        ),
      ],
    );
  }
}
