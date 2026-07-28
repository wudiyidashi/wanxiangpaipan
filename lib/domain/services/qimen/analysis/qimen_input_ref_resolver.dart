import 'dart:convert';

import '../../../../divination_systems/qimen/models/qimen_result.dart';
import 'models/qimen_rule_models.dart';

class QimenInputPath {
  QimenInputPath._();

  static String palace(int number, String field) =>
      '\$.palaces[number=$number].$field';
}

class QimenInputRefResolver {
  QimenInputRefResolver._();

  static final RegExp _palaceSelector = RegExp(r'^palaces\[number=([1-9])\]$');

  static String? resolve(QimenResult result, String path) {
    if (!path.startsWith(r'$.')) return null;

    dynamic value = result.toJson();
    for (final segment in path.substring(2).split('.')) {
      final palaceMatch = _palaceSelector.firstMatch(segment);
      if (palaceMatch != null) {
        if (value is! Map || value['palaces'] is! List) return null;
        final number = int.parse(palaceMatch.group(1)!);
        final matches = (value['palaces'] as List).where((entry) {
          return entry is Map && entry['number'] == number;
        }).toList(growable: false);
        if (matches.length != 1) return null;
        value = matches.single;
        continue;
      }
      if (value is! Map || !value.containsKey(segment)) return null;
      value = value[segment];
    }
    return _normalize(value);
  }

  static bool matches(QimenResult result, QimenInputRef ref) =>
      resolve(result, ref.path) == ref.value;

  static String _normalize(dynamic value) {
    if (value == null) return 'null';
    if (value is List) {
      return value.map(_normalize).join(',');
    }
    if (value is Map) return jsonEncode(value);
    return value.toString();
  }
}
