import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'canonical_json.dart';
import 'constants.dart';
import 'security.dart';

class HoldoutMember {
  const HoldoutMember({required this.caseId, required this.selectionHash});

  final String caseId;
  final String selectionHash;

  Map<String, Object?> toJson() => <String, Object?>{
        'caseId': caseId,
        'selectionHash': selectionHash,
      };
}

class HoldoutSelection {
  const HoldoutSelection({required this.members, required this.cohortHash});

  final List<HoldoutMember> members;
  final String cohortHash;

  Map<String, Object?> toJson() => <String, Object?>{
        'selectionSalt': holdoutSelectionSalt,
        'members': members
            .map((HoldoutMember member) => member.toJson())
            .toList(growable: false),
        'cohortHash': cohortHash,
      };
}

HoldoutSelection selectHoldout(Iterable<String> originalBookCaseIds) {
  final Set<String> unique = originalBookCaseIds.toSet();
  if (unique.length < 6 ||
      unique.any((String caseId) => caseId.trim().isEmpty)) {
    throw const EvalFailure('insufficientOriginalBookCasesForHoldout');
  }
  final List<HoldoutMember> ranked = unique
      .map(
        (String caseId) => HoldoutMember(
          caseId: caseId,
          selectionHash: sha256Text('$holdoutSelectionSalt\n$caseId'),
        ),
      )
      .toList();
  ranked.sort((HoldoutMember left, HoldoutMember right) {
    final int hashOrder = left.selectionHash.compareTo(right.selectionHash);
    return hashOrder != 0 ? hashOrder : left.caseId.compareTo(right.caseId);
  });
  final List<HoldoutMember> members = ranked.take(6).toList(growable: false);
  return HoldoutSelection(
    members: List<HoldoutMember>.unmodifiable(members),
    cohortHash: sha256Json(
      members.map((HoldoutMember member) => member.toJson()).toList(),
    ),
  );
}

void validateFrozenHoldout({
  required Iterable<String> originalBookCaseIds,
  required List<String> memberIds,
  required List<String> selectionHashes,
  required String cohortHash,
}) {
  final HoldoutSelection computed = selectHoldout(originalBookCaseIds);
  if (memberIds.length != 6 ||
      selectionHashes.length != 6 ||
      !_listEquals(
        memberIds,
        computed.members.map((HoldoutMember member) => member.caseId).toList(),
      ) ||
      !_listEquals(
        selectionHashes,
        computed.members
            .map((HoldoutMember member) => member.selectionHash)
            .toList(),
      ) ||
      cohortHash != computed.cohortHash) {
    throw const EvalFailure('frozenHoldoutSelectionMismatch');
  }
}

class HoldoutRevealStore {
  HoldoutRevealStore({required this.outputRoot});

  final Directory outputRoot;

  File reveal({
    required String runId,
    required String candidateHash,
    required String cohortHash,
    DateTime? revealedAtUtc,
  }) {
    _validateRevealIdentity(
      runId: runId,
      candidateHash: candidateHash,
      cohortHash: cohortHash,
    );
    final DateTime revealTime = revealedAtUtc ?? DateTime.now().toUtc();
    if (!revealTime.isUtc) {
      throw const EvalFailure('invalidHoldoutRevealTimestamp');
    }
    final Directory markerDirectory =
        Directory(p.join(outputRoot.path, '_holdout_reveals'));
    if (FileSystemEntity.typeSync(markerDirectory.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const EvalFailure('holdoutRevealDirectoryIsLink');
    }
    markerDirectory.createSync(recursive: true);
    final File marker = File(p.join(markerDirectory.path, '$cohortHash.json'));
    if (marker.existsSync()) {
      try {
        validateReveal(
          runId: runId,
          candidateHash: candidateHash,
          cohortHash: cohortHash,
        );
        return marker;
      } on EvalFailure {
        throw const EvalFailure('holdoutAlreadyRevealedRegressionOnly');
      }
    }
    final Map<String, Object?> document = <String, Object?>{
      'schemaVersion': 'liuyao-holdout-reveal/1.0.0',
      'candidateHash': candidateHash,
      'runId': runId,
      'revealedAtUtc': revealTime.toIso8601String(),
      'cohortHash': cohortHash,
    };
    try {
      marker.createSync(exclusive: true);
      marker.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(normalizeJson(document))}\n',
        flush: true,
      );
      return marker;
    } on FileSystemException {
      throw const EvalFailure('holdoutRevealWriteFailed');
    }
  }

  bool isRevealed(String cohortHash) {
    _validateRevealHash(cohortHash);
    return File(
      p.join(outputRoot.path, '_holdout_reveals', '$cohortHash.json'),
    ).existsSync();
  }

  void validateReveal({
    required String runId,
    required String candidateHash,
    required String cohortHash,
  }) {
    _validateRevealIdentity(
      runId: runId,
      candidateHash: candidateHash,
      cohortHash: cohortHash,
    );
    final Directory markerDirectory =
        Directory(p.join(outputRoot.path, '_holdout_reveals'));
    if (FileSystemEntity.typeSync(markerDirectory.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw const EvalFailure('holdoutRevealDirectoryMissingOrInvalid');
    }
    final File marker = File(p.join(markerDirectory.path, '$cohortHash.json'));
    if (FileSystemEntity.typeSync(marker.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const EvalFailure('holdoutRevealMarkerMissingOrInvalid');
    }
    try {
      final Map<String, Object?> document =
          decodeObject(marker.readAsStringSync());
      requireExactKeys(
        document,
        <String>{
          'schemaVersion',
          'candidateHash',
          'runId',
          'revealedAtUtc',
          'cohortHash',
        },
      );
      final DateTime? revealedAt =
          DateTime.tryParse(requireString(document, 'revealedAtUtc'));
      if (requireString(document, 'schemaVersion') !=
              'liuyao-holdout-reveal/1.0.0' ||
          requireString(document, 'candidateHash') != candidateHash ||
          requireString(document, 'runId') != runId ||
          requireString(document, 'cohortHash') != cohortHash ||
          revealedAt == null ||
          !revealedAt.isUtc) {
        throw const EvalFailure('holdoutRevealMarkerMismatch');
      }
    } on FormatException {
      throw const EvalFailure('holdoutRevealMarkerInvalid');
    } on FileSystemException {
      throw const EvalFailure('holdoutRevealMarkerReadFailed');
    }
  }
}

bool _isHash(String value) => RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

void _validateRevealIdentity({
  required String runId,
  required String candidateHash,
  required String cohortHash,
}) {
  validateRunId(runId);
  _validateRevealHash(candidateHash);
  _validateRevealHash(cohortHash);
}

void _validateRevealHash(String value) {
  if (!_isHash(value)) {
    throw const EvalFailure('invalidHoldoutRevealHash');
  }
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
