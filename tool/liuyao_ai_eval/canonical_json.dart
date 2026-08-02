import 'dart:convert';

import 'package:crypto/crypto.dart';

Object? normalizeJson(Object? value) {
  if (value is Map) {
    final Map<String, Object?> object = value.cast<String, Object?>();
    final List<String> keys = object.keys.toList()..sort();
    return <String, Object?>{
      for (final String key in keys) key: normalizeJson(object[key]),
    };
  }
  if (value is List) {
    return value.map(normalizeJson).toList(growable: false);
  }
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  throw FormatException('Unsupported canonical JSON value type.');
}

String canonicalJson(Object? value) => jsonEncode(normalizeJson(value));

String sha256Text(String value) =>
    sha256.convert(utf8.encode(value)).toString();

String sha256Json(Object? value) => sha256Text(canonicalJson(value));

Map<String, Object?> decodeObject(String source) {
  final Object? decoded = jsonDecode(source);
  if (decoded is! Map) {
    throw const FormatException('Expected a JSON object.');
  }
  return decoded.cast<String, Object?>();
}

void requireExactKeys(
  Map<String, Object?> value,
  Set<String> required, {
  Set<String> optional = const <String>{},
}) {
  final Set<String> actual = value.keys.toSet();
  final Set<String> missing = required.difference(actual);
  final Set<String> unknown =
      actual.difference(<String>{...required, ...optional});
  if (missing.isNotEmpty || unknown.isNotEmpty) {
    throw const FormatException('JSON object keys do not match the contract.');
  }
}

String requireString(
  Map<String, Object?> value,
  String key, {
  bool allowEmpty = false,
}) {
  final Object? raw = value[key];
  if (raw is! String || (!allowEmpty && raw.trim().isEmpty)) {
    throw const FormatException('Expected a non-empty string.');
  }
  return raw;
}

int requireInt(Map<String, Object?> value, String key, {int? minimum}) {
  final Object? raw = value[key];
  if (raw is! int || (minimum != null && raw < minimum)) {
    throw const FormatException('Expected an integer in the allowed range.');
  }
  return raw;
}

bool requireBool(Map<String, Object?> value, String key) {
  final Object? raw = value[key];
  if (raw is! bool) {
    throw const FormatException('Expected a boolean.');
  }
  return raw;
}

List<Object?> requireList(Map<String, Object?> value, String key) {
  final Object? raw = value[key];
  if (raw is! List) {
    throw const FormatException('Expected a JSON array.');
  }
  return raw.cast<Object?>();
}

Map<String, Object?> requireObject(Map<String, Object?> value, String key) {
  final Object? raw = value[key];
  if (raw is! Map) {
    throw const FormatException('Expected a JSON object.');
  }
  return raw.cast<String, Object?>();
}

List<String> requireStringList(Map<String, Object?> value, String key) {
  final List<Object?> raw = requireList(value, key);
  if (raw.any((Object? item) => item is! String || item.trim().isEmpty)) {
    throw const FormatException('Expected a non-empty string array.');
  }
  return raw.cast<String>();
}
