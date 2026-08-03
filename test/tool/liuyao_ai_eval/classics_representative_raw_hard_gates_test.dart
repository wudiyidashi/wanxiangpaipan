import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/liuyao_ai_eval/canonical_json.dart';
import '../../../tool/liuyao_ai_eval/classics_representative_contract.dart';
import '../../../tool/liuyao_ai_eval/classics_representative_raw_hard_gates.dart';
import '../../../tool/liuyao_ai_eval/hard_gates.dart';

void main() {
  late ClassicsRepresentativeAdapterCase adapterCase;
  late String validOutput;

  setUpAll(() {
    final ClassicsRepresentativeAssetLoader loader =
        ClassicsRepresentativeAssetLoader(Directory.current.path);
    final ClassicsRepresentativeGenerationFixture fixture =
        loader.loadGenerationFixture();
    final ClassicsRepresentativeAdapter adapter = loader.loadAdapter(fixture);
    adapterCase = adapter.caseById('liuyao.case.golden.007');
    validOutput = _validOutput(adapterCase.candidate.projection);
  });

  test('raw gate IDs remain distinct from judge normalization phase', () {
    expect(classicsRepresentativeRawHardGateIds, hardGateIds);
    final result = const ClassicsRepresentativeRawHardGateEvaluator().evaluate(
      adapterCase: adapterCase,
      rawOutput: validOutput,
    );
    expect(result.passed, isTrue, reason: result.gates.toString());
  });

  test('each raw claim is checked without a scoring reference', () {
    final Map<String, String> invalidByGate = <String, String>{
      'verdictPreserved': ' $validOutput',
      'conditionsComplete': validOutput.replaceFirst('待出月', '条件甲'),
      'panAndYongShenGrounded': validOutput.replaceFirst(
        'main:yao:6',
        'main:yao:9',
      ),
      'timingBounded': '$validOutput\nlyt-not-allowlisted',
      'sourcesAllowlisted': '$validOutput\nliuyao.source.not-allowlisted',
      'citationsAllowlisted': '$validOutput\n据第999页。',
    };

    for (final MapEntry<String, String> entry in invalidByGate.entries) {
      final result =
          const ClassicsRepresentativeRawHardGateEvaluator().evaluate(
        adapterCase: adapterCase,
        rawOutput: entry.value,
      );
      expect(
        result.failedGateIds,
        contains(entry.key),
        reason: '${entry.key}: ${result.gates}',
      );
    }
  });
}

String _validOutput(Map<String, Object?> projection) {
  final String mode = requireString(
    requireObject(projection, 'policy'),
    'verdictMode',
  );
  final List<Object?> timing = requireList(projection, 'timingCandidates');
  final Map<String, Object?> verdict = requireObject(projection, 'verdict');
  final List<String> lines = <String>[
    '[LIUYAO_DECISION] mode=$mode;overall=withheld;'
        'timing=${timing.isEmpty ? 'withheld' : 'provided'}',
    'trend=${requireString(verdict, 'trend')}',
    'matchedDecisionRowId=${requireString(verdict, 'matchedDecisionRowId')}',
  ];
  final Object? nuance = verdict['nuance'];
  if (nuance is String) lines.add('nuance=$nuance');
  for (final Object? raw in requireList(projection, 'conditions')) {
    final Map<String, Object?> condition =
        (raw as Map<Object?, Object?>).cast<String, Object?>();
    lines.add(requireString(condition, 'label'));
  }
  final Map<String, Object?> selectedRole = requireList(projection, 'roles')
      .map((raw) => (raw as Map<Object?, Object?>).cast<String, Object?>())
      .singleWhere((role) => requireBool(role, 'selected'));
  final Map<String, Object?> actor = selectedRole['actor'] is Map
      ? (selectedRole['actor']! as Map<Object?, Object?>)
          .cast<String, Object?>()
      : selectedRole;
  lines.add(
    '用神 ${requireString(actor, 'actorId')}',
  );
  for (final Object? raw in timing) {
    final Map<String, Object?> candidate =
        (raw as Map<Object?, Object?>).cast<String, Object?>();
    lines.add('${requireString(candidate, 'label')}，不保证结果。');
  }
  final Map<String, Object?> source =
      (requireList(projection, 'sources').first as Map<Object?, Object?>)
          .cast<String, Object?>();
  lines.add('来源 ${requireString(source, 'sourceId')}');
  return lines.join('\n');
}
