import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/output/formatters/meihua_formatter.dart';
import 'package:wanxiang_paipan/divination_systems/meihua/meihua_system.dart';
import 'package:wanxiang_paipan/divination_systems/meihua/models/meihua_result.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

void main() {
  group('MeiHuaStructuredFormatter', () {
    late MeiHuaSystem system;
    late MeiHuaStructuredFormatter formatter;

    setUp(() {
      system = MeiHuaSystem();
      formatter = MeiHuaStructuredFormatter();
    });

    test('时间起卦：按 meihua.md §11.3 校盘样例渲染', () async {
      final result = await system.cast(
        method: CastMethod.time,
        input: const {},
        castTime: DateTime(2026, 4, 19, 9, 22),
      ) as MeiHuaResult;

      final output = formatter.format(result, question: '问近期事业');
      final rendered = formatter.render(output);

      // 标题与摘要
      expect(rendered, startsWith('【梅花易数完整结构化排盘】'));
      expect(output.summary, '风火家人 → 风山渐 · 体生用');

      // 一、排盘总览
      expect(rendered, contains('一、排盘总览'));
      expect(rendered, contains('- 起卦：2026-04-19 09:22（农历三月初三）'));
      expect(rendered, contains('- 方式：时间起卦'));
      expect(rendered, contains('- 四柱：丙午年 壬辰月 癸亥日 丁巳时'));
      expect(rendered, contains('- 本卦：风火家人'));
      expect(rendered, contains('- 变卦：风山渐'));
      expect(rendered, contains('- 互卦：火水未济'));
      expect(rendered, contains('- 动爻：初爻'));
      expect(rendered, contains('- 体卦：巽'));
      expect(rendered, contains('- 用卦：离'));
      expect(rendered, contains('- 体用关系：体生用'));

      // 二、起卦依据（时间）
      expect(rendered, contains('二、起卦依据'));
      expect(rendered, contains('- 年支：午，数7'));
      expect(rendered, contains('- 月数：3'));
      expect(rendered, contains('- 日数：3'));
      expect(rendered, contains('- 时支：巳，数6'));
      expect(rendered, contains('- 上卦数：5 -> 巽'));
      expect(rendered, contains('- 下卦数：3 -> 离'));
      expect(rendered, contains('- 动爻数：1 -> 初爻'));

      // 三、卦象结构
      expect(rendered, contains('三、卦象结构'));
      expect(rendered, contains('- 本卦：上巽下离，风火家人'));
      expect(rendered, contains('- 变卦：上巽下艮，风山渐'));
      expect(rendered, contains('- 互卦：上离下坎，火水未济'));

      // 四、体用与五行
      expect(rendered, contains('四、体用与五行'));
      expect(rendered, contains('- 动爻落下卦，故上卦为体（巽），下卦为用（离）'));
      expect(rendered, contains('- 体卦：巽，木'));
      expect(rendered, contains('- 用卦：离，火'));
      expect(rendered, contains('- 关系：体生用'));

      // 占断不在结构化输出里
      expect(rendered, isNot(contains('五、占断')));
      expect(rendered, isNot(contains('结论：')));

      // 第一版不混入六爻概念
      const sixSpirits = ['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武'];
      for (final spirit in sixSpirits) {
        expect(rendered, isNot(contains(spirit)));
      }
      expect(rendered, isNot(contains('妻财')));
      expect(rendered, isNot(contains('官鬼')));
      expect(rendered, isNot(contains('世爻')));
      expect(rendered, isNot(contains('应爻')));
      expect(rendered, isNot(contains('纳甲')));
      expect(rendered, isNot(contains('六亲')));
    });

    test('数字起卦：起卦依据应显示上下数与取数过程', () async {
      final result = await system.cast(
        method: CastMethod.number,
        input: const {'upperNumber': 7, 'lowerNumber': 3},
        castTime: DateTime(2026, 4, 19, 9, 22),
      ) as MeiHuaResult;

      final rendered = formatter.render(formatter.format(result));

      expect(rendered, contains('- 方式：数字起卦'));
      expect(rendered, contains('- 上数：7'));
      expect(rendered, contains('- 下数：3'));
      expect(rendered, contains('- 上卦数：7 % 8 = 7 -> 艮'));
      expect(rendered, contains('- 下卦数：3 % 8 = 3 -> 离'));
      expect(rendered, contains('- 动爻数：10 % 6 = 4 -> 四爻'));
    });

    test('手动起卦：起卦依据应显示手动指定的卦与动爻', () async {
      final result = await system.cast(
        method: CastMethod.manual,
        input: const {
          'upperTrigram': '艮',
          'lowerTrigram': '离',
          'movingLine': 2,
        },
        castTime: DateTime(2026, 4, 19, 9, 22),
      ) as MeiHuaResult;

      final rendered = formatter.render(formatter.format(result));

      expect(rendered, contains('- 方式：手动输入'));
      expect(rendered, contains('- 上卦：艮'));
      expect(rendered, contains('- 下卦：离'));
      expect(rendered, contains('- 动爻：二爻'));
      expect(rendered, contains('- 来源：手动指定'));
      // 手动模式下 山火贲 动二爻，下卦为用
      expect(rendered, contains('- 动爻落下卦，故上卦为体（艮），下卦为用（离）'));
      expect(rendered, contains('- 关系：用生体'));
    });
  });
}
