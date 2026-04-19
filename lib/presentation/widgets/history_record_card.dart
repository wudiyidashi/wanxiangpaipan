import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/antique_tokens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../divination_systems/daliuren/models/daliuren_result.dart';
import '../../divination_systems/liuyao/liuyao_result.dart';
import '../../divination_systems/meihua/models/meihua_result.dart';
import '../../divination_systems/xiaoliuren/models/xiaoliuren_result.dart';
import '../../domain/divination_system.dart';
import '../../domain/repositories/divination_repository.dart';
import 'antique/antique.dart';

/// 历史记录卡片（跨术数统一骨架）。
///
/// 5 层信息分布于左右两列：
/// - 左列：占问（顶）/ 系统 tag + 方式 tag（底）
/// - 右列：时间（顶）/ 结果摘要（底）
/// 两列 spaceBetween 形成水平双重心；背景为系统 antique 底图 @ 28% opacity。
/// 见 `docs/superpowers/specs/2026-04-18-history-card-visual-design.md`。
class HistoryRecordCard extends StatelessWidget {
  const HistoryRecordCard({
    super.key,
    required this.result,
    this.onTap,
  });

  final DivinationResult result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<DivinationRepository>();
    final questionKey = 'question_${result.id}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: FutureBuilder<String?>(
        future: repository.readEncryptedField(questionKey),
        builder: (context, snapshot) {
          final question = snapshot.data ?? '';
          return _buildCard(context, question);
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, String question) {
    final bgPath = _systemBackground(result.systemType);
    return AntiqueCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      semanticsLabel: _buildSemanticsLabel(question),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AntiqueTokens.radiusCard),
        child: Stack(
          children: [
            if (bgPath != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.28,
                  child: Image.asset(
                    bgPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomRight,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 左列：占问（顶）+ tags（底）
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Layer 1: 占问
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 24),
                            child: Text(
                              question,
                              style: AppTextStyles.antiqueTitle.copyWith(
                                fontSize: 17,
                                letterSpacing: 1,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Layer 4+5: tags
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildSystemTag(),
                              _buildMethodTag(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 右列：时间（顶）+ 结果摘要（底）
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Layer 2: 时间
                          Text(
                            _formatDateTime(result.castTime),
                            style: AppTextStyles.antiqueLabel.copyWith(
                              color: AppColors.guhe,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 8),
                          // Layer 3: 结果摘要
                          Text(
                            _summary(result),
                            style: AppTextStyles.antiqueBody.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.zhusha,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemTag() {
    final color = _systemColor(result.systemType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AntiqueTokens.radiusTag),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Text(
        result.systemType.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMethodTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AntiqueTokens.radiusTag),
        border: Border.all(color: AppColors.danjin, width: 1),
      ),
      child: Text(
        result.castMethod.displayName,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.5,
          color: AppColors.guhe,
        ),
      ),
    );
  }

  String _buildSemanticsLabel(String question) {
    final parts = <String>[];
    if (question.isNotEmpty) {
      parts.add('占问：$question');
    }
    parts.add(
        '${result.systemType.displayName}, ${result.castMethod.displayName}');
    parts.add(_summary(result));
    parts.add(_formatDateTime(result.castTime));
    return parts.join('。');
  }
}

// ==================== file-level helpers ====================

String _summary(DivinationResult r) {
  if (r is LiuYaoResult) {
    return r.changingGua == null
        ? r.mainGua.name
        : '${r.mainGua.name} → ${r.changingGua!.name}';
  }
  if (r is DaLiuRenResult) {
    return '${r.keTypeName}课 · 初传${r.chuChuan} '
        '中传${r.zhongChuan} 末传${r.moChuan}';
  }
  if (r is MeiHuaResult) {
    return '${r.benGua.name} → ${r.bianGua.name} · ${r.wuXingRelation}';
  }
  if (r is XiaoLiuRenResult) {
    return '${r.finalPosition.name} · ${r.finalPosition.keyword}';
  }
  // 未来紫微等系统接入时，在此 switch 补 case；
  // 兜底使用 DivinationResult.getSummary()
  return r.getSummary();
}

Color _systemColor(DivinationType t) {
  switch (t) {
    case DivinationType.liuYao:
      return AppColors.liuyaoColor;
    case DivinationType.daLiuRen:
      return AppColors.daliurenColor;
    case DivinationType.xiaoLiuRen:
      return AppColors.xiaoliurenColor;
    case DivinationType.meiHua:
      return AppColors.meihuaColor;
  }
}

String? _systemBackground(DivinationType t) {
  switch (t) {
    case DivinationType.liuYao:
      return 'assets/images/screen_card/liuyao_background.png';
    case DivinationType.daLiuRen:
      return 'assets/images/screen_card/daliuren_background.png';
    case DivinationType.xiaoLiuRen:
      return 'assets/images/screen_card/xiaoliuren_background.png';
    case DivinationType.meiHua:
      return 'assets/images/screen_card/meihua_background.png';
  }
}

String _formatDateTime(DateTime dt) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} '
      '${pad(dt.hour)}:${pad(dt.minute)}';
}
