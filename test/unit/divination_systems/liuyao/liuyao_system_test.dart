import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/gua.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/yao.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
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
