import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/template/builtin_templates.dart';
import 'package:wanxiang_paipan/ai/template/template_engine.dart';

void main() {
  group('BuiltInTemplates 排盘数据使用约定（system 模板）', () {
    test('六爻 system 模板含排盘数据使用约定三层意思', () {
      final content = BuiltInTemplates.liuYaoSystemPrompt.content;

      expect(content, contains('## 排盘数据使用约定'));
      // 1. 事实基础
      expect(content, contains('断卦分析（规则标注）'));
      expect(content, contains('事实基础'));
      // 2. 禁止重推
      expect(content, contains('不得自行重推'));
      expect(content, contains('装卦'));
      expect(content, contains('世应'));
      expect(content, contains('旺衰标签'));
      // 3. 分歧须显式说明
      expect(content, contains('显式说明分歧理由'));
      expect(content, contains('不得默默替换'));
    });

    test('大六壬 system 模板含排盘数据使用约定三层意思', () {
      final content = BuiltInTemplates.daLiuRenSystemPrompt.content;

      expect(content, contains('## 排盘数据使用约定'));
      // 1. 事实基础
      expect(content, contains('断课分析（规则标注）'));
      expect(content, contains('事实基础'));
      // 2. 禁止重推
      expect(content, contains('不得自行重推'));
      expect(content, contains('三传取法'));
      expect(content, contains('课体判定'));
      expect(content, contains('涉害深度'));
      // 3. 分歧须显式说明
      expect(content, contains('裁决摘要'));
      expect(content, contains('显式说明分歧理由'));
      expect(content, contains('不得默默替换'));
    });
  });

  group('BuiltInTemplates analysis 模板结构调整', () {
    test('六爻 analysis 模板首节解释已判定卦性、综合判断锚定摘要、含应期提示节', () {
      final content = BuiltInTemplates.liuYaoAnalysisPrompt.content;

      expect(content, contains('解释程序已判定的卦性含义'));
      expect(content, contains('以"断卦分析（规则标注）"段的用神状态摘要为基准展开'));
      expect(content, contains('### 7. 应期提示'));
      expect(content, contains('应期候选'));
      expect(content, contains('不得凭空另造应期'));
      expect(content, contains('### 8. 行动建议'));
    });

    test('大六壬 analysis 模板首节解释已判定课体、综合判断锚定裁决摘要、含应期提示节', () {
      final content = BuiltInTemplates.daLiuRenAnalysisPrompt.content;

      expect(content, contains('解释程序已判定的课体（格局）含义'));
      expect(content, contains('以"断课分析（规则标注）"段的裁决摘要为基准展开'));
      expect(content, contains('### 7. 应期提示'));
      expect(content, contains('应期候选'));
      expect(content, contains('不得凭空另造应期'));
      expect(content, contains('### 8. 行动建议'));
    });

    test('brief 模板本次不动', () {
      expect(BuiltInTemplates.liuYaoBriefPrompt.content,
          isNot(contains('应期提示')));
      expect(BuiltInTemplates.daLiuRenBriefPrompt.content,
          isNot(contains('应期提示')));
    });
  });

  group('BuiltInTemplates Handlebars 结构完整性', () {
    final engine = PromptTemplateEngine();

    for (final template in [
      BuiltInTemplates.liuYaoSystemPrompt,
      BuiltInTemplates.liuYaoAnalysisPrompt,
      BuiltInTemplates.daLiuRenSystemPrompt,
      BuiltInTemplates.daLiuRenAnalysisPrompt,
    ]) {
      test('${template.id} 校验通过且可渲染', () {
        final result = engine.validate(template.content);
        expect(result.isValid, isTrue, reason: result.errors.join('; '));

        final rendered = engine.render(template.content, {
          'structuredOutput': '[排盘数据]',
          'question': '问事业',
          'hasQuestion': true,
          'hasMovingYao': true,
          'hasChangingGua': true,
          'customInstructions': '自定义指令',
          'includeAdvice': true,
        });
        expect(rendered, isNotEmpty);
        // 条件块与变量应全部被消费，不残留 Handlebars 语法
        expect(rendered, isNot(contains('{{')));
        expect(rendered, isNot(contains('}}')));
      });
    }
  });
}
