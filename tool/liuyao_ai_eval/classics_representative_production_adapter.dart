import 'package:wanxiang_paipan/ai/service/prompt_assembler.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/gua_calculator.dart';
import 'package:wanxiang_paipan/domain/services/liushen_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/lunar_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

import 'canonical_json.dart';
import 'classics_representative_contract.dart';

typedef _RepresentativeCalendar = ({DateTime castTime, LunarInfo lunarInfo});

class ClassicsRepresentativeProductionAssets {
  const ClassicsRepresentativeProductionAssets({
    required this.document,
    required this.fixture,
    required this.adapter,
  });

  final Map<String, Object?> document;
  final ClassicsRepresentativeGenerationFixture fixture;
  final ClassicsRepresentativeAdapter adapter;
}

class ClassicsRepresentativeProductionAdapterBuilder {
  ClassicsRepresentativeProductionAdapterBuilder({
    required this.repositoryRoot,
    required this.assembler,
  });

  final String repositoryRoot;
  final PromptAssembler assembler;

  Future<ClassicsRepresentativeProductionAssets> build() async {
    final ClassicsRepresentativeAssetLoader loader =
        ClassicsRepresentativeAssetLoader(repositoryRoot);
    final ClassicsRepresentativeGenerationFixture fixture =
        loader.loadGenerationFixture();
    final ClassicsRepresentativeFrozenBaseline frozen =
        loader.loadFrozenBaseline(fixture);
    final Map<String, _RepresentativeCalendar> calendars =
        _buildCalendars(fixture.cases);
    final List<Map<String, Object?>> cases = <Map<String, Object?>>[];

    for (final ClassicsRepresentativeGenerationCase generationCase
        in fixture.cases) {
      final LiuYaoResult result = _buildResult(
        generationCase,
        calendars[generationCase.caseId]!,
      );
      final AssembledPrompt assembled = await assembler.assemble(
        result,
        question: generationCase.question,
      );
      final Map<String, Object?> candidateProjection = _projectionOf(assembled);
      final ClassicsRepresentativeFrozenBaselineCase baseline =
          frozen.caseById(generationCase.caseId);
      final ClassicsRepresentativePromptVariant candidate =
          _candidateVariant(assembled, candidateProjection);
      final ClassicsRepresentativeAdapterCase adapterCase =
          ClassicsRepresentativeAdapterCase.fromJson(<String, Object?>{
        'caseId': generationCase.caseId,
        'generationInputHash': sha256Json(generationCase.generationInput()),
        'baseline': baseline.prompt.toJson(),
        'candidate': candidate.toJson(),
      });
      cases.add(adapterCase.toJson());
    }

    final Map<String, Object?> document = <String, Object?>{
      'schemaVersion': classicsRepresentativeAdapterSchemaVersion,
      'generationFixtureHash': fixture.hash,
      'baselineSourceCommit': classicsRepresentativeBaselineSourceCommit,
      'requestParameters':
          const ClassicsRepresentativeRequestParameters().toJson(),
      'cases': cases,
    };
    final ClassicsRepresentativeAdapter adapter =
        ClassicsRepresentativeAdapter.fromJson(document, fixture: fixture);
    return ClassicsRepresentativeProductionAssets(
      document: (normalizeJson(document)! as Map).cast<String, Object?>(),
      fixture: fixture,
      adapter: adapter,
    );
  }

  LiuYaoResult _buildResult(
    ClassicsRepresentativeGenerationCase generationCase,
    _RepresentativeCalendar calendar,
  ) {
    final mainGua = GuaCalculator.calculateGua(generationCase.numbers);
    final changingGua = GuaCalculator.generateChangingGua(mainGua);
    if (mainGua.name != generationCase.declaredMainGuaName ||
        changingGua?.name != generationCase.declaredChangingGuaName ||
        sha256Json(mainGua.movingYaos.map((item) => item.position).toList()) !=
            sha256Json(generationCase.declaredMovingPositions)) {
      throw const FormatException(
        'Representative generation pan no longer reproduces.',
      );
    }
    final selected = mainGua.yaos[generationCase.useSpiritPosition - 1];
    if (!generationCase.selectedHidden &&
        (selected.branch != generationCase.declaredBranch ||
            selected.liuQin.name != generationCase.declaredLiuQin ||
            selected.wuXing.name != generationCase.declaredWuXing)) {
      throw const FormatException(
        'Representative visible use spirit no longer reproduces.',
      );
    }
    return LiuYaoResult(
      id: generationCase.caseId,
      castTime: calendar.castTime,
      castMethod: CastMethod.manual,
      mainGua: mainGua,
      changingGua: changingGua,
      lunarInfo: calendar.lunarInfo,
      liuShen: LiuShenService.calculateLiuShen(calendar.lunarInfo.riGan),
      yongShenPosition: generationCase.useSpiritPosition,
      yongShenIsFuShen: generationCase.selectedHidden,
    );
  }

  Map<String, _RepresentativeCalendar> _buildCalendars(
    List<ClassicsRepresentativeGenerationCase> cases,
  ) {
    final Map<String, ClassicsRepresentativeGenerationCase> unresolved =
        <String, ClassicsRepresentativeGenerationCase>{
      for (final item in cases) item.caseId: item,
    };
    final Map<String, Set<String>> excludedYearBranches = <String, Set<String>>{
      for (final item in cases)
        item.caseId: <String>{
          ...GuaCalculator.calculateGua(item.numbers)
              .yaos
              .map((yao) => yao.branch),
          item.declaredBranch,
        },
    };
    final Map<String, _RepresentativeCalendar> resolved =
        <String, _RepresentativeCalendar>{};
    DateTime cursor = DateTime.utc(1901, 1, 1, 12);
    final DateTime end = DateTime.utc(1962, 1, 1, 12);
    while (cursor.isBefore(end) && unresolved.isNotEmpty) {
      final LunarInfo lunar = LunarService.getLunarInfo(cursor);
      if (lunar.yearGanZhi.length >= 2) {
        final String yearBranch = lunar.yearGanZhi.substring(1);
        final List<ClassicsRepresentativeGenerationCase> matches =
            unresolved.values
                .where(
                  (item) =>
                      item.monthBranch == lunar.yueJian &&
                      item.dayGanZhi == lunar.riGanZhi &&
                      !excludedYearBranches[item.caseId]!.contains(yearBranch),
                )
                .toList(growable: false);
        for (final item in matches) {
          resolved[item.caseId] = (castTime: cursor, lunarInfo: lunar);
          unresolved.remove(item.caseId);
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    if (unresolved.isNotEmpty) {
      throw FormatException(
        'No representative calendar witness for ${unresolved.keys.join(',')}.',
      );
    }
    return Map<String, _RepresentativeCalendar>.unmodifiable(resolved);
  }

  Map<String, Object?> _projectionOf(AssembledPrompt prompt) {
    final matching = prompt.structuredOutput.sections
        .where((section) => section.key == 'analysis')
        .toList(growable: false);
    if (matching.length != 1) {
      throw const FormatException(
        'Representative candidate needs one analysis projection.',
      );
    }
    final Object? raw = matching.single.metadata?['projection'];
    if (raw is! Map) {
      throw const FormatException(
        'Representative candidate projection is absent.',
      );
    }
    return Map<String, Object?>.from(raw.cast<String, Object?>());
  }

  ClassicsRepresentativePromptVariant _candidateVariant(
    AssembledPrompt prompt,
    Map<String, Object?> projection,
  ) {
    final Map<String, Object?> metadata = <String, Object?>{
      'analysisSchemaVersion': prompt.metadata.analysisSchemaVersion,
      'projectionSchemaVersion': prompt.metadata.projectionSchemaVersion,
      'ruleSetId': prompt.metadata.ruleSetId,
      'ruleSetVersion': prompt.metadata.ruleSetVersion,
      'sourceCatalogVersion': prompt.metadata.sourceCatalogVersion,
      'promptPolicyVersion': prompt.metadata.promptPolicyVersion,
      'systemTemplateId':
          prompt.metadata.systemTemplateId ?? 'builtin_liuyao_system',
      'analysisTemplateId':
          prompt.metadata.analysisTemplateId ?? 'builtin_liuyao_analysis',
    };
    final ClassicsRepresentativePromptVariant unhashed =
        ClassicsRepresentativePromptVariant(
      variant: classicsRepresentativeCandidateVariant,
      systemPrompt: prompt.systemPrompt,
      userPrompt: prompt.userPrompt,
      projection: Map<String, Object?>.unmodifiable(projection),
      metadata: Map<String, Object?>.unmodifiable(metadata),
      requestHash: '',
    );
    return ClassicsRepresentativePromptVariant(
      variant: unhashed.variant,
      systemPrompt: unhashed.systemPrompt,
      userPrompt: unhashed.userPrompt,
      projection: unhashed.projection,
      metadata: unhashed.metadata,
      requestHash: unhashed.calculateHash(),
    );
  }
}
