import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/qigua_service.dart';

void main() {
  final system = LiuYaoSystem();

  group('QiGuaService.guaNameCast 动爻反推', () {
    test('需(111010)变大过(011110)：初爻四爻动', () {
      final numbers = QiGuaService.guaNameCast('111010', '011110');
      expect(numbers, [9, 7, 7, 6, 7, 8]);
    });

    test('无变卦全静', () {
      expect(QiGuaService.guaNameCast('111111', null), [7, 7, 7, 7, 7, 7]);
    });

    test('变卦同本卦视为全静', () {
      expect(QiGuaService.guaNameCast('101010', '101010'), [7, 8, 7, 8, 7, 8]);
    });

    test('非法卦 id 抛参数错误', () {
      expect(
          () => QiGuaService.guaNameCast('11101', null), throwsArgumentError);
      expect(() => QiGuaService.guaNameCast('111010', '11x010'),
          throwsArgumentError);
    });
  });

  group('LiuYaoSystem 卦名卦', () {
    test('巳月乙亥日 需变大过：卦名、动爻、月建、空亡俱正确', () async {
      final result = await system.castByGuaName(
        benGuaId: '111010',
        bianGuaId: '011110',
        yueJian: '巳',
        riGanZhi: '乙亥',
      );

      expect(result.mainGua.name, contains('需'));
      expect(result.changingGua, isNotNull);
      expect(result.changingGua!.name, contains('大过'));
      expect(result.movingYaos.map((y) => y.position), [1, 4]);
      expect(result.lunarInfo.yueJian, '巳');
      expect(result.lunarInfo.riGanZhi, '乙亥');
      expect(result.lunarInfo.riGan, '乙');
      expect(result.lunarInfo.riZhi, '亥');
      // 乙亥在甲戌旬，空申酉
      expect(result.lunarInfo.kongWang, ['申', '酉']);
      // 月干支置为月建支保证「巳月」显示一致
      expect(result.lunarInfo.monthGanZhi, '巳');
      expect(result.lunarInfo.hourGanZhi, isNull);
      expect(result.castMethod, CastMethod.guaName);
    });

    test('给定年时干支时覆盖农历信息', () async {
      final result = await system.castByGuaName(
        benGuaId: '111010',
        yueJian: '巳',
        riGanZhi: '乙亥',
        yearGanZhi: '庚辰',
        hourGanZhi: '丁丑',
      );
      expect(result.lunarInfo.yearGanZhi, '庚辰');
      expect(result.lunarInfo.hourGanZhi, '丁丑');
      expect(result.calendarInputMode, LiuYaoCalendarInputMode.providedGanZhi);
    });

    test('阳历模式保存所选时间并校验完整四柱', () async {
      final castTime = DateTime(2026, 2, 28, 8);
      final result = await system.castByGuaName(
        benGuaId: '001000',
        bianGuaId: '101001',
        yueJian: '庚寅',
        riGanZhi: '癸酉',
        yearGanZhi: '丙午',
        hourGanZhi: '丙辰',
        castTime: castTime,
        calendarInputMode: LiuYaoCalendarInputMode.providedSolar,
      );

      expect(result.castTime, castTime);
      expect(result.lunarInfo.yearGanZhi, '丙午');
      expect(result.lunarInfo.monthGanZhi, '庚寅');
      expect(result.lunarInfo.riGanZhi, '癸酉');
      expect(result.lunarInfo.yueJian, '寅');
      expect(result.lunarInfo.kongWang, ['戌', '亥']);
      expect(result.calendarInputMode, LiuYaoCalendarInputMode.providedSolar);
    });

    test('阳历模式拒绝 7 月记录时间与 2 月四柱错配', () async {
      await expectLater(
        system.castByGuaName(
          benGuaId: '001000',
          bianGuaId: '101001',
          yueJian: '庚寅',
          riGanZhi: '癸酉',
          yearGanZhi: '丙午',
          hourGanZhi: '丙辰',
          castTime: DateTime(2026, 7, 31, 8),
          calendarInputMode: LiuYaoCalendarInputMode.providedSolar,
        ),
        throwsArgumentError,
      );
    });

    for (final invalidMode in <LiuYaoCalendarInputMode>[
      LiuYaoCalendarInputMode.derivedFromCastTime,
      LiuYaoCalendarInputMode.userOverride,
      LiuYaoCalendarInputMode.legacyUnknown,
    ]) {
      test('卦名卦拒绝伪造历法来源 ${invalidMode.name}', () async {
        await expectLater(
          system.castByGuaName(
            benGuaId: '001000',
            yueJian: '寅',
            riGanZhi: '癸酉',
            calendarInputMode: invalidMode,
          ),
          throwsArgumentError,
        );
      });
    }

    test('完整月干支：月建取支、月干支保留', () async {
      final result = await system.cast(
        method: CastMethod.guaName,
        input: {
          'benGuaId': '111010',
          'monthGanZhi': '己巳',
          'riGanZhi': '乙亥',
        },
      ) as dynamic;
      expect(result.lunarInfo.yueJian, '巳');
      expect(result.lunarInfo.monthGanZhi, '己巳');
    });

    test('无变卦：六爻安静', () async {
      final result = await system.castByGuaName(
        benGuaId: '111111',
        yueJian: '午',
        riGanZhi: '甲子',
      );
      expect(result.hasMovingYao, isFalse);
      expect(result.changingGua, isNull);
    });

    test('校验：非法输入被拒', () {
      expect(
        system.validateInput(CastMethod.guaName, {
          'benGuaId': '111010',
          'yueJian': '巳',
          'riGanZhi': '乙亥',
        }),
        isTrue,
      );
      expect(
        system.validateInput(CastMethod.guaName, {
          'benGuaId': 'abcdef',
          'yueJian': '巳',
          'riGanZhi': '乙亥',
        }),
        isFalse,
      );
      expect(
        system.validateInput(CastMethod.guaName, {
          'benGuaId': '111010',
          'yueJian': '猫',
          'riGanZhi': '乙亥',
        }),
        isFalse,
      );
      expect(
        system.validateInput(CastMethod.guaName, {
          'benGuaId': '111010',
          'yueJian': '巳',
          'riGanZhi': '乙子',
        }),
        isFalse,
      );
    });
  });
}
