import 'package:flutter/material.dart';
import '../../../divination_systems/liuyao/models/gua.dart';
import '../../../models/lunar_info.dart';
import '../../../domain/divination_system.dart';
import '../../widgets/diagram_comparison_row.dart';
import '../../widgets/question_section.dart';
import '../../widgets/extended_info_section.dart';
import '../../widgets/special_relation_section.dart';

/// 卦象结果展示界面
///
/// 注意：此界面仅用于展示结果，不负责保存记录
/// 记录已在 LiuYaoViewModel 中自动保存到数据库
///
/// 布局改进：
/// 1. 横向对比布局（本卦 | 动爻标记 | 变卦）
/// 2. 紧凑表格样式
/// 3. 占问信息区块
/// 4. 扩展信息区块（农历、节气、神煞）
/// 5. 特殊关系解析区块
class ResultScreen extends StatelessWidget {
  final Gua mainGua;
  final Gua? changingGua;
  final LunarInfo lunarInfo;
  final List<String> liuShen;
  final CastMethod castMethod;

  /// 占卜时间
  final DateTime? castTime;

  /// 占问主题（可选）
  final String? questionSubject;

  /// 占问问题（可选）
  final String? questionDetail;

  /// 神煞信息（可选）
  final String? shenShaInfo;

  /// 特殊关系类型（可选）
  final String? specialRelationType;

  /// 特殊关系描述（可选）
  final String? specialRelationDescription;

  const ResultScreen({
    super.key,
    required this.mainGua,
    this.changingGua,
    required this.lunarInfo,
    required this.liuShen,
    required this.castMethod,
    this.castTime,
    this.questionSubject,
    this.questionDetail,
    this.shenShaInfo,
    this.specialRelationType,
    this.specialRelationDescription,
  });

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
              subject: questionSubject,
              question: questionDetail,
            ),

            // 扩展信息区块（农历、节气、神煞）
            ExtendedInfoSection(
              castTime: castTime ?? DateTime.now(),
              lunarInfo: lunarInfo,
              liuShen: liuShen,
              shenShaInfo: shenShaInfo,
            ),

            // 卦象横向对比布局（核心改进）
            DiagramComparisonRow(
              mainGua: mainGua,
              changingGua: changingGua,
              liuShen: liuShen,
            ),

            // 特殊关系解析区块
            SpecialRelationSection(
              relationType: specialRelationType,
              description: specialRelationDescription,
            ),

            // 底部间距
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
