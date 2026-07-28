import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

void main() {
  group('DlrRuleRef', () {
    test('classic B 级规则带 C00 source 时可 round-trip', () {
      final ref = DlrRuleRef(
        ruleId: 'dlr.rule.kejing.002',
        ruleSetVersion: 'daliuren-kejing/1.0.0',
        kind: DlrRuleKind.classic,
        evidenceLevel: DlrEvidenceLevel.b,
        sourceIds: const <String>['dlr.source.siku-liuren-daquan'],
      );

      expect(DlrRuleRef.fromJson(ref.toJson()), ref);
      expect(ref.sourceIds, isNot(isEmpty));
      expect(ref.executableApproved, isFalse);
      expect(ref.isExecutable, isFalse);
    });

    test('只有 C00 当前明确批准的 classic 规则可标为 executable', () {
      final approved = DlrRuleRef(
        ruleId: DlrClassicExecutableRuleIds.heavenPlateRotation,
        ruleSetVersion: DlrRuleSetVersions.panCurrent,
        kind: DlrRuleKind.classic,
        evidenceLevel: DlrEvidenceLevel.b,
        sourceIds: const <String>['dlr.source.daliuren-zhinan-scan'],
        executableApproved: true,
      );

      expect(approved.executableApproved, isTrue);
      expect(approved.isExecutable, isTrue);
      expect(DlrRuleRef.fromJson(approved.toJson()), approved);

      expect(
        () => DlrRuleRef(
          ruleId: 'dlr.rule.pan.001.month-general-by-zhongqi',
          ruleSetVersion: DlrRuleSetVersions.panCurrent,
          kind: DlrRuleKind.classic,
          evidenceLevel: DlrEvidenceLevel.b,
          sourceIds: const <String>['dlr.source.siku-liuren-daquan'],
          executableApproved: true,
        ),
        throwsArgumentError,
        reason: 'C00 adopted/B 不等于 executableApproved',
      );
      expect(
        () => DlrRuleRef(
          ruleId: 'dlr.rule.class-spirit.001.general',
          ruleSetVersion: DlrRuleSetVersions.analysisCurrent,
          kind: DlrRuleKind.classic,
          evidenceLevel: DlrEvidenceLevel.d,
          executableApproved: true,
        ),
        throwsArgumentError,
      );
    });

    test('classic executable allowlist 与 C00 manifest 全部规则文件同步', () {
      final catalogRoot = Directory('assets/data/daliuren/classics');
      final manifest = jsonDecode(
        File('${catalogRoot.path}/manifest.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final ruleFiles = (manifest['ruleFiles'] as List<dynamic>).cast<String>();
      final approvedRuleIds = <String>{};

      for (final relativePath in ruleFiles) {
        final document = jsonDecode(
          File('${catalogRoot.path}/$relativePath').readAsStringSync(),
        ) as Map<String, dynamic>;
        for (final rawEntry in document['entries'] as List<dynamic>) {
          final entry = rawEntry as Map<String, dynamic>;
          if (entry['executableApproved'] == true) {
            approvedRuleIds.add(entry['ruleId'] as String);
          }
        }
      }

      expect(
        DlrClassicExecutableRuleIds.all,
        unorderedEquals(approvedRuleIds),
      );
    });

    test('project helper 固定 project/D 与 current analysis version', () {
      final ref = DlrRuleRef.project(
        DlrProjectRuleIds.transmissionReturnsToGenerateSelf,
      );

      expect(ref.kind, DlrRuleKind.project);
      expect(ref.evidenceLevel, DlrEvidenceLevel.d);
      expect(ref.ruleSetVersion, DlrRuleSetVersions.analysisCurrent);
      expect(ref.sourceIds, isEmpty);
      expect(ref.executableApproved, isFalse);
      expect(ref.isExecutable, isTrue);
    });

    test('project pan 规则使用独立命名域与 pan version', () {
      final ref = DlrRuleRef.project(
        'dlr.project.pan.calendar.month-general-baseline',
        ruleSetVersion: DlrRuleSetVersions.panCurrent,
      );

      expect(ref.kind, DlrRuleKind.project);
      expect(ref.ruleSetVersion, DlrRuleSetVersions.panCurrent);
      expect(ref.isExecutable, isTrue);
    });

    test('拒绝规则 kind 与稳定命名域不匹配', () {
      expect(
        () => DlrRuleRef(
          ruleId: 'dlr.rule.kejing.002',
          ruleSetVersion: 'v1',
          kind: DlrRuleKind.project,
          evidenceLevel: DlrEvidenceLevel.d,
        ),
        throwsArgumentError,
      );
      expect(
        () => DlrRuleRef(
          ruleId: 'dlr.project.foo',
          ruleSetVersion: 'v1',
          kind: DlrRuleKind.project,
          evidenceLevel: DlrEvidenceLevel.d,
        ),
        throwsArgumentError,
      );
    });

    test('拒绝空规则版本', () {
      expect(
        () => DlrRuleRef(
          ruleId: 'dlr.project.analysis.test.rule',
          ruleSetVersion: '   ',
          kind: DlrRuleKind.project,
          evidenceLevel: DlrEvidenceLevel.d,
        ),
        throwsArgumentError,
      );
      expect(
        () => DlrRuleRef(
          ruleId: 'dlr.project.analysis.test.rule',
          ruleSetVersion: ' ${DlrRuleSetVersions.analysisCurrent}',
          kind: DlrRuleKind.project,
          evidenceLevel: DlrEvidenceLevel.d,
        ),
        throwsArgumentError,
      );
    });

    test('拒绝 classic A/B 无 source ID', () {
      for (final level in <DlrEvidenceLevel>[
        DlrEvidenceLevel.a,
        DlrEvidenceLevel.b,
      ]) {
        expect(
          () => DlrRuleRef(
            ruleId: 'dlr.rule.kejing.002',
            ruleSetVersion: 'daliuren-kejing/1.0.0',
            kind: DlrRuleKind.classic,
            evidenceLevel: level,
          ),
          throwsArgumentError,
        );
      }
    });

    test('拒绝 project 冒充 classic evidence 或挂古籍 source', () {
      expect(
        () => DlrRuleRef(
          ruleId: 'dlr.project.analysis.test.rule',
          ruleSetVersion: 'v1',
          kind: DlrRuleKind.project,
          evidenceLevel: DlrEvidenceLevel.b,
        ),
        throwsArgumentError,
      );
      expect(
        () => DlrRuleRef(
          ruleId: 'dlr.project.analysis.test.rule',
          ruleSetVersion: 'v1',
          kind: DlrRuleKind.project,
          evidenceLevel: DlrEvidenceLevel.d,
          sourceIds: const <String>['dlr.source.siku-liuren-daquan'],
        ),
        throwsArgumentError,
      );
      expect(
        () => DlrRuleRef(
          ruleId: 'dlr.project.analysis.test.rule',
          ruleSetVersion: 'v1',
          kind: DlrRuleKind.project,
          evidenceLevel: DlrEvidenceLevel.d,
          executableApproved: true,
        ),
        throwsArgumentError,
      );
    });

    test('fromJson 对错误字段类型统一抛 ArgumentError', () {
      final valid = DlrRuleRef.project(
        DlrProjectRuleIds.progressiveGeneration,
      ).toJson();

      for (final override in <Map<String, dynamic>>[
        <String, dynamic>{'ruleId': 1},
        <String, dynamic>{'ruleSetVersion': 1},
        <String, dynamic>{'sourceIds': 'not-a-list'},
        <String, dynamic>{
          'sourceIds': <dynamic>[1]
        },
        <String, dynamic>{'executableApproved': 'true'},
      ]) {
        expect(
          () => DlrRuleRef.fromJson(<String, dynamic>{...valid, ...override}),
          throwsArgumentError,
          reason: 'override=$override',
        );
      }
    });
  });

  group('DlrRuleSetVersions', () {
    test('盘面版本必须精确匹配 current，首尾空白不得被静默归一化', () {
      final snapshot = DlrCastInputSnapshot.capture(
        castMethod: CastMethod.time,
        castTime: DateTime.utc(2026, 7, 28),
        utcOffsetMinutes: 0,
        normalizedInput: const <String, dynamic>{
          'params': <String, dynamic>{},
        },
        replayStatus: DlrReplayStatus.complete,
      );

      expect(
        DlrRuleSetVersions.resolveAnalysisCompatibility(
          sourcePanRuleSetVersion: ' ${DlrRuleSetVersions.panCurrent}',
          castInputSnapshot: snapshot,
        ),
        DlrAnalysisCompatibility.versionMismatch,
      );
    });
  });

  group('DlrCastInputSnapshot', () {
    test('公开构造同样执行深复制与 replay 状态校验', () {
      final nested = <String, dynamic>{
        'params': <String, dynamic>{
          'options': <dynamic>[
            <String, dynamic>{'enabled': true},
          ],
        },
      };
      final snapshot = DlrCastInputSnapshot(
        castMethod: CastMethod.time,
        castTime: DateTime.utc(2026, 7, 28),
        utcOffsetMinutes: 0,
        normalizedInput: nested,
        replayStatus: DlrReplayStatus.complete,
      );

      final params = nested['params'] as Map<String, dynamic>;
      final options = params['options'] as List<dynamic>;
      (options.first as Map<String, dynamic>)['enabled'] = false;

      final savedParams =
          snapshot.normalizedInput['params'] as Map<String, dynamic>;
      final savedOptions = savedParams['options'] as List<dynamic>;
      expect((savedOptions.first as Map<String, dynamic>)['enabled'], true);
      expect(
        () => (savedOptions.first as Map<String, dynamic>)['enabled'] = false,
        throwsUnsupportedError,
      );
      expect(
        () => DlrCastInputSnapshot(
          castMethod: CastMethod.computer,
          castTime: DateTime.utc(2026, 7, 28),
          utcOffsetMinutes: 0,
          normalizedInput: const <String, dynamic>{},
          replayStatus: DlrReplayStatus.incomplete,
        ),
        throwsArgumentError,
      );
    });

    test('capture 对嵌套 JSON-safe 输入做深复制', () {
      final nestedParams = <String, dynamic>{
        'mode': 'auto',
        'options': <dynamic>[
          <String, dynamic>{'enabled': true},
        ],
      };
      final normalized = <String, dynamic>{'params': nestedParams};
      final snapshot = DlrCastInputSnapshot.capture(
        castMethod: CastMethod.time,
        castTime: DateTime.utc(2026, 7, 28, 1, 2, 3),
        utcOffsetMinutes: 0,
        normalizedInput: normalized,
        replayStatus: DlrReplayStatus.complete,
      );

      nestedParams['mode'] = 'manual';
      (nestedParams['options'] as List<dynamic>).first['enabled'] = false;
      normalized['extra'] = 'later';

      final savedParams =
          snapshot.normalizedInput['params'] as Map<String, dynamic>;
      final savedOptions = savedParams['options'] as List<dynamic>;
      expect(savedParams['mode'], 'auto');
      expect((savedOptions.first as Map<String, dynamic>)['enabled'], true);
      expect(snapshot.normalizedInput, isNot(contains('extra')));
    });

    test('capture 拒绝 DateTime、非字符串 map key 与非有限数字', () {
      for (final invalid in <Map<String, dynamic>>[
        <String, dynamic>{'value': DateTime(2026)},
        <String, dynamic>{
          'value': <Object, Object>{1: 'not-string-key'}
        },
        <String, dynamic>{'value': double.nan},
      ]) {
        expect(
          () => DlrCastInputSnapshot.capture(
            castMethod: CastMethod.time,
            castTime: DateTime.utc(2026),
            utcOffsetMinutes: 0,
            normalizedInput: invalid,
            replayStatus: DlrReplayStatus.complete,
          ),
          throwsArgumentError,
        );
      }
    });

    test('JSON round-trip 保留显式 UTC offset，不从 DateTime 重算', () {
      final snapshot = DlrCastInputSnapshot.capture(
        castMethod: CastMethod.time,
        castTime: DateTime(2026, 7, 28, 9),
        utcOffsetMinutes: 480,
        normalizedInput: const <String, dynamic>{'params': <String, dynamic>{}},
        replayStatus: DlrReplayStatus.complete,
      );

      final decoded = DlrCastInputSnapshot.fromJson(snapshot.toJson());
      expect(decoded.utcOffsetMinutes, 480);
      expect(decoded.castTime, snapshot.castTime);
    });

    test('fromJson 拒绝非法 schema、replay 组合与非 JSON-safe 输入', () {
      final validJson = <String, dynamic>{
        'schemaVersion': DlrRuleSetVersions.castInputSchema,
        'castMethod': CastMethod.time.name,
        'castTime': DateTime.utc(2026, 7, 28).toIso8601String(),
        'utcOffsetMinutes': 0,
        'normalizedInput': <String, dynamic>{
          'params': <String, dynamic>{},
        },
        'replayStatus': DlrReplayStatus.complete.name,
        'missingFields': <String>[],
      };

      expect(
        () => DlrCastInputSnapshot.fromJson(
          <String, dynamic>{...validJson, 'schemaVersion': '   '},
        ),
        throwsArgumentError,
      );
      expect(
        () => DlrCastInputSnapshot.fromJson(
          <String, dynamic>{
            ...validJson,
            'missingFields': <String>['randomSeed'],
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => DlrCastInputSnapshot.fromJson(
          <String, dynamic>{
            ...validJson,
            'replayStatus': DlrReplayStatus.incomplete.name,
          },
        ),
        throwsArgumentError,
      );

      for (final invalid in <Object?>[
        DateTime.utc(2026, 7, 28),
        double.infinity,
        <Object, Object>{1: 'not-string-key'},
      ]) {
        expect(
          () => DlrCastInputSnapshot.fromJson(
            <String, dynamic>{
              ...validJson,
              'normalizedInput': <String, dynamic>{'value': invalid},
            },
          ),
          throwsArgumentError,
        );
      }
    });

    test('fromJson 拒绝非法顶层 JSON shape 与枚举值', () {
      final validJson = <String, dynamic>{
        'schemaVersion': DlrRuleSetVersions.castInputSchema,
        'castMethod': CastMethod.reportNumber.name,
        'castTime': DateTime.utc(2026, 7, 28).toIso8601String(),
        'utcOffsetMinutes': 0,
        'normalizedInput': <String, dynamic>{
          'number': 12,
          'params': <String, dynamic>{},
        },
        'replayStatus': DlrReplayStatus.complete.name,
        'missingFields': <String>[],
      };

      for (final override in <Map<String, dynamic>>[
        <String, dynamic>{'schemaVersion': 1},
        <String, dynamic>{'castMethod': 'unknown'},
        <String, dynamic>{'castMethod': CastMethod.coin.name},
        <String, dynamic>{'castTime': 20260728},
        <String, dynamic>{'castTime': 'not-a-date'},
        <String, dynamic>{'utcOffsetMinutes': 0.5},
        <String, dynamic>{'normalizedInput': <dynamic>[]},
        <String, dynamic>{'replayStatus': 'unknown'},
        <String, dynamic>{'missingFields': 'randomSeed'},
        <String, dynamic>{
          'missingFields': <dynamic>[1]
        },
      ]) {
        expect(
          () => DlrCastInputSnapshot.fromJson(
            <String, dynamic>{...validJson, ...override},
          ),
          throwsArgumentError,
          reason: 'override=$override',
        );
      }
    });

    test('copyWith 不能绕过深复制或 replay 状态校验', () {
      final snapshot = DlrCastInputSnapshot.capture(
        castMethod: CastMethod.time,
        castTime: DateTime.utc(2026, 7, 28),
        utcOffsetMinutes: 0,
        normalizedInput: const <String, dynamic>{
          'params': <String, dynamic>{},
        },
        replayStatus: DlrReplayStatus.complete,
      );
      final replacement = <String, dynamic>{
        'params': <String, dynamic>{'mode': 'auto'},
      };
      final copied = snapshot.copyWith(normalizedInput: replacement);
      (replacement['params'] as Map<String, dynamic>)['mode'] = 'manual';

      expect(
        (copied.normalizedInput['params'] as Map<String, dynamic>)['mode'],
        'auto',
      );
      expect(
        () => snapshot.copyWith(replayStatus: DlrReplayStatus.incomplete),
        throwsArgumentError,
      );
    });
  });
}
