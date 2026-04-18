import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'antique/antique.dart';

/// 占问信息区块组件
///
/// 显示占问的主题和问题详情
class QuestionSection extends StatelessWidget {
  /// 占问主题（可选）
  final String? subject;

  /// 占问问题（可选）
  final String? question;

  const QuestionSection({
    super.key,
    this.subject,
    this.question,
  });

  @override
  Widget build(BuildContext context) {
    // 判断是否有内容
    final hasSubject = subject != null && subject!.isNotEmpty;
    final hasQuestion = question != null && question!.isNotEmpty;
    final hasContent = hasSubject || hasQuestion;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AntiqueCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 区块标题
            AntiqueSectionTitle(title: '占问事宜'),
            const SizedBox(height: 8),

            // 如果没有内容，显示提示
            if (!hasContent)
              Text(
                '（未设置占问内容）',
                style: AppTextStyles.antiqueLabel.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.qianhe,
                ),
              ),

            // 主题
            if (hasSubject) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      '主题：',
                      style: AppTextStyles.antiqueBody.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      subject!,
                      style: AppTextStyles.antiqueBody.copyWith(
                        color: AppColors.zhusha,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // 问题
            if (hasQuestion) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      '问题：',
                      style: AppTextStyles.antiqueBody.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      question!,
                      style: AppTextStyles.antiqueBody,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
