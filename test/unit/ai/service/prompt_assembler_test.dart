import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/config/ai_config_manager.dart';
import 'package:wanxiang_paipan/ai/llm_provider.dart';
import 'package:wanxiang_paipan/ai/output/formatters/liuyao_formatter.dart';
import 'package:wanxiang_paipan/ai/output/structured_output.dart';
import 'package:wanxiang_paipan/ai/output/structured_output_formatter.dart';
import 'package:wanxiang_paipan/ai/service/prompt_assembler.dart';
import 'package:wanxiang_paipan/ai/template/prompt_template.dart' as tmpl;
import 'package:wanxiang_paipan/ai/template/builtin_templates.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/secure/secure_storage.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

class _MockSecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<bool> containsKey(String key) async => _storage.containsKey(key);

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<String?> read(String key) async => _storage[key];

  @override
  Future<Map<String, String>> readMultiple(List<String> keys) async {
    final result = <String, String>{};
    for (final key in keys) {
      final value = _storage[key];
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  @override
  Future<Map<String, String>> readAll() async => Map.unmodifiable(_storage);

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }
}

class _FakeResult implements DivinationResult {
  @override
  final String id = 'fake-result-1';

  @override
  DateTime get castTime => DateTime(2026, 4, 19, 9, 22);

  @override
  CastMethod get castMethod => CastMethod.time;

  @override
  LunarInfo get lunarInfo => const LunarInfo(
        yueJian: '辰',
        riGan: '癸',
        riZhi: '亥',
        riGanZhi: '癸亥',
        hourGanZhi: '丁巳',
        kongWang: ['子', '丑'],
        yearGanZhi: '丙午',
        monthGanZhi: '壬辰',
      );

  @override
  DivinationType get systemType => DivinationType.meiHua;

  @override
  String getSummary() => '风火家人';

  @override
  Map<String, dynamic> toJson() => {'id': id};
}

class _FakeFormatter extends StructuredOutputFormatter<_FakeResult> {
  @override
  DivinationType get systemType => DivinationType.meiHua;

  @override
  StructuredDivinationOutput format(_FakeResult result, {String? question}) {
    return StructuredDivinationOutput(
      systemType: result.systemType.id,
      temporal: TemporalInfo(
        solarTime: result.castTime,
        yearGanZhi: result.lunarInfo.yearGanZhi,
        monthGanZhi: result.lunarInfo.monthGanZhi,
        dayGanZhi: result.lunarInfo.riGanZhi,
        hourGanZhi: result.lunarInfo.hourGanZhi,
        kongWang: result.lunarInfo.kongWang,
        yueJian: result.lunarInfo.yueJian,
      ),
      coreData: const {
        'mainSymbol': '风火家人',
        'mainGuaName': '风火家人',
        'hasChangingGua': false,
        'hasMovingYao': true,
      },
      sections: const [
        StructuredSection(
          key: 'overview',
          title: '排盘总览',
          content: '本卦：风火家人',
          priority: 1,
        ),
      ],
      userQuestion: question,
      summary: '风火家人',
    );
  }

  @override
  String render(StructuredDivinationOutput output) {
    return 'RENDERED:${output.summary}';
  }
}

class _PhaseAnchorFormatter extends StructuredOutputFormatter<LiuYaoResult> {
  _PhaseAnchorFormatter({this.timingProvided = false});

  final bool timingProvided;

  @override
  DivinationType get systemType => DivinationType.liuYao;

  @override
  StructuredDivinationOutput format(
    LiuYaoResult result, {
    String? question,
  }) {
    final projection = <String, Object?>{
      'policy': <String, Object?>{'verdictMode': 'explainLifecycle'},
      'timingCandidates': timingProvided
          ? <Object?>[
              <String, Object?>{'timingId': 'timing-fixture-1'},
            ]
          : <Object?>[],
      'conditions': timingProvided
          ? <Object?>[
              <String, Object?>{'conditionId': 'condition-fixture-1'},
            ]
          : <Object?>[],
      'questionFocus': <String, Object?>{'classification': 'unspecified'},
      'actorFacts': <Object?>[],
      'directedEffects': <Object?>[
        _effect(
          ruleId: 'liuyao.rule.shengke.moving-overcomes',
          phase: 'earlyProcess',
          fromActorId: 'main:yao:2',
          toActorId: 'main:yao:1',
        ),
        _effect(
          ruleId: 'liuyao.rule.shengke.moving-overcomes',
          phase: 'earlyProcess',
          fromActorId: 'main:yao:3',
          toActorId: 'main:yao:1',
        ),
        _effect(
          ruleId: 'liuyao.rule.dongbian.return-overcomes',
          phase: 'laterProcess',
          fromActorId: 'changed:yao:3',
          toActorId: 'main:yao:3',
        ),
      ],
    };
    return StructuredDivinationOutput(
      systemType: systemType.id,
      temporal: TemporalInfo(
        solarTime: result.castTime,
        yearGanZhi: result.lunarInfo.yearGanZhi,
        monthGanZhi: result.lunarInfo.monthGanZhi,
        dayGanZhi: result.lunarInfo.riGanZhi,
        hourGanZhi: result.lunarInfo.hourGanZhi,
        kongWang: result.lunarInfo.kongWang,
        yueJian: result.lunarInfo.yueJian,
      ),
      coreData: const <String, dynamic>{},
      sections: <StructuredSection>[
        StructuredSection(
          key: 'analysis',
          title: '分析',
          content: 'PHASE ANCHOR FIXTURE',
          metadata: <String, dynamic>{
            'projection': projection,
            'aiProjection': <String, Object?>{
              'projectionView': 'phaseAnchorFixture',
            },
          },
        ),
      ],
      userQuestion: question,
      summary: 'PHASE ANCHOR FIXTURE',
    );
  }

  @override
  String render(StructuredDivinationOutput output) => output.summary!;

  Map<String, Object?> _effect({
    required String ruleId,
    required String phase,
    required String fromActorId,
    required String toActorId,
  }) =>
      <String, Object?>{
        'ruleId': ruleId,
        'status': 'active',
        'phase': phase,
        'fromActor': <String, Object?>{'actorId': fromActorId},
        'toActor': <String, Object?>{'actorId': toActorId},
      };
}

void main() {
  group('PromptAssembler', () {
    late AppDatabase database;
    late _MockSecureStorage secureStorage;
    late AIConfigManager configManager;
    late StructuredOutputFormatterRegistry formatterRegistry;
    late PromptAssembler assembler;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      secureStorage = _MockSecureStorage();
      configManager = AIConfigManager(
        database: database,
        secureStorage: secureStorage,
      );
      formatterRegistry = StructuredOutputFormatterRegistry.instance;
      formatterRegistry.clear();
      formatterRegistry.register(_FakeFormatter());
      formatterRegistry.register(LiuYaoStructuredFormatter());
      assembler = PromptAssembler(
        configManager: configManager,
        formatterRegistry: formatterRegistry,
      );
    });

    tearDown(() async {
      formatterRegistry.clear();
      await database.close();
    });

    test('assemble 应使用当前激活模板并注入问题、时间与自定义变量', () async {
      final systemTemplate = _template(
        id: 'system_active',
        templateType: 'system',
        content: 'SYS {{mainSymbol}} {{#if hasQuestion}}HASQ{{/if}}',
        isActive: true,
      );
      final inactiveAnalysis = _template(
        id: 'analysis_inactive',
        templateType: 'analysis',
        content: 'INACTIVE {{question}}',
        isActive: false,
      );
      final activeAnalysis = _template(
        id: 'analysis_active',
        templateType: 'analysis',
        content: 'USR {{structuredOutput}} | Q={{question}} | '
            'day={{temporal.dayGanZhi}} | extra={{customInstructions}} | '
            'advice={{includeAdvice}}',
        isActive: false,
      );

      await configManager.saveTemplate(systemTemplate);
      await configManager.saveTemplate(inactiveAnalysis);
      await configManager.saveTemplate(activeAnalysis);
      await configManager.setActiveTemplate(
        activeAnalysis.id,
        activeAnalysis.systemType,
        activeAnalysis.templateType,
      );

      final prompt = await assembler.assemble(
        _FakeResult(),
        question: '问财运',
        analysisType: AnalysisType.advice,
        customVariables: const {'customInstructions': '只看结论'},
      );

      expect(prompt.systemPrompt, 'SYS 风火家人 HASQ');
      expect(prompt.userPrompt, contains('RENDERED:风火家人'));
      expect(prompt.userPrompt, contains('Q=问财运'));
      expect(prompt.userPrompt, contains('day=癸亥'));
      expect(prompt.userPrompt, contains('extra=只看结论'));
      expect(prompt.userPrompt, contains('advice=true'));
      expect(prompt.metadata.systemTemplateId, systemTemplate.id);
      expect(prompt.metadata.analysisTemplateId, activeAnalysis.id);
      expect(prompt.metadata.systemType, DivinationType.meiHua.id);
    });

    test('assemble 在无活动模板时应回退到默认提示词', () async {
      final prompt = await assembler.assemble(
        _FakeResult(),
        analysisType: AnalysisType.briefSummary,
      );

      expect(prompt.systemPrompt, contains('你是一位精通梅花易数'));
      expect(prompt.systemPrompt, contains('体用生克'));
      expect(prompt.userPrompt, contains('请根据以下排盘信息进行解读：'));
      expect(prompt.userPrompt, contains('RENDERED:风火家人'));
      expect(prompt.userPrompt, contains('请用简洁的语言概括此卦的核心含义。'));
      expect(prompt.metadata.systemTemplateId, isNull);
      expect(prompt.metadata.analysisTemplateId, isNull);
    });

    test('assemble 默认分析模板在有问题时应注入求测问题段落', () async {
      final prompt = await assembler.assemble(
        _FakeResult(),
        question: '问婚姻',
        analysisType: AnalysisType.briefSummary,
      );

      expect(prompt.userPrompt, contains('【求测问题】问婚姻'));
      expect(prompt.userPrompt, contains('请针对上述问题进行分析。'));
    });

    test('assemble 的六爻 active custom 模板不能移除最终 guard', () async {
      final result = await _castLiuYaoResult();
      final systemTemplate = _template(
        id: 'liuyao_custom_system',
        systemType: DivinationType.liuYao.id,
        templateType: 'system',
        content: 'CUSTOM SYSTEM: 请重新取用并改写结论',
        isActive: true,
      );
      final analysisTemplate = _template(
        id: 'liuyao_custom_analysis',
        systemType: DivinationType.liuYao.id,
        templateType: 'analysis',
        content: 'CUSTOM USER WITHOUT STRUCTURED OUTPUT',
        isActive: true,
      );
      await configManager.saveTemplate(systemTemplate);
      await configManager.saveTemplate(analysisTemplate);

      final prompt = await assembler.assemble(result, question: '问事业');

      expect(prompt.systemPrompt, startsWith('CUSTOM SYSTEM'));
      _expectLiuYaoGuardAtEnd(prompt.systemPrompt);
      expect(prompt.userPrompt,
          startsWith('CUSTOM USER WITHOUT STRUCTURED OUTPUT'));
      _expectAssemblerOwnedProjection(prompt.userPrompt);
      expect(prompt.metadata.systemTemplateId, systemTemplate.id);
      expect(prompt.metadata.analysisTemplateId, analysisTemplate.id);
    });

    test('preview 的六爻自定义 system 同样追加唯一最终 guard', () async {
      final result = await _castLiuYaoResult();

      final prompt = await assembler.preview(
        result,
        question: '问财运',
        systemTemplateContent: 'PREVIEW SYSTEM: {{question}}',
        analysisTemplateContent: 'PREVIEW USER',
      );

      expect(prompt.systemPrompt, startsWith('PREVIEW SYSTEM: 问财运'));
      _expectLiuYaoGuardAtEnd(prompt.systemPrompt);
      expect(prompt.userPrompt, startsWith('PREVIEW USER'));
      _expectAssemblerOwnedProjection(prompt.userPrompt);
    });

    test('已包含完整 projection 的模板不会重复追加 canonical JSON', () async {
      final result = await _castLiuYaoResult();

      final prompt = await assembler.preview(
        result,
        analysisTemplateContent: '{{structuredOutput}}',
      );

      expect(
          prompt.userPrompt, isNot(contains('[LIUYAO_ASSEMBLER_PROJECTION]')));
      expect(
        RegExp(r'\[LIUYAO_CANONICAL_PROJECTION\]')
            .allMatches(prompt.userPrompt),
        hasLength(1),
      );
    });

    test('comprehensive 与 brief 路径均保留 formation-first 租房生命周期', () async {
      final result = await _castRentalResult(selected: true);

      for (final template in <String>[
        BuiltInTemplates.liuYaoAnalysisPrompt.content,
        BuiltInTemplates.liuYaoBriefPrompt.content,
      ]) {
        final prompt = await assembler.preview(
          result,
          question: '租房是否顺利',
          analysisTemplateContent: template,
        );

        _expectLiuYaoGuardAtEnd(prompt.systemPrompt);
        expect(
          prompt.metadata.promptPolicyVersion,
          PromptAssembler.liuYaoPromptPolicyVersion,
        );
        expect(prompt.userPrompt, contains('"verdictMode":"explainLifecycle"'));
        expect(prompt.userPrompt, contains('"formation":"willForm"'));
        expect(prompt.userPrompt, contains('"quality":"adverse"'));
        expect(prompt.userPrompt, contains('"continuity":"unstable"'));
        expect(prompt.userPrompt, contains('"persistence":"entangled"'));
        expect(
          prompt.userPrompt,
          contains('"headlineCode":"formsButAdverse"'),
        );
        expect(prompt.userPrompt, contains('出租权与合同主体'));
        expect(prompt.userPrompt, contains('完整租期'));
        _expectLiuYaoOutputContract(
          prompt.userPrompt,
          '[LIUYAO_DECISION] mode=explainLifecycle;'
          'overall=lifecycle;timing=withheld',
        );
        expect(prompt.userPrompt, contains('conditions=[] 且 timing=withheld'));
        expect(
          prompt.userPrompt,
          contains('省略条件/时间段落'),
        );
        expect(prompt.userPrompt, contains('事后事实隔离'));
        expect(prompt.userPrompt, contains('不举例、不类比'));
        expect(prompt.userPrompt, contains('完整租期持续履约风险'));
        _expectNoTimingResultBoundary(
          prompt.userPrompt,
          expectLifecycle: true,
        );
        _expectResolvedReleaseWordingForbidden(prompt.userPrompt);
        _expectLegacyTimingSummaryAbsent(prompt.userPrompt);
        expect(
          prompt.userPrompt,
          contains(
            '阶段锚点：main:yao:3 在 earlyProcess 对 main:yao:1 的克制已经发生；'
            'changed:yao:3 在 laterProcess 回头克并限制 main:yao:3 的后段/最终；'
            '后段限制不追溯抹除前段作用。',
          ),
        );
      }
    });

    test('comprehensive、brief 与 custom 路径的未选用神状态均强制 abstain', () async {
      final result = await _castRentalResult(selected: false);
      final templates = <String>[
        BuiltInTemplates.liuYaoAnalysisPrompt.content,
        BuiltInTemplates.liuYaoBriefPrompt.content,
        'CUSTOM WITHOUT STRUCTURED OUTPUT',
      ];

      for (final template in templates) {
        final prompt = await assembler.preview(
          result,
          question: '租房是否顺利',
          analysisTemplateContent: template,
        );

        _expectLiuYaoGuardAtEnd(prompt.systemPrompt);
        expect(prompt.systemPrompt, contains('verdictMode=abstain'));
        expect(prompt.systemPrompt, contains('禁止输出顺利/不顺利'));
        expect(prompt.userPrompt, contains('"verdictMode":"abstain"'));
        expect(prompt.userPrompt, contains('"lifecycleVerdict":null'));
        expect(prompt.userPrompt, contains('"timingCandidates":[]'));
        _expectLiuYaoOutputContract(
          prompt.userPrompt,
          '[LIUYAO_DECISION] mode=abstain;'
          'overall=withheld;timing=withheld',
        );
        expect(prompt.userPrompt, contains('本次不执行上方租房五项回答要求'));
        expect(prompt.userPrompt, contains('本段合同覆盖此前模板的输出段落要求'));
        expect(prompt.userPrompt, contains('“候选用神”和“待核验维度”两组列表'));
        expect(prompt.userPrompt, contains('第二组列表后立即结束回复'));
        expect(prompt.userPrompt, contains('不得解释 actorFacts'));
        expect(prompt.userPrompt, contains('本次 timing=withheld'));
        final outputContract =
            prompt.userPrompt.split('[LIUYAO_OUTPUT_CONTRACT]').last;
        expect(outputContract, contains('第二组列表后立即结束'));
        expect(outputContract, contains('不输出条件、应期、时间或行动文字'));
        _expectNoTimingResultBoundary(
          prompt.userPrompt,
          expectLifecycle: false,
        );
        expect(outputContract, isNot(contains('binding-opened')));
        expect(outputContract, isNot(contains('日冲已解除合绊')));
      }
    });

    test('custom 路径不能移除选定用神的生命周期投影', () async {
      final result = await _castRentalResult(selected: true);
      final prompt = await assembler.preview(
        result,
        question: '租房是否顺利',
        systemTemplateContent: 'CUSTOM SYSTEM',
        analysisTemplateContent: 'CUSTOM USER',
      );

      _expectLiuYaoGuardAtEnd(prompt.systemPrompt);
      _expectAssemblerOwnedProjection(prompt.userPrompt);
      expect(prompt.userPrompt, contains('"verdictMode":"explainLifecycle"'));
      expect(prompt.userPrompt, contains('"headlineCode":"formsButAdverse"'));
      expect(prompt.userPrompt, contains('"phase":"earlyProcess"'));
      expect(prompt.userPrompt, contains('"phase":"laterProcess"'));
      _expectLiuYaoOutputContract(
        prompt.userPrompt,
        '[LIUYAO_DECISION] mode=explainLifecycle;'
        'overall=lifecycle;timing=withheld',
      );
      _expectNoTimingResultBoundary(
        prompt.userPrompt,
        expectLifecycle: true,
      );
      _expectResolvedReleaseWordingForbidden(prompt.userPrompt);
      _expectLegacyTimingSummaryAbsent(prompt.userPrompt);
    });

    test('custom 路径的伏神取用保留缺失事实与单轴结论权限', () async {
      final base = await _castRentalResult(selected: false);
      final result = base.copyWith(
        yongShenPosition: 1,
        yongShenIsFuShen: true,
      );
      final prompt = await assembler.preview(
        result,
        question: '租房是否顺利',
        analysisTemplateContent: 'CUSTOM WITHOUT STRUCTURED OUTPUT',
      );

      _expectAssemblerOwnedProjection(prompt.userPrompt);
      expect(
        prompt.userPrompt,
        contains('"selectedFactOccurrenceIds":'),
      );
      expect(
        prompt.userPrompt,
        contains('"factsNotPresentElsewhere":'),
      );
      expect(
        prompt.userPrompt,
        contains('"ruleId":"liuyao.rule.liuqin.selected-hidden-use-spirit"'),
      );
      expect(
        prompt.userPrompt,
        contains('"verdictMode":"explainSelectedVerdict"'),
      );
      _expectLiuYaoOutputContract(
        prompt.userPrompt,
        '[LIUYAO_DECISION] mode=explainSelectedVerdict;'
        'overall=withheld;timing=withheld',
      );
      _expectNoTimingResultBoundary(
        prompt.userPrompt,
        expectLifecycle: false,
      );
    });

    test('selected non-rental paths preserve program verdict without lifecycle',
        () async {
      final result = await _castRentalResult(selected: true);
      for (final template in <String>[
        BuiltInTemplates.liuYaoAnalysisPrompt.content,
        BuiltInTemplates.liuYaoBriefPrompt.content,
        'CUSTOM WITHOUT STRUCTURED OUTPUT',
      ]) {
        final prompt = await assembler.preview(
          result,
          question: '这次求职能否成功',
          analysisTemplateContent: template,
        );

        _expectLiuYaoGuardAtEnd(prompt.systemPrompt);
        expect(
          prompt.systemPrompt,
          contains('verdictMode=explainSelectedVerdict'),
        );
        expect(prompt.systemPrompt, contains('生命周期维度不可用'));
        expect(prompt.systemPrompt, contains('selectedUseSpiritAxis'));
        expect(
          prompt.systemPrompt,
          contains('禁止据此宣告整件事'),
        );
        expect(
          prompt.systemPrompt,
          contains('conditions=[] 且 timingCandidates=[] 时'),
        );
        expect(
          prompt.userPrompt,
          contains('"verdictMode":"explainSelectedVerdict"'),
        );
        expect(
          prompt.userPrompt,
          contains('"mayIssueOverallOutcome":false'),
        );
        expect(
          prompt.userPrompt,
          contains('"legacyVerdictScope":"selectedUseSpiritAxis"'),
        );
        expect(prompt.userPrompt, contains('"lifecycleVerdict":null'));
        expect(prompt.userPrompt, contains('"verdict":{"trend":'));
        expect(prompt.userPrompt, contains('"matchedDecisionRowId":'));
        _expectLiuYaoOutputContract(
          prompt.userPrompt,
          '[LIUYAO_DECISION] mode=explainSelectedVerdict;'
          'overall=withheld;timing=withheld',
        );
        _expectNoTimingResultBoundary(
          prompt.userPrompt,
          expectLifecycle: false,
        );
        _expectLegacyTimingSummaryAbsent(prompt.userPrompt);
        expect(
          prompt.userPrompt,
          contains('正文必须逐字单独一行输出“单轴裁决锚点：trend='),
        );
        expect(
          RegExp(
            r'单轴裁决锚点：trend=[^；]+；matchedDecisionRowId=[^”；]+',
          ).hasMatch(prompt.userPrompt),
          isTrue,
        );
      }
    });

    test('unselected non-rental output contract contains no rental wording',
        () async {
      final result = await _castRentalResult(selected: false);
      final prompt = await assembler.preview(
        result,
        question: '这次求职能否成功',
        analysisTemplateContent: 'CUSTOM WITHOUT STRUCTURED OUTPUT',
      );

      expect(prompt.userPrompt, contains('"classification":"unspecified"'));
      expect(prompt.userPrompt, contains('不能判断所问事项的总体结果'));
      expect(prompt.userPrompt, isNot(contains('租房')));
      expect(prompt.userPrompt, isNot(contains('出租权')));
      expect(prompt.userPrompt, isNot(contains('收费')));
      expect(prompt.userPrompt, isNot(contains('租期')));
      _expectLiuYaoOutputContract(
        prompt.userPrompt,
        '[LIUYAO_DECISION] mode=abstain;'
        'overall=withheld;timing=withheld',
      );
    });

    test('phase anchor skips an unpaired early effect and finds a later pair',
        () async {
      formatterRegistry.register(_PhaseAnchorFormatter());
      final result = await _castRentalResult(selected: true);
      final prompt = await assembler.preview(
        result,
        question: '阶段作用测试',
        analysisTemplateContent: 'CUSTOM USER',
      );

      expect(
        prompt.userPrompt,
        contains(
          '阶段锚点：main:yao:3 在 earlyProcess 对 main:yao:1 的克制已经发生；'
          'changed:yao:3 在 laterProcess 回头克并限制 main:yao:3 的后段/最终；'
          '后段限制不追溯抹除前段作用。',
        ),
      );
      expect(prompt.userPrompt, isNot(contains('阶段锚点：main:yao:2')));
    });

    test('timing provided path requires the program-owned observation anchor',
        () async {
      formatterRegistry.register(_PhaseAnchorFormatter(timingProvided: true));
      final result = await _castRentalResult(selected: true);
      final prompt = await assembler.preview(
        result,
        question: '应期边界测试',
        analysisTemplateContent: 'CUSTOM USER',
      );

      _expectLiuYaoOutputContract(
        prompt.userPrompt,
        '[LIUYAO_DECISION] mode=explainLifecycle;'
        'overall=lifecycle;timing=provided',
      );
      final outputContract =
          prompt.userPrompt.split('[LIUYAO_OUTPUT_CONTRACT]').last;
      expect(
        outputContract,
        contains(PromptAssembler.liuYaoTimingObservationAnchor),
      );
      expect(
        outputContract,
        contains('除该锚点外不讨论观察窗口对事项结果的确定程度'),
      );
      expect(
        outputContract,
        contains(PromptAssembler.liuYaoUnauthorizedResultBoundary),
      );
      expect(
        RegExp(r'必然|必定|保证|一定').hasMatch(outputContract),
        isFalse,
      );
    });

    test('production timing path retains verdict summary exactly once',
        () async {
      final base = await _castRentalResult(selected: false);
      final result = base.copyWith(yongShenPosition: 6);
      final prompt = await assembler.preview(
        result,
        question: '租房是否顺利',
        analysisTemplateContent: BuiltInTemplates.liuYaoAnalysisPrompt.content,
      );
      final analysis = prompt.structuredOutput.sections.singleWhere(
        (section) => section.key == 'analysis',
      );
      final projection =
          (analysis.metadata!['projection']! as Map<Object?, Object?>)
              .cast<String, Object?>();
      final verdict = (projection['verdict']! as Map<Object?, Object?>)
          .cast<String, Object?>();
      final summary = verdict['summary']! as String;

      expect(projection['timingCandidates'], isNotEmpty);
      expect(summary, contains('应期候选'));
      expect(summary, contains('触发窗口'));
      expect(summary, contains('优先观察'));
      expect(prompt.userPrompt.split(summary), hasLength(2));
    });
  });
}

Future<LiuYaoResult> _castLiuYaoResult() async {
  return await LiuYaoSystem().cast(
    method: CastMethod.time,
    input: const <String, dynamic>{},
    castTime: DateTime(2026, 4, 24, 5, 30),
  ) as LiuYaoResult;
}

Future<LiuYaoResult> _castRentalResult({required bool selected}) async {
  final result = await LiuYaoSystem().castByManualYaoNumbers(
    const <int>[8, 8, 6, 7, 8, 6],
    castTime: DateTime(2026, 2, 28, 8),
  );
  return selected ? result.copyWith(yongShenPosition: 1) : result;
}

void _expectLiuYaoGuardAtEnd(String systemPrompt) {
  expect(systemPrompt, endsWith(PromptAssembler.liuYaoImmutablePolicy));
  expect(
    RegExp(r'\[LIUYAO_IMMUTABLE_POLICY ').allMatches(systemPrompt),
    hasLength(1),
  );
  expect(systemPrompt, contains('calculationOwner=program'));
  expect(systemPrompt, contains('mayOverrideVerdict=false'));
  expect(systemPrompt, contains('mayOverrideLifecycle=false'));
  expect(systemPrompt, contains('mayInventSources=false'));
  expect(systemPrompt, contains('mayInventTiming=false'));
  expect(systemPrompt, contains('responsePrefixOwner=program'));
  expect(systemPrompt, contains('mayPrependResponseText=false'));
  expect(systemPrompt, contains('原始回复必须从该标记的第一个 `[` 字符开始'));
  expect(systemPrompt, contains('禁止举例、类比或猜测'));
  expect(
    systemPrompt,
    contains('只写当前盘面事实与程序已授权裁决'),
  );
  expect(systemPrompt, contains('不得扩写任何释放路径、观察窗口、未来状态、行动建议或新日期'));
  expect(
    RegExp(
      r'出空|出月|填实|冲开|解除合绊|合绊已解|等待|等到|等至|待到|待至|择日|时机|届时',
    ).hasMatch(PromptAssembler.liuYaoImmutablePolicy),
    isFalse,
  );
  expect(
    systemPrompt,
    contains('[LIUYAO_IMMUTABLE_POLICY '
        '${PromptAssembler.liuYaoPromptPolicyVersion}]'),
  );
  expect(systemPrompt, contains('不得复述 compact view 已省略的关系'));
  expect(systemPrompt, isNot(contains('日冲已解除合绊')));
  expect(systemPrompt, isNot(contains('合绊=true')));
  expect(systemPrompt, isNot(contains('冲开=true')));
  expect(systemPrompt, isNot(contains('全文必须且只能出现一次')));
  expect(systemPrompt, isNot(contains('该句独占一行')));
  expect(systemPrompt, isNot(contains('禁止解释或复述')));
  expect(systemPrompt, contains('不得用否定式描述前段作用'));
  expect(systemPrompt, contains('verdictMode=abstain'));
  expect(systemPrompt, contains('verdictMode=explainLifecycle'));
  expect(systemPrompt, contains('verdictMode=explainSelectedVerdict'));
  expect(systemPrompt, contains('selectedUseSpiritAxis'));
  expect(systemPrompt, contains('conditions=[] 且 timingCandidates=[] 时'));
  expect(
    systemPrompt,
    contains(PromptAssembler.liuYaoUnauthorizedResultBoundary),
  );
  expect(
    systemPrompt,
    contains('output contract 的 timing=provided 约束'),
  );
  expect(
    systemPrompt,
    isNot(contains(PromptAssembler.liuYaoTimingObservationAnchor)),
  );
  expect(systemPrompt, contains('无论 timingCandidates 是否为空'));
  expect(
    RegExp(r'必然|必定|保证|一定').hasMatch(PromptAssembler.liuYaoImmutablePolicy),
    isFalse,
  );
  expect(systemPrompt, contains('formation'));
  expect(systemPrompt, contains('quality'));
  expect(systemPrompt, contains('continuity'));
  expect(systemPrompt, contains('persistence'));
}

void _expectAssemblerOwnedProjection(String userPrompt) {
  expect(userPrompt, contains('[LIUYAO_ASSEMBLER_PROJECTION]'));
  expect(userPrompt, contains('[/LIUYAO_ASSEMBLER_PROJECTION]'));
  expect(userPrompt, contains('"calculationOwner":"program"'));
  expect(userPrompt, contains('"aiProjectionSchemaVersion":1'));
  expect(userPrompt, contains('"projectionView":"aiCompact"'));
  expect(userPrompt, contains('"projectionSchemaVersion":2'));
  expect(userPrompt, contains('"ruleSetId":"liuyao-zengshan-primary"'));
}

void _expectLiuYaoOutputContract(String userPrompt, String marker) {
  expect(
    RegExp(r'\[LIUYAO_OUTPUT_CONTRACT\]').allMatches(userPrompt),
    hasLength(1),
  );
  expect(userPrompt, contains(marker));
  expect(userPrompt, contains('必须直接逐字复制下一行作为第一行'));
  expect(userPrompt, contains('rawResponse.startsWith("$marker\\n")'));
  expect(userPrompt, endsWith(marker));
}

void _expectNoTimingResultBoundary(
  String userPrompt, {
  required bool expectLifecycle,
}) {
  final outputContract = userPrompt.split('[LIUYAO_OUTPUT_CONTRACT]').last;
  expect(
    outputContract,
    contains(PromptAssembler.liuYaoUnauthorizedResultBoundary),
  );
  expect(
    outputContract.contains(
      'explainLifecycle 仍须原值输出已授权的 lifecycleVerdict',
    ),
    expectLifecycle,
  );
  expect(
    RegExp(r'必然|必定|保证|一定').hasMatch(outputContract),
    isFalse,
  );
}

void _expectResolvedReleaseWordingForbidden(String userPrompt) {
  final outputContract = userPrompt.split('[LIUYAO_OUTPUT_CONTRACT]').last;
  expect(
    outputContract,
    contains('只写当前盘面事实与程序已授权裁决'),
  );
  expect(
    RegExp(
      r'出空|出月|填实|冲开|解除合绊|合绊已解|等待|等到|等至|待到|待至|择日|时机|届时',
    ).hasMatch(outputContract),
    isFalse,
  );
  expect(outputContract, contains('不得复述 compact view 已省略的关系'));
  expect(outputContract, isNot(contains('日冲已解除合绊')));
  expect(outputContract, isNot(contains('合绊=true')));
  expect(outputContract, isNot(contains('冲开=true')));
  expect(outputContract, isNot(contains('全文必须且只能出现一次')));
  expect(outputContract, isNot(contains('该句独占一行')));
  expect(outputContract, isNot(contains('禁止解释或复述')));
}

void _expectLegacyTimingSummaryAbsent(String prompt) {
  for (final term in const <String>[
    '应期候选',
    '触发窗口',
    '优先观察',
  ]) {
    expect(prompt, isNot(contains(term)));
  }
}

tmpl.PromptTemplate _template({
  required String id,
  String systemType = 'meihua',
  required String templateType,
  required String content,
  required bool isActive,
}) {
  return tmpl.PromptTemplate(
    id: id,
    name: id,
    description: 'test',
    systemType: systemType,
    templateType: templateType,
    content: content,
    variablesJson: '{}',
    isBuiltIn: false,
    isActive: isActive,
    createdAt: DateTime(2026, 4, 19, 12),
    updatedAt: DateTime(2026, 4, 19, 12),
  );
}
