import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lunar/lunar.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../domain/services/last_cast_method_service.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../daliuren_system.dart';
import '../models/daliuren_result.dart';
import '../models/pan_params.dart';
import 'daliuren_result_screen.dart';

/// 大六壬统一起课界面（仿古风）
///
/// 将四种起课方式（正时、报数、指定干支、随机）合并到一个页面，
/// 通过下拉选择切换，风格为新中式仿古风。
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

  @override
  void dispose() {
    _questionController.dispose();
    _numberController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  Future<void> _handleCast() async {
    if (_isLoading) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final system = DaLiuRenSystem();
      DivinationResult result;
      final params = _buildPanParams();

      switch (_selectedMethod) {
        case CastMethod.time:
          result = await system.cast(
            method: CastMethod.time,
            input: {'params': params.toJson()},
            castTime: DateTime.now(),
          );
        case CastMethod.reportNumber:
          final number = int.tryParse(_numberController.text.trim());
          if (number == null) {
            _showError('请输入有效的数字');
            setState(() => _isLoading = false);
            return;
          }
          result = await system.cast(
            method: CastMethod.reportNumber,
            input: {
              'number': number,
              'params': params.toJson(),
            },
            castTime: DateTime.now(),
          );
        case CastMethod.manual:
          result = await system.cast(
            method: CastMethod.manual,
            input: {
              'yearGanZhi': '$_yearGan$_yearZhi',
              'monthGanZhi': '$_monthGan$_monthZhi',
              'dayGanZhi': '$_dayGan$_dayZhi',
              'hourGanZhi': '$_hourGan$_hourZhi',
              'params': params.toJson(),
            },
          );
        case CastMethod.computer:
          result = await system.cast(
            method: CastMethod.computer,
            input: {'params': params.toJson()},
            castTime: DateTime.now(),
          );
        default:
          throw UnsupportedError('不支持的起课方式');
      }

      if (!mounted) {
        return;
      }

      try {
        final repository = context.read<DivinationRepository>();
        await repository.saveRecord(result);

        final question = _questionController.text.trim();
        if (question.isNotEmpty) {
          await repository.saveEncryptedFieldsBatch({
            'question_${result.id}': question,
          });
        }
      } catch (saveError) {
        debugPrint('DLR: failed to save record: $saveError');
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              DaLiuRenResultScreen(result: result as DaLiuRenResult),
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
              _buildQuestionSection(),
              const SizedBox(height: 16),
              _buildMethodSelector(),
              const SizedBox(height: 16),
              _buildPanParamsSection(),
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

  Widget _buildQuestionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('占问事项', style: AppTextStyles.antiqueLabel),
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
        Text('起课方式', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueDropdown<CastMethod>(
          value: _selectedMethod,
          items: _availableMethods
              .map(
                (method) => AntiqueDropdownItem<CastMethod>(
                  value: method,
                  label: _methodNames[method] ?? method.displayName,
                ),
              )
              .toList(),
          onChanged: (method) {
            if (method != null) {
              setState(() => _selectedMethod = method);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPanParamsSection() {
    final forceManualMonthGeneral = _selectedMethod == CastMethod.manual;
    final effectiveMonthGeneralMode = forceManualMonthGeneral
        ? DaLiuRenMonthGeneralMode.manual
        : _monthGeneralMode;

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(title: '排盘参数'),
          const AntiqueDivider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  '昼夜',
                  _dayNightMode.id,
                  DaLiuRenDayNightMode.values.map((e) => e.id).toList(),
                  (value) {
                    if (value != null) {
                      setState(() {
                        _dayNightMode = DaLiuRenDayNightMode.fromId(value);
                      });
                    }
                  },
                  labels: const {
                    'auto': '自动',
                    'day': '昼贵',
                    'night': '夜贵',
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  '旬位',
                  _xunShouMode.id,
                  DaLiuRenXunShouMode.values.map((e) => e.id).toList(),
                  (value) {
                    if (value != null) {
                      setState(() {
                        _xunShouMode = DaLiuRenXunShouMode.fromId(value);
                      });
                    }
                  },
                  labels: const {
                    'day': '日柱旬遁干',
                    'hour': '时柱旬遁干',
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  '贵人口诀',
                  _guiRenVerse.id,
                  DaLiuRenGuiRenVerse.values.map((e) => e.id).toList(),
                  (value) {
                    if (value != null) {
                      setState(() {
                        _guiRenVerse = DaLiuRenGuiRenVerse.fromId(value);
                      });
                    }
                  },
                  labels: const {
                    'classic': '甲戊庚牛羊',
                    'jiaDayAlt': '甲羊戊庚牛',
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: forceManualMonthGeneral
                    ? _buildDropdown(
                        '月将',
                        _manualMonthGeneral,
                        _diZhi,
                        (value) {
                          if (value != null) {
                            setState(() => _manualMonthGeneral = value);
                          }
                        },
                      )
                    : _buildDropdown(
                        '月将模式',
                        effectiveMonthGeneralMode.id,
                        DaLiuRenMonthGeneralMode.values
                            .map((e) => e.id)
                            .toList(),
                        (value) {
                          if (value != null) {
                            setState(() {
                              _monthGeneralMode =
                                  DaLiuRenMonthGeneralMode.fromId(value);
                            });
                          }
                        },
                        labels: const {
                          'auto': '自动',
                          'manual': '手动',
                        },
                      ),
              ),
            ],
          ),
          if (!forceManualMonthGeneral &&
              effectiveMonthGeneralMode == DaLiuRenMonthGeneralMode.manual) ...[
            const SizedBox(height: 12),
            _buildDropdown(
              '手动月将',
              _manualMonthGeneral,
              _diZhi,
              (value) {
                if (value != null) {
                  setState(() => _manualMonthGeneral = value);
                }
              },
            ),
          ],
          const SizedBox(height: 12),
          Text('生年', style: AppTextStyles.antiqueLabel),
          const SizedBox(height: 6),
          AntiqueTextField(
            controller: _birthYearController,
            hint: '本命占可填，时事占可留空',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _showSanChuanOnTop,
                activeColor: AppColors.zhusha,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _showSanChuanOnTop = value);
                  }
                },
              ),
              const SizedBox(width: 4),
              Text('三传显示在上', style: AppTextStyles.antiqueLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCastSection() {
    switch (_selectedMethod) {
      case CastMethod.time:
        return _buildTimeCastSection();
      case CastMethod.reportNumber:
        return _buildReportNumberCastSection();
      case CastMethod.manual:
        return _buildManualCastSection();
      case CastMethod.computer:
        return _buildComputerCastSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTimeCastSection() {
    final now = DateTime.now();
    final lunar = Lunar.fromDate(now);
    final yearGanZhi = '${lunar.getYearGan()}${lunar.getYearZhi()}';
    final monthGanZhi = '${lunar.getMonthGan()}${lunar.getMonthZhi()}';
    final dayGanZhi = '${lunar.getDayGan()}${lunar.getDayZhi()}';
    final timeGanZhi = '${lunar.getTimeGan()}${lunar.getTimeZhi()}';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            border: Border.all(color: AppColors.danjin.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                '当前干支',
                style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGanZhiItem('年', yearGanZhi),
                  _buildGanZhiItem('月', monthGanZhi),
                  _buildGanZhiItem('日', dayGanZhi),
                  _buildGanZhiItem('时', timeGanZhi),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AntiqueButton(
          label: _isLoading ? '起课中...' : '起课',
          onPressed: _isLoading ? null : _handleCast,
          variant: AntiqueButtonVariant.primary,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildGanZhiItem(String label, String ganZhi) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 4),
        Text(ganZhi, style: AppTextStyles.antiqueTitle),
      ],
    );
  }

  Widget _buildReportNumberCastSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border.all(color: AppColors.danjin),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: _numberController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.antiqueBody,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '请输入任意数字',
              hintStyle: AppTextStyles.antiqueBody.copyWith(
                color: AppColors.qianhe,
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '输入任意数字，除12取余映射地支',
          style: AppTextStyles.antiqueLabel,
        ),
        const SizedBox(height: 24),
        AntiqueButton(
          label: _isLoading ? '起课中...' : '起课',
          onPressed: _isLoading ? null : _handleCast,
          variant: AntiqueButtonVariant.primary,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildManualCastSection() {
    return Column(
      children: [
        _buildPillarSelectorRow(
          label: '年柱',
          gan: _yearGan,
          zhi: _yearZhi,
          onGanChanged: (value) => setState(() => _yearGan = value),
          onZhiChanged: (value) => setState(() => _yearZhi = value),
        ),
        const SizedBox(height: 12),
        _buildPillarSelectorRow(
          label: '月柱',
          gan: _monthGan,
          zhi: _monthZhi,
          onGanChanged: (value) => setState(() => _monthGan = value),
          onZhiChanged: (value) => setState(() => _monthZhi = value),
        ),
        const SizedBox(height: 12),
        _buildPillarSelectorRow(
          label: '日柱',
          gan: _dayGan,
          zhi: _dayZhi,
          onGanChanged: (value) => setState(() => _dayGan = value),
          onZhiChanged: (value) => setState(() => _dayZhi = value),
        ),
        const SizedBox(height: 12),
        _buildPillarSelectorRow(
          label: '时柱',
          gan: _hourGan,
          zhi: _hourZhi,
          onGanChanged: (value) => setState(() => _hourGan = value),
          onZhiChanged: (value) => setState(() => _hourZhi = value),
        ),
        const SizedBox(height: 8),
        Text(
          '指定干支模式按输入四柱直接起课，月将请在上方“排盘参数”中明确指定。',
          style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 24),
        AntiqueButton(
          label: _isLoading ? '起课中...' : '起课',
          onPressed: _isLoading ? null : _handleCast,
          variant: AntiqueButtonVariant.primary,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    Map<String, String>? labels,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 4),
        AntiqueDropdown<String>(
          value: value,
          items: items
              .map(
                (item) => AntiqueDropdownItem<String>(
                  value: item,
                  label: labels?[item] ?? item,
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPillarSelectorRow({
    required String label,
    required String gan,
    required String zhi,
    required ValueChanged<String> onGanChanged,
    required ValueChanged<String> onZhiChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label, style: AppTextStyles.antiqueLabel),
        ),
        Expanded(
          child: _buildDropdown(
            '天干',
            gan,
            _tianGan,
            (value) {
              if (value != null) {
                onGanChanged(value);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDropdown(
            '地支',
            zhi,
            _diZhi,
            (value) {
              if (value != null) {
                onZhiChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComputerCastSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            border: Border.all(color: AppColors.danjin.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                Icons.casino_outlined,
                size: 48,
                color: AppColors.zhusha.withOpacity(0.7),
              ),
              const SizedBox(height: 12),
              Text(
                '系统随机取地支作为占时',
                style: AppTextStyles.antiqueBody.copyWith(
                  color: AppColors.guhe,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AntiqueButton(
          label: _isLoading ? '起课中...' : '起课',
          onPressed: _isLoading ? null : _handleCast,
          variant: AntiqueButtonVariant.primary,
          fullWidth: true,
        ),
      ],
    );
  }
}
