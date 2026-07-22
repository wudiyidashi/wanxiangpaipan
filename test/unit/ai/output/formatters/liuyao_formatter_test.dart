import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/output/formatters/liuyao_formatter.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

void main() {
  test('动爻输出应读取变卦对应爻的完整纳甲', () async {
    final result = await LiuYaoSystem().cast(
      method: CastMethod.time,
      input: const <String, dynamic>{},
      castTime: DateTime(2026, 4, 24, 5, 30),
    ) as LiuYaoResult;
    final formatter = LiuYaoStructuredFormatter();

    final rendered = formatter.render(formatter.format(result));

    expect(
      rendered,
      contains('四爻动: 子孙丁亥(水) → 兄弟戊申(金)'),
    );
    expect(rendered, isNot(contains('子孙丁亥(水) → 亥')));
  });
}
