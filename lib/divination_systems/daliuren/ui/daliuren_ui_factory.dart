import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lunar/lunar.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../domain/services/last_cast_method_service.dart';
import '../../../domain/services/shared/tiangan_dizhi_service.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/widgets/ai_analysis_widget.dart';
import '../../../presentation/widgets/extended_info_section.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../../../presentation/widgets/history_record_card.dart';
import '../daliuren_system.dart';
import '../models/daliuren_result.dart';
import '../models/chuan.dart';
import '../models/pan_params.dart';

/// 大六壬 UI 工厂
///
/// 实现 DivinationUIFactory 接口，提供大六壬特定的 UI 组件。
class DaLiuRenUIFactory implements DivinationUIFactory {
  @override
  DivinationType get systemType => DivinationType.daLiuRen;

  @override
  Widget buildCastScreen(CastMethod method) {
    // 统一起课页面，内部通过下拉选择切换方式
    return const _DaLiuRenCastScreen();
  }

  @override
  Widget buildResultScreen(DivinationResult result) {
    if (result is! DaLiuRenResult) {
      throw ArgumentError('结果类型必须是 DaLiuRenResult，实际类型: ${result.runtimeType}');
    }
    return _DaLiuRenResultScreen(result: result);
  }

  @override
  Widget buildHistoryCard(DivinationResult result) =>
      HistoryRecordCard(result: result);

  @override
  IconData? getSystemIcon() {
    // 使用太阳图标代表大六壬（月将与太阳位置相关）
    return Icons.wb_sunny;
  }

  @override
  Color? getSystemColor() {
    // 使用紫檀色作为大六壬的主题色
    return AppColors.daliurenColor;
  }
}

// ==================== 统一起课界面 ====================

/// 大六壬统一起课界面（仿古风）
///
/// 将四种起课方式（正时、报数、指定干支、随机）合并到一个页面，
/// 通过下拉选择切换，风格为新中式仿古风。
class _DaLiuRenCastScreen extends StatefulWidget {
  const _DaLiuRenCastScreen();

  @override
  State<_DaLiuRenCastScreen> createState() => _DaLiuRenCastScreenState();
}

class _DaLiuRenCastScreenState extends State<_DaLiuRenCastScreen> {
  // 支持的起课方式
  static const List<CastMethod> _availableMethods = [
    CastMethod.time,
    CastMethod.reportNumber,
    CastMethod.manual,
    CastMethod.computer,
  ];

  // 起课方式的中文显示名
  static const Map<CastMethod, String> _methodNames = {
    CastMethod.time: '正时起课',
    CastMethod.reportNumber: '报数起课',
    CastMethod.manual: '指定干支',
    CastMethod.computer: '随机起课',
  };

  CastMethod _selectedMethod = CastMethod.time;
  bool _isLoading = false;
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _birthYearController = TextEditingController();

  // 手动输入相关
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

  // ==================== 起课逻辑 ====================

  Future<void> _handleCast() async {
    if (_isLoading) return;
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

      if (!mounted) return;

      // Save to repository so the record appears in history
      try {
        final repository = context.read<DivinationRepository>();
        await repository.saveRecord(result);

        // Save question as encrypted field if provided
        final question = _questionController.text.trim();
        if (question.isNotEmpty) {
          await repository.saveEncryptedFieldsBatch({
            'question_${result.id}': question,
          });
        }
      } catch (saveError) {
        // Non-blocking: cast succeeded; just log the failure
        debugPrint('DLR: failed to save record: $saveError');
      }

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              _DaLiuRenResultScreen(result: result as DaLiuRenResult),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('起课失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  // ==================== UI 构建 ====================

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

  /// 占问事项输入
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

  /// 起课方式选择器
  Widget _buildMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('起课方式', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueDropdown<CastMethod>(
          value: _selectedMethod,
          items: _availableMethods
              .map((method) => AntiqueDropdownItem<CastMethod>(
                    value: method,
                    label: _methodNames[method] ?? method.displayName,
                  ))
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

  /// 动态起课区域
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

  /// 正时起课区域
  Widget _buildTimeCastSection() {
    final now = DateTime.now();
    final lunar = Lunar.fromDate(now);
    final yearGanZhi = '${lunar.getYearGan()}${lunar.getYearZhi()}';
    final monthGanZhi = '${lunar.getMonthGan()}${lunar.getMonthZhi()}';
    final dayGanZhi = '${lunar.getDayGan()}${lunar.getDayZhi()}';
    final timeGanZhi = '${lunar.getTimeGan()}${lunar.getTimeZhi()}';

    return Column(
      children: [
        // 当前干支时间信息
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

  /// 干支显示小组件
  Widget _buildGanZhiItem(String label, String ganZhi) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.antiqueLabel,
        ),
        const SizedBox(height: 4),
        Text(
          ganZhi,
          style: AppTextStyles.antiqueTitle,
        ),
      ],
    );
  }

  /// 报数起课区域
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

  /// 指定干支区域
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

  /// 仿古风下拉选择器（字符串专用）
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

  /// 随机起课区域
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

/// 大六壬结果展示界面（仿古风）
class _DaLiuRenResultScreen extends StatelessWidget {
  final DaLiuRenResult result;

  const _DaLiuRenResultScreen({required this.result});

  @override
  Widget build(BuildContext context) {
    final upperSection = result.panParams.showSanChuanOnTop
        ? _buildSanChuanSection()
        : _buildSiKeSection();
    final lowerSection = result.panParams.showSanChuanOnTop
        ? _buildSiKeSection()
        : _buildSanChuanSection();
    final questionFuture = _loadQuestion(context);

    return FutureBuilder<String?>(
      future: questionFuture,
      builder: (context, snapshot) {
        final question = (snapshot.data ?? '').trim();
        return AntiqueScaffold(
          appBar: const AntiqueAppBar(title: '大六壬排盘结果'),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExtendedInfoSection(
                    castTime: result.castTime,
                    lunarInfo: result.lunarInfo,
                    liuShen: const [],
                  ),
                  const SizedBox(height: 16),
                  _buildPanParamsSummarySection(question),
                  const SizedBox(height: 16),
                  upperSection,
                  const SizedBox(height: 16),
                  lowerSection,
                  const SizedBox(height: 16),

                  // 天盘
                  _buildTianPanSection(),
                  const SizedBox(height: 16),

                  // 神将
                  _buildShenJiangSection(),
                  const SizedBox(height: 16),

                  // 神煞
                  _buildShenShaSection(),
                  const SizedBox(height: 16),

                  // AI 分析组件
                  AIAnalysisWidget(
                    result: result,
                    question: question.isEmpty ? null : question,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== 1. 基本信息 → 使用统一的 ExtendedInfoSection ====================

  Widget _buildPanParamsSummarySection(String question) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(title: '排盘参数'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          _buildAntiqueInfoRow('占问', question.isEmpty ? '未设置' : question),
          _buildAntiqueInfoRow('干支', _buildGanZhiText()),
          _buildAntiqueInfoRow('遁干', _buildDunGanText()),
          _buildAntiqueInfoRow('月将', _buildYueJiangText()),
          _buildAntiqueInfoRow('贵神', _buildGuiRenText()),
        ],
      ),
    );
  }

  Future<String?> _loadQuestion(BuildContext context) {
    final repository = _tryReadRepository(context);
    final fallbackQuestion =
        result.questionId.isNotEmpty ? result.questionId : null;
    return repository?.readEncryptedField('question_${result.id}') ??
        Future<String?>.value(fallbackQuestion);
  }

  DivinationRepository? _tryReadRepository(BuildContext context) {
    try {
      return context.read<DivinationRepository>();
    } catch (_) {
      return null;
    }
  }

  String _buildGanZhiText() {
    final hourGanZhi = result.lunarInfo.hourGanZhi ?? result.shiZhi;
    return '${result.lunarInfo.yearGanZhi}年　'
        '${result.lunarInfo.monthGanZhi}月　'
        '${result.lunarInfo.riGanZhi}日　'
        '$hourGanZhi时';
  }

  String _buildDunGanText() {
    final xunTarget = result.panParams.xunShouMode == DaLiuRenXunShouMode.hour
        ? (result.lunarInfo.hourGanZhi ?? result.lunarInfo.riGanZhi)
        : result.lunarInfo.riGanZhi;
    final xunName = _resolveXunName(xunTarget);
    final kongWang = result.lunarInfo.kongWang.join();
    return '${result.panParams.xunShouModeLabel} $xunName旬 $kongWang空';
  }

  String _buildYueJiangText() {
    final modeLabel = result.panParams.usesManualMonthGeneral ? '手动指定' : '系统选将';
    return '${result.tianPan.yueJiang} 将($modeLabel)';
  }

  String _buildGuiRenText() {
    final guiRenType = result.shenJiangConfig.isYangGui ? '昼贵' : '夜贵';
    return '$guiRenType （${result.panParams.guiRenVerseLabel}）';
  }

  String _resolveXunName(String ganZhi) {
    final index = TianGanDiZhiService.getGanZhiIndex(ganZhi);
    if (index == -1) {
      return '';
    }
    final xunStartIndex = (index ~/ 10) * 10;
    return TianGanDiZhiService.getGanZhi(xunStartIndex);
  }

  // ==================== 2. 四课（传统 2x2 格子） ====================

  Widget _buildSiKeSection() {
    // 从右到左传统顺序：一课 → 二课 → 三课 → 四课
    final keList = [
      result.siKe.ke4,
      result.siKe.ke3,
      result.siKe.ke2,
      result.siKe.ke1,
    ];
    final keLabels = ['四课', '三课', '二课', '一课'];

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(title: '四课'),
          const AntiqueDivider(),
          const SizedBox(height: 8),
          // 2x2 格子表格
          Table(
            border: TableBorder.all(
              color: AppColors.danjin.withOpacity(0.5),
              width: 1,
            ),
            children: [
              // 标题行
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.danjin.withOpacity(0.1),
                ),
                children: keLabels.map((label) {
                  return TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Center(
                        child: Text(
                          label,
                          style: AppTextStyles.antiqueBody.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.guhe,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // 上神行
              TableRow(
                children: keList.map((ke) {
                  return TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          ke.shangShen,
                          // 域色：贼课(zhusha)/正常(xuanse) 动态区分
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                ke.hasKe ? AppColors.zhusha : AppColors.xuanse,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // 下神行
              TableRow(
                children: keList.map((ke) {
                  return TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          ke.xiaShen,
                          style: AppTextStyles.antiqueTitle.copyWith(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 五行关系
          Row(
            children: keList.map((ke) {
              return Expanded(
                child: Center(
                  child: Text(
                    ke.wuXingRelation ?? '',
                    // 域色：贼课(zhusha)/比用(biyongBlue)/普通(guhe) 三态语义色
                    style: TextStyle(
                      fontSize: 11,
                      color: ke.isZeiKe
                          ? AppColors.zhusha
                          : ke.isBiYong
                              ? AppColors.biyongBlue
                              : AppColors.guhe,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== 3. 三传（横排三圆） ====================

  Widget _buildSanChuanSection() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(title: '三传'),
          const AntiqueDivider(),
          const SizedBox(height: 12),
          // 三个圆 + 箭头
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChuanCircle('初传', result.sanChuan.chuChuan),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child:
                    Icon(Icons.arrow_forward, size: 18, color: AppColors.guhe),
              ),
              _buildChuanCircle('中传', result.sanChuan.zhongChuan),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child:
                    Icon(Icons.arrow_forward, size: 18, color: AppColors.guhe),
              ),
              _buildChuanCircle('末传', result.sanChuan.moChuan),
            ],
          ),
          const SizedBox(height: 12),
          // 课体 badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.zhusha.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.zhusha.withOpacity(0.3)),
              ),
              child: Text(
                '${result.keTypeName}课',
                // 域色：课体标识，朱砂语义色
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.zhusha,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (result.sanChuan.keTypeExplanation != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                result.sanChuan.keTypeExplanation!,
                style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChuanCircle(String label, Chuan chuan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 6),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.zhusha, AppColors.zhushaLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.zhusha.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                chuan.diZhi,
                // 域色：三传圆圈白字，渐变背景下保持对比
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chuan.liuQin,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            chuan.chengShenName,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
          ),
          if (chuan.isKongWang) ...[
            const SizedBox(height: 2),
            Text(
              '空亡',
              style: AppTextStyles.antiqueLabel.copyWith(
                fontSize: 11,
                color: AppColors.zhusha,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== 4. 天盘 ====================

  Widget _buildTianPanSection() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(title: '天盘'),
          const AntiqueDivider(),
          const SizedBox(height: 4),
          _buildAntiqueInfoRow('月将',
              '${result.tianPan.yueJiang}（${result.tianPan.yueJiangName}）'),
          _buildAntiqueInfoRow('描述', result.tianPan.yueJiangDescription),
          const SizedBox(height: 12),
          _buildGridSection(
            items: result.tianPan.fullDisplay
                .map((item) => _buildGridItem(
                      title: '${item['地盘']}宫',
                      primary: item['天盘'] ?? '',
                      secondary: '天地盘',
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ==================== 5. 神将 ====================

  Widget _buildShenJiangSection() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(title: '十二神将'),
          const AntiqueDivider(),
          const SizedBox(height: 4),
          _buildAntiqueInfoRow('贵人',
              '${result.shenJiangConfig.guiRenPosition}（${result.shenJiangConfig.guiRenTypeDescription}）'),
          _buildAntiqueInfoRow(
              '布神', result.shenJiangConfig.directionDescription),
          const SizedBox(height: 12),
          _buildGridSection(
            items: result.shenJiangConfig.positions
                .map((pos) => _buildGridItem(
                      title: pos.name,
                      primary: pos.diZhi,
                      secondary: '乘${pos.tianPanZhi}',
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ==================== 6. 神煞 ====================

  Widget _buildShenShaSection() {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AntiqueSectionTitle(title: '神煞'),
          const AntiqueDivider(),
          if (result.shenShaList.jiShen.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '吉神',
              // 域色：吉神绿语义色
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.jishenGreen,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.shenShaList.jiShen.map((shenSha) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.jishenGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.jishenGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    shenSha.displayText,
                    // 域色：吉神绿语义色
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.jishenGreen),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (result.shenShaList.xiongShen.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '凶神',
              // 域色：凶神朱砂语义色
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.zhusha,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.shenShaList.xiongShen.map((shenSha) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.zhusha.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.zhusha.withOpacity(0.3)),
                  ),
                  child: Text(
                    shenSha.displayText,
                    // 域色：凶神朱砂语义色
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.zhusha),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== 辅助方法 ====================

  Widget _buildAntiqueInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: AppTextStyles.antiqueBody.copyWith(
                color: AppColors.guhe,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.antiqueBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridSection({required List<Widget> items}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items,
    );
  }

  Widget _buildGridItem({
    required String title,
    required String primary,
    required String secondary,
  }) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danjin.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            primary,
            style: AppTextStyles.antiqueTitle.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            secondary,
            style: AppTextStyles.antiqueLabel.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
