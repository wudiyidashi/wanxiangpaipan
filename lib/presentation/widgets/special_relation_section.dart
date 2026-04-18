import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'antique/antique.dart';

/// 特殊卦象关系解析组件
///
/// 显示卦象之间的特殊关系（如游魂卦、归魂卦、六冲卦等）及其解析。
class SpecialRelationSection extends StatelessWidget {
  /// 特殊关系类型（如 "游魂卦"、"归魂卦"、"六冲卦" 等）
  final String? relationType;

  /// 特殊关系描述
  final String? description;

  const SpecialRelationSection({
    super.key,
    this.relationType,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    // 如果没有特殊关系信息，不显示该区块
    if ((relationType == null || relationType!.isEmpty) &&
        (description == null || description!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AntiqueCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 区块标题
            AntiqueSectionTitle(title: '卦象特性'),
            const SizedBox(height: 8),

            // 特殊关系类型
            if (relationType != null && relationType!.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      // 仿古金色徽章背景 — 通用卦象特性标签
                      color: AppColors.danjinDeep,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      relationType!,
                      style: AppTextStyles.antiqueButton.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // 描述
            if (description != null && description!.isNotEmpty)
              Text(
                description!,
                style: AppTextStyles.antiqueBody,
              ),
          ],
        ),
      ),
    );
  }
}
