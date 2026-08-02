import 'assets.dart';
import 'canonical_json.dart';

const Set<String> hardGateIds = <String>{
  'verdictPreserved',
  'conditionsComplete',
  'panAndYongShenGrounded',
  'timingBounded',
  'sourcesAllowlisted',
  'citationsAllowlisted',
};

class TimingClaim {
  const TimingClaim({required this.timingId, required this.guaranteed});

  final String timingId;
  final bool guaranteed;

  factory TimingClaim.fromJson(Map<String, Object?> json) {
    requireExactKeys(json, <String>{'timingId', 'guaranteed'});
    return TimingClaim(
      timingId: requireString(json, 'timingId'),
      guaranteed: requireBool(json, 'guaranteed'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'timingId': timingId,
        'guaranteed': guaranteed,
      };
}

class CitationClaim {
  const CitationClaim({
    required this.sourceId,
    required this.locator,
    required this.quote,
  });

  final String sourceId;
  final String? locator;
  final String? quote;

  factory CitationClaim.fromJson(Map<String, Object?> json) {
    requireExactKeys(json, <String>{'sourceId', 'locator', 'quote'});
    final Object? locator = json['locator'];
    final Object? quote = json['quote'];
    if ((locator != null && locator is! String) ||
        (quote != null && quote is! String)) {
      throw const FormatException('Citation values must be strings or null.');
    }
    return CitationClaim(
      sourceId: requireString(json, 'sourceId'),
      locator: locator as String?,
      quote: quote as String?,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'sourceId': sourceId,
        'locator': locator,
        'quote': quote,
      };
}

class NormalizedModelOutput {
  const NormalizedModelOutput({
    required this.caseId,
    required this.verdictTrend,
    required this.conditionIds,
    required this.panFactIds,
    required this.yongShenActorId,
    required this.timingClaims,
    required this.sourceIds,
    required this.citations,
  });

  final String caseId;
  final String? verdictTrend;
  final Set<String> conditionIds;
  final Set<String> panFactIds;
  final String? yongShenActorId;
  final List<TimingClaim> timingClaims;
  final Set<String> sourceIds;
  final List<CitationClaim> citations;

  factory NormalizedModelOutput.fromJson(Map<String, Object?> json) {
    requireExactKeys(
      json,
      <String>{
        'caseId',
        'verdictTrend',
        'conditionIds',
        'panFactIds',
        'yongShenActorId',
        'timingClaims',
        'sourceIds',
        'citations',
      },
    );
    final Object? verdict = json['verdictTrend'];
    final Object? yongShen = json['yongShenActorId'];
    if ((verdict != null && verdict is! String) ||
        (yongShen != null && yongShen is! String)) {
      throw const FormatException('Normalized nullable value is invalid.');
    }
    final List<TimingClaim> timingClaims = requireList(json, 'timingClaims')
        .map(
          (Object? value) => TimingClaim.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
    final List<CitationClaim> citations = requireList(json, 'citations')
        .map(
          (Object? value) => CitationClaim.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
    return NormalizedModelOutput(
      caseId: requireString(json, 'caseId'),
      verdictTrend: verdict as String?,
      conditionIds: requireStringList(json, 'conditionIds').toSet(),
      panFactIds: requireStringList(json, 'panFactIds').toSet(),
      yongShenActorId: yongShen as String?,
      timingClaims: List<TimingClaim>.unmodifiable(timingClaims),
      sourceIds: requireStringList(json, 'sourceIds').toSet(),
      citations: List<CitationClaim>.unmodifiable(citations),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'caseId': caseId,
        'verdictTrend': verdictTrend,
        'conditionIds': conditionIds.toList()..sort(),
        'panFactIds': panFactIds.toList()..sort(),
        'yongShenActorId': yongShenActorId,
        'timingClaims': timingClaims
            .map((TimingClaim claim) => claim.toJson())
            .toList(growable: false),
        'sourceIds': sourceIds.toList()..sort(),
        'citations': citations
            .map((CitationClaim claim) => claim.toJson())
            .toList(growable: false),
      };
}

class HardGateResult {
  const HardGateResult({required this.gates});

  final Map<String, bool> gates;

  bool get passed => gates.values.every((bool value) => value);

  Set<String> get failedGateIds => gates.entries
      .where((MapEntry<String, bool> entry) => !entry.value)
      .map((MapEntry<String, bool> entry) => entry.key)
      .toSet();

  Map<String, Object?> toJson() => <String, Object?>{
        'passed': passed,
        'gates': <String, Object?>{
          for (final String gate in (gates.keys.toList()..sort()))
            gate: gates[gate],
        },
      };
}

class HardGateEvaluator {
  const HardGateEvaluator();

  HardGateResult evaluate(EvalCase evalCase, NormalizedModelOutput output) {
    if (output.caseId != evalCase.caseId) {
      return HardGateResult(
        gates: <String, bool>{
          for (final String gate in hardGateIds) gate: false
        },
      );
    }
    final ScoringReference reference = evalCase.scoringReference;
    final bool verdictPreserved =
        output.verdictTrend == reference.expectedVerdictTrend;
    final bool conditionsComplete =
        _setEquals(output.conditionIds, reference.requiredConditionIds);
    final bool panGrounded =
        reference.allowedPanFactIds.containsAll(output.panFactIds) &&
            output.yongShenActorId == reference.expectedYongShenActorId;
    final bool timingBounded = output.timingClaims.every(
      (TimingClaim claim) =>
          reference.allowedTimingIds.contains(claim.timingId) &&
          !claim.guaranteed,
    );
    final Set<String> claimedSourceIds = <String>{
      ...output.sourceIds,
      ...output.citations.map((CitationClaim citation) => citation.sourceId),
    };
    final bool sourcesAllowlisted =
        reference.allowedSources.keys.toSet().containsAll(claimedSourceIds);
    final bool citationsAllowlisted = output.citations.every(
      (CitationClaim citation) {
        final AllowedSource? source =
            reference.allowedSources[citation.sourceId];
        if (source == null) {
          return false;
        }
        final String? locator = citation.locator;
        final String? quote = citation.quote;
        return (locator == null || source.locators.contains(locator)) &&
            (quote == null || source.exactQuotes.contains(quote));
      },
    );
    return HardGateResult(
      gates: <String, bool>{
        'verdictPreserved': verdictPreserved,
        'conditionsComplete': conditionsComplete,
        'panAndYongShenGrounded': panGrounded,
        'timingBounded': timingBounded,
        'sourcesAllowlisted': sourcesAllowlisted,
        'citationsAllowlisted': citationsAllowlisted,
      },
    );
  }
}

void validateOfflineHardGateFixtures(
  EvalFixture fixture,
  EvalRubric rubric,
  Map<String, Object?> document,
) {
  requireExactKeys(
    document,
    <String>{'schemaVersion', 'caseId', 'good', 'badByGate'},
  );
  if (requireString(document, 'schemaVersion') !=
          'liuyao-ai-normalized-output-fixtures/1.0.0' ||
      !_setEquals(rubric.hardGateIds, hardGateIds)) {
    throw const FormatException('Offline hard-gate contract changed.');
  }
  final EvalCase evalCase = fixture.caseById(requireString(document, 'caseId'));
  const HardGateEvaluator evaluator = HardGateEvaluator();
  final NormalizedModelOutput good = NormalizedModelOutput.fromJson(
    requireObject(document, 'good'),
  );
  if (!evaluator.evaluate(evalCase, good).passed) {
    throw const FormatException('Known-good output failed a hard gate.');
  }
  final Map<String, Object?> badByGate = requireObject(document, 'badByGate');
  requireExactKeys(badByGate, hardGateIds);
  for (final String gateId in hardGateIds) {
    final NormalizedModelOutput bad = NormalizedModelOutput.fromJson(
      (badByGate[gateId]! as Map).cast<String, Object?>(),
    );
    final HardGateResult result = evaluator.evaluate(evalCase, bad);
    if (!result.failedGateIds.contains(gateId)) {
      throw const FormatException(
          'Known-bad output did not fail its hard gate.');
    }
  }
}

bool _setEquals<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);
