import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart' as lunar_pkg;
import '../../models/lunar_info.dart';
import '../../core/theme/app_text_styles.dart';
import 'antique/antique.dart';

/// 扩展信息区块组件
///
/// 精简显示时间和节气信息。
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
    final displayHourZhi =
        (lunarInfo.hourGanZhi != null && lunarInfo.hourGanZhi!.isNotEmpty)
            ? lunarInfo.hourGanZhi!.substring(lunarInfo.hourGanZhi!.length - 1)
            : lunarDate.getTimeZhi();
    final lunarDateText =
        '${castTime.year}年${lunarDate.getMonthInChinese()}月${lunarDate.getDayInChinese()}$displayHourZhi时';
    final zhongQiList = _getUpcomingZhongQi(castTime);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AntiqueCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              '阳历时',
              _formatSolarDateTime(castTime),
            ),
            const SizedBox(height: 6),
            _buildInfoRow(
              '农历时',
              lunarDateText,
            ),
            for (final item in zhongQiList) ...[
              const SizedBox(height: 6),
              _buildInfoRow(
                _formatSolarTermLabel(item.name),
                _formatSolarTermTime(item.solar),
              ),
            ],
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
          width: 52,
          child: Text(
            '$label：',
            style: AppTextStyles.antiqueLabel.copyWith(
              fontWeight: FontWeight.w500,
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
    );
  }

  String _formatSolarDateTime(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatSolarTermLabel(String name) {
    if (name.length == 2) {
      return '${name[0]}　${name[1]}';
    }
    return name;
  }

  String _formatSolarTermTime(lunar_pkg.Solar solar) {
    final parts = solar.toYmdHms().split(' ');
    final ymd = parts.first.split('-');
    final hm = parts.length > 1 ? parts[1].split(':') : const ['00', '00'];
    return '${ymd[0]}年${ymd[1]}月${ymd[2]}日${hm[0]}时${hm[1]}分';
  }

  List<_ZhongQiEntry> _getUpcomingZhongQi(DateTime dateTime) {
    const zhongQiNames = [
      '雨水',
      '春分',
      '谷雨',
      '小满',
      '夏至',
      '大暑',
      '处暑',
      '秋分',
      '霜降',
      '小雪',
      '冬至',
      '大寒',
    ];

    final current = lunar_pkg.Lunar.fromDate(dateTime);
    final nextYear =
        lunar_pkg.Lunar.fromDate(DateTime(dateTime.year + 1, 1, 1));
    final table = <String, lunar_pkg.Solar>{}
      ..addAll(current.getJieQiTable())
      ..addAll(nextYear.getJieQiTable());
    final currentTime = lunar_pkg.Solar.fromDate(dateTime).toYmdHms();

    final entries = table.entries
        .where((entry) => zhongQiNames.contains(entry.key))
        .map((entry) => _ZhongQiEntry(entry.key, entry.value))
        .where((entry) => entry.solar.toYmdHms().compareTo(currentTime) >= 0)
        .toList()
      ..sort((a, b) => a.solar.toYmdHms().compareTo(b.solar.toYmdHms()));

    return entries.take(2).toList();
  }
}

class _ZhongQiEntry {
  const _ZhongQiEntry(this.name, this.solar);

  final String name;
  final lunar_pkg.Solar solar;
}
