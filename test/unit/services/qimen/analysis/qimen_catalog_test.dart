import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/models/qimen_rule_models.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_rule_catalog.dart';
import 'package:wanxiang_paipan/domain/services/qimen/analysis/rules/qimen_source_catalog.dart';

import 'helpers/qimen_stem_response_expectations.dart';

void main() {
  group('Qimen v1 catalogs', () {
    test('have unique, sourced, internally valid stable IDs', () {
      expect(QimenRuleCatalog.validate, returnsNormally);
      expect(QimenSourceCatalog.validate, returnsNormally);
      expect(QimenRuleCatalog.byId, hasLength(QimenRuleCatalog.all.length));
      expect(QimenSourceCatalog.byId, hasLength(QimenSourceCatalog.all.length));
      expect(QimenRuleCatalog.resolve('current').version, 'v1');
      expect(
          QimenRuleCatalog.resolve('v1').ruleSetId, QimenRuleCatalog.ruleSetId);
      expect(() => QimenRuleCatalog.resolve('v2'), throwsArgumentError);
    });

    test('the stem-response table covers all 81 QiYi pairs once', () {
      final rules = <String>{
        for (final heaven in expectedStemResponseOrder)
          for (final earth in expectedStemResponseOrder)
            expectedStemResponseRuleId(heaven, earth),
      };
      expect(rules, hasLength(81));
      expect(rules.every(QimenRuleCatalog.byId.containsKey), true);
      expect(
        rules.every((id) =>
            QimenRuleCatalog.rule(id).family == QimenRuleFamily.stemResponse),
        true,
      );
      expect(QimenRuleCatalog.stemResponseSpecs, hasLength(81));
      expect(QimenRuleCatalog.stemResponseByPair, hasLength(81));
      for (final heaven in expectedStemResponseOrder) {
        final terms = expectedStemResponseTerms[heaven]!;
        expect(terms, hasLength(9));
        for (var index = 0; index < expectedStemResponseOrder.length; index++) {
          final earth = expectedStemResponseOrder[index];
          final spec = QimenRuleCatalog.stemResponseSpec(heaven, earth);
          expect(spec.ruleId, expectedStemResponseRuleId(heaven, earth));
          expect(spec.sourceTerm, terms[index]);
          expect(
            spec.sourceWitnessPair,
            expectedStemResponseWitnessPair(heaven, earth),
          );
          expect(spec.displayTerm, '$heaven加$earth·${terms[index]}');
          expect(spec.claimSummary, contains(heaven));
          expect(spec.claimSummary, contains(earth));
          expect(spec.sourceIds, <String>[QimenSourceCatalog.baoJian]);
        }
      }
      expect(
        () => QimenRuleCatalog.stemResponseSpec('甲', '乙'),
        throwsArgumentError,
      );
    });

    test('released catalogs and rule-set lists are immutable', () {
      expect(() => QimenRuleCatalog.all.clear(), throwsUnsupportedError);
      expect(() => QimenRuleCatalog.byId.clear(), throwsUnsupportedError);
      expect(() => QimenRuleCatalog.released.clear(), throwsUnsupportedError);
      expect(
        () => QimenRuleCatalog.resolve('v1').rules.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => QimenRuleCatalog.stemResponseSpecs.clear(),
        throwsUnsupportedError,
      );
      expect(() => QimenSourceCatalog.byId.clear(), throwsUnsupportedError);
      expect(() => QimenRuleCatalog.rule('QMV1-UNKNOWN'), throwsStateError);
    });

    test('door-palace relation roles are owned by the rule catalog', () {
      const expected = <String, QimenFactRole>{
        QimenRuleCatalog.doorStateSame: QimenFactRole.support,
        QimenRuleCatalog.doorGeneratesPalace: QimenFactRole.support,
        QimenRuleCatalog.palaceGeneratesDoor: QimenFactRole.neutral,
        QimenRuleCatalog.doorControlsPalace: QimenFactRole.inhibit,
        QimenRuleCatalog.palaceControlsDoor: QimenFactRole.inhibit,
      };

      for (final entry in expected.entries) {
        expect(
          QimenRuleCatalog.rule(entry.key).factRole,
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('fixed classical sources retain audited immutable revisions', () {
      const oldIds = <String, String>{
        QimenSourceCatalog.tongZong: 'oldid=1378608',
        QimenSourceCatalog.dunJiaYanYi: 'oldid=2082234',
        QimenSourceCatalog.yuanLingJing: 'oldid=1378607',
        QimenSourceCatalog.baoJian: 'oldid=2353651',
        QimenSourceCatalog.tuShu707: 'oldid=1942670',
      };
      for (final entry in oldIds.entries) {
        final source = QimenSourceCatalog.byId[entry.key]!;
        expect(source.locator, contains(entry.value));
        expect(source.accessedOn, '2026-07-28');
      }
    });

    test('decision-capable rules never rely on an external snapshot alone', () {
      for (final rule in QimenRuleCatalog.all.where(
        (rule) => rule.decisionCapable,
      )) {
        final sources = rule.sourceIds.map(
          (sourceId) => QimenSourceCatalog.byId[sourceId]!,
        );
        expect(
          sources.every(
            (source) => source.kind == QimenSourceKind.externalCrossCheck,
          ),
          false,
          reason: rule.ruleId,
        );
      }
      expect(
        QimenSourceCatalog.all.map((source) => source.kind).toSet(),
        containsAll(<QimenSourceKind>{
          QimenSourceKind.classicalText,
          QimenSourceKind.publishedCase,
          QimenSourceKind.externalCrossCheck,
          QimenSourceKind.projectConvention,
        }),
      );
    });

    test('analysis imports no pan, persistence, UI, network, or clock code',
        () {
      const forbiddenServiceFiles = <String>[
        'qimen_system.dart',
        'qimen_time_service.dart',
        'qimen_ju_service.dart',
        'qimen_earth_plate_service.dart',
        'qimen_duty_service.dart',
        'qimen_heaven_plate_service.dart',
        'qimen_door_service.dart',
        'qimen_deity_service.dart',
        'qimen_hidden_stem_service.dart',
        'qimen_marker_service.dart',
        'qimen_pan_service.dart',
      ];
      const forbiddenImportFragments = <String>[
        '/data/',
        '/presentation/',
        '/repositories/',
        '/repository/',
        '/providers/',
        'package:flutter/',
        'package:http/',
        'package:dio/',
        'package:clock/',
        'package:drift/',
        'flutter_secure_storage',
        'shared_preferences',
        'dart:io',
        'dart:html',
      ];
      const forbiddenRuntimeCalls = <String>[
        'DateTime.now(',
        'DateTime.timestamp(',
        'Stopwatch(',
        'Timer(',
      ];
      final importPattern = RegExp(
        r'''^\s*import\s+['"]([^'"]+)['"];''',
        multiLine: true,
      );
      final files = _dartFiles('lib/domain/services/qimen/analysis');
      for (final file in files) {
        final source = file.readAsStringSync();
        for (final forbidden in forbiddenServiceFiles) {
          expect(source.contains(forbidden), false, reason: file.path);
        }
        for (final match in importPattern.allMatches(source)) {
          final uri = match.group(1)!;
          for (final forbidden in forbiddenImportFragments) {
            expect(uri.contains(forbidden), false,
                reason: '${file.path}: $uri');
          }
        }
        for (final forbidden in forbiddenRuntimeCalls) {
          expect(source.contains(forbidden), false, reason: file.path);
        }
      }
    });

    test('analysis and upstream Qimen contracts contain no scoring fields', () {
      const upstreamPaths = <String>[
        'lib/divination_systems/qimen/qimen_system.dart',
        'lib/domain/services/qimen/qimen_constants.dart',
        'lib/domain/services/qimen/qimen_ju_service.dart',
        'lib/domain/services/qimen/qimen_ju_strategy.dart',
        'lib/domain/services/qimen/chai_bu_ju_strategy.dart',
        'lib/domain/services/qimen/mao_shan_ju_strategy.dart',
        'lib/domain/services/qimen/zhi_run_ju_strategy.dart',
      ];
      final forbiddenIdentifier = RegExp(
        r'(?<![A-Za-z0-9_])(?:score|rating|percent|percentage|weighted[A-Za-z0-9_]*|tagCount|confidence)(?![A-Za-z0-9_])',
        caseSensitive: false,
      );
      final files = <File>[
        ..._dartFiles('lib/domain/services/qimen/analysis'),
        for (final path in upstreamPaths) File(path),
      ];

      for (final file in files) {
        expect(file.existsSync(), true, reason: file.path);
        final match = forbiddenIdentifier.firstMatch(file.readAsStringSync());
        expect(match, isNull, reason: '${file.path}: ${match?.group(0)}');
      }
    });

    test('analysis production and fixtures never invoke a pan cast', () {
      final directCast = RegExp(r'\.\s*cast\s*\(');
      final files = <File>[
        ..._dartFiles('lib/domain/services/qimen/analysis'),
        ..._dartFiles('test/unit/services/qimen/analysis').where(
          (file) => !file.path.endsWith('qimen_catalog_test.dart'),
        ),
      ];

      for (final file in files) {
        final source = file.readAsStringSync();
        expect(directCast.hasMatch(source), false, reason: file.path);
        expect(
          source.contains('QimenPanService.arrange('),
          false,
          reason: file.path,
        );
      }
    });
  });
}

List<File> _dartFiles(String root) {
  final files = Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList(growable: false)
    ..sort((left, right) => left.path.compareTo(right.path));
  return files;
}
