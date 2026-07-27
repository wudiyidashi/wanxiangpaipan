import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/san_chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/si_ke.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/san_chuan_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/si_ke_service.dart';

/// 由位移 s 构造天盘映射（天盘支 = 地盘支 + s，mod 12，子=0…亥=11）
Map<String, String> buildTianPanMap(int s) {
  const diZhi = DaLiuRenConstants.diZhi;
  return {
    for (var i = 0; i < 12; i++) diZhi[i]: diZhi[(i + s + 12) % 12],
  };
}

/// 直调服务：排四课 + 推三传
({SiKe siKe, SanChuan sanChuan}) run(String riGan, String riZhi, int s) {
  final tianPanMap = buildTianPanMap(s);
  final siKe = SiKeService.arrangeSiKe(
    riGan: riGan,
    riZhi: riZhi,
    tianPanMap: tianPanMap,
  );
  final sanChuan = SanChuanService.deriveSanChuan(
    siKe: siKe,
    tianPanMap: tianPanMap,
  );
  return (siKe: siKe, sanChuan: sanChuan);
}

void expectSanChuan(SanChuan sanChuan, String chu, String zhong, String mo) {
  expect(sanChuan.chuChuan.diZhi, chu, reason: '初传');
  expect(sanChuan.zhongChuan.diZhi, zhong, reason: '中传');
  expect(sanChuan.moChuan.diZhi, mo, reason: '末传');
}

void expectKe(SiKe siKe, List<String> shangList, List<String> xiaList) {
  final allKe = siKe.allKe;
  for (var i = 0; i < 4; i++) {
    expect(allKe[i].shangShen, shangList[i], reason: '第${i + 1}课上神');
    expect(allKe[i].xiaShen, xiaList[i], reason: '第${i + 1}课下神');
  }
}

void main() {
  group('黄金课例（design.md §5，共 13 例）', () {
    test('K 戊子 s=+4：元首（单一上克下，无下贼上）→ 辰申子', () {
      final r = run('戊', '子', 4);
      expectKe(r.siKe, ['酉', '丑', '辰', '申'], ['戊', '酉', '子', '辰']);
      expect(r.sanChuan.keType, KeType.zeiKe);
      expectSanChuan(r.sanChuan, '辰', '申', '子');
      expect(r.sanChuan.keTypeExplanation, contains('元首'));
    });

    test('B 甲子 s=+1：重审（下贼上优先于两处上克下）→ 辰巳午', () {
      final r = run('甲', '子', 1);
      expectKe(r.siKe, ['卯', '辰', '丑', '寅'], ['甲', '卯', '子', '丑']);
      expect(r.sanChuan.keType, KeType.zeiKe);
      expectSanChuan(r.sanChuan, '辰', '巳', '午');
      expect(r.sanChuan.keTypeExplanation, contains('下贼上'));
    });

    test('A 庚午 s=+5：知一（两上克下，庚阳取辰）→ 辰酉寅', () {
      final r = run('庚', '午', 5);
      expectKe(r.siKe, ['丑', '午', '亥', '辰'], ['庚', '丑', '午', '亥']);
      expect(r.sanChuan.keType, KeType.biYong);
      expectSanChuan(r.sanChuan, '辰', '酉', '寅');
      expect(r.sanChuan.keTypeExplanation, contains('知一'));
    });

    test('C 丁卯 s=+4：涉害（未2害 vs 亥3害，取深者亥）→ 亥卯未', () {
      final r = run('丁', '卯', 4);
      expectKe(r.siKe, ['亥', '卯', '未', '亥'], ['丁', '亥', '卯', '未']);
      expect(r.sanChuan.keType, KeType.sheHai);
      expectSanChuan(r.sanChuan, '亥', '卯', '未');
      expect(r.sanChuan.keTypeExplanation, contains('涉害'));
      expect(r.sanChuan.keTypeExplanation, contains('未涉2害'));
      expect(r.sanChuan.keTypeExplanation, contains('亥涉3害'));
    });

    test('D 己卯 s=+2：弹射（无近克，己土克亥水唯一）→ 亥丑卯', () {
      final r = run('己', '卯', 2);
      expect(r.sanChuan.keType, KeType.yaoKe);
      expectSanChuan(r.sanChuan, '亥', '丑', '卯');
      expect(r.sanChuan.keTypeExplanation, contains('弹射'));
    });

    test('D2 丁巳 s=+8：蒿矢（亥水克丁火，蒿矢先于弹射）→ 亥未卯', () {
      final r = run('丁', '巳', 8);
      expect(r.sanChuan.keType, KeType.yaoKe);
      expectSanChuan(r.sanChuan, '亥', '未', '卯');
      expect(r.sanChuan.keTypeExplanation, contains('蒿矢'));
    });

    test('E 乙未 s=+10：昴星柔日（天盘酉下之支亥）→ 亥寅巳', () {
      final r = run('乙', '未', 10);
      expect(r.sanChuan.keType, KeType.maoXing);
      expectSanChuan(r.sanChuan, '亥', '寅', '巳');
      expect(r.sanChuan.keTypeExplanation, contains('昴星'));
    });

    test('G 辛丑 s=+3：别责柔日（巳酉丑局丑之次位巳）→ 巳丑丑', () {
      final r = run('辛', '丑', 3);
      expect(r.sanChuan.keType, KeType.bieZe);
      expectSanChuan(r.sanChuan, '巳', '丑', '丑');
      expect(r.sanChuan.keTypeExplanation, contains('别责'));
    });

    test('F 甲寅 s=+9：八专阳日（干上亥顺数三位丑）→ 丑亥亥', () {
      final r = run('甲', '寅', 9);
      expect(r.sanChuan.keType, KeType.baZhuan);
      expectSanChuan(r.sanChuan, '丑', '亥', '亥');
      expect(r.sanChuan.keTypeExplanation, contains('八专'));
    });

    test('H1 甲子 s=0：伏吟自任（无克刚日干上寅，刑传寅巳申）→ 寅巳申', () {
      final r = run('甲', '子', 0);
      expect(r.sanChuan.keType, KeType.fuYin);
      expectSanChuan(r.sanChuan, '寅', '巳', '申');
      expect(r.sanChuan.keTypeExplanation, contains('自任'));
    });

    test('H2 丁亥 s=0：伏吟自信+自刑（亥自刑，中传干上未，末传未刑丑）→ 亥未丑', () {
      final r = run('丁', '亥', 0);
      expect(r.sanChuan.keType, KeType.fuYin);
      expectSanChuan(r.sanChuan, '亥', '未', '丑');
      expect(r.sanChuan.keTypeExplanation, contains('自信'));
      expect(r.sanChuan.keTypeExplanation, contains('自刑'));
    });

    test('I 乙酉 s=+6：反吟有克（两下贼上，乙阴比取卯，取上神）→ 卯酉卯', () {
      final r = run('乙', '酉', 6);
      expect(r.sanChuan.keType, KeType.fanYin);
      expectSanChuan(r.sanChuan, '卯', '酉', '卯');
      expect(r.sanChuan.keTypeExplanation, contains('反吟'));
    });

    test('J 己丑 s=+6：反吟无克（井栏射，日支丑驿马亥）→ 亥未丑', () {
      final r = run('己', '丑', 6);
      expect(r.sanChuan.keType, KeType.fanYin);
      expectSanChuan(r.sanChuan, '亥', '未', '丑');
      expect(r.sanChuan.keTypeExplanation, contains('驿马'));
      expect(r.sanChuan.keTypeExplanation, contains('井栏射'));
    });
  });

  group('SiKeService 克方向判定（design.md §2）', () {
    test('下克上 → isZeiKe=true（下贼上），isBiYong=false', () {
      // 甲子日 s=+1，第二课 辰/卯：下神卯木克上神辰土
      final r = run('甲', '子', 1);
      final ke2 = r.siKe.ke2;
      expect(ke2.shangShen, '辰');
      expect(ke2.xiaShen, '卯');
      expect(ke2.isZeiKe, true);
      expect(ke2.isBiYong, false);
      expect(ke2.wuXingRelation, '下克上');
    });

    test('上克下 → isBiYong=true，isZeiKe=false', () {
      // 甲子日 s=+1，第三课 丑/子：上神丑土克下神子水
      final r = run('甲', '子', 1);
      final ke3 = r.siKe.ke3;
      expect(ke3.shangShen, '丑');
      expect(ke3.xiaShen, '子');
      expect(ke3.isZeiKe, false);
      expect(ke3.isBiYong, true);
      expect(ke3.wuXingRelation, '上克下');
    });
  });

  group('天干寄宫表（design.md §1.1）', () {
    test('六壬寄宫口径：甲寅乙辰丙戊巳丁己未庚申辛戌壬亥癸丑', () {
      expect(DaLiuRenConstants.getGanJiGong('甲'), '寅');
      expect(DaLiuRenConstants.getGanJiGong('乙'), '辰');
      expect(DaLiuRenConstants.getGanJiGong('丙'), '巳');
      expect(DaLiuRenConstants.getGanJiGong('丁'), '未');
      expect(DaLiuRenConstants.getGanJiGong('戊'), '巳');
      expect(DaLiuRenConstants.getGanJiGong('己'), '未');
      expect(DaLiuRenConstants.getGanJiGong('庚'), '申');
      expect(DaLiuRenConstants.getGanJiGong('辛'), '戌');
      expect(DaLiuRenConstants.getGanJiGong('壬'), '亥');
      expect(DaLiuRenConstants.getGanJiGong('癸'), '丑');
    });

    test('无效天干抛出 ArgumentError（不再静默兜底）', () {
      expect(() => DaLiuRenConstants.getGanJiGong('子'), throwsArgumentError);
    });

    test('八专五日判定：甲寅/庚申/丁未/己未/癸丑', () {
      expect(DaLiuRenConstants.isBaZhuanDay('甲', '寅'), true);
      expect(DaLiuRenConstants.isBaZhuanDay('庚', '申'), true);
      expect(DaLiuRenConstants.isBaZhuanDay('丁', '未'), true);
      expect(DaLiuRenConstants.isBaZhuanDay('己', '未'), true);
      expect(DaLiuRenConstants.isBaZhuanDay('癸', '丑'), true);
      expect(DaLiuRenConstants.isBaZhuanDay('甲', '子'), false);
      expect(DaLiuRenConstants.isBaZhuanDay('癸', '亥'), false);
    });
  });
}
