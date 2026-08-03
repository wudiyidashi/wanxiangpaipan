import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/config/ai_config_manager.dart';
import 'package:wanxiang_paipan/ai/output/formatters/liuyao_formatter.dart';
import 'package:wanxiang_paipan/ai/output/structured_output_formatter.dart';
import 'package:wanxiang_paipan/ai/service/prompt_assembler.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/secure/secure_storage.dart';

import '../../../tool/liuyao_ai_eval/canonical_json.dart';
import '../../../tool/liuyao_ai_eval/classics_representative_contract.dart';
import '../../../tool/liuyao_ai_eval/classics_representative_production_adapter.dart';
import '../../../tool/liuyao_ai_eval/constants.dart';
import '../../../tool/liuyao_ai_eval/security.dart';

final _unprojectedTimingVocabulary =
    RegExp(r'出空|出月|填实|冲开|解除合绊|合绊已解|等待|等到|等至|待到|待至|择日|时机|届时');

class _Storage implements SecureStorage {
  @override
  Future<bool> containsKey(String key) async => false;
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll() async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<Map<String, String>> readAll() async => const {};
  @override
  Future<Map<String, String>> readMultiple(List<String> keys) async => const {};
  @override
  Future<void> write(String key, String value) async {}
}

void main() {
  late AppDatabase database;
  late StructuredOutputFormatterRegistry registry;
  late ClassicsRepresentativeProductionAdapterBuilder builder;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    registry = StructuredOutputFormatterRegistry.instance
      ..clear()
      ..register(LiuYaoStructuredFormatter());
    builder = ClassicsRepresentativeProductionAdapterBuilder(
      repositoryRoot: Directory.current.path,
      assembler: PromptAssembler(
        configManager: AIConfigManager(
          database: database,
          secureStorage: _Storage(),
        ),
        formatterRegistry: registry,
      ),
    );
  });

  tearDown(() async {
    registry.clear();
    await database.close();
  });

  test('fixed representative assets contain exactly three calibration cases',
      () {
    final ClassicsRepresentativeAssetLoader loader =
        ClassicsRepresentativeAssetLoader(Directory.current.path);
    final ClassicsRepresentativeGenerationFixture fixture =
        loader.loadGenerationFixture();
    final ClassicsRepresentativeAdapter adapter = loader.loadAdapter(fixture);
    final ClassicsRepresentativeJudgeReferenceManifest referenceManifest =
        loader.loadJudgeReferenceManifest();
    final ClassicsRepresentativeJudgeReference reference =
        loader.loadJudgeReference(
      generationFixture: fixture,
      manifest: referenceManifest,
    );
    final ClassicsRepresentativeFrozenBaseline baseline =
        loader.loadFrozenBaseline(fixture);

    expect(
      fixture.cases.map((item) => item.caseId).toList(),
      classicsRepresentativeCaseIds,
    );
    expect(
      adapter.cases.map((item) => item.caseId).toList(),
      classicsRepresentativeCaseIds,
    );
    expect(
      reference.cases.map((item) => item.caseId).toList(),
      classicsRepresentativeCaseIds,
    );
    expect(referenceManifest.caseIds, classicsRepresentativeCaseIds);
    expect(
      baseline.cases.map((item) => item.caseId).toList(),
      classicsRepresentativeCaseIds,
    );
    expect(
      reference.cases.every((item) => item.evaluationSplit == 'calibration'),
      isTrue,
    );
  });

  test('frozen adapter is rebuilt through current production assembler',
      () async {
    final generated = await builder.build();
    final frozen = SafeArtifactReader(root: Directory.current).readJson(
      classicsRepresentativeAdapterRelativePath,
    );
    expect(sha256Json(generated.document), sha256Json(frozen));
    expect(generated.adapter.cases, hasLength(3));
    for (final item in generated.adapter.cases) {
      expect(
          item.baseline.metadata, containsPair('analysisSchemaVersion', '1'));
      expect(
          item.baseline.metadata, containsPair('projectionSchemaVersion', '1'));
      expect(item.baseline.metadata, containsPair('ruleSetVersion', 'v2'));
      expect(
        item.baseline.metadata,
        containsPair('promptPolicyVersion', 'liuyao-ai-policy/1.0.0'),
      );
      expect(
          item.candidate.metadata, containsPair('analysisSchemaVersion', '2'));
      expect(item.candidate.metadata,
          containsPair('projectionSchemaVersion', '2'));
      expect(item.candidate.metadata, containsPair('ruleSetVersion', 'v3'));
      expect(
        item.candidate.metadata,
        containsPair(
          'promptPolicyVersion',
          candidatePromptPolicyVersion,
        ),
      );
      expect(
        utf8.encode(item.candidate.systemPrompt).length +
            utf8.encode(item.candidate.userPrompt).length,
        lessThanOrEqualTo(generationInputUtf8ByteLimit),
      );
    }
    expect(
      candidatePromptPolicyVersion,
      PromptAssembler.liuYaoPromptPolicyVersion,
    );
    final noTimingCandidate =
        generated.adapter.caseById('liuyao.case.golden.001').candidate;
    expect(noTimingCandidate.projection['conditions'], isEmpty);
    expect(noTimingCandidate.projection['timingCandidates'], isEmpty);
    expect(
      _unprojectedTimingVocabulary.hasMatch(
        noTimingCandidate.systemPrompt + noTimingCandidate.userPrompt,
      ),
      isFalse,
    );
    for (final prompt in <String>[
      noTimingCandidate.systemPrompt,
      noTimingCandidate.userPrompt,
    ]) {
      expect(
        prompt,
        contains(
          '不得把程序未授权的推演、状态或观察写成无条件成立的事项结果，'
          '也不得以确定性结果措辞扩展程序裁决',
        ),
      );
      expect(
        prompt,
        isNot(contains(PromptAssembler.liuYaoTimingObservationAnchor)),
      );
      expect(RegExp(r'必然|必定|保证|一定').hasMatch(prompt), isFalse);
    }
    for (final caseId in <String>[
      'liuyao.case.golden.007',
      'liuyao.case.golden.037',
    ]) {
      final candidate = generated.adapter.caseById(caseId).candidate;
      expect(candidate.projection['timingCandidates'], isNotEmpty);
      expect(
        candidate.systemPrompt,
        isNot(contains(PromptAssembler.liuYaoTimingObservationAnchor)),
      );
      expect(
        candidate.userPrompt,
        contains(PromptAssembler.liuYaoTimingObservationAnchor),
      );
      expect(
        RegExp(
          RegExp.escape(PromptAssembler.liuYaoTimingObservationAnchor),
        ).allMatches(candidate.userPrompt),
        hasLength(1),
      );
      final outputContractStart =
          candidate.userPrompt.lastIndexOf('[LIUYAO_OUTPUT_CONTRACT]');
      final outputContractEnd =
          candidate.userPrompt.lastIndexOf('[/LIUYAO_OUTPUT_CONTRACT]');
      final timingAnchorIndex = candidate.userPrompt.indexOf(
        PromptAssembler.liuYaoTimingObservationAnchor,
      );
      expect(
        RegExp(
          RegExp.escape('[LIUYAO_OUTPUT_CONTRACT]'),
        ).allMatches(candidate.userPrompt),
        hasLength(1),
      );
      expect(
        RegExp(
          RegExp.escape('[/LIUYAO_OUTPUT_CONTRACT]'),
        ).allMatches(candidate.userPrompt),
        hasLength(1),
      );
      expect(outputContractStart, greaterThanOrEqualTo(0));
      expect(outputContractEnd, greaterThan(outputContractStart));
      expect(timingAnchorIndex, greaterThan(outputContractStart));
      expect(timingAnchorIndex, lessThan(outputContractEnd));
      for (final prompt in <String>[
        candidate.systemPrompt,
        candidate.userPrompt,
      ]) {
        expect(
          prompt,
          contains(PromptAssembler.liuYaoUnauthorizedResultBoundary),
        );
        expect(RegExp(r'必然|必定|保证|一定').hasMatch(prompt), isFalse);
      }
    }
  });

  test('representative production files have no full-cohort dependency', () {
    final List<String> productionSources = <String>[
      File(
        'tool/liuyao_ai_eval/classics_representative_contract.dart',
      ).readAsStringSync(),
      File(
        'tool/liuyao_ai_eval/classics_representative_production_adapter.dart',
      ).readAsStringSync(),
      File(
        'tool/liuyao_ai_eval/classics_representative_evaluation.dart',
      ).readAsStringSync(),
    ];
    final List<String> assetTexts = <String>[
      classicsRepresentativeGenerationRelativePath,
      classicsRepresentativeReferenceRelativePath,
      classicsRepresentativeBaselineRelativePath,
      classicsRepresentativeAdapterRelativePath,
    ].map((path) => File(path).readAsStringSync()).toList();
    const List<String> forbiddenDependencies = <String>[
      'classics_cases.v1',
      'canonical_v2_fixture',
      'canonical_v2_adapter',
      'CanonicalRequestSet',
      'HoldoutRevealStore',
      'EvaluationComparator',
    ];
    for (final String text in <String>[...productionSources, ...assetTexts]) {
      expect(
        forbiddenDependencies.where(text.contains),
        isEmpty,
      );
    }
    expect(
      assetTexts.where((text) => text.toLowerCase().contains('holdout')),
      isEmpty,
    );
  });
}
