import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/divination_system.dart';
import '../../domain/repositories/divination_repository.dart';
import '../widgets/ai_analysis_widget.dart';
import '../widgets/antique/antique.dart';

typedef DivinationResultSectionsBuilder = List<Widget> Function(
  BuildContext context,
  String question,
);

/// 统一结果页外壳：
/// - 读取加密占问
/// - 提供统一 AntiqueScaffold / 滚动容器
/// - 在页尾挂载 AI 分析组件
class DivinationResultPage extends StatelessWidget {
  final DivinationResult result;
  final String title;
  final String? fallbackQuestion;
  final DivinationResultSectionsBuilder buildSections;
  final EdgeInsetsGeometry padding;
  final double sectionSpacing;
  final bool includeAiAnalysis;

  const DivinationResultPage({
    super.key,
    required this.result,
    required this.title,
    required this.buildSections,
    this.fallbackQuestion,
    this.padding = const EdgeInsets.all(16),
    this.sectionSpacing = 16,
    this.includeAiAnalysis = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: DivinationQuestionLoader.load(
        context,
        result,
        fallbackQuestion: fallbackQuestion,
      ),
      builder: (context, snapshot) {
        final question = (snapshot.data ?? '').trim();
        final sections = buildSections(context, question);
        final children = _buildChildren(question, sections);

        return AntiqueScaffold(
          appBar: AntiqueAppBar(title: title),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildChildren(String question, List<Widget> sections) {
    final children = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      if (i > 0) {
        children.add(SizedBox(height: sectionSpacing));
      }
      children.add(sections[i]);
    }

    if (includeAiAnalysis) {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: sectionSpacing));
      }
      children.add(
        AIAnalysisWidget(
          result: result,
          question: question.isEmpty ? null : question,
        ),
      );
    }

    return children;
  }
}

class DivinationQuestionLoader {
  static Future<String?> load(
    BuildContext context,
    DivinationResult result, {
    String? fallbackQuestion,
  }) {
    final repository = _tryReadRepository(context);
    return repository?.readEncryptedField('question_${result.id}') ??
        Future<String?>.value(fallbackQuestion);
  }

  static DivinationRepository? _tryReadRepository(BuildContext context) {
    try {
      return context.read<DivinationRepository>();
    } catch (_) {
      return null;
    }
  }
}
