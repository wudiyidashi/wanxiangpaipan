import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/ke.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/san_chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/si_ke.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/ke_ge_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/san_chuan_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/si_ke_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/analysis/models/polarity.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';

/// 由位移 s 构造天盘映射（天盘支 = 地盘支 + s，mod 12，子=0…亥=11）
Map<String, String> buildTianPanMap(int s) {
  const diZhi = DaLiuRenConstants.diZhi;
  return {
    for (var i = 0; i < 12; i++) diZhi[i]: diZhi[(i + s + 12) % 12],
  };
}

/// 直调排盘服务：排四课 + 推三传（复用黄金课例输入）
({SiKe siKe, SanChuan sanChuan}) run(String riGan, String riZhi, int s) {
  final tianPanMap = buildTianPanMap(s);
  final siKe = SiKeService.arrangeSiKe(
    riGan: riGan,
    riZhi: riZhi,
    tianPanMap: tianPanMap,
    resolveChengShen: (_) => ShenJiang.guiRen,
  );
  final sanChuan = SanChuanService.deriveSanChuan(
    siKe: siKe,
    tianPanMap: tianPanMap,
  );
  return (siKe: siKe, sanChuan: sanChuan);
}

void expectKeGe(
  ({SiKe siKe, SanChuan sanChuan}) r,
  String geName,
  Polarity polarity,
  String ruleId,
) {
  final keGe = KeGeService.analyze(sanChuan: r.sanChuan, siKe: r.siKe);
  expect(keGe.geName, geName, reason: '格名');
  expect(keGe.polarity, polarity, reason: '格局吉凶');
  expect(keGe.keTypeName, r.sanChuan.keType.name, reason: '九宗门名');
  expect(keGe.reason, isNotEmpty, reason: '基调');
  expect(keGe.ruleRef.ruleId, ruleId, reason: '稳定规则 ID');
}

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

Chuan makeChuan(ChuanPosition position, String diZhi) {
  return Chuan(
    position: position,
    diZhi: diZhi,
    wuXing: WuXingService.getWuXingFromBranch(diZhi)?.name ?? '',
    chengShen: ShenJiang.guiRen,
    liuQin: '兄弟',
  );
}

SanChuan makeSanChuan(KeType keType, String chu, String zhong, String mo) {
  return SanChuan(
    chuChuan: makeChuan(ChuanPosition.chu, chu),
    zhongChuan: makeChuan(ChuanPosition.zhong, zhong),
    moChuan: makeChuan(ChuanPosition.mo, mo),
    keType: keType,
  );
}

void main() {
  group('KeGeService 黄金课例 13 例格名映射（design §7）', () {
    test('K 戊子 s=+4 贼克仅上克下 → 元首（吉）', () {
      expectKeGe(
          run('戊', '子', 4), '元首', Polarity.ji, DlrProjectRuleIds.keGeYuanShou);
    });

    test('B 甲子 s=+1 贼克有下贼上 → 重审（中性）', () {
      expectKeGe(run('甲', '子', 1), '重审', Polarity.neutral,
          DlrProjectRuleIds.keGeChongShen);
    });

    test('A 庚午 s=+5 比用 → 知一（中性）', () {
      expectKeGe(run('庚', '午', 5), '知一', Polarity.neutral,
          DlrProjectRuleIds.keGeZhiYi);
    });

    test('C 丁卯 s=+4 涉害 → 涉害（凶）', () {
      expectKeGe(
          run('丁', '卯', 4), '涉害', Polarity.xiong, DlrProjectRuleIds.keGeSheHai);
    });

    test('D 己卯 s=+2 遥克日干克上神 → 弹射（中性）', () {
      expectKeGe(run('己', '卯', 2), '弹射', Polarity.neutral,
          DlrProjectRuleIds.keGeTanShe);
    });

    test('D2 丁巳 s=+8 遥克上神克日干 → 蒿矢（中性）', () {
      expectKeGe(run('丁', '巳', 8), '蒿矢', Polarity.neutral,
          DlrProjectRuleIds.keGeHaoShi);
    });

    test('E 乙未 s=+10 昴星柔日 → 冬蛇掩目（凶）', () {
      expectKeGe(run('乙', '未', 10), '冬蛇掩目', Polarity.xiong,
          DlrProjectRuleIds.keGeDongSheYanMu);
    });

    test('G 辛丑 s=+3 别责 → 别责（中性）', () {
      expectKeGe(run('辛', '丑', 3), '别责', Polarity.neutral,
          DlrProjectRuleIds.keGeBieZe);
    });

    test('F 甲寅 s=+9 八专 → 八专（中性）', () {
      expectKeGe(run('甲', '寅', 9), '八专', Polarity.neutral,
          DlrProjectRuleIds.keGeBaZhuan);
    });

    test('H1 甲子 s=0 伏吟无克刚日 → 自任（中性）', () {
      expectKeGe(run('甲', '子', 0), '自任', Polarity.neutral,
          DlrProjectRuleIds.keGeZiRen);
    });

    test('H2 丁亥 s=0 伏吟无克柔日 → 自信（中性）', () {
      expectKeGe(run('丁', '亥', 0), '自信', Polarity.neutral,
          DlrProjectRuleIds.keGeZiXin);
    });

    test('I 乙酉 s=+6 反吟有克 → 反吟（凶）', () {
      expectKeGe(
          run('乙', '酉', 6), '反吟', Polarity.xiong, DlrProjectRuleIds.keGeFanYin);
    });

    test('J 己丑 s=+6 反吟无克 → 井栏射（中性）', () {
      expectKeGe(run('己', '丑', 6), '井栏射', Polarity.neutral,
          DlrProjectRuleIds.keGeJingLanShe);
    });
  });

  group('KeGeService 构造盘面补全格名（虎视/不虞）', () {
    test('昴星刚日 → 虎视（凶）', () {
      final siKe = SiKe(
        ke1: makeKe(1, '子', '巳'),
        ke2: makeKe(2, '未', '子'),
        ke3: makeKe(3, '卯', '申'),
        ke4: makeKe(4, '戌', '卯'),
        riGan: '戊',
        riZhi: '申',
      );
      final sanChuan = makeSanChuan(KeType.maoXing, '辰', '卯', '子');
      final keGe = KeGeService.analyze(sanChuan: sanChuan, siKe: siKe);
      expect(keGe.geName, '虎视');
      expect(keGe.polarity, Polarity.xiong);
      expect(keGe.ruleRef.ruleId, DlrProjectRuleIds.keGeHuShi);
    });

    test('伏吟有克 → 不虞（凶）', () {
      final siKe = SiKe(
        ke1: makeKe(1, '寅', '甲').copyWith(
          hasKe: true,
          isBiYong: true,
        ),
        ke2: makeKe(2, '寅', '寅'),
        ke3: makeKe(3, '辰', '辰'),
        ke4: makeKe(4, '辰', '辰'),
        riGan: '戊',
        riZhi: '辰',
      );
      final sanChuan = makeSanChuan(KeType.fuYin, '寅', '巳', '申');
      final keGe = KeGeService.analyze(sanChuan: sanChuan, siKe: siKe);
      expect(keGe.geName, '不虞');
      expect(keGe.polarity, Polarity.xiong);
      expect(keGe.ruleRef.ruleId, DlrProjectRuleIds.keGeBuYu);
    });
  });
}
