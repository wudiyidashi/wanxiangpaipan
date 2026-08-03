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
import '../../../tool/liuyao_ai_eval/constants.dart';
import '../../../tool/liuyao_ai_eval/real_world_contract.dart';
import '../../../tool/liuyao_ai_eval/real_world_production_adapter.dart';
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
  late RealWorldProductionAdapterBuilder builder;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    registry = StructuredOutputFormatterRegistry.instance
      ..clear()
      ..register(LiuYaoStructuredFormatter());
    builder = RealWorldProductionAdapterBuilder(
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

  test('frozen v1.6.0 and current v3 adapter match production assembly',
      () async {
    final generated = await builder.build();
    final frozen = SafeArtifactReader(root: Directory.current).readJson(
      realWorldAdapterRelativePath,
    );
    expect(sha256Json(generated.document), sha256Json(frozen));
    expect(generated.adapter.cases, hasLength(2));
    expect(
      generated.adapter
          .scenario('unselected')
          .candidate
          .metadata['projectionSchemaVersion'],
      '2',
    );
    expect(
      generated.adapter
          .scenario('unselected')
          .candidate
          .metadata['promptPolicyVersion'],
      candidatePromptPolicyVersion,
    );
    expect(
      candidatePromptPolicyVersion,
      PromptAssembler.liuYaoPromptPolicyVersion,
    );
    for (final item in generated.adapter.cases) {
      final candidate = item.candidate;
      expect(
        utf8.encode(candidate.systemPrompt + candidate.userPrompt).length,
        lessThanOrEqualTo(70 * 1024),
        reason: '${item.scenarioId} candidate request must stay within the '
            'locally verified model input envelope',
      );
      expect(
        candidate.userPrompt,
        contains('"aiProjectionSchemaVersion":1'),
      );
      expect(
        candidate.systemPrompt,
        isNot(contains(PromptAssembler.liuYaoTimingObservationAnchor)),
      );
      expect(
        candidate.userPrompt,
        isNot(contains(PromptAssembler.liuYaoTimingObservationAnchor)),
      );
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
      expect(
        _unprojectedTimingVocabulary.hasMatch(
          candidate.systemPrompt + candidate.userPrompt,
        ),
        isFalse,
        reason: '${item.scenarioId} must not inject unprojected timing terms',
      );
    }
    expect(
      generated.adapter
          .scenario('selected-main-1')
          .baseline
          .metadata['projectionSchemaVersion'],
      '1',
    );
    final selectedCandidate =
        generated.adapter.scenario('selected-main-1').candidate;
    final unselectedCandidate =
        generated.adapter.scenario('unselected').candidate;
    expect(
      RegExp(
        RegExp.escape(PromptAssembler.liuYaoCurrentStateAnchor),
      ).allMatches(selectedCandidate.userPrompt),
      hasLength(1),
    );
    expect(
      selectedCandidate.systemPrompt,
      isNot(contains(PromptAssembler.liuYaoCurrentStateAnchor)),
    );
    expect(
      unselectedCandidate.systemPrompt + unselectedCandidate.userPrompt,
      isNot(contains(PromptAssembler.liuYaoCurrentStateAnchor)),
    );
    final selectedLifecycle = requireObject(
      selectedCandidate.projection,
      'lifecycleVerdict',
    );
    expect(selectedLifecycle, containsPair('formation', 'willForm'));
    expect(selectedLifecycle, containsPair('quality', 'adverse'));
    expect(selectedLifecycle, containsPair('continuity', 'unstable'));
    expect(selectedLifecycle, containsPair('persistence', 'entangled'));
    expect(selectedLifecycle, containsPair('headlineCode', 'formsButAdverse'));
    for (final prompt in <String>[
      selectedCandidate.systemPrompt,
      selectedCandidate.userPrompt,
    ]) {
      expect(
        prompt,
        contains('只写当前盘面事实与程序已授权裁决'),
      );
      expect(prompt, contains('不得复述 compact view 已省略的关系'));
      expect(prompt, isNot(contains('日冲已解除合绊')));
      expect(prompt, isNot(contains('合绊=true')));
      expect(prompt, isNot(contains('冲开=true')));
      expect(prompt, isNot(contains('全文必须且只能出现一次')));
      expect(prompt, isNot(contains('该句独占一行')));
      expect(prompt, isNot(contains('禁止解释或复述')));
      expect(
        prompt,
        contains(
          '不得把程序未授权的推演、状态或观察写成无条件成立的事项结果，'
          '也不得以确定性结果措辞扩展程序裁决',
        ),
      );
      expect(RegExp(r'必然|必定|保证|一定').hasMatch(prompt), isFalse);
    }
  });

  test('no-timing production prompts omit the legacy timing summary', () async {
    final generated = await builder.build();

    for (final item in generated.adapter.cases) {
      final prompt = item.candidate.systemPrompt + item.candidate.userPrompt;
      for (final timingSummaryTerm in const <String>[
        '应期候选',
        '触发窗口',
        '优先观察',
      ]) {
        expect(
          prompt,
          isNot(contains(timingSummaryTerm)),
          reason:
              '${item.scenarioId} must not expose a withheld timing summary',
        );
      }
    }

    final selected = generated.adapter.scenario('selected-main-1').candidate;
    final verdict = requireObject(selected.projection, 'verdict');
    expect(requireString(verdict, 'summary'), contains('应期候选'));
    expect(requireString(verdict, 'summary'), contains('触发窗口'));
  });

  test('generation adapter has no dependency on judge-only reference', () {
    final source = File(
      'tool/liuyao_ai_eval/real_world_production_adapter.dart',
    ).readAsStringSync();
    expect(source, isNot(contains(realWorldJudgeReferenceRelativePath)));
    expect(source, isNot(contains('actualOutcome')));
    expect(source, isNot(contains('retrospectiveMappings')));
  });

  test('adapter rejects the same non-canonical rule-set id on both variants',
      () {
    final loader = RealWorldAssetLoader(Directory.current.path);
    final fixture = loader.loadGenerationFixture();
    final source = SafeArtifactReader(root: Directory.current).readJson(
      realWorldAdapterRelativePath,
    );
    final mutated =
        (jsonDecode(jsonEncode(source)) as Map).cast<String, Object?>();
    final cases = (mutated['cases']! as List).cast<Object?>();
    final firstCase = (cases.first as Map).cast<String, Object?>();
    for (final variantKey in <String>['baseline', 'candidate']) {
      final variant = (firstCase[variantKey]! as Map).cast<String, Object?>();
      final metadata = (variant['metadata']! as Map).cast<String, Object?>();
      metadata['ruleSetId'] = 'tampered-rule-set';
    }

    expect(
      () => RealWorldEvalAdapter.fromJson(mutated, fixture: fixture),
      throwsFormatException,
    );
  });

  test('frozen generation prompts contain no hindsight-only precise fact', () {
    final fixture = RealWorldAssetLoader(
      Directory.current.path,
    ).loadGenerationFixture();
    final adapter = RealWorldAssetLoader(
      Directory.current.path,
    ).loadAdapter(fixture);
    const forbidden = <String>[
      '二房东',
      '黑中介',
      '六个月',
      '三个月',
      '甲午月',
      '跑路',
      '被赶出',
      '三千',
    ];
    for (final item in adapter.cases) {
      for (final prompt in <String>[
        item.baseline.systemPrompt,
        item.baseline.userPrompt,
        item.candidate.systemPrompt,
        item.candidate.userPrompt,
      ]) {
        expect(forbidden.where(prompt.contains), isEmpty);
      }
    }
  });
}
