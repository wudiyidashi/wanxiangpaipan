import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/yao.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/liuyao_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_report.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/verdict_service.dart';

import 'helpers/analysis_fixtures.dart';

/// 裁决层测试：经 LiuYaoAnalyzer 全管道驱动，用真实服务产出的标签作输入，
/// 覆盖决策表每行的正例与关键反例。卦例按《增删卜易》断法原则构造。
void main() {
  YaoAnalysisTag tag(String term, TagCategory category) => YaoAnalysisTag(
        term: term,
        category: category,
        polarity: Polarity.neutral,
        priority: 0,
        reason: '通用规则组合：$term',
      );

  VerdictJudgment judgeTags(
    List<YaoAnalysisTag> tags, {
    Yao? yongShen,
    bool isFuShen = false,
  }) {
    final yao = yongShen ?? makeYao(branch: '午', moving: true);
    return VerdictService.judge(
      yongShen: yao,
      isFuShen: isFuShen,
      yongShenTags: tags,
      yaoTags: {yao.position: tags},
      mainGua: buildGua([7, 7, 7, 7, 7, 7]),
      lunarInfo: buildLunar(),
      yingQi: const [],
    );
  }

  VerdictJudgment judge(
    List<int> numbers, {
    required String yueJian,
    required String riGanZhi,
    required int position,
    bool isFuShen = false,
    bool withChanging = false,
  }) {
    final gua = buildGua(numbers);
    final changing = withChanging ? buildChangingGua(gua) : null;
    final report = LiuYaoAnalyzer.analyze(
      gua,
      changing,
      buildLunar(yueJian: yueJian, riGanZhi: riGanZhi),
      yongShenPosition: position,
      yongShenIsFuShen: isFuShen,
    );
    return report.judgment!;
  }

  group('决策表 strong 分支', () {
    test('正例·日月生扶忌静无条件 → 可成（乾申月戊戌日用神五爻申金）', () {
      final j =
          judge([7, 7, 7, 7, 7, 7], yueJian: '申', riGanZhi: '戊戌', position: 5);
      expect(j.trend, VerdictTrend.keCheng);
      expect(j.conditions, isEmpty);
      expect(j.factors.map((f) => f.rule), contains('临月建'));
      expect(j.summary, contains('可成'));
    });

    test('正例·旺相动而化合为化扶 → 可成（乾午月丙寅日四爻午动化未）', () {
      final j = judge([7, 7, 7, 9, 7, 7],
          yueJian: '午', riGanZhi: '丙寅', position: 4, withChanging: true);
      expect(j.trend, VerdictTrend.keCheng);
      expect(j.conditions.map((c) => c.label), isNot(contains('待冲开')));
      expect(j.factors.map((f) => f.rule), contains('化合'));
    });

    test('正例·日月扶而忌神独发 → 待条件·吉中有阻（兑酉月戊辰日初爻巳动克五爻酉）', () {
      final j = judge([9, 7, 8, 7, 7, 8],
          yueJian: '酉', riGanZhi: '戊辰', position: 5, withChanging: true);
      expect(j.trend, VerdictTrend.daiTiaoJian);
      expect(j.nuance, '吉中有阻');
      expect(j.conditions, isEmpty);
      expect(j.factors.map((f) => f.rule), contains('动爻克'));
    });

    test(
        '反例·忌神动被日辰合住则贪合忘克，不作阻断 → 可成'
        '（乾子月己巳日五爻申动，日巳合申）', () {
      final j = judge([7, 7, 7, 7, 9, 7],
          yueJian: '子', riGanZhi: '己巳', position: 2, withChanging: true);
      expect(j.trend, VerdictTrend.keCheng);
      expect(j.factors.map((f) => f.rule), contains('贪合忘克'));
      expect(j.factors.map((f) => f.rule), isNot(contains('动爻克')));
    });
  });

  group('决策表 weak 分支', () {
    test('正例·真空无救 → 难成（坤未月辛未日用神五爻亥水真空）', () {
      final j =
          judge([8, 8, 8, 8, 8, 8], yueJian: '未', riGanZhi: '辛未', position: 5);
      expect(j.trend, VerdictTrend.nanCheng);
      expect(j.nuance, contains('无救'));
      final kong = j.conditions.firstWhere((c) => c.label == '待出空');
      expect(kong.hasRescue, isFalse);
    });

    test('正例·休囚无生扶 → 难成·衰而无助（乾酉月乙丑日用神二爻寅木）', () {
      final j =
          judge([7, 7, 7, 7, 7, 7], yueJian: '酉', riGanZhi: '乙丑', position: 2);
      expect(j.trend, VerdictTrend.nanCheng);
      expect(j.nuance, '衰而无助');
      expect(j.conditions, isEmpty);
    });

    test('正例·衰而化绝化回头克 → 难成（坤申月甲戌日三爻卯动化申）', () {
      final j = judge([8, 8, 6, 8, 8, 8],
          yueJian: '申', riGanZhi: '甲戌', position: 3, withChanging: true);
      expect(j.trend, VerdictTrend.nanCheng);
      expect(j.factors.map((f) => f.rule), contains('回头克'));
      expect(j.conditions.any((c) => !c.hasRescue), isTrue);
    });

    test('反例·旺相之空为假空，条件可解不判无救（乾申月戊戌日三爻辰土旬空）', () {
      // 甲午旬辰巳空；辰土得日戌拱扶为假空
      final j =
          judge([7, 7, 7, 7, 7, 7], yueJian: '申', riGanZhi: '戊戌', position: 3);
      final kong = j.conditions.firstWhere((c) => c.label == '待出空');
      expect(kong.hasRescue, isTrue);
      expect(j.trend, isNot(VerdictTrend.nanCheng));
    });
  });

  group('决策表 mixed 分支', () {
    test('正例·元神动而生用 → 待条件·先难后成（震午月辛卯日三爻辰动生五爻申）', () {
      final j = judge([7, 8, 6, 7, 8, 8],
          yueJian: '午', riGanZhi: '辛卯', position: 5, withChanging: true);
      expect(j.trend, VerdictTrend.daiTiaoJian);
      expect(j.nuance, '先难后成');
      expect(j.factors.map((f) => f.rule), contains('动爻生'));
    });

    test('正例·忌神独发克用 → 难成·抑重于扶（乾子月癸酉日五爻申动克二爻寅）', () {
      final j = judge([7, 7, 7, 7, 9, 7],
          yueJian: '子', riGanZhi: '癸酉', position: 2, withChanging: true);
      expect(j.trend, VerdictTrend.nanCheng);
      expect(j.nuance, '抑重于扶');
      expect(j.factors.map((f) => f.rule), contains('动爻克'));
    });

    test('正例·月破待出月 → 待条件·待解除后再断（乾申月丁亥日用神二爻寅木月破）', () {
      final j =
          judge([7, 7, 7, 7, 7, 7], yueJian: '申', riGanZhi: '丁亥', position: 2);
      expect(j.trend, VerdictTrend.daiTiaoJian);
      expect(j.nuance, '待解除后再断');
      expect(j.conditions.map((c) => c.label), contains('待出月'));
    });
  });

  group('悬置状态产条件不判凶', () {
    test('月破转条件而非直接难成（用神有日生仍为待条件）', () {
      final j =
          judge([7, 7, 7, 7, 7, 7], yueJian: '申', riGanZhi: '丁亥', position: 2);
      final poCondition = j.conditions.firstWhere((c) => c.label == '待出月');
      expect(poCondition.hasRescue, isTrue);
      expect(j.trend, isNot(VerdictTrend.nanCheng));
    });

    test('动爻逢日合仍转"待冲开"条件，附冲支衔接应期', () {
      final j = judge([9, 8, 7, 6, 8, 8],
          yueJian: '申', riGanZhi: '丙子', position: 4, withChanging: true);
      final he = j.conditions.firstWhere((c) => c.label == '待冲开');
      expect(he.branch, '未'); // 丑之冲支
      expect(he.hasRescue, isTrue);
    });
  });

  group('伏神取用', () {
    test('天山遁伏神寅木：出伏条件 + 飞伏关系因素，基于伏神自身裁决', () {
      final j = judge([8, 8, 7, 7, 7, 7],
          yueJian: '午', riGanZhi: '甲子', position: 2, isFuShen: true);
      expect(j.conditions.map((c) => c.label), contains('待出伏'));
      expect(j.factors.map((f) => f.rule), contains('伏生飞'));
      // 日子水生寅木，伏神有气：非难成
      expect(j.trend, VerdictTrend.daiTiaoJian);
    });

    test('飞克伏时出伏无解，不以“尚未受日月再克”误判为可解', () {
      final j = judge([8, 8, 7, 7, 7, 7],
          yueJian: '申', riGanZhi: '甲寅', position: 1, isFuShen: true);
      expect(j.factors.map((f) => f.rule), contains('飞克伏'));
      expect(j.factors.map((f) => f.rule), isNot(contains('伏神受制')));
      final condition = j.conditions.firstWhere((c) => c.label == '待出伏');
      expect(condition.hasRescue, isFalse);
    });

    test('只有飞生伏而无日月生扶时仍为 mixed，不提升为 strong', () {
      final j = judge([8, 7, 7, 7, 7, 7],
          yueJian: '午', riGanZhi: '乙丑', position: 2, isFuShen: true);
      expect(j.factors.map((f) => f.rule), contains('飞生伏'));
      expect(j.nuance, '待解除后再断');
    });
  });

  group('黄金断例领域复核回归', () {
    test('复之震：用神受日月克但化回头生，仍以相生为吉', () {
      final j = judge([7, 8, 8, 6, 8, 8],
          yueJian: '卯', riGanZhi: '己卯', position: 4, withChanging: true);

      expect(j.trend, VerdictTrend.keCheng);
      expect(j.factors.map((f) => f.rule), contains('回头生'));
      expect(j.factors.last.rule, '裁决·用神回头得生');
    });

    test('否之讼：休囚但得日生，按克处逢生保留先难后成', () {
      final j = judge([8, 6, 8, 7, 7, 7],
          yueJian: '卯', riGanZhi: '戊辰', position: 5, withChanging: true);

      expect(j.trend, VerdictTrend.daiTiaoJian);
      expect(j.nuance, '先难后成');
      expect(j.factors.last.rule, '裁决·克处逢生');
    });

    test('师之明夷：用神自身回头克优先于同卦连续相生', () {
      final j = judge([6, 9, 6, 8, 8, 8],
          yueJian: '酉', riGanZhi: '甲辰', position: 3, withChanging: true);

      expect(j.factors.map((f) => f.rule), containsAll(['回头克', '连续相生']));
      expect(j.trend, VerdictTrend.nanCheng);
      expect(j.factors.last.rule, '裁决·用神回头受克');
    });

    test('临之泰：元神暗动与忌神明动并见且非接续相生，忌神优先', () {
      final j = judge([7, 7, 6, 8, 8, 8],
          yueJian: '丑', riGanZhi: '癸卯', position: 5, withChanging: true);

      expect(j.factors.map((f) => f.rule), containsAll(['暗动生', '动爻克']));
      expect(j.trend, VerdictTrend.nanCheng);
      expect(j.factors.last.rule, '裁决·忌神动而克用');
    });

    test('日冲飞神已得出时，飞克伏不再把出伏标作无解', () {
      final j = judge([8, 8, 7, 7, 7, 7],
          yueJian: '申', riGanZhi: '甲戌', position: 1, isFuShen: true);

      expect(j.factors.map((f) => f.rule), contains('伏神得出'));
      final condition = j.conditions.firstWhere((c) => c.label == '待出伏');
      expect(condition.hasRescue, isTrue);
      expect(j.trend, VerdictTrend.daiTiaoJian);
    });
  });

  group('领域复核规则按通用标签组合生效', () {
    test('回头生前置规则不依赖复之震占例', () {
      final j = judgeTags([
        tag('月克', TagCategory.wangShuai),
        tag('回头生', TagCategory.dongBian),
      ]);

      expect(j.trend, VerdictTrend.keCheng);
      expect(j.factors.last.rule, '裁决·用神回头得生');
    });

    test('回头克优先、克处逢生、非接续元忌均由标签守卫决定', () {
      final huiTouKe = judgeTags([
        tag('月克', TagCategory.wangShuai),
        tag('回头克', TagCategory.dongBian),
        tag('连续相生', TagCategory.shengKe),
      ]);
      final keChuFengSheng = judgeTags([
        tag('日生', TagCategory.wangShuai),
        tag('回头克', TagCategory.dongBian),
      ]);
      final yuanJi = judgeTags([
        tag('动爻生', TagCategory.shengKe),
        tag('动爻克', TagCategory.shengKe),
      ]);

      expect(huiTouKe.factors.last.rule, '裁决·用神回头受克');
      expect(huiTouKe.trend, VerdictTrend.nanCheng);
      expect(keChuFengSheng.factors.last.rule, '裁决·克处逢生');
      expect(keChuFengSheng.trend, VerdictTrend.daiTiaoJian);
      expect(yuanJi.factors.last.rule, '裁决·忌神动而克用');
      expect(yuanJi.trend, VerdictTrend.nanCheng);
    });

    test('伏神得出可解覆盖飞克伏无解也不依赖具体卦例', () {
      final j = judgeTags(
        [
          tag('飞克伏', TagCategory.fuShen),
          tag('伏神得出', TagCategory.fuShen),
        ],
        yongShen: makeYao(branch: '子'),
        isFuShen: true,
      );

      final condition = j.conditions.singleWhere((c) => c.label == '待出伏');
      expect(condition.hasRescue, isTrue);
      expect(j.trend, VerdictTrend.daiTiaoJian);
    });
  });

  group('推理链与兼容', () {
    test('三合局只记录成局事实，不在缺少作用方向时自动算作扶助', () {
      final j =
          judge([9, 7, 9, 7, 7, 7], yueJian: '午', riGanZhi: '乙丑', position: 5);
      expect(j.factors.map((f) => f.rule), isNot(contains('三合局')));
    });

    test('推理链末条为决策表命中记录，因素均有经文出处', () {
      final j =
          judge([7, 7, 7, 7, 7, 7], yueJian: '申', riGanZhi: '戊戌', position: 5);
      expect(j.factors.last.rule, startsWith('裁决·'));
      for (final f in j.factors) {
        expect(f.source, contains('《增删卜易》'));
      }
    });

    test('未选用神时 judgment 为 null（旧行为兼容）', () {
      final report = LiuYaoAnalyzer.analyze(
        buildGua([7, 7, 7, 7, 7, 7]),
        null,
        buildLunar(yueJian: '午', riGanZhi: '甲子'),
      );
      expect(report.judgment, isNull);
      expect(report.verdictSummary, isNull);
    });

    test('verdictSummary 由裁决摘要填充且保留免责表述', () {
      final report = LiuYaoAnalyzer.analyze(
        buildGua([7, 7, 7, 7, 7, 7]),
        null,
        buildLunar(yueJian: '午', riGanZhi: '甲子'),
        yongShenPosition: 2,
      );
      expect(report.verdictSummary, report.judgment!.summary);
      expect(report.verdictSummary, contains('条件触发窗口'));
      expect(report.verdictSummary, contains('断曰'));
    });
  });
}
