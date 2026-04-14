import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lunar/lunar.dart';
import '../../../domain/divination_system.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/widgets/ai_analysis_widget.dart';
import '../../../presentation/widgets/cast/compass_background.dart';
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
  Widget buildHistoryCard(DivinationResult result) {
    if (result is! DaLiuRenResult) {
      throw ArgumentError('结果类型必须是 DaLiuRenResult，实际类型: ${result.runtimeType}');
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // TODO: 导航到详情页面
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 课体和时间
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${result.keTypeName}课',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatDateTime(result.castTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 三传
              Row(
                children: [
                  _buildTag('初传: ${result.chuChuan}'),
                  const SizedBox(width: 8),
                  _buildTag('中传: ${result.zhongChuan}'),
                  const SizedBox(width: 8),
                  _buildTag('末传: ${result.moChuan}'),
                ],
              ),

              // 日干支
              const SizedBox(height: 8),
              Text(
                '${result.lunarInfo.yearGanZhi}年 ${result.lunarInfo.monthGanZhi}月 ${result.lunarInfo.riGanZhi}日',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget? buildSystemCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          // TODO: 导航到大六壬起课方式选择页面
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    getSystemIcon(),
                    size: 32,
                    color: getSystemColor(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '大六壬',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '大六壬是中国古代三式之一，以天干地支、十二神将为基础，通过四课三传进行占断。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildTag('时间起课'),
                  _buildTag('手动输入'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  IconData? getSystemIcon() {
    // 使用太阳图标代表大六壬（月将与太阳位置相关）
    return Icons.wb_sunny;
  }

  @override
  Color? getSystemColor() {
    // 使用紫色作为大六壬的主题色
    return const Color(0xFF7B1FA2);
  }

  // ==================== 私有辅助方法 ====================

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTag(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.purple).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color ?? Colors.purple,
        ),
      ),
    );
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
        backgroundColor: const Color(0xFF8B2020),
      ),
    );
  }

  // ==================== UI 构建 ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('大六壬起课'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 缃色渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF7F7F5), Color(0xFFF0EDE8)],
              ),
            ),
          ),
          // 罗盘背景装饰（居中）
          const Center(child: CompassBackground()),
          // 主内容
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestionSection(),
                  const SizedBox(height: 16),
                  _buildMethodSelector(),
                  const SizedBox(height: 16),
                  const Divider(
                    color: Color(0xFFD4B896),
                    thickness: 0.5,
                    height: 1,
                  ),
                  const SizedBox(height: 20),
                  _buildCastSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 占问事项输入
  Widget _buildQuestionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '占问事项',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF8B7355),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border.all(color: const Color(0xFFD4B896)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: _questionController,
            style: const TextStyle(
              color: Color(0xFF2C2C2C),
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '请输入您想占问的事项...',
              hintStyle: TextStyle(
                color: Color(0xFFA0937E),
                fontSize: 13,
              ),
              isDense: true,
            ),
            maxLines: 2,
            minLines: 1,
          ),
        ),
      ],
    );
  }

  /// 起课方式选择器
  Widget _buildMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '起课方式',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF8B7355),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border.all(color: const Color(0xFFD4B896)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CastMethod>(
              value: _selectedMethod,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(
                color: Color(0xFF2C2C2C),
                fontSize: 13,
              ),
              items: _availableMethods.map((method) {
                return DropdownMenuItem<CastMethod>(
                  value: method,
                  child: Text(
                    _methodNames[method] ?? method.displayName,
                    style: const TextStyle(
                      color: Color(0xFF2C2C2C),
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (method) {
                if (method != null) {
                  setState(() => _selectedMethod = method);
                }
              },
            ),
          ),
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
            border: Border.all(color: const Color(0xFFD4B896).withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Text(
                '当前干支',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B7355),
                  letterSpacing: 1,
                ),
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
        _buildCastButton(),
      ],
    );
  }

  /// 干支显示小组件
  Widget _buildGanZhiItem(String label, String ganZhi) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8B7355),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ganZhi,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2C2C),
          ),
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
            border: Border.all(color: const Color(0xFFD4B896)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: _numberController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: Color(0xFF2C2C2C),
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '请输入任意数字',
              hintStyle: TextStyle(
                color: Color(0xFFA0937E),
                fontSize: 13,
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '输入任意数字，除12取余映射地支',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF8B7355),
          ),
        ),
        const SizedBox(height: 24),
        _buildCastButton(),
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
        _buildCastButton(),
      ],
    );
  }

  /// 仿古风下拉选择器
  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8B7355),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border.all(color: const Color(0xFFD4B896)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(
                color: Color(0xFF2C2C2C),
                fontSize: 13,
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Color(0xFF2C2C2C),
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
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
            border: Border.all(color: const Color(0xFFD4B896).withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                Icons.casino_outlined,
                size: 48,
                color: const Color(0xFFC94A4A).withOpacity(0.7),
              ),
              const SizedBox(height: 12),
              const Text(
                '系统随机取地支作为占时',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8B7355),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildCastButton(),
      ],
    );
  }

  /// 朱砂红起课按钮
  Widget _buildCastButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleCast,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC94A4A), Color(0xFFE07070)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC94A4A).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  '起课',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }
}

/// 大六壬结果展示界面（仿古风）
class _DaLiuRenResultScreen extends StatelessWidget {
  final DaLiuRenResult result;

  const _DaLiuRenResultScreen({required this.result});

  // 仿古风配色常量
  static const _zhuShaRed = Color(0xFFC94A4A);
  static const _danJin = Color(0xFFD4B896);
  static const _textDark = Color(0xFF2C2C2C);
  static const _textMuted = Color(0xFF8B7355);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('大六壬排盘结果'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 缃色渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF7F7F5), Color(0xFFF0EDE8)],
              ),
            ),
          ),
          // 主内容
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 基本信息（精简两行）
                _buildInfoSection(),
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
        ],
      ),
    );
  }

  /// 仿古风卡片容器
  Widget _buildAntiqueCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        border: Border.all(color: _danJin.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  /// 仿古风区块标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: _zhuShaRed,
        letterSpacing: 1,
      ),
    );
  }

  /// 仿古风分割线
  Widget _buildAntiqueDivider() {
    return Divider(color: _danJin.withOpacity(0.5));
  }

  // ==================== 1. 基本信息（精简两行） ====================

  Widget _buildInfoSection() {
    final castTime = result.castTime;
    final lunar = Lunar.fromDate(castTime);
    final lunarMonthDay = '${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
    final timeStr =
        '${castTime.year}-${castTime.month.toString().padLeft(2, '0')}-${castTime.day.toString().padLeft(2, '0')} '
        '${castTime.hour.toString().padLeft(2, '0')}:${castTime.minute.toString().padLeft(2, '0')}';

    final yearGZ = result.lunarInfo.yearGanZhi;
    final monthGZ = result.lunarInfo.monthGanZhi;
    final dayGZ = result.lunarInfo.riGanZhi;
    final timeGZ = '${lunar.getTimeGan()}${lunar.getTimeZhi()}';
    final kongWang = result.lunarInfo.kongWang.join('');
    final yueJiang = result.tianPan.yueJiang;
    final yueJiangName = result.tianPan.yueJiangName;

    return _buildAntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('基本信息'),
          _buildAntiqueDivider(),
          const SizedBox(height: 4),
          // Line 1: 时间
          Row(
            children: [
              const Text(
                '时间',
                style: TextStyle(fontSize: 13, color: _textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$timeStr  $lunarMonthDay',
                  style: const TextStyle(fontSize: 13, color: _textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Line 2: 干支
          Row(
            children: [
              const Text(
                '干支',
                style: TextStyle(fontSize: 13, color: _textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$yearGZ $monthGZ $dayGZ $timeGZ  空亡:$kongWang  月将:$yueJiang($yueJiangName)',
                  style: const TextStyle(fontSize: 13, color: _textDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

    return _buildAntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('四课'),
          _buildAntiqueDivider(),
          const SizedBox(height: 8),
          // 2x2 格子表格
          Table(
            border: TableBorder.all(
              color: _danJin.withOpacity(0.5),
              width: 1,
            ),
            children: [
              // 标题行
              TableRow(
                decoration: BoxDecoration(
                  color: _danJin.withOpacity(0.1),
                ),
                children: keLabels.map((label) {
                  return TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Center(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _textMuted,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ke.hasKe ? _zhuShaRed : _textDark,
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
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
                    style: TextStyle(
                      fontSize: 11,
                      color: ke.isZeiKe
                          ? _zhuShaRed
                          : ke.isBiYong
                              ? const Color(0xFF3A6EA5)
                              : _textMuted,
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
    return _buildAntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('三传'),
          _buildAntiqueDivider(),
          const SizedBox(height: 12),
          // 三个圆 + 箭头
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChuanCircle('初传', result.sanChuan.chuChuan),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Icon(Icons.arrow_forward, size: 18, color: _textMuted),
              ),
              _buildChuanCircle('中传', result.sanChuan.zhongChuan),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Icon(Icons.arrow_forward, size: 18, color: _textMuted),
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
                color: _zhuShaRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _zhuShaRed.withOpacity(0.3)),
              ),
              child: Text(
                '${result.keTypeName}课',
                style: const TextStyle(
                  fontSize: 13,
                  color: _zhuShaRed,
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
                style: const TextStyle(fontSize: 12, color: _textMuted),
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
            style: const TextStyle(fontSize: 12, color: _textMuted),
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
                colors: [_zhuShaRed, Color(0xFFE07070)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _zhuShaRed.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                chuan.diZhi,
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
            style: const TextStyle(fontSize: 12, color: _textMuted),
          ),
        ],
      ),
    );
  }

  // ==================== 4. 天盘 ====================

  Widget _buildTianPanSection() {
    return _buildAntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('天盘'),
          _buildAntiqueDivider(),
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
    return _buildAntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('十二神将'),
          _buildAntiqueDivider(),
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
    return _buildAntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('神煞'),
          _buildAntiqueDivider(),
          if (result.shenShaList.jiShen.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '吉神',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A7C59),
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
                    color: const Color(0xFF4A7C59).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF4A7C59).withOpacity(0.3)),
                  ),
                  child: Text(
                    shenSha.displayText,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF4A7C59)),
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _zhuShaRed,
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
                    color: _zhuShaRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _zhuShaRed.withOpacity(0.3)),
                  ),
                  child: Text(
                    shenSha.displayText,
                    style: const TextStyle(fontSize: 12, color: _zhuShaRed),
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
              style: const TextStyle(fontSize: 13, color: _textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: _textDark),
            ),
          ),
        ],
      ),
    );
  }
}
