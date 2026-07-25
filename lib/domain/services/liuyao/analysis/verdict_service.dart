import '../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import '../../shared/wuxing_service.dart';
import 'models/analysis_report.dart';
import 'models/analysis_tag.dart';
import 'tables/chang_sheng_table.dart';
import 'tables/dizhi_relations.dart';

/// 用神净强弱三分类（分类裁决，非加权打分）
enum _Strength { strong, weak, mixed }

/// 裁决层：从既有标签求值用神受力，经决策表输出趋势 + 条件集 + 推理链。
///
/// 规则依据《增删卜易》：作用力层级为日月 > 动爻 > 暗动 > 变爻（仅回头作用本位），
/// 静爻不作用；空破墓合伏等悬置状态不直接判凶，转为待解除条件；
/// 元神动须先于忌神判（贪生忘克）。决策表按行序首行命中，保证结果唯一。
/// 消费既有标签结论（含贪合忘生克等遮蔽结果），不重算事实层。
class VerdictService {
  VerdictService._();

  static const _l1FuTerms = {'临月建', '临日建', '日扶', '月生', '日生', '旺', '相'};
  static const _l1YiTerms = {'月克', '日克', '囚', '死', '日破', '冲散'};
  static const _l2FuTerms = {'动爻生', '动爻扶', '连续相生', '三合局', '三合成局', '半合', '合起'};
  static const _l2YiTerms = {'动爻克', '连续相克'};
  static const _l4FuTerms = {'回头生', '化进神'};
  static const _l4YiHeavyTerms = {'回头克', '化退神'};
  static const _l4YiLightTerms = {'化泄', '化冲'};
  static const _fuShenFuTerms = {'飞生伏', '伏克飞', '伏神得出'};
  static const _fuShenYiTerms = {'飞克伏', '伏生飞', '伏神受制'};
  static const _neutralTerms = {'休', '贪合忘生', '贪合忘克', '贪生忘克', '克出', '日冲', '暗动'};

  /// 悬置状态：不判凶，转条件（日合/月合仅动爻悬置，静爻为合起论扶）
  static const _suspendTerms = {
    '旬空', '真空', '假空', '月破',
    '入日墓', '入月墓', '入动墓', '化墓',
    '合住', '合绊', '化合', '化空', '化破', '临绝', '化绝',
  };

  static const Map<TagCategory, String> _sources = {
    TagCategory.wangShuai: '《增删卜易》月将章/日辰章',
    TagCategory.kongWang: '《增删卜易》旬空章',
    TagCategory.muJue: '《增删卜易》生旺墓绝章',
    TagCategory.heChong: '《增删卜易》合冲章',
    TagCategory.dongBian: '《增删卜易》动变章',
    TagCategory.shengKe: '《增删卜易》动静生克章',
    TagCategory.liuQin: '《增删卜易》用神元神忌神仇神章',
    TagCategory.fuShen: '《增删卜易》用神伏藏章',
    TagCategory.special: '《增删卜易》日辰章',
    TagCategory.guaChange: '《增删卜易》卦变章',
  };

  static VerdictJudgment judge({
    required Yao yongShen,
    required bool isFuShen,
    required List<YaoAnalysisTag> yongShenTags,
    required Map<int, List<YaoAnalysisTag>> yaoTags,
    required Gua mainGua,
    Yao? changedYao,
    required LunarInfo lunarInfo,
    required List<YingQiCandidate> yingQi,
  }) {
    final terms = yongShenTags.map((t) => t.term).toSet();
    final factors = <VerdictFactor>[];

    // ── Step 1 受力归集（日月 > 动爻 > 暗动 > 变爻）──
    for (final tag in yongShenTags) {
      final effect = _effectOf(tag.term, yongShen);
      if (effect == null) continue;
      factors.add(VerdictFactor(
        rule: tag.term,
        effect: effect,
        reason: tag.reason,
        source: _sources[tag.category] ?? '《增删卜易》',
      ));
    }

    // L3 暗动：暗动爻以爻间生克论，但力次于明动
    var anDongSheng = false;
    var anDongKe = false;
    yaoTags.forEach((position, tags) {
      if (position == yongShen.position) return;
      if (!tags.any((t) => t.term == '暗动')) return;
      final other = mainGua.yaos[position - 1];
      if (WuXingService.isSheng(other.wuXing, yongShen.wuXing)) {
        anDongSheng = true;
        factors.add(VerdictFactor(
          rule: '暗动生',
          effect: VerdictEffect.fu,
          reason: '$position爻${other.branch}暗动生用神',
          source: '《增删卜易》暗动章',
        ));
      } else if (WuXingService.isKe(other.wuXing, yongShen.wuXing)) {
        anDongKe = true;
        factors.add(VerdictFactor(
          rule: '暗动克',
          effect: VerdictEffect.yi,
          reason: '$position爻${other.branch}暗动克用神',
          source: '《增删卜易》暗动章',
        ));
      }
    });

    // 净强弱：动爻克不入重抑集（即忌神动，由 jiActive 修正处理，避免双重计数）
    final hasFu = factors.any((f) => f.effect == VerdictEffect.fu);
    final l1Fu = terms.intersection(_l1FuTerms).isNotEmpty ||
        terms.intersection(_fuShenFuTerms).isNotEmpty;
    final heavyYi = terms.intersection({
      ..._l1YiTerms,
      ..._l4YiHeavyTerms,
      '飞克伏',
      '伏神受制',
    });
    final _Strength strength;
    if (l1Fu && heavyYi.isEmpty) {
      strength = _Strength.strong;
    } else if (heavyYi.isNotEmpty && !hasFu) {
      strength = _Strength.weak;
    } else {
      strength = _Strength.mixed;
    }

    // ── Step 3 元/忌神活跃性（标签驱动，遮蔽结论已由事实层吸收）──
    final yuanActive =
        terms.contains('动爻生') || terms.contains('连续相生') || anDongSheng;
    var jiActive =
        terms.contains('动爻克') || terms.contains('连续相克') || anDongKe;
    if (jiActive && terms.contains('动爻克') && !anDongKe) {
      final attackers = yongShenTags
          .where((t) => t.term == '动爻克')
          .expand((t) => t.relatedYao)
          .toSet();
      final allRestrained = attackers.isNotEmpty &&
          attackers.every((position) {
            final attackerTerms =
                (yaoTags[position] ?? const <YaoAnalysisTag>[])
                    .map((t) => t.term)
                    .toSet();
            return attackerTerms.contains('回头克') ||
                attackerTerms.contains('化退神') ||
                attackerTerms.contains('冲散');
          });
      if (allRestrained && !terms.contains('连续相克')) {
        jiActive = false;
        factors.add(const VerdictFactor(
          rule: '忌神受制',
          effect: VerdictEffect.neutral,
          reason: '克用神之动爻自身逢回头克/化退/冲散，受制难施克',
          source: '《增删卜易》忌神章',
        ));
      }
    }

    // ── Step 2 悬置状态 → 未决条件集 ──
    final conditions = _buildConditions(
      yongShen: yongShen,
      isFuShen: isFuShen,
      terms: terms,
      strength: strength,
      hasFu: hasFu,
      yuanActive: yuanActive,
      changedYao: changedYao,
    );

    // ── Step 4 裁决决策表（首行命中）──
    final hasNoRescue = conditions.any((c) => !c.hasRescue);
    final allRescuable = conditions.isNotEmpty && !hasNoRescue;
    VerdictTrend trend;
    String? nuance;
    String rule;
    switch (strength) {
      case _Strength.weak:
        if (hasNoRescue) {
          (trend, nuance, rule) =
              (VerdictTrend.nanCheng, '空破墓绝，到底无救', '衰而无救');
        } else if (yuanActive) {
          // 元神动须先于忌神判：忌元同动则贪生忘克，接续相生
          (trend, nuance, rule) =
              (VerdictTrend.daiTiaoJian, '先难后成', '元神动而生用');
        } else if (jiActive) {
          (trend, nuance, rule) = (VerdictTrend.nanCheng, '克处无生', '忌神乘衰攻用');
        } else {
          (trend, nuance, rule) = (VerdictTrend.nanCheng, '衰而无助', '休囚无生扶');
        }
      case _Strength.strong:
        if (conditions.isEmpty && !jiActive) {
          (trend, nuance, rule) = (VerdictTrend.keCheng, null, '日月生扶而无阻');
        } else if (conditions.isNotEmpty) {
          (trend, nuance, rule) = (VerdictTrend.daiTiaoJian, '成而有待', '旺而有待');
        } else {
          (trend, nuance, rule) = (VerdictTrend.daiTiaoJian, '吉中有阻', '旺而忌动');
        }
      case _Strength.mixed:
        if (yuanActive) {
          (trend, nuance, rule) =
              (VerdictTrend.daiTiaoJian, '先难后成', '元神动而生用');
        } else if (jiActive) {
          (trend, nuance, rule) = (VerdictTrend.nanCheng, '抑重于扶', '忌神动而克用');
        } else if (allRescuable) {
          (trend, nuance, rule) =
              (VerdictTrend.daiTiaoJian, '待解除后再断', '悬而未决');
        } else {
          (trend, nuance, rule) =
              (VerdictTrend.buMing, '扶抑并见，须参断者裁', '扶抑并见');
        }
    }
    factors.add(VerdictFactor(
      rule: '裁决·$rule',
      effect: VerdictEffect.neutral,
      reason: '决策表命中：${trend.name}${nuance == null ? '' : '（$nuance）'}',
      source: '《增删卜易》断法总论',
    ));

    return VerdictJudgment(
      trend: trend,
      nuance: nuance,
      conditions: conditions,
      factors: factors,
      summary: _buildSummary(
        yongShen: yongShen,
        isFuShen: isFuShen,
        trend: trend,
        nuance: nuance,
        conditions: conditions,
        yingQi: yingQi,
      ),
    );
  }

  /// term → 受力方向；悬置与未知术语返回 null（悬置由条件集表达）
  static VerdictEffect? _effectOf(String term, Yao yongShen) {
    if (_suspendTerms.contains(term)) return VerdictEffect.suspend;
    if (_l1FuTerms.contains(term) ||
        _l2FuTerms.contains(term) ||
        _l4FuTerms.contains(term) ||
        _fuShenFuTerms.contains(term)) {
      return VerdictEffect.fu;
    }
    // 日月合静爻为合起论扶，合动爻为合绊（悬置，条件集处理）
    if (term == '日合' || term == '月合') {
      return yongShen.isMoving ? VerdictEffect.suspend : VerdictEffect.fu;
    }
    if (_l1YiTerms.contains(term) ||
        _l2YiTerms.contains(term) ||
        _l4YiHeavyTerms.contains(term) ||
        _l4YiLightTerms.contains(term) ||
        _fuShenYiTerms.contains(term)) {
      return VerdictEffect.yi;
    }
    if (_neutralTerms.contains(term)) return VerdictEffect.neutral;
    return null;
  }

  static List<VerdictCondition> _buildConditions({
    required Yao yongShen,
    required bool isFuShen,
    required Set<String> terms,
    required _Strength strength,
    required bool hasFu,
    required bool yuanActive,
    Yao? changedYao,
  }) {
    final conditions = <VerdictCondition>[];
    final zhi = yongShen.branch;
    final chongZhi = DiZhiRelations.getLiuChong(zhi)!;
    final muBranch = ChangShengTable.getMuBranch(yongShen.wuXing);
    final notWeak = strength != _Strength.weak;

    if (terms.contains('真空')) {
      conditions.add(VerdictCondition(
        label: '待出空',
        branch: zhi,
        reason: '休囚安静逢空为真空，出空值日方有转机',
        hasRescue: notWeak,
      ));
    } else if (terms.contains('旬空')) {
      conditions.add(VerdictCondition(
        label: '待出空',
        branch: zhi,
        reason: terms.contains('冲空') ? '旬空而日辰冲空，冲空则起，出空填实可用' : '旬空待出空填实',
      ));
    }
    if (terms.contains('月破')) {
      conditions.add(VerdictCondition(
        label: '待出月',
        reason: '月破待出月、填实或逢合解破',
        hasRescue: notWeak,
      ));
    }
    final inMu = terms.contains('入日墓') ||
        terms.contains('入月墓') ||
        terms.contains('入动墓');
    if (inMu && !terms.contains('出墓')) {
      conditions.add(VerdictCondition(
        label: '待冲开墓库',
        branch: DiZhiRelations.getLiuChong(muBranch),
        reason: '入墓待冲开墓库$muBranch之日',
      ));
    }
    if (terms.contains('化墓')) {
      conditions.add(VerdictCondition(
        label: '待冲开化墓',
        branch: DiZhiRelations.getLiuChong(muBranch),
        reason: '动而化墓，待冲开墓库$muBranch',
      ));
    }
    final heZhu = terms.contains('合住') ||
        terms.contains('合绊') ||
        terms.contains('化合') ||
        (yongShen.isMoving &&
            (terms.contains('日合') || terms.contains('月合')));
    if (heZhu && !terms.contains('冲开')) {
      conditions.add(VerdictCondition(
        label: '待冲开',
        branch: chongZhi,
        reason: '合住则绊，待冲开之日用神方能施为',
      ));
    }
    if (terms.contains('化空') && changedYao != null) {
      conditions.add(VerdictCondition(
        label: '待变爻填实',
        branch: changedYao.branch,
        reason: '动而化空，变爻${changedYao.branch}出空填实之日应之',
      ));
    }
    if (terms.contains('化破') && changedYao != null) {
      conditions.add(VerdictCondition(
        label: '待变爻出月填实',
        branch: changedYao.branch,
        reason: '动而化破，变爻${changedYao.branch}出月或填实应之',
      ));
    }
    if (terms.contains('临绝') || terms.contains('化绝')) {
      conditions.add(VerdictCondition(
        label: '待长生扶起',
        branch: ChangShengTable.getChangShengBranch(yongShen.wuXing),
        reason: '临绝待长生之日，绝处逢生',
        hasRescue: hasFu || yuanActive,
      ));
    }
    if (isFuShen) {
      conditions.add(VerdictCondition(
        label: '待出伏',
        branch: zhi,
        reason: '用神不现，待伏神值日或冲飞之日引出',
        hasRescue: !terms.contains('伏神受制'),
      ));
    }
    return conditions;
  }

  static String _buildSummary({
    required Yao yongShen,
    required bool isFuShen,
    required VerdictTrend trend,
    required String? nuance,
    required List<VerdictCondition> conditions,
    required List<YingQiCandidate> yingQi,
  }) {
    final desc = '${yongShen.liuQin.name}${yongShen.branch}'
        '${yongShen.wuXing.name}${isFuShen ? '（伏）' : ''}';
    final condText =
        conditions.take(2).map((c) => c.label).join('、');
    final yingQiHint = yingQi.isEmpty
        ? ''
        : '；优先观察：${yingQi.take(2).map((c) => c.label).join('，')}';
    return '用神$desc，断曰：${trend.name}${nuance == null ? '' : '（$nuance）'}。'
        '${condText.isEmpty ? '' : '未决条件：$condText。'}'
        '应期候选仅表示条件触发窗口，不单独决定事情成败$yingQiHint';
  }
}
