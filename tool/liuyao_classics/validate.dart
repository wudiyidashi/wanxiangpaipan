import 'dart:convert';
import 'dart:io';

import 'fixture_models.dart';
import 'validator.dart';

void main() {
  try {
    final fixture = LiuYaoClassicsFixture.fromFile(
      File('test/fixtures/liuyao/classics_cases.v1.json'),
    );
    final result = const LiuYaoClassicsValidator().validate(fixture);
    stdout.writeln(jsonEncode(result.toJson()));
    if (!result.isValid) exitCode = 1;
  } on Object catch (error) {
    stdout.writeln(jsonEncode(<String, Object?>{
      'status': 'invalid',
      'error': error.runtimeType.toString(),
    }));
    exitCode = 1;
  }
}
