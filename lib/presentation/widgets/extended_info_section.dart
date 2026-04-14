import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart' as lunar_pkg;
import '../../models/lunar_info.dart';

/// 扩展信息区块组件
///
/// 精简显示时间和干支信息。
class ExtendedInfoSection extends StatelessWidget {
  final DateTime castTime;
  final LunarInfo lunarInfo;
  final List<String> liuShen;
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
    final lunarDate = lunar_pkg.Lunar.fromDate(castTime);
    final lunarMonthDay =
        '${lunarDate.getMonthInChinese()}月${lunarDate.getDayInChinese()}';
    final shiGanZhi = lunarDate.getTimeInGanZhi();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间：阳历 + 农历
            _buildInfoRow(
              '时间',
              '${_formatDateTime(castTime)}  农历$lunarMonthDay',
            ),
            const SizedBox(height: 6),
            // 干支四柱：年月日时 + 空亡
            _buildInfoRow(
              '干支',
              '${lunarInfo.yearGanZhi}年 '
                  '${lunarInfo.monthGanZhi}月 '
                  '${lunarInfo.riGanZhi}日 '
                  '$shiGanZhi时'
                  '${lunarInfo.kongWang.isNotEmpty ? "  空亡: ${lunarInfo.kongWang.join("")}" : ""}',
            ),
            const SizedBox(height: 6),
            // 月建 + 日建
            _buildInfoRow(
              '月日建',
              '月建${lunarInfo.yueJian}  日建${lunarInfo.riZhi}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Text(
            '$label：',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}年${dt.month}月${dt.day}日 '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
