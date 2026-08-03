import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'canonical_json.dart';
import 'constants.dart';

final RegExp _runIdPattern = RegExp(r'^[a-z0-9][a-z0-9._-]{2,63}$');

void validateRunId(String runId) {
  if (!_runIdPattern.hasMatch(runId)) {
    throw const EvalFailure('invalidRunId');
  }
}

class EvalFailure implements Exception {
  const EvalFailure(this.kind);

  final String kind;

  @override
  String toString() => kind;
}

class RepositoryLocator {
  const RepositoryLocator();

  String findRoot([String? startingPath]) {
    Directory current =
        Directory(startingPath ?? Directory.current.path).absolute;
    while (true) {
      if (File(p.join(current.path, 'pubspec.yaml')).existsSync() &&
          Directory(p.join(current.path, '.git')).existsSync()) {
        return p.normalize(current.path);
      }
      final Directory parent = current.parent;
      if (p.equals(parent.path, current.path)) {
        throw const EvalFailure('repositoryRootNotFound');
      }
      current = parent;
    }
  }
}

class GitInspector {
  const GitInspector();

  bool isIgnored(String repositoryRoot, String relativePath) =>
      _exitCode(
        repositoryRoot,
        <String>['check-ignore', '-q', '--', relativePath],
      ) ==
      0;

  bool isTracked(String repositoryRoot, String relativePath) =>
      _exitCode(
        repositoryRoot,
        <String>['ls-files', '--error-unmatch', '--', relativePath],
      ) ==
      0;

  int _exitCode(String repositoryRoot, List<String> arguments) {
    try {
      return Process.runSync(
        'git',
        arguments,
        workingDirectory: repositoryRoot,
        runInShell: Platform.isWindows,
      ).exitCode;
    } on ProcessException {
      throw const EvalFailure('gitInspectionFailed');
    }
  }
}

class OutputPathGuard {
  OutputPathGuard({
    required this.repositoryRoot,
    GitInspector? gitInspector,
  }) : gitInspector = gitInspector ?? const GitInspector();

  final String repositoryRoot;
  final GitInspector gitInspector;

  Directory validateAndCreateRoot(String suppliedPath) {
    final String expected = p.normalize(
      p.absolute(p.join(repositoryRoot, evalOutputRootRelativePath)),
    );
    final String candidate = p.normalize(
      p.absolute(
        p.isAbsolute(suppliedPath)
            ? suppliedPath
            : p.join(repositoryRoot, suppliedPath),
      ),
    );
    if (!p.equals(expected, candidate)) {
      throw const EvalFailure('outputPathOutsideTaskEvalRoot');
    }
    if (!gitInspector.isIgnored(
      repositoryRoot,
      evalOutputRootRelativePath,
    )) {
      throw const EvalFailure('outputPathNotIgnored');
    }
    if (gitInspector.isTracked(
      repositoryRoot,
      evalOutputRootRelativePath,
    )) {
      throw const EvalFailure('outputPathTracked');
    }
    _rejectLinksBetween(repositoryRoot, candidate);
    _rejectResolvedExistingComponents(repositoryRoot, candidate);
    final Directory directory = Directory(candidate)
      ..createSync(recursive: true);
    _rejectLinksBetween(repositoryRoot, directory.path);
    final String resolvedRepository =
        Directory(repositoryRoot).resolveSymbolicLinksSync();
    final String resolvedOutput = directory.resolveSymbolicLinksSync();
    final String expectedResolved = p.normalize(
      p.join(resolvedRepository, evalOutputRootRelativePath),
    );
    if (!p.equals(resolvedOutput, expectedResolved) ||
        !p.isWithin(resolvedRepository, resolvedOutput)) {
      throw const EvalFailure('outputPathResolvesOutsideTaskEvalRoot');
    }
    return directory;
  }

  void _rejectLinksBetween(String ancestor, String descendant) {
    String current = p.normalize(p.absolute(ancestor));
    final String target = p.normalize(p.absolute(descendant));
    final List<String> relativeParts =
        p.split(p.relative(target, from: current));
    for (final String part in relativeParts) {
      current = p.join(current, part);
      if (FileSystemEntity.typeSync(current, followLinks: false) ==
          FileSystemEntityType.link) {
        throw const EvalFailure('outputPathContainsLink');
      }
    }
  }

  void _rejectResolvedExistingComponents(String ancestor, String descendant) {
    final String normalizedAncestor = p.normalize(p.absolute(ancestor));
    final String resolvedAncestor =
        Directory(normalizedAncestor).resolveSymbolicLinksSync();
    String current = normalizedAncestor;
    for (final String part
        in p.split(p.relative(descendant, from: normalizedAncestor))) {
      current = p.join(current, part);
      final FileSystemEntityType type =
          FileSystemEntity.typeSync(current, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        return;
      }
      if (type != FileSystemEntityType.directory) {
        throw const EvalFailure('outputPathComponentInvalid');
      }
      final String expected = p.normalize(
        p.join(
          resolvedAncestor,
          p.relative(current, from: normalizedAncestor),
        ),
      );
      final String resolved = Directory(current).resolveSymbolicLinksSync();
      if (!p.equals(expected, resolved)) {
        throw const EvalFailure('outputPathComponentResolvesElsewhere');
      }
    }
  }
}

class RunWorkspace {
  RunWorkspace._({required this.runId, required this.directory});

  final String runId;
  final Directory directory;

  factory RunWorkspace.open({
    required Directory outputRoot,
    required String runId,
  }) {
    validateRunId(runId);
    final Directory runDirectory = Directory(p.join(outputRoot.path, runId));
    if (FileSystemEntity.typeSync(runDirectory.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const EvalFailure('runDirectoryIsLink');
    }
    runDirectory.createSync(recursive: true);
    final File identityFile =
        File(p.join(runDirectory.path, 'run_identity.json'));
    if (identityFile.existsSync()) {
      try {
        final Map<String, Object?> identity =
            decodeObject(identityFile.readAsStringSync());
        requireExactKeys(identity, <String>{'schemaVersion', 'runId'});
        if (requireString(identity, 'schemaVersion') !=
                evalArtifactSchemaVersion ||
            requireString(identity, 'runId') != runId) {
          throw const EvalFailure('runIdentityMismatch');
        }
      } on FormatException {
        throw const EvalFailure('runIdentityInvalid');
      }
    } else {
      identityFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{
              'schemaVersion': evalArtifactSchemaVersion,
              'runId': runId,
            })}\n',
        flush: true,
      );
    }
    return RunWorkspace._(runId: runId, directory: runDirectory);
  }

  Directory createCommandDirectory(String command, {String? variant}) {
    final String leaf = variant == null ? command : '$command-$variant';
    if (!_runIdPattern.hasMatch(leaf)) {
      throw const EvalFailure('invalidArtifactScope');
    }
    final Directory result = Directory(p.join(directory.path, leaf));
    if (result.existsSync() ||
        FileSystemEntity.typeSync(result.path, followLinks: false) !=
            FileSystemEntityType.notFound) {
      throw const EvalFailure('artifactScopeAlreadyExists');
    }
    result.createSync(recursive: false);
    return result;
  }

  Directory createSequencedCommandDirectory(String command) {
    _validateArtifactScope(command);
    for (int sequence = 1; sequence <= 999; sequence += 1) {
      final String leaf = sequence == 1 ? command : '$command-$sequence';
      final Directory candidate = Directory(p.join(directory.path, leaf));
      if (FileSystemEntity.typeSync(candidate.path, followLinks: false) ==
          FileSystemEntityType.notFound) {
        candidate.createSync(recursive: false);
        return candidate;
      }
    }
    throw const EvalFailure('artifactScopeSequenceExhausted');
  }

  Directory createRetryableCommandDirectory(String command) {
    _validateArtifactScope(command);
    final List<Directory> attempts = _commandDirectories(command);
    if (attempts.any(
      (Directory directory) =>
          File(p.join(directory.path, '_SUCCESS')).existsSync(),
    )) {
      throw const EvalFailure('artifactScopeAlreadyCompleted');
    }
    return createSequencedCommandDirectory(command);
  }

  void bindRetryIdentity({
    required String command,
    required String identityHash,
    required Map<String, Object?> identity,
  }) {
    _validateArtifactScope(command);
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(identityHash)) {
      throw const EvalFailure('retryIdentityInvalid');
    }
    final Object? normalizedIdentity;
    try {
      normalizedIdentity = normalizeJson(identity);
    } on Object {
      throw const EvalFailure('retryIdentityInvalid');
    }
    final Object? embeddedRunHash = normalizedIdentity is Map<String, Object?>
        ? normalizedIdentity['runHash']
        : null;
    if (normalizedIdentity is! Map<String, Object?> ||
        normalizedIdentity.isEmpty ||
        (embeddedRunHash != null &&
            (embeddedRunHash is! String || embeddedRunHash != identityHash))) {
      throw const EvalFailure('retryIdentityInvalid');
    }
    final File identityFile =
        File(p.join(directory.path, '$command.identity.json'));
    final FileSystemEntityType type = FileSystemEntity.typeSync(
      identityFile.path,
      followLinks: false,
    );
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const EvalFailure('retryIdentityInvalid');
    }
    final Map<String, Object?> expected = <String, Object?>{
      'schemaVersion': evalArtifactSchemaVersion,
      'command': command,
      'identityHash': identityHash,
      'identity': normalizedIdentity,
    };
    if (type == FileSystemEntityType.file) {
      try {
        final Map<String, Object?> existing =
            decodeObject(identityFile.readAsStringSync());
        requireExactKeys(
          existing,
          <String>{'schemaVersion', 'command', 'identityHash', 'identity'},
        );
        final String existingHash = requireString(existing, 'identityHash');
        final Map<String, Object?> existingIdentity =
            requireObject(existing, 'identity');
        if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(existingHash)) {
          throw const FormatException('Invalid retry identity hash.');
        }
        if (requireString(existing, 'schemaVersion') !=
                evalArtifactSchemaVersion ||
            requireString(existing, 'command') != command ||
            existingHash != identityHash ||
            canonicalJson(existingIdentity) !=
                canonicalJson(normalizedIdentity)) {
          throw const EvalFailure('retryIdentityMismatch');
        }
      } on FormatException {
        throw const EvalFailure('retryIdentityInvalid');
      }
      return;
    }
    identityFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(expected)}\n',
      flush: true,
    );
  }

  Directory requireSuccessfulCommandDirectory(String command) {
    _validateArtifactScope(command);
    final List<Directory> successful = _commandDirectories(command)
        .where(
          (Directory directory) =>
              File(p.join(directory.path, '_SUCCESS')).existsSync(),
        )
        .toList(growable: false);
    if (successful.length != 1) {
      throw const EvalFailure('requiredArtifactMissingOrInvalid');
    }
    return successful.single;
  }

  List<Directory> _commandDirectories(String command) {
    final List<Directory> result = <Directory>[];
    for (int sequence = 1; sequence <= 999; sequence += 1) {
      final String leaf = sequence == 1 ? command : '$command-$sequence';
      final String path = p.join(directory.path, leaf);
      final FileSystemEntityType type =
          FileSystemEntity.typeSync(path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        continue;
      }
      if (type != FileSystemEntityType.directory) {
        throw const EvalFailure('artifactScopeInvalid');
      }
      result.add(Directory(path));
    }
    return result;
  }

  void _validateArtifactScope(String command) {
    if (!_runIdPattern.hasMatch(command)) {
      throw const EvalFailure('invalidArtifactScope');
    }
  }
}

class EvalCredentials {
  const EvalCredentials({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    required this.providerLabel,
    this.timeoutSeconds = defaultTransportTimeoutSeconds,
  });

  final String apiKey;
  final String baseUrl;
  final String model;
  final String? providerLabel;
  final int timeoutSeconds;

  Set<String> get sensitiveValues => <String>{apiKey, baseUrl};

  Map<String, Object?> safeMetadata() => <String, Object?>{
        'providerLabel': providerLabel,
        'model': model,
        'timeoutSeconds': timeoutSeconds,
      };

  @override
  String toString() => 'EvalCredentials(configured: true)';
}

class ConfigLoadResult {
  const ConfigLoadResult({
    required this.realModelStatus,
    this.credentials,
    this.errorKind,
  });

  final String realModelStatus;
  final EvalCredentials? credentials;
  final String? errorKind;
}

class EvalConfigLoader {
  EvalConfigLoader({
    required this.repositoryRoot,
    Map<String, String>? environment,
    GitInspector? gitInspector,
  })  : environment = environment ?? Platform.environment,
        gitInspector = gitInspector ?? const GitInspector();

  final String repositoryRoot;
  final Map<String, String> environment;
  final GitInspector gitInspector;

  ConfigLoadResult load() {
    try {
      _validateIgnoreContract();
      final File localFile = File(
        p.join(repositoryRoot, evalLocalConfigRelativePath),
      );
      Map<String, Object?> local = <String, Object?>{};
      if (localFile.existsSync()) {
        _validateLocalFile(localFile);
        local = decodeObject(localFile.readAsStringSync());
        requireExactKeys(
          local,
          <String>{'apiKey', 'baseUrl', 'model'},
          optional: <String>{'providerLabel', 'timeoutSeconds'},
        );
        requireString(local, 'apiKey');
        requireString(local, 'baseUrl');
        requireString(local, 'model');
        if (local.containsKey('providerLabel')) {
          requireString(local, 'providerLabel');
        }
        if (local.containsKey('timeoutSeconds')) {
          requireInt(local, 'timeoutSeconds');
        }
      }

      final bool anyEnvironmentField = <String>{
        'LIUYAO_AI_EVAL_API_KEY',
        'LIUYAO_AI_EVAL_BASE_URL',
        'LIUYAO_AI_EVAL_MODEL',
        'LIUYAO_AI_EVAL_PROVIDER_LABEL',
        'LIUYAO_AI_EVAL_TIMEOUT_SECONDS',
      }.any(environment.containsKey);
      if (local.isEmpty && !anyEnvironmentField) {
        return const ConfigLoadResult(
          realModelStatus: 'blockedMissingCredentials',
          errorKind: 'missingCredentials',
        );
      }

      String? field(String environmentKey, String localKey) {
        if (environment.containsKey(environmentKey)) {
          return environment[environmentKey];
        }
        return local[localKey] as String?;
      }

      final String? apiKey = field('LIUYAO_AI_EVAL_API_KEY', 'apiKey');
      final String? baseUrl = field('LIUYAO_AI_EVAL_BASE_URL', 'baseUrl');
      final String? model = field('LIUYAO_AI_EVAL_MODEL', 'model');
      final String? providerLabel =
          field('LIUYAO_AI_EVAL_PROVIDER_LABEL', 'providerLabel');
      final Object? timeoutRaw = environment.containsKey(
        'LIUYAO_AI_EVAL_TIMEOUT_SECONDS',
      )
          ? environment['LIUYAO_AI_EVAL_TIMEOUT_SECONDS']
          : local['timeoutSeconds'];
      final int? timeoutSeconds = switch (timeoutRaw) {
        null => defaultTransportTimeoutSeconds,
        int value => value,
        String value => int.tryParse(value),
        _ => null,
      };
      if (apiKey == null || baseUrl == null || model == null) {
        return const ConfigLoadResult(
          realModelStatus: 'blockedInvalidConfiguration',
          errorKind: 'incompleteConfiguration',
        );
      }
      _validateCredentialValue(apiKey, 'apiKey');
      _validateBaseUrl(baseUrl);
      _validateCredentialValue(model, 'model');
      if (providerLabel != null) {
        _validateProviderLabel(providerLabel);
      }
      if (timeoutSeconds == null ||
          timeoutSeconds < minimumTransportTimeoutSeconds ||
          timeoutSeconds > maximumTransportTimeoutSeconds) {
        throw const EvalFailure('invalidTimeoutSeconds');
      }
      return ConfigLoadResult(
        realModelStatus: 'ready',
        credentials: EvalCredentials(
          apiKey: apiKey,
          baseUrl: baseUrl,
          model: model,
          providerLabel: providerLabel,
          timeoutSeconds: timeoutSeconds,
        ),
      );
    } on EvalFailure catch (error) {
      return ConfigLoadResult(
        realModelStatus: 'blockedInvalidConfiguration',
        errorKind: error.kind,
      );
    } on FormatException {
      return const ConfigLoadResult(
        realModelStatus: 'blockedInvalidConfiguration',
        errorKind: 'invalidLocalConfigSchema',
      );
    } on FileSystemException {
      return const ConfigLoadResult(
        realModelStatus: 'blockedInvalidConfiguration',
        errorKind: 'localConfigReadFailed',
      );
    }
  }

  void _validateIgnoreContract() {
    final File ignore = File(p.join(repositoryRoot, '.gitignore'));
    if (!ignore.existsSync()) {
      throw const EvalFailure('gitIgnoreMissing');
    }
    final int exactEntries = ignore
        .readAsLinesSync()
        .where((String line) => line == evalLocalConfigIgnoreRule)
        .length;
    if (exactEntries != 1 ||
        !gitInspector.isIgnored(repositoryRoot, evalLocalConfigRelativePath) ||
        gitInspector.isTracked(repositoryRoot, evalLocalConfigRelativePath)) {
      throw const EvalFailure('localConfigGitBoundaryInvalid');
    }
  }

  void _validateLocalFile(File file) {
    if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const EvalFailure('localConfigPathInvalid');
    }
    final String expected = p.normalize(
      p.absolute(p.join(repositoryRoot, evalLocalConfigRelativePath)),
    );
    final String resolved = p.normalize(file.resolveSymbolicLinksSync());
    if (!p.equals(expected, resolved)) {
      throw const EvalFailure('localConfigPathInvalid');
    }
    if (!Platform.isWindows && (file.statSync().mode & 0x3f) != 0) {
      throw const EvalFailure('localConfigPermissionsTooBroad');
    }
  }

  void _validateCredentialValue(String value, String field) {
    if (value.trim().isEmpty || value.contains(RegExp(r'[\r\n\x00]'))) {
      throw EvalFailure('invalid$field');
    }
  }

  void _validateBaseUrl(String value) {
    _validateCredentialValue(value, 'baseUrl');
    final Uri? uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        !<String>{'http', 'https'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const EvalFailure('invalidBaseUrl');
    }
  }

  void _validateProviderLabel(String value) {
    if (value.trim().isEmpty ||
        value.length > 80 ||
        value.contains(RegExp(r'[\r\n\x00]'))) {
      throw const EvalFailure('invalidProviderLabel');
    }
  }
}

class ScanReport {
  const ScanReport({
    required this.filesScanned,
    required this.matchesByKind,
  });

  final int filesScanned;
  final Map<String, int> matchesByKind;

  int get totalMatches =>
      matchesByKind.values.fold(0, (int sum, int count) => sum + count);

  bool get isClean => totalMatches == 0;

  Map<String, Object?> toJson() => <String, Object?>{
        'filesScanned': filesScanned,
        'totalMatches': totalMatches,
        'matchesByKind': <String, Object?>{
          for (final String key in (matchesByKind.keys.toList()..sort()))
            key: matchesByKind[key],
        },
      };
}

class SensitiveDataFilter {
  SensitiveDataFilter({Set<String> knownSensitiveValues = const <String>{}})
      : knownSensitiveValues = knownSensitiveValues
            .where((String value) => value.isNotEmpty)
            .toList()
          ..sort((String left, String right) =>
              right.length.compareTo(left.length));

  final List<String> knownSensitiveValues;

  static final Map<String, RegExp> _patterns = <String, RegExp>{
    'authorizationHeader': RegExp(
      r'authorization\s*[:=]\s*[^\r\n,}]+',
      caseSensitive: false,
    ),
    'bearerToken': RegExp(
      r'\bbearer\s+[a-z0-9._~+\-/=]{8,}',
      caseSensitive: false,
    ),
    'apiKeyField': RegExp(
      r'["\x27]?(?:api[_-]?key|token)["\x27]?\s*[:=]\s*["\x27][^"\x27\r\n]{4,}["\x27]',
      caseSensitive: false,
    ),
    'openAiStyleKey': RegExp(r'\bsk-[a-z0-9_-]{16,}\b', caseSensitive: false),
  };

  String redact(String value) {
    String result = value;
    for (final String secret in knownSensitiveValues) {
      result = result.replaceAll(secret, '[REDACTED]');
    }
    for (final RegExp pattern in _patterns.values) {
      result = result.replaceAll(pattern, '[REDACTED]');
    }
    return result;
  }

  ScanReport scanText(String value) {
    final Map<String, int> matches = <String, int>{};
    for (final String secret in knownSensitiveValues) {
      final int count = secret.isEmpty ? 0 : _literalMatchCount(value, secret);
      if (count > 0) {
        matches['knownSensitiveValue'] =
            (matches['knownSensitiveValue'] ?? 0) + count;
      }
    }
    for (final MapEntry<String, RegExp> entry in _patterns.entries) {
      final int count = entry.value.allMatches(value).length;
      if (count > 0) {
        matches[entry.key] = count;
      }
    }
    return ScanReport(filesScanned: 0, matchesByKind: matches);
  }

  ScanReport scanDirectory(Directory directory) {
    int files = 0;
    final Map<String, int> matches = <String, int>{};
    if (!directory.existsSync()) {
      return const ScanReport(filesScanned: 0, matchesByKind: <String, int>{});
    }
    for (final FileSystemEntity entity
        in directory.listSync(recursive: true, followLinks: false)) {
      if (entity is Link) {
        matches['unsafeLink'] = (matches['unsafeLink'] ?? 0) + 1;
        continue;
      }
      if (entity is! File) {
        continue;
      }
      files += 1;
      String content;
      try {
        content = entity.readAsStringSync();
      } on FileSystemException {
        matches['unreadableFile'] = (matches['unreadableFile'] ?? 0) + 1;
        continue;
      }
      final ScanReport report = scanText(content);
      for (final MapEntry<String, int> entry in report.matchesByKind.entries) {
        matches[entry.key] = (matches[entry.key] ?? 0) + entry.value;
      }
    }
    return ScanReport(filesScanned: files, matchesByKind: matches);
  }
}

int _literalMatchCount(String source, String literal) {
  int count = 0;
  int start = 0;
  while (true) {
    final int index = source.indexOf(literal, start);
    if (index < 0) {
      return count;
    }
    count += 1;
    start = index + literal.length;
  }
}

class SafeArtifactWriter {
  SafeArtifactWriter({required this.root, required this.filter});

  final Directory root;
  final SensitiveDataFilter filter;

  File writeJson(String relativePath, Map<String, Object?> value) {
    final String targetPath = _target(relativePath);
    final File target = File(targetPath);
    if (target.existsSync()) {
      throw const EvalFailure('artifactAlreadyExists');
    }
    target.parent.createSync(recursive: true);
    final String encoded =
        '${const JsonEncoder.withIndent('  ').convert(normalizeJson(value))}\n';
    final String redacted = filter.redact(encoded);
    if (!filter.scanText(redacted).isClean) {
      throw const EvalFailure('artifactRedactionFailed');
    }
    final File temporary = File('$targetPath.tmp');
    if (FileSystemEntity.typeSync(temporary.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw const EvalFailure('artifactTemporaryFileExists');
    }
    temporary.writeAsStringSync(redacted, flush: true);
    temporary.renameSync(targetPath);
    return target;
  }

  File writeMarker(String relativePath) {
    final String targetPath = _target(relativePath);
    final File target = File(targetPath);
    if (target.existsSync()) {
      throw const EvalFailure('artifactAlreadyExists');
    }
    target.parent.createSync(recursive: true);
    target.writeAsStringSync('ok\n', flush: true);
    return target;
  }

  String _target(String relativePath) {
    if (p.isAbsolute(relativePath) || relativePath.contains('..')) {
      throw const EvalFailure('artifactPathInvalid');
    }
    final String target = p.normalize(p.join(root.path, relativePath));
    if (!p.isWithin(root.path, target)) {
      throw const EvalFailure('artifactPathInvalid');
    }
    String current = root.path;
    for (final String part in p.split(p.relative(target, from: root.path))) {
      current = p.join(current, part);
      if (FileSystemEntity.typeSync(current, followLinks: false) ==
          FileSystemEntityType.link) {
        throw const EvalFailure('artifactPathContainsLink');
      }
    }
    return target;
  }
}

class SafeArtifactReader {
  SafeArtifactReader({required this.root});

  final Directory root;

  Map<String, Object?> readJson(String relativePath) {
    try {
      return decodeObject(readText(relativePath));
    } on FormatException {
      throw const EvalFailure('requiredArtifactMalformed');
    }
  }

  String readText(String relativePath) {
    final String targetPath = _target(relativePath);
    if (FileSystemEntity.typeSync(targetPath, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const EvalFailure('requiredArtifactMissingOrInvalid');
    }
    try {
      return File(targetPath).readAsStringSync();
    } on FileSystemException {
      throw const EvalFailure('requiredArtifactReadFailed');
    }
  }

  String _target(String relativePath) {
    if (p.isAbsolute(relativePath) || relativePath.contains('..')) {
      throw const EvalFailure('artifactPathInvalid');
    }
    final String normalizedRoot = p.normalize(p.absolute(root.path));
    final String target = p.normalize(p.join(normalizedRoot, relativePath));
    if (!p.isWithin(normalizedRoot, target)) {
      throw const EvalFailure('artifactPathInvalid');
    }
    String current = normalizedRoot;
    for (final String part
        in p.split(p.relative(target, from: normalizedRoot))) {
      current = p.join(current, part);
      final FileSystemEntityType type =
          FileSystemEntity.typeSync(current, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw const EvalFailure('artifactPathContainsLink');
      }
    }
    return target;
  }
}
