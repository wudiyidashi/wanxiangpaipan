import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'cast_button.dart';

/// 钱币卦起卦区
///
/// 用户为每一爻选择三枚铜钱的正反面组合，从下往上排列。
/// 背背背(老阴6)、背背正(少阴8)、背正正(少阳7)、正正正(老阳9)
class CoinCastSection extends StatefulWidget {
  const CoinCastSection({
    super.key,
    this.onCast,
    this.isLoading = false,
  });

  final void Function(List<int> yaoNumbers)? onCast;
  final bool isLoading;

  @override
  State<CoinCastSection> createState() => _CoinCastSectionState();
}

class _CoinCastSectionState extends State<CoinCastSection> {
  final List<int?> _yaoValues = List.filled(6, null);

  /// 铜钱组合选项
  static const List<Map<String, dynamic>> _coinOptions = [
    {
      'label': '背背正',
      'value': 8,
      'coins': [false, false, true]
    },
    {
      'label': '背正正',
      'value': 7,
      'coins': [false, true, true]
    },
    {
      'label': '正正正',
      'value': 9,
      'coins': [true, true, true]
    },
    {
      'label': '背背背',
      'value': 6,
      'coins': [false, false, false]
    },
  ];

  static const List<String> _yaoLabels = [
    '初爻（一爻）',
    '二爻',
    '三爻',
    '四爻',
    '五爻',
    '六爻（上爻）',
  ];

  bool get _allSelected => _yaoValues.every((v) => v != null);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._buildYaoRows(),
        const SizedBox(height: 24),
        CastButton(
          onPressed: _allSelected
              ? () => widget.onCast?.call(_yaoValues.map((v) => v!).toList())
              : null,
          isLoading: widget.isLoading,
        ),
      ],
    );
  }

  List<Widget> _buildYaoRows() {
    // 从下往上排列：上爻在最上面，初爻在最下面
    return List.generate(6, (i) {
      final index = 5 - i;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _yaoLabels[index],
              style: AppTextStyles.antiqueLabel,
            ),
            const SizedBox(height: 4),
            _buildInputContainer(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _yaoValues[index],
                  hint: Text(
                    '请选择铜钱组合',
                    style: AppTextStyles.antiqueBody
                        .copyWith(color: AppColors.qianhe),
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  selectedItemBuilder: (context) {
                    return _coinOptions.map((opt) {
                      return _buildCoinOptionRow(opt);
                    }).toList();
                  },
                  items: _coinOptions.map((opt) {
                    return DropdownMenuItem<int>(
                      value: opt['value'] as int,
                      child: _buildCoinOptionRow(opt),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _yaoValues[index] = val);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCoinOptionRow(Map<String, dynamic> opt) {
    final coins = opt['coins'] as List<bool>;
    final label = opt['label'] as String;

    return Row(
      children: [
        // 三枚铜钱图标
        ...List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _buildMiniCoin(isFront: coins[i]),
          );
        }),
        const SizedBox(width: 8),
        // 组合名称
        // 0xFF2B4570: 阴阳爻线/卦文蓝，域色，保留内联
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2B4570), // 卦文蓝，域色，保留内联
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCoin({required bool isFront}) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 铜钱正面/背面渐变：域色（铜钱金/灰），保留内联
        gradient: RadialGradient(
          colors: isFront
              ? [
                  const Color(0xFFC9A84C), // 铜钱正面金色渐变起色
                  const Color(0xFF8B6914), // 铜钱正面金色渐变终色
                ]
              : [
                  const Color(0xFF9A9A9A), // 铜钱背面灰色渐变起色
                  const Color(0xFF666666), // 铜钱背面灰色渐变终色
                ],
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
        ),
        border: Border.all(
          color: isFront
              ? const Color(0xFFA08030) // 铜钱正面边框金色，域色
              : const Color(0xFF888888), // 铜钱背面边框灰色，域色
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      // 铜钱文字色：域色（铜钱深棕/高光白），保留内联
      child: Text(
        isFront ? '正' : '背',
        style: TextStyle(
          color: isFront
              ? const Color(0xFF3D2800) // 铜钱正面文字深棕，域色
              : const Color(0xFFE0E0E0), // 铜钱背面文字高光白，域色
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        border: Border.all(color: AppColors.danjinDeep.withOpacity(0x4D / 255)),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
