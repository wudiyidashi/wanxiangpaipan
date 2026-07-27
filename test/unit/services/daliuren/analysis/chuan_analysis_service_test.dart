import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/san_chuan.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/chuan_analysis_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/models/daliuren_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/shared/analysis/models/polarity.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';

Chuan makeChuan(
  ChuanPosition position,
  String diZhi, {
  ShenJiang chengShen = ShenJiang.guiRen,
  bool isKongWang = false,
}) {
  return Chuan(
    position: position,
    diZhi: diZhi,
    wuXing: WuXingService.getWuXingFromBranch(diZhi)?.name ?? '',
    chengShen: chengShen,
    liuQin: '兄弟',
    isKongWang: isKongWang,
  );
}

SanChuan makeSanChuan(
  String chu,
  String zhong,
  String mo, {
  KeType keType = KeType.zeiKe,
  ShenJiang chuJiang = ShenJiang.guiRen,
  bool chuKong = false,
  bool zhongKong = false,
  bool moKong = false,
}) {
  return SanChuan(
    chuChuan: makeChuan(ChuanPosition.chu, chu,
        chengShen: chuJiang, isKongWang: chuKong),
    zhongChuan: makeChuan(ChuanPosition.zhong, zhong, isKongWang: zhongKong),
    moChuan: makeChuan(ChuanPosition.mo, mo, isKongWang: moKong),
    keType: keType,
  );
}

void main() {
  group('ChuanAnalysisService 每传标签（design §3.3）', () {
    test('三传空亡 → 发用落空/中传落空/末传落空', () {
      final sanChuan = makeSanChuan('寅', '午', '戌',
          chuKong: true, zhongKong: true, moKong: true);
      final tags = ChuanAnalysisService.analyzeChuanTags(
        sanChuan: sanChuan,
        riGan: '甲',
      );
      expect(
        tags[ChuanPosition.chu]!.map((t) => t.term),
        contains('发用落空'),
      );
      expect(
        tags[ChuanPosition.zhong]!.map((t) => t.term),
        contains('中传落空'),
      );
      expect(
        tags[ChuanPosition.mo]!.map((t) => t.term),
        contains('末传落空'),
      );
      final faYongKong = tags[ChuanPosition.chu]!
          .firstWhere((t) => t.term == '发用落空');
      expect(faYongKong.polarity, Polarity.xiong);
    });

    test('天将吉凶：吉将吉、凶将凶，term 为"X传乘Y"', () {
      final sanChuan = makeSanChuan('寅', '午', '戌',
          chuJiang: ShenJiang.qingLong);
      final tags = ChuanAnalysisService.analyzeChuanTags(
        sanChuan: sanChuan,
        riGan: '甲',
      );
      final chuJiangTag = tags[ChuanPosition.chu]!
          .firstWhere((t) => t.category == DlrTagCategory.tianJiang);
      expect(chuJiangTag.term, '初传乘青龙');
      expect(chuJiangTag.polarity, Polarity.ji);
      expect(chuJiangTag.reason, ShenJiang.qingLong.description);
    });

    test('初传克日干 → 发用克身；初传生日干 → 发用生身', () {
      // 甲木日干，初传申金克木
      final keTags = ChuanAnalysisService.analyzeChuanTags(
        sanChuan: makeSanChuan('申', '子', '辰'),
        riGan: '甲',
      );
      expect(
        keTags[ChuanPosition.chu]!.map((t) => t.term),
        contains('发用克身'),
      );

      // 甲木日干，初传子水生木
      final shengTags = ChuanAnalysisService.analyzeChuanTags(
        sanChuan: makeSanChuan('子', '丑', '寅'),
        riGan: '甲',
      );
      expect(
        shengTags[ChuanPosition.chu]!.map((t) => t.term),
        contains('发用生身'),
      );
    });
  });

  group('ChuanAnalysisService 课局级标签（design §3.3）', () {
    test('初生中且中生末 → 递生传进（吉）', () {
      // 亥水生寅木，寅木生巳火
      final juTags = ChuanAnalysisService.analyzeJuTags(
        sanChuan: makeSanChuan('亥', '寅', '巳'),
        riGan: '庚',
      );
      final tag = juTags.firstWhere((t) => t.term == '递生传进');
      expect(tag.polarity, Polarity.ji);
    });

    test('初克中且中克末 → 递克传退（凶）', () {
      // 寅木克辰土，辰土克子水
      final juTags = ChuanAnalysisService.analyzeJuTags(
        sanChuan: makeSanChuan('寅', '辰', '子'),
        riGan: '庚',
      );
      final tag = juTags.firstWhere((t) => t.term == '递克传退');
      expect(tag.polarity, Polarity.xiong);
    });

    test('末传生日干 → 传归生身；末传克日干 → 传归克身', () {
      // 甲木日干，末传子水生木
      final shengTags = ChuanAnalysisService.analyzeJuTags(
        sanChuan: makeSanChuan('午', '卯', '子'),
        riGan: '甲',
      );
      expect(shengTags.map((t) => t.term), contains('传归生身'));

      // 甲木日干，末传申金克木
      final keTags = ChuanAnalysisService.analyzeJuTags(
        sanChuan: makeSanChuan('子', '辰', '申'),
        riGan: '甲',
      );
      expect(keTags.map((t) => t.term), contains('传归克身'));
    });

    test('末传与日干寄宫支六合 → 传归生身（六合口径）', () {
      // 丙火寄宫巳，巳申六合；末传申金对丙火为我克，非生非克
      final juTags = ChuanAnalysisService.analyzeJuTags(
        sanChuan: makeSanChuan('子', '辰', '申'),
        riGan: '丙',
      );
      final tag = juTags.firstWhere((t) => t.term == '传归生身');
      expect(tag.reason, contains('六合'));
    });

    test('三传构成三合局 → 三传合局（中性，注明何局）', () {
      final juTags = ChuanAnalysisService.analyzeJuTags(
        sanChuan: makeSanChuan('申', '子', '辰'),
        riGan: '丙',
      );
      final tag = juTags.firstWhere((t) => t.term == '三传合局');
      expect(tag.polarity, Polarity.neutral);
      expect(tag.reason, contains('申子辰水局'));
    });
  });
}
