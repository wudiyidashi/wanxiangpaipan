import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/ke.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/si_ke.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/gan_zhi_zhu_ke_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/models/daliuren_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/shared/analysis/models/polarity.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';

Ke makeKe(int index, String shang, String xia) {
  return Ke(
    index: index,
    shangShen: shang,
    xiaShen: xia,
    chengShen: ShenJiang.guiRen,
    shangShenWuXing: WuXingService.getWuXingFromBranch(shang)?.name ?? '土',
    xiaShenWuXing: WuXingService.getWuXingFromBranch(xia)?.name ?? '土',
  );
}

SiKe makeSiKe({
  required String riGan,
  required String riZhi,
  required String ganShang,
  required String zhiShang,
}) {
  return SiKe(
    ke1: makeKe(1, ganShang, DaLiuRenConstants.getGanJiGong(riGan)),
    ke2: makeKe(2, '子', ganShang),
    ke3: makeKe(3, zhiShang, riZhi),
    ke4: makeKe(4, '子', zhiShang),
    riGan: riGan,
    riZhi: riZhi,
  );
}

void main() {
  group('GanZhiZhuKeService 干支主客（design §3.2）', () {
    test('干上神生日干 → 干上生身（吉）', () {
      // 甲木日干，干上神子水生木
      final siKe = makeSiKe(riGan: '甲', riZhi: '午', ganShang: '子', zhiShang: '午');
      final tags = GanZhiZhuKeService.analyze(siKe: siKe, kongWang: const []);
      final ganTag = tags.firstWhere((t) => t.relatedPositions.contains('干上'));
      expect(ganTag.term, '干上生身');
      expect(ganTag.polarity, Polarity.ji);
      expect(ganTag.category, DlrTagCategory.ganZhi);
    });

    test('干上神克日干 → 干上克身（凶）', () {
      // 甲木日干，干上神申金克木
      final siKe = makeSiKe(riGan: '甲', riZhi: '午', ganShang: '申', zhiShang: '午');
      final tags = GanZhiZhuKeService.analyze(siKe: siKe, kongWang: const []);
      final ganTag = tags.firstWhere((t) => t.relatedPositions.contains('干上'));
      expect(ganTag.term, '干上克身');
      expect(ganTag.polarity, Polarity.xiong);
    });

    test('日干克干上神 → 身制干上（中性）', () {
      // 甲木克辰土
      final siKe = makeSiKe(riGan: '甲', riZhi: '午', ganShang: '辰', zhiShang: '午');
      final tags = GanZhiZhuKeService.analyze(siKe: siKe, kongWang: const []);
      final ganTag = tags.firstWhere((t) => t.relatedPositions.contains('干上'));
      expect(ganTag.term, '身制干上');
      expect(ganTag.polarity, Polarity.neutral);
    });

    test('支上神克日支 → 事体受制（凶）；生日支 → 事得生扶（吉）', () {
      // 日支午火，支上神亥水克火
      final siKe1 = makeSiKe(riGan: '甲', riZhi: '午', ganShang: '寅', zhiShang: '亥');
      final tags1 = GanZhiZhuKeService.analyze(siKe: siKe1, kongWang: const []);
      final zhiTag1 = tags1.firstWhere((t) => t.relatedPositions.contains('支上'));
      expect(zhiTag1.term, '事体受制');
      expect(zhiTag1.polarity, Polarity.xiong);

      // 日支午火，支上神卯木生火
      final siKe2 = makeSiKe(riGan: '甲', riZhi: '午', ganShang: '寅', zhiShang: '卯');
      final tags2 = GanZhiZhuKeService.analyze(siKe: siKe2, kongWang: const []);
      final zhiTag2 = tags2.firstWhere((t) => t.relatedPositions.contains('支上'));
      expect(zhiTag2.term, '事得生扶');
      expect(zhiTag2.polarity, Polarity.ji);
    });

    test('干上/支上落旬空 → 空亡标签（凶，注明待填实）', () {
      final siKe = makeSiKe(riGan: '甲', riZhi: '午', ganShang: '子', zhiShang: '丑');
      final tags = GanZhiZhuKeService.analyze(
        siKe: siKe,
        kongWang: const ['子', '丑'],
      );
      final ganKong = tags.firstWhere((t) => t.term == '干上空亡');
      final zhiKong = tags.firstWhere((t) => t.term == '支上空亡');
      expect(ganKong.polarity, Polarity.xiong);
      expect(ganKong.category, DlrTagCategory.kongWang);
      expect(ganKong.reason, contains('填实'));
      expect(zhiKong.polarity, Polarity.xiong);
      expect(zhiKong.reason, contains('填实'));
    });
  });
}
