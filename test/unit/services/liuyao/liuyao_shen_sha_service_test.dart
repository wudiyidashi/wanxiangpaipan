import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/liuyao_shen_sha_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/tiangan_dizhi_service.dart';

void main() {
  group('LiuYaoShenShaService', () {
    test('甲子日：驿马寅、桃花酉、日禄寅、贵人丑未', () {
      final result = LiuYaoShenShaService.calculate(
        riGan: '甲',
        riZhi: '子',
      );

      expect(result.yiMa, '寅');
      expect(result.taoHua, '酉');
      expect(result.riLu, '寅');
      expect(result.guiRen, ['丑', '未']);
    });

    test('辛酉日：驿马亥、桃花午、日禄酉、贵人午寅', () {
      final result = LiuYaoShenShaService.calculate(
        riGan: '辛',
        riZhi: '酉',
      );

      expect(result.yiMa, '亥');
      expect(result.taoHua, '午');
      expect(result.riLu, '酉');
      expect(result.guiRen, ['午', '寅']);
    });

    test('十干、十二支均有完整映射', () {
      for (final riGan in TianGanDiZhiService.tianGan) {
        for (final riZhi in TianGanDiZhiService.diZhi) {
          final result = LiuYaoShenShaService.calculate(
            riGan: riGan,
            riZhi: riZhi,
          );
          expect(result.yiMa, isNotEmpty);
          expect(result.taoHua, isNotEmpty);
          expect(result.riLu, isNotEmpty);
          expect(result.guiRen, hasLength(2));
        }
      }
    });

    test('无效日干或日支拒绝计算', () {
      expect(
        () => LiuYaoShenShaService.calculate(riGan: '无', riZhi: '子'),
        throwsArgumentError,
      );
      expect(
        () => LiuYaoShenShaService.calculate(riGan: '甲', riZhi: '无'),
        throwsArgumentError,
      );
    });
  });
}
