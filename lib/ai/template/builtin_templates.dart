/// 内置提示词模板
///
/// 定义各术数系统的默认提示词模板。
library;

import 'package:uuid/uuid.dart';
import 'prompt_template.dart';

/// 内置模板管理
class BuiltInTemplates {
  static const _uuid = Uuid();

  /// 六爻系统提示词模板
  static PromptTemplate get liuYaoSystemPrompt => PromptTemplate(
        id: 'builtin_liuyao_system',
        name: '六爻系统提示词（默认）',
        description: '定义 AI 的角色和分析规则',
        systemType: 'liuyao',
        templateType: 'system',
        isBuiltIn: true,
        isActive: true,
        content: '''
你是一位精通六爻占卜的资深易学专家，拥有深厚的周易理论功底和丰富的实战经验。

## 你的专业领域
- 六爻纳甲体系（京房易学）
- 六亲生克制化关系
- 六神象意解读（青龙、朱雀、勾陈、螣蛇、白虎、玄武）
- 空亡、月破、日破判断
- 动爻变化及其影响分析
- 世应关系与用神取用

## 分析原则
1. 先观卦象整体格局，判断卦气旺衰
2. 以用神为核心，分析其生旺墓绝、动静变化
3. 重点关注动爻，动爻是事情变化的关键
4. 结合世应关系判断事情发展方向
5. 考虑空亡、月建、日辰对各爻的影响
6. 给出清晰、有条理的解读，避免模棱两可

## 分析顺序
1. 卦名卦宫，判断卦性（六冲、六合、游魂、归魂）
2. 世应位置及其爻位含义
3. 用神取用及用神状态
4. 动爻变化分析
5. 六神配合解读
6. 综合判断与建议

{{#if customInstructions}}
## 用户自定义指令
{{customInstructions}}
{{/if}}
''',
      );

  /// 六爻综合分析模板
  static PromptTemplate get liuYaoAnalysisPrompt => PromptTemplate(
        id: 'builtin_liuyao_analysis',
        name: '六爻综合分析模板（默认）',
        description: '全面分析卦象的默认模板',
        systemType: 'liuyao',
        templateType: 'analysis',
        isBuiltIn: true,
        isActive: true,
        content: '''
请根据以下排盘信息进行专业解读：

{{structuredOutput}}

{{#if question}}
【求测问题】{{question}}

请针对上述问题，结合卦象进行解读。
{{else}}
请对此卦进行全面解读。
{{/if}}

## 请按以下结构输出分析：

### 1. 卦象概述
简要介绍本卦的基本含义、所属宫位、卦性特点{{#if hasChangingGua}}，以及变卦的含义{{/if}}。

### 2. 世应分析
分析世爻和应爻的位置、强弱及其关系。世爻代表求测者，应爻代表所求之事或对方。

{{#if question}}
### 3. 用神分析
根据所问之事确定用神，分析用神的旺衰、动静、空亡等状态。
{{/if}}

{{#if hasMovingYao}}
### 4. 动爻解读
详细分析各动爻的变化：
- 动爻的六亲属性及象意
- 变爻后的状态变化
- 动爻对其他爻的生克影响
{{/if}}

### 5. 六神参考
结合六神的象意辅助判断事情的性质和特点。

### 6. 综合判断
综合以上分析，给出最终的判断结论。

{{#if includeAdvice}}
### 7. 行动建议
根据卦象给出具体的行动建议和注意事项。
{{/if}}
''',
      );

  /// 六爻简要分析模板
  static PromptTemplate get liuYaoBriefPrompt => PromptTemplate(
        id: 'builtin_liuyao_brief',
        name: '六爻简要分析模板',
        description: '快速简要的卦象解读',
        systemType: 'liuyao',
        templateType: 'analysis',
        isBuiltIn: true,
        isActive: false,
        content: '''
请根据以下排盘信息进行简要解读：

{{structuredOutput}}

{{#if question}}
【求测问题】{{question}}
{{/if}}

请用简洁的语言（200字以内）概括此卦的核心含义和主要提示。
''',
      );

  /// 六爻问题引导模板
  static PromptTemplate get liuYaoQuestionPrompt => PromptTemplate(
        id: 'builtin_liuyao_question',
        name: '六爻问题引导模板',
        description: '针对具体问题的分析引导',
        systemType: 'liuyao',
        templateType: 'question',
        isBuiltIn: true,
        isActive: true,
        content: '''
用户的问题是：{{question}}

请根据问题类型确定用神：
- 问事业/工作：以官鬼为用神
- 问财运/求财：以妻财为用神
- 问婚姻/感情：男问以妻财为用神，女问以官鬼为用神
- 问健康/疾病：以官鬼为病，子孙为药
- 问考试/学业：以父母为用神
- 问出行/行人：以世爻为自己，应爻为目的地

针对此问题进行重点分析。
''',
      );

  /// 获取所有内置模板
  static List<PromptTemplate> getAll() => [
        liuYaoSystemPrompt,
        liuYaoAnalysisPrompt,
        liuYaoBriefPrompt,
        liuYaoQuestionPrompt,
        // 未来添加其他系统的模板...
      ];

  /// 获取指定系统的内置模板
  static List<PromptTemplate> getBySystem(String systemType) {
    return getAll().where((t) => t.systemType == systemType).toList();
  }

  /// 获取指定系统的默认系统提示词
  static PromptTemplate? getDefaultSystemPrompt(String systemType) {
    return getAll().where((t) =>
        t.systemType == systemType &&
        t.templateType == 'system' &&
        t.isActive).firstOrNull;
  }

  /// 获取指定系统的默认分析模板
  static PromptTemplate? getDefaultAnalysisPrompt(String systemType) {
    return getAll().where((t) =>
        t.systemType == systemType &&
        t.templateType == 'analysis' &&
        t.isActive).firstOrNull;
  }

  /// 创建用户自定义模板（基于内置模板）
  static PromptTemplate createCustomTemplate({
    required String name,
    required String systemType,
    required String templateType,
    required String content,
    String description = '',
  }) {
    return PromptTemplate(
      id: _uuid.v4(),
      name: name,
      description: description,
      systemType: systemType,
      templateType: templateType,
      content: content,
      isBuiltIn: false,
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
