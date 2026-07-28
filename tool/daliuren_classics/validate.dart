import 'dart:io';

import 'package:path/path.dart' as p;

import 'validator.dart';

void main(List<String> arguments) {
  String repositoryPath = Directory.current.absolute.path;
  String? registryPath;
  bool writeReport = true;

  for (final String argument in arguments) {
    if (argument.startsWith('--repository=')) {
      repositoryPath = argument.substring('--repository='.length);
    } else if (argument.startsWith('--registry=')) {
      registryPath = argument.substring('--registry='.length);
    } else if (argument == '--no-write-report') {
      writeReport = false;
    } else {
      stderr.writeln('Unknown argument: $argument');
      exitCode = 64;
      return;
    }
  }

  final Directory repositoryRoot = Directory(repositoryPath).absolute;
  final Directory registryRoot = Directory(
    registryPath ??
        p.join(
          repositoryRoot.path,
          'assets',
          'data',
          'daliuren',
          'classics',
        ),
  ).absolute;
  final ClassicEvidenceValidator validator = ClassicEvidenceValidator(
    registryRoot: registryRoot,
    repositoryRoot: repositoryRoot,
  );
  final ValidationResult result = validator.validate();

  if (!result.isValid) {
    stderr.writeln(
      'Da Liu Ren classic evidence validation failed '
      'with ${result.issues.length} issue(s):',
    );
    for (final ValidationIssue issue in result.issues) {
      stderr.writeln('  $issue');
    }
    exitCode = 1;
    return;
  }

  if (writeReport) {
    final File reportFile = File(
      p.join(repositoryRoot.path, result.coverageReportPath),
    );
    reportFile.parent.createSync(recursive: true);
    reportFile.writeAsStringSync(result.coverageMarkdown);
  }

  stdout.writeln(
    'Da Liu Ren classic evidence registry is valid '
    '(${result.coverageReportPath}).',
  );
}
