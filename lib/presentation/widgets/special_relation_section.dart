import 'package:flutter/material.dart';

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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 区块标题
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  '卦象特性',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // 特殊关系类型
            if (relationType != null && relationType!.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      relationType!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
