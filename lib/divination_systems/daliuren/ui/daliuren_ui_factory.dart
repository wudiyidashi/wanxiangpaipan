import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lunar/lunar.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/widgets/ai_analysis_widget.dart';
import '../../../presentation/widgets/extended_info_section.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../../../presentation/widgets/history_record_card.dart';
import '../daliuren_system.dart';
import '../models/daliuren_result.dart';
import '../models/chuan.dart';

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
  Widget buildHistoryCard(DivinationResult result) => HistoryRecordCard(result: result);

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

  // 手动输入相关
  static const List<String> _tianGan = [
    '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
  ];
  static const List<String> _diZhi = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
  ];

  String _riGan = '甲';
  String _riZhi = '子';
  String _shiZhi = '子';
  String _yueJian = '寅';

  @override
  void dispose() {
    _questionController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  // ==================== 起课逻辑 ====================

  Future<void> _handleCast() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final system = DaLiuRenSystem();
      DivinationResult result;

      switch (_selectedMethod) {
        case CastMethod.time:
          result = await system.cast(
            method: CastMethod.time,
            input: {},
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
            input: {'number': number},
            castTime: DateTime.now(),
          );
        case CastMethod.manual:
          result = await system.cast(
            method: CastMethod.manual,
            input: {
              'riGan': _riGan,
              'riZhi': _riZhi,
              'shiZhi': _shiZhi,
              'yueJian': _yueJian,
            },
          );
        case CastMethod.computer:
          result = await system.cast(
            method: CastMethod.computer,
            input: {},
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
        // 日干 / 日支
        Row(
          children: [
            Expanded(child: _buildDropdown('日干', _riGan, _tianGan, (v) {
              setState(() => _riGan = v!);
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown('日支', _riZhi, _diZhi, (v) {
              setState(() => _riZhi = v!);
            })),
          ],
        ),
        const SizedBox(height: 12),
        // 时支 / 月建
        Row(
          children: [
            Expanded(child: _buildDropdown('时支', _shiZhi, _diZhi, (v) {
              setState(() => _shiZhi = v!);
            })),
            const SizedBox(width: 12),
            Expanded(child: _buildDropdown('月建', _yueJian, _diZhi, (v) {
              setState(() => _yueJian = v!);
            })),
          ],
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
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 4),
        AntiqueDropdown<String>(
          value: value,
          items: items
              .map((item) => AntiqueDropdownItem<String>(value: item, label: item))
              .toList(),
          onChanged: onChanged,
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

              // 四课（传统 2x2 格子）
              _buildSiKeSection(),
              const SizedBox(height: 16),

              // 三传（横排三圆）
              _buildSanChuanSection(),
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
              AIAnalysisWidget(result: result),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 1. 基本信息 → 使用统一的 ExtendedInfoSection ====================

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
                            color: ke.hasKe ? AppColors.zhusha : AppColors.xuanse,
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
                child: Icon(Icons.arrow_forward, size: 18, color: AppColors.guhe),
              ),
              _buildChuanCircle('中传', result.sanChuan.zhongChuan),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Icon(Icons.arrow_forward, size: 18, color: AppColors.guhe),
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
          _buildAntiqueInfoRow('布神', result.shenJiangConfig.directionDescription),
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
                    border: Border.all(color: AppColors.zhusha.withOpacity(0.3)),
                  ),
                  child: Text(
                    shenSha.displayText,
                    // 域色：凶神朱砂语义色
                    style: const TextStyle(fontSize: 12, color: AppColors.zhusha),
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
}
