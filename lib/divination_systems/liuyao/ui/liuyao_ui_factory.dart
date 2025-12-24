import 'package:flutter/material.dart';
import '../../../domain/divination_system.dart';
import '../models/gua.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/screens/cast/coin_cast_screen.dart';
import '../../../presentation/screens/cast/time_cast_screen.dart';
import '../../../presentation/screens/cast/manual_cast_screen.dart';
import '../../../presentation/widgets/ai_analysis_widget.dart';
import '../../../presentation/widgets/diagram_comparison_row.dart';
import '../../../presentation/widgets/question_section.dart';
import '../../../presentation/widgets/extended_info_section.dart';
import '../../../presentation/widgets/special_relation_section.dart';
import '../liuyao_result.dart';

/// 六爻 UI 工厂
///
/// 实现 DivinationUIFactory 接口，提供六爻特定的 UI 组件。
/// 复用现有的六爻 UI 组件，确保用户体验保持一致。
class LiuYaoUIFactory implements DivinationUIFactory {
  @override
  DivinationType get systemType => DivinationType.liuYao;

  @override
  Widget buildCastScreen(CastMethod method) {
    switch (method) {
      case CastMethod.coin:
        // 复用现有的摇钱法起卦页面
        return const CoinCastScreen();

      case CastMethod.time:
        // 复用现有的时间起卦页面
        return const TimeCastScreen();

      case CastMethod.manual:
        // 复用现有的手动输入页面
        return const ManualCastScreen();

      default:
        throw UnsupportedError('六爻不支持的起卦方式: ${method.displayName}');
    }
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // TODO: 导航到详情页面
          // Navigator.push(context, MaterialPageRoute(
          //   builder: (_) => buildResultScreen(result),
          // ));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 卦名和时间
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    liuyaoResult.mainGua.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatDateTime(liuyaoResult.castTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 八宫和起卦方式
              Row(
                children: [
                  _buildTag(liuyaoResult.mainGua.baGong.name),
                  const SizedBox(width: 8),
                  _buildTag(liuyaoResult.castMethod.displayName),
                  if (liuyaoResult.hasChangingGua) ...[
                    const SizedBox(width: 8),
                    _buildTag('有变卦', color: Colors.orange),
                  ],
                ],
              ),

              // 如果有变卦，显示变卦信息
              if (liuyaoResult.hasChangingGua) ...[
                const SizedBox(height: 8),
                Text(
                  '变卦：${liuyaoResult.changingGua!.name}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],

              // 农历信息
              const SizedBox(height: 8),
              Text(
                '${liuyaoResult.lunarInfo.yearGanZhi}年 ${liuyaoResult.lunarInfo.monthGanZhi}月 ${liuyaoResult.lunarInfo.riGanZhi}日',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget? buildSystemCard() {
    // 返回六爻系统介绍卡片
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          // TODO: 导航到六爻起卦方式选择页面
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    getSystemIcon(),
                    size: 32,
                    color: getSystemColor(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '六爻',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '周易六爻占卜，通过摇钱法或时间起卦生成卦象，分析世应、六亲、动爻等要素进行占断。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildTag('摇钱法'),
                  _buildTag('时间起卦'),
                  _buildTag('手动输入'),
                ],
              ),
            ],
          ),
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
    return const Color(0xFFD32F2F);
  }

  // ==================== 私有辅助方法 ====================

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 构建标签 Widget
  Widget _buildTag(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color ?? Colors.blue,
        ),
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('排盘结果'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 占问信息区块
            QuestionSection(
              subject: null, // TODO: 从加密存储获取
              question: null, // TODO: 从加密存储获取
            ),

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
            AIAnalysisWidget(
              result: result,
              question: null, // TODO: 从加密存储获取
            ),

            // 底部间距
            const SizedBox(height: 16),
          ],
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
