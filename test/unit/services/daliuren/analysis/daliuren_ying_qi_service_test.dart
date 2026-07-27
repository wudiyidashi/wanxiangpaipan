import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/san_chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/shen_sha.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/daliuren_ying_qi_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/analysis/models/verdict_models.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';

Chuan makeChuan(ChuanPosition position, String diZhi) {
  return Chuan(
    position: position,
    diZhi: diZhi,
    wuXing: WuXingService.getWuXingFromBranch(diZhi)?.name ?? '',
    chengShen: ShenJiang.guiRen,
    liuQin: '兄弟',
  );
}

SanChuan makeSanChuan(String chu, String zhong, String mo,
    {KeType keType = KeType.zeiKe}) {
  return SanChuan(
    chuChuan: makeChuan(ChuanPosition.chu, chu),
    zhongChuan: makeChuan(ChuanPosition.zhong, zhong),
    moChuan: makeChuan(ChuanPosition.mo, mo),
    keType: keType,
  );
}

const emptyShenSha = ShenShaList(allShenSha: []);

void main() {
  group('DaLiuRenYingQiService（design §5）', () {
    test('恒有发用之期与归宿之期，全为日尺度', () {
      final candidates = DaLiuRenYingQiService.calculate(
        sanChuan: makeSanChuan('寅', '午', '戌'),
        shenShaList: emptyShenSha,
        conditions: const [],
      );
      expect(candidates.map((c) => c.branch), containsAll(['寅', '戌']));
      expect(candidates.every((c) => c.scale == YingQiScale.ri), true);
      final faYong = candidates.firstWhere((c) => c.branch == '寅');
      final guiSu = candidates.firstWhere((c) => c.branch == '戌');
      expect(faYong.priority, 2);
      expect(guiSu.priority, 3);
    });

    test('末传与初传同支时去重', () {
      final candidates = DaLiuRenYingQiService.calculate(
        sanChuan: makeSanChuan('巳', '丑', '巳'),
        shenShaList: emptyShenSha,
        conditions: const [],
      );
      expect(candidates.where((c) => c.branch == '巳'), hasLength(1));
    });

    test('空亡悬置 → 填实候选 priority=1 且与条件地支衔接', () {
      final candidates = DaLiuRenYingQiService.calculate(
        sanChuan: makeSanChuan('寅', '午', '戌'),
        shenShaList: emptyShenSha,
        conditions: const [
          VerdictCondition(label: '待发用填实', branch: '寅', reason: '初传寅落空'),
        ],
      );
      final tianShi = candidates.firstWhere((c) => c.priority == 1);
      expect(tianShi.branch, '寅');
      expect(candidates.first.priority, 1, reason: '按 priority 排序');
    });

    test('驿马命中三传 → 马支值日候选', () {
      const yiMa = ShenSha(
        name: '驿马',
        type: ShenShaType.ji,
        diZhi: '寅',
        description: '驿马星，主动、出行、变迁',
      );
      final candidates = DaLiuRenYingQiService.calculate(
        sanChuan: makeSanChuan('寅', '午', '戌'),
        shenShaList: const ShenShaList(allShenSha: [yiMa]),
        conditions: const [],
      );
      final maYing = candidates.firstWhere((c) => c.label.contains('驿马'));
      expect(maYing.branch, '寅');
      expect(maYing.priority, 2);
    });

    test('伏吟 → 初传冲支值日候选', () {
      final candidates = DaLiuRenYingQiService.calculate(
        sanChuan: makeSanChuan('亥', '未', '丑', keType: KeType.fuYin),
        shenShaList: emptyShenSha,
        conditions: const [],
      );
      final chongYing = candidates.firstWhere((c) => c.label.contains('伏吟'));
      expect(chongYing.branch, '巳', reason: '亥之冲为巳');
    });
  });
}
