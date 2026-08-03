import 'dart:convert';

import 'package:wanxiang_paipan/ai/output/formatters/liuyao_formatter.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';

Future<void> main() async {
  final result = await LiuYaoSystem().castByManualYaoNumbers(
    const <int>[8, 8, 6, 7, 8, 6],
    castTime: DateTime(2026, 2, 28, 8),
  );
  final formatter = LiuYaoStructuredFormatter();

  print('main=${result.mainGua.name}');
  print('changing=${result.changingGua?.name}');
  print('calendar=${result.lunarInfo.toJson()}');
  _printProjection('unselected', formatter, result);

  for (var position = 1; position <= 6; position += 1) {
    _printProjection(
      'main-$position',
      formatter,
      result.copyWith(
        yongShenPosition: position,
        yongShenIsFuShen: false,
      ),
    );
  }

  for (var position = 1; position <= 6; position += 1) {
    try {
      _printProjection(
        'hidden-$position',
        formatter,
        result.copyWith(
          yongShenPosition: position,
          yongShenIsFuShen: true,
        ),
      );
    } on Object catch (error) {
      print('hidden-$position error=${error.runtimeType}');
    }
  }
}

void _printProjection(
  String label,
  LiuYaoStructuredFormatter formatter,
  LiuYaoResult result,
) {
  final output = formatter.format(result, question: '租房是否顺利');
  final section = output.sections.singleWhere(
    (candidate) => candidate.key == 'analysis',
  );
  final projection =
      (section.metadata!['projection']! as Map).cast<String, Object?>();
  final useSpirit = (projection['useSpirit']! as Map).cast<String, Object?>();
  final verdict = projection['verdict'];
  final hiddenActors = (projection['actorAvailability']! as List<Object?>)
      .cast<Map>()
      .map((item) => item.cast<String, Object?>())
      .map((item) => (item['actor']! as Map).cast<String, Object?>())
      .where((actor) => actor['kind'] == 'hiddenYao')
      .toList();
  print('$label useSpirit=${jsonEncode(useSpirit)}');
  print('$label verdict=${jsonEncode(verdict)}');
  if (label == 'main-1' || label == 'main-6' || label == 'hidden-1') {
    print(
        '$label selectedFacts=${jsonEncode(projection['selectedUseSpiritFacts'])}');
    print('$label factors=${jsonEncode(projection['factors'])}');
    print('$label conditions=${jsonEncode(projection['conditions'])}');
    print('$label timing=${jsonEncode(projection['timingCandidates'])}');
    print('$label roles=${jsonEncode(projection['roles'])}');
    print('$label effects=${jsonEncode(projection['directedEffects'])}');
    print('$label auxiliary=${jsonEncode(projection['auxiliaryEvidence'])}');
  }
  if (label == 'unselected') {
    print('$label hiddenActors=${jsonEncode(hiddenActors)}');
    print('$label auxiliary=${jsonEncode(projection['auxiliaryEvidence'])}');
  }
}
