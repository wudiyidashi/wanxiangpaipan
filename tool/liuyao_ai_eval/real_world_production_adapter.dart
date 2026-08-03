import 'dart:io';

import 'package:wanxiang_paipan/ai/service/prompt_assembler.dart';
import 'package:wanxiang_paipan/ai/template/builtin_templates.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';

import 'canonical_contract.dart';
import 'canonical_json.dart';
import 'constants.dart';
import 'real_world_contract.dart';
import 'security.dart';

class RealWorldProductionAssets {
  const RealWorldProductionAssets({
    required this.document,
    required this.fixture,
    required this.adapter,
  });

  final Map<String, Object?> document;
  final RealWorldGenerationFixture fixture;
  final RealWorldEvalAdapter adapter;
}

class RealWorldProductionAdapterBuilder {
  RealWorldProductionAdapterBuilder({
    required this.repositoryRoot,
    required this.assembler,
  });

  final String repositoryRoot;
  final PromptAssembler assembler;

  Future<RealWorldProductionAssets> build() async {
    final RealWorldAssetLoader loader = RealWorldAssetLoader(repositoryRoot);
    final RealWorldGenerationFixture fixture = loader.loadGenerationFixture();
    final Map<String, Object?> baselineDocument = SafeArtifactReader(
      root: Directory(repositoryRoot),
    ).readJson(realWorldBaselineRequestsRelativePath);
    requireExactKeys(
      baselineDocument,
      <String>{'schemaVersion', 'sourceTag', 'sourceCommit', 'cases'},
    );
    if (requireString(baselineDocument, 'schemaVersion') !=
            'liuyao-real-case-baseline-requests/1.0.0' ||
        requireString(baselineDocument, 'sourceTag') != 'v1.6.0' ||
        requireString(baselineDocument, 'sourceCommit') !=
            'e97d94b54b7ac02edcca00b6ab08b8835fad8090') {
      throw const FormatException('Frozen v1.6.0 request identity mismatch.');
    }
    final Map<String, Map<String, Object?>> baselineByScenario =
        <String, Map<String, Object?>>{};
    for (final Object? raw in requireList(baselineDocument, 'cases')) {
      final Map<String, Object?> item = (raw as Map).cast<String, Object?>();
      requireExactKeys(
        item,
        <String>{
          'scenario',
          'question',
          'systemPrompt',
          'userPrompt',
          'projection',
          'metadata',
        },
      );
      final String scenario = requireString(item, 'scenario');
      if (requireString(item, 'question') != fixture.question ||
          baselineByScenario.containsKey(scenario)) {
        throw const FormatException('Frozen baseline scenario mismatch.');
      }
      baselineByScenario[scenario] = item;
    }

    final LiuYaoResult base = await LiuYaoSystem().castByManualYaoNumbers(
      fixture.numbers,
      castTime: fixture.castTime,
    );
    _validateCalendar(base, fixture.expectedCalendar);
    final List<Map<String, Object?>> cases = <Map<String, Object?>>[];
    for (final RealWorldScenario scenario in fixture.scenarios) {
      final LiuYaoResult result = scenario.selectedPosition == null
          ? base
          : base.copyWith(
              yongShenPosition: scenario.selectedPosition,
              yongShenIsFuShen: scenario.selectedHidden,
            );
      final candidate = await assembler.preview(
        result,
        question: fixture.question,
        systemTemplateContent: BuiltInTemplates.liuYaoSystemPrompt.content,
        analysisTemplateContent: BuiltInTemplates.liuYaoAnalysisPrompt.content,
      );
      final Map<String, Object?> candidateProjection = _projectionOf(candidate);
      final Map<String, Object?> baseline = baselineByScenario[
              scenario.scenarioId] ??
          (throw const FormatException('Missing frozen baseline scenario.'));
      final Map<String, Object?> baselineProjection =
          requireObject(baseline, 'projection');
      _validateNoRetrospective(<String>[
        requireString(baseline, 'systemPrompt'),
        requireString(baseline, 'userPrompt'),
        candidate.systemPrompt,
        candidate.userPrompt,
      ]);
      _validateScenarioProjection(
        scenario.scenarioId,
        baselineProjection,
        candidateProjection,
      );
      cases.add(<String, Object?>{
        'scenarioId': scenario.scenarioId,
        'generationInputHash': sha256Json(fixture.generationInput(scenario)),
        'baseline': _variantDocument(
          variant: realWorldBaselineVariant,
          systemPrompt: requireString(baseline, 'systemPrompt'),
          userPrompt: requireString(baseline, 'userPrompt'),
          projection: baselineProjection,
          metadata: requireObject(baseline, 'metadata'),
        ),
        'candidate': _variantDocument(
          variant: realWorldCandidateVariant,
          systemPrompt: candidate.systemPrompt,
          userPrompt: candidate.userPrompt,
          projection: candidateProjection,
          metadata: <String, Object?>{
            'analysisSchemaVersion': candidate.metadata.analysisSchemaVersion,
            'projectionSchemaVersion':
                candidate.metadata.projectionSchemaVersion,
            'ruleSetId': candidate.metadata.ruleSetId,
            'ruleSetVersion': candidate.metadata.ruleSetVersion,
            'sourceCatalogVersion': candidate.metadata.sourceCatalogVersion,
            'promptPolicyVersion': candidate.metadata.promptPolicyVersion,
          },
        ),
      });
    }
    final Map<String, Object?> document = <String, Object?>{
      'schemaVersion': realWorldAdapterSchemaVersion,
      'generationFixtureHash': fixture.hash,
      'baselineSourceCommit': 'e97d94b54b7ac02edcca00b6ab08b8835fad8090',
      'requestParameters': const GenerationRequestParameters().toJson(),
      'cases': cases,
    };
    final RealWorldEvalAdapter adapter = RealWorldEvalAdapter.fromJson(
      document,
      fixture: fixture,
    );
    return RealWorldProductionAssets(
      document: (normalizeJson(document)! as Map).cast<String, Object?>(),
      fixture: fixture,
      adapter: adapter,
    );
  }

  Map<String, Object?> _variantDocument({
    required String variant,
    required String systemPrompt,
    required String userPrompt,
    required Map<String, Object?> projection,
    required Map<String, Object?> metadata,
  }) {
    final Map<String, Object?> identity = <String, Object?>{
      'variant': variant,
      'systemPrompt': systemPrompt,
      'userPrompt': userPrompt,
      'projection': projection,
      'metadata': metadata,
    };
    return <String, Object?>{
      'systemPrompt': systemPrompt,
      'userPrompt': userPrompt,
      'projection': projection,
      'metadata': metadata,
      'requestHash': sha256Json(identity),
    };
  }

  Map<String, Object?> _projectionOf(AssembledPrompt prompt) {
    final section = prompt.structuredOutput.sections.singleWhere(
      (item) => item.key == 'analysis',
    );
    final Object? raw = section.metadata?['projection'];
    if (raw is! Map) {
      throw const FormatException('Candidate projection is absent.');
    }
    return Map<String, Object?>.from(raw.cast<String, Object?>());
  }

  void _validateCalendar(
    LiuYaoResult result,
    Map<String, Object?> expected,
  ) {
    if (result.lunarInfo.yearGanZhi != expected['yearGanZhi'] ||
        result.lunarInfo.monthGanZhi != expected['monthGanZhi'] ||
        result.lunarInfo.riGanZhi != expected['dayGanZhi'] ||
        result.lunarInfo.yueJian != expected['monthBranch'] ||
        sha256Json(result.lunarInfo.kongWang) !=
            sha256Json(expected['kongWang'])) {
      throw const FormatException('Real-world calendar witness mismatch.');
    }
  }

  void _validateScenarioProjection(
    String scenario,
    Map<String, Object?> baseline,
    Map<String, Object?> candidate,
  ) {
    if (baseline['projectionSchemaVersion'] != 1 ||
        candidate['projectionSchemaVersion'] != 2 ||
        baseline['ruleSetVersion'] != 'v2' ||
        candidate['ruleSetVersion'] != 'v3') {
      throw const FormatException('Projection version boundary mismatch.');
    }
    final Map<String, Object?> policy = requireObject(candidate, 'policy');
    if (scenario == 'unselected') {
      if (policy['verdictMode'] != 'abstain' ||
          candidate['lifecycleVerdict'] != null) {
        throw const FormatException('Unselected candidate must abstain.');
      }
      return;
    }
    final Map<String, Object?> lifecycle = requireObject(
      candidate,
      'lifecycleVerdict',
    );
    if (policy['verdictMode'] != 'explainLifecycle' ||
        lifecycle['formation'] != 'willForm' ||
        lifecycle['quality'] != 'adverse' ||
        lifecycle['continuity'] != 'unstable' ||
        lifecycle['persistence'] != 'entangled') {
      throw const FormatException('Selected lifecycle contract mismatch.');
    }
  }

  void _validateNoRetrospective(List<String> prompts) {
    const List<String> forbidden = <String>[
      '二房东',
      '黑中介',
      '六个月',
      '三个月',
      '甲午月',
      '跑路',
      '被赶出',
      '三千',
    ];
    if (prompts.any((prompt) => forbidden.any(prompt.contains))) {
      throw const FormatException('Retrospective leaked into generation.');
    }
  }
}
