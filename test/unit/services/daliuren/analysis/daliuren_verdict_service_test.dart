import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/daliuren_verdict_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/models/daliuren_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/shared/analysis/models/polarity.dart';
import 'package:wanxiang_paipan/domain/services/shared/analysis/models/verdict_models.dart';

DlrAnalysisTag tag(
  String term,
  Polarity polarity, {
  DlrTagCategory category = DlrTagCategory.chuan,
  required String ruleId,
}) {
  return DlrAnalysisTag(
    ruleRef: DlrRuleRef.project(ruleId),
    term: term,
    category: category,
    polarity: polarity,
    priority: 1,
    reason: '测试标签 $term',
  );
}

final keGeNeutral = KeGeInfo(
  ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeChongShen),
  keTypeName: '贼克',
  geName: '重审',
  polarity: Polarity.neutral,
  reason: '事从卑下而起，先难后易，审慎则吉',
);

final keGeJi = KeGeInfo(
  ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeYuanShou),
  keTypeName: '贼克',
  geName: '元首',
  polarity: Polarity.ji,
  reason: '尊临卑、事顺理正',
);

final keGeXiong = KeGeInfo(
  ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeSheHai),
  keTypeName: '涉害',
  geName: '涉害',
  polarity: Polarity.xiong,
  reason: '历涉艰难，事迟滞乃成',
);

VerdictJudgment judge({
  KeGeInfo? keGe,
  List<DlrAnalysisTag> ganZhiTags = const [],
  List<DlrAnalysisTag> juTags = const [],
  Map<ChuanPosition, List<DlrAnalysisTag>> chuanTags = const {},
  bool chuKongWang = false,
  bool zhongKongWang = false,
  bool moKongWang = false,
}) {
  return DaLiuRenVerdictService.judge(
    keGe: keGe ?? keGeNeutral,
    ganZhiTags: ganZhiTags,
    chuanTags: chuanTags,
    juTags: juTags,
    chuChuanZhi: '寅',
    moChuanZhi: '戌',
    chuKongWang: chuKongWang,
    zhongKongWang: zhongKongWang,
    moKongWang: moKongWang,
  );
}

void main() {
  group('DaLiuRenVerdictService 决策表逐行命中（design §4）', () {
    test('行1：初传空且末传空 → 难成，首尾俱空，hasRescue=false', () {
      final j = judge(chuKongWang: true, moKongWang: true);
      expect(j.trend, VerdictTrend.nanCheng);
      expect(j.nuance, '首尾俱空，事难成实');
      expect(j.conditions, hasLength(2));
      expect(j.conditions.every((c) => !c.hasRescue), true);
      expect(j.conditions.first.branch, '寅');
      expect(j.conditions.last.branch, '戌');
    });

    test('行2：传归克身且干上克身 → 难成（内外交攻）', () {
      final j = judge(
        ganZhiTags: [
          tag(
            '干上克身',
            Polarity.xiong,
            ruleId: DlrProjectRuleIds.ganAboveControlsSelf,
          ),
        ],
        juTags: [
          tag(
            '传归克身',
            Polarity.xiong,
            ruleId: DlrProjectRuleIds.transmissionReturnsToControlSelf,
          ),
        ],
      );
      expect(j.trend, VerdictTrend.nanCheng);
      expect(j.nuance, '内外交攻');
      expect(
        j.factors.map((f) => f.rule),
        containsAll(['传归克身', '干上克身']),
      );
    });

    test('行3：递克传退且课格凶 → 难成', () {
      final j = judge(
        keGe: keGeXiong,
        juTags: [
          tag(
            '递克传退',
            Polarity.xiong,
            ruleId: DlrProjectRuleIds.progressiveControl,
          ),
        ],
      );
      expect(j.trend, VerdictTrend.nanCheng);
      expect(j.factors.map((f) => f.rule), contains('递克传退'));
    });

    test('行4：传归生身且无悬置 → 可成；课格重审 nuance=先难后成', () {
      final j = judge(juTags: [
        tag(
          '传归生身',
          Polarity.ji,
          ruleId: DlrProjectRuleIds.transmissionReturnsToGenerateSelf,
        ),
      ]);
      expect(j.trend, VerdictTrend.keCheng);
      expect(j.nuance, '先难后成');
    });

    test('行4：传归生身且课格非涉害/重审 → 可成且无 nuance', () {
      final j = judge(keGe: keGeJi, juTags: [
        tag(
          '传归生身',
          Polarity.ji,
          ruleId: DlrProjectRuleIds.transmissionReturnsToGenerateSelf,
        ),
      ]);
      expect(j.trend, VerdictTrend.keCheng);
      expect(j.nuance, isNull);
    });

    test('行5：传归生身且有悬置 → 待条件', () {
      final j = judge(
        juTags: [
          tag(
            '传归生身',
            Polarity.ji,
            ruleId: DlrProjectRuleIds.transmissionReturnsToGenerateSelf,
          ),
        ],
        chuKongWang: true,
      );
      expect(j.trend, VerdictTrend.daiTiaoJian);
      expect(j.conditions.single.label, '待发用填实');
      expect(j.conditions.single.branch, '寅');
    });

    test('行6：递生传进且无悬置且无克身标签 → 可成', () {
      final j = judge(juTags: [
        tag(
          '递生传进',
          Polarity.ji,
          ruleId: DlrProjectRuleIds.progressiveGeneration,
        ),
      ]);
      expect(j.trend, VerdictTrend.keCheng);
      expect(j.factors.map((f) => f.rule), contains('递生传进'));
    });

    test('行7：仅末传空悬置 → 待条件', () {
      final j = judge(moKongWang: true);
      expect(j.trend, VerdictTrend.daiTiaoJian);
      expect(j.conditions.single.label, '待归宿填实');
      expect(j.conditions.single.branch, '戌');
    });

    test('行8：发用克身无悬置 → 难成', () {
      final j = judge(chuanTags: {
        ChuanPosition.chu: [
          tag(
            '发用克身',
            Polarity.xiong,
            ruleId: DlrProjectRuleIds.initialTransmissionControlsSelf,
          ),
        ],
      });
      expect(j.trend, VerdictTrend.nanCheng);
      expect(j.factors.map((f) => f.rule), contains('发用克身'));
    });

    test('行9：课格吉且无任何凶标签 → 可成', () {
      final j = judge(
        keGe: keGeJi,
        ganZhiTags: [
          tag(
            '干上生身',
            Polarity.ji,
            category: DlrTagCategory.ganZhi,
            ruleId: DlrProjectRuleIds.ganAboveGeneratesSelf,
          ),
        ],
      );
      expect(j.trend, VerdictTrend.keCheng);
    });

    test('行10：其余（课格中性带凶标签但不成克身格局）→ 趋势不明', () {
      final j = judge(
        ganZhiTags: [
          tag(
            '事体受制',
            Polarity.xiong,
            category: DlrTagCategory.ganZhi,
            ruleId: DlrProjectRuleIds.affairIsControlled,
          ),
        ],
      );
      expect(j.trend, VerdictTrend.buMing);
    });

    test('展示词改名不改变 ruleId 驱动的裁决与参与 factor', () {
      final j = judge(
        juTags: [
          tag(
            '终传扶身（改名）',
            Polarity.ji,
            ruleId: DlrProjectRuleIds.transmissionReturnsToGenerateSelf,
          ),
        ],
      );

      expect(j.trend, VerdictTrend.keCheng);
      expect(j.nuance, '先难后成');
      expect(j.factors.map((factor) => factor.rule), contains('终传扶身（改名）'));
    });

    test('课格展示名改名不改变 ruleId 驱动的 nuance', () {
      final renamedKeGe = keGeNeutral.copyWith(geName: '复核格（改名）');
      final j = judge(
        keGe: renamedKeGe,
        juTags: [
          tag(
            '传归生身',
            Polarity.ji,
            ruleId: DlrProjectRuleIds.transmissionReturnsToGenerateSelf,
          ),
        ],
      );

      expect(j.trend, VerdictTrend.keCheng);
      expect(j.nuance, '先难后成');
    });

    test('display-only 凶标签不得改变项目 v1 裁决', () {
      final displayTag = DlrAnalysisTag(
        ruleRef: DlrRuleRef(
          ruleId: 'dlr.display.analysis.warning',
          ruleSetVersion: DlrRuleSetVersions.analysisCurrent,
          kind: DlrRuleKind.display,
          evidenceLevel: DlrEvidenceLevel.d,
        ),
        term: '仅展示警示',
        category: DlrTagCategory.chuan,
        polarity: Polarity.xiong,
        priority: 1,
        reason: '不得进入裁决条件',
      );

      final j = judge(keGe: keGeJi, juTags: <DlrAnalysisTag>[displayTag]);

      expect(j.trend, VerdictTrend.keCheng);
      expect(j.factors.map((factor) => factor.rule), isNot(contains('仅展示警示')));
    });

    test('非当前项目规则集不得复用稳定 ID 改变裁决', () {
      final futureTag = DlrAnalysisTag(
        ruleRef: DlrRuleRef(
          ruleId: DlrProjectRuleIds.initialTransmissionControlsSelf,
          ruleSetVersion: 'daliuren-analysis-project-v1/2.0.0',
          kind: DlrRuleKind.project,
          evidenceLevel: DlrEvidenceLevel.d,
        ),
        term: '发用克身',
        category: DlrTagCategory.chuan,
        polarity: Polarity.xiong,
        priority: 1,
        reason: '未知未来版本',
      );

      final j = judge(juTags: <DlrAnalysisTag>[futureTag]);

      expect(j.trend, VerdictTrend.buMing);
      expect(j.factors.map((factor) => factor.rule), isNot(contains('发用克身')));
    });
  });

  group('DaLiuRenVerdictService factors 与 summary', () {
    test('课格行 source 为《大六壬指南》课体章（基调）', () {
      final j = judge();
      final keGeFactor = j.factors.firstWhere((f) => f.rule.startsWith('课格·'));
      expect(keGeFactor.source, '《大六壬指南》课体章（基调）');
    });

    test('命中行殿后且 source 为本项目约定', () {
      final j = judge();
      expect(j.factors.last.rule, startsWith('裁决·'));
      expect(j.factors.last.source, '本项目约定（大六壬断课 v1）');
    });

    test('summary 含课体名、格名与趋势，悬置附条件清单', () {
      final j = judge(chuKongWang: true);
      expect(j.summary, contains('课体贼克（重审）'));
      expect(j.summary, contains('断曰：待条件'));
      expect(j.summary, contains('待发用填实（寅）'));
    });

    test('中传空不单独成悬置', () {
      final j = judge(zhongKongWang: true);
      expect(j.conditions, isEmpty);
      expect(j.trend, isNot(VerdictTrend.daiTiaoJian));
    });
  });
}
