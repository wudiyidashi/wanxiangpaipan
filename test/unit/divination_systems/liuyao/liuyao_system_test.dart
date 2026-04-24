import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/gua.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/yao.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/fushen_service.dart';
import 'package:wanxiang_paipan/domain/services/qigua_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/liuqin_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

void main() {
  group('LiuYaoResult', () {
    test('无变卦时摘要应只返回主卦名', () {
      final result = _buildResult(mainGuaName: '天雷无妄');

      expect(result.getSummary(), '天雷无妄');
    });

    test('有变卦时摘要应包含主卦与变卦', () {
      final result = _buildResult(
        mainGuaName: '天雷无妄',
        changingGuaName: '天风姤',
      );

      expect(result.getSummary(), '天雷无妄 → 天风姤');
    });
  });

  group('LiuYaoSystem', () {
    late LiuYaoSystem system;

    setUp(() {
      system = LiuYaoSystem();
    });

    test('manual 模式必须显式提供 manualMode', () {
      expect(
        system.validateInput(
          CastMethod.manual,
          {
            'yaoNumbers': <int>[7, 8, 7, 8, 7, 8]
          },
        ),
        false,
      );
    });

    test('manual yaoNumbers 模式应通过验证', () {
      expect(
        system.validateInput(
          CastMethod.manual,
          {
            'manualMode': LiuYaoManualInputMode.yaoNumbers.id,
            'yaoNumbers': <int>[7, 8, 7, 8, 7, 8],
          },
        ),
        true,
      );
    });

    test('manual coinInputs 模式应通过验证', () {
      expect(
        system.validateInput(
          CastMethod.manual,
          {
            'manualMode': LiuYaoManualInputMode.coinInputs.id,
            'coinInputs': List<List<CoinFace>>.generate(
              6,
              (_) => <CoinFace>[CoinFace.front, CoinFace.back, CoinFace.back],
            ),
          },
        ),
        true,
      );
    });

    test('旧的 manual 输入格式应直接报错', () async {
      await expectLater(
        system.cast(
          method: CastMethod.manual,
          input: {
            'yaoNumbers': <int>[7, 8, 7, 8, 7, 8]
          },
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('castByManualYaoNumbers 应使用显式模式完成起卦', () async {
      final result = await system.castByManualYaoNumbers(
        <int>[7, 8, 7, 8, 7, 8],
        castTime: DateTime(2025, 1, 1, 8, 30),
      );

      expect(result.castMethod, CastMethod.manual);
      expect(result.mainGua.name, isNotEmpty);
    });

    test('time 起卦应匹配元亨利贞参考盘', () async {
      final result = await system.cast(
        method: CastMethod.time,
        input: const <String, dynamic>{},
        castTime: DateTime(2026, 4, 24, 11, 30),
      ) as LiuYaoResult;

      expect(result.lunarInfo.yearGanZhi, '丙午');
      expect(result.lunarInfo.monthGanZhi, '壬辰');
      expect(result.lunarInfo.riGanZhi, '戊辰');
      expect(result.lunarInfo.hourGanZhi, '戊午');
      expect(result.liuShen, <String>['勾陈', '腾蛇', '白虎', '玄武', '青龙', '朱雀']);

      expect(result.mainGua.id, '111110');
      expect(result.mainGua.name, '泽天夬');
      expect(result.mainGua.baGong, BaGong.kun);
      expect(result.mainGua.seYaoPosition, 5);
      expect(result.mainGua.yingYaoPosition, 2);
      expect(result.mainGua.movingYaos.map((yao) => yao.position), <int>[1]);
      expect(
        result.mainGua.yaos
            .map((yao) =>
                '${yao.liuQin.name}${yao.stem}${yao.branch}${yao.wuXing.name}')
            .toList(),
        <String>['妻财甲子水', '官鬼甲寅木', '兄弟甲辰土', '妻财丁亥水', '子孙丁酉金', '兄弟丁未土'],
      );
      final fuShenByPosition = FuShenService.calculateFuShen(result.mainGua);
      expect(fuShenByPosition.keys, <int>[2]);
      expect(fuShenByPosition[2]!.displayText, '父母乙巳火');

      expect(result.changingGua, isNotNull);
      expect(result.changingGua!.id, '011110');
      expect(result.changingGua!.name, '泽风大过');
      expect(result.changingGua!.baGong, BaGong.zhen);
      expect(result.changingGua!.specialType, GuaSpecialType.youHun);
      expect(result.changingGua!.seYaoPosition, 4);
      expect(result.changingGua!.yingYaoPosition, 1);
      expect(
        result.changingGua!.yaos
            .map((yao) =>
                '${yao.liuQin.name}${yao.stem}${yao.branch}${yao.wuXing.name}')
            .toList(),
        <String>['兄弟辛丑土', '妻财辛亥水', '子孙辛酉金', '妻财丁亥水', '子孙丁酉金', '兄弟丁未土'],
      );
    });

    test('time 起卦卯时应匹配元亨利贞参考盘', () async {
      final result = await system.cast(
        method: CastMethod.time,
        input: const <String, dynamic>{},
        castTime: DateTime(2026, 4, 24, 5, 30),
      ) as LiuYaoResult;

      expect(result.lunarInfo.yearGanZhi, '丙午');
      expect(result.lunarInfo.monthGanZhi, '壬辰');
      expect(result.lunarInfo.riGanZhi, '戊辰');
      expect(result.lunarInfo.hourGanZhi, '乙卯');
      expect(result.liuShen, <String>['勾陈', '腾蛇', '白虎', '玄武', '青龙', '朱雀']);

      expect(result.mainGua.id, '010110');
      expect(result.mainGua.name, '泽水困');
      expect(result.mainGua.baGong, BaGong.dui);
      expect(result.mainGua.specialType, GuaSpecialType.liuHe);
      expect(result.mainGua.seYaoPosition, 1);
      expect(result.mainGua.yingYaoPosition, 4);
      expect(result.mainGua.movingYaos.map((yao) => yao.position), <int>[4]);
      expect(
        result.mainGua.yaos
            .map((yao) =>
                '${yao.liuQin.name}${yao.stem}${yao.branch}${yao.wuXing.name}')
            .toList(),
        <String>['妻财戊寅木', '父母戊辰土', '官鬼戊午火', '子孙丁亥水', '兄弟丁酉金', '父母丁未土'],
      );
      expect(FuShenService.calculateFuShen(result.mainGua), isEmpty);

      expect(result.changingGua, isNotNull);
      expect(result.changingGua!.id, '010010');
      expect(result.changingGua!.name, '坎为水');
      expect(result.changingGua!.baGong, BaGong.kan);
      expect(result.changingGua!.specialType, GuaSpecialType.liuChong);
      expect(result.changingGua!.seYaoPosition, 6);
      expect(result.changingGua!.yingYaoPosition, 3);
      expect(
        result.changingGua!.yaos
            .map((yao) =>
                '${yao.liuQin.name}${yao.stem}${yao.branch}${yao.wuXing.name}')
            .toList(),
        <String>['妻财戊寅木', '父母戊辰土', '官鬼戊午火', '兄弟戊申金', '父母戊戌土', '子孙戊子水'],
      );
    });
  });
}

LiuYaoResult _buildResult({
  required String mainGuaName,
  String? changingGuaName,
}) {
  return LiuYaoResult(
    id: 'test-id',
    castTime: DateTime(2025, 1, 15),
    castMethod: CastMethod.coin,
    mainGua: _buildGua(mainGuaName),
    changingGua: changingGuaName == null ? null : _buildGua(changingGuaName),
    lunarInfo: const LunarInfo(
      yueJian: '寅',
      riGan: '甲',
      riZhi: '子',
      riGanZhi: '甲子',
      kongWang: <String>['戌', '亥'],
      yearGanZhi: '甲子',
      monthGanZhi: '丙寅',
    ),
    liuShen: const <String>['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武'],
  );
}

Gua _buildGua(String name) {
  final yaos = List<Yao>.generate(
    6,
    (index) => Yao(
      position: index + 1,
      number: YaoNumber.shaoYang,
      branch: '子',
      stem: '甲',
      liuQin: LiuQin.fuMu,
      wuXing: WuXing.shui,
      isSeYao: index == 4,
      isYingYao: index == 1,
    ),
  );

  return Gua(
    id: 'gua-$name',
    yaos: yaos,
    name: name,
    baGong: BaGong.qian,
    seYaoPosition: 5,
    yingYaoPosition: 2,
  );
}
