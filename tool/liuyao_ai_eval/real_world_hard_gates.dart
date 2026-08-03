import 'real_world_contract.dart';

const String _abstainMode = 'abstain';
const String _explainLifecycleMode = 'explainLifecycle';
const String _explainSelectedVerdictMode = 'explainSelectedVerdict';
const String _releaseConditionDisclaimer = '仅为机械释放条件，不是应期';
const String _bindingOpenedRuleId = 'liuyao.rule.hechong.binding-opened';

const Set<String> realWorldHardGateIds = <String>{
  'conclusionAuthority',
  'lifecyclePreserved',
  'formationFirst',
  'phaseSemanticsPreserved',
  'rentalCycleCovered',
  'liuHeScoped',
  'fakeVoidBoundary',
  'timingAndSourcesGrounded',
  'hindsightNotInvented',
};

class RealWorldHardGateResult {
  const RealWorldHardGateResult(
    this.gates, {
    this.diagnostics = const <String, bool>{},
  });

  final Map<String, bool> gates;
  final Map<String, bool> diagnostics;

  bool get passed => gates.values.every((value) => value);

  Set<String> get failedGateIds => gates.entries
      .where((entry) => !entry.value)
      .map((entry) => entry.key)
      .toSet();
}

/// Reference-free gates over the exact generation text.
///
/// These checks intentionally run before the hindsight fixture is opened.
/// The judge is allowed to score subjective quality, but it cannot manufacture
/// lifecycle, phase, source, or conclusion facts on behalf of a generation.
class RealWorldHardGateEvaluator {
  const RealWorldHardGateEvaluator();

  RealWorldHardGateResult evaluate({
    required RealWorldAdapterCase adapterCase,
    required String rawOutput,
  }) {
    final text = rawOutput.trim();
    final projection = adapterCase.candidate.projection;
    final verdictMode = _verdictMode(projection);
    final selected = verdictMode == _explainLifecycleMode ||
        verdictMode == _explainSelectedVerdictMode;
    const lifecycleValues = <String>[
      'willForm',
      'adverse',
      'unstable',
      'entangled',
    ];
    final bool lifecyclePreserved;
    if (verdictMode == _explainLifecycleMode) {
      lifecyclePreserved = _containsAll(text, lifecycleValues);
    } else if (verdictMode == _abstainMode ||
        verdictMode == _explainSelectedVerdictMode) {
      lifecyclePreserved = !_containsAny(text, lifecycleValues);
    } else {
      lifecyclePreserved = false;
    }
    final compact = text
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '，')
        .replaceAll(';', '；');
    final hasFrozenHeadline = compact.contains('事必成，成而受困；合非吉兆，是套');
    final explicitlyAbstains = _explicitlyAbstains(text);
    final issuesOverallVerdict = _issuesOverallVerdict(text);
    final decisionMarkerExact = _hasRequiredDecisionMarker(
      rawOutput,
      projection,
    );
    final bool conclusionAuthority;
    if (verdictMode == _explainLifecycleMode) {
      conclusionAuthority =
          decisionMarkerExact && lifecyclePreserved && hasFrozenHeadline;
    } else if (verdictMode == _explainSelectedVerdictMode) {
      conclusionAuthority = decisionMarkerExact && !issuesOverallVerdict;
    } else if (verdictMode == _abstainMode) {
      conclusionAuthority =
          decisionMarkerExact && explicitlyAbstains && !issuesOverallVerdict;
    } else {
      conclusionAuthority = false;
    }
    final formationIndex = text.indexOf('formation');
    final qualityIndex = text.indexOf('quality');
    final formationFirst = verdictMode != _explainLifecycleMode ||
        (formationIndex >= 0 &&
            qualityIndex >= 0 &&
            formationIndex < qualityIndex);
    final hasEarlyActor = _containsAny(
      text,
      const <String>['main:yao:3', '卯木'],
    );
    final hasEarlyTarget = _containsAny(
      text,
      const <String>['main:yao:1', '未土'],
    );
    final hasLaterActor = _containsAny(
      text,
      const <String>['changed:yao:3', '申金'],
    );
    final hasEarlyEffect = text.contains('earlyProcess') &&
        hasEarlyActor &&
        hasEarlyTarget &&
        _containsAny(text, const <String>['克', '克制', '克世', '动而克']);
    final hasLaterRestriction = text.contains('laterProcess') &&
        hasLaterActor &&
        _containsAny(text, const <String>['回头克', '受制', '限制']);
    final deniesEarlyEffect = _deniesEarlyEffect(text);
    final phaseSemanticsPreserved = !selected ||
        (hasEarlyEffect && hasLaterRestriction && !deniesEarlyEffect);
    final rentalCycleCovered = !selected ||
        _containsOneFromEach(text, const <List<String>>[
          <String>['出租权', '合同主体', '权属'],
          <String>['收费', '费用', '押金'],
          <String>['交付占有', '房屋交付', '入住', '占有'],
          <String>['完整租期', '租期持续', '持续履约', '履约中断'],
        ]);
    final liuHeScoped = !_hasUnscopedLiuHeClaim(text);
    final fakeVoidBoundary = !_containsAny(text, const <String>[
      '假空就是不存在',
      '假空表示不存在',
      '假空意味着不存在',
      '假空说明费用不存在',
      '假空说明收费不存在',
      '假空完全无效',
    ]);
    final groundingDiagnostics = _timingAndSourceDiagnostics(
      text,
      projection,
    );
    final timingAndSourcesGrounded =
        groundingDiagnostics.values.every((value) => value);
    final hindsightNotInvented = !_containsUnsupportedPreciseOutcome(text);

    return RealWorldHardGateResult(
      <String, bool>{
        'conclusionAuthority': conclusionAuthority,
        'lifecyclePreserved': lifecyclePreserved,
        'formationFirst': formationFirst,
        'phaseSemanticsPreserved': phaseSemanticsPreserved,
        'rentalCycleCovered': rentalCycleCovered,
        'liuHeScoped': liuHeScoped,
        'fakeVoidBoundary': fakeVoidBoundary,
        'timingAndSourcesGrounded': timingAndSourcesGrounded,
        'hindsightNotInvented': hindsightNotInvented,
      },
      diagnostics: <String, bool>{
        'decisionMarkerExact': decisionMarkerExact,
        'explicitlyAbstains': explicitlyAbstains,
        'noOverallVerdictIssued': !issuesOverallVerdict,
        'frozenLifecycleHeadlinePresent': hasFrozenHeadline,
        'phaseEarlyActorIdentified': hasEarlyActor,
        'phaseEarlyTargetIdentified': hasEarlyTarget,
        'phaseLaterActorIdentified': hasLaterActor,
        'phaseEarlyEffectPreserved': hasEarlyEffect,
        'phaseLaterRestrictionPreserved': hasLaterRestriction,
        'phaseRetroactiveErasureAbsent': !deniesEarlyEffect,
        ..._overallVerdictDiagnosticFlags(text),
        ..._positiveTimingDiagnosticFlags(text),
        ...groundingDiagnostics,
      },
    );
  }

  bool _explicitlyAbstains(String text) {
    final hasMode = text.contains('abstain') ||
        _containsAny(text, const <String>[
          '未选用神',
          '未选定用神',
          '缺少用神',
          '尚未取用',
        ]);
    final sentences = text.split(RegExp(r'[。！？；\n]'));
    final hasBoundary = sentences.any(
      (sentence) =>
          _containsAny(sentence, const <String>[
            '不能判断',
            '无法判断',
            '不作判断',
            '不下结论',
            '只列候选',
            '仅列候选',
            '没有程序裁决',
          ]) ||
          (_containsAny(sentence, const <String>[
                '总体',
                '整体',
                '最终',
                '租房',
              ]) &&
              _containsAny(sentence, const <String>[
                '不能',
                '无法',
                '不作',
                '禁止',
                '不可',
                '不应',
                '暂不',
              ])),
    );
    return hasMode && hasBoundary;
  }

  bool _deniesEarlyEffect(String text) {
    final denial = RegExp(r'前段从未作用|前段没有作用|卯木从未作用|卯木未曾作用');
    final negatedDenial = RegExp(
      r'(?:不得|不能|不可|不应|并非|不是|并不|禁止|避免)'
      r'[^。；！？!?\r\n]{0,16}'
      r'(?:前段从未作用|前段没有作用|卯木从未作用|卯木未曾作用)',
    );
    for (final sentence in text.split(RegExp(r'[。；！？!?\r\n]+'))) {
      if (denial.hasMatch(sentence) && !negatedDenial.hasMatch(sentence)) {
        return true;
      }
    }
    return false;
  }

  bool _issuesOverallVerdict(String text) =>
      _overallVerdictViolationSentences(text).isNotEmpty;

  List<String> _overallVerdictViolationSentences(String text) {
    final violations = <String>[];
    for (final sentence in text.split(RegExp(r'[。！；\n]'))) {
      final statesOutcome = _containsDirectOverallOutcome(sentence);
      final hasQuestionForm = _containsAny(
        sentence,
        const <String>['是否', '能否', '可否', '？', '?'],
      );
      final assertsOutcome = _containsAny(sentence, const <String>[
        '结论是',
        '判断为',
        '断为',
        '因此',
        '所以',
        '故而',
        '可见',
      ]);
      final boundaryScan = sentence
          .replaceAll('不顺利', '')
          .replaceAll('难成', '')
          .replaceAll('最终凶', '')
          .replaceAll('总体凶', '');
      final deniesJudgment = RegExp(
        r'(?:不|无|未|非|勿|莫)[^。；\n]{0,48}'
        r'(?:判断|结论|定论|断语|下断|判定)',
      ).hasMatch(boundaryScan);
      final isBoundary = _containsAny(sentence, const <String>[
            '不能',
            '无法',
            '不作',
            '禁止',
            '不可',
            '不应',
            '暂不',
            '没有资格',
            '并非',
            '不等于',
            '不代表',
            '不意味着',
            '不能说明',
            '不得据此',
            '不能据此',
            '不做',
            '不判断',
            '不予',
            '不判',
            '无结论',
            '不输出',
            '不回答',
            '不评价',
            '不分析',
            '不涉及',
            '不讨论',
            '不描述',
            '不提供',
            '不给出',
            '不具备',
            '无权',
            '无资格',
            '拒绝下结论',
            '仅作核验',
            '【问题】',
            '求测问题',
            '占问',
            '？',
            '?',
          ]) ||
          deniesJudgment ||
          (hasQuestionForm && !assertsOutcome);
      if (statesOutcome && !isBoundary) {
        violations.add(sentence);
      }
    }
    return violations;
  }

  bool _containsDirectOverallOutcome(String sentence) {
    const outcome = r'(?:不顺利|顺利(?!程度|与否|问题)|能成|可成|难成|吉(?!凶)|凶)';
    final assertive = RegExp(
      '(?:结论是|判断为|断为|因此|所以|故而|可见|表明|显示|意味着)'
      r'[^，。；\n]{0,16}'
      '$outcome',
    );
    final rental = RegExp(
      r'(?:本次租房|这次租房|此次租房|租房结果|租房)'
      r'(?:总体|整体)?'
      r'(?:是|为|会|将|可谓|属于|偏向|倾向|呈现|显示|表明|结果)?'
      r'[^，。；\n]{0,8}'
      '$outcome',
    );
    final overall = RegExp(
      r'(?:总体|整体|最终)'
      r'(?:上|而言|来看|判断|结论|结果)?'
      r'(?:是|为|呈现|显示|表明|偏向|倾向)?'
      r'[：,:，\s]{0,3}'
      '$outcome',
    );
    final standalone = RegExp(
      '^\\s*(?:结论[：:]?|总体[：:]?|最终[：:]?)?\\s*$outcome\\s*\$',
    );
    return assertive.hasMatch(sentence) ||
        rental.hasMatch(sentence) ||
        overall.hasMatch(sentence) ||
        standalone.hasMatch(sentence);
  }

  Map<String, bool> _overallVerdictDiagnosticFlags(String text) {
    final violations = _overallVerdictViolationSentences(text);
    final joined = violations.join('\n');
    final withoutNegativeOutcomes =
        joined.replaceAll('不顺利', '').replaceAll('难成', '').replaceAll('凶', '');
    final firstNegationIndex = _firstIndexOfAny(
      withoutNegativeOutcomes,
      const <String>['不', '无', '未', '非', '勿', '莫', '否'],
    );
    final firstSmoothIndex = withoutNegativeOutcomes.indexOf('顺利');
    final firstJiXiongIndex = withoutNegativeOutcomes.indexOf('吉凶');
    return <String, bool>{
      'overallViolationDetected': violations.isNotEmpty,
      'overallViolationUsesRentalScope': joined.contains('租房'),
      'overallViolationUsesOverallScope': _containsAny(
        joined,
        const <String>['总体', '整体', '最终', '租房结果'],
      ),
      'overallViolationUsesSmoothTerm': _containsAny(
        joined,
        const <String>['顺利', '不顺利'],
      ),
      'overallViolationUsesFormationTerm': _containsAny(
        joined,
        const <String>['能成', '可成', '难成'],
      ),
      'overallViolationUsesJiXiongTerm': _containsAny(
        joined,
        const <String>['吉', '凶'],
      ),
      'overallViolationContainsNegativeOutcome': _containsAny(
        joined,
        const <String>['不顺利', '难成', '最终凶', '总体凶'],
      ),
      'overallViolationContainsPositiveOutcome': _containsAny(
        joined.replaceAll('不顺利', '').replaceAll('难成', ''),
        const <String>['顺利', '能成', '可成', '最终吉', '总体吉'],
      ),
      'overallViolationContainsCombinedJiXiong': joined.contains('吉凶'),
      'overallViolationContainsCategoryNoun': _containsAny(
        joined,
        const <String>[
          '程度',
          '与否',
          '判断',
          '结论',
          '定论',
          '层面',
          '结果',
          '问题',
          '好坏',
        ],
      ),
      'overallViolationContainsResidualNegation': _containsAny(
        withoutNegativeOutcomes,
        const <String>['不', '无', '未', '非', '勿', '莫', '否'],
      ),
      'overallViolationNegationPrecedesSmooth': firstNegationIndex >= 0 &&
          firstSmoothIndex >= 0 &&
          firstNegationIndex < firstSmoothIndex,
      'overallViolationNegationPrecedesJiXiong': firstNegationIndex >= 0 &&
          firstJiXiongIndex >= 0 &&
          firstNegationIndex < firstJiXiongIndex,
      'overallViolationSmoothPrecedesNegation': firstNegationIndex >= 0 &&
          firstSmoothIndex >= 0 &&
          firstSmoothIndex < firstNegationIndex,
      'overallViolationContainsRawNegation': _containsAny(
        joined,
        const <String>['不', '无', '未', '非', '否'],
      ),
      'overallViolationContainsQuestionForm': _containsAny(
        joined,
        const <String>['是否', '能否', '可否', '？', '?'],
      ),
      'overallViolationContainsUncertainty': _containsAny(
        joined,
        const <String>['不确定', '无法确定', '尚难', '难以', '不能确定'],
      ),
    };
  }

  bool _hasUnscopedLiuHeClaim(String text) {
    for (final sentence in text.split(RegExp(r'[。！？；\n]'))) {
      if (!sentence.contains('六合')) continue;
      final claimsGoodOutcome = _containsAny(sentence, const <String>[
        '所以顺利',
        '因此顺利',
        '必然顺利',
        '就是吉兆',
        '必然可成',
        '最终吉',
      ]);
      final statesBoundary = _containsAny(sentence, const <String>[
        '不能',
        '不得',
        '不可',
        '并非',
        '不等于',
        '非吉兆',
      ]);
      if (claimsGoodOutcome && !statesBoundary) return true;
    }
    return false;
  }

  Map<String, bool> _timingAndSourceDiagnostics(
    String text,
    Map<String, Object?> projection,
  ) {
    final allowedTiming = _ids(projection, 'timingCandidates', 'timingId');
    if (allowedTiming == null) {
      return const <String, bool>{'timingProjectionValid': false};
    }
    final mentionedTiming = RegExp(r'lyt-[A-Za-z0-9._-]+')
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toSet();
    final diagnostics = <String, bool>{
      'timingIdsGrounded': allowedTiming.containsAll(mentionedTiming),
    };
    if (allowedTiming.isEmpty) {
      diagnostics.addAll(_emptyTimingDiagnostics(text, projection));
    }

    final allowedSources = _ids(projection, 'sources', 'sourceId');
    if (allowedSources == null) {
      diagnostics['sourceProjectionValid'] = false;
      return diagnostics;
    }
    final mentionedSources = RegExp(r'liuyao\.source\.[A-Za-z0-9._-]+')
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toSet();
    diagnostics['sourceIdsGrounded'] =
        allowedSources.containsAll(mentionedSources);

    final allowedTitles = _sourceTitles(projection);
    if (allowedTitles == null) {
      diagnostics['sourceTitlesGrounded'] = false;
      return diagnostics;
    }
    var sourceTitlesGrounded = true;
    for (final match in RegExp(r'《([^》]+)》').allMatches(text)) {
      final title = match.group(1)!;
      if (!allowedTitles.any(
        (allowed) => allowed.contains(title) || title.contains(allowed),
      )) {
        sourceTitlesGrounded = false;
      }
    }
    diagnostics['sourceTitlesGrounded'] = sourceTitlesGrounded;
    return diagnostics;
  }

  Map<String, bool> _emptyTimingDiagnostics(
    String text,
    Map<String, Object?> projection,
  ) {
    final conditions = projection['conditions'];
    final conditionProjectionValid = conditions is List;
    final hasMechanicalConditions = conditions is List && conditions.isNotEmpty;
    var noPositiveTimingInstruction = true;
    var releaseConditionsQualified = true;
    var datesGrounded = true;
    for (final sentence in text.split(RegExp(r'[。！？!?；;\r\n]+'))) {
      if (sentence.isEmpty) continue;
      final hasReleaseCondition = _containsReleaseCondition(sentence);
      if (hasReleaseCondition) {
        if (!hasMechanicalConditions &&
            _isGroundedCurrentBindingResolution(sentence, projection)) {
          continue;
        }
        if (!hasMechanicalConditions ||
            !sentence.contains(_releaseConditionDisclaimer) ||
            _containsPositiveTimingInstruction(
              sentence,
              allowMechanicalWaitLabel: true,
            ) ||
            _containsActionAdvice(sentence) ||
            (_containsConcreteDate(sentence) &&
                _containsUnsupportedConcreteDate(sentence, projection))) {
          releaseConditionsQualified = false;
        }
        continue;
      }
      if (_containsPositiveTimingInstruction(sentence)) {
        noPositiveTimingInstruction = false;
      }
      if (_containsConcreteDate(sentence) &&
          (_containsUnsupportedConcreteDate(sentence, projection) ||
              _containsActionAdvice(sentence))) {
        datesGrounded = false;
      }
    }
    return <String, bool>{
      'conditionProjectionValid': conditionProjectionValid,
      'noPositiveTimingInstruction': noPositiveTimingInstruction,
      'releaseConditionsQualified': releaseConditionsQualified,
      'datesGrounded': datesGrounded,
    };
  }

  bool _isGroundedCurrentBindingResolution(
    String sentence,
    Map<String, Object?> projection,
  ) {
    if (!_containsAny(sentence, const <String>['冲开', '解除合绊', '合绊已解']) ||
        RegExp(r'出空|出月|填实').hasMatch(sentence) ||
        !_hasActiveActorFactRule(projection, _bindingOpenedRuleId) ||
        !_containsCompletedCurrentBindingResolution(sentence) ||
        _containsFutureBindingResolution(sentence) ||
        _containsPositiveTimingInstruction(sentence) ||
        _containsActionAdvice(sentence) ||
        (_containsConcreteDate(sentence) &&
            _containsUnsupportedConcreteDate(sentence, projection))) {
      return false;
    }

    final dayBranch = _castDayBranch(projection);
    final citesCastDay = dayBranch != null &&
        RegExp('${RegExp.escape(dayBranch)}(?:日|辰)?[^\u3002\uff1b]{0,12}冲开')
            .hasMatch(sentence);
    return sentence.contains('日辰') || sentence.contains('日冲') || citesCastDay;
  }

  bool _containsCompletedCurrentBindingResolution(String sentence) => RegExp(
        r'(?:已|已经|现已|当前已|当下已)[^。；]{0,12}(?:冲开|解除)|'
        r'(?:冲开|解除)(?:了|完成|完毕)',
      ).hasMatch(sentence);

  bool _containsFutureBindingResolution(String sentence) => RegExp(
        r'(?:将会|即将|将|会|待|等待|等到|等至|届时)'
        r'[^。；]{0,16}(?:冲开|解除)|'
        r'(?:冲开|解除)[^。；]{0,16}'
        r'(?:之后|以后|随后|后再|再|才|方|将会|即将|将|会|届时)',
      ).hasMatch(sentence);

  bool _hasActiveActorFactRule(
    Map<String, Object?> projection,
    String ruleId,
  ) {
    final actorFacts = projection['actorFacts'];
    if (actorFacts is! List) return false;
    for (final actorFact in actorFacts) {
      if (actorFact is! Map) continue;
      final tags = actorFact['tags'];
      if (tags is! List) continue;
      for (final tag in tags) {
        if (tag is Map && tag['ruleId'] == ruleId && tag['active'] == true) {
          return true;
        }
      }
    }
    return false;
  }

  String? _castDayBranch(Map<String, Object?> projection) {
    final pan = projection['pan'];
    if (pan is! Map) return null;
    final calendar = pan['calendar'];
    if (calendar is! Map) return null;
    final dayGanZhi = calendar['dayGanZhi'];
    if (dayGanZhi is! String || dayGanZhi.isEmpty) return null;
    return dayGanZhi.substring(dayGanZhi.length - 1);
  }

  bool _containsUnsupportedConcreteDate(
    String sentence,
    Map<String, Object?> projection,
  ) {
    var remaining = sentence;
    final allowed = _castDateSpellings(projection).toList()
      ..sort((left, right) => right.length.compareTo(left.length));
    for (final spelling in allowed) {
      remaining = remaining.replaceAll(spelling, '');
    }
    return _containsConcreteDate(remaining);
  }

  Set<String> _castDateSpellings(Map<String, Object?> projection) {
    final pan = projection['pan'];
    if (pan is! Map) return const <String>{};
    final calendar = pan['calendar'];
    if (calendar is! Map) return const <String>{};
    final castTime = calendar['castTime'];
    if (castTime is! String) return const <String>{};
    final match = RegExp(
      r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})',
    ).firstMatch(castTime);
    if (match == null) return const <String>{};
    final year = match.group(1)!;
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final monthForms = <String>{'$month', month.toString().padLeft(2, '0')};
    final dayForms = <String>{'$day', day.toString().padLeft(2, '0')};
    final result = <String>{};
    for (final monthForm in monthForms) {
      result.add('$year年$monthForm月');
      for (final dayForm in dayForms) {
        result
          ..add('$year年$monthForm月$dayForm日')
          ..add('$year-$monthForm-$dayForm')
          ..add('$year/$monthForm/$dayForm')
          ..add('$year.$monthForm.$dayForm')
          ..add('$monthForm月$dayForm日')
          ..add('$dayForm日');
      }
    }
    return result;
  }

  bool _containsReleaseCondition(String sentence) =>
      RegExp(r'出空|出月|填实|冲开|解除合绊|合绊已解').hasMatch(sentence);

  bool _containsPositiveTimingInstruction(
    String sentence, {
    bool allowMechanicalWaitLabel = false,
  }) {
    final cues = <String>[
      '等待',
      '等到',
      '等至',
      '待到',
      '待至',
      '择日',
      '时机',
      '届时',
      if (!allowMechanicalWaitLabel) ...<String>[
        '待出空',
        '待出月',
        '待填实',
        '待冲开',
      ],
    ];
    for (final cue in cues) {
      var start = 0;
      while (true) {
        final index = sentence.indexOf(cue, start);
        if (index < 0) break;
        if (!_isNegated(sentence, index) &&
            !_isDeniedAfterCue(sentence, index + cue.length)) {
          return true;
        }
        start = index + cue.length;
      }
    }
    return false;
  }

  Map<String, bool> _positiveTimingDiagnosticFlags(String text) =>
      <String, bool>{
        'positiveWaitingCueDetected': _containsPositiveTimingCueGroup(
          text,
          const <String>[
            '等待',
            '等到',
            '等至',
            '待到',
            '待至',
            '待出空',
            '待出月',
            '待填实',
            '待冲开',
          ],
        ),
        'positiveChooseDateCueDetected':
            _containsPositiveTimingCueGroup(text, const <String>['择日']),
        'positiveChooseDateCueContainsRawNegation': _containsAny(
          _positiveTimingCueSentences(text, const <String>['择日']).join('\n'),
          const <String>['不', '无', '未', '非', '勿', '莫', '否'],
        ),
        'positiveChooseDateCueContainsAdviceLanguage': _containsAny(
          _positiveTimingCueSentences(text, const <String>['择日']).join('\n'),
          const <String>['建议', '应当', '应该', '可以', '可在', '宜在'],
        ),
        'positiveOpportunityCueDetected':
            _containsPositiveTimingCueGroup(text, const <String>['时机']),
        'positiveThenCueDetected':
            _containsPositiveTimingCueGroup(text, const <String>['届时']),
      };

  bool _containsPositiveTimingCueGroup(String text, List<String> cues) {
    return _positiveTimingCueSentences(text, cues).isNotEmpty;
  }

  List<String> _positiveTimingCueSentences(String text, List<String> cues) {
    final matches = <String>[];
    for (final sentence in text.split(RegExp(r'[。！？!?；;\r\n]+'))) {
      for (final cue in cues) {
        var start = 0;
        while (true) {
          final index = sentence.indexOf(cue, start);
          if (index < 0) break;
          if (!_isNegated(sentence, index) &&
              !_isDeniedAfterCue(sentence, index + cue.length)) {
            matches.add(sentence);
            break;
          }
          start = index + cue.length;
        }
      }
    }
    return matches;
  }

  bool _containsConcreteDate(String sentence) => RegExp(
        r'(?:\d{4}\s*年\s*\d{1,2}\s*月(?:\s*\d{1,2}\s*[日号])?|'
        r'\d{1,2}\s*月\s*\d{1,2}\s*[日号]|'
        r'\d{4}\s*[-/.]\s*\d{1,2}\s*[-/.]\s*\d{1,2}|'
        r'\d{1,2}\s*[日号])',
      ).hasMatch(sentence);

  bool _containsActionAdvice(String sentence) {
    const cues = <String>[
      '建议',
      '应当',
      '应该',
      '务必',
      '最好',
      '需要',
      '必须',
      '可以',
      '可在',
      '可于',
      '宜在',
      '宜于',
    ];
    for (final cue in cues) {
      var start = 0;
      while (true) {
        final index = sentence.indexOf(cue, start);
        if (index < 0) break;
        if (!_isNegated(sentence, index)) return true;
        start = index + cue.length;
      }
    }

    const actions = <String>[
      '签约',
      '付款',
      '付费',
      '交费',
      '缴费',
      '入住',
      '办理',
      '行动',
      '联系对方',
      '提交',
      '决定',
    ];
    for (final action in actions) {
      var start = 0;
      while (true) {
        final actionIndex = sentence.indexOf(action, start);
        if (actionIndex < 0) break;
        if (!_isNegated(sentence, actionIndex)) return true;
        start = actionIndex + action.length;
      }
    }
    return false;
  }

  bool _isNegated(String sentence, int index) {
    if (index == 0) return false;
    var clauseStart = 0;
    for (final separator in const <String>['，', ',', '；', ';', '但', '却']) {
      final separatorIndex = sentence.lastIndexOf(separator, index - 1);
      if (separatorIndex >= clauseStart) {
        clauseStart = separatorIndex + separator.length;
      }
    }
    final prefix = sentence.substring(clauseStart, index).trimLeft();
    return prefix.startsWith('不') ||
        prefix.startsWith('无') ||
        prefix.startsWith('未') ||
        prefix.startsWith('非') ||
        prefix.startsWith('勿') ||
        prefix.startsWith('莫') ||
        prefix.endsWith('非') ||
        _containsAny(prefix, const <String>[
          '不代表',
          '不能',
          '不可',
          '不得',
          '不应',
          '不建议',
          '不可以',
          '不提供',
          '禁止',
          '切勿',
          '不要',
          '无需',
          '无须',
          '不必',
          '不做',
          '不作',
          '不予',
          '不判',
          '不另',
          '不宜',
          '避免',
          '而非',
          '并非',
          '不是',
        ]);
  }

  bool _isDeniedAfterCue(String sentence, int cueEnd) {
    final end = cueEnd + 16 < sentence.length ? cueEnd + 16 : sentence.length;
    final suffix = sentence.substring(cueEnd, end).trimLeft();
    return suffix.startsWith('：无') ||
        suffix.startsWith(':无') ||
        suffix.startsWith('为无') ||
        suffix.startsWith('没有') ||
        suffix.startsWith('尚无') ||
        suffix.startsWith('尚未') ||
        suffix.startsWith('未给') ||
        suffix.startsWith('不提供') ||
        suffix.startsWith('不适用') ||
        suffix.startsWith('为空') ||
        suffix.startsWith('=withheld');
  }

  bool _containsUnsupportedPreciseOutcome(String text) => RegExp(
        r'二房东|黑中介|跑路|被赶(?:出|走)|甲午月|'
        r'(?:损失|被骗|多骗|中介费)[^。；\n]{0,10}(?:3000|三千)|'
        r'(?:交|预付)[^。；\n]{0,6}六个月|'
        r'(?:住|居住)[^。；\n]{0,6}三个月',
      ).hasMatch(text);

  String? _verdictMode(Map<String, Object?> projection) {
    final rawPolicy = projection['policy'];
    if (rawPolicy is! Map) return null;
    final mode = rawPolicy['verdictMode'];
    return mode is String ? mode : null;
  }

  bool _hasRequiredDecisionMarker(
    String rawOutput,
    Map<String, Object?> projection,
  ) {
    final expected = _expectedDecisionMarker(projection);
    if (expected == null) return false;
    return rawOutput == expected ||
        rawOutput.startsWith('$expected\n') ||
        rawOutput.startsWith('$expected\r\n');
  }

  String? _expectedDecisionMarker(Map<String, Object?> projection) {
    final mode = _verdictMode(projection);
    final timingIds = _ids(projection, 'timingCandidates', 'timingId');
    if (mode == null || timingIds == null) return null;
    final timing = timingIds.isEmpty ? 'withheld' : 'provided';
    if (mode == _abstainMode) {
      if (timingIds.isNotEmpty) return null;
      return '[LIUYAO_DECISION] mode=abstain;overall=withheld;timing=withheld';
    }
    if (mode == _explainLifecycleMode) {
      return '[LIUYAO_DECISION] mode=explainLifecycle;'
          'overall=lifecycle;timing=$timing';
    }
    if (mode == _explainSelectedVerdictMode) {
      return '[LIUYAO_DECISION] mode=explainSelectedVerdict;'
          'overall=withheld;timing=$timing';
    }
    return null;
  }

  Set<String>? _ids(
    Map<String, Object?> projection,
    String collectionKey,
    String idKey,
  ) {
    final raw = projection[collectionKey];
    if (raw is! List) return null;
    final result = <String>{};
    for (final item in raw) {
      if (item is! Map<Object?, Object?>) return null;
      final id = item[idKey];
      if (id is! String || id.isEmpty) return null;
      result.add(id);
    }
    return result;
  }

  Set<String>? _sourceTitles(Map<String, Object?> projection) {
    final raw = projection['sources'];
    if (raw is! List) return null;
    final result = <String>{};
    for (final item in raw) {
      if (item is! Map<Object?, Object?>) return null;
      final title = item['title'];
      if (title is! String || title.isEmpty) return null;
      result.add(title);
    }
    return result;
  }

  bool _containsAll(String text, Iterable<String> values) =>
      values.every(text.contains);

  bool _containsAny(String text, Iterable<String> values) =>
      values.any(text.contains);

  bool _containsOneFromEach(String text, Iterable<List<String>> groups) =>
      groups.every((group) => _containsAny(text, group));

  int _firstIndexOfAny(String text, Iterable<String> values) {
    var result = -1;
    for (final value in values) {
      final index = text.indexOf(value);
      if (index >= 0 && (result < 0 || index < result)) result = index;
    }
    return result;
  }
}
