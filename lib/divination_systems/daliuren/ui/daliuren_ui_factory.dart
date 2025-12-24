import 'package:flutter/material.dart';
import '../../../domain/divination_system.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/widgets/ai_analysis_widget.dart';
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
    switch (method) {
      case CastMethod.time:
        // 时间起课界面
        return const _DaLiuRenTimeCastScreen();
      case CastMethod.manual:
        // 手动输入界面
        return const _DaLiuRenManualCastScreen();
      default:
        throw UnsupportedError('大六壬不支持的起卦方式: ${method.displayName}');
    }
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

// ==================== 临时占位界面 ====================

/// 大六壬时间起课界面
class _DaLiuRenTimeCastScreen extends StatefulWidget {
  const _DaLiuRenTimeCastScreen();

  @override
  State<_DaLiuRenTimeCastScreen> createState() => _DaLiuRenTimeCastScreenState();
}

class _DaLiuRenTimeCastScreenState extends State<_DaLiuRenTimeCastScreen> {
  bool _isLoading = false;

  Future<void> _handleTimeCast() async {
    setState(() => _isLoading = true);

    try {
      // 执行时间起课
      final system = DaLiuRenSystem();
      final result = await system.cast(
        method: CastMethod.time,
        input: {},
        castTime: DateTime.now(),
      );

      if (!mounted) return;

      // 导航到结果页面
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => _DaLiuRenResultScreen(result: result as DaLiuRenResult),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('起课失败: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('大六壬 - 时间起课'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wb_sunny,
              size: 80,
              color: Colors.purple[300],
            ),
            const SizedBox(height: 24),
            const Text(
              '时间起课',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '使用当前时间进行排盘',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _handleTimeCast,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始起课'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/// 大六壬手动输入界面
class _DaLiuRenManualCastScreen extends StatefulWidget {
  const _DaLiuRenManualCastScreen();

  @override
  State<_DaLiuRenManualCastScreen> createState() => _DaLiuRenManualCastScreenState();
}

class _DaLiuRenManualCastScreenState extends State<_DaLiuRenManualCastScreen> {
  final _tianGan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  final _diZhi = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  String _riGan = '甲';
  String _riZhi = '子';
  String _shiZhi = '子';
  String _yueJian = '寅';
  bool _isLoading = false;

  Future<void> _handleManualCast() async {
    setState(() => _isLoading = true);

    try {
      final system = DaLiuRenSystem();
      final result = await system.cast(
        method: CastMethod.manual,
        input: {
          'riGan': _riGan,
          'riZhi': _riZhi,
          'shiZhi': _shiZhi,
          'yueJian': _yueJian,
        },
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => _DaLiuRenResultScreen(result: result as DaLiuRenResult),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('起课失败: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('大六壬 - 手动输入'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '日干支',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _riGan,
                            decoration: const InputDecoration(
                              labelText: '日干',
                              border: OutlineInputBorder(),
                            ),
                            items: _tianGan.map((gan) {
                              return DropdownMenuItem(value: gan, child: Text(gan));
                            }).toList(),
                            onChanged: (value) => setState(() => _riGan = value!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _riZhi,
                            decoration: const InputDecoration(
                              labelText: '日支',
                              border: OutlineInputBorder(),
                            ),
                            items: _diZhi.map((zhi) {
                              return DropdownMenuItem(value: zhi, child: Text(zhi));
                            }).toList(),
                            onChanged: (value) => setState(() => _riZhi = value!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '时支',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _shiZhi,
                      decoration: const InputDecoration(
                        labelText: '时支',
                        border: OutlineInputBorder(),
                      ),
                      items: _diZhi.map((zhi) {
                        return DropdownMenuItem(value: zhi, child: Text(zhi));
                      }).toList(),
                      onChanged: (value) => setState(() => _shiZhi = value!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '月建',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _yueJian,
                      decoration: const InputDecoration(
                        labelText: '月建',
                        border: OutlineInputBorder(),
                      ),
                      items: _diZhi.map((zhi) {
                        return DropdownMenuItem(value: zhi, child: Text(zhi));
                      }).toList(),
                      onChanged: (value) => setState(() => _yueJian = value!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _handleManualCast,
                    icon: const Icon(Icons.check),
                    label: const Text('开始起课'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/// 大六壬结果展示界面
class _DaLiuRenResultScreen extends StatelessWidget {
  final DaLiuRenResult result;

  const _DaLiuRenResultScreen({required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('大六壬排盘结果'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 基本信息卡片
            _buildInfoCard(context),
            const SizedBox(height: 16),

            // 天盘信息
            _buildTianPanCard(context),
            const SizedBox(height: 16),

            // 四课信息
            _buildSiKeCard(context),
            const SizedBox(height: 16),

            // 三传信息
            _buildSanChuanCard(context),
            const SizedBox(height: 16),

            // 神将信息
            _buildShenJiangCard(context),
            const SizedBox(height: 16),

            // 神煞信息
            _buildShenShaCard(context),
            const SizedBox(height: 16),

              // AI 分析组件
            AIAnalysisWidget(result: result),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本信息',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildInfoRow('课体', '${result.keTypeName}课'),
            _buildInfoRow('日干支', result.lunarInfo.riGanZhi),
            _buildInfoRow('月建', result.lunarInfo.yueJian),
            _buildInfoRow('时支', result.shiZhi),
            _buildInfoRow('空亡', result.lunarInfo.kongWang.join('、')),
          ],
        ),
      ),
    );
  }

  Widget _buildTianPanCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '天盘',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildInfoRow('月将', '${result.tianPan.yueJiang}（${result.tianPan.yueJiangName}）'),
            _buildInfoRow('描述', result.tianPan.yueJiangDescription),
          ],
        ),
      ),
    );
  }

  Widget _buildSiKeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '四课',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            for (final ke in result.siKe.allKe)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        ke.keName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text('${ke.shangShen}/${ke.xiaShen}'),
                    const SizedBox(width: 8),
                    if (ke.wuXingRelation != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ke.isZeiKe
                              ? Colors.red.withOpacity(0.1)
                              : ke.isBiYong
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ke.wuXingRelation!,
                          style: TextStyle(
                            fontSize: 12,
                            color: ke.isZeiKe
                                ? Colors.red
                                : ke.isBiYong
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSanChuanCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '三传',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    result.keTypeName,
                    style: const TextStyle(color: Colors.purple, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildChuanItem('初传', result.sanChuan.chuChuan),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                _buildChuanItem('中传', result.sanChuan.zhongChuan),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                _buildChuanItem('末传', result.sanChuan.moChuan),
              ],
            ),
            if (result.sanChuan.keTypeExplanation != null) ...[
              const SizedBox(height: 12),
              Text(
                result.sanChuan.keTypeExplanation!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChuanItem(String label, Chuan chuan) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              chuan.diZhi,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          chuan.liuQin,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildShenJiangCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '十二神将',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildInfoRow('贵人', '${result.shenJiangConfig.guiRenPosition}（${result.shenJiangConfig.guiRenTypeDescription}）'),
            _buildInfoRow('布神', result.shenJiangConfig.directionDescription),
          ],
        ),
      ),
    );
  }

  Widget _buildShenShaCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '神煞',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            if (result.shenShaList.jiShen.isNotEmpty) ...[
              Text(
                '吉神',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.shenShaList.jiShen.map((shenSha) {
                  return Chip(
                    label: Text(shenSha.displayText),
                    backgroundColor: Colors.green.withOpacity(0.1),
                    labelStyle: const TextStyle(fontSize: 12, color: Colors.green),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (result.shenShaList.xiongShen.isNotEmpty) ...[
              Text(
                '凶神',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.shenShaList.xiongShen.map((shenSha) {
                  return Chip(
                    label: Text(shenSha.displayText),
                    backgroundColor: Colors.red.withOpacity(0.1),
                    labelStyle: const TextStyle(fontSize: 12, color: Colors.red),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
