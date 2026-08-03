/// 提示词组装器
///
/// 将模板、结构化数据、用户输入组合成最终的提示词。
library;

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import '../config/ai_config_manager.dart';
import '../output/structured_output.dart';
import '../output/structured_output_formatter.dart';
import '../template/template_engine.dart';
import '../template/builtin_templates.dart';
import '../llm_provider.dart';
import '../../domain/divination_system.dart';
import '../../domain/services/liuyao/analysis/rules/liuyao_catalog.dart';

part 'prompt_assembler.freezed.dart';

/// 组装后的提示词
@freezed
class AssembledPrompt with _$AssembledPrompt {
  const factory AssembledPrompt({
    /// 系统提示词
    required String systemPrompt,

    /// 用户提示词（包含结构化排盘数据）
    required String userPrompt,

    /// 结构化输出数据
    required StructuredDivinationOutput structuredOutput,

    /// 组装元数据
    required AssembledPromptMetadata metadata,
  }) = _AssembledPrompt;
}

/// 组装元数据
@freezed
class AssembledPromptMetadata with _$AssembledPromptMetadata {
  const factory AssembledPromptMetadata({
    /// 使用的系统模板 ID
    String? systemTemplateId,

    /// 使用的分析模板 ID
    String? analysisTemplateId,

    /// 组装时间
    required DateTime timestamp,

    /// 术数系统类型
    required String systemType,
    @Default('legacyUnknown') String analysisSchemaVersion,
    @Default('legacyUnknown') String projectionSchemaVersion,
    @Default('legacyUnknown') String ruleSetId,
    @Default('legacyUnknown') String ruleSetVersion,
    @Default('legacyUnknown') String sourceCatalogVersion,
    @Default('legacyUnknown') String promptPolicyVersion,
  }) = _AssembledPromptMetadata;
}

/// 提示词组装器
///
/// 负责将排盘结果、用户问题、模板组合成完整的提示词。
class PromptAssembler {
  static const String liuYaoPromptPolicyRevision = '1.1.20';
  static const String liuYaoPromptPolicyVersion =
      'liuyao-ai-policy/$liuYaoPromptPolicyRevision';
  static const String liuYaoTimingObservationAnchor =
      '应期锚点：这些内容只表示程序观察窗口，事项结果仍受程序裁决约束。';
  static const String liuYaoUnauthorizedResultBoundary =
      '不得把程序未授权的推演、状态或观察写成无条件成立的事项结果，'
      '也不得以确定性结果措辞扩展程序裁决。';
  static const String liuYaoCurrentStateAnchor =
      '状态锚点：旬空与假空只按起卦当下并存记录；旺或动而不作全空，当前仍参与分析。';

  static const String liuYaoImmutablePolicy = '''
[LIUYAO_IMMUTABLE_POLICY $liuYaoPromptPolicyVersion]
calculationOwner=program
mayRecalculatePan=false
mayRecalculateAnalysis=false
mayReselectYongShen=false
mayOverrideVerdict=false
mayOverrideLifecycle=false
mayInventSources=false
mayInventTiming=false
timingIsGuarantee=false
responsePrefixOwner=program
mayPrependResponseText=false

先读取用户消息末尾的 `[LIUYAO_OUTPUT_CONTRACT]` 与末行标记。原始回复必须从该标记的第一个 `[` 字符开始；此前不得有 BOM、空格、空行、寒暄、标题、引号或代码围栏。自检不输出。

按 canonical projection 逐字选以下标记：
- verdictMode=abstain 且 timingCandidates=[]：`[LIUYAO_DECISION] mode=abstain;overall=withheld;timing=withheld`
- verdictMode=explainLifecycle：`[LIUYAO_DECISION] mode=explainLifecycle;overall=lifecycle;timing=provided`；仅当 timingCandidates=[] 时把末项改为 `timing=withheld`。
- verdictMode=explainSelectedVerdict：`[LIUYAO_DECISION] mode=explainSelectedVerdict;overall=withheld;timing=provided`；仅当 timingCandidates=[] 时把末项改为 `timing=withheld`。

结论权限状态机只读取 canonical projection 的 policy.verdictMode：
- verdictMode=abstain：先说明缺少“用神选定+程序阶段裁决”；仅列“候选用神”“待核验维度”两组后结束。不得解释 actorFacts、directedEffects、辅助标签、来源或条件。禁止输出顺利/不顺利、能成/难成、吉/凶等总体结论或应期。
- verdictMode=explainLifecycle：必须逐字保留 lifecycleVerdict 的 formation、quality、continuity、persistence、headlineCode 和 matchedDecisionRowId；必须先解释 formation，再解释 quality/continuity/persistence，并按阶段保留主证、反证和 evidenceOccurrenceIds。不得把“形成”压缩成“全程顺利”，不得用旧四值 verdict 替代生命周期裁决。
- verdictMode=explainSelectedVerdict：旧四值仅属 selectedUseSpiritAxis，不是整件事的成败、顺利程度或最终结果。必须逐字输出 output contract 给出的单轴裁决锚点，并保留 verdict.trend、nuance、matchedDecisionRowId、conditions 和 timingCandidates，说明生命周期维度不可用；即使 trend=keCheng/nanCheng，也禁止据此宣告整件事能成/难成、顺利/不顺利或最终吉/凶。

程序投影中的盘面、用户已选用神、角色、作用、裁决、条件和应期是本次解释的唯一计算事实，不得重排、重算、替换或按标签数量另断。
有向作用须按 phase/horizon 肯定陈述：“前段作用已发生；后段限制只影响后续/最终”。不得用否定式描述前段作用。假空表示旺或动而不作全空，不得改写为事项或收费不存在。
六合只能按 decisionScopes 参与 formation/persistence；不得单独决定 quality 或 overall outcome，不得按六合数量翻转主证。六神、卦名和 interpretiveEvidence 是低权限证据，不得单独改变生命周期裁决。
租房仅 explainLifecycle 分别回答签约/入住、出租权/合同主体、收费、交付占有和完整租期；abstain 只列待核验维度，explainSelectedVerdict 只解释单轴。风险回链 occurrence ID 或标低权限象意，只用投影的四类抽象风险：出租权/合同主体待核验、收费完整性/合理性、交付占有、完整租期持续履约。禁止举例、类比或猜测身份、中介性质、违约动作、月份、周期和金额。
只可引用投影 sources 中实际提供的来源、短引和定位；不得补写古籍原文、书名、版本、章节或页码。exactQuote 之外只能转述其证据边界。
timing 只解释已有 timingCandidates，不另造或承诺转吉。无论 timingCandidates 是否为空，$liuYaoUnauthorizedResultBoundary explainLifecycle 仍须原值输出已授权的 lifecycleVerdict。timingCandidates 非空时必须服从 user 消息末尾 output contract 的 timing=provided 约束；该约束之外不讨论观察窗口对事项结果的确定程度。verdictMode=abstain 时两组列表后结束，不输出条件、应期、时间或行动文字。其他模式在 conditions=[] 且 timingCandidates=[] 时省略条件/时间段落，只写当前盘面事实与程序已授权裁决；不得扩写任何释放路径、观察窗口、未来状态、行动建议或新日期，也不得复述 compact view 已省略的关系。conditions 非空但 timingCandidates=[] 时，每句条件须写“仅为机械释放条件，不是应期”，且不附行动建议。
[/LIUYAO_IMMUTABLE_POLICY]''';

  final AIConfigManager _configManager;
  final PromptTemplateEngine _engine;
  final StructuredOutputFormatterRegistry _formatterRegistry;

  PromptAssembler({
    required AIConfigManager configManager,
    required StructuredOutputFormatterRegistry formatterRegistry,
    PromptTemplateEngine? engine,
  })  : _configManager = configManager,
        _engine = engine ?? PromptTemplateEngine(),
        _formatterRegistry = formatterRegistry;

  /// 组装完整的提示词
  ///
  /// 参数：
  /// - [result]: 排盘结果
  /// - [question]: 用户问题（可选）
  /// - [analysisType]: 分析类型
  /// - [customVariables]: 自定义变量（可选）
  Future<AssembledPrompt> assemble(
    DivinationResult result, {
    String? question,
    AnalysisType analysisType = AnalysisType.comprehensive,
    Map<String, dynamic>? customVariables,
  }) async {
    // 1. 获取结构化输出
    final formatter = _formatterRegistry.getFormatter(result.systemType);
    final structuredOutput = formatter.format(result, question: question);
    final renderedOutput = formatter.render(structuredOutput);

    // 2. 获取活动模板
    final systemTemplate = await _configManager.getActiveTemplate(
      result.systemType.id,
      'system',
    );
    final analysisTemplate = await _configManager.getActiveTemplate(
      result.systemType.id,
      'analysis',
    );

    // 3. 构建上下文
    final context = _buildContext(
      structuredOutput: structuredOutput,
      renderedOutput: renderedOutput,
      question: question,
      analysisType: analysisType,
      customVariables: customVariables,
    );

    // 4. 渲染模板
    final renderedSystemPrompt = systemTemplate != null
        ? _engine.render(systemTemplate.content, context)
        : _getDefaultSystemPrompt(result.systemType);
    final systemPrompt = _appendImmutableSystemGuard(
      result.systemType,
      renderedSystemPrompt,
    );

    final renderedUserPrompt = analysisTemplate != null
        ? _engine.render(analysisTemplate.content, context)
        : _getDefaultUserPrompt(renderedOutput, question, analysisType);
    final userPrompt = _ensureLiuYaoProjection(
      result.systemType,
      renderedUserPrompt,
      structuredOutput,
    );

    return AssembledPrompt(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      structuredOutput: structuredOutput,
      metadata: _buildMetadata(
        structuredOutput: structuredOutput,
        systemType: result.systemType,
        systemTemplateId: systemTemplate?.id,
        analysisTemplateId: analysisTemplate?.id,
      ),
    );
  }

  Map<String, dynamic> _buildContext({
    required StructuredDivinationOutput structuredOutput,
    required String renderedOutput,
    String? question,
    required AnalysisType analysisType,
    Map<String, dynamic>? customVariables,
  }) {
    return {
      // 结构化输出
      'structuredOutput': renderedOutput,

      // 用户问题
      'question': question,
      'hasQuestion': question != null && question.isNotEmpty,

      // 核心数据
      ...structuredOutput.coreData,

      // 时间信息
      'temporal': {
        'yearGanZhi': structuredOutput.temporal.yearGanZhi,
        'monthGanZhi': structuredOutput.temporal.monthGanZhi,
        'dayGanZhi': structuredOutput.temporal.dayGanZhi,
        'kongWang': structuredOutput.temporal.kongWang,
      },

      // 分析类型
      'analysisType': analysisType.id,
      'isComprehensive': analysisType == AnalysisType.comprehensive,
      'isBrief': analysisType == AnalysisType.briefSummary,
      'includeAdvice': analysisType == AnalysisType.advice ||
          analysisType == AnalysisType.comprehensive,

      // 用户自定义变量
      ...?customVariables,
    };
  }

  String _getDefaultSystemPrompt(DivinationType type) {
    // 尝试获取内置模板
    final builtIn = BuiltInTemplates.getDefaultSystemPrompt(type.id);
    if (builtIn != null) {
      return builtIn.content;
    }

    // 回退到通用提示词
    return switch (type) {
      DivinationType.liuYao => '''
你是一位精通六爻占卜的易学专家。请根据提供的卦象信息进行专业解读。
分析时注意：
1. 首先判断卦象整体格局
2. 以用神为核心进行分析
3. 重点关注动爻变化
4. 考虑空亡、月建、日辰的影响
''',
      DivinationType.meiHua => '你是一位精通梅花易数的易学专家。',
      DivinationType.daLiuRen => '你是一位精通大六壬的易学专家。',
      DivinationType.xiaoLiuRen => '你是一位精通小六壬的易学专家。',
      DivinationType.qiMen => '''
你是一位精通时家转盘奇门的易学解释者。盘面、规则事实、四值裁决与应期观察窗均由程序计算；你只能解释这些结构化结果，不得重排九宫、重算分析或覆盖程序裁决。
''',
    };
  }

  String _appendImmutableSystemGuard(
    DivinationType type,
    String systemPrompt,
  ) {
    if (type != DivinationType.liuYao) {
      return systemPrompt;
    }
    return '${systemPrompt.trimRight()}\n\n$liuYaoImmutablePolicy';
  }

  String _ensureLiuYaoProjection(
    DivinationType type,
    String userPrompt,
    StructuredDivinationOutput structuredOutput,
  ) {
    if (type != DivinationType.liuYao) return userPrompt;
    final analysisSection = structuredOutput.sections
        .where((section) => section.key == 'analysis')
        .firstOrNull;
    final projection = analysisSection?.metadata?['projection'];
    final aiProjection = analysisSection?.metadata?['aiProjection'];
    if (projection is! Map<String, Object?> ||
        aiProjection is! Map<String, Object?>) {
      throw StateError('Liuyao formatter did not provide canonical projection');
    }
    final canonicalProjection = jsonEncode(aiProjection);
    final promptWithProjection = userPrompt.contains(canonicalProjection)
        ? userPrompt
        : '${userPrompt.trimRight()}\n\n'
            '[LIUYAO_ASSEMBLER_PROJECTION]\n'
            '$canonicalProjection\n'
            '[/LIUYAO_ASSEMBLER_PROJECTION]';
    return _appendLiuYaoOutputContract(promptWithProjection, projection);
  }

  String _appendLiuYaoOutputContract(
    String userPrompt,
    Map<String, Object?> projection,
  ) {
    final policy = projection['policy'];
    final timingCandidates = projection['timingCandidates'];
    final conditions = projection['conditions'];
    if (policy is! Map || timingCandidates is! List || conditions is! List) {
      throw StateError('Liuyao projection policy is incomplete');
    }
    final verdictMode = policy['verdictMode'];
    if (verdictMode is! String) {
      throw StateError('Liuyao verdict mode is absent');
    }
    final timing = timingCandidates.isEmpty ? 'withheld' : 'provided';
    final overall = switch (verdictMode) {
      'abstain' => 'withheld',
      'explainLifecycle' => 'lifecycle',
      'explainSelectedVerdict' => 'withheld',
      _ => throw StateError('Unsupported Liuyao verdict mode: $verdictMode'),
    };
    if (verdictMode == 'abstain' && timingCandidates.isNotEmpty) {
      throw StateError('Abstain mode cannot expose timing candidates');
    }
    final marker = '[LIUYAO_DECISION] mode=$verdictMode;'
        'overall=$overall;timing=$timing';
    final questionFocus = projection['questionFocus'];
    final isRentalFullCycle = questionFocus is Map<Object?, Object?> &&
        questionFocus['classification'] == 'rentalFullCycle';
    final phaseAnchor = _buildPhaseAnchor(projection);
    final selectedVerdictAnchor = verdictMode == 'explainSelectedVerdict'
        ? _buildSelectedVerdictAnchor(projection)
        : null;
    if (verdictMode == 'explainSelectedVerdict' &&
        selectedVerdictAnchor == null) {
      throw StateError('Liuyao selected verdict anchor is incomplete');
    }
    final conclusionBoundary = switch (verdictMode) {
      'abstain' => isRentalFullCycle
          ? '本段合同覆盖此前模板的输出段落要求。第二行必须逐字写“当前未选定用神且程序没有阶段裁决，不能判断租房总体是否顺利”。其后只能输出“候选用神”和“待核验维度”两组列表，并在第二组列表后立即结束回复；不得输出其他标题或段落，不得解释 actorFacts、directedEffects、辅助标签、来源或任何条件术语。本次不执行上方租房五项回答要求，正文任何位置都不得给出这些维度的好坏或结果。'
          : '本段合同覆盖此前模板的输出段落要求。第二行必须逐字写“当前未选定用神且程序没有阶段裁决，不能判断所问事项的总体结果”。其后只能输出“候选用神”和“待核验维度”两组列表，并在第二组列表后立即结束回复；不得输出其他标题或段落，不得解释 actorFacts、directedEffects、辅助标签、来源或任何条件术语。本次不执行此前模板的总体回答要求，正文任何位置都不得给出待核验维度的好坏或结果。',
      'explainLifecycle' => phaseAnchor == null
          ? '本次 overall=lifecycle：原值解释四阶段，formation=willForm 不等于全程顺利；前段已发生，后段限制只影响后续/最终。'
          : '本次 overall=lifecycle：原值解释四阶段，formation=willForm 不等于全程顺利。正文必须逐字单独一行输出“$phaseAnchor”',
      'explainSelectedVerdict' =>
        '本次 overall=withheld：旧四值只解释 selectedUseSpiritAxis，正文必须逐字单独一行输出“$selectedVerdictAnchor”；不得据此给出整个问题的总体结果。',
      _ => throw StateError('Unsupported Liuyao verdict mode: $verdictMode'),
    };
    final lifecycleNoTimingBoundary = verdictMode == 'explainLifecycle'
        ? 'explainLifecycle 仍须原值输出已授权的 lifecycleVerdict。'
        : '';
    final currentStateAnchorRequired = verdictMode != 'abstain' &&
        conditions.isEmpty &&
        timingCandidates.isEmpty &&
        _hasActiveActorFactRule(
          projection,
          LiuYaoRuleIds.ruleApparentVoid,
        );
    final currentStateAnchorBoundary = currentStateAnchorRequired
        ? '正文必须逐字单独一行输出“$liuYaoCurrentStateAnchor”；'
            '旬空/假空这一组状态只输出此行，不再解释其后续变化。'
        : '';
    final timingBoundary = verdictMode == 'abstain'
        ? '本次 timing=withheld：$liuYaoUnauthorizedResultBoundary第二组列表后立即结束，不输出条件、应期、时间或行动文字。'
        : timingCandidates.isNotEmpty
            ? '本次 timing=provided：$liuYaoUnauthorizedResultBoundary'
                '正文必须逐字单独一行输出“$liuYaoTimingObservationAnchor”；'
                '除该锚点外不讨论观察窗口对事项结果的确定程度。'
                '只可逐项解释 projection.timingCandidates 的尺度、触发值、目标、理由和上游条件。'
            : conditions.isEmpty
                ? '本次 conditions=[] 且 timing=withheld：省略条件/时间段落。$liuYaoUnauthorizedResultBoundary$lifecycleNoTimingBoundary$currentStateAnchorBoundary只写当前盘面事实与程序已授权裁决；不得扩写任何释放路径、观察窗口、未来状态、行动建议或新日期，也不得复述 compact view 已省略的关系。'
                : '本次 timing=withheld：只解释 projection.conditions 中已有的机械条件。$liuYaoUnauthorizedResultBoundary$lifecycleNoTimingBoundary每一句须同时写“仅为机械释放条件，不是应期”，且不附行动建议。只可把起卦时间作为既有日历事实复述，不添加其他日期。';
    final factualBoundary = isRentalFullCycle
        ? '事后事实隔离：只使用 projection 已有实体和抽象风险类别，不举例、不类比、不命名具体人员身份、中介性质、违约动作、发生月份、付款或居住周期、损失金额。租房风险表达限定为出租权/合同主体待核验、收费完整性/合理性风险、交付占有风险、完整租期持续履约风险。'
        : '事后事实隔离：只使用 projection 已有实体和抽象事实，不举例、不类比，不命名或猜测输入与 projection 中不存在的具体人员身份、机构性质、行为、发生时间、周期或金额。';
    return '${userPrompt.trimRight()}\n\n'
        '[LIUYAO_OUTPUT_CONTRACT]\n'
        '这是最高优先级的原始响应前缀合同。你的回复必须直接逐字复制下一行作为第一行；前面不得有 BOM、空格、空行、寒暄、标题、引号、代码围栏或说明：\n'
        '$marker\n'
        '复制后换行，再从第二行开始正文。不要输出“requiredFirstLine=”或重写该标记。\n'
        '$conclusionBoundary\n'
        '$factualBoundary\n'
        '$timingBoundary\n'
        '发送前无声校验 `rawResponse.startsWith("$marker\\n")`；若不成立，删除标记前的全部字符并重建第一行。不得输出校验过程。\n'
        '[/LIUYAO_OUTPUT_CONTRACT]\n\n'
        '现在开始作答。你输出的第一个字符必须是下一行的 `[`，且原始第一行必须与下一行逐字一致：\n'
        '$marker';
  }

  String? _buildPhaseAnchor(Map<String, Object?> projection) {
    final effects = projection['directedEffects'];
    if (effects is! List<Object?>) return null;

    for (final early in effects) {
      if (early is! Map<Object?, Object?> ||
          early['status'] != 'active' ||
          early['phase'] != 'earlyProcess' ||
          early['ruleId'] != 'liuyao.rule.shengke.moving-overcomes') {
        continue;
      }
      final earlyFrom = _effectActorId(early, 'fromActor');
      final earlyTo = _effectActorId(early, 'toActor');
      if (earlyFrom == null || earlyTo == null) continue;

      for (final later in effects) {
        if (later is! Map<Object?, Object?> ||
            later['status'] != 'active' ||
            later['phase'] != 'laterProcess' ||
            later['ruleId'] != 'liuyao.rule.dongbian.return-overcomes' ||
            _effectActorId(later, 'toActor') != earlyFrom) {
          continue;
        }
        final laterFrom = _effectActorId(later, 'fromActor');
        final laterTo = _effectActorId(later, 'toActor');
        if (laterFrom == null || laterTo == null) continue;
        return '阶段锚点：$earlyFrom 在 earlyProcess 对 $earlyTo 的克制已经发生；'
            '$laterFrom 在 laterProcess 回头克并限制 $laterTo 的后段/最终；'
            '后段限制不追溯抹除前段作用。';
      }
    }
    return null;
  }

  bool _hasActiveActorFactRule(
    Map<String, Object?> projection,
    String ruleId,
  ) {
    final actorFacts = projection['actorFacts'];
    if (actorFacts is! List<Object?>) return false;
    for (final fact in actorFacts) {
      if (fact is! Map<Object?, Object?>) continue;
      final tags = fact['tags'];
      if (tags is! List<Object?>) continue;
      for (final tag in tags) {
        if (tag is Map<Object?, Object?> &&
            tag['ruleId'] == ruleId &&
            tag['active'] == true) {
          return true;
        }
      }
    }
    return false;
  }

  String? _buildSelectedVerdictAnchor(Map<String, Object?> projection) {
    final verdict = projection['verdict'];
    if (verdict is! Map<Object?, Object?>) return null;
    final trend = verdict['trend'];
    final matchedDecisionRowId = verdict['matchedDecisionRowId'];
    final nuance = verdict['nuance'];
    if (trend is! String ||
        trend.isEmpty ||
        matchedDecisionRowId is! String ||
        matchedDecisionRowId.isEmpty ||
        (nuance != null && (nuance is! String || nuance.isEmpty))) {
      return null;
    }
    final nuanceField = nuance == null ? '' : '；nuance=$nuance';
    return '单轴裁决锚点：trend=$trend；'
        'matchedDecisionRowId=$matchedDecisionRowId$nuanceField';
  }

  String? _effectActorId(Map<Object?, Object?> effect, String key) {
    final actor = effect[key];
    if (actor is! Map<Object?, Object?>) return null;
    final actorId = actor['actorId'];
    return actorId is String && actorId.isNotEmpty ? actorId : null;
  }

  AssembledPromptMetadata _buildMetadata({
    required StructuredDivinationOutput structuredOutput,
    required DivinationType systemType,
    String? systemTemplateId,
    String? analysisTemplateId,
  }) {
    final contract = structuredOutput.analysisContract;
    return AssembledPromptMetadata(
      systemTemplateId: systemTemplateId,
      analysisTemplateId: analysisTemplateId,
      timestamp: DateTime.now(),
      systemType: systemType.id,
      analysisSchemaVersion: contract?.analysisSchemaVersion ?? 'legacyUnknown',
      projectionSchemaVersion:
          contract?.projectionSchemaVersion ?? 'legacyUnknown',
      ruleSetId: contract?.ruleSetId ?? 'legacyUnknown',
      ruleSetVersion: contract?.ruleSetVersion ?? 'legacyUnknown',
      sourceCatalogVersion: contract?.sourceCatalogVersion ?? 'legacyUnknown',
      promptPolicyVersion: systemType == DivinationType.liuYao
          ? liuYaoPromptPolicyVersion
          : 'legacyUnknown',
    );
  }

  String _getDefaultUserPrompt(
    String renderedOutput,
    String? question,
    AnalysisType analysisType,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('请根据以下排盘信息进行解读：');
    buffer.writeln();
    buffer.writeln(renderedOutput);

    if (question != null && question.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('【求测问题】$question');
      buffer.writeln();
      buffer.writeln('请针对上述问题进行分析。');
    } else {
      buffer.writeln();
      buffer.writeln(switch (analysisType) {
        AnalysisType.comprehensive => '请对此卦进行全面、系统的解读。',
        AnalysisType.briefSummary => '请用简洁的语言概括此卦的核心含义。',
        AnalysisType.trend => '请分析此卦所示的发展趋势。',
        AnalysisType.advice => '请根据卦象给出具体的行动建议。',
        AnalysisType.specificQuestion => '请解读此卦。',
      });
    }

    return buffer.toString();
  }

  /// 预览组装效果（不保存）
  Future<AssembledPrompt> preview(
    DivinationResult result, {
    String? question,
    String? systemTemplateContent,
    String? analysisTemplateContent,
    Map<String, dynamic>? customVariables,
  }) async {
    // 获取结构化输出
    final formatter = _formatterRegistry.getFormatter(result.systemType);
    final structuredOutput = formatter.format(result, question: question);
    final renderedOutput = formatter.render(structuredOutput);

    // 构建上下文
    final context = _buildContext(
      structuredOutput: structuredOutput,
      renderedOutput: renderedOutput,
      question: question,
      analysisType: AnalysisType.comprehensive,
      customVariables: customVariables,
    );

    // 渲染模板
    final renderedSystemPrompt = systemTemplateContent != null
        ? _engine.render(systemTemplateContent, context)
        : _getDefaultSystemPrompt(result.systemType);
    final systemPrompt = _appendImmutableSystemGuard(
      result.systemType,
      renderedSystemPrompt,
    );

    final renderedUserPrompt = analysisTemplateContent != null
        ? _engine.render(analysisTemplateContent, context)
        : _getDefaultUserPrompt(
            renderedOutput, question, AnalysisType.comprehensive);
    final userPrompt = _ensureLiuYaoProjection(
      result.systemType,
      renderedUserPrompt,
      structuredOutput,
    );

    return AssembledPrompt(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      structuredOutput: structuredOutput,
      metadata: _buildMetadata(
        structuredOutput: structuredOutput,
        systemType: result.systemType,
      ),
    );
  }
}
