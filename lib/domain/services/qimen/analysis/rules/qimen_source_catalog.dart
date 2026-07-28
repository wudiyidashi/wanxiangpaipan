import '../models/qimen_rule_models.dart';

class QimenSourceCatalog {
  QimenSourceCatalog._();

  static const String tongZong = 'QMS-CLASSIC-TONGZONG';
  static const String dunJiaYanYi = 'QMS-CLASSIC-YANYI';
  static const String yuanLingJing = 'QMS-CLASSIC-YUANLING';
  static const String baoJian = 'QMS-CLASSIC-BAOJIAN';
  static const String tuShu707 = 'QMS-CLASSIC-TUSHU-707';
  static const String projectV1 = 'QMS-PROJECT-V1';
  static const String panGolden3Meta = 'QMSRC-PAN-GOLDEN-3META';
  static const String panGoldenQiMen = 'QMSRC-PAN-GOLDEN-QIMEN';

  static const List<QimenSourceRef> all = <QimenSourceRef>[
    QimenSourceRef(
      sourceId: dunJiaYanYi,
      kind: QimenSourceKind.classicalText,
      title: '程道生《遁甲演义》',
      editionOrRevision: 'Wikisource transcription, oldid 2082234',
      locator:
          'https://zh.wikisource.org/w/index.php?title=%E9%81%81%E7%94%B2%E6%BC%94%E7%BE%A9&oldid=2082234',
      claimSummary: '九星旺相休囚废、精确格局公式与排局实例。',
      adjudicationNote: '固定转录版本用于公开定位，不冒充校勘本；异本未锁定者只作背景。',
      accessedOn: '2026-07-28',
    ),
    QimenSourceRef(
      sourceId: tongZong,
      kind: QimenSourceKind.classicalText,
      title: '《奇门遁甲统宗》',
      editionOrRevision: 'Wikisource transcription, oldid 1378608',
      locator:
          'https://zh.wikisource.org/w/index.php?title=%E5%A5%87%E9%96%80%E9%81%81%E7%94%B2%E7%B5%B1%E5%AE%97&oldid=1378608',
      claimSummary: '钓叟歌、八门旺相、三遁、击刑、入墓、五不遇与十干格。',
      adjudicationNote: '固定转录版本用于发现与核对；项目明确记录采用口径，不补猜缺文。',
      accessedOn: '2026-07-28',
    ),
    QimenSourceRef(
      sourceId: yuanLingJing,
      kind: QimenSourceKind.publishedCase,
      title: '《奇门遁甲元灵经》',
      editionOrRevision: 'Wikisource transcription, oldid 1378607',
      locator:
          'https://zh.wikisource.org/w/index.php?title=%E5%A5%87%E9%96%80%E9%81%81%E7%94%B2%E5%85%83%E9%9D%88%E7%B6%93&oldid=1378607',
      claimSummary: '财、学业、升迁、走失与军务等公开占例。',
      adjudicationNote: '仅把原文明确给出的盘面与断语作为案例证据；缺失四柱不得伪装为历史事实。',
      accessedOn: '2026-07-28',
    ),
    QimenSourceRef(
      sourceId: baoJian,
      kind: QimenSourceKind.classicalText,
      title: '《奇门宝鉴御定》',
      editionOrRevision: 'Wikisource transcription, oldid 2353651',
      locator:
          'https://zh.wikisource.org/w/index.php?title=%E5%A5%87%E9%97%A8%E5%AE%9D%E9%89%B4%E5%BE%A1%E5%AE%9A&oldid=2353651',
      claimSummary: '三奇游六仪、九星旺相、玉女守门与“混合百神”九乘九十干克应表。',
      adjudicationNote: '十干克应在v1逐对记录为中性结构，不把条目文辞直接提升为综合裁决；'
          '辛加辛转录中的“卒”字保留为版本歧义，不静默改字。',
      accessedOn: '2026-07-28',
    ),
    QimenSourceRef(
      sourceId: tuShu707,
      kind: QimenSourceKind.classicalText,
      title: '《古今图书集成·艺术典》第707卷',
      editionOrRevision: 'Wikisource transcription, oldid 1942670',
      locator:
          'https://zh.wikisource.org/w/index.php?title=%E6%AC%BD%E5%AE%9A%E5%8F%A4%E4%BB%8A%E5%9C%96%E6%9B%B8%E9%9B%86%E6%88%90%2F%E5%8D%9A%E7%89%A9%E5%BD%99%E7%B7%A8%2F%E8%97%9D%E8%A1%93%E5%85%B8%2F%E7%AC%AC707%E5%8D%B7&oldid=1942670',
      claimSummary: '门迫、三遁、三奇入墓、五不遇与诸凶格交叉核验。',
      adjudicationNote: '该汇编可能复录早期材料，只作支持证据，不重复计为独立来源。',
      accessedOn: '2026-07-28',
    ),
    QimenSourceRef(
      sourceId: projectV1,
      kind: QimenSourceKind.projectConvention,
      title: '本项目约定（奇门分析 v1）',
      editionOrRevision: 'qimen-shijia-zhuanpan-analysis/v1',
      locator: '.trellis/spec/domain/qimen-analysis-engine.md',
      claimSummary: '八类焦点、保守冲突顺序、首行命中裁决与结构化应期合同。',
      adjudicationNote: '古籍没有唯一综合裁决表；项目只允许显式收敛规则决定趋势，其他混合证据返回趋势不明。',
    ),
    QimenSourceRef(
      sourceId: panGolden3Meta,
      kind: QimenSourceKind.externalCrossCheck,
      title: '3metaJun/3meta Qimen fixed case',
      editionOrRevision: '9be1238cbb7b0118826a689f9d3f8100284f6df3',
      locator:
          'https://github.com/3metaJun/3meta/blob/9be1238cbb7b0118826a689f9d3f8100284f6df3/src/__tests__/qimen.test.ts',
      claimSummary: '仅交叉校验冻结排盘 fixture，不授权分析断语。',
      adjudicationNote: '与另一仓库可能同谱系，因此不作为独立解释权威。',
      accessedOn: '2026-07-28',
    ),
    QimenSourceRef(
      sourceId: panGoldenQiMen,
      kind: QimenSourceKind.externalCrossCheck,
      title: 'xuanyuwang/QiMen fixed case',
      editionOrRevision: 'c07efe2ba3c74b58e02301abce1c16b4eb9d79b1',
      locator:
          'https://github.com/xuanyuwang/QiMen/blob/c07efe2ba3c74b58e02301abce1c16b4eb9d79b1/tests/main.test.js#L129',
      claimSummary: '仅交叉校验冻结排盘 fixture，不授权分析断语。',
      adjudicationNote: '与另一仓库可能同谱系，冻结字段另经项目逐宫复核。',
      accessedOn: '2026-07-28',
    ),
  ];

  static final Map<String, QimenSourceRef> byId =
      Map<String, QimenSourceRef>.unmodifiable(<String, QimenSourceRef>{
    for (final source in all) source.sourceId: source,
  });

  static void validate() {
    if (byId.length != all.length) {
      throw StateError('Qimen source catalog contains duplicate IDs');
    }
    for (final source in all) {
      if (source.sourceId.isEmpty ||
          source.title.isEmpty ||
          source.editionOrRevision.isEmpty ||
          source.locator.isEmpty ||
          source.claimSummary.isEmpty ||
          source.adjudicationNote.isEmpty) {
        throw StateError('Incomplete Qimen source: ${source.sourceId}');
      }
      if (source.locator.startsWith('http') && source.accessedOn == null) {
        throw StateError(
          'URL Qimen source lacks access date: ${source.sourceId}',
        );
      }
    }
  }
}
