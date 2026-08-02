import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/liuyao_ai_eval/assets.dart';
import '../../../tool/liuyao_ai_eval/canonical_json.dart';
import '../../../tool/liuyao_ai_eval/constants.dart';
import '../../../tool/liuyao_ai_eval/hard_gates.dart';
import '../../../tool/liuyao_ai_eval/security.dart';

void main() {
  late EvalAssets assets;

  setUpAll(() {
    assets = EvalAssets(Directory.current.path);
  });

  test(
      'frozen templates and actual formatter-to-assembler requests hash cleanly',
      () {
    final FrozenValidation frozen = assets.validateFrozenAssets();

    expect(frozen.sourceCommit, hasLength(40));
    expect(
        frozen.templateHashes.keys,
        containsAll(<String>{
          'builtin_liuyao_system',
          'builtin_liuyao_analysis',
          'builtin_liuyao_brief',
        }));
    expect(frozen.requests, hasLength(2));
    expect(
      frozen.requests.map((Map<String, Object?> item) => item['requestId']),
      containsAll(<String>{
        'legacy-selected-moving-comprehensive',
        'legacy-unselected-static-brief',
      }),
    );
  });

  test('fixture keeps case kind and evaluation split orthogonal', () {
    final EvalFixture fixture = assets.loadFixture();

    expect(fixture.cases, hasLength(2));
    expect(
      fixture.cases
          .where((EvalCase value) => value.caseKind == 'ruleValidation'),
      everyElement(
        isA<EvalCase>().having(
          (EvalCase value) => value.evaluationSplit,
          'evaluationSplit',
          'calibration',
        ),
      ),
    );
  });

  test('canonical cache is bound to the shared classics fixture', () {
    final EvalFixture fixture = assets.loadCanonicalFixture();
    final Map<String, Object?> source = _readObject(
      evalClassicsFixtureRelativePath,
    );
    expect(fixture.sourceFixtureVersion, source['fixtureVersion']);
    expect(fixture.sourceFixtureHash, sha256Json(source));

    final Directory temporary = Directory.systemTemp.createTempSync(
      'liuyao-eval-source-binding-',
    );
    addTearDown(() => temporary.deleteSync(recursive: true));
    final File cached = File(
      '${temporary.path}/$evalCanonicalFixtureRelativePath',
    )..parent.createSync(recursive: true);
    File(evalCanonicalFixtureRelativePath).copySync(cached.path);
    final Map<String, Object?> changedSource = _deepCopy(source);
    changedSource['fixtureVersion'] = 'tampered-source/1';
    final File sourceCopy = File(
      '${temporary.path}/$evalClassicsFixtureRelativePath',
    )..parent.createSync(recursive: true);
    sourceCopy.writeAsStringSync(jsonEncode(changedSource));

    expect(
      () => EvalAssets(temporary.path).loadCanonicalFixture(),
      throwsA(
        isA<EvalFailure>().having(
          (EvalFailure error) => error.kind,
          'kind',
          'canonicalV2SourceFixtureMismatch',
        ),
      ),
    );
  });

  test('fixture rejects scoring reference fields in model input', () {
    final Map<String, Object?> document = _deepCopy(
      _readObject('tool/liuyao_ai_eval/fixtures/offline_fixture.json'),
    );
    final List<Object?> cases = document['cases']! as List<Object?>;
    final Map<String, Object?> first =
        (cases.first! as Map).cast<String, Object?>();
    final Map<String, Object?> requestInput =
        (first['requestInput']! as Map).cast<String, Object?>();
    requestInput['adjudication'] = 'leaked answer';

    expect(
      () => EvalFixture.fromJson(document),
      throwsA(isA<FormatException>()),
    );
  });

  test('rubric freezes seven dimensions across four declared cohorts', () {
    final EvalRubric rubric = assets.loadRubric();

    expect(rubric.dimensions, hasLength(7));
    expect(rubric.cohorts, hasLength(4));
    expect(
      rubric.dimensions.expand((RubricDimension value) => value.anchors.keys),
      everyElement(anyOf(0, 1, 2)),
    );
  });

  test('known good passes and every registered bad sample trips its gate', () {
    final EvalFixture fixture = assets.loadFixture();
    final EvalRubric rubric = assets.loadRubric();
    final Map<String, Object?> outputs = assets.loadOfflineOutputs();

    expect(
      () => validateOfflineHardGateFixtures(fixture, rubric, outputs),
      returnsNormally,
    );

    final EvalCase evalCase = fixture.caseById(outputs['caseId']! as String);
    final Map<String, Object?> badByGate =
        (outputs['badByGate']! as Map).cast<String, Object?>();
    for (final String gateId in hardGateIds) {
      final NormalizedModelOutput output = NormalizedModelOutput.fromJson(
        (badByGate[gateId]! as Map).cast<String, Object?>(),
      );
      expect(
        const HardGateEvaluator().evaluate(evalCase, output).failedGateIds,
        contains(gateId),
        reason: gateId,
      );
    }
  });
}

Map<String, Object?> _readObject(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as Map).cast<String, Object?>();

Map<String, Object?> _deepCopy(Map<String, Object?> value) =>
    decodeObject(jsonEncode(value));
