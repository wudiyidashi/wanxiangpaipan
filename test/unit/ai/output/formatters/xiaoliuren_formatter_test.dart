import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/output/formatters/xiaoliuren_formatter.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/models/xiaoliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/xiaoliuren_system.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

void main() {
  group('XiaoLiuRenStructuredFormatter', () {
    late XiaoLiuRenSystem system;
    late XiaoLiuRenStructuredFormatter formatter;

    setUp(() {
      system = XiaoLiuRenSystem();
      formatter = XiaoLiuRenStructuredFormatter();
    });

    test('时间起六宫：按 xiaoliuren.md §12.1 校盘样例渲染', () async {
      final result = await system.cast(
        method: CastMethod.time,
        input: const {},
        castTime: DateTime(2026, 4, 19, 9, 22),
      ) as XiaoLiuRenResult;

      final output = formatter.format(result, question: '问近期事业');
      final rendered = formatter.render(output);

      expect(rendered, startsWith('【小六壬完整结构化排盘】'));
      expect(output.summary, '赤口 · 口舌是非');

      // 一、排盘总览
      expect(rendered, contains('一、排盘总览'));
      expect(rendered, contains('- 起课：2026-04-19 09:22（农历三月初三）'));
      expect(rendered, contains('- 方式：时间起课'));
      expect(rendered, contains('- 盘式：六宫'));
      expect(rendered, contains('- 四柱：丙午年 壬辰月 癸亥日 丁巳时'));
      expect(rendered, contains('- 第一段：月数 3 -> 速喜'));
      expect(rendered, contains('- 第二段：日数 3 -> 小吉'));
      expect(rendered, contains('- 第三段：时数 6 -> 赤口'));
      expect(rendered, contains('- 最终落宫：赤口（凶）'));
      expect(rendered, contains('- 关键词：口舌是非'));

      // 二、起课依据
      expect(rendered, contains('二、起课依据'));
      expect(rendered, contains('- 月数：3'));
      expect(rendered, contains('- 日数：3'));
      expect(rendered, contains('- 时数：6'));
      expect(rendered, contains('- 时支：巳'));

      // 三、三段顺推
      expect(rendered, contains('三、三段顺推'));
      expect(rendered, contains('- 第一段：月数 3 从大安起 -> 速喜'));
      expect(rendered, contains('- 第二段：日数 3 从速喜推 -> 小吉'));
      expect(rendered, contains('- 第三段：时数 6 从小吉推 -> 赤口'));

      // 四、最终落宫
      expect(rendered, contains('四、最终落宫'));
      expect(rendered, contains('- 宫位：赤口（凶）'));
      expect(rendered, contains('- 关键词：口舌是非'));
      expect(rendered, contains('- 五行：金'));
      expect(rendered, contains('- 方位：西方'));

      // 占断不在结构化输出里
      expect(rendered, isNot(contains('占断')));
      expect(rendered, isNot(contains('结论：')));

      // 第一版不混入六爻概念
      const sixSpirits = ['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武'];
      for (final spirit in sixSpirits) {
        expect(rendered, isNot(contains(spirit)));
      }
      expect(rendered, isNot(contains('妻财')));
      expect(rendered, isNot(contains('官鬼')));
      expect(rendered, isNot(contains('世爻')));
      expect(rendered, isNot(contains('纳甲')));
    });

    test('报数起六宫：按 xiaoliuren.md §12.2 校盘样例渲染', () async {
      final result = await system.cast(
        method: CastMethod.reportNumber,
        input: const {
          'firstNumber': 4,
          'secondNumber': 18,
          'thirdNumber': 7,
        },
        castTime: DateTime(2026, 4, 19, 9, 22),
      ) as XiaoLiuRenResult;

      final rendered = formatter.render(formatter.format(result));

      expect(rendered, contains('- 方式：报数起课'));
      expect(rendered, contains('- 盘式：六宫'));
      expect(rendered, contains('- 第一段：数一 4 -> 赤口'));
      expect(rendered, contains('- 第二段：数二 18 -> 速喜'));
      expect(rendered, contains('- 第三段：数三 7 -> 速喜'));
      expect(rendered, contains('- 最终落宫：速喜（吉）'));
    });

    test('时间起九宫：按 xiaoliuren.md §12.3 校盘样例渲染', () async {
      final result = await system.cast(
        method: CastMethod.time,
        input: const {'palaceMode': 'ninePalaces'},
        castTime: DateTime(2026, 4, 19, 9, 22),
      ) as XiaoLiuRenResult;

      final output = formatter.format(result);
      final rendered = formatter.render(output);

      expect(output.summary, '大安 · 诸事安稳');
      expect(rendered, contains('- 盘式：九宫'));
      expect(rendered, contains('- 第一段：月数 3 -> 速喜'));
      expect(rendered, contains('- 第二段：日数 3 -> 小吉'));
      expect(rendered, contains('- 第三段：时数 6 -> 大安'));
      expect(rendered, contains('- 最终落宫：大安（吉）'));
    });

    test('汉字笔画起课：起课依据应显示三段笔画', () async {
      final result = await system.cast(
        method: CastMethod.characterStroke,
        input: const {
          'firstStroke': 8,
          'secondStroke': 11,
          'thirdStroke': 6,
        },
        castTime: DateTime(2026, 4, 19, 9, 22),
      ) as XiaoLiuRenResult;

      final rendered = formatter.render(formatter.format(result));

      expect(rendered, contains('- 方式：汉字笔画起'));
      expect(rendered, contains('- 首字笔画：8'));
      expect(rendered, contains('- 次字笔画：11'));
      expect(rendered, contains('- 末字笔画：6'));
      expect(rendered, contains('- 第一段：首字笔画 8 从大安起 ->'));
    });
  });
}
