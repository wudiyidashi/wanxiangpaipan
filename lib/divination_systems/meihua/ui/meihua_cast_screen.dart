import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/services/last_cast_method_service.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../../../presentation/widgets/cast/cast_form_sections.dart';
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
              CastQuestionInputSection(controller: _questionController),
              const SizedBox(height: 16),
              CastLabeledDropdown<CastMethod>(
                label: '起卦方式',
                value: _selectedMethod,
                items: _availableMethods
                    .map(
                      (method) => AntiqueDropdownItem<CastMethod>(
                        value: method,
                        label: _methodLabels[method] ?? method.displayName,
                      ),
                    )
                    .toList(),
                onChanged: (method) {
                  if (method != null) {
                    setState(() => _selectedMethod = method);
                  }
                },
              ),
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

    return CastTimeSummaryCard(
      ganZhiText: ganZhi,
      lunarText: lunarText,
      note: '取农历年支数、月数、日数、时支数推上下卦与动爻',
      accentColor: AppColors.meihuaColor,
    );
  }

  Widget _buildNumberBody() {
    return CastNumberPairCard(
      title: '报两个数',
      firstLabel: '上卦数',
      firstController: _upperNumberController,
      secondLabel: '下卦数',
      secondController: _lowerNumberController,
      note: '上数取上卦，下数取下卦，两数之和取动爻',
      hintText: '请输入正整数',
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
                child: CastLabeledDropdown<String>(
                  label: '上卦',
                  value: _manualUpperTrigram,
                  items: _trigramNames
                      .map(
                        (name) => AntiqueDropdownItem<String>(
                          value: name,
                          label: name,
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _manualUpperTrigram = v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CastLabeledDropdown<String>(
                  label: '下卦',
                  value: _manualLowerTrigram,
                  items: _trigramNames
                      .map(
                        (name) => AntiqueDropdownItem<String>(
                          value: name,
                          label: name,
                        ),
                      )
                      .toList(),
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
          CastLabeledDropdown<int>(
            label: '动爻',
            value: _manualMovingLine,
            items: _movingLineLabels.entries
                .map(
                  (entry) => AntiqueDropdownItem<int>(
                    value: entry.key,
                    label: entry.value,
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _manualMovingLine = value);
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            '动爻决定体用：动爻在 1–3 爻则上为体下为用；在 4–6 爻则反之',
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
