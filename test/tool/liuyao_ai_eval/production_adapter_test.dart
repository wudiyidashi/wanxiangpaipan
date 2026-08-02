import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wanxiang_paipan/ai/config/ai_config_manager.dart';
import 'package:wanxiang_paipan/ai/output/formatters/liuyao_formatter.dart';
import 'package:wanxiang_paipan/ai/output/structured_output_formatter.dart';
import 'package:wanxiang_paipan/ai/service/prompt_assembler.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/secure/secure_storage.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/shared/lunar_service.dart';

import '../../../tool/liuyao_ai_eval/assets.dart';
import '../../../tool/liuyao_ai_eval/canonical_json.dart';
import '../../../tool/liuyao_ai_eval/canonical_contract.dart';
import '../../../tool/liuyao_ai_eval/constants.dart';
import '../../../tool/liuyao_ai_eval/paired_evaluation.dart';
import '../../../tool/liuyao_ai_eval/production_adapter.dart';
import '../../../tool/liuyao_ai_eval/security.dart';

void main() {
  test('production flow builds the complete canonical v2 assets', () async {
    final AppDatabase database =
        AppDatabase.forTesting(NativeDatabase.memory());
    final StructuredOutputFormatterRegistry registry =
        StructuredOutputFormatterRegistry.instance;
    registry
      ..clear()
      ..register(LiuYaoStructuredFormatter());
    addTearDown(() async {
      registry.clear();
      await database.close();
    });
    final AIConfigManager configManager = AIConfigManager(
      database: database,
      secureStorage: SecureStorage(),
    );
    await configManager.initializeBuiltInTemplates();
    final PromptAssembler promptAssembler = PromptAssembler(
      configManager: configManager,
      formatterRegistry: registry,
    );
    final CanonicalProductionAssets generated =
        await CanonicalProductionAdapterBuilder(
      repositoryRoot: Directory.current.path,
      assembler: promptAssembler,
    ).build();

    expect(generated.fixture.projectionSchemaVersion, '1');
    expect(generated.fixture.cases, hasLength(40));
    expect(
      generated.fixture.cases
          .where((evalCase) => evalCase.caseKind == 'originalBook'),
      hasLength(26),
    );
    expect(
      generated.fixture.cases
          .where((evalCase) => evalCase.caseKind == 'ruleValidation'),
      hasLength(14),
    );
    expect(
      generated.fixture.cases
          .where((evalCase) => evalCase.evaluationSplit == 'holdout'),
      hasLength(6),
    );
    expect(generated.adapter.cases, hasLength(40));
    final Map<String, Object?> sourceFixture = decodeObject(
      File(
        p.join(Directory.current.path, evalClassicsFixtureRelativePath),
      ).readAsStringSync(),
    );
    expect(
      generated.fixture.sourceFixtureVersion,
      sourceFixture['fixtureVersion'],
    );
    expect(generated.fixture.sourceFixtureHash, sha256Json(sourceFixture));
    expect(
      generated.adapter.sourceFixtureHash,
      generated.fixture.sourceFixtureHash,
    );
    for (int index = 0; index < generated.fixture.cases.length; index += 1) {
      final Map<String, Object?> projection = requireObject(
        generated.fixture.cases[index].requestInput,
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
          generated.adapter.cases[index].variants[candidateVariant]!.userPrompt;
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
        adapter: generated.adapter,
        fixture: generated.fixture,
        rubric: EvalAssets(Directory.current.path).loadRubric(),
      ),
      candidate: CanonicalRequestSet.create(
        runId: 'canonical-v2-r1',
        variant: candidateVariant,
        adapter: generated.adapter,
        fixture: generated.fixture,
        rubric: EvalAssets(Directory.current.path).loadRubric(),
      ),
      fixture: generated.fixture,
    );
    const bool updateAssets =
        bool.fromEnvironment('LIUYAO_UPDATE_CANONICAL_ASSETS');
    if (updateAssets) {
      _writeGenerated(
        evalCanonicalFixtureRelativePath,
        generated.fixtureDocument,
      );
      _writeGenerated(
        evalCanonicalAdapterRelativePath,
        generated.adapterDocument,
      );
      print(jsonEncode(<String, String>{
        'canonicalV2FixtureHash': generated.fixture.hash,
        'canonicalV2AdapterHash': generated.adapter.hash,
        'canonicalV2CandidateHash': pair.candidateHash,
      }));
    } else {
      expect(generated.fixture.hash, canonicalV2FixtureHash);
      expect(generated.adapter.hash, canonicalV2AdapterHash);
      expect(pair.candidateHash, canonicalV2CandidateHash);
      final Map<String, Object?> checkedFixture = decodeObject(
        File(
          p.join(Directory.current.path, evalCanonicalFixtureRelativePath),
        ).readAsStringSync(),
      );
      final Map<String, Object?> checkedAdapter = decodeObject(
        File(
          p.join(Directory.current.path, evalCanonicalAdapterRelativePath),
        ).readAsStringSync(),
      );
      expect(
        sha256Json(checkedFixture),
        sha256Json(generated.fixtureDocument),
      );
      expect(
        sha256Json(checkedAdapter),
        sha256Json(generated.adapterDocument),
      );
      final SensitiveDataFilter filter = SensitiveDataFilter();
      expect(
        filter.scanText(canonicalJson(checkedFixture)).isClean,
        isTrue,
      );
      expect(
        filter.scanText(canonicalJson(checkedAdapter)).isClean,
        isTrue,
      );
    }

    final LiuYaoResult unselected = await LiuYaoSystem().cast(
      method: CastMethod.time,
      input: const <String, Object?>{},
      castTime: DateTime(2026, 8, 1, 12),
    ) as LiuYaoResult;
    final AssembledPrompt unselectedPrompt = await promptAssembler.assemble(
      unselected,
      question: '未指定用神时如何分析？',
    );
    final Object? rawProjection = unselectedPrompt.structuredOutput.sections
        .singleWhere((section) => section.key == 'analysis')
        .metadata?['projection'];
    final Map<String, Object?> unselectedProjection =
        (rawProjection! as Map).cast<String, Object?>();
    expect(
      requireObject(unselectedProjection, 'useSpirit')['mode'],
      'unselected',
    );
    expect(unselectedProjection['verdict'], isNull);
    expect(requireList(unselectedProjection, 'conditions'), isEmpty);
    expect(requireList(unselectedProjection, 'timingCandidates'), isEmpty);
    expect(
      unselectedPrompt.systemPrompt,
      endsWith(PromptAssembler.liuYaoImmutablePolicy),
    );
  });
}

void _writeGenerated(String relativePath, Map<String, Object?> document) {
  final File file = File(p.join(Directory.current.path, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(normalizeJson(document))}\n',
    flush: true,
  );
}
