import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/qimen_system.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_analysis_projection.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_rule_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/qimen_input_ref_resolver.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_rule_catalog.dart';
import 'package:wanxiang_paipan/domain/services/shared/analysis/models/verdict_models.dart';

import 'helpers/qimen_analysis_fixtures.dart';

void main() {
  group('QimenAnalyzer', () {
    test('analyzes the fixed full pan deterministically without persistence',
        () {
      final result = fixedQimenAnalysisResult();
      final first = QimenAnalyzer.analyze(result, ruleSetVersion: 'v1');
      final second = QimenAnalyzer.analyze(result);

      expect(first.toCanonicalJson(), second.toCanonicalJson());
      expect(first.status, QimenAnalysisStatus.complete);
      expect(first.ruleSetVersion, 'v1');
      expect(first.inputResultId, 'qimen-analysis-public-2008-general');
      expect(first.verdict.matchedDecisionRowId, QimenRuleCatalog.decision60);
      expect(first.verdict.judgment.trend, VerdictTrend.buMing);
      expect(
        first.focuses.map((focus) => focus.roleId),
        containsAll(<String>[
          'self',
          'matter',
          'generalDutyStar',
          'generalDutyDoor',
        ]),
      );
      expect(first.facts, isNotEmpty);
      expect(first.trace.first.stage, QimenTraceStage.input);
      expect(
        first.trace.map((step) => step.sequence),
        List<int>.generate(first.trace.length, (index) => index + 1),
      );
      expect(result.toJson(), isNot(contains('analysis')));
    });

    test('report survives a real JSON wire round-trip deeply', () {
      final original = QimenAnalyzer.analyze(fixedQimenAnalysisResult());
      final wire = jsonEncode(original.toJson());
      final decoded = Map<String, dynamic>.from(jsonDecode(wire) as Map);
      final restored = QimenAnalysisReport.fromJson(decoded);

      expect(restored, original);
      expect(restored.toJson(), original.toJson());
      expect(
        () => QimenAnalysisReport.fromJson(<String, dynamic>{
          ...decoded,
          'analysisSchemaVersion': 2,
        }),
        throwsA(isA<QimenAnalysisCompatibilityException>()),
      );
      expect(() => restored.facts.clear(), throwsUnsupportedError);
    });

    test('report decoding rejects unknown rule and source IDs', () {
      final report = QimenAnalyzer.analyze(fixedQimenAnalysisResult());
      final unknownRule = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(report.toJson())) as Map,
      );
      final facts = unknownRule['facts'] as List;
      (facts.first as Map<String, dynamic>)['ruleId'] = 'QMV1-UNKNOWN';
      expect(
        () => QimenAnalysisReport.fromJson(unknownRule),
        throwsFormatException,
      );

      final unknownSource = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(report.toJson())) as Map,
      );
      final sources = unknownSource['sources'] as List;
      (sources.first as Map<String, dynamic>)['sourceId'] = 'QMS-UNKNOWN';
      expect(
        () => QimenAnalysisReport.fromJson(unknownSource),
        throwsFormatException,
      );
    });

    test('report decoding rejects corrupted graph references and identities',
        () {
      final report = QimenAnalyzer.analyze(fixedQimenAnalysisResult());

      void rejects(void Function(Map<String, dynamic>) corrupt) {
        final wire = _deepMap(report.toJson());
        corrupt(wire);
        expect(
          () => QimenAnalysisReport.fromJson(wire),
          throwsFormatException,
        );
      }

      rejects((wire) {
        final fact = Map<String, dynamic>.from(
          (wire['facts'] as List).first as Map,
        );
        final verdict = Map<String, dynamic>.from(wire['verdict'] as Map);
        final conditions = List<dynamic>.from(verdict['conditionLinks'] as List)
          ..add(<String, dynamic>{
            'conditionId': 'QMV1-COND@dangling',
            'sourceFactId': 'QMV1-F-MISSING@fact',
            'ruleId': fact['ruleId'],
            'condition': <String, dynamic>{
              'label': 'dangling',
              'branch': null,
              'reason': 'corruption test',
              'hasRescue': false,
            },
            'releaseTriggerKind': 'conditionRelease',
            'releaseTriggerValue': 'dangling',
            'releaseScale': 'ri',
            'sourceIds': fact['sourceIds'],
          });
        verdict['conditionLinks'] = conditions;
        wire['verdict'] = verdict;
      });
      rejects((wire) {
        final factId =
            ((wire['facts'] as List).first as Map)['occurrenceId'] as String;
        (wire['conflicts'] as List).add(<String, dynamic>{
          'resolutionId': 'QMV1-X-UNRESOLVED@corrupt',
          'policyId': QimenRuleCatalog.conflictUnresolved,
          'contenderOccurrenceIds': <String>[
            factId,
            'QMV1-F-MISSING@fact',
          ],
          'winnerOccurrenceId': null,
          'suppressedOccurrenceIds': const <String>[],
          'reason': 'corruption test',
        });
      });
      rejects((wire) {
        final verdict = Map<String, dynamic>.from(wire['verdict'] as Map);
        verdict['participatingFactIds'] = <String>['QMV1-F-MISSING@fact'];
        wire['verdict'] = verdict;
      });
      rejects((wire) {
        final candidates = wire['yingQiCandidates'] as List;
        final candidate = Map<String, dynamic>.from(candidates.first as Map)
          ..['relatedFactIds'] = <String>['QMV1-F-MISSING@fact'];
        candidates[0] = candidate;
      });
      rejects((wire) {
        final trace = wire['trace'] as List;
        final index = trace.indexWhere(
          (value) =>
              (value as Map)['stage'] == 'fact' &&
              (value)['outputOccurrenceIds'] is List &&
              ((value)['outputOccurrenceIds'] as List).isNotEmpty,
        );
        final step = Map<String, dynamic>.from(trace[index] as Map)
          ..['outputOccurrenceIds'] = <String>['QMV1-F-MISSING@fact'];
        trace[index] = step;
      });
      rejects((wire) {
        final facts = wire['facts'] as List;
        facts.add(_deepMap(Map<String, dynamic>.from(facts.first as Map)));
      });
      rejects((wire) {
        final trace = wire['trace'] as List;
        trace.add(_deepMap(Map<String, dynamic>.from(trace.first as Map)));
      });
      rejects((wire) {
        (wire['sources'] as List).removeAt(0);
      });
      rejects((wire) {
        final sources = wire['sources'] as List;
        final source = Map<String, dynamic>.from(sources.first as Map)
          ..['title'] = '被篡改的已知来源';
        sources[0] = source;
      });
      rejects((wire) {
        ((wire['focuses'] as List).first as Map<String, dynamic>)
            .remove('originPalaceNumber');
      });
      rejects((wire) {
        final verdict = wire['verdict'] as Map<String, dynamic>;
        final judgment = verdict['judgment'] as Map<String, dynamic>;
        final factor =
            (judgment['factors'] as List).first as Map<String, dynamic>;
        factor['rule'] = 'QMV1-UNKNOWN';
      });
      rejects((wire) {
        final verdict = wire['verdict'] as Map<String, dynamic>;
        final judgment = verdict['judgment'] as Map<String, dynamic>;
        final factor =
            (judgment['factors'] as List).first as Map<String, dynamic>;
        factor['source'] = 'QMS-UNKNOWN';
      });
    });

    test('history adapter reanalyzes v1 and diagnoses future schemas', () {
      final persisted = fixedQimenAnalysisPanMap();
      final reopened = QimenAnalyzer.analyzePersisted(
        persisted,
        ruleSetVersion: 'v1',
      );
      expect(reopened.status, QimenAnalysisStatus.complete);
      expect(reopened.inputResultId, persisted['id']);

      final future = QimenAnalyzer.analyzePersisted(<String, dynamic>{
        ...persisted,
        'schemaVersion': 2,
      });
      expect(future.status, QimenAnalysisStatus.unsupportedPanSchema);
      expect(future.facts, isEmpty);
      expect(future.yingQiCandidates, isEmpty);
      expect(future.verdict.matchedDecisionRowId, QimenRuleCatalog.decision00);
      expect(future.diagnostics.single.code, 'QMV1-E-UNSUPPORTED-PAN-SCHEMA');

      final malformed = QimenAnalyzer.analyzePersisted(<String, dynamic>{
        ...persisted,
        'palaces': const <Object>[],
      });
      expect(malformed.status, QimenAnalysisStatus.invalidPanFacts);
      expect(
          malformed.verdict.matchedDecisionRowId, QimenRuleCatalog.decision00);

      final invalidMonth = fixedQimenAnalysisPanMap();
      final context = Map<String, dynamic>.from(
        invalidMonth['temporalContext'] as Map,
      )..['monthGanZhi'] = 'invalid';
      invalidMonth['temporalContext'] = context;
      final diagnosed = QimenAnalyzer.analyzePersisted(invalidMonth);
      expect(diagnosed.status, QimenAnalysisStatus.invalidPanFacts);
      expect(
        diagnosed.diagnostics.map((value) => value.code),
        contains('QMV1-E-INVALID-MONTH-PILLAR'),
      );
    });

    test('real QimenSystem history reopen restores pan then reanalyzes', () {
      final persisted = fixedQimenAnalysisPanMap();
      final reopened = QimenSystem().resultFromJson(persisted) as QimenResult;
      final report = QimenAnalyzer.analyze(reopened, ruleSetVersion: 'v1');

      expect(reopened.toJson(), persisted);
      expect(report.status, QimenAnalysisStatus.complete);
      expect(report.inputResultId, persisted['id']);
      expect(reopened.toJson(), isNot(contains('analysis')));
    });

    test('every report evidence ref resolves to its recorded pan value', () {
      final result = fixedQimenAnalysisResult();
      final report = QimenAnalyzer.analyze(result);
      final refs = <QimenInputRef>[
        ...report.facts.expand((fact) => fact.inputRefs),
        ...report.trace.expand((step) => step.inputRefs),
      ];

      expect(refs, isNotEmpty);
      for (final ref in refs) {
        expect(
          QimenInputRefResolver.matches(result, ref),
          true,
          reason: '${ref.path} recorded ${ref.value}, resolved '
              '${QimenInputRefResolver.resolve(result, ref.path)}',
        );
      }
      expect(
        refs.where((ref) => ref.path.startsWith(r'$.palaces[')).every(
              (ref) => ref.path.contains('[number='),
            ),
        true,
      );
    });

    test('AI projection freezes program ownership and report evidence', () {
      final report = QimenAnalyzer.analyze(fixedQimenAnalysisResult());
      final projection = QimenAnalysisProjection.fromReport(report);
      final restored = QimenAnalysisProjection.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(jsonEncode(projection.toJson())) as Map,
        ),
      );

      expect(restored.calculationOwner, 'program');
      expect(restored.mayRecalculatePan, false);
      expect(restored.mayRecalculateAnalysis, false);
      expect(restored.mayOverrideVerdict, false);
      expect(restored.status, report.status);
      expect(restored.diagnostics, isEmpty);
      expect(restored.verdict.toJson(), report.verdict.toJson());
      expect(restored.facts.map((fact) => fact.toJson()),
          report.facts.map((fact) => fact.toJson()));
      expect(restored.panFieldReferences, isNotEmpty);
      expect(projection.toJson().keys.toSet(),
          QimenAnalysisProjection.topLevelKeys);
      expect(
        (projection.toJson()['policy'] as Map).keys.toSet(),
        QimenAnalysisProjection.policyKeys,
      );
      expect(
        _allKeys(projection.toJson()).intersection(const <String>{
          'score',
          'rating',
          'confidence',
          'weightedTotal',
          'tagCount',
          'recalculatePan',
          'recalculateAnalysis',
          'overrideVerdict',
        }),
        isEmpty,
      );

      final invalidPolicy = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(projection.toJson())) as Map,
      );
      final policy = Map<String, dynamic>.from(invalidPolicy['policy'] as Map)
        ..['mayRecalculatePan'] = true;
      invalidPolicy['policy'] = policy;
      expect(
        () => QimenAnalysisProjection.fromJson(invalidPolicy),
        throwsFormatException,
      );

      for (final invalidValue in <Object?>[null, 'not-an-object']) {
        final nonMapPolicy = _deepMap(projection.toJson())
          ..['policy'] = invalidValue;
        expect(
          () => QimenAnalysisProjection.fromJson(nonMapPolicy),
          throwsFormatException,
          reason: '$invalidValue',
        );
      }

      final additiveField = Map<String, dynamic>.from(projection.toJson())
        ..['rawCastTime'] = 'forbidden';
      expect(
        () => QimenAnalysisProjection.fromJson(additiveField),
        throwsFormatException,
      );

      final unknownRule = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(projection.toJson())) as Map,
      );
      ((unknownRule['facts'] as List).first as Map<String, dynamic>)['ruleId'] =
          'QMV1-UNKNOWN';
      expect(
        () => QimenAnalysisProjection.fromJson(unknownRule),
        throwsFormatException,
      );

      final missingPanReference = _deepMap(projection.toJson());
      (missingPanReference['panFieldReferences'] as List).removeLast();
      expect(
        () => QimenAnalysisProjection.fromJson(missingPanReference),
        throwsFormatException,
      );

      final extraPanReference = _deepMap(projection.toJson());
      (extraPanReference['panFieldReferences'] as List).add(
        <String, dynamic>{'path': r'$.invented', 'value': 'forbidden'},
      );
      expect(
        () => QimenAnalysisProjection.fromJson(extraPanReference),
        throwsFormatException,
      );

      final futureReport = QimenAnalyzer.analyzePersisted(<String, dynamic>{
        ...fixedQimenAnalysisPanMap(),
        'schemaVersion': 2,
      });
      final diagnosticProjection = QimenAnalysisProjection.fromReport(
        futureReport,
      );
      final restoredDiagnostic = QimenAnalysisProjection.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(jsonEncode(diagnosticProjection.toJson())) as Map,
        ),
      );
      expect(
        restoredDiagnostic.status,
        QimenAnalysisStatus.unsupportedPanSchema,
      );
      expect(
        restoredDiagnostic.diagnostics.single.code,
        'QMV1-E-UNSUPPORTED-PAN-SCHEMA',
      );
      expect(
        restoredDiagnostic.panFieldReferences.map((ref) => ref.toJson()),
        <Map<String, dynamic>>[
          <String, dynamic>{
            'path': r'$.id',
            'value': fixedQimenAnalysisPanMap()['id'],
          },
        ],
      );
      expect(
        restoredDiagnostic.panFieldReferences.map((ref) => ref.value),
        isNot(contains(restoredDiagnostic.diagnostics.single.code)),
      );

      final missingIdPan = fixedQimenAnalysisPanMap()..remove('id');
      final missingIdProjection = QimenAnalysisProjection.fromReport(
        QimenAnalyzer.analyzePersisted(missingIdPan),
      );
      expect(missingIdProjection.panFieldReferences, isEmpty);
    });
  });
}

Set<String> _allKeys(dynamic value) {
  final keys = <String>{};
  if (value is Map) {
    for (final entry in value.entries) {
      keys.add(entry.key.toString());
      keys.addAll(_allKeys(entry.value));
    }
  } else if (value is List) {
    for (final entry in value) {
      keys.addAll(_allKeys(entry));
    }
  }
  return keys;
}

Map<String, dynamic> _deepMap(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
