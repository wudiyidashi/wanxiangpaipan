import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/template/builtin_templates.dart';
import 'package:wanxiang_paipan/ai/template/template_engine.dart';

void main() {
  group('BuiltInTemplates 排盘数据使用约定（system 模板）', () {
    test('六爻 system 模板锁定程序计算权、取用与古籍边界', () {
      final content = BuiltInTemplates.liuYaoSystemPrompt.content;

      expect(content, contains('## 排盘数据使用约定'));
      expect(content, contains('断卦分析（规则标注）'));
      expect(content, contains('事实基础'));
      expect(content, contains('不得自行重推'));
      expect(content, contains('装卦'));
      expect(content, contains('世应'));
      expect(content, contains('不得覆盖程序四值裁决'));
      expect(content, contains('不得用吉凶标签数量重新打分'));
      expect(content, contains('用户已选用神时必须沿用'));
      expect(content, contains('页级短引'));
      expect(content, contains('没有 exactQuote 时一律转述'));
      expect(content, contains('应期只解释为条件解除或状态成熟的观察窗口'));
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

    test('奇门 system 模板锁定程序唯一计算方与不可覆盖策略', () {
      final content = BuiltInTemplates.qimenSystemPrompt.content;

      expect(content, contains('calculationOwner=program'));
      expect(content, contains('不得重排九宫'));
      expect(content, contains('重算盘面或重算规则分析'));
      expect(content, contains('mayOverrideVerdict=false'));
      expect(content, contains('不承诺事件一定发生'));
    });
  });

  group('BuiltInTemplates analysis 模板结构调整', () {
    test('六爻 analysis 模板按固定九段证据链输出', () {
      final content = BuiltInTemplates.liuYaoAnalysisPrompt.content;

      const headings = [
        '### 1. 问题与取用边界',
        '### 2. 盘面与世应',
        '### 3. 日月与用神状态',
        '### 4. 动变与作用链',
        '### 5. 程序裁决与反证',
        '### 6. 未决条件',
        '### 7. 应期观察窗',
        '### 8. 古籍与项目依据',
        '### 9. 有边界的建议',
      ];
      var previousIndex = -1;
      for (final heading in headings) {
        final index = content.indexOf(heading);
        expect(index, greaterThan(previousIndex), reason: heading);
        previousIndex = index;
      }
      expect(content, contains('from → to'));
      expect(content, contains('matched decision row'));
      expect(content, contains('conditions、hasRescue'));
      expect(content, contains('exactQuote、paraphrase、projectConvention'));
      expect(content, contains('locatorOnly'));
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

    test('六爻 brief 模板保留全部条件、应期和来源边界', () {
      final content = BuiltInTemplates.liuYaoBriefPrompt.content;

      const headings = [
        '### 1. 问题与取用边界',
        '### 2. 盘面与世应',
        '### 3. 日月与用神状态',
        '### 4. 动变与作用链',
        '### 5. 程序裁决与反证',
        '### 6. 全部未决条件',
        '### 7. 已给应期观察窗',
        '### 8. 实际古籍与项目来源',
        '### 9. 有边界的建议',
      ];
      var previousIndex = -1;
      for (final heading in headings) {
        final index = content.indexOf(heading);
        expect(index, greaterThan(previousIndex), reason: heading);
        previousIndex = index;
      }
      expect(content, contains('全部未决条件'));
      expect(content, contains('已给应期观察窗'));
      expect(content, contains('实际古籍与项目来源'));
      expect(content, contains('不得重算、重选、覆盖裁决'));
      expect(BuiltInTemplates.daLiuRenBriefPrompt.content,
          isNot(contains('应期提示')));
    });

    test('奇门 analysis 与 brief 模板只解释程序投影', () {
      final analysis = BuiltInTemplates.qimenAnalysisPrompt.content;
      final brief = BuiltInTemplates.qimenBriefPrompt.content;

      expect(analysis, contains('{{structuredOutput}}'));
      expect(analysis, contains('不得改成百分比、星级或加权评分'));
      expect(analysis, contains('不得作为独立裁决依据重复计算'));
      expect(brief, contains('不得重排、重算或覆盖裁决'));
      expect(BuiltInTemplates.getBySystem('qimen'), hasLength(3));
    });
  });

  group('BuiltInTemplates Handlebars 结构完整性', () {
    final engine = PromptTemplateEngine();

    for (final template in [
      BuiltInTemplates.liuYaoSystemPrompt,
      BuiltInTemplates.liuYaoAnalysisPrompt,
      BuiltInTemplates.liuYaoBriefPrompt,
      BuiltInTemplates.daLiuRenSystemPrompt,
      BuiltInTemplates.daLiuRenAnalysisPrompt,
      BuiltInTemplates.qimenSystemPrompt,
      BuiltInTemplates.qimenAnalysisPrompt,
      BuiltInTemplates.qimenBriefPrompt,
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
