import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/shared/lunar_service.dart';

import '../../../tool/liuyao_ai_eval/assets.dart';
import '../../../tool/liuyao_ai_eval/canonical_contract.dart';
import '../../../tool/liuyao_ai_eval/canonical_json.dart';
import '../../../tool/liuyao_ai_eval/constants.dart';
import '../../../tool/liuyao_ai_eval/paired_evaluation.dart';
import '../../../tool/liuyao_ai_eval/security.dart';

void main() {
  test('canonical v2 remains a frozen cache after production advances', () {
    final EvalAssets assets = EvalAssets(Directory.current.path);
    final EvalFixture fixture = assets.loadCanonicalFixture();
    final EvalRubric rubric = assets.loadRubric();
    final CanonicalEvalAdapter adapter = CanonicalAdapterFileLoader(
      repositoryRoot: Directory.current.path,
    ).load(fixture, rubric);

    expect(fixture.projectionSchemaVersion, canonicalProjectionSchemaVersion);
    expect(fixture.hash, canonicalV2FixtureHash);
    expect(adapter.hash, canonicalV2AdapterHash);
    expect(fixture.cases, hasLength(40));
    expect(
      fixture.cases.where((item) => item.caseKind == 'originalBook'),
      hasLength(26),
    );
    expect(
      fixture.cases.where((item) => item.caseKind == 'ruleValidation'),
      hasLength(14),
    );
    expect(
      fixture.cases.where((item) => item.evaluationSplit == 'holdout'),
      hasLength(6),
    );
    expect(adapter.cases, hasLength(40));
    expect(adapter.sourceFixtureVersion, fixture.sourceFixtureVersion);
    expect(adapter.sourceFixtureHash, fixture.sourceFixtureHash);

    for (int index = 0; index < fixture.cases.length; index += 1) {
      final Map<String, Object?> projection = requireObject(
        fixture.cases[index].requestInput,
        'projection',
      );
      final Map<String, Object?> calendar = requireObject(
        requireObject(projection, 'pan'),
        'calendar',
      );
      expect(
        canonicalJson(projection),
        isNot(contains('liuyao.rule.special.year-command')),
      );
      final String prompt =
          adapter.cases[index].variants[candidateVariant]!.userPrompt;
      final RegExpMatch? date = RegExp(
        r'公历: (\d{4})年(\d{1,2})月(\d{1,2})日 (\d{2}):(\d{2})',
      ).firstMatch(prompt);
      expect(date, isNotNull);
      final computed = LunarService.getLunarInfo(
        DateTime.utc(
          int.parse(date!.group(1)!),
          int.parse(date.group(2)!),
          int.parse(date.group(3)!),
          int.parse(date.group(4)!),
          int.parse(date.group(5)!),
        ),
      );
      expect(calendar['yearGanZhi'], computed.yearGanZhi);
      expect(calendar['monthGanZhi'], computed.monthGanZhi);
      expect(calendar['dayGanZhi'], computed.riGanZhi);
      expect(calendar['yueJian'], computed.yueJian);
    }

    final CanonicalPairContract pair = validateCanonicalRequestPair(
      baseline: CanonicalRequestSet.create(
        runId: 'canonical-v2-r1',
        variant: baselineVariant,
        adapter: adapter,
        fixture: fixture,
        rubric: rubric,
      ),
      candidate: CanonicalRequestSet.create(
        runId: 'canonical-v2-r1',
        variant: candidateVariant,
        adapter: adapter,
        fixture: fixture,
        rubric: rubric,
      ),
      fixture: fixture,
    );
    expect(pair.candidateHash, canonicalV2CandidateHash);

    final SensitiveDataFilter filter = SensitiveDataFilter();
    final SafeArtifactReader reader = SafeArtifactReader(
      root: Directory.current,
    );
    expect(
      filter
          .scanText(
            canonicalJson(reader.readJson(evalCanonicalFixtureRelativePath)),
          )
          .isClean,
      isTrue,
    );
    expect(
      filter
          .scanText(
            canonicalJson(reader.readJson(evalCanonicalAdapterRelativePath)),
          )
          .isClean,
      isTrue,
    );
  });
}
