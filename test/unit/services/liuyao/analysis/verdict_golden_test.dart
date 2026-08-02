import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../../../tool/liuyao_classics/fixture_models.dart';
import '../../../../../tool/liuyao_classics/validator.dart';

void main() {
  test('共享 40 例 fixture 的领域裁决与证据闭包全部匹配', () {
    final fixture = LiuYaoClassicsFixture.fromFile(
      File(
        p.join(
          Directory.current.path,
          'test',
          'fixtures',
          'liuyao',
          'classics_cases.v1.json',
        ),
      ),
    );
    final result = const LiuYaoClassicsValidator().validate(fixture);

    expect(result.errors, isEmpty, reason: result.errors.join('\n'));
    expect(result.caseCount, 40);
    expect(result.originalBookCount, 26);
    expect(result.ruleValidationCount, 14);
    expect(result.holdoutCount, 6);
    expect(
      result.cohortHash,
      'a4b6dcec44989a2d01d83b2113f9effa6099a95be1c8c876e6cb1ce0b44491a3',
    );
  });
}
