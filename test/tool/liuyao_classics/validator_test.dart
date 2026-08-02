import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/liuyao_classics/fixture_models.dart';
import '../../../tool/liuyao_classics/validator.dart';

void main() {
  Map<String, Object?> fixtureJson() {
    final file = File(
      p.join(
        Directory.current.path,
        'test',
        'fixtures',
        'liuyao',
        'classics_cases.v1.json',
      ),
    );
    return (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)
        .cast<String, Object?>();
  }

  LiuYaoClassicsValidationResult validate(Map<String, Object?> json) =>
      const LiuYaoClassicsValidator().validate(
        LiuYaoClassicsFixture.fromJson(json),
      );

  test('接受已签入 fixture 并冻结 cohort 统计', () {
    final result = validate(fixtureJson());

    expect(result.errors, isEmpty, reason: result.errors.join('\n'));
    expect(
      result.toJson(),
      <String, Object?>{
        'status': 'valid',
        'caseCount': 40,
        'originalBookCount': 26,
        'ruleValidationCount': 14,
        'holdoutCount': 6,
        'cohortHash':
            'a4b6dcec44989a2d01d83b2113f9effa6099a95be1c8c876e6cb1ce0b44491a3',
        'errors': <String>[],
      },
    );
  });

  test('评测 draft 不读取 holdout 的 expected 或 adjudication', () {
    final json = fixtureJson();
    for (final testCase in _cases(json).where(
      (testCase) => testCase['evaluationSplit'] == 'holdout',
    )) {
      _object(testCase['reference'])['adjudication'] = 42;
      testCase['expected'] = 'must-not-be-read-in-draft';
    }

    final fixture = LiuYaoClassicsFixture.fromJson(
      json,
      readMode: LiuYaoClassicsReadMode.evaluationDraft,
    );
    final holdouts = fixture.cases.where(
      (testCase) => testCase.evaluationSplit == 'holdout',
    );
    final result = const LiuYaoClassicsValidator().validate(
      fixture,
      mode: LiuYaoClassicsValidationMode.evaluationDraft,
    );

    expect(result.errors, isEmpty, reason: result.errors.join('\n'));
    expect(holdouts, hasLength(6));
    expect(
      holdouts.every(
        (testCase) =>
            testCase.evaluationReferenceWithheld &&
            testCase.reference.adjudication ==
                LiuYaoFixtureExpected.withheldValue &&
            testCase.expected.trend == LiuYaoFixtureExpected.withheldValue,
      ),
      isTrue,
    );
    expect(
      () => LiuYaoClassicsFixture.fromJson(json),
      throwsA(isA<FormatException>()),
    );
  });

  test('拒绝被修改的 holdout cohort hash', () {
    final json = fixtureJson();
    _object(json['holdout'])['cohortHash'] =
        List<String>.filled(64, '0').join();

    expect(
      validate(json).errors,
      contains('Holdout cohort hash mismatch.'),
    );
  });

  test('拒绝被修改的 holdout salt、成员顺序与 selection hash', () {
    final json = fixtureJson();
    final holdout = _object(json['holdout']);
    holdout['salt'] = 'changed-salt';
    final members = holdout['members']! as List<dynamic>;
    final first = _object(members.first);
    first['selectionHash'] = List<String>.filled(64, 'f').join();
    final moved = members.removeAt(0);
    members.add(moved);
    final errors = validate(json).errors;

    expect(
      errors,
      contains('Holdout salt does not match the frozen literal.'),
    );
    expect(
      errors.any((error) => error.startsWith('Holdout member mismatch at')),
      isTrue,
    );
  });

  test('拒绝盘面声明与未知规则 ID', () {
    final json = fixtureJson();
    final first = _cases(json).first;
    _object(first['pan'])['declaredMainGuaName'] = '错误卦名';
    (first['ruleIds']! as List<dynamic>).add('liuyao.rule.missing');
    final errors = validate(json).errors;

    expect(
      errors,
      contains(
        'liuyao.case.golden.001: unknown ruleId liuyao.rule.missing',
      ),
    );
    expect(
      errors.any((error) =>
          error.startsWith('liuyao.case.golden.001: main gua mismatch:')),
      isTrue,
    );
  });

  test('拒绝运行时稳定 ID 与来源闭包漂移', () {
    final json = fixtureJson();
    final first = _cases(json).first;
    final expected = _object(first['expected']);
    (expected['factorIds']! as List<dynamic>).clear();
    (first['sourceRefs']! as List<dynamic>).clear();
    final errors = validate(json).errors;

    expect(
      errors,
      contains(
          'liuyao.case.golden.001: factor runtime IDs are missing or stale'),
    );
    expect(
      errors,
      contains(
        'liuyao.case.golden.001: case sourceRefs do not cover the runtime source closure',
      ),
    );
  });

  test('拒绝证据 locator 泄露绝对路径', () {
    final json = fixtureJson();
    final first = _cases(json).first;
    final sourceRef = _object((first['sourceRefs']! as List<dynamic>).first);
    sourceRef['locator'] = r'C:\private\classics.pdf';

    expect(
      validate(json).errors,
      contains(
        'liuyao.case.golden.001: source locator leaks an absolute path',
      ),
    );
  });
}

Map<String, Object?> _object(Object? value) =>
    (value as Map<dynamic, dynamic>).cast<String, Object?>();

List<Map<String, Object?>> _cases(Map<String, Object?> json) =>
    (json['cases']! as List<dynamic>).map(_object).toList();
