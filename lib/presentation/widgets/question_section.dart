import 'package:flutter/material.dart';

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
                  Icons.question_answer_outlined,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '占问事宜',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // 如果没有内容，显示提示
            if (!hasContent)
              Text(
                '（未设置占问内容）',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),

            // 主题
            if (hasSubject) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 50,
                    child: Text(
                      '主题：',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      subject!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
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
                  const SizedBox(
                    width: 50,
                    child: Text(
                      '问题：',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      question!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
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
