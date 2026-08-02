import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:wanxiang_paipan/ai/service/prompt_assembler.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/gua_calculator.dart';
import 'package:wanxiang_paipan/domain/services/liushen_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/lunar_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

import '../liuyao_classics/fixture_models.dart';
import '../liuyao_classics/validator.dart';
import 'assets.dart';
import 'canonical_contract.dart';
import 'canonical_json.dart';
import 'constants.dart';
import 'holdout.dart';

typedef _CanonicalCalendar = ({DateTime castTime, LunarInfo lunarInfo});

class CanonicalProductionAssets {
  const CanonicalProductionAssets({
    required this.fixtureDocument,
    required this.adapterDocument,
    required this.fixture,
    required this.adapter,
  });

  final Map<String, Object?> fixtureDocument;
  final Map<String, Object?> adapterDocument;
  final EvalFixture fixture;
  final CanonicalEvalAdapter adapter;
}

class CanonicalProductionAdapterBuilder {
  CanonicalProductionAdapterBuilder({
    required this.repositoryRoot,
    required this.assembler,
    EvalAssets? assets,
  }) : assets = assets ?? EvalAssets(repositoryRoot);

  final String repositoryRoot;
  final PromptAssembler assembler;
  final EvalAssets assets;

  Future<CanonicalProductionAssets> build() async {
    final File classicsFile = File(
      p.join(repositoryRoot, evalClassicsFixtureRelativePath),
    );
    final Map<String, Object?> classicsDocument =
        decodeObject(classicsFile.readAsStringSync());
    final LiuYaoClassicsFixture classics = LiuYaoClassicsFixture.fromJson(
      classicsDocument,
      readMode: LiuYaoClassicsReadMode.evaluationDraft,
    );
    final LiuYaoClassicsValidationResult validation =
        const LiuYaoClassicsValidator().validate(
      classics,
      mode: LiuYaoClassicsValidationMode.evaluationDraft,
    );
    if (!validation.isValid) {
      throw FormatException(
        'Classics source fixture is invalid: ${validation.errors.join('; ')}',
      );
    }
    if (classics.ruleSetId != canonicalRuleSetId ||
        classics.ruleSetVersion != canonicalRuleSetVersion ||
        classics.cases.length != 40) {
      throw const FormatException(
        'Classics source fixture does not match the canonical evaluation.',
      );
    }

    final EvalRubric rubric = assets.loadRubric();
    final FrozenValidation frozen = assets.validateFrozenAssets();
    final String legacySystem =
        frozen.templateContents['builtin_liuyao_system']!;
    final String legacyAnalysis =
        frozen.templateContents['builtin_liuyao_analysis']!;
    final List<Map<String, Object?>> fixtureCases = <Map<String, Object?>>[];
    final List<Map<String, Object?>> adapterCases = <Map<String, Object?>>[];
    final Map<String, _CanonicalCalendar> calendars =
        _buildCanonicalCalendars(classics.cases);

    for (final LiuYaoClassicsCase classicsCase in classics.cases) {
      final LiuYaoResult result = _buildResult(classicsCase, calendars);
      final AssembledPrompt candidate = await assembler.assemble(
        result,
        question: classicsCase.question,
      );
      _validateCandidateMetadata(candidate);
      final Map<String, Object?> projection = _projectionOf(candidate);
      final ScoringReference scoringReference =
          scoringReferenceFromCanonicalProjection(projection);
      final Map<String, Object?> requestInput = <String, Object?>{
        'question': classicsCase.question,
        'projection': projection,
      };
      fixtureCases.add(<String, Object?>{
        'caseId': classicsCase.caseId,
        'caseKind': classicsCase.caseKind,
        'evaluationSplit': classicsCase.evaluationSplit,
        'cohortIds': <String>[
          'overall',
          classicsCase.caseKind,
          classicsCase.evaluationSplit,
        ],
        'requestInput': requestInput,
        'scoringReference': scoringReference.toJson(),
      });

      final AssembledPrompt baselineWithGuard = await assembler.preview(
        result,
        question: classicsCase.question,
        systemTemplateContent: legacySystem,
        analysisTemplateContent: legacyAnalysis,
      );
      final Map<String, Object?> baselineProjection =
          _projectionOf(baselineWithGuard);
      if (sha256Json(baselineProjection) != sha256Json(projection)) {
        throw const FormatException(
          'Baseline and candidate production projections diverged.',
        );
      }
      final String encodedProjection = jsonEncode(projection);
      if (!candidate.userPrompt.contains(encodedProjection) ||
          !baselineWithGuard.userPrompt.contains(encodedProjection)) {
        throw const FormatException(
          'Production prompt omitted the canonical projection.',
        );
      }
      adapterCases.add(<String, Object?>{
        'caseId': classicsCase.caseId,
        'caseInputHash': sha256Json(requestInput),
        'projectionHash': sha256Json(projection),
        'variants': <String, Object?>{
          baselineVariant: <String, Object?>{
            'systemTemplateId': 'builtin_liuyao_system',
            'analysisTemplateId': 'builtin_liuyao_analysis',
            'promptPolicyVersion': 'legacy-frozen',
            'systemPrompt': _removeEvaluatorBaselineGuard(
              baselineWithGuard.systemPrompt,
            ),
            'userPrompt': baselineWithGuard.userPrompt,
          },
          candidateVariant: <String, Object?>{
            'systemTemplateId': candidate.metadata.systemTemplateId,
            'analysisTemplateId': candidate.metadata.analysisTemplateId,
            'promptPolicyVersion': candidate.metadata.promptPolicyVersion,
            'systemPrompt': candidate.systemPrompt,
            'userPrompt': candidate.userPrompt,
          },
        },
      });
    }

    final Map<String, Object?> fixtureDocument = <String, Object?>{
      'schemaVersion': evalFixtureVersion,
      'fixtureVersion': evalFixtureVersion,
      'rubricVersion': evalRubricVersion,
      'projectionSchemaVersion': canonicalProjectionSchemaVersion,
      'requestSchemaVersion': evalRequestSchemaVersion,
      'sourceFixtureVersion': classics.fixtureVersion,
      'sourceFixtureHash': sha256Json(classicsDocument),
      'cases': fixtureCases,
    };
    final EvalFixture fixture = EvalFixture.fromJson(fixtureDocument);
    _validateHoldout(classics, fixture);
    final Map<String, Object?> adapterDocument = <String, Object?>{
      'schemaVersion': evalCanonicalAdapterSchemaVersion,
      'fixtureHash': fixture.hash,
      'rubricHash': rubric.hash,
      'projectionSchemaVersion': canonicalProjectionSchemaVersion,
      'ruleSetId': canonicalRuleSetId,
      'ruleSetVersion': canonicalRuleSetVersion,
      'requestParameters': const GenerationRequestParameters().toJson(),
      'sourceFixtureVersion': classics.fixtureVersion,
      'sourceFixtureHash': sha256Json(classicsDocument),
      'cases': adapterCases,
    };
    final CanonicalEvalAdapter adapter = CanonicalEvalAdapter.fromJson(
      adapterDocument,
      fixture: fixture,
      rubric: rubric,
    );
    return CanonicalProductionAssets(
      fixtureDocument:
          (normalizeJson(fixtureDocument)! as Map).cast<String, Object?>(),
      adapterDocument:
          (normalizeJson(adapterDocument)! as Map).cast<String, Object?>(),
      fixture: fixture,
      adapter: adapter,
    );
  }

  LiuYaoResult _buildResult(
    LiuYaoClassicsCase classicsCase,
    Map<String, _CanonicalCalendar> calendars,
  ) {
    final mainGua = GuaCalculator.calculateGua(classicsCase.pan.numbers);
    final changingGua = GuaCalculator.generateChangingGua(mainGua);
    final _CanonicalCalendar calendar = calendars[classicsCase.caseId]!;
    return LiuYaoResult(
      id: classicsCase.caseId,
      castTime: calendar.castTime,
      castMethod: CastMethod.manual,
      mainGua: mainGua,
      changingGua: changingGua,
      lunarInfo: calendar.lunarInfo,
      liuShen: LiuShenService.calculateLiuShen(calendar.lunarInfo.riGan),
      yongShenPosition: classicsCase.useSpirit.position,
      yongShenIsFuShen: classicsCase.useSpirit.mode == 'selectedHidden',
    );
  }

  Map<String, _CanonicalCalendar> _buildCanonicalCalendars(
    List<LiuYaoClassicsCase> cases,
  ) {
    final Map<String, LiuYaoClassicsCase> unresolved =
        <String, LiuYaoClassicsCase>{
      for (final LiuYaoClassicsCase item in cases) item.caseId: item,
    };
    final Map<String, Set<String>> excludedYearBranches = <String, Set<String>>{
      for (final LiuYaoClassicsCase item in cases)
        item.caseId: <String>{
          ...GuaCalculator.calculateGua(item.pan.numbers)
              .yaos
              .map((yao) => yao.branch),
          item.useSpirit.declaredBranch,
        },
    };
    final Map<String, _CanonicalCalendar> resolved =
        <String, _CanonicalCalendar>{};
    DateTime cursor = DateTime.utc(1901, 1, 1, 12);
    final DateTime end = DateTime.utc(1962, 1, 1, 12);
    while (cursor.isBefore(end) && unresolved.isNotEmpty) {
      final LunarInfo lunar = LunarService.getLunarInfo(cursor);
      if (lunar.yearGanZhi.length >= 2) {
        final String yearBranch = lunar.yearGanZhi.substring(1);
        final List<LiuYaoClassicsCase> matches = unresolved.values
            .where(
              (item) =>
                  item.pan.monthBranch == lunar.yueJian &&
                  item.pan.dayGanZhi == lunar.riGanZhi &&
                  !excludedYearBranches[item.caseId]!.contains(yearBranch),
            )
            .toList(growable: false);
        for (final LiuYaoClassicsCase item in matches) {
          resolved[item.caseId] = (castTime: cursor, lunarInfo: lunar);
          unresolved.remove(item.caseId);
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    if (unresolved.isNotEmpty) {
      final List<String> missing = unresolved.keys.toList()..sort();
      throw FormatException(
        'No internally consistent calendar witness for: ${missing.join(',')}',
      );
    }
    return Map<String, _CanonicalCalendar>.unmodifiable(resolved);
  }

  Map<String, Object?> _projectionOf(AssembledPrompt prompt) {
    final matching = prompt.structuredOutput.sections
        .where((section) => section.key == 'analysis')
        .toList(growable: false);
    if (matching.length != 1) {
      throw const FormatException(
        'Production formatter must emit one analysis section.',
      );
    }
    final Object? raw = matching.single.metadata?['projection'];
    if (raw is! Map) {
      throw const FormatException(
        'Production formatter did not emit a canonical projection.',
      );
    }
    return Map<String, Object?>.from(raw.cast<String, Object?>());
  }

  void _validateCandidateMetadata(AssembledPrompt prompt) {
    if (prompt.metadata.systemTemplateId != 'builtin_liuyao_system' ||
        prompt.metadata.analysisTemplateId != 'builtin_liuyao_analysis' ||
        prompt.metadata.projectionSchemaVersion !=
            canonicalProjectionSchemaVersion ||
        prompt.metadata.ruleSetId != canonicalRuleSetId ||
        prompt.metadata.ruleSetVersion != canonicalRuleSetVersion ||
        prompt.metadata.promptPolicyVersion !=
            PromptAssembler.liuYaoPromptPolicyVersion ||
        !prompt.systemPrompt.endsWith(PromptAssembler.liuYaoImmutablePolicy) ||
        RegExp(r'\[LIUYAO_IMMUTABLE_POLICY ')
                .allMatches(prompt.systemPrompt)
                .length !=
            1) {
      throw const FormatException(
        'Production candidate assembly metadata or guard is invalid.',
      );
    }
  }

  String _removeEvaluatorBaselineGuard(String systemPrompt) {
    final String suffix = '\n\n${PromptAssembler.liuYaoImmutablePolicy}';
    if (!systemPrompt.endsWith(suffix) ||
        RegExp(r'\[LIUYAO_IMMUTABLE_POLICY ').allMatches(systemPrompt).length !=
            1) {
      throw const FormatException(
        'Evaluator baseline guard bypass did not match the production guard.',
      );
    }
    final String result =
        systemPrompt.substring(0, systemPrompt.length - suffix.length);
    if (result.contains('[LIUYAO_IMMUTABLE_POLICY ')) {
      throw const FormatException('Evaluator baseline retained a guard.');
    }
    return result;
  }

  void _validateHoldout(
    LiuYaoClassicsFixture classics,
    EvalFixture fixture,
  ) {
    final HoldoutSelection selected = selectHoldout(
      fixture.cases
          .where((evalCase) => evalCase.caseKind == 'originalBook')
          .map((evalCase) => evalCase.caseId),
    );
    final Set<String> actual = fixture.cases
        .where((evalCase) => evalCase.evaluationSplit == 'holdout')
        .map((evalCase) => evalCase.caseId)
        .toSet();
    final Set<String> expected =
        selected.members.map((member) => member.caseId).toSet();
    if (actual.length != expected.length ||
        !actual.containsAll(expected) ||
        selected.cohortHash != classics.holdoutCohortHash) {
      throw const FormatException(
        'Canonical evaluation holdout does not match the classics source.',
      );
    }
  }
}
