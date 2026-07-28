import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/daliuren_classics/validator.dart';

void main() {
  final Directory sourceRegistry = Directory(
    p.join(
      Directory.current.path,
      'assets',
      'data',
      'daliuren',
      'classics',
    ),
  );

  late Directory temporaryRoot;
  late Directory repositoryRoot;
  late Directory registryRoot;

  setUp(() {
    temporaryRoot = Directory.systemTemp.createTempSync(
      'daliuren_classics_validator_',
    );
    repositoryRoot = Directory(p.join(temporaryRoot.path, 'repository'))
      ..createSync(recursive: true);
    registryRoot = Directory(
      p.join(
        repositoryRoot.path,
        'assets',
        'data',
        'daliuren',
        'classics',
      ),
    );
    _copyDirectory(sourceRegistry, registryRoot);
  });

  tearDown(() {
    if (temporaryRoot.existsSync()) {
      temporaryRoot.deleteSync(recursive: true);
    }
  });

  ValidationResult validate() => ClassicEvidenceValidator(
        registryRoot: registryRoot,
        repositoryRoot: repositoryRoot,
      ).validate();

  Map<String, Object?> readJson(String relativePath) => _readJson(
        File(p.join(registryRoot.path, relativePath)),
      );

  void writeJson(String relativePath, Map<String, Object?> value) {
    _writeJson(File(p.join(registryRoot.path, relativePath)), value);
  }

  Set<String> issueCodes() =>
      validate().issues.map((ValidationIssue issue) => issue.code).toSet();

  test('accepts the checked-in registry and builds deterministic coverage', () {
    final ValidationResult first = validate();
    final ValidationResult second = validate();

    expect(first.issues, isEmpty);
    expect(first.coverageMarkdown, second.coverageMarkdown);
    expect(first.coverageMarkdown, contains('| kejing | 64 |'));
    expect(first.coverageMarkdown, contains('| bifa | 100 |'));
  });

  test('registers approved Guide cases across two jiuzongmen branches', () {
    final Map<String, Object?> document = readJson('cases/zhinan.json');
    final List<Map<String, Object?>> cases = _objectList(document, 'cases');

    expect(document['catalogStatus'], 'approved');
    expect(cases, hasLength(3));
    final Set<String> courseNames = <String>{
      for (final Map<String, Object?> caseEntry in cases)
        ...(((caseEntry['expectedFacts']!
                as Map<String, dynamic>)['courseNames']! as List<dynamic>)
            .cast<String>()),
    };
    expect(courseNames, containsAll(<String>['重审', '涉害']));
    for (final Map<String, Object?> caseEntry in cases) {
      expect(caseEntry['verificationStatus'], 'approved');
      expect(caseEntry['evidenceLevel'], 'B');
      expect(caseEntry['locatorOnly'], isFalse);
      final Map<String, dynamic> sourceRef =
          caseEntry['sourceRef']! as Map<String, dynamic>;
      expect(sourceRef['referenceKind'], 'scan');
      final Map<String, dynamic> derivation =
          caseEntry['expectedDerivation']! as Map<String, dynamic>;
      expect(derivation['method'], 'independentManual');
      expect(derivation['usesProductionCode'], isFalse);
    }
  });

  test('freezes the independently reviewed 238-entry shensha catalog', () {
    final Map<String, Object?> document = readJson('rules/shensha.json');
    final List<Map<String, Object?>> entries = _objectList(document, 'entries');
    Map<String, Object?> at(int ordinal) => entries[ordinal - 1];

    expect(document['expectedEntryCount'], 238);
    expect(entries, hasLength(238));
    expect(at(46)['traditionalName'], '天阙');
    expect(at(53)['adoptedStatus'], 'disputed');
    expect(at(54)['traditionalName'], '关');
    expect(at(54)['evidenceLevel'], 'C');
    expect(at(57)['traditionalName'], '关魂');
    expect(at(67)['traditionalName'], '扳鞍');
    expect(at(91)['traditionalName'], '游神');
    expect(at(93)['traditionalName'], '天车');
    expect(at(94)['traditionalName'], '寡神');
    expect(at(99)['subfamily'], 'dayStem');
    expect(at(102)['traditionalName'], '喝散');
    expect(at(103)['traditionalName'], '禁神');
    expect(at(104)['traditionalName'], '孤神');
    expect(at(108)['traditionalName'], '天鸡');
    expect(at(193)['traditionalName'], '孤辰');
    expect(at(194)['traditionalName'], '钥神');
    expect(at(104)['variantGroupId'],
        'dlr.variant.shensha-gushen-guchen-identity');
    expect(at(193)['variantGroupId'],
        'dlr.variant.shensha-gushen-guchen-identity');
    expect(
      entries.where(
          (Map<String, Object?> item) => item['adoptedStatus'] == 'excluded'),
      hasLength(3),
    );
    expect(
      entries.every(
          (Map<String, Object?> item) => item['executableApproved'] == false),
      isTrue,
    );
  });

  test('freezes 100 reviewed bifa identities without executable approval', () {
    final Map<String, Object?> document = readJson('rules/bifa.json');
    final List<Map<String, Object?>> entries = _objectList(document, 'entries');
    Map<String, Object?> at(int ordinal) => entries[ordinal - 1];

    expect(entries, hasLength(100));
    expect(at(14)['traditionalName'], '传财太旺返财亏');
    expect(at(36)['traditionalName'], '干支皆败势倾颓');
    expect(at(36)['sourceRefs'], isNotEmpty);
    expect(
      _objectList(at(36), 'sourceRefs').first['pdfPage'],
      118,
    );
    expect(at(64)['traditionalName'], '夫妇无淫各有私');
    expect(at(76)['adoptedStatus'], 'disputed');
    expect(at(98)['traditionalName'], '分占现类勿言之');
    expect(at(99)['traditionalName'], '常流不应逢吉象');
    expect(
      entries.every((Map<String, Object?> item) =>
          item['evidenceLevel'] == 'B' &&
          item['locatorOnly'] == false &&
          item['executableApproved'] == false),
      isTrue,
    );
  });

  test('rejects duplicate rule IDs and ordinals', () {
    final Map<String, Object?> document = readJson('rules/pan.json');
    final List<Map<String, Object?>> entries = _objectList(document, 'entries');
    entries[1]['ruleId'] = entries.first['ruleId'];
    entries[1]['ordinal'] = entries.first['ordinal'];
    writeJson('rules/pan.json', document);

    expect(
      issueCodes(),
      containsAll(<String>['rule.duplicate', 'ordinal.duplicate']),
    );
  });

  test('rejects a scan reference without a stable locus', () {
    final Map<String, Object?> document = readJson('rules/pan.json');
    final Map<String, Object?> rule = _objectList(document, 'entries').first;
    rule['sourceRefs'] = <Object?>[
      _scanRef(
        scanLeaf: null,
        pdfPage: null,
        reviewers: _distinctReviewers,
      ),
    ];
    writeJson('rules/pan.json', document);

    expect(issueCodes(), contains('sourceRef.locusMissing'));
  });

  test('rejects dangling source, rule, and fixture references', () {
    final Map<String, Object?> rules = readJson('rules/pan.json');
    final Map<String, Object?> rule = _objectList(rules, 'entries').first;
    final Map<String, Object?> sourceRef =
        _objectList(rule, 'sourceRefs').first;
    sourceRef['sourceId'] = 'dlr.source.missing';
    rule['fixtureIds'] = <String>['dlr.case.missing'];
    writeJson('rules/pan.json', rules);

    final Map<String, Object?> cases = readJson('cases/cunyan.json');
    final Map<String, Object?> caseEntry = _objectList(cases, 'cases').first;
    (caseEntry['coveredRuleIds']! as List<dynamic>).add('dlr.rule.missing');
    writeJson('cases/cunyan.json', cases);

    expect(
      issueCodes(),
      containsAll(<String>[
        'reference.sourceDangling',
        'reference.fixtureDangling',
        'reference.ruleDangling',
      ]),
    );
  });

  test('rejects a source used outside its registered rule layers', () {
    final Map<String, Object?> document = readJson('rules/pan.json');
    final Map<String, Object?> sources = readJson('sources.json');
    final Map<String, Object?> source =
        _objectList(sources, 'sources').firstWhere(
      (Map<String, Object?> item) =>
          item['sourceId'] == 'dlr.source.daliuren-zhinan-scan',
    );
    source['ruleLayers'] = <String>['judgment'];
    writeJson('sources.json', sources);
    writeJson('rules/pan.json', document);

    expect(issueCodes(), contains('sourceRef.layerMismatch'));
  });

  test('rejects an orphan A, B, or C rule without a source reference', () {
    final Map<String, Object?> document = readJson('rules/pan.json');
    final Map<String, Object?> rule = _objectList(document, 'entries').first;
    rule['sourceRefs'] = <Object?>[];
    writeJson('rules/pan.json', document);

    expect(issueCodes(), contains('evidence.sourceRequired'));
  });

  test('rejects a case source not registered for external cases', () {
    final Map<String, Object?> sources = readJson('sources.json');
    final Map<String, Object?> source =
        _objectList(sources, 'sources').firstWhere(
      (Map<String, Object?> item) =>
          item['sourceId'] == 'dlr.source.cunyan-transcription-d2a44794',
    );
    source['ruleLayers'] = <String>['pan'];
    writeJson('sources.json', sources);

    expect(issueCodes(), contains('sourceRef.layerMismatch'));
  });

  test('rejects incorrect fixed shensha, kejing, and bifa counts', () {
    for (final String family in <String>['shensha', 'kejing', 'bifa']) {
      final String path = 'rules/$family.json';
      final Map<String, Object?> document = readJson(path);
      final List<dynamic> entries = document['entries']! as List<dynamic>;
      entries.removeLast();
      document['expectedEntryCount'] = entries.length;
      writeJson(path, document);
    }

    final ValidationResult result = validate();
    expect(
      result.issues
          .where((ValidationIssue issue) => issue.code == 'family.exactCount'),
      hasLength(3),
    );
  });

  test('rejects locator-only promotion to A or B evidence', () {
    final Map<String, Object?> document = readJson('rules/pan.json');
    final Map<String, Object?> rule = _objectList(document, 'entries').first;
    rule
      ..['evidenceLevel'] = 'B'
      ..['locatorOnly'] = true;
    writeJson('rules/pan.json', document);

    expect(issueCodes(), contains('evidence.locatorPromotion'));
  });

  test('rejects an executable rule without a fixture', () {
    final Map<String, Object?> document = readJson('rules/pan.json');
    final Map<String, Object?> rule = _objectList(document, 'entries').first;
    _makeExecutableRule(rule, fixtureIds: <String>[]);
    writeJson('rules/pan.json', document);

    expect(issueCodes(), contains('executable.fixture'));
  });

  test('rejects an overlong source quote', () {
    final Map<String, Object?> document = readJson('rules/pan.json');
    final Map<String, Object?> rule = _objectList(document, 'entries').first;
    _objectList(rule, 'sourceRefs').first['shortQuote'] =
        List<String>.filled(161, 'x').join();
    writeJson('rules/pan.json', document);

    expect(issueCodes(), contains('quote.tooLong'));
  });

  test('rejects a checked-in scan or image file', () {
    File(p.join(registryRoot.path, 'forbidden.pdf')).writeAsBytesSync(
      <int>[0x25, 0x50, 0x44, 0x46],
    );

    expect(issueCodes(), contains('scan.forbidden'));
  });

  test('rejects expected facts generated by production code', () {
    final Map<String, Object?> document = readJson('cases/cunyan.json');
    final Map<String, Object?> caseEntry = _objectList(document, 'cases').first;
    final Map<String, Object?> derivation =
        (caseEntry['expectedDerivation']! as Map<String, dynamic>)
            .cast<String, Object?>();
    derivation['usesProductionCode'] = true;
    writeJson('cases/cunyan.json', document);

    expect(issueCodes(), contains('case.productionExpected'));
  });

  test('rejects an unsafe manifest path', () {
    final Map<String, Object?> manifest = readJson('manifest.json');
    manifest['sourceFile'] = '../sources.json';
    writeJson('manifest.json', manifest);

    expect(issueCodes(), contains('path.invalid'));
  });

  test('rejects attempts to weaken fixed manifest gates', () {
    final Map<String, Object?> manifest = readJson('manifest.json');
    (manifest['requiredFamilies']! as List<dynamic>).remove('shensha');
    (manifest['ruleFiles']! as List<dynamic>).remove('rules/shensha.json');
    (manifest['caseFiles']! as List<dynamic>).remove('cases/zhinan.json');
    final Map<String, dynamic> exactCounts =
        manifest['exactRuleCounts']! as Map<String, dynamic>;
    exactCounts['shensha'] = 236;
    exactCounts['kejing'] = 63;
    manifest['maxShortQuoteCharacters'] = 1000;
    (manifest['forbiddenExtensions']! as List<dynamic>).remove('.pdf');
    writeJson('manifest.json', manifest);

    expect(
      issueCodes(),
      containsAll(<String>[
        'manifest.requiredFamilyMissing',
        'manifest.requiredPathMissing',
        'manifest.exactRuleConstraint',
        'manifest.forbiddenExtensionMissing',
        'shape.type',
      ]),
    );
  });

  test('rejects configurable variants without two A/B scan options', () {
    final Map<String, Object?> document = readJson('variants.json');
    final Map<String, Object?> variant =
        _objectList(document, 'variants').first;
    final List<Map<String, Object?>> options = _objectList(variant, 'options');
    variant['status'] = 'adopted';
    variant['configurable'] = true;
    variant['adoptedVariantId'] = options.first['variantId'];
    writeJson('variants.json', document);

    expect(issueCodes(), contains('variant.configurableEvidence'));
  });

  test('does not accept an unverified scan source as A/B evidence', () {
    final Map<String, Object?> document = readJson('rules/pan.json');
    final Map<String, Object?> rule = _objectList(document, 'entries').first;
    rule
      ..['evidenceLevel'] = 'B'
      ..['locatorOnly'] = false
      ..['sourceRefs'] = <Object?>[
        _scanRef(
          sourceId: 'dlr.source.zhinan-xiangjie-scan',
          volume: '全册',
          scanLeaf: 0,
          pdfPage: 1,
          reviewers: _distinctReviewers,
        ),
      ];
    writeJson('rules/pan.json', document);

    expect(
      issueCodes(),
      containsAll(<String>[
        'sourceRef.scanSourceUnverified',
        'evidence.scanRequired',
      ]),
    );
  });

  test('counts page reviewers by identity rather than review date', () {
    final Map<String, Object?> document = readJson('rules/pan.json');
    final Map<String, Object?> rule = _objectList(document, 'entries').first;
    rule
      ..['evidenceLevel'] = 'B'
      ..['locatorOnly'] = false
      ..['sourceRefs'] = <Object?>[
        _scanRef(
          reviewers: <Map<String, Object?>>[
            <String, Object?>{
              'reviewer': 'same-reviewer',
              'date': '2026-07-27',
            },
            <String, Object?>{
              'reviewer': 'same-reviewer',
              'date': '2026-07-28',
            },
          ],
        ),
      ];
    writeJson('rules/pan.json', document);

    expect(
      issueCodes(),
      containsAll(<String>[
        'evidence.reviewerDuplicate',
        'evidence.secondReviewRequired',
      ]),
    );
  });

  test('requires A evidence to have cross-source and complete-case support',
      () {
    final Map<String, Object?> document = readJson('rules/pan.json');
    final Map<String, Object?> rule = _objectList(document, 'entries').first;
    rule
      ..['evidenceLevel'] = 'A'
      ..['locatorOnly'] = false
      ..['sourceRefs'] = <Object?>[
        _scanRef(reviewers: _distinctReviewers),
      ]
      ..['fixtureIds'] = <String>[];
    writeJson('rules/pan.json', document);

    expect(
      issueCodes(),
      containsAll(<String>[
        'evidence.aIndependentSource',
        'evidence.aFixture',
      ]),
    );
  });

  test('rejects unsupported schema versions and malformed stable IDs', () {
    final Map<String, Object?> document = readJson('sources.json');
    document['schemaVersion'] = '2.0.0';
    _objectList(document, 'sources').first['sourceId'] = 'not-a-source-id';
    writeJson('sources.json', document);

    final Map<String, Object?> schema = readJson('schema/rule.schema.json');
    schema[r'$id'] = 'https://example.invalid/rule.schema.json';
    writeJson('schema/rule.schema.json', schema);

    expect(
      issueCodes(),
      containsAll(<String>['schema.version', 'schema.id', 'id.pattern']),
    );
  });

  test('rejects an executable rule backed only by a locator case', () {
    final Map<String, Object?> document = readJson('rules/jiuzongmen.json');
    final Map<String, Object?> rule = _objectList(document, 'entries').first;
    _makeExecutableRule(
      rule,
      fixtureIds: <String>['dlr.case.cunyan.dingchou-yiyou-pregnancy'],
    );
    writeJson('rules/jiuzongmen.json', document);

    expect(issueCodes(), contains('executable.fixtureEvidence'));
  });
}

const List<Map<String, Object?>> _distinctReviewers = <Map<String, Object?>>[
  <String, Object?>{'reviewer': 'scan-review-one', 'date': '2026-07-27'},
  <String, Object?>{'reviewer': 'scan-review-two', 'date': '2026-07-28'},
];

Map<String, Object?> _scanRef({
  String sourceId = 'dlr.source.siku-liuren-daquan',
  String volume = '卷一',
  int? scanLeaf = 1,
  int? pdfPage = 1,
  List<Map<String, Object?>> reviewers = const <Map<String, Object?>>[],
}) =>
    <String, Object?>{
      'sourceId': sourceId,
      'referenceKind': 'scan',
      'volume': volume,
      'scanLeaf': scanLeaf,
      'printedLeaf': null,
      'pdfPage': pdfPage,
      'imageLabel': null,
      'locator': null,
      'shortQuote': '测试所需短引',
      'verifiedBy': reviewers,
    };

void _makeExecutableRule(
  Map<String, Object?> rule, {
  required List<String> fixtureIds,
}) {
  rule
    ..['adoptedStatus'] = 'adopted'
    ..['evidenceLevel'] = 'B'
    ..['locatorOnly'] = false
    ..['executableApproved'] = true
    ..['sourceRefs'] = <Object?>[
      _scanRef(reviewers: _distinctReviewers),
    ]
    ..['fixtureIds'] = fixtureIds
    ..['variantGroupId'] = null
    ..['adoptedVariantId'] = null;
}

Map<String, Object?> _readJson(File file) {
  return (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)
      .cast<String, Object?>();
}

void _writeJson(File file, Map<String, Object?> value) {
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(value)}\n');
}

List<Map<String, Object?>> _objectList(
  Map<String, Object?> object,
  String key,
) {
  return (object[key]! as List<dynamic>)
      .map(
        (dynamic item) =>
            (item as Map<String, dynamic>).cast<String, Object?>(),
      )
      .toList(growable: false);
}

void _copyDirectory(Directory source, Directory destination) {
  if (!source.existsSync()) {
    throw StateError('Source registry does not exist: ${source.path}');
  }
  destination.createSync(recursive: true);
  for (final FileSystemEntity entity
      in source.listSync(recursive: false, followLinks: false)) {
    final String targetPath = p.join(destination.path, p.basename(entity.path));
    if (entity is Directory) {
      _copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      File(targetPath)
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(entity.readAsBytesSync());
    }
  }
}
