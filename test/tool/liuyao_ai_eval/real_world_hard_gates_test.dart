import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/liuyao_ai_eval/real_world_contract.dart';
import '../../../tool/liuyao_ai_eval/real_world_hard_gates.dart';

void main() {
  late RealWorldEvalAdapter adapter;

  setUpAll(() {
    final loader = RealWorldAssetLoader(Directory.current.path);
    final fixture = loader.loadGenerationFixture();
    adapter = loader.loadAdapter(fixture);
  });

  test('raw unselected and selected generations pass without judge facts', () {
    final evaluator = const RealWorldHardGateEvaluator();
    final unselected = evaluator.evaluate(
      adapterCase: adapter.scenario('unselected'),
      rawOutput: _unselectedOutput,
    );
    final selected = evaluator.evaluate(
      adapterCase: adapter.scenario('selected-main-1'),
      rawOutput: _selectedOutput,
    );
    expect(unselected.passed, isTrue, reason: unselected.gates.toString());
    expect(selected.passed, isTrue, reason: selected.gates.toString());
  });

  test('each raw-output regression fails its dedicated gate', () {
    final evaluator = const RealWorldHardGateEvaluator();
    final item = adapter.scenario('selected-main-1');
    final cases = <String, String>{
      'conclusionAuthority': _selectedOutput.replaceFirst(
        '事必成，成而受困；合非吉兆，是套。',
        '',
      ),
      'lifecyclePreserved':
          _selectedOutput.replaceAll('quality: adverse', 'quality: favorable'),
      'formationFirst': _selectedOutput.replaceFirst(
        'formation: willForm\nquality: adverse',
        'quality: adverse\nformation: willForm',
      ),
      'phaseSemanticsPreserved':
          _selectedOutput.replaceAll('earlyProcess', 'laterProcess'),
      'rentalCycleCovered': _selectedOutput
          .replaceAll('出租权、合同主体与权属', '材料')
          .replaceAll('收费与费用', '金额')
          .replaceAll('房屋交付占有与入住', '房屋')
          .replaceAll('完整租期能否持续履约', '后续'),
      'liuHeScoped': '$_selectedOutput\n六合所以顺利。',
      'fakeVoidBoundary': '$_selectedOutput\n假空就是不存在。',
      'timingAndSourcesGrounded': '$_selectedOutput\n建议等到出空之日。',
      'hindsightNotInvented': '$_selectedOutput\n对方是二房东。',
    };
    for (final entry in cases.entries) {
      final result = evaluator.evaluate(
        adapterCase: item,
        rawOutput: entry.value,
      );
      expect(result.failedGateIds, contains(entry.key), reason: entry.key);
    }
  });

  test('traditional actor labels preserve phased effects without actor IDs',
      () {
    final output = _selectedOutput
        .replaceFirst(
          'main:yao:3 在 earlyProcess 对 main:yao:1 的克制已经发生；',
          '卯木在 earlyProcess 对未土的前段克制已经发生；',
        )
        .replaceFirst(
          'changed:yao:3 在 laterProcess 回头限制 main:yao:3，',
          '申金在 laterProcess 回头克卯木，只限制后段，',
        );
    final result = const RealWorldHardGateEvaluator().evaluate(
      adapterCase: adapter.scenario('selected-main-1'),
      rawOutput: output,
    );

    expect(result.gates['phaseSemanticsPreserved'], isTrue);
    expect(result.diagnostics['phaseEarlyActorIdentified'], isTrue);
    expect(result.diagnostics['phaseLaterActorIdentified'], isTrue);
  });

  test('phase labels alone cannot replace actors and directed effects', () {
    final output = _selectedOutput
        .replaceFirst(
          'main:yao:3 在 earlyProcess 对 main:yao:1 的克制已经发生；',
          'earlyProcess 已说明；',
        )
        .replaceFirst(
          'changed:yao:3 在 laterProcess 回头限制 main:yao:3，',
          'laterProcess 已说明，',
        );
    final result = const RealWorldHardGateEvaluator().evaluate(
      adapterCase: adapter.scenario('selected-main-1'),
      rawOutput: output,
    );

    expect(result.gates['phaseSemanticsPreserved'], isFalse);
  });

  test('negated phase boundary is not mistaken for retroactive erasure', () {
    final evaluator = const RealWorldHardGateEvaluator();
    final item = adapter.scenario('selected-main-1');
    final guarded = evaluator.evaluate(
      adapterCase: item,
      rawOutput: '$_selectedOutput\n不能说前段没有作用。',
    );
    final erased = evaluator.evaluate(
      adapterCase: item,
      rawOutput: '$_selectedOutput\n前段没有作用。',
    );

    expect(guarded.gates['phaseSemanticsPreserved'], isTrue);
    expect(guarded.diagnostics['phaseRetroactiveErasureAbsent'], isTrue);
    expect(erased.gates['phaseSemanticsPreserved'], isFalse);
    expect(erased.diagnostics['phaseRetroactiveErasureAbsent'], isFalse);
  });

  test('unselected overall conclusion fails even when abstain is mentioned',
      () {
    final result = const RealWorldHardGateEvaluator().evaluate(
      adapterCase: adapter.scenario('unselected'),
      rawOutput:
          '''[LIUYAO_DECISION] mode=abstain;overall=withheld;timing=withheld
verdictMode=abstain。总体判断为租房顺利。
''',
    );
    expect(result.gates['conclusionAuthority'], isFalse);
  });

  test('unselected direct rental conclusion cannot bypass overall wording', () {
    final result = const RealWorldHardGateEvaluator().evaluate(
      adapterCase: adapter.scenario('unselected'),
      rawOutput:
          '''[LIUYAO_DECISION] mode=abstain;overall=withheld;timing=withheld
verdictMode=abstain。当前未选定用神，不作总体成败与最终吉凶判断。
但这次租房不顺利。
''',
    );
    expect(result.gates['conclusionAuthority'], isFalse);
  });

  test('unselected question restatement and scoped caution are not verdicts',
      () {
    final result = const RealWorldHardGateEvaluator().evaluate(
      adapterCase: adapter.scenario('unselected'),
      rawOutput:
          '''[LIUYAO_DECISION] mode=abstain;overall=withheld;timing=withheld
【问题】租房是否顺利？
当前未选定用神，不能判断租房总体是否顺利，只列候选用神与核验维度。
六合不代表租房顺利。
''',
    );
    expect(result.gates['conclusionAuthority'], isTrue);
  });

  test('question wording cannot shield an asserted rental verdict', () {
    final result = const RealWorldHardGateEvaluator().evaluate(
      adapterCase: adapter.scenario('unselected'),
      rawOutput:
          '''[LIUYAO_DECISION] mode=abstain;overall=withheld;timing=withheld
当前未选定用神，不能判断总体结果。
租房总体是否顺利，结论是不顺利。
''',
    );
    expect(result.gates['conclusionAuthority'], isFalse);
  });

  test('explicit no-judgment wording remains an abstention boundary', () {
    final result = const RealWorldHardGateEvaluator().evaluate(
      adapterCase: adapter.scenario('unselected'),
      rawOutput:
          '''[LIUYAO_DECISION] mode=abstain;overall=withheld;timing=withheld
当前未选定用神，只列候选用神与核验维度。
总体顺利程度与最终吉凶均不做判断，也不予下结论。
''',
    );
    expect(result.gates['conclusionAuthority'], isTrue);
  });

  test('permission-denial wording is not an overall verdict', () {
    final result = const RealWorldHardGateEvaluator().evaluate(
      adapterCase: adapter.scenario('unselected'),
      rawOutput:
          '''[LIUYAO_DECISION] mode=abstain;overall=withheld;timing=withheld
当前未选定用神，只列候选用神与核验维度。
总体与最终吉凶不输出，顺利或不顺利也不回答；当前不具备判断资格。
''',
    );
    expect(result.gates['conclusionAuthority'], isTrue);
  });

  test('long permission denial passes after negative outcomes are excluded',
      () {
    final evaluator = const RealWorldHardGateEvaluator();
    final item = adapter.scenario('unselected');
    final abstention = evaluator.evaluate(
      adapterCase: item,
      rawOutput:
          '''[LIUYAO_DECISION] mode=abstain;overall=withheld;timing=withheld
当前未选定用神，只列候选用神与核验维度。
未对完整周期的总体顺利程度与最终吉凶给出程序结论。
''',
    );
    final actualVerdict = evaluator.evaluate(
      adapterCase: item,
      rawOutput:
          '''[LIUYAO_DECISION] mode=abstain;overall=withheld;timing=withheld
当前未选定用神，只列候选用神与核验维度。
总体不顺利，结论明确。
''',
    );

    expect(abstention.gates['conclusionAuthority'], isTrue);
    expect(actualVerdict.gates['conclusionAuthority'], isFalse);
  });

  test('decision marker must be the exact first raw-output line', () {
    final evaluator = const RealWorldHardGateEvaluator();
    final item = adapter.scenario('selected-main-1');
    final regressions = <String>[
      _selectedOutput.replaceFirst('[LIUYAO_DECISION]', ' [LIUYAO_DECISION]'),
      _selectedOutput.replaceFirst('timing=withheld', 'timing=withheld '),
      _selectedOutput.replaceFirst(
        '[LIUYAO_DECISION] mode=explainLifecycle;'
            'overall=lifecycle;timing=withheld\n',
        '',
      ),
      _selectedOutput.replaceFirst(
        'mode=explainLifecycle',
        'mode=explainSelectedVerdict',
      ),
    ];

    for (final rawOutput in regressions) {
      final result = evaluator.evaluate(
        adapterCase: item,
        rawOutput: rawOutput,
      );
      expect(result.gates['conclusionAuthority'], isFalse);
      expect(result.diagnostics['decisionMarkerExact'], isFalse);
    }
  });

  test('explainSelectedVerdict uses withheld overall and timing marker', () {
    final lifecycleCase = adapter.scenario('selected-main-1');
    final selectedVerdictCase = _withVerdictMode(
      lifecycleCase,
      'explainSelectedVerdict',
    );
    final evaluator = const RealWorldHardGateEvaluator();
    final passing = evaluator.evaluate(
      adapterCase: selectedVerdictCase,
      rawOutput: _selectedVerdictOutput,
    );
    final wrongOverall = evaluator.evaluate(
      adapterCase: selectedVerdictCase,
      rawOutput: '$_selectedVerdictOutput\n总体可成。',
    );

    expect(passing.gates['conclusionAuthority'], isTrue);
    expect(wrongOverall.gates['conclusionAuthority'], isFalse);
  });

  test('empty timing allows only explicitly disclaimed release conditions', () {
    final evaluator = const RealWorldHardGateEvaluator();
    final item = _withMechanicalCondition(
      adapter.scenario('selected-main-1'),
    );

    for (final releaseCondition in <String>['出空', '出月', '填实', '冲开']) {
      final result = evaluator.evaluate(
        adapterCase: item,
        rawOutput: '$_selectedOutput\n'
            '$releaseCondition仅为机械释放条件，不是应期。',
      );
      expect(
        result.gates['timingAndSourcesGrounded'],
        isTrue,
        reason: releaseCondition,
      );
    }

    final negativeBoundary = evaluator.evaluate(
      adapterCase: item,
      rawOutput: '$_selectedOutput\n'
          '出空仅为机械释放条件，不是应期，不代表可以签约。',
    );
    expect(negativeBoundary.gates['timingAndSourcesGrounded'], isTrue);

    final mechanicalWaitLabel = evaluator.evaluate(
      adapterCase: item,
      rawOutput: '$_selectedOutput\n'
          '待出空仅为机械释放条件，不是应期。',
    );
    expect(mechanicalWaitLabel.gates['timingAndSourcesGrounded'], isTrue);

    final explicitBoundary = evaluator.evaluate(
      adapterCase: item,
      rawOutput: '$_selectedOutput\n本次不提供择日或时机建议。',
    );
    expect(explicitBoundary.gates['timingAndSourcesGrounded'], isTrue);

    final suffixBoundaries = evaluator.evaluate(
      adapterCase: item,
      rawOutput: '$_selectedOutput\n时机：无；择日不适用。',
    );
    expect(suffixBoundaries.gates['timingAndSourcesGrounded'], isTrue);

    final adviceBoundary = evaluator.evaluate(
      adapterCase: item,
      rawOutput: '$_selectedOutput\n建议不做择日判断。',
    );
    expect(adviceBoundary.gates['timingAndSourcesGrounded'], isTrue);
  });

  test('empty timing allows the existing cast calendar fact', () {
    final evaluator = const RealWorldHardGateEvaluator();
    final item = adapter.scenario('selected-main-1');
    final result = evaluator.evaluate(
      adapterCase: item,
      rawOutput: '$_selectedOutput\n时间边界为 2026年2月28日 08:00。',
    );

    expect(result.gates['timingAndSourcesGrounded'], isTrue);
  });

  test('empty timing permits omission but rejects future binding resolution',
      () {
    const currentResolution = '日辰酉冲开卯戌合绊，当前已解除。';
    final evaluator = const RealWorldHardGateEvaluator();
    final item = adapter.scenario('selected-main-1');
    final omitted = evaluator.evaluate(
      adapterCase: item,
      rawOutput: _selectedOutput,
    );

    expect(omitted.gates['timingAndSourcesGrounded'], isTrue);
    expect(omitted.diagnostics['releaseConditionsQualified'], isTrue);

    final current = evaluator.evaluate(
      adapterCase: item,
      rawOutput: '$_selectedOutput\n$currentResolution',
    );

    expect(current.gates['timingAndSourcesGrounded'], isTrue);
    expect(current.diagnostics['releaseConditionsQualified'], isTrue);

    for (final futureClaim in const <String>[
      '卯戌待冲开后再签约。',
      '酉日冲开卯戌，随后付款。',
      '日辰将冲开合绊。',
      '日辰会冲开合绊。',
      '酉日冲开卯戌合绊，将会解除。',
    ]) {
      final result = evaluator.evaluate(
        adapterCase: item,
        rawOutput: '$_selectedOutput\n$futureClaim',
      );
      expect(
        result.gates['timingAndSourcesGrounded'],
        isFalse,
        reason: futureClaim,
      );
    }

    final ungrounded = evaluator.evaluate(
      adapterCase: _withoutBindingOpenedFact(item),
      rawOutput: '$_selectedOutput\n$currentResolution',
    );
    expect(ungrounded.gates['timingAndSourcesGrounded'], isFalse);
  });

  test('empty timing rejects separated disclaimers and timing advice', () {
    final evaluator = const RealWorldHardGateEvaluator();
    final item = _withMechanicalCondition(
      adapter.scenario('selected-main-1'),
    );
    final regressions = <String>[
      '出空。仅为机械释放条件，不是应期。',
      '出月仅为机械释放条件，不是应期，可以签约。',
      '填实仅为机械释放条件，不是应期，8月10日付款。',
      '冲开仅为机械释放条件，不是应期，届时择日。',
      '冲开仅为机械释放条件，不是应期，随后付款。',
      '8月10日签约。',
      '公历 2026年8月10日应签约。',
      '起卦时间：公历 2026年2月27日 08:00。',
    ];

    for (final regression in regressions) {
      final result = evaluator.evaluate(
        adapterCase: item,
        rawOutput: '$_selectedOutput\n$regression',
      );
      expect(
        result.gates['timingAndSourcesGrounded'],
        isFalse,
        reason: regression,
      );
    }
  });

  test('empty conditions reject ungrounded release-condition vocabulary', () {
    final evaluator = const RealWorldHardGateEvaluator();
    final item = adapter.scenario('selected-main-1');
    final result = evaluator.evaluate(
      adapterCase: item,
      rawOutput: '$_selectedOutput\n出空仅为机械释放条件，不是应期。',
    );

    expect(result.gates['timingAndSourcesGrounded'], isFalse);
  });
}

const String _unselectedOutput =
    '''[LIUYAO_DECISION] mode=abstain;overall=withheld;timing=withheld
verdictMode=abstain。当前未选定用神，不能作总体成败、最终吉凶或顺利程度判断。
这里只列出候选用神与合同、收费、交付和租期核验维度，不提供应期。
''';

const String _selectedOutput =
    '''[LIUYAO_DECISION] mode=explainLifecycle;overall=lifecycle;timing=withheld
formation: willForm
quality: adverse
continuity: unstable
persistence: entangled
事必成，成而受困；合非吉兆，是套。

main:yao:3 在 earlyProcess 对 main:yao:1 的克制已经发生；
changed:yao:3 在 laterProcess 回头限制 main:yao:3，不能倒推为前段无作用。
出租权、合同主体与权属需要核验；收费与费用存在暴露；房屋交付占有与入住、完整租期能否持续履约应分别判断。
六合只参与 formation 和 persistence，不能单独决定总体结果。假空按动不为空理解，不等于收费不存在。
''';

const String _selectedVerdictOutput =
    '''[LIUYAO_DECISION] mode=explainSelectedVerdict;overall=withheld;timing=withheld
生命周期维度不可用。selectedUseSpiritAxis 只解释所选用神，不能作总体成败、最终吉凶或顺利程度判断。
''';

RealWorldAdapterCase _withVerdictMode(
  RealWorldAdapterCase source,
  String verdictMode,
) {
  final projection = Map<String, Object?>.from(source.candidate.projection);
  final policy = Map<String, Object?>.from(
    (projection['policy']! as Map).cast<String, Object?>(),
  );
  policy['verdictMode'] = verdictMode;
  projection['policy'] = policy;
  projection['lifecycleVerdict'] = null;
  return RealWorldAdapterCase(
    scenarioId: source.scenarioId,
    generationInputHash: source.generationInputHash,
    baseline: source.baseline,
    candidate: RealWorldPromptVariant(
      variant: source.candidate.variant,
      systemPrompt: source.candidate.systemPrompt,
      userPrompt: source.candidate.userPrompt,
      projection: projection,
      metadata: source.candidate.metadata,
      requestHash: source.candidate.requestHash,
    ),
  );
}

RealWorldAdapterCase _withMechanicalCondition(RealWorldAdapterCase source) {
  final projection = Map<String, Object?>.from(source.candidate.projection);
  projection['conditions'] = <Object?>[
    const <String, Object?>{'conditionId': 'test-condition'},
  ];
  return RealWorldAdapterCase(
    scenarioId: source.scenarioId,
    generationInputHash: source.generationInputHash,
    baseline: source.baseline,
    candidate: RealWorldPromptVariant(
      variant: source.candidate.variant,
      systemPrompt: source.candidate.systemPrompt,
      userPrompt: source.candidate.userPrompt,
      projection: projection,
      metadata: source.candidate.metadata,
      requestHash: source.candidate.requestHash,
    ),
  );
}

RealWorldAdapterCase _withoutBindingOpenedFact(RealWorldAdapterCase source) {
  final projection = Map<String, Object?>.from(source.candidate.projection);
  final actorFacts = (projection['actorFacts']! as List<Object?>).map((raw) {
    final fact =
        Map<String, Object?>.from((raw! as Map).cast<String, Object?>());
    fact['tags'] = (fact['tags']! as List<Object?>).where((tag) {
      final value = (tag! as Map).cast<String, Object?>();
      return value['ruleId'] != 'liuyao.rule.hechong.binding-opened';
    }).toList(growable: false);
    return fact;
  }).toList(growable: false);
  projection['actorFacts'] = actorFacts;
  return RealWorldAdapterCase(
    scenarioId: source.scenarioId,
    generationInputHash: source.generationInputHash,
    baseline: source.baseline,
    candidate: RealWorldPromptVariant(
      variant: source.candidate.variant,
      systemPrompt: source.candidate.systemPrompt,
      userPrompt: source.candidate.userPrompt,
      projection: projection,
      metadata: source.candidate.metadata,
      requestHash: source.candidate.requestHash,
    ),
  );
}
