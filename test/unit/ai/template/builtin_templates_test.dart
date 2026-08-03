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
      expect(
        content,
        contains('只解释 timingCandidates 已有窗口'),
      );
      expect(content, contains('policy.verdictMode'));
      expect(content, contains('verdictMode=abstain'));
      expect(content, contains('verdictMode=explainLifecycle'));
      expect(content, contains('verdictMode=explainSelectedVerdict'));
      expect(content, contains('生命周期维度不可用'));
      expect(content, contains('所选用神强弱、扶抑与条件的单轴'));
      expect(content, contains('不得据此判断整件事'));
      expect(content, contains('timingCandidates 为空时'));
      expect(content, contains('conditions 与 timingCandidates 均为空时省略该段'));
      expect(content, contains('formation'));
      expect(content, contains('完整租期持续性'));
      expect(content, contains('仅在 verdictMode=explainLifecycle'));
      expect(content, contains('只把它们列作核验维度'));
    });

    test('六爻生产模板的全应期边界不枚举确定性禁词', () {
      const boundary = '不得把程序未授权的推演、状态或观察写成无条件成立的事项结果，也不得以确定性结果措辞扩展程序裁决';
      final forbiddenDeterminism = RegExp(r'必然|必定|保证|一定');

      for (final content in <String>[
        BuiltInTemplates.liuYaoSystemPrompt.content,
        BuiltInTemplates.liuYaoAnalysisPrompt.content,
        BuiltInTemplates.liuYaoBriefPrompt.content,
      ]) {
        expect(content, contains(boundary));
        expect(content, contains('无论 timingCandidates 是否为空'));
        expect(content, contains('output contract 给出的应期锚点'));
        expect(forbiddenDeterminism.hasMatch(content), isFalse);
      }
      expect(
        BuiltInTemplates.liuYaoSystemPrompt.content,
        contains(
          'explainLifecycle 仍须原值输出已授权的 lifecycleVerdict',
        ),
      );
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
    test('六爻 analysis 模板按授权段落组织生命周期证据链', () {
      final content = BuiltInTemplates.liuYaoAnalysisPrompt.content;

      const headings = [
        '### 1. 日历与问题边界',
        '### 2. 取用与结论模式',
        '### 3. 生命周期阶段裁决',
        '### 4. 所选用神与另一现',
        '### 5. 全爻主证、反证与阶段作用',
        '### 6. 世应、合同、费用与持续履约',
        '### 7. 六合、六神与卦名权限',
        '### 8. 未决条件与应期观察窗',
        '### 9. 古籍与项目依据',
        '### 10. 核验建议与不确定性',
      ];
      var previousIndex = -1;
      for (final heading in headings) {
        final index = content.indexOf(heading);
        expect(index, greaterThan(previousIndex), reason: heading);
        previousIndex = index;
      }
      expect(content, contains('from → to'));
      expect(content, contains('decision row'));
      expect(content, contains('conditions 的 scope、dimension、hasRescue'));
      expect(content, contains('exactQuote、paraphrase、projectConvention'));
      expect(content, contains('locatorOnly'));
      expect(content, contains('formation'));
      expect(content, contains('quality'));
      expect(content, contains('continuity'));
      expect(content, contains('persistence'));
      expect(content, contains('出租权与合同主体'));
      expect(content, contains('收费是否完整合理'));
      expect(content, contains('selectedUseSpiritAxis'));
      expect(content, contains('必须跳过第 8 段'));
      expect(content, contains('不写标题或缺省说明'));
      expect(content, contains('verdictMode=abstain 时不执行下列十段顺序'));
      expect(content, contains('两组列表并立即结束'));
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
        '### 1. 日历与问题边界',
        '### 2. 取用与结论模式',
        '### 3. 生命周期阶段裁决',
        '### 4. 所选用神与另一现',
        '### 5. 全爻主证、反证与阶段作用',
        '### 6. 世应、合同、费用与持续履约',
        '### 7. 六合、六神与卦名权限',
        '### 8. 全部未决条件与已给应期观察窗',
        '### 9. 实际古籍与项目来源',
        '### 10. 核验建议与不确定性',
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
      expect(content, contains('verdictMode=abstain'));
      expect(content, contains('verdictMode=explainSelectedVerdict'));
      expect(content, contains('verdict.trend'));
      expect(content, contains('selectedUseSpiritAxis'));
      expect(content, contains('必须跳过第 8 段'));
      expect(content, contains('不写标题或缺省说明'));
      expect(content, contains('verdictMode=abstain 时不执行下列十段顺序'));
      expect(content, contains('两组列表并立即结束'));
      expect(
          content, contains('formation → quality → continuity → persistence'));
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
