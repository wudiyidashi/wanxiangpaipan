import 'dart:convert';
import 'dart:io';

import 'canonical_json.dart';
import 'runner.dart';
import 'security.dart';

Future<void> main(List<String> arguments) async {
  CliResult result;
  try {
    final CliInvocation invocation = const EvalCliParser().parse(arguments);
    final String repositoryRoot = const RepositoryLocator().findRoot();
    result = await LiuYaoEvalRunner(repositoryRoot: repositoryRoot).execute(
      invocation,
    );
  } on EvalFailure catch (error) {
    result = CliResult(
      exitCode: 2,
      payload: <String, Object?>{
        'runId': _safeRunId(arguments),
        'command': arguments.isEmpty ? null : arguments.first,
        'status': 'failed',
        'errorKind': error.kind,
      },
    );
  } on Object {
    result = CliResult(
      exitCode: 2,
      payload: <String, Object?>{
        'runId': _safeRunId(arguments),
        'command': arguments.isEmpty ? null : arguments.first,
        'status': 'failed',
        'errorKind': 'internalFailure',
      },
    );
  }
  stdout.writeln(jsonEncode(normalizeJson(result.payload)));
  exitCode = result.exitCode;
}

String? _safeRunId(List<String> arguments) {
  final int index = arguments.indexOf('--run-id');
  if (index < 0 || index + 1 >= arguments.length) {
    return null;
  }
  final String value = arguments[index + 1];
  return RegExp(r'^[a-z0-9][a-z0-9._-]{2,63}$').hasMatch(value) ? value : null;
}
