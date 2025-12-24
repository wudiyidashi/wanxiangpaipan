import 'package:flutter/material.dart';
import '../../divination_systems/liuyao/models/gua.dart';
import '../../divination_systems/liuyao/models/yao.dart';

class GuaDisplay extends StatelessWidget {
  final Gua gua;
  final List<String>? liuShen;

  const GuaDisplay({
    super.key,
    required this.gua,
    this.liuShen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卦名和八宫
            Text(
              '${gua.name} (${gua.baGong.name})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            // 六爻（从上到下显示，即从第6爻到第1爻）
            ...List.generate(6, (i) {
              final yaoIndex = 5 - i; // 倒序显示：i=0→yaoIndex=5（上爻），i=5→yaoIndex=0（初爻）
              final yao = gua.yaos[yaoIndex];
              final liuShenName = liuShen != null && liuShen!.length > yaoIndex
                  ? liuShen![yaoIndex]
                  : '';
              return _buildYaoRow(context, yao, liuShenName);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildYaoRow(BuildContext context, Yao yao, String liuShenName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 爻位
          SizedBox(
            width: 40,
            child: Text(
              _getYaoPositionName(yao.position),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // 爻象（阴阳）
          SizedBox(
            width: 60,
            child: Text(
              yao.isYang ? '━━━' : '━ ━',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          // 动爻标记
          if (yao.isMoving)
            const Icon(Icons.arrow_forward, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          // 地支
          Text('${yao.branch}${yao.wuXing.name}', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          // 六亲
          Text(yao.liuQin.name, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          // 六神
          if (liuShenName.isNotEmpty)
            Text('[$liuShenName]', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          // 世应标记
          if (yao.isSeYao)
            const Text('[世]', style: TextStyle(fontSize: 14, color: Colors.blue)),
          if (yao.isYingYao)
            const Text('[应]', style: TextStyle(fontSize: 14, color: Colors.green)),
        ],
      ),
    );
  }

  String _getYaoPositionName(int position) {
    const names = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
    return names[position - 1];
  }
}
