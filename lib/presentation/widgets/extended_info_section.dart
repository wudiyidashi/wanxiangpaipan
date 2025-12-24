import 'package:flutter/material.dart';
import '../../models/lunar_info.dart';

/// 扩展信息区块组件
///
/// 显示农历信息、节气信息、神煞信息等
class ExtendedInfoSection extends StatelessWidget {
  /// 占卜时间
  final DateTime castTime;

  /// 农历信息
  final LunarInfo lunarInfo;

  /// 六神列表
  final List<String> liuShen;

  /// 神煞信息（可选）
  final String? shenShaInfo;

  const ExtendedInfoSection({
    super.key,
    required this.castTime,
    required this.lunarInfo,
    required this.liuShen,
    this.shenShaInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 区块标题
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '占卜信息',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // 占卜时间
            _buildInfoRow(
              '占卜时间',
              _formatDateTime(castTime),
            ),

            // 农历日期
            _buildInfoRow(
              '农历日期',
              '${lunarInfo.yearGanZhi}年 ${lunarInfo.monthGanZhi}月 ${lunarInfo.riGanZhi}日',
            ),

            // 月建
            _buildInfoRow('月建', lunarInfo.yueJian),

            // 日干支
            _buildInfoRow('日干支', lunarInfo.riGanZhi),

            // 空亡
            _buildInfoRow('空亡', lunarInfo.kongWang.join('、')),

            // 六神
            if (liuShen.isNotEmpty)
              _buildInfoRow(
                '六神',
                liuShen.join(' → '),
              ),

            // 节气（如果有）
            if (lunarInfo.solarTerm != null && lunarInfo.solarTerm!.isNotEmpty)
              _buildInfoRow('节气', lunarInfo.solarTerm!),

            // 神煞（如果有）
            if (shenShaInfo != null && shenShaInfo!.isNotEmpty)
              _buildInfoRow('神煞', shenShaInfo!),
          ],
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label：',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
