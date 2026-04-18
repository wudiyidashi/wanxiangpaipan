import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../models/gua.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/screens/cast/unified_cast_screen.dart';
import '../../../presentation/widgets/ai_analysis_widget.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../../../presentation/widgets/diagram_comparison_row.dart';
import '../../../presentation/widgets/question_section.dart';
import '../../../presentation/widgets/extended_info_section.dart';
import '../../../presentation/widgets/special_relation_section.dart';
import '../liuyao_result.dart';
import '../viewmodels/liuyao_viewmodel.dart';

/// 六爻 UI 工厂
///
/// 实现 DivinationUIFactory 接口，提供六爻特定的 UI 组件。
/// 复用现有的六爻 UI 组件，确保用户体验保持一致。
class LiuYaoUIFactory implements DivinationUIFactory {
  @override
  DivinationType get systemType => DivinationType.liuYao;

  @override
  Widget buildCastScreen(CastMethod method) {
    return const UnifiedCastScreen();
  }

  @override
  Widget buildResultScreen(DivinationResult result) {
    // 类型检查
    if (result is! LiuYaoResult) {
      throw ArgumentError('结果类型必须是 LiuYaoResult，实际类型: ${result.runtimeType}');
    }

    // 返回包含 AI 分析功能的结果页面
    return _LiuYaoResultScreenWithAI(result: result);
  }

  @override
  Widget buildHistoryCard(DivinationResult result) {
    // 类型检查
    if (result is! LiuYaoResult) {
      throw ArgumentError('结果类型必须是 LiuYaoResult，实际类型: ${result.runtimeType}');
    }

    final liuyaoResult = result;

    // 创建六爻历史记录卡片
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AntiqueCard(
        onTap: () {
          // TODO: 导航到详情页面
          // Navigator.push(context, MaterialPageRoute(
          //   builder: (_) => buildResultScreen(result),
          // ));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 卦名和时间
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  liuyaoResult.mainGua.name,
                  style: AppTextStyles.antiqueTitle,
                ),
                Text(
                  _formatDateTime(liuyaoResult.castTime),
                  style: AppTextStyles.antiqueLabel,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 八宫和起卦方式
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildTag(liuyaoResult.mainGua.baGong.name),
                _buildTag(liuyaoResult.castMethod.displayName),
                if (liuyaoResult.hasChangingGua)
                  _buildTag('有变卦', color: Colors.orange),
              ],
            ),

            // 如果有变卦，显示变卦信息
            if (liuyaoResult.hasChangingGua) ...[
              const SizedBox(height: 8),
              Text(
                '变卦：${liuyaoResult.changingGua!.name}',
                style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
              ),
            ],

            // 农历信息
            const SizedBox(height: 8),
            Text(
              '${liuyaoResult.lunarInfo.yearGanZhi}年 ${liuyaoResult.lunarInfo.monthGanZhi}月 ${liuyaoResult.lunarInfo.riGanZhi}日',
              style: AppTextStyles.antiqueLabel,
            ),
          ],
        ),
      ),
    );
  }

  @override
  IconData? getSystemIcon() {
    // 返回六爻系统的图标（使用六边形代表六爻）
    return Icons.hexagon;
  }

  @override
  Color? getSystemColor() {
    // 返回六爻系统的主题色（中国传统色：朱红）
    return const Color(0xFFD32F2F); // 六爻系统专属主题色，非通用 token（deferred to semantic-color pass）
  }

  // ==================== 私有辅助方法 ====================

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 构建标签 Widget
  Widget _buildTag(String text, {Color? color}) {
    if (color != null) {
      return AntiqueTag(label: text, color: color);
    }
    // 无色时使用 AntiqueTag 默认色（AppColors.zhusha），保持仿古风主题。
    return AntiqueTag(label: text, color: AppColors.zhusha);
  }
}

/// 六爻结果页面（包含 AI 分析功能）
///
/// 这是一个内部组件，用于在结果页面中集成 AI 分析功能。
class _LiuYaoResultScreenWithAI extends StatelessWidget {
  final LiuYaoResult result;

  const _LiuYaoResultScreenWithAI({required this.result});

  @override
  Widget build(BuildContext context) {
    return AntiqueScaffold(
      appBar: const AntiqueAppBar(title: '排盘结果'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // 占问信息区块
            Builder(builder: (context) {
              final question =
                  context.select<LiuYaoViewModel, String?>((vm) => vm.question);
              if (question == null || question.isEmpty) {
                return const SizedBox.shrink();
              }
              return QuestionSection(
                subject: null,
                question: question,
              );
            }),

            // 扩展信息区块（农历、节气、神煞）
            ExtendedInfoSection(
              castTime: result.castTime,
              lunarInfo: result.lunarInfo,
              liuShen: result.liuShen,
              shenShaInfo: null,
            ),

            // 卦象横向对比布局
            DiagramComparisonRow(
              mainGua: result.mainGua,
              changingGua: result.changingGua,
              liuShen: result.liuShen,
            ),

            // 特殊关系解析区块
            SpecialRelationSection(
              relationType: _getSpecialRelationType(result.mainGua),
              description: _getSpecialRelationDescription(result.mainGua),
            ),

            // AI 分析区块
            Builder(builder: (context) {
              final question =
                  context.select<LiuYaoViewModel, String?>((vm) => vm.question);
              return AIAnalysisWidget(
                result: result,
                question: question,
              );
            }),

            // 底部间距
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

  /// 获取特殊关系类型
  String? _getSpecialRelationType(Gua gua) {
    if (gua.specialType == GuaSpecialType.none) {
      return null;
    }
    return gua.specialType.name;
  }

  /// 获取特殊关系描述
  String? _getSpecialRelationDescription(Gua gua) {
    return switch (gua.specialType) {
      GuaSpecialType.youHun => '游魂卦，主动荡不安，事多变化。',
      GuaSpecialType.guiHun => '归魂卦，主稳定，事归本源。',
      GuaSpecialType.liuChong => '六冲卦，主冲突激烈，事难成。',
      GuaSpecialType.liuHe => '六合卦，主和谐顺利，事易成。',
      GuaSpecialType.none => null,
    };
  }
}
