import '../../../../divination_systems/liuyao/models/gua.dart';
import '../../../../divination_systems/liuyao/models/yao.dart';
import '../../../../models/lunar_info.dart';
import '../../fushen_service.dart';
import 'dong_bian_service.dart';
import 'fu_shen_relation_service.dart';
import 'gua_change_service.dart';
import 'he_chong_service.dart';
import 'kong_wang_service.dart';
import 'liu_qin_deduce_service.dart';
import 'models/analysis_report.dart';
import 'models/analysis_tag.dart';
import 'mu_jue_service.dart';
import 'sheng_ke_service.dart';
import 'special_service.dart';
import 'wang_shuai_service.dart';
import 'ying_qi_service.dart';

/// 六爻断卦分析编排器：唯一对上层暴露的分析入口。
///
/// 无用神时仅输出爻级客观分析与卦级标签；
/// 指定用神后追加六亲推理链、应期候选与结论摘要。
/// 分析结果为派生数据，不做持久化。
class LiuYaoAnalyzer {
  LiuYaoAnalyzer._();

  static AnalysisReport analyze(
    Gua mainGua,
    Gua? changingGua,
    LunarInfo lunarInfo, {
    int? yongShenPosition,
    bool yongShenIsFuShen = false,
  }) {
    final yaoTags = <int, List<YaoAnalysisTag>>{
      for (final yao in mainGua.yaos) yao.position: <YaoAnalysisTag>[],
    };

    for (final yao in mainGua.yaos) {
      yaoTags[yao.position]!
        ..addAll(WangShuaiService.analyzeYao(yao, lunarInfo))
        ..addAll(KongWangService.analyzeYao(yao, mainGua, lunarInfo))
        ..addAll(MuJueService.analyzeYao(yao, mainGua, lunarInfo))
        ..addAll(SpecialService.analyzeYao(yao, lunarInfo));
    }
    _merge(yaoTags, HeChongService.analyzeGua(mainGua, lunarInfo));
    _merge(
        yaoTags, DongBianService.analyzeGua(mainGua, changingGua, lunarInfo));
    _merge(yaoTags, ShengKeService.analyzeGua(mainGua, lunarInfo));
    _merge(yaoTags, FuShenRelationService.analyzeGua(mainGua, lunarInfo));

    final guaTags = GuaChangeService.analyzeGua(mainGua, changingGua);

    YongShenChain? chain;
    List<YaoAnalysisTag> selectedYongShenTags = const [];
    List<YingQiCandidate>? yingQi;
    String? verdict;

    if (yongShenPosition != null) {
      chain = LiuQinDeduceService.deduce(
        mainGua,
        yongShenPosition,
        isFuShen: yongShenIsFuShen,
      );
      _addChainTags(yaoTags, chain, mainGua);

      final yongShenYao = yongShenIsFuShen
          ? FuShenService.calculateFuShen(mainGua)[yongShenPosition]!.yao
          : mainGua.yaos[yongShenPosition - 1];
      selectedYongShenTags = yongShenIsFuShen
          ? _analyzeFuShenYongShen(
              yongShenYao,
              mainGua,
              lunarInfo,
              yaoTags[yongShenPosition]!,
            )
          : List<YaoAnalysisTag>.from(yaoTags[yongShenPosition]!);
      selectedYongShenTags.sort(
        (a, b) => a.priority.compareTo(b.priority),
      );
      yingQi = YingQiService.calculate(
        yongShen: yongShenYao,
        changedYao: yongShenYao.isMoving && changingGua != null
            ? changingGua.yaos[yongShenPosition - 1]
            : null,
        yongShenTags: selectedYongShenTags,
        lunarInfo: lunarInfo,
      );
      verdict = _buildVerdict(yongShenYao, selectedYongShenTags, yingQi);
    }

    for (final tags in yaoTags.values) {
      tags.sort((a, b) => a.priority.compareTo(b.priority));
    }
    yaoTags.removeWhere((_, tags) => tags.isEmpty);

    return AnalysisReport(
      yaoTags: yaoTags,
      guaTags: guaTags,
      yongShen: chain,
      yongShenTags: selectedYongShenTags,
      yingQi: yingQi,
      verdictSummary: verdict,
    );
  }

  static List<YaoAnalysisTag> _analyzeFuShenYongShen(
    Yao fuShen,
    Gua mainGua,
    LunarInfo lunarInfo,
    List<YaoAnalysisTag> positionTags,
  ) {
    return <YaoAnalysisTag>[
      ...WangShuaiService.analyzeYao(fuShen, lunarInfo),
      ...KongWangService.analyzeYao(fuShen, mainGua, lunarInfo),
      ...MuJueService.analyzeYao(fuShen, mainGua, lunarInfo),
      ...SpecialService.analyzeYao(fuShen, lunarInfo),
      ...positionTags.where(
        (tag) =>
            tag.category == TagCategory.fuShen ||
            (tag.category == TagCategory.liuQin &&
                tag.relatedYao.isEmpty &&
                tag.term == '用神(伏)'),
      ),
    ];
  }

  static void _merge(Map<int, List<YaoAnalysisTag>> into,
      Map<int, List<YaoAnalysisTag>> from) {
    from.forEach((position, tags) => into[position]!.addAll(tags));
  }

  static void _addChainTags(
    Map<int, List<YaoAnalysisTag>> yaoTags,
    YongShenChain chain,
    Gua gua,
  ) {
    void addRole(int? position, String term, Polarity polarity, int priority,
        String reason) {
      if (position == null) return;
      yaoTags[position]!.add(YaoAnalysisTag(
        term: term,
        category: TagCategory.liuQin,
        polarity: polarity,
        priority: priority,
        reason: reason,
      ));
    }

    addRole(chain.position, chain.isFuShen ? '用神(伏)' : '用神', Polarity.neutral,
        0, chain.isFuShen ? '用神不现，伏神取用' : '所占之事以此爻为用');
    addRole(chain.yuanShenPosition, '原神', Polarity.ji, 1, '生用神者为原神');
    addRole(chain.jiShenPosition, '忌神', Polarity.xiong, 1, '克用神者为忌神');
    addRole(chain.chouShenPosition, '仇神', Polarity.xiong, 8, '克原神生忌神者为仇神');
    for (final position in chain.duplicatePositions) {
      addRole(position, '用神两现', Polarity.neutral, 8, '与用神同六亲，舍此取彼');
    }
  }

  static String _buildVerdict(
    Yao yongShen,
    List<YaoAnalysisTag> yongShenTags,
    List<YingQiCandidate> yingQi,
  ) {
    final desc =
        '${yongShen.liuQin.name}${yongShen.branch}${yongShen.wuXing.name}';
    final keyTags = [...yongShenTags]
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final keyTerms = keyTags
        .where((t) => t.category != TagCategory.liuQin)
        .take(3)
        .map((t) => t.term)
        .join('、');

    final yingQiHint = yingQi.isEmpty
        ? ''
        : '；优先观察：${yingQi.take(2).map((c) => c.label).join('，')}';

    final stateDesc = keyTerms.isEmpty ? '暂无突出状态' : '主要状态：$keyTerms';
    return '用神$desc，$stateDesc。'
        '应期候选仅表示条件触发窗口，不单独决定事情成败$yingQiHint';
  }
}
