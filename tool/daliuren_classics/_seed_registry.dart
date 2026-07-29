import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const String _root = 'assets/data/daliuren/classics';
const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

void main() {
  _write('sources.json', _sources());
  _write('rules/pan.json', _pan());
  _write('rules/shenjiang.json', _shenjiang());
  _write('rules/jiuzongmen.json', _jiuzongmen());
  _write('rules/derived-facts.json', _derivedFacts());
  _write('rules/shensha.json', _shensha());
  _write('rules/kejing.json', _kejing());
  _write('rules/bifa.json', _bifa());
  _write('rules/nianming.json', _nianming());
  _write('rules/class-spirit.json', _classSpirit());
  _write('rules/judgment.json', _judgment());
  _write('rules/timing.json', _timing());
  _write('cases/duanan.json', _duananCases());
  _write('cases/cunyan.json', _cunyanCases());
  _write('cases/zhinan.json', _zhinanCases());
  _write('variants.json', _variants());
}

void _write(String relativePath, Object value) {
  final File file = File(p.join(_root, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('${_encoder.convert(value)}\n');
}

Map<String, Object?> _sources() => <String, Object?>{
      'schemaVersion': '1.0.0',
      'sources': <Object?>[
        <String, Object?>{
          'sourceId': 'dlr.source.siku-liuren-daquan',
          'sourceType': 'scan',
          'title': '钦定四库全书·六壬大全',
          'authorsEditors': <String>['题撰者未由馆藏元数据确认'],
          'edition': '钦定四库全书·子部七·术数类影印本',
          'repository': 'Internet Archive / Universal Library',
          'identifier': '06054168.cn--06054177.cn',
          'accessUrl': 'https://archive.org/details/06054168.cn',
          'accessedAt': '2026-07-28',
          'verificationStatus': 'scanVerified',
          'locatorOnly': false,
          'usage': <String>['primaryBaseline'],
          'ruleLayers': <String>[
            'pan',
            'shenjiang',
            'jiuzongmen',
            'derivedFacts',
            'shensha',
            'kejing',
            'bifa',
          ],
          'volumes': <Object?>[
            _scanVolume('卷一', '06054168.cn', 112, 3458657, 36109),
            _scanVolume('卷二', '06054169.cn', 134, 4459686, 43171),
            _scanVolume('卷三', '06054170.cn', 134, 4201731, 43171),
            _scanVolume('卷四至五', '06054171.cn', 184, 6522261, 59221),
            _scanVolume('卷六', '06054172.cn', 154, 5283430, 49591),
            _scanVolume('卷七', '06054173.cn', 144, 5092219, 46381),
            _scanVolume('卷八', '06054174.cn', 148, 4935577, 47665),
            _scanVolume('卷九', '06054175.cn', 152, 5325007, 48949),
            _scanVolume('卷十', '06054176.cn', 132, 4497262, 42529),
            _scanVolume('卷十一至十二', '06054177.cn', 210, 4703602, 67567),
          ],
          'rightsNote': '仅登记公开馆藏标识与短引；扫描件本体不入库。',
          'limitations': <String>[
            '馆藏 metadata 的卷名不能替代影印页内卷题核验。',
            '固定转录文件与影印本卷界并非一一对应，规则引用不得按文件名或固定偏移推导。',
            'scan leaf 与 PDF 页数映射已由 scandata 核对；版心叶码仍须逐条人工记录。',
          ],
        },
        <String, Object?>{
          'sourceId': 'dlr.source.daliuren-zhinan-scan',
          'sourceType': 'scan',
          'title': '大六壬指南',
          'authorsEditors': <String>[
            '明·陈公献手著',
            '清·程翔云鉴定',
            '于鸿编辑校订',
          ],
          'edition': '中国数术学研究社影印编校本；刊刻年代未核',
          'repository': 'Internet Archive',
          'identifier': '20210924_20210924_0416',
          'accessUrl': 'https://archive.org/details/20210924_20210924_0416',
          'accessedAt': '2026-07-28',
          'verificationStatus': 'scanVerified',
          'locatorOnly': false,
          'usage': <String>['judgmentBaseline', 'externalCase'],
          'ruleLayers': <String>[
            'pan',
            'nianming',
            'classSpirit',
            'judgment',
            'timing',
            'externalCases',
          ],
          'volumes': <Object?>[
            _zeroBasedScanVolume(
              '全册',
              '20210924_20210924_0416',
              '大六壬指南.pdf',
              83,
              8251802,
              '大六壬指南_scandata.xml',
              26699,
            ),
          ],
          'rightsNote': '仅登记公开馆藏标识与短引；扫描件本体不入库。',
          'limitations': <String>[
            '作者与编校信息来自影印 PDF 第 2 页题名页，馆藏元数据仍缺年代与出版者。',
            '自动 OCR 严重失真，只能检索定位。',
            '影印本似止于印刷页 78，而目录列至 84；缺叶或版本差异尚未解决。',
            'PDF 6 基础规则及 PDF 44、54、56 课例已独立复核；其余断课、类神与应期页面仍须逐条二审，因此 source 维持 scanVerified。',
          ],
        },
        <String, Object?>{
          'sourceId': 'dlr.source.daquan-transcription-aa7bc942',
          'sourceType': 'transcription',
          'title': '六壬大全固定提交转录',
          'authorsEditors': <String>['youngzs/xuanxue contributors'],
          'edition': 'Git commit aa7bc942602d2d88ef94778a726c0d19a4d286ff',
          'repository': 'GitHub youngzs/xuanxue',
          'identifier': 'aa7bc942602d2d88ef94778a726c0d19a4d286ff',
          'accessUrl':
              'https://github.com/youngzs/xuanxue/tree/aa7bc942602d2d88ef94778a726c0d19a4d286ff/docs/%E5%85%AD%E5%A3%AC%E5%A4%A7%E5%85%A8',
          'accessedAt': '2026-07-28',
          'verificationStatus': 'metadataVerified',
          'locatorOnly': true,
          'usage': <String>['searchLocator', 'variantLocator'],
          'ruleLayers': <String>[
            'pan',
            'jiuzongmen',
            'derivedFacts',
            'shensha',
            'kejing',
            'bifa',
            'timing',
          ],
          'volumes': <Object?>[
            _textSnapshotVolume(
              '固定提交文本集合',
              'aa7bc942602d2d88ef94778a726c0d19a4d286ff',
              'https://github.com/youngzs/xuanxue/tree/aa7bc942602d2d88ef94778a726c0d19a4d286ff/docs/%E5%85%AD%E5%A3%AC%E5%A4%A7%E5%85%A8',
              <String>[
                '000提要.md',
                '001巻一 起例.md',
                '002卷二 神将释.md',
                '003巻三 歌赋（一）.md',
                '004巻四 歌赋（二）.md',
                '005巻五 兵占.md',
                '006巻六 宿度分野.md',
                '007巻七 课经集（一）.md',
                '008巻八 课经集（二）.md',
                '009巻九 课经集（三）.md',
                '010巻十 课经集（四）.md',
                '011巻十一 《毕法赋》上.md',
                '012巻十二 《毕法赋》下.md',
              ],
            ),
          ],
          'rightsNote': '仅作检索定位；短引须回到影印页复核。',
          'limitations': <String>[
            '固定转录只具 C 级 locator 资格。',
            '转录文件会跨越四库影印本卷界，不能按文件名或卷号差推导 scan locus。',
            'OCR 或录入异文未经过本项目逐字复核。',
          ],
        },
        <String, Object?>{
          'sourceId': 'dlr.source.cunyan-transcription-d2a44794',
          'sourceType': 'transcription',
          'title': '六壬存验固定提交转录',
          'authorsEditors': <String>[
            '清·吴师青',
            'mahavivo/scripta-sinica contributors'
          ],
          'edition': 'Git commit d2a447941d43fd5ac35b35194dcb0a68d4275aa7',
          'repository': 'GitHub mahavivo/scripta-sinica',
          'identifier': 'd2a447941d43fd5ac35b35194dcb0a68d4275aa7',
          'accessUrl':
              'https://github.com/mahavivo/scripta-sinica/blob/d2a447941d43fd5ac35b35194dcb0a68d4275aa7/01%E6%98%93%E8%97%8F-0195%E9%83%A8/02%E6%9C%AF%E6%95%B0-146%E9%83%A8/%E5%85%AD%E5%A3%AC%E5%AD%98%E9%AA%8C-%E6%B8%85-%E5%90%B4%E5%B8%88%E9%9D%92.txt',
          'accessedAt': '2026-07-28',
          'verificationStatus': 'metadataVerified',
          'locatorOnly': true,
          'usage': <String>['externalCase', 'searchLocator', 'variantLocator'],
          'ruleLayers': <String>[
            'pan',
            'shenjiang',
            'nianming',
            'classSpirit',
            'judgment',
            'timing',
            'externalCases',
          ],
          'volumes': <Object?>[
            _textSnapshotVolume(
              '固定提交全文',
              'd2a447941d43fd5ac35b35194dcb0a68d4275aa7',
              'https://github.com/mahavivo/scripta-sinica/blob/d2a447941d43fd5ac35b35194dcb0a68d4275aa7/01%E6%98%93%E8%97%8F-0195%E9%83%A8/02%E6%9C%AF%E6%95%B0-146%E9%83%A8/%E5%85%AD%E5%A3%AC%E5%AD%98%E9%AA%8C-%E6%B8%85-%E5%90%B4%E5%B8%88%E9%9D%92.txt',
              <String>['六壬存验-清-吴师青.txt'],
            ),
          ],
          'rightsNote': '仅作检索定位；课例必须回到影印页才可升为 A/B。',
          'limitations': <String>[
            '未找到可与该固定转录逐页对应的影印底本。',
            '转录课例全部保持 C 级 pendingScan。',
          ],
        },
        _ctpSource(
          'dlr.source.duanan-ctp-936550',
          '大六壬断案',
          '936550',
          <String>['externalCase', 'searchLocator'],
        ),
        _ctpSource(
          'dlr.source.cunyan-ctp-872390',
          '六壬存验',
          '872390',
          <String>['externalCase', 'searchLocator'],
        ),
        <String, Object?>{
          'sourceId': 'dlr.source.zhinan-xiangjie-scan',
          'sourceType': 'scan',
          'title': '校正大六壬指南详解',
          'authorsEditors': <String>['馆藏元数据未载'],
          'edition': '版本待卷首核定',
          'repository': 'Internet Archive',
          'identifier': '20210924_20210924_0419',
          'accessUrl': 'https://archive.org/details/20210924_20210924_0419',
          'accessedAt': '2026-07-28',
          'verificationStatus': 'metadataVerified',
          'locatorOnly': false,
          'usage': <String>['supplement'],
          'ruleLayers': <String>['judgment', 'timing'],
          'volumes': <Object?>[
            _zeroBasedScanVolume(
              '全册',
              '20210924_20210924_0419',
              '校正大六壬指南详解.pdf',
              34,
              null,
              '校正大六壬指南详解_scandata.xml',
              null,
            ),
          ],
          'rightsNote': '只作释义交叉参考，不替代主底本。',
          'limitations': <String>['馆藏元数据不完整，OCR 严重失真。'],
        },
        <String, Object?>{
          'sourceId': 'dlr.source.yuding-liuren-zhizhi-candidate',
          'sourceType': 'scan',
          'title': '御定六壬直指',
          'authorsEditors': <String>['馆藏元数据未载'],
          'edition': '馆藏标为清康熙时期精钞本，版本真伪待核',
          'repository': 'Internet Archive',
          'identifier': '20260504_20260504_1528',
          'accessUrl': 'https://archive.org/details/20260504_20260504_1528',
          'accessedAt': '2026-07-28',
          'verificationStatus': 'scanVerified',
          'locatorOnly': false,
          'usage': <String>['supplement', 'variantLocator'],
          'ruleLayers': <String>['pan', 'shenjiang', 'jiuzongmen'],
          'volumes': <Object?>[
            _zeroBasedScanVolume(
              '上下卷附析义',
              '20260504_20260504_1528',
              '御定六壬直指.上下卷.附析義.清康熙時期精鈔本.pdf',
              854,
              null,
              '御定六壬直指.上下卷.附析義.清康熙時期精鈔本_scandata.xml',
              null,
            ),
          ],
          'rightsNote': '仅登记公开馆藏标识与短引；扫描件本体不入库。',
          'limitations': <String>[
            '卷上 PDF 18 / scan leaf 17 / printed leaf 七已经 C00 与 C04 核页；PDF 19 / scan leaf 18 / printed leaf 八由 C04 独立核页；其余页面仍须逐条复核。',
            '馆藏所标“清康熙时期精钞本”的版本真伪尚未核定，本源只作 supplement/variant，不升为主底本或 approved source。',
          ],
        },
      ],
      'unregisteredCandidates': <Object?>[
        _candidate('duanan-scan', '大六壬断案影印本', 'notLocated',
            'CTP 与殆知阁链接均落到版本暂缺的 wiki 转录；NDL 仅查到 2012 年纸本疏正，无在线页图。'),
        _candidate('cunyan-scan', '六壬存验影印本', 'notLocated',
            '目前只有固定提交与 CTP 版本暂缺转录，尚无可逐页对应的影印底本。'),
        _candidate('rengui', '壬归', 'notLocated', '仅作为补缺候选，尚未固定可核影印版本。'),
        _candidate(
            'liuren-cuiyan', '六壬粹言', 'notLocated', '仅作为补缺候选，尚未固定可核影印版本。'),
        _candidate(
            'daliuren-tanyuan', '大六壬探原', 'notLocated', '仅作为补缺候选，尚未固定可核影印版本。'),
      ],
    };

Map<String, Object?> _scanVolume(
  String label,
  String identifier,
  int leafCount,
  int pdfSize,
  int scanDataSize,
) =>
    <String, Object?>{
      'volumeLabel': label,
      'identifier': identifier,
      'accessUrl': 'https://archive.org/details/$identifier',
      'remoteFiles': <Object?>[
        <String, Object?>{
          'name': '$identifier.pdf',
          'format': 'Text PDF',
          'sizeBytes': pdfSize,
        },
        <String, Object?>{
          'name': '${identifier}_scandata.xml',
          'format': 'Scandata',
          'sizeBytes': scanDataSize,
        },
      ],
      'pagination': <String, Object?>{
        'scanLeafBase': 1,
        'leafCount': leafCount,
        'pdfPageBase': 1,
        'mappingRule': 'pdfPageEqualsScanLeaf',
        'mappingStatus': 'verifiedFromScandata',
        'printedLeafScheme': '版心叶码须在单条 rule sourceRef 中人工抄录',
        'notes': 'scandata 中所有 leaf 均进入 access PDF；scan leaf 与 PDF 页一一相等。',
      },
    };

Map<String, Object?> _zeroBasedScanVolume(
  String label,
  String identifier,
  String pdfName,
  int leafCount,
  int? pdfSize,
  String scanDataName,
  int? scanDataSize,
) =>
    <String, Object?>{
      'volumeLabel': label,
      'identifier': identifier,
      'accessUrl': 'https://archive.org/details/$identifier',
      'remoteFiles': <Object?>[
        <String, Object?>{
          'name': pdfName,
          'format': 'Image Container PDF',
          'sizeBytes': pdfSize,
        },
        <String, Object?>{
          'name': scanDataName,
          'format': 'Scandata',
          'sizeBytes': scanDataSize,
        },
      ],
      'pagination': <String, Object?>{
        'scanLeafBase': 0,
        'leafCount': leafCount,
        'pdfPageBase': 1,
        'mappingRule': 'pdfPageEqualsScanLeafPlusOne',
        'mappingStatus': 'verifiedFromScandata',
        'printedLeafScheme': '版心叶码须在单条 rule sourceRef 中人工抄录',
        'notes': 'scandata 的 leaf 从 0 起，全部进入 PDF；PDF 页 = scan leaf + 1。',
      },
    };

Map<String, Object?> _textSnapshotVolume(
  String label,
  String identifier,
  String accessUrl,
  List<String> filenames,
) =>
    <String, Object?>{
      'volumeLabel': label,
      'identifier': identifier,
      'accessUrl': accessUrl,
      'remoteFiles': filenames
          .map(
            (String name) => <String, Object?>{
              'name': name,
              'format': 'UTF-8 transcription',
              'sizeBytes': null,
            },
          )
          .toList(),
      'pagination': <String, Object?>{
        'scanLeafBase': null,
        'leafCount': null,
        'pdfPageBase': null,
        'mappingRule': 'notApplicable',
        'mappingStatus': 'notApplicable',
        'printedLeafScheme': '不适用；只能使用固定提交路径和行号',
        'notes': '文本行号是检索 locator，不是影印页。',
      },
    };

Map<String, Object?> _ctpSource(
  String sourceId,
  String title,
  String resourceId,
  List<String> usage,
) =>
    <String, Object?>{
      'sourceId': sourceId,
      'sourceType': 'transcription',
      'title': title,
      'authorsEditors': <String>['Chinese Text Project wiki contributors'],
      'edition': 'CTP wiki 明示版本暂缺',
      'repository': 'Chinese Text Project',
      'identifier': 'ctext-wiki-res-$resourceId',
      'accessUrl': 'https://ctext.org/wiki.pl?if=gb&res=$resourceId',
      'accessedAt': '2026-07-28',
      'verificationStatus': 'metadataVerified',
      'locatorOnly': true,
      'usage': usage,
      'ruleLayers': <String>['externalCases'],
      'volumes': <Object?>[
        _textSnapshotVolume(
          'CTP wiki 转录',
          'ctext-wiki-res-$resourceId',
          'https://ctext.org/wiki.pl?if=gb&res=$resourceId',
          <String>['wiki.pl?res=$resourceId'],
        ),
      ],
      'rightsNote': '仅记录 locator；不把 wiki 转录当作影印证据。',
      'limitations': <String>[
        '页面明示版本暂缺。',
        '无影印页，最高只能作为 C 级 locator。',
      ],
    };

Map<String, Object?> _candidate(
  String id,
  String title,
  String status,
  String reason,
) =>
    <String, Object?>{
      'candidateId': 'dlr.candidate.$id',
      'title': title,
      'status': status,
      'reason': reason,
    };

Map<String, Object?> _family(
  String family,
  String catalogStatus,
  String description,
  List<Map<String, Object?>> entries, {
  int? expectedEntryCount,
}) =>
    <String, Object?>{
      'schemaVersion': '1.0.0',
      'family': family,
      'catalogStatus': catalogStatus,
      'description': description,
      'expectedEntryCount': expectedEntryCount ?? entries.length,
      'entries': entries,
    };

Map<String, Object?> _rule({
  required String id,
  required String family,
  required String subfamily,
  required int ordinal,
  required String name,
  required String conditions,
  required String interpretation,
  required String targetCapability,
  required String targetCodeDomain,
  String priority = '同规则族内的优先关系尚未由影印页冻结；不得按目录顺序推断执行优先级。',
  String status = 'pending',
  String evidence = 'C',
  bool locatorOnly = true,
  bool executableApproved = false,
  List<Map<String, Object?>> sourceRefs = const <Map<String, Object?>>[],
  String? variantGroupId,
  String? adoptedVariantId,
  List<String> fixtureIds = const <String>[],
  List<String> notes = const <String>[],
}) =>
    <String, Object?>{
      'ruleId': id,
      'family': family,
      'subfamily': subfamily,
      'ordinal': ordinal,
      'traditionalName': name,
      'adoptedStatus': status,
      'conditionsSummary': conditions,
      'prioritySummary': priority,
      'interpretation': interpretation,
      'evidenceLevel': evidence,
      'locatorOnly': locatorOnly,
      'executableApproved': executableApproved,
      'sourceRefs': sourceRefs,
      'variantGroupId': variantGroupId,
      'adoptedVariantId': adoptedVariantId,
      'fixtureIds': fixtureIds,
      'targetCapabilityId': targetCapability,
      'targetCodeDomain': targetCodeDomain,
      'notes': notes,
    };

Map<String, Object?> _locator(
  String sourceId,
  String locator,
  String shortQuote,
) =>
    <String, Object?>{
      'sourceId': sourceId,
      'referenceKind': 'locator',
      'volume': null,
      'scanLeaf': null,
      'printedLeaf': null,
      'pdfPage': null,
      'imageLabel': null,
      'locator': locator,
      'shortQuote': shortQuote,
      'verifiedBy': <Object?>[],
    };

Map<String, Object?> _scan(
  String sourceId,
  String volume, {
  required int scanLeaf,
  required int pdfPage,
  required String shortQuote,
  String? printedLeaf,
  String? imageLabel,
  String reviewer = 'C00 first-pass scan audit',
  List<String> additionalReviewers = const <String>[],
}) =>
    <String, Object?>{
      'sourceId': sourceId,
      'referenceKind': 'scan',
      'volume': volume,
      'scanLeaf': scanLeaf,
      'printedLeaf': printedLeaf,
      'pdfPage': pdfPage,
      'imageLabel': imageLabel,
      'locator': null,
      'shortQuote': shortQuote,
      'verifiedBy': <Object?>[
        <String, Object?>{
          'reviewer': reviewer,
          'date': '2026-07-28',
        },
        for (final String additionalReviewer in additionalReviewers)
          <String, Object?>{
            'reviewer': additionalReviewer,
            'date': '2026-07-28',
          },
      ],
    };

Map<String, Object?> _variantLocator(
  String sourceId,
  String locator,
  String shortQuote,
) =>
    <String, Object?>{
      'sourceId': sourceId,
      'referenceKind': 'locator',
      'volume': null,
      'scanLeaf': null,
      'printedLeaf': null,
      'pdfPage': null,
      'imageLabel': null,
      'locator': locator,
      'shortQuote': shortQuote,
    };

Map<String, Object?> _variantScan(
  String sourceId,
  String volume, {
  required int scanLeaf,
  required int pdfPage,
  required String shortQuote,
  String? printedLeaf,
  String? imageLabel,
}) =>
    <String, Object?>{
      'sourceId': sourceId,
      'referenceKind': 'scan',
      'volume': volume,
      'scanLeaf': scanLeaf,
      'printedLeaf': printedLeaf,
      'pdfPage': pdfPage,
      'imageLabel': imageLabel,
      'locator': null,
      'shortQuote': shortQuote,
    };

Map<String, Object?> _pan() {
  const String cunyan = 'dlr.source.cunyan-transcription-d2a44794';
  const String daquan = 'dlr.source.daquan-transcription-aa7bc942';
  const String siku = 'dlr.source.siku-liuren-daquan';
  const String zhinanScan = 'dlr.source.daliuren-zhinan-scan';
  final List<Map<String, Object?>> entries = <Map<String, Object?>>[
    _rule(
      id: 'dlr.rule.pan.001.month-general-by-zhongqi',
      family: 'pan',
      subfamily: 'calendarMonthGeneral',
      ordinal: 1,
      name: '月将随中气',
      conditions: '按所占时刻已发生的中气选择月将，再把月将加到占时地盘支。',
      interpretation: '转录明确列十二中气与月将，并说明月将加占时；精确交节时刻仍属现代历法软件契约。',
      targetCapability: 'daliuren.pan.monthGeneral',
      targetCodeDomain: 'lib/domain/services/daliuren/yue_jiang_service.dart',
      status: 'adopted',
      evidence: 'B',
      locatorOnly: false,
      sourceRefs: <Map<String, Object?>>[
        _scan(
          zhinanScan,
          '全册',
          scanLeaf: 5,
          pdfPage: 6,
          printedLeaf: '1',
          shortQuote: '雨水亥、春分戌、谷雨酉……冬至丑、大寒子。',
          additionalReviewers: <String>['c00_independent_recheck (Codex)'],
        ),
        _locator(cunyan, '六壬存验-清-吴师青.txt:L329-L344', '先立定地盘十二支。次取月令……月将加时。'),
      ],
      notes: <String>['中气日的秒级边界不能从该转录直接推导，必须由历法事件时间另行验证。'],
    ),
    _rule(
      id: 'dlr.rule.pan.002.month-general-table',
      family: 'pan',
      subfamily: 'calendarMonthGeneral',
      ordinal: 2,
      name: '十二月将表',
      conditions: '大寒/立春起子将，依十二组节气顺列至雨水/惊蛰亥将。',
      interpretation: '冻结转录中的十二组节气/月将目录，尚未逐项回到影印页。',
      targetCapability: 'daliuren.pan.monthGeneralTable',
      targetCodeDomain: 'lib/domain/services/daliuren/yue_jiang_service.dart',
      status: 'adopted',
      evidence: 'B',
      locatorOnly: false,
      sourceRefs: <Map<String, Object?>>[
        _scan(
          zhinanScan,
          '全册',
          scanLeaf: 5,
          pdfPage: 6,
          printedLeaf: '1',
          shortQuote: '雨水亥、春分戌、谷雨酉……冬至丑、大寒子。',
          additionalReviewers: <String>['c00_independent_recheck (Codex)'],
        ),
        _locator(cunyan, '六壬存验-清-吴师青.txt:L332-L344', '十二将：大寒立春子神后……雨水惊蛰亥登明。'),
      ],
    ),
    _rule(
      id: 'dlr.rule.pan.003.heaven-plate-rotation',
      family: 'pan',
      subfamily: 'heavenPlate',
      ordinal: 3,
      name: '月将加时顺布天盘',
      conditions: '月将加到占时地盘宫，天盘十二支固定顺行一周，不因昼夜改方向。',
      interpretation: '该条冻结天地盘坐标关系；昼夜只进入贵人选择，不改变天盘支顺序。',
      targetCapability: 'daliuren.pan.heavenPlate',
      targetCodeDomain: 'lib/domain/services/daliuren/tianpan_service.dart',
      status: 'adopted',
      evidence: 'B',
      locatorOnly: false,
      executableApproved: true,
      fixtureIds: <String>[
        'dlr.case.zhinan.renyin-guimao-liu-tuizhai',
        'dlr.case.zhinan.yiwei-jimao-feng-yunsheng',
        'dlr.case.zhinan.gengyin-gengchen-ma-lianzhuang',
      ],
      sourceRefs: <Map<String, Object?>>[
        _scan(
          zhinanScan,
          '全册',
          scanLeaf: 5,
          pdfPage: 6,
          printedLeaf: '1',
          shortQuote: '月将加占时之上……顺布十二宫辰即天盘也。',
          additionalReviewers: <String>['c00_independent_recheck (Codex)'],
        ),
        _locator(cunyan, '六壬存验-清-吴师青.txt:L329', '顺行十二支，俱无阳阴顺逆之分。'),
      ],
    ),
    _rule(
      id: 'dlr.rule.pan.004.stem-residences',
      family: 'pan',
      subfamily: 'stemResidence',
      ordinal: 4,
      name: '十干寄宫',
      conditions: '甲寅、乙辰、丙戊巳、丁己未、庚申、辛戌、壬亥、癸丑。',
      interpretation: '寄宫用于干课与别责等规则，不得与日禄位置混用。',
      targetCapability: 'daliuren.pan.stemResidence',
      targetCodeDomain: 'lib/domain/services/daliuren/daliuren_constants.dart',
      locatorOnly: false,
      sourceRefs: <Map<String, Object?>>[
        _scan(
          siku,
          '卷一',
          scanLeaf: 11,
          pdfPage: 11,
          printedLeaf: '1a',
          shortQuote: '甲课寅兮乙课辰……癸课原来丑宫坐。',
        ),
        _locator(daquan, 'docs/六壬大全/001巻一 起例.md:L5-L7', '甲课寅兮乙课辰……癸课原来丑宫坐。'),
      ],
    ),
    for (final ({int ordinal, String id, String name, String condition}) item
        in <({
      int ordinal,
      String id,
      String name,
      String condition,
    })>[
      (
        ordinal: 5,
        id: 'first-lesson',
        name: '第一课',
        condition: '以日干寄宫所乘天盘支为上神，日干为下神。'
      ),
      (
        ordinal: 6,
        id: 'second-lesson',
        name: '第二课',
        condition: '以第一课上神所在宫再取天盘支为上神，第一课上神为下神。'
      ),
      (
        ordinal: 7,
        id: 'third-lesson',
        name: '第三课',
        condition: '以日支所乘天盘支为上神，日支为下神。'
      ),
      (
        ordinal: 8,
        id: 'fourth-lesson',
        name: '第四课',
        condition: '以第三课上神所在宫再取天盘支为上神，第三课上神为下神。'
      ),
    ])
      _rule(
        id: 'dlr.rule.pan.${item.ordinal.toString().padLeft(3, '0')}.${item.id}',
        family: 'pan',
        subfamily: 'fourLessons',
        ordinal: item.ordinal,
        name: item.name,
        conditions: item.condition,
        interpretation: '四课必须由完整天地盘和干寄宫构造，缺键不能静默退回本支。',
        targetCapability: 'daliuren.pan.fourLessons.${item.ordinal}',
        targetCodeDomain: 'lib/domain/services/daliuren/si_ke_service.dart',
        status: 'adopted',
        evidence: 'B',
        locatorOnly: false,
        executableApproved: true,
        fixtureIds: <String>[
          'dlr.case.zhinan.renyin-guimao-liu-tuizhai',
          'dlr.case.zhinan.yiwei-jimao-feng-yunsheng',
          'dlr.case.zhinan.gengyin-gengchen-ma-lianzhuang',
        ],
        sourceRefs: <Map<String, Object?>>[
          _scan(
            zhinanScan,
            '全册',
            scanLeaf: 5,
            pdfPage: 6,
            printedLeaf: '1',
            shortQuote: '视阴阳为四课之分。',
            additionalReviewers: <String>['c00_independent_recheck (Codex)'],
          ),
          _locator(cunyan, '六壬存验-清-吴师青.txt:L330', '次起四课……先以占事之日干立起初柱。'),
        ],
      ),
  ];
  return _family('pan', 'partial', '月将、天地盘、寄宫与四课的有限基础目录。', entries);
}

Map<String, Object?> _shenjiang() {
  const String source = 'dlr.source.cunyan-transcription-d2a44794';
  const String siku = 'dlr.source.siku-liuren-daquan';
  const String zhizhi = 'dlr.source.yuding-liuren-zhizhi-candidate';
  final List<Map<String, Object?>> entries = <Map<String, Object?>>[
    _rule(
      id: 'dlr.rule.shenjiang.001.day-night-selection',
      family: 'shenjiang',
      subfamily: 'guiRenSelection',
      ordinal: 1,
      name: '昼夜取贵',
      conditions: '卯至申用阳贵，酉至寅用阴贵；昼夜只负责选贵人支。',
      interpretation: '《直指》逐支给出昼夜边界；《六壬大全》另把十干分昼夜取贵与地盘定顺逆分开，二者不是同一步。',
      targetCapability: 'daliuren.shenjiang.dayNightSelection',
      targetCodeDomain: 'lib/domain/services/daliuren/shen_jiang_service.dart',
      status: 'adopted',
      evidence: 'B',
      locatorOnly: false,
      sourceRefs: <Map<String, Object?>>[
        _scan(
          siku,
          '卷二',
          scanLeaf: 62,
          pdfPage: 62,
          shortQuote: '贵人从十干分昼夜治。',
          reviewer: 'C00 independent scan recheck',
          additionalReviewers: <String>['C04 independent scan audit'],
        ),
        _scan(
          zhizhi,
          '上下卷附析义',
          scanLeaf: 17,
          pdfPage: 18,
          printedLeaf: '七',
          shortQuote: '正时自卯至申用昼贵，即阳贵；自酉至寅用夜贵，即阴贵。',
          reviewer: 'C00 independent scan recheck',
          additionalReviewers: <String>['C04 independent scan audit'],
        ),
        _locator(source, '六壬存验-清-吴师青.txt:L329', '自卯至申为日间时……自酉至寅为夜间时。'),
      ],
      notes: <String>[
        '只批准昼夜边界与“昼夜只用于取贵”的事实；不批准 002/003 贵人整表，也不把昼夜解释为顺逆。',
        '缺少已批准的夜贵顺/逆完整课例，故保持 executableApproved=false。',
      ],
    ),
    _rule(
      id: 'dlr.rule.shenjiang.002.yang-gui-table',
      family: 'shenjiang',
      subfamily: 'guiRenSelection',
      ordinal: 2,
      name: '十干阳贵表',
      conditions: '甲丑、己子、乙子、庚丑、丙亥、辛午、丁亥、壬巳、戊丑、癸巳。',
      interpretation: '固定转录表与候选《直指》完整表在甲乙丙辛壬五干冲突；待主底本影印页核定后才能采用。',
      targetCapability: 'daliuren.shenjiang.yangGuiTable',
      targetCodeDomain: 'lib/domain/services/daliuren/daliuren_constants.dart',
      sourceRefs: <Map<String, Object?>>[
        _scan(
          zhizhi,
          '上下卷附析义',
          scanLeaf: 17,
          pdfPage: 18,
          printedLeaf: '七',
          shortQuote: '庚戊见牛甲在羊，乙猴己鼠丙鸡方，丁猪癸蛇壬兔位，六辛逢虎贵为阳。',
          reviewer: 'C00 independent scan recheck',
          additionalReviewers: <String>['C04 independent scan audit'],
        ),
        _locator(source, '六壬存验-清-吴师青.txt:L347-L349', '阳贵：甲丑，己子，乙子，庚丑……'),
      ],
      variantGroupId: 'dlr.variant.gui-ren-table',
    ),
    _rule(
      id: 'dlr.rule.shenjiang.003.yin-gui-table',
      family: 'shenjiang',
      subfamily: 'guiRenSelection',
      ordinal: 3,
      name: '十干阴贵表',
      conditions: '甲未、己申、乙申、庚未、丙酉、辛寅、丁酉、壬卯、戊未、癸卯。',
      interpretation: '固定转录表与候选《直指》完整表在甲乙丙辛壬五干冲突；阴阳两表必须成组裁决。',
      targetCapability: 'daliuren.shenjiang.yinGuiTable',
      targetCodeDomain: 'lib/domain/services/daliuren/daliuren_constants.dart',
      sourceRefs: <Map<String, Object?>>[
        _scan(
          zhizhi,
          '上下卷附析义',
          scanLeaf: 17,
          pdfPage: 18,
          printedLeaf: '七',
          shortQuote: '甲贵阴牛庚戊羊，乙贵在鼠己猴乡，丙猪丁鸡辛遇马，壬蛇癸兔属阴方。',
          reviewer: 'C00 independent scan recheck',
          additionalReviewers: <String>['C04 independent scan audit'],
        ),
        _locator(source, '六壬存验-清-吴师青.txt:L347-L349', '阴贵：甲未，己申，乙申，庚未……'),
      ],
      variantGroupId: 'dlr.variant.gui-ren-table',
    ),
    _rule(
      id: 'dlr.rule.shenjiang.004.direction-by-earth-palace',
      family: 'shenjiang',
      subfamily: 'layoutDirection',
      ordinal: 4,
      name: '贵人落地宫定顺逆',
      conditions: '天盘贵人临地盘亥子丑寅卯辰则顺，临巳午未申酉戌则逆。',
      interpretation: '《直指》逐支明言六位顺、六位逆；《六壬大全》的“地盘一定顺逆”与天门地户说是同一方法的原则解释。',
      targetCapability: 'daliuren.shenjiang.actualDirection',
      targetCodeDomain: 'lib/domain/services/daliuren/shen_jiang_service.dart',
      status: 'adopted',
      evidence: 'B',
      locatorOnly: false,
      sourceRefs: <Map<String, Object?>>[
        _scan(
          siku,
          '卷二',
          scanLeaf: 59,
          pdfPage: 59,
          shortQuote: '地盘一定顺逆之序，顺布者则背天门，逆布者则向地户。',
          reviewer: 'C00 independent scan recheck',
          additionalReviewers: <String>['C04 independent scan audit'],
        ),
        _scan(
          siku,
          '卷二',
          scanLeaf: 62,
          pdfPage: 62,
          shortQuote: '顺治谓在天门之前、地户之后；逆治谓在地户之前、天门之后。',
          reviewer: 'C00 independent scan recheck',
          additionalReviewers: <String>['C04 independent scan audit'],
        ),
        _scan(
          zhizhi,
          '上下卷附析义',
          scanLeaf: 18,
          pdfPage: 19,
          printedLeaf: '八',
          shortQuote: '贵人加于亥子丑寅卯辰六位则顺行，加于巳午未申酉戌六位则逆行。',
          reviewer: 'C04 independent scan audit',
        ),
        _locator(source, '六壬存验-清-吴师青.txt:L329', '贵临地盘亥子丑寅卯辰六位顺行……巳午未申酉戌六位逆行。'),
      ],
      variantGroupId: 'dlr.variant.gui-ren-direction',
      adoptedVariantId: 'landing-palace-six-zones',
      notes: <String>[
        '三张已批准《指南》课例只覆盖昼贵顺与昼贵逆；缺夜贵顺/逆批准课例，故保持 executableApproved=false。',
      ],
    ),
    _rule(
      id: 'dlr.rule.shenjiang.005.twelve-generals-order',
      family: 'shenjiang',
      subfamily: 'generalOrder',
      ordinal: 5,
      name: '十二天将次序',
      conditions: '贵人、螣蛇、朱雀、六合、勾陈、青龙、天空、白虎、太常、玄武、太阴、天后。',
      interpretation: '卷二直接列贵人前后诸将，可还原固定身份次序；方向只改变布列方向。',
      targetCapability: 'daliuren.shenjiang.generalOrder',
      targetCodeDomain: 'lib/domain/services/daliuren/daliuren_constants.dart',
      status: 'adopted',
      evidence: 'B',
      locatorOnly: false,
      sourceRefs: <Map<String, Object?>>[
        _scan(
          siku,
          '卷二',
          scanLeaf: 58,
          pdfPage: 58,
          shortQuote: '前有五位一蛇二雀三合四勾五龙……后有五位一后二阴三玄四常五虎。',
          reviewer: 'C00 independent scan recheck',
          additionalReviewers: <String>['C04 independent scan audit'],
        ),
        _scan(
          zhizhi,
          '上下卷附析义',
          scanLeaf: 18,
          pdfPage: 19,
          printedLeaf: '八',
          shortQuote: '一贵人、二螣蛇、三朱雀、四六合、五勾陈、六青龙、七天空、八白虎、九太常、十玄武、十一太阴、十二天后。',
          reviewer: 'C04 independent scan audit',
        ),
        _locator(source, '六壬存验-清-吴师青.txt:L345-L346', '十二神：贵人、螣蛇、朱雀、六合……天后。'),
      ],
    ),
    _rule(
      id: 'dlr.rule.shenjiang.006.dual-coordinate-layout',
      family: 'shenjiang',
      subfamily: 'coordinateContract',
      ordinal: 6,
      name: '天盘起贵与地盘定向坐标分工',
      conditions: '以课之天盘起贵神，再以贵人所临地盘宫定顺逆；两类坐标不得混为同一事实。',
      interpretation: '主底本直接区分“以课之天盘起贵神”与“地盘一定顺逆”的坐标职责；显式保存两张 map 和双坐标 position 是项目数据契约，不是古籍逐字结构。',
      targetCapability: 'daliuren.shenjiang.dualCoordinates',
      targetCodeDomain:
          'lib/divination_systems/daliuren/models/shen_jiang_config.dart',
      status: 'adopted',
      evidence: 'B',
      locatorOnly: false,
      sourceRefs: <Map<String, Object?>>[
        _scan(
          siku,
          '卷二',
          scanLeaf: 58,
          pdfPage: 58,
          shortQuote: '以课之天盘起贵神之例。',
          reviewer: 'C00 independent scan recheck',
          additionalReviewers: <String>['C04 independent scan audit'],
        ),
        _scan(
          siku,
          '卷二',
          scanLeaf: 59,
          pdfPage: 59,
          shortQuote: '地盘一定顺逆之序。',
          reviewer: 'C00 independent scan recheck',
          additionalReviewers: <String>['C04 independent scan audit'],
        ),
        _locator(source, '六壬存验-清-吴师青.txt:L329', '是以天盘之贵而临地盘之六位，非贵在地盘也。'),
      ],
      notes: <String>[
        '古籍 attribution 只支持坐标职责分工；tianBranchToGeneral、earthPalaceToGeneral 及双坐标 positions 由项目执行规则承担。',
        '完整排将链缺夜贵顺/逆批准课例，故保持 executableApproved=false。',
      ],
    ),
  ];
  return _family('shenjiang', 'partial', '贵人选择、落宫、顺逆和十二天将坐标的有限目录。', entries);
}

Map<String, Object?> _jiuzongmen() {
  const String source = 'dlr.source.daquan-transcription-aa7bc942';
  const String siku = 'dlr.source.siku-liuren-daquan';
  final List<
      ({
        String id,
        String name,
        String locator,
        String quote,
        String conditions,
        int scanPage,
        String printedLeaf,
        String? variant,
        List<String> fixtures,
      })> seeds = <({
    String id,
    String name,
    String locator,
    String quote,
    String conditions,
    int scanPage,
    String printedLeaf,
    String? variant,
    List<String> fixtures,
  })>[
    (
      id: 'zeike',
      name: '贼克法',
      locator: 'docs/六壬大全/001巻一 起例.md:L9-L11',
      quote: '取课先从下贼呼，如无下贼上克初。',
      conditions: '四课有克时先取下贼上；没有下贼上才取上克下，初传取所选课上神。',
      scanPage: 11,
      printedLeaf: '1a',
      variant: null,
      fixtures: <String>['dlr.case.cunyan.dingchou-yiyou-pregnancy'],
    ),
    (
      id: 'biyong',
      name: '比用法',
      locator: 'docs/六壬大全/001巻一 起例.md:L13-L15',
      quote: '阳日用阳阴用阴。若或俱比俱不比，立法别有涉害陈。',
      conditions: '同向多克候选按日干阴阳取相比者；俱比或俱不比转涉害。',
      scanPage: 11,
      printedLeaf: '1a',
      variant: null,
      fixtures: <String>[
        'dlr.case.cunyan.renwu-bingxu-exam',
        'dlr.case.cunyan.wuzi-bingzi-promotion',
      ],
    ),
    (
      id: 'shehai',
      name: '涉害法',
      locator: 'docs/六壬大全/001巻一 起例.md:L17-L19',
      quote: '涉害行来本家止，路逢多克为用取。孟深仲浅季当休，复等柔辰刚日宜。',
      conditions: '候选沿地盘归本家计涉害深浅；并列再按孟仲与刚柔先见裁决。',
      scanPage: 12,
      printedLeaf: '1b',
      variant: 'dlr.variant.shehai-tie-break',
      fixtures: <String>[
        'dlr.case.zhinan.gengyin-gengchen-ma-lianzhuang',
      ],
    ),
    (
      id: 'yaoke',
      name: '遥克法',
      locator: 'docs/六壬大全/001巻一 起例.md:L21-L23',
      quote: '神遥克日曰蒿矢，日遥克神曰弹射。',
      conditions: '四课无直接克时先取上神遥克日干（蒿矢），再取日干遥克上神（弹射）；多者比用。',
      scanPage: 12,
      printedLeaf: '1b',
      variant: null,
      fixtures: <String>[],
    ),
    (
      id: 'maoxing',
      name: '昴星法',
      locator: 'docs/六壬大全/001巻一 起例.md:L25-L27',
      quote: '无遥无克昴星穷，阳仰阴俯酉位中。',
      conditions: '四课全且无直接克、无遥克；刚日仰视地盘酉上，柔日俯视天盘酉所临地盘。',
      scanPage: 13,
      printedLeaf: '2a',
      variant: null,
      fixtures: <String>[],
    ),
    (
      id: 'bieze',
      name: '别责法',
      locator: 'docs/六壬大全/001巻一 起例.md:L29-L31',
      quote: '刚日干合上头神，柔日支前三合取。',
      conditions: '三课备且无克、无遥克；刚日取干合之寄宫上神，柔日取支三合前辰，中末皆干上。',
      scanPage: 13,
      printedLeaf: '2a',
      variant: 'dlr.variant.bieze-yang-method',
      fixtures: <String>[],
    ),
    (
      id: 'bazhuan',
      name: '八专法',
      locator: 'docs/六壬大全/001巻一 起例.md:L33-L35',
      quote: '两课无克号八专，阳日日阳顺行三……阴日辰阴逆三位。',
      conditions: '干支同位、课内无克；阳日从日上顺数三，阴日从辰阴逆数三，中末并日上。',
      scanPage: 14,
      printedLeaf: '2b',
      variant: 'dlr.variant.bazhuan-with-ke-label',
      fixtures: <String>[],
    ),
    (
      id: 'fuyin',
      name: '伏吟法',
      locator: 'docs/六壬大全/001巻一 起例.md:L37-L39',
      quote: '伏吟有克还为用，无克刚干柔取辰。迤逦刑之作中末。',
      conditions: '天地盘同位；有克按克取用，无克刚取干上柔取支上，中末走刑链，自刑按日辰与冲退路。',
      scanPage: 14,
      printedLeaf: '2b',
      variant: null,
      fixtures: <String>[],
    ),
    (
      id: 'fanyin',
      name: '返吟法',
      locator: 'docs/六壬大全/001巻一 起例.md:L41-L43',
      quote: '若知六日该无克，丑未同干丁己辛。',
      conditions: '天地盘相冲；有克按克取用，无克限丁己辛之丑未六日取井栏射。',
      scanPage: 15,
      printedLeaf: '3a',
      variant: 'dlr.variant.fanyin-terminology',
      fixtures: <String>['dlr.case.cunyan.wuzi-bingzi-promotion'],
    ),
  ];
  final List<Map<String, Object?>> entries = <Map<String, Object?>>[
    for (int index = 0; index < seeds.length; index++)
      _rule(
        id: 'dlr.rule.jiuzongmen.${(index + 1).toString().padLeft(3, '0')}.${seeds[index].id}',
        family: 'jiuzongmen',
        subfamily: 'threeTransmissionSelection',
        ordinal: index + 1,
        name: seeds[index].name,
        conditions: seeds[index].conditions,
        interpretation: '影印页已完成首次视觉定位；独立复核、异文裁决与完整外例完成前不批准执行扩展。',
        targetCapability: 'daliuren.jiuzongmen.${seeds[index].id}',
        targetCodeDomain: 'lib/domain/services/daliuren/san_chuan_service.dart',
        locatorOnly: false,
        sourceRefs: <Map<String, Object?>>[
          _scan(
            siku,
            '卷一',
            scanLeaf: seeds[index].scanPage,
            pdfPage: seeds[index].scanPage,
            printedLeaf: seeds[index].printedLeaf,
            shortQuote: seeds[index].quote,
          ),
          _locator(source, seeds[index].locator, seeds[index].quote),
        ],
        variantGroupId: seeds[index].variant,
        fixtureIds: seeds[index].fixtures,
      ),
  ];
  return _family('jiuzongmen', 'partial', '九宗门恰好九法的候选规则目录。', entries);
}

Map<String, Object?> _derivedFacts() {
  const String daquan = 'dlr.source.daquan-transcription-aa7bc942';
  final List<Map<String, Object?>> entries = <Map<String, Object?>>[
    _rule(
      id: 'dlr.rule.derived-facts.001.xun-context',
      family: 'derivedFacts',
      subfamily: 'xun',
      ordinal: 1,
      name: '六旬旬首',
      conditions: '由日柱或显式采用的时柱确定所属六旬与旬首。',
      interpretation: '旬上下文必须记录采用日旬还是时旬，不能只输出展示词。',
      targetCapability: 'daliuren.derivedFacts.xunContext',
      targetCodeDomain: 'lib/domain/services/daliuren/',
      evidence: 'D',
      sourceRefs: <Map<String, Object?>>[],
      notes: <String>['当前只冻结软件所需事实边界，影印规则 locus 未核。'],
    ),
    _rule(
      id: 'dlr.rule.derived-facts.002.kongwang',
      family: 'derivedFacts',
      subfamily: 'xun',
      ordinal: 2,
      name: '旬空',
      conditions: '每旬缺出的两支为空亡；采用的旬轴必须随事实保存。',
      interpretation: '空亡是客观派生事实，填实或喜惧另由分析与应期规则解释。',
      targetCapability: 'daliuren.derivedFacts.kongWang',
      targetCodeDomain: 'lib/domain/services/daliuren/',
      evidence: 'C',
      sourceRefs: <Map<String, Object?>>[
        _locator(daquan, 'docs/六壬大全/011巻十一 《毕法赋》上.md:L95-L99', '旬内空亡逐类推。'),
      ],
    ),
    _rule(
      id: 'dlr.rule.derived-facts.003.transmission-dungan',
      family: 'derivedFacts',
      subfamily: 'dunGan',
      ordinal: 3,
      name: '三传旬遁干',
      conditions: '在采用的六旬上下文中，为初中末传各自地支配旬遁天干；无干位置显式为空。',
      interpretation: '旬遁干、天盘干与天干寄宫必须使用不同 typed 字段。',
      targetCapability: 'daliuren.derivedFacts.transmissionDunGan',
      targetCodeDomain: 'lib/domain/services/daliuren/',
      evidence: 'D',
      sourceRefs: <Map<String, Object?>>[],
    ),
    _rule(
      id: 'dlr.rule.derived-facts.004.wangxiang-five-states',
      family: 'derivedFacts',
      subfamily: 'strength',
      ordinal: 4,
      name: '旺相休囚死五态',
      conditions: '依据月令与五行关系为每个课传事实标记旺、相、休、囚、死之一。',
      interpretation: '五态是事实，不可压缩为 isWangXiang 布尔值或直接作为最终吉凶。',
      targetCapability: 'daliuren.derivedFacts.strength',
      targetCodeDomain: 'lib/domain/services/daliuren/',
      evidence: 'C',
      sourceRefs: <Map<String, Object?>>[
        _locator(
            daquan, 'docs/六壬大全/007巻七 课经集（一）.md:L73-L91', '旺气言官职……相气论……死、囚、休气。'),
      ],
    ),
    _rule(
      id: 'dlr.rule.derived-facts.005.six-relations',
      family: 'derivedFacts',
      subfamily: 'relations',
      ordinal: 5,
      name: '三传六亲',
      conditions: '以每传五行相对日干五行派生父母、兄弟、子孙、妻财、官鬼。',
      interpretation: '六亲关系必须对初中末传对称产出，并保留原始五行关系。',
      targetCapability: 'daliuren.derivedFacts.sixRelations',
      targetCodeDomain: 'lib/domain/services/daliuren/',
      evidence: 'C',
      fixtureIds: <String>[
        'dlr.case.zhinan.gengyin-gengchen-ma-lianzhuang',
      ],
      sourceRefs: <Map<String, Object?>>[
        _locator(
            daquan, 'docs/六壬大全/010巻十 课经集（四）.md:L769', '凡课俱取初传动爻，以别五行六亲、物类亲疏。'),
      ],
    ),
    _rule(
      id: 'dlr.rule.derived-facts.006.five-element-relation-to-day-stem',
      family: 'derivedFacts',
      subfamily: 'relations',
      ordinal: 6,
      name: '每传对日干五行关系',
      conditions: '每传分别记录生我、我生、克我、我克、同我；六合等旁系事实另列。',
      interpretation: '六合不得覆盖实际克身关系，事实层允许多关系并存。',
      targetCapability: 'daliuren.derivedFacts.relationToDayStem',
      targetCodeDomain: 'lib/domain/services/daliuren/',
      evidence: 'D',
      sourceRefs: <Map<String, Object?>>[],
    ),
  ];
  return _family(
      'derivedFacts', 'locatorOnly', '旬空、遁干、旺相与日干关系的有限事实目录。', entries);
}

class _ShenShaSeed {
  const _ShenShaSeed({
    required this.name,
    required this.subfamily,
    required this.scanPage,
    this.status = 'pending',
    this.notes = const <String>[],
  });

  final String name;
  final String subfamily;
  final int scanPage;
  final String status;
  final List<String> notes;
}

class _ShenShaReviewSeed {
  const _ShenShaReviewSeed(
    this.name,
    this.scanPage,
    this.shortQuote,
    this.conditions, {
    this.subfamily,
    this.status = 'adopted',
    this.evidence = 'B',
    this.locatorOnly = false,
  });

  final String name;
  final int scanPage;
  final String shortQuote;
  final String conditions;
  final String? subfamily;
  final String status;
  final String evidence;
  final bool locatorOnly;
}

const List<_ShenShaReviewSeed> _shenshaFrontReviews = <_ShenShaReviewSeed>[
  _ShenShaReviewSeed(
    '岁君',
    26,
    '歲君：甲見甲之類。年中天子之象，統攝諸位神煞。',
    '岁干同干之类；原文另述占尊长、部官及不宜受尅',
  ),
  _ShenShaReviewSeed(
    '太岁',
    26,
    '太歲：子年見子之類。',
    '岁支同支；六月前后另分旧年、来年太岁所主',
  ),
  _ShenShaReviewSeed(
    '年冲',
    27,
    '太歲排輪十二宮，歲破大耗與年沖。',
    '与岁破、大耗同列太岁对冲组；不从名称另造算法',
  ),
  _ShenShaReviewSeed(
    '死符',
    27,
    '前五死符并小耗。',
    '太岁前五，与小耗并列',
  ),
  _ShenShaReviewSeed(
    '太阴',
    27,
    '後二太陰并弔客。',
    '太岁后二，与吊客并列',
  ),
  _ShenShaReviewSeed(
    '白虎',
    27,
    '後四白虎是凶神。',
    '太岁后四',
  ),
  _ShenShaReviewSeed(
    '畜官',
    27,
    '歲前二辰喪門凶，前四畜官官符神。',
    '太岁前四；与官符同句',
  ),
  _ShenShaReviewSeed(
    '官符',
    27,
    '歲前二辰喪門凶，前四畜官官符神。',
    '太岁前四；与畜官同句',
  ),
  _ShenShaReviewSeed(
    '力士',
    27,
    '太歲前維力士位。',
    '仅按原文“太岁前维”保存；“维”不得擅自 typed 化',
  ),
  _ShenShaReviewSeed(
    '蚕室',
    27,
    '對沖蠶室有災星。',
    '对冲位',
  ),
  _ShenShaReviewSeed(
    '奏书',
    27,
    '奏書後維沖博士。',
    '奏书与博士以后维、冲位相对；精确坐标仍须后续 fixture',
  ),
  _ShenShaReviewSeed(
    '博士',
    27,
    '奏書後維沖博士。',
    '同上；不按目录次序推断优先级',
  ),
  _ShenShaReviewSeed(
    '五鬼',
    27,
    '五鬼逆行子加辰。',
    '子位起辰，逆行',
  ),
  _ShenShaReviewSeed(
    '黄幡',
    27,
    '黃幡只向三合末。',
    '取三合末；“末”以影印字形为准',
  ),
  _ShenShaReviewSeed(
    '豹尾',
    27,
    '對沖豹尾不虛云。',
    '与黄幡对冲',
  ),
  _ShenShaReviewSeed(
    '伏兵',
    27,
    '三合中沖兩邊干，便是伏兵大禍神。',
    '三合中冲两边干；保持原文，不先转换 typed 坐标',
  ),
  _ShenShaReviewSeed(
    '大祸',
    27,
    '三合中沖兩邊干，便是伏兵大禍神。',
    '与伏兵同句同维度',
  ),
  _ShenShaReviewSeed(
    '将军',
    27,
    '亥子丑年將軍酉，三年一移順仲神；子丑寅卯辰巳午未申酉戌亥／酉酉子子子卯卯卯午午午酉。',
    '年支表为酉酉子子子卯卯卯午午午酉',
  ),
  _ShenShaReviewSeed(
    '岁刑',
    28,
    '子丑寅卯辰巳午未申酉戌亥／歲刑卯戌巳子辰申午丑寅酉未亥。',
    '按年支取十二值',
  ),
  _ShenShaReviewSeed(
    '岁破',
    28,
    '歲破午未申酉戌亥子丑寅卯辰巳，即歲沖也。',
    '按年支取对冲十二值',
  ),
  _ShenShaReviewSeed(
    '岁煞',
    28,
    '歲煞未辰丑戌未辰丑戌未辰丑戌。',
    '按年支取十二值',
  ),
  _ShenShaReviewSeed(
    '大耗',
    28,
    '大耗午未申酉戌亥子丑寅卯辰巳，歲建前破也。',
    '按年支取十二值',
  ),
  _ShenShaReviewSeed(
    '小耗',
    28,
    '小耗巳午未申酉戌亥子丑寅卯辰，歲建前執也。',
    '按年支取十二值',
  ),
  _ShenShaReviewSeed(
    '丧门',
    28,
    '喪門，歲前二辰。',
    '太岁前二辰',
  ),
  _ShenShaReviewSeed(
    '吊客',
    29,
    '弔客，歲後二辰。',
    '太岁后二辰',
  ),
  _ShenShaReviewSeed(
    '岁墓',
    29,
    '歲墓，歲後五位，如子年見未。',
    '太岁后五位',
  ),
  _ShenShaReviewSeed(
    '岁德',
    29,
    '歲德，即歲君，陰年從陽，如己年見甲之例。',
    '同岁君；阴年从阳',
  ),
  _ShenShaReviewSeed(
    '岁合',
    29,
    '歲合，即甲年見己。',
    '岁干合；原页只举甲见己',
  ),
  _ShenShaReviewSeed(
    '年月三煞',
    29,
    '年月三煞未辰丑戌未辰丑戌未辰丑戌。',
    '按年支或月支表头取十二值；两维同表',
  ),
  _ShenShaReviewSeed(
    '金神',
    29,
    '金神酉巳丑酉巳丑酉巳丑酉巳丑，即破碎。',
    '按年支取十二值',
  ),
  _ShenShaReviewSeed(
    '岁宅',
    29,
    '歲宅，歲前五位，如子年見巳，即小耗。',
    '太岁前五位；与小耗同位',
  ),
  _ShenShaReviewSeed(
    '病符',
    29,
    '病符，歲後一辰。',
    '太岁后一辰',
  ),
  _ShenShaReviewSeed(
    '岁虎',
    30,
    '歲虎，歲後四辰。',
    '太岁后四辰',
  ),
  _ShenShaReviewSeed(
    '福星',
    30,
    '甲乙丙丁戊己庚辛壬癸／福星子丑子子未未丑丑巳巳。',
    '按日干甲至癸取十值',
  ),
  _ShenShaReviewSeed(
    '日德',
    30,
    '日德寅申巳亥巳寅申巳亥巳。',
    '按日干甲至癸取十值',
  ),
  _ShenShaReviewSeed(
    '日禄',
    30,
    '日祿寅卯巳午巳午申酉亥子。',
    '按日干甲至癸取十值',
  ),
  _ShenShaReviewSeed(
    '日医',
    30,
    '日醫卯亥丑未巳卯亥丑未巳。',
    '按日干甲至癸取十值',
  ),
  _ShenShaReviewSeed(
    '直符',
    30,
    '直符巳辰卯寅丑午未申酉戌。',
    '按日干甲至癸取十值',
  ),
  _ShenShaReviewSeed(
    '仪神',
    31,
    '儀神午巳辰卯寅丑未申酉戌。',
    '按日干甲至癸取十值',
  ),
  _ShenShaReviewSeed(
    '游都',
    31,
    '遊都丑子寅巳申丑子寅巳申。',
    '按日干甲至癸取十值',
  ),
  _ShenShaReviewSeed(
    '天盗',
    31,
    '天盜子亥卯申巳子亥卯申巳。',
    '按日干甲至癸取十值',
  ),
  _ShenShaReviewSeed(
    '天贼',
    31,
    '天賊辰午申亥寅辰午申亥寅。',
    '按日干甲至癸取十值',
  ),
  _ShenShaReviewSeed(
    '稼穑',
    31,
    '稼穡丑丑辰辰未未戌戌戌戌。',
    '按日干甲至癸取十值',
  ),
  _ShenShaReviewSeed(
    '羊刃',
    31,
    '羊刃卯辰午未午未酉戌子丑。',
    '按日干甲至癸取十值',
  ),
  _ShenShaReviewSeed(
    '天罗',
    31,
    '天羅卯巳午申午申酉亥子寅，日前一位。',
    '按日干甲至癸取十值；页下注“日前一位”',
  ),
  _ShenShaReviewSeed(
    '天阙',
    31,
    '天闕亥申未丑酉亥申未丑酉。',
    '按日干甲至癸取十值',
  ),
  _ShenShaReviewSeed(
    '三奇',
    32,
    '三奇乙丙丁；三奇甲戊庚；三奇辛壬癸。',
    '影印只支持三组干名；未说明触发、组合顺序或优先级',
  ),
  _ShenShaReviewSeed(
    '支德',
    32,
    '子丑寅卯辰巳午未申酉戌亥／支德巳午未申酉戌亥子丑寅卯辰，支前五辰。',
    '按日支取十二值',
  ),
  _ShenShaReviewSeed(
    '支马',
    32,
    '支馬寅亥申巳寅亥申巳寅亥申巳。',
    '按日支取十二值',
  ),
  _ShenShaReviewSeed(
    '支刑',
    32,
    '支刑卯戌巳子辰申午丑寅酉未亥。',
    '按日支取十二值',
  ),
  _ShenShaReviewSeed(
    '支破',
    33,
    '支破酉辰亥午丑申卯戌巳子未寅；陽日後三辰，陰日前三辰。',
    '按日支取十二值，并有阴阳日前后注',
  ),
  _ShenShaReviewSeed(
    '支冲',
    33,
    '支沖，即對宮。',
    '日支对宫',
  ),
  _ShenShaReviewSeed(
    '支害',
    33,
    '支害未子巳辰卯寅丑子亥戌酉申。',
    '影印第二值明确似“子”，使丑日值与常见六害结构冲突',
    status: 'disputed',
  ),
  _ShenShaReviewSeed(
    '关',
    33,
    '關巳寅亥申巳寅亥申巳寅亥申。',
    '影印题名为单字“關”，按日支表头列十二值；与固定转录“时煞”及逐月表“关神”的关系未决。',
    subfamily: 'dayBranch',
    status: 'disputed',
    evidence: 'C',
    locatorOnly: true,
  ),
  _ShenShaReviewSeed(
    '支仪',
    33,
    '支儀午巳辰卯寅丑未申酉戌亥子。',
    '按日支取十二值',
  ),
  _ShenShaReviewSeed(
    '金神',
    33,
    '金神巳丑酉巳丑酉巳丑酉巳丑酉。',
    '按日支取十二值',
  ),
  _ShenShaReviewSeed(
    '关魂',
    33,
    '關魂：凡墓神為元武皆是。',
    '墓神乘元武',
  ),
  _ShenShaReviewSeed(
    '马倒',
    33,
    '馬倒：驛馬前一位。',
    '驿马前一位',
  ),
  _ShenShaReviewSeed(
    '劫煞',
    34,
    '劫殺災殺歲殺知，天殺月殺地殺齊。',
    '仅在地支神煞歌诀列名，无本条表值',
  ),
  _ShenShaReviewSeed(
    '灾煞',
    34,
    '劫殺災殺歲殺知，天殺月殺地殺齊。',
    '仅歌诀列名，无本条表值',
  ),
  _ShenShaReviewSeed(
    '岁煞',
    34,
    '劫殺災殺歲殺知，天殺月殺地殺齊。',
    '仅歌诀列名，无本条表值',
  ),
  _ShenShaReviewSeed(
    '天煞',
    34,
    '劫殺災殺歲殺知，天殺月殺地殺齊。',
    '仅歌诀列名，无本条表值',
  ),
  _ShenShaReviewSeed(
    '月煞',
    34,
    '劫殺災殺歲殺知，天殺月殺地殺齊。',
    '仅歌诀列名，无本条表值',
  ),
  _ShenShaReviewSeed(
    '地煞',
    34,
    '劫殺災殺歲殺知，天殺月殺地殺齊。',
    '仅歌诀列名，无本条表值',
  ),
  _ShenShaReviewSeed(
    '亡神',
    34,
    '亡神將星扳鞍是，驛馬六厄華蓋馳。',
    '仅歌诀列名，无本条表值',
  ),
  _ShenShaReviewSeed(
    '将星',
    34,
    '亡神將星扳鞍是，驛馬六厄華蓋馳。',
    '仅歌诀列名，无本条表值',
  ),
  _ShenShaReviewSeed(
    '扳鞍',
    34,
    '亡神將星扳鞍是，驛馬六厄華蓋馳。',
    '仅歌诀列名，无本条表值',
  ),
  _ShenShaReviewSeed(
    '驿马',
    34,
    '亡神將星扳鞍是，驛馬六厄華蓋馳。',
    '仅歌诀列名，无本条表值',
  ),
  _ShenShaReviewSeed(
    '六厄',
    34,
    '亡神將星扳鞍是，驛馬六厄華蓋馳。',
    '仅歌诀列名，无本条表值',
  ),
  _ShenShaReviewSeed(
    '华盖',
    34,
    '亡神將星扳鞍是，驛馬六厄華蓋馳。',
    '仅歌诀列名，无本条表值',
  ),
  _ShenShaReviewSeed(
    '天德',
    35,
    '天德丁坤壬辛亥甲癸寅丙乙巳庚。',
    '按正月至十二月取十二值；混含“坤”方位字，照录不归一化',
  ),
  _ShenShaReviewSeed(
    '月德',
    35,
    '月德巳寅亥申三輪。',
    '巳寅亥申循环三轮',
  ),
  _ShenShaReviewSeed(
    '月合',
    35,
    '月合辛巳丁乙三輪。',
    '辛巳丁乙循环三轮',
  ),
  _ShenShaReviewSeed(
    '天马',
    35,
    '天馬午順六陽。',
    '午起，顺六阳；不先补成十二支表',
  ),
  _ShenShaReviewSeed(
    '天喜',
    35,
    '天喜春戌夏丑秋辰冬未。',
    '按四季取戌丑辰未',
  ),
  _ShenShaReviewSeed(
    '天诏',
    35,
    '天詔、遊魂亥順十二。',
    '与游魂同为亥起顺十二',
  ),
  _ShenShaReviewSeed(
    '游魂',
    35,
    '天詔、遊魂亥順十二。',
    '与天诏同为亥起顺十二',
  ),
  _ShenShaReviewSeed(
    '天赦',
    35,
    '天赦春戊寅夏甲午秋戊申冬甲子。',
    '按四季取四个干支',
  ),
  _ShenShaReviewSeed(
    '天医',
    35,
    '天醫子卯午酉三輪。',
    '子卯午酉循环三轮',
  ),
  _ShenShaReviewSeed(
    '天书',
    35,
    '天書戌順十二。',
    '戌起顺十二',
  ),
  _ShenShaReviewSeed(
    '皇恩',
    35,
    '皇恩戌丑辰未卯酉子午亥寅巳申。',
    '按正月至十二月取十二值',
  ),
  _ShenShaReviewSeed(
    '圣心',
    35,
    '聖心亥巳子午丑未寅申卯酉辰戌。',
    '按正月至十二月取十二值',
  ),
  _ShenShaReviewSeed(
    '进爵',
    35,
    '進爵申亥巳申亥巳申亥巳申亥巳。',
    '按正月至十二月取十二值',
  ),
  _ShenShaReviewSeed(
    '凤辇',
    35,
    '鳳輦辰未戌丑三輪。',
    '辰未戌丑循环三轮',
  ),
  _ShenShaReviewSeed(
    '銮舆',
    35,
    '鑾輿戌丑辰未三輪。',
    '戌丑辰未循环三轮',
  ),
  _ShenShaReviewSeed(
    '会神',
    35,
    '會神未戌寅亥酉子丑午巳卯申辰。',
    '按正月至十二月取十二值',
  ),
  _ShenShaReviewSeed(
    '天解',
    35,
    '天解申戌子寅辰午申戌子寅辰午。',
    '按正月至十二月取十二值',
  ),
  _ShenShaReviewSeed(
    '皇书',
    35,
    '皇書春寅夏巳秋申冬亥。',
    '按四季取寅巳申亥',
  ),
  _ShenShaReviewSeed(
    '解神',
    35,
    '解神申申酉酉戌戌亥亥午午未未。',
    '按正月至十二月取十二值',
  ),
  _ShenShaReviewSeed(
    '风煞',
    36,
    '風煞申逆十二。',
    '申起逆行十二',
  ),
  _ShenShaReviewSeed(
    '游神',
    36,
    '遊神春丑夏子秋戌冬亥，主行人至。',
    '按四季取丑、子、戌、亥；原文另述主行人至。',
    subfamily: 'seasonalMonthlyFormula',
  ),
  _ShenShaReviewSeed(
    '管神',
    36,
    '管神、天車、寡神：春丑夏辰秋未冬戌。',
    '与天车、寡神同组，按四季取丑辰未戌',
  ),
  _ShenShaReviewSeed(
    '天车',
    36,
    '管神、天車、寡神：春丑夏辰秋未冬戌。',
    '与管神、寡神同组，按四季取丑、辰、未、戌。',
    subfamily: 'seasonalMonthlyFormula',
  ),
  _ShenShaReviewSeed(
    '寡神',
    36,
    '管神、天車、寡神：春丑夏辰秋未冬戌。',
    '与管神、天车同组，按四季取丑、辰、未、戌；不与逐月表寡宿静默合并。',
    subfamily: 'seasonalMonthlyFormula',
  ),
  _ShenShaReviewSeed(
    '戏神',
    36,
    '戲神春巳夏子秋酉冬辰。',
    '按四季取巳子酉辰',
  ),
  _ShenShaReviewSeed(
    '信煞',
    36,
    '信煞酉順十二，主遞信至。',
    '酉起顺行十二',
  ),
  _ShenShaReviewSeed(
    '信神',
    36,
    '信神申戌寅丑亥辰巳未巳未申戌。',
    '按正月至十二月取十二值',
  ),
  _ShenShaReviewSeed(
    '成神',
    36,
    '成神巳申亥寅三輪。',
    '巳申亥寅循环三轮',
  ),
  _ShenShaReviewSeed(
    '福星',
    36,
    '福星甲丙丁在子，乙庚辛在丑，戊己在未，壬癸在巳。',
    '明确按日干分组，不是季节或逐月式',
    subfamily: 'dayStem',
  ),
  _ShenShaReviewSeed(
    '天巫',
    36,
    '天巫主婚姻，辰順十二。',
    '辰起顺行十二',
  ),
  _ShenShaReviewSeed(
    '生气',
    36,
    '生氣子順十二。',
    '子起顺行十二',
  ),
  _ShenShaReviewSeed(
    '喝散',
    36,
    '喝散、禁神、孤神：春巳夏申秋亥冬寅。',
    '与禁神、孤神同组，按四季取巳申亥寅',
  ),
  _ShenShaReviewSeed(
    '禁神',
    36,
    '喝散、禁神、孤神：春巳夏申秋亥冬寅。',
    '与喝散、孤神同组，按四季取巳申亥寅',
    subfamily: 'seasonalMonthlyFormula',
  ),
  _ShenShaReviewSeed(
    '孤神',
    36,
    '喝散、禁神、孤神：春巳夏申秋亥冬寅。',
    '与喝散、禁神同组，按四季取巳申亥寅；不与逐月表孤辰静默合并。',
    subfamily: 'seasonalMonthlyFormula',
  ),
  _ShenShaReviewSeed(
    '雨煞',
    36,
    '雨煞、災煞子酉午卯三輪。',
    '与灾煞同为子酉午卯循环三轮',
  ),
  _ShenShaReviewSeed(
    '灾煞',
    36,
    '雨煞、災煞子酉午卯三輪。',
    '与雨煞同为子酉午卯循环三轮',
  ),
  _ShenShaReviewSeed(
    '雌虎',
    36,
    '天雞、雌虎、地醫酉逆十二。',
    '与天鸡、地医同为酉起逆行十二',
  ),
  _ShenShaReviewSeed(
    '天鸡',
    36,
    '天雞、雌虎、地醫酉逆十二。',
    '与雌虎、地医同为酉起逆行十二。',
    subfamily: 'seasonalMonthlyFormula',
  ),
  _ShenShaReviewSeed(
    '地医',
    36,
    '天雞、雌虎、地醫酉逆十二。',
    '与天鸡、雌虎同为酉起逆行十二',
  ),
  _ShenShaReviewSeed(
    '游煞',
    36,
    '遊煞卯順十二。',
    '卯起顺行十二',
  ),
  _ShenShaReviewSeed(
    '转煞',
    36,
    '轉煞。',
    '影印可见题名，未见可无歧义归属本条的公式',
  ),
  _ShenShaReviewSeed(
    '天目',
    36,
    '天目春辰夏未秋戌冬丑。',
    '按四季取辰未戌丑',
  ),
  _ShenShaReviewSeed(
    '月符',
    36,
    '月符春辰夏未秋戌冬丑。',
    '按四季取辰未戌丑',
  ),
  _ShenShaReviewSeed(
    '天鬼',
    36,
    '天鬼酉午卯子三輪。',
    '酉午卯子循环三轮',
  ),
  _ShenShaReviewSeed(
    '天咒',
    36,
    '天咒酉午卯子三輪。',
    '酉午卯子循环三轮',
  ),
  _ShenShaReviewSeed(
    '天转',
    36,
    '天轉春乙卯夏丙午秋辛酉冬壬子。',
    '按四季取四个干支',
  ),
  _ShenShaReviewSeed(
    '地转',
    36,
    '地轉春辛卯夏戊午秋癸酉冬丙子。',
    '按四季取四个干支',
  ),
  _ShenShaReviewSeed(
    '天厕',
    36,
    '天廁寅巳申亥三輪。',
    '寅巳申亥循环三轮',
  ),
  _ShenShaReviewSeed(
    '天耳',
    36,
    '天耳春戌夏丑秋辰冬未。',
    '按四季取戌丑辰未',
  ),
  _ShenShaReviewSeed(
    '天坑',
    36,
    '天坑丑順十二。',
    '丑起顺行十二',
  ),
  _ShenShaReviewSeed(
    '天盗',
    36,
    '天盜春酉夏午秋卯冬子。',
    '按四季取酉午卯子',
  ),
  _ShenShaReviewSeed(
    '天煞',
    36,
    '天煞正月丑逆行四季，見之并朱雀克日主怪異。',
    '仅可冻结“正月丑、逆行四季”原文，不据此补造十二值',
  ),
  _ShenShaReviewSeed(
    '天狱',
    36,
    '天獄春未夏戌秋丑冬辰。',
    '按四季取未戌丑辰',
  ),
  _ShenShaReviewSeed(
    '月冲',
    37,
    '月沖申順十二。',
    '申起顺行十二',
  ),
];

String? _shenshaPrintedLeaf(int scanPage) => switch (scanPage) {
      26 => '8b',
      27 => '9a',
      28 => '9b',
      29 => '10a',
      30 => '10b',
      31 => '11a',
      32 => '11b',
      33 => '12a',
      34 => '12b',
      35 => '13a',
      36 => '13b',
      37 => '14a',
      _ => null,
    };

const int _shenshaExpectedEntryCount = 238;
const int _shenshaExpectedFrontReviewCount = 124;

List<String> _normalizedMonthlyGridShenShaNames(String rawName) =>
    switch (rawName) {
      '亡神孤辰' => <String>['亡神', '孤辰'],
      '煞神枯骨' => <String>['煞神', '枯骨'],
      '会[部' => <String>['会神'],
      '四放心' => <String>['四废'],
      '孤神' => <String>['孤辰'],
      '杀神' => <String>['煞神'],
      '天杀' => <String>['天煞'],
      '天时' => <String>['大时'],
      '月皮' => <String>['月破'],
      '驿心' => <String>['圣心'],
      '阴死' => <String>['受死'],
      '阴灾' => <String>['阴煞'],
      '浴神' => <String>['浴盆'],
      '灾神' => <String>['灾煞'],
      '战难' => <String>['战雌'],
      _ => <String>[rawName],
    };

Map<String, Object?> _shensha() {
  const String scanSource = 'dlr.source.siku-liuren-daquan';
  final List<_ShenShaSeed> seeds = <_ShenShaSeed>[];
  final Set<String> subfamilyNames = <String>{};

  void addNames(
    String subfamily,
    int scanPage,
    String names, {
    String status = 'pending',
    List<String> notes = const <String>[],
  }) {
    for (final String rawName in names.split(RegExp(r'\s+'))) {
      if (rawName.isEmpty) {
        continue;
      }
      for (final String name in <String>[rawName]) {
        if (!subfamilyNames.add('$subfamily::$name')) {
          continue;
        }
        seeds.add(
          _ShenShaSeed(
            name: name,
            subfamily: subfamily,
            scanPage: scanPage,
            status: status,
            notes: <String>[
              ...notes,
              if (rawName != name) '固定转录 token“$rawName”经两轮影印复核归并为“$name”。',
            ],
          ),
        );
      }
    }
  }

  addNames('annual', 26, '岁君 太岁');
  addNames(
    'annual',
    27,
    '年冲 死符 太阴 白虎 畜官 官符 力士 蚕室 奏书 博士 五鬼 黄幡 豹尾 伏兵 大祸 将军',
  );
  addNames('annual', 28, '将军 岁刑 岁破 岁煞 大耗 小耗 丧门');
  addNames('annual', 29, '吊客 岁墓 岁德 岁合 年月三煞 金神 岁宅 病符');
  addNames('annual', 30, '岁虎');

  addNames('dayStem', 30, '福星 日德 日禄 日医 直符');
  addNames('dayStem', 31, '仪神 游都 天盗 天贼 稼穑 羊刃 天罗 天阙');
  addNames(
    'dayStem',
    32,
    '三奇',
    notes: <String>['影印页列乙丙丁、甲戊庚、辛壬癸三组三奇；三组条件暂不拆成可执行规则。'],
  );

  addNames('dayBranch', 32, '支德 支马 支刑');
  addNames('dayBranch', 33, '支破 支冲 支害 关 支仪 金神 关魂 马倒');
  addNames(
    'dayBranch',
    34,
    '劫煞 灾煞 岁煞 天煞 月煞 地煞 亡神 将星 扳鞍 驿马 六厄 华盖',
  );

  addNames(
    'seasonalMonthlyFormula',
    35,
    '天德 月德 月合 天马 天喜 天诏 游魂 天赦 天医 天书 皇恩 圣心 进爵 凤辇 銮舆 会神 天解 皇书 解神',
  );
  addNames(
    'seasonalMonthlyFormula',
    36,
    '风煞 游神 管神 天车 寡神 戏神 信煞 信神 成神 福星 天巫 生气 喝散 禁神 孤神 雨煞 灾煞 雌虎 天鸡 地医 游煞 转煞 天目 月符 天鬼 天咒 天转 地转 天厕 天耳 天坑 天盗 天煞 天狱',
  );
  addNames(
    'seasonalMonthlyFormula',
    37,
    '月冲 月破 月刑 月害 井煞 小煞 煞神 大时 小时 地狱 受死 市曹 飞廉 死气 谩语 死神 游祸 墓门 女灾 飞祸 贼神 绳索 长绳',
  );
  addNames(
    'seasonalMonthlyFormula',
    38,
    '绞神 勾神 奸门 奸神 白浪 覆舟 旬盗 日盗 丧魂 往亡 产煞 血忌 岁虎 飞横 黄幡 豹尾 血支 邪神 时盗 五盗 咸池 火鬼 火怪 天车 雷煞 火烛 天机 阴煞 丧魄 火神 悬索 月鬼 忧神',
  );

  const Map<int, String> monthlyFirstOccurrences = <int, String>{
    39: '豹尾 成神 雌虎 大祸 大时 盗神 地医 地狱 吊客 风煞 勾陈 寡宿 关神 喝散 皇书 火鬼 火神 奸神 雷煞 吏神 谩语 迷惑 日煞 三丘 上丧 生气 绳索 时盗 时煞 市曹 死气 死神 螣蛇 天厕 天车 天盗 天耳 天机 天牢 天马 天目 天日 天煞 天巫 天医 天狱 外解 亡神孤辰 往亡 戏神 咸池 小煞 悬索 血忌 血支 钥神 阴煞 忧神 游祸 游煞 游神 雨煞 雨师 浴盆 月德 月符 月煞 灾煞 贼神 战雄 朱雀',
    40: '白虎 病煞 大煞 飞横 飞祸 飞廉 风伯 伏殃 皇恩 黄幡 会神 昏迷 火灾 奸淫 绞神 劫煞 解神 金神 枯骨 哭神 门神 灭门 墓门 内解 女灾 破碎 丧车 丧魄 杀神 神豪 圣心 受死 四废 岁煞 天德 天鬼 天猴 天鸡 天解 天空 天赦 天师 天吞 天喜 天刑 天诏 亡神 五墓 下丧 邪神 信煞 信神 玄武 血腥 阳煞 驿马 游魂 狱神 月鬼 月破 月厌 战雌 长绳',
    41: '勾神 孤辰 火怪 煞神 天火',
    42: '孤神 管神 天书 刑亡',
    43: '战难',
    44: '天杀',
    45: '天恩 驿心',
    46: '会[部',
    47: '天六 阴死',
    48: '月皮',
    49: '天神',
    50: '大神 丧魁 四放心 天时',
    54: '煞神枯骨 岁神',
    55: '阴灾',
    56: '奸门 浴神 灾神',
  };
  final Set<String> knownNames =
      seeds.map((_ShenShaSeed seed) => seed.name).toSet();
  for (final MapEntry<int, String> page in monthlyFirstOccurrences.entries) {
    for (final String rawName in page.value.split(RegExp(r'\s+'))) {
      for (final String name in _normalizedMonthlyGridShenShaNames(rawName)) {
        if (!knownNames.add(name)) {
          continue;
        }
        seeds.add(
          _ShenShaSeed(
            name: name,
            subfamily: 'monthlyGridOnly',
            scanPage: page.key,
            notes: <String>[
              '该名在逐月十二支表中首次定位；目录身份已复核，起例维度、同名关系和表值未冻结。',
              if (rawName != name) '固定转录 token“$rawName”经两轮影印复核归并为“$name”。',
            ],
          ),
        );
      }
    }
  }

  seeds.addAll(<_ShenShaSeed>[
    const _ShenShaSeed(
      name: '内天罡行十二经络',
      subfamily: 'excludedMedicalFlow',
      scanPage: 34,
      status: 'excluded',
      notes: <String>['这是按时辰流转经络的医占附表，不作为基础盘神煞落宫规则。'],
    ),
    const _ShenShaSeed(
      name: '逐月神煞排列表（索引结构）',
      subfamily: 'excludedIndexStructure',
      scanPage: 39,
      status: 'excluded',
      notes: <String>['逐月表是目录索引，不另算一个神煞；其中只见于表内的名称已逐项登记。'],
    ),
    const _ShenShaSeed(
      name: '总钤/德煞续篇',
      subfamily: 'excludedAdjacentSection',
      scanPage: 57,
      status: 'excluded',
      notes: <String>['PDF 57 另起“总钤/德煞”，不纳入 PDF 26-56 的本次有限清单。'],
    ),
  ]);

  if (seeds.length != _shenshaExpectedEntryCount) {
    throw StateError(
      'ShenSha seed count drifted: expected $_shenshaExpectedEntryCount, '
      'found ${seeds.length}.',
    );
  }
  if (_shenshaFrontReviews.length != _shenshaExpectedFrontReviewCount) {
    throw StateError(
      'ShenSha front-review count drifted: '
      'expected $_shenshaExpectedFrontReviewCount, '
      'found ${_shenshaFrontReviews.length}.',
    );
  }
  for (int index = 0; index < _shenshaFrontReviews.length; index++) {
    if (seeds[index].name != _shenshaFrontReviews[index].name) {
      throw StateError(
        'ShenSha source-order drift at ordinal ${index + 1}: '
        'seed=${seeds[index].name}, review=${_shenshaFrontReviews[index].name}.',
      );
    }
  }

  String conditionsFor(_ShenShaSeed seed) => switch (seed.subfamily) {
        'monthlyGridOnly' => '逐月十二支表中可见该名；本轮只冻结目录身份与首见页，不批准表值或同名合并。',
        'excludedMedicalFlow' ||
        'excludedIndexStructure' ||
        'excludedAdjacentSection' =>
          '明确排除项；仅保存目录边界，不进入实现候选。',
        _ => '影印正文中可见该名；本轮只冻结目录身份与首见页，不批准 typed 起例。',
      };

  List<Map<String, Object?>> sourceRefsFor(
    int index,
    _ShenShaSeed seed,
    _ShenShaReviewSeed? review,
  ) {
    final int scanPage = review?.scanPage ?? seed.scanPage;
    final bool isFrontReview = review != null;
    final bool isSingleReview = review?.evidence == 'C';
    final String reviewer = isSingleReview
        ? 'c00_shensha_review_a (Codex)'
        : 'C00 finite shensha first-pass scan audit';
    final List<String> additionalReviewers = isSingleReview
        ? const <String>[]
        : <String>[
            isFrontReview
                ? 'c00_shensha_review_a (Codex)'
                : 'root / Codex independent pass B',
          ];

    if (index == 17) {
      return <Map<String, Object?>>[
        _scan(
          scanSource,
          '卷一',
          scanLeaf: 27,
          pdfPage: 27,
          printedLeaf: '9a',
          shortQuote: '亥子丑年將軍酉，三年一移順仲神。',
          reviewer: reviewer,
          additionalReviewers: additionalReviewers,
        ),
        _scan(
          scanSource,
          '卷一',
          scanLeaf: 28,
          pdfPage: 28,
          printedLeaf: '9b',
          shortQuote: '子丑寅卯辰巳午未申酉戌亥／酉酉子子子卯卯卯午午午酉。',
          reviewer: reviewer,
          additionalReviewers: additionalReviewers,
        ),
      ];
    }

    final List<Map<String, Object?>> refs = <Map<String, Object?>>[
      _scan(
        scanSource,
        '卷一',
        scanLeaf: scanPage,
        pdfPage: scanPage,
        printedLeaf: isFrontReview ? _shenshaPrintedLeaf(scanPage) : null,
        shortQuote: review?.shortQuote ?? seed.name,
        reviewer: reviewer,
        additionalReviewers: additionalReviewers,
      ),
    ];
    final List<({int page, String quote})> repeats =
        switch (review?.name ?? seed.name) {
      '游神' => <({int page, String quote})>[
          (page: 39, quote: '逐月神煞表另见游神。'),
        ],
      '天车' => <({int page, String quote})>[
          (page: 38, quote: '天车。'),
        ],
      '天鸡' => <({int page, String quote})>[
          (page: 40, quote: '逐月神煞表另见天鸡。'),
        ],
      '孤辰' => <({int page, String quote})>[
          (page: 41, quote: '孤辰。'),
          (page: 42, quote: '孤辰。'),
        ],
      _ => const <({int page, String quote})>[],
    };
    for (final ({int page, String quote}) repeat in repeats) {
      refs.add(
        _scan(
          scanSource,
          '卷一',
          scanLeaf: repeat.page,
          pdfPage: repeat.page,
          shortQuote: repeat.quote,
          reviewer: 'C00 finite shensha first-pass scan audit',
          additionalReviewers: <String>['root / Codex independent pass B'],
        ),
      );
    }
    return refs;
  }

  final List<Map<String, Object?>> entries = <Map<String, Object?>>[
    for (int index = 0; index < seeds.length; index++)
      _rule(
        id: 'dlr.rule.shensha.${(index + 1).toString().padLeft(3, '0')}',
        family: 'shensha',
        subfamily: index < _shenshaFrontReviews.length
            ? _shenshaFrontReviews[index].subfamily ?? seeds[index].subfamily
            : seeds[index].subfamily,
        ordinal: index + 1,
        name: seeds[index].name,
        conditions: index < _shenshaFrontReviews.length
            ? _shenshaFrontReviews[index].conditions
            : conditionsFor(seeds[index]),
        interpretation: seeds[index].status == 'excluded'
            ? '本条冻结排除边界，不授权任何产品算法。'
            : index < _shenshaFrontReviews.length
                ? '本条采用主底本目录身份、影印短引与非 typed 条件摘要；不批准执行条件、优先级或 fixture。'
                : '本条只采用主底本有限目录身份与首次影印页；不批准表值、typed 起例、优先级或 fixture。',
        targetCapability:
            'daliuren.shensha.${(index + 1).toString().padLeft(3, '0')}',
        targetCodeDomain: 'lib/domain/services/daliuren/shen_sha_service.dart',
        status: index < _shenshaFrontReviews.length
            ? _shenshaFrontReviews[index].status
            : seeds[index].status == 'excluded'
                ? 'excluded'
                : 'adopted',
        evidence: index < _shenshaFrontReviews.length
            ? _shenshaFrontReviews[index].evidence
            : 'B',
        locatorOnly: index < _shenshaFrontReviews.length
            ? _shenshaFrontReviews[index].locatorOnly
            : false,
        sourceRefs: sourceRefsFor(
          index,
          seeds[index],
          index < _shenshaFrontReviews.length
              ? _shenshaFrontReviews[index]
              : null,
        ),
        variantGroupId: seeds[index].name == '支害'
            ? 'dlr.variant.shensha-zhi-hai-second-value'
            : <String>{'关', '关神', '时煞'}.contains(seeds[index].name)
                ? 'dlr.variant.shensha-guan-identity'
                : <String>{'孤神', '孤辰'}.contains(seeds[index].name)
                    ? 'dlr.variant.shensha-gushen-guchen-identity'
                    : null,
        notes: <String>[
          ...seeds[index].notes,
          if (seeds[index].name == '支害')
            '目录身份与影印字形已核；第二值影印似“子”，与常见六害结构冲突，保持 disputed。',
          if (seeds[index].name == '关')
            'C00 首次冻结前新增；单字“關”与固定转录“时煞”、逐月表“关神”的关系未决。',
          if (seeds[index].name == '寡神') 'C00 首次冻结前新增；不得与逐月表“寡宿”静默合并。',
          if (seeds[index].name == '禁神') '后出逐页全页清点确认其与喝散、孤神并列；旧 236 项门禁因此作废。',
          if (seeds[index].name == '孤神')
            'PDF 36 正文独立题名；不得受逐月表 OCR 的“孤神→孤辰”校正影响。',
          if (seeds[index].name == '孤辰')
            '逐月表 PDF 39、41、42 均保留孤辰身份；不得与 PDF 36 正文孤神静默合并。',
          'adopted 仅表示目录身份采用；executableApproved 保持 false。',
        ],
      ),
  ];
  return _family(
    'shensha',
    'partial',
    '四库本卷一 PDF 26-56 的 238 项首次冻结目录；除支害条件、单字“关”及孤神/孤辰关系未决外，目录身份已完成二审，typed 起例留待 C06。',
    entries,
    expectedEntryCount: _shenshaExpectedEntryCount,
  );
}

class _CatalogSeed {
  const _CatalogSeed(this.name, this.locator, [this.notes = const <String>[]]);

  final String name;
  final String locator;
  final List<String> notes;
}

Map<String, Object?> _kejing() {
  const String source = 'dlr.source.daquan-transcription-aa7bc942';
  const String scanSource = 'dlr.source.siku-liuren-daquan';
  const List<int> scanPages = <int>[
    35,
    49,
    57,
    64,
    81,
    93,
    104,
    109,
    120,
    136,
    147,
    154,
    160,
    170,
    176,
    179,
    3,
    9,
    16,
    21,
    27,
    35,
    38,
    43,
    53,
    59,
    62,
    68,
    73,
    85,
    105,
    113,
    132,
    140,
    146,
    3,
    12,
    28,
    31,
    41,
    48,
    51,
    56,
    76,
    85,
    94,
    101,
    108,
    117,
    122,
    131,
    139,
    3,
    9,
    15,
    28,
    40,
    44,
    68,
    78,
    83,
    94,
    100,
    102,
  ];
  const List<String> scanQuotes = <String>[
    '凡一上克下，餘課無克，為元首課，象天如君克臣必順。',
    '凡一下賊上，餘課無克，為重審課，象地事逆，以下犯上。',
    '凡課有二上克下，或二下克上，擇課之陰陽與今日比者而為用神，曰知一課。',
    '凡課有二上克下，或二下克上，與今日俱比俱不比，則以涉地盤歸本家受克深處為用，為涉害課。',
    '凡課無克，取日干與四課上神相克者為用，曰遙克課。',
    '凡四課上下無相克，又無遙克，取從魁上下神為用，曰昴星課。',
    '凡三課無克，別取一神為用，曰別責格。',
    '凡干支同位無克，取陽順陰逆三神為用，曰八專課。',
    '定章曰：此謂日辰合為一神，陰陽不相克，剛日從陽順數至三神。',
    '凡課十二神各居沖位，取相克為用，曰返吟課。',
    '凡課用神日辰旺相，吉神在中，為三光課。',
    '凡課天乙順行，日辰有氣，居前旺相，氣發用，為三陽課。',
    '凡課得旬日之奇發用，或入傳，為三奇課。',
    '凡課的旬首之儀發用，或入傳，為六儀課。',
    '凡課用起太歲月建，乘青龍六合，又帶財德之神，為時泰課。',
    '凡太歲月將乘貴人發用，為龍德課。',
    '凡課得歲月年命驛馬發用，又天魁太常入傳，為官爵課。',
    '凡課得天乙乘旺相氣，上下相生，更臨日辰年命發用，為富貴課。',
    '凡課的勝光為用，遇太沖神后，為軒蓋課。',
    '凡課得戌加巳，申傳，為鑄印課。',
    '凡課卯加庚或加辛為用，曰斫輪課。',
    '凡課日辰干支前後上神發用為初末傳，曰引從課。',
    '凡課用神生日，及三傳遞生日干，或干支俱互生旺，為亨通課。',
    '凡夫妻年立德方發用，為繁昌課。',
    '凡祿馬貴人臨干支年命，併旺相氣發用入傳，更乘吉將，為榮華課。',
    '凡課日辰干支德神及天月二德發用，併在年命乘吉將，為德慶課。',
    '凡課日辰遇天干作合，及支三合六合發用，併占人年命俱乘吉將，為合歡課。',
    '凡課干支遇三合六合，上下遞互相合，取為和美課。',
    '凡卦魁罡加日辰發用，為斬關課。',
    '凡旬尾加旬首，或旬首乘玄武，或旬首位上神乘玄武發用者，為閉口課。',
    '凡課三傳皆土，遇旬丁天馬為用，曰游子課。',
    '凡四仲日占，四仲加日辰，三傳皆仲，皆逢陰合，為三交課。',
    '凡課日干剋辰，又自加臨為用，曰贅婿課。',
    '凡課日辰之沖神加破為用，曰沖破課。',
    '凡課初傳卯酉為用，將乘后合，為淫泆課。',
    '凡四課有尅缺一為不備，及日辰交互相尅，為無淫課。',
    '凡夫妻行年沖克，及上下神互相克賊，為解離格。',
    '度厄：三上克下曰幼度厄，三下賊上曰長度厄。',
    '凡課四上俱克下，為無祿課。',
    '凡八迍課得五福，為迍福課。',
    '凡課日辰六害相加，並行年為用，為侵害課。',
    '凡課中三刑發用，併行年，為刑傷課。',
    '凡四仲月將遇四正及四平日占，得日月宿加四仲，斗罡繫五未，為二煩課。',
    '凡四立日占，得今日干支臨昨日干支，或昨日干支臨今日干支，為天禍課。',
    '凡課囚死墓神發用，斗係日本，為天獄卦。',
    '凡四離日占，得月宿加離辰，為天寇課。',
    '凡課占時與用神同克日，為天網課。',
    '凡白虎帶死神死氣，臨日辰行年發用，為魄化課。',
    '凡天乙逆行，日辰在後，用其凶死將乘玄虎，時克行年，為三陰卦。',
    '凡卯酉日占，卯酉為用，人年立卯酉，為龍戰課。',
    '凡干罡係日辰，陰陽發用，為死奇課。',
    '凡喪車、遊魂、伏殃、病符、喪吊、丘墓、歲虎發用者，為災厄課也。',
    '凡三傳遞克日神，將克戰，或干支乘墓，為殃咎課。',
    '凡戊子、戊午、壬子、壬午、乙卯、乙酉、己卯、己酉、辛卯、辛酉十日為九醜日。',
    '凡日辰墓神及日鬼發用，為鬼墓課。',
    '凡天乙立卯酉，為勵德課。',
    '凡太歲月建及日時并三傳皆在四課之中，曰盤珠課也。',
    '凡課得三合俱在傳者，為全局課。',
    '凡孟神發用，傳皆四孟，為玄胎課。',
    '凡用神傳在一方相連作中末，為連珠課。',
    '凡課間位作三傳，為間傳課。',
    '六純格。',
    '凡課俱取初傳動爻，以別五行純雜數目物色為用，曰雜狀課。',
    '物類課。',
  ];
  final List<_CatalogSeed> seeds = <_CatalogSeed>[
    _CatalogSeed('元首课', 'docs/六壬大全/007巻七 课经集（一）.md:L3'),
    _CatalogSeed('重审课', 'docs/六壬大全/007巻七 课经集（一）.md:L101'),
    _CatalogSeed('知一课', 'docs/六壬大全/007巻七 课经集（一）.md:L171'),
    _CatalogSeed('涉害课', 'docs/六壬大全/007巻七 课经集（一）.md:L253-L255'),
    _CatalogSeed('遥克课', 'docs/六壬大全/007巻七 课经集（一）.md:L443'),
    _CatalogSeed('昴星课', 'docs/六壬大全/007巻七 课经集（一）.md:L585'),
    _CatalogSeed('别责课', 'docs/六壬大全/007巻七 课经集（一）.md:L689'),
    _CatalogSeed('八专课', 'docs/六壬大全/007巻七 课经集（一）.md:L731'),
    _CatalogSeed('伏吟课', 'docs/六壬大全/007巻七 课经集（一）.md:L871'),
    _CatalogSeed('返吟课', 'docs/六壬大全/007巻七 课经集（一）.md:L1049',
        <String>['产品展示统一使用“反吟”，传统名原样保留。']),
    _CatalogSeed('三光课', 'docs/六壬大全/007巻七 课经集（一）.md:L1167'),
    _CatalogSeed('三阳课', 'docs/六壬大全/007巻七 课经集（一）.md:L1265'),
    _CatalogSeed('三奇课', 'docs/六壬大全/007巻七 课经集（一）.md:L1321'),
    _CatalogSeed('六仪课', 'docs/六壬大全/007巻七 课经集（一）.md:L1413'),
    _CatalogSeed('时泰课', 'docs/六壬大全/007巻七 课经集（一）.md:L1493'),
    _CatalogSeed('龙德课', 'docs/六壬大全/007巻七 课经集（一）.md:L1531'),
    _CatalogSeed('官爵课', 'docs/六壬大全/008巻八 课经集（二）.md:L3'),
    _CatalogSeed('富贵课', 'docs/六壬大全/008巻八 课经集（二）.md:L83'),
    _CatalogSeed('轩盖课', 'docs/六壬大全/008巻八 课经集（二）.md:L143'),
    _CatalogSeed('铸印课', 'docs/六壬大全/008巻八 课经集（二）.md:L197'),
    _CatalogSeed('斫轮课', 'docs/六壬大全/008巻八 课经集（二）.md:L257'),
    _CatalogSeed('引从课', 'docs/六壬大全/008巻八 课经集（二）.md:L321'),
    _CatalogSeed('亨通课', 'docs/六壬大全/008巻八 课经集（二）.md:L355'),
    _CatalogSeed('繁昌课', 'docs/六壬大全/008巻八 课经集（二）.md:L389'),
    _CatalogSeed('荣华课', 'docs/六壬大全/008巻八 课经集（二）.md:L499'),
    _CatalogSeed('德庆课', 'docs/六壬大全/008巻八 课经集（二）.md:L555'),
    _CatalogSeed('合欢课', 'docs/六壬大全/008巻八 课经集（二）.md:L585'),
    _CatalogSeed('和美课', 'docs/六壬大全/008巻八 课经集（二）.md:L619'),
    _CatalogSeed('斩关课', 'docs/六壬大全/008巻八 课经集（二）.md:L647'),
    _CatalogSeed('闭口课', 'docs/六壬大全/008巻八 课经集（二）.md:L739'),
    _CatalogSeed('游子课', 'docs/六壬大全/009巻九 课经集（三）.md:L3'),
    _CatalogSeed('三交课', 'docs/六壬大全/009巻九 课经集（三）.md:L71'),
    _CatalogSeed('赘婿课', 'docs/六壬大全/009巻九 课经集（三）.md:L215'),
    _CatalogSeed('冲破课', 'docs/六壬大全/009巻九 课经集（三）.md:L303'),
    _CatalogSeed('淫泆课', 'docs/六壬大全/009巻九 课经集（三）.md:L339'),
    _CatalogSeed(
      '无淫课',
      'docs/六壬大全/009巻九 课经集（三）.md:L419',
      <String>['主底本题名为“無淫課”；固定转录“芜淫课”仅登记为异文，不作为 adopted 目录名。'],
    ),
    _CatalogSeed(
      '解离课',
      'docs/六壬大全/009巻九 课经集（三）.md:L559',
      <String>['主底本题名后缀作“解離格”；规范目录统一使用“解离课”。'],
    ),
    _CatalogSeed('度厄课', 'docs/六壬大全/009巻九 课经集（三）.md:L725'),
    _CatalogSeed('无禄绝嗣课', 'docs/六壬大全/009巻九 课经集（三）.md:L815'),
    _CatalogSeed('迍福课', 'docs/六壬大全/009巻九 课经集（三）.md:L951'),
    _CatalogSeed('侵害课', 'docs/六壬大全/009巻九 课经集（三）.md:L1003'),
    _CatalogSeed('刑伤课', 'docs/六壬大全/009巻九 课经集（三）.md:L1035'),
    _CatalogSeed('二烦课', 'docs/六壬大全/009巻九 课经集（三）.md:L1091'),
    _CatalogSeed('天祸课', 'docs/六壬大全/009巻九 课经集（三）.md:L1247'),
    _CatalogSeed(
      '天狱课',
      'docs/六壬大全/009巻九 课经集（三）.md:L1341',
      <String>['主底本定义称“天獄卦”；规范目录统一使用“天狱课”。'],
    ),
    _CatalogSeed('天寇课', 'docs/六壬大全/009巻九 课经集（三）.md:L1443'),
    _CatalogSeed('天网课', 'docs/六壬大全/009巻九 课经集（三）.md:L1515'),
    _CatalogSeed('魄化课', 'docs/六壬大全/009巻九 课经集（三）.md:L1607'),
    _CatalogSeed(
      '三阴课',
      'docs/六壬大全/009巻九 课经集（三）.md:L1707',
      <String>['主底本定义称“三陰卦”；规范目录统一使用“三阴课”。'],
    ),
    _CatalogSeed('龙战课', 'docs/六壬大全/009巻九 课经集（三）.md:L1765'),
    _CatalogSeed('死奇课', 'docs/六壬大全/009巻九 课经集（三）.md:L1873'),
    _CatalogSeed('灾厄课', 'docs/六壬大全/009巻九 课经集（三）.md:L1957'),
    _CatalogSeed('殃咎课', 'docs/六壬大全/010巻十 课经集（四）.md:L3'),
    _CatalogSeed('九丑课', 'docs/六壬大全/010巻十 课经集（四）.md:L51'),
    _CatalogSeed('鬼墓课', 'docs/六壬大全/010巻十 课经集（四）.md:L113'),
    _CatalogSeed('励德课', 'docs/六壬大全/010巻十 课经集（四）.md:L197'),
    _CatalogSeed('盘珠课', 'docs/六壬大全/010巻十 课经集（四）.md:L369'),
    _CatalogSeed('全局课', 'docs/六壬大全/010巻十 课经集（四）.md:L409'),
    _CatalogSeed(
      '玄胎课',
      'docs/六壬大全/010巻十 课经集（四）.md:L549',
      <String>['主底本题名与定义均作“玄胎課”；固定转录“元胎课”仅登记为异文。'],
    ),
    _CatalogSeed('连珠课', 'docs/六壬大全/010巻十 课经集（四）.md:L635'),
    _CatalogSeed('间传课', 'docs/六壬大全/010巻十 课经集（四）.md:L657'),
    _CatalogSeed(
      '六纯课',
      'docs/六壬大全/010巻十 课经集（四）.md:L687',
      <String>['主底本题名后缀作“六純格”；规范目录统一使用“六纯课”。'],
    ),
    _CatalogSeed('杂状课', 'docs/六壬大全/010巻十 课经集（四）.md:L763'),
    _CatalogSeed('物类课', 'docs/六壬大全/010巻十 课经集（四）.md:L769'),
  ];
  if (scanPages.length != seeds.length || scanQuotes.length != seeds.length) {
    throw StateError('Kejing scan metadata must contain exactly 64 rows.');
  }
  final List<Map<String, Object?>> entries = <Map<String, Object?>>[
    for (int index = 0; index < seeds.length; index++)
      _rule(
        id: 'dlr.rule.kejing.${(index + 1).toString().padLeft(3, '0')}',
        family: 'kejing',
        subfamily: 'kejingCatalog',
        ordinal: index + 1,
        name: seeds[index].name,
        conditions: '本条只冻结六十四课经目录身份；typed 命中条件须由影印正文和独立正反例另行批准。',
        interpretation: '主底本题名、起始影印页与短引已完成独立二审；本条不批准完整充分必要条件或执行优先级。',
        targetCapability:
            'daliuren.kejing.${(index + 1).toString().padLeft(3, '0')}',
        targetCodeDomain: 'lib/domain/services/daliuren/kejing/',
        status: 'adopted',
        evidence: 'B',
        locatorOnly: false,
        sourceRefs: <Map<String, Object?>>[
          _scan(
            scanSource,
            switch (index) {
              < 16 => '卷四至五',
              < 35 => '卷六',
              < 52 => '卷七',
              _ => '卷八',
            },
            scanLeaf: scanPages[index],
            pdfPage: scanPages[index],
            shortQuote: scanQuotes[index],
            reviewer: 'C00 catalog first-pass scan audit',
            additionalReviewers: const <String>[
              'c00_kejing_recheck (Codex)',
            ],
          ),
          _locator(
            source,
            seeds[index].locator,
            switch (index + 1) {
              36 => '芜淫课',
              59 => '元胎课',
              _ => seeds[index].name,
            },
          ),
        ],
        fixtureIds: switch (index + 1) {
          2 => <String>[
              'dlr.case.cunyan.dingchou-yiyou-pregnancy',
              'dlr.case.zhinan.renyin-guimao-liu-tuizhai',
              'dlr.case.zhinan.yiwei-jimao-feng-yunsheng',
            ],
          3 => <String>[
              'dlr.case.cunyan.renwu-bingxu-exam',
              'dlr.case.cunyan.wuzi-bingzi-promotion',
            ],
          4 => <String>[
              'dlr.case.zhinan.gengyin-gengchen-ma-lianzhuang',
            ],
          10 => <String>['dlr.case.cunyan.wuzi-bingzi-promotion'],
          29 => <String>[
              'dlr.case.zhinan.renyin-guimao-liu-tuizhai',
            ],
          61 => <String>[
              'dlr.case.zhinan.gengyin-gengchen-ma-lianzhuang',
            ],
          _ => <String>[],
        },
        notes: <String>[
          ...seeds[index].notes,
          'B 级只覆盖目录身份、起始影印页与本条短引；typed 条件、重叠关系、优先级和正反 fixture 仍待后续批准。',
          'printed leaf 未建立独立映射，继续保持 null。',
        ],
      ),
  ];
  return _family(
    'kejing',
    'partial',
    '恰好六十四个稳定课经 ID；目录身份、起始影印页与短引均完成 B 级独立二审。',
    entries,
  );
}

class _BifaReviewSeed {
  const _BifaReviewSeed(
    this.name,
    this.scanPage,
    this.shortQuote, {
    this.status = 'adopted',
  });

  final String name;
  final int scanPage;
  final String shortQuote;
  final String status;
}

const List<_BifaReviewSeed> _bifaReviews = <_BifaReviewSeed>[
  _BifaReviewSeed(
    '前后引从升迁吉',
    9,
    '前後引從陞遷吉',
  ),
  _BifaReviewSeed(
    '首尾相见始终宜',
    14,
    '首尾相見始終宜',
  ),
  _BifaReviewSeed(
    '帘幕贵人高甲第',
    17,
    '簾幕貴人高甲第',
  ),
  _BifaReviewSeed(
    '催官使者赴官期',
    21,
    '催官使者赴官期',
  ),
  _BifaReviewSeed(
    '六阳数足须公用',
    23,
    '六陽數足須公用',
  ),
  _BifaReviewSeed(
    '六阴相继尽昏迷',
    25,
    '六陰相繼盡昏迷',
  ),
  _BifaReviewSeed(
    '旺禄临身徒妄作',
    27,
    '旺祿臨身徒妄作',
  ),
  _BifaReviewSeed(
    '权摄不正禄临支',
    31,
    '權攝不正祿臨支',
  ),
  _BifaReviewSeed(
    '避难逃生须弃旧',
    33,
    '避難逃生須棄舊',
  ),
  _BifaReviewSeed(
    '朽木难雕别作为',
    38,
    '朽木難雕別作為',
  ),
  _BifaReviewSeed(
    '众鬼虽彰全不畏',
    38,
    '衆鬼雖彰全不畏',
  ),
  _BifaReviewSeed(
    '虽忧狐假虎威仪',
    44,
    '雖憂狐假虎威儀',
  ),
  _BifaReviewSeed(
    '鬼贼当时无畏忌',
    45,
    '鬼賊當時無畏忌',
  ),
  _BifaReviewSeed(
    '传财太旺返财亏',
    46,
    '傳財太旺返財虧',
  ),
  _BifaReviewSeed(
    '脱上逢脱防虚诈',
    47,
    '脫上逢脫防虛詐',
  ),
  _BifaReviewSeed(
    '空上乘空事莫追',
    50,
    '空上乘空事莫追',
  ),
  _BifaReviewSeed(
    '进茹空亡宜退步',
    52,
    '進茹空亡宜退步',
  ),
  _BifaReviewSeed(
    '踏脚空亡进用宜',
    54,
    '踏腳空亡進用宜',
  ),
  _BifaReviewSeed(
    '胎财生气妻怀孕',
    55,
    '胎財生氣妻懷孕',
  ),
  _BifaReviewSeed(
    '胎财死气损胎推',
    66,
    '胎財死氣損胎推',
  ),
  _BifaReviewSeed(
    '交车相合交关利',
    66,
    '交車相合交關利',
  ),
  _BifaReviewSeed(
    '上下皆合两心齐',
    71,
    '上下皆合兩心齊',
  ),
  _BifaReviewSeed(
    '彼求我事支传干',
    76,
    '彼求我事支傳干',
  ),
  _BifaReviewSeed(
    '我求彼事干传支',
    76,
    '我求彼事干傳支',
  ),
  _BifaReviewSeed(
    '金日逢丁凶祸动',
    77,
    '金日逢丁凶禍動',
  ),
  _BifaReviewSeed(
    '水日逢丁财动之',
    85,
    '水日逢丁財動之',
  ),
  _BifaReviewSeed(
    '传财化鬼财休觅',
    89,
    '傳財化鬼財休覓',
  ),
  _BifaReviewSeed(
    '传鬼化财钱险危',
    94,
    '傳鬼化財錢險危',
  ),
  _BifaReviewSeed(
    '眷属丰盈居狭宅',
    98,
    '眷屬豐盈居狹宅',
  ),
  _BifaReviewSeed(
    '屋宅宽广致人衰',
    100,
    '屋宅寬廣致人衰',
  ),
  _BifaReviewSeed(
    '三传递生人举荐',
    102,
    '三傳遞生人舉薦',
  ),
  _BifaReviewSeed(
    '三传互克众人欺',
    105,
    '三傳互克衆人欺',
  ),
  _BifaReviewSeed(
    '有始无终难变易',
    108,
    '有始無終難變易',
  ),
  _BifaReviewSeed(
    '苦去甘来乐里悲',
    110,
    '苦去甘來樂裏悲',
  ),
  _BifaReviewSeed(
    '人宅受脱俱招盗',
    116,
    '人宅受脫俱招盜',
  ),
  _BifaReviewSeed(
    '干支皆败势倾颓',
    118,
    '干支皆敗勢傾頹',
  ),
  _BifaReviewSeed(
    '末助初兮三等讼',
    120,
    '末助初兮三等訟',
  ),
  _BifaReviewSeed(
    '闭口卦体两般推',
    124,
    '閉口卦體兩般推',
  ),
  _BifaReviewSeed(
    '太阳照武宜擒贼',
    130,
    '太陽照武宜擒賊',
  ),
  _BifaReviewSeed(
    '后合占婚岂用媒',
    135,
    '后合占婚豈用媒',
  ),
  _BifaReviewSeed(
    '富贵干支逢禄马',
    136,
    '富貴干支逢祿馬',
  ),
  _BifaReviewSeed(
    '尊崇传内遇三奇',
    137,
    '尊崇傳內遇三奇',
  ),
  _BifaReviewSeed(
    '害贵讼直作曲断',
    138,
    '害貴訟直作曲斷',
  ),
  _BifaReviewSeed(
    '课传俱贵转无依',
    139,
    '課傳俱貴轉無依',
  ),
  _BifaReviewSeed(
    '昼夜贵加求两贵',
    141,
    '晝夜貴加求兩貴',
  ),
  _BifaReviewSeed(
    '贵人差迭事参差',
    143,
    '貴人差迭事參差',
  ),
  _BifaReviewSeed(
    '贵虽在狱宜临干',
    145,
    '貴雖在獄宜臨干',
  ),
  _BifaReviewSeed(
    '鬼乘天乙乃神祇',
    146,
    '鬼乘天乙乃神祇',
  ),
  _BifaReviewSeed(
    '两贵受克难干贵',
    147,
    '兩貴受克難干貴',
  ),
  _BifaReviewSeed(
    '二贵皆空虚喜期',
    150,
    '二貴皆空虛喜期',
  ),
  _BifaReviewSeed(
    '魁度天门关隔定',
    3,
    '魁度天門關隔定',
  ),
  _BifaReviewSeed(
    '罡塞鬼户任谋为',
    4,
    '罡塞鬼戶任謀為',
  ),
  _BifaReviewSeed(
    '两蛇夹墓凶难免',
    7,
    '兩蛇夾墓凶難免',
  ),
  _BifaReviewSeed(
    '虎视逢虎力难施',
    9,
    '虎視逢虎力難施',
  ),
  _BifaReviewSeed(
    '所谋多拙逢网罗',
    12,
    '所謀多拙逢網羅',
  ),
  _BifaReviewSeed(
    '天网自裹己招非',
    13,
    '天網自裹己招非',
  ),
  _BifaReviewSeed(
    '费有余而得不足',
    15,
    '費有餘而得不足',
  ),
  _BifaReviewSeed(
    '用破身心无所归',
    17,
    '用破身心無所歸',
  ),
  _BifaReviewSeed(
    '华盖覆日人昏晦',
    19,
    '華蓋覆日人昏晦',
  ),
  _BifaReviewSeed(
    '太阳射宅屋光辉',
    20,
    '太陽射宅屋光輝',
  ),
  _BifaReviewSeed(
    '干乘墓虎无占病',
    21,
    '干乘墓虎無占病',
  ),
  _BifaReviewSeed(
    '支乘墓虎有伏尸',
    22,
    '支乘墓虎有伏尸',
  ),
  _BifaReviewSeed(
    '彼此全伤防两损',
    25,
    '彼此全傷防兩損',
  ),
  _BifaReviewSeed(
    '夫妇无淫各有私',
    26,
    '夫婦無淫各有私',
  ),
  _BifaReviewSeed(
    '干墓并关人宅废',
    28,
    '干墓併關人宅廢',
  ),
  _BifaReviewSeed(
    '支坟财并旅程稽',
    29,
    '支墳財併旅程稽',
  ),
  _BifaReviewSeed(
    '受虎克神为病症',
    30,
    '受虎克神為病證',
  ),
  _BifaReviewSeed(
    '制鬼之位乃良医',
    41,
    '制鬼之位乃良醫',
  ),
  _BifaReviewSeed(
    '虎乘遁鬼殃非浅',
    44,
    '虎乘遁鬼殃非淺',
  ),
  _BifaReviewSeed(
    '鬼临三四讼灾随',
    46,
    '鬼臨三四訟災隨',
  ),
  _BifaReviewSeed(
    '病符克宅全家患',
    48,
    '病符克宅全家患',
  ),
  _BifaReviewSeed(
    '丧吊全逢挂缟衣',
    49,
    '喪吊全逢掛縞衣',
  ),
  _BifaReviewSeed(
    '前后逼迫难进退',
    54,
    '前後逼迫難進退',
  ),
  _BifaReviewSeed(
    '空空如也事休追',
    57,
    '空空如也事休追',
  ),
  _BifaReviewSeed(
    '宾主不投刑在上',
    58,
    '賓主不投刑在上',
  ),
  _BifaReviewSeed(
    '彼此猜忌害相随／彼此猜忌祸相随（未定）',
    65,
    '彼此猜忌禍相隨',
    status: 'disputed',
  ),
  _BifaReviewSeed(
    '互生俱生凡事益',
    68,
    '互生俱生凡事益',
  ),
  _BifaReviewSeed(
    '互旺皆旺坐谋宜',
    72,
    '互旺皆旺坐謀宜',
  ),
  _BifaReviewSeed(
    '干支值绝凡谋决',
    74,
    '干支值絕凡謀決',
  ),
  _BifaReviewSeed(
    '人宅皆死各衰羸',
    76,
    '人宅皆死各衰羸',
  ),
  _BifaReviewSeed(
    '传墓入墓分憎爱',
    77,
    '傳墓入墓分憎愛',
  ),
  _BifaReviewSeed(
    '不行传者考初时',
    79,
    '不行傳者考初時',
  ),
  _BifaReviewSeed(
    '万事喜忻三六合',
    82,
    '萬事喜忻三六合',
  ),
  _BifaReviewSeed(
    '合中犯杀蜜中砒',
    85,
    '合中犯殺蜜中砒',
  ),
  _BifaReviewSeed(
    '初遭夹克不由己',
    86,
    '初遭夾克不由己',
  ),
  _BifaReviewSeed(
    '将逢内战所谋危',
    88,
    '將逢內戰所謀危',
  ),
  _BifaReviewSeed(
    '人宅坐墓甘招晦',
    91,
    '人宅坐墓甘招晦',
  ),
  _BifaReviewSeed(
    '干支乘墓各昏迷',
    93,
    '干支乘墓各昏迷',
  ),
  _BifaReviewSeed(
    '任信丁马须言动',
    96,
    '任信丁馬須言動',
  ),
  _BifaReviewSeed(
    '来去俱空岂动宜',
    100,
    '來去俱空豈動宜',
  ),
  _BifaReviewSeed(
    '虎临干鬼凶速速',
    103,
    '虎臨干鬼凶速速',
  ),
  _BifaReviewSeed(
    '龙加生气吉迟迟',
    107,
    '龍加生氣吉遲遲',
  ),
  _BifaReviewSeed(
    '妄用三传灾福异',
    108,
    '妄用三傳災福異',
  ),
  _BifaReviewSeed(
    '喜惧空亡乃妙机',
    110,
    '喜懼空亡乃妙機',
  ),
  _BifaReviewSeed(
    '六爻现卦防其克',
    115,
    '六爻現卦防其克',
  ),
  _BifaReviewSeed(
    '旬内空亡逐类推',
    124,
    '旬內空亡逐類推',
  ),
  _BifaReviewSeed(
    '所筮不入仍凭类',
    128,
    '所筮不入仍憑類',
  ),
  _BifaReviewSeed(
    '分占现类勿言之',
    128,
    '分占現類勿言之',
  ),
  _BifaReviewSeed(
    '常流不应逢吉象',
    129,
    '常流不應逢吉象',
  ),
  _BifaReviewSeed(
    '已灾凶逃返无疑',
    130,
    '已災凶逃返無疑',
  ),
];

Map<String, Object?> _bifa() {
  const String source = 'dlr.source.daquan-transcription-aa7bc942';
  const String scanSource = 'dlr.source.siku-liuren-daquan';
  if (_bifaReviews.length != 100) {
    throw StateError(
      'BiFa review count drifted: expected 100, found ${_bifaReviews.length}.',
    );
  }
  final List<Map<String, Object?>> entries = <Map<String, Object?>>[
    for (int index = 0; index < _bifaReviews.length; index++)
      _rule(
        id: 'dlr.rule.bifa.${(index + 1).toString().padLeft(3, '0')}',
        family: 'bifa',
        subfamily: 'bifaCatalog',
        ordinal: index + 1,
        name: _bifaReviews[index].name,
        conditions: '本条只冻结毕法赋百法目录身份；typed 命中条件须由影印正文和独立正反例另行批准。',
        interpretation: '详细题句与起始影印页已独立复核；本条不批准执行条件、优先级或 fixture。',
        targetCapability:
            'daliuren.bifa.${(index + 1).toString().padLeft(3, '0')}',
        targetCodeDomain: 'lib/domain/services/daliuren/bifa/',
        status: _bifaReviews[index].status,
        evidence: 'B',
        locatorOnly: false,
        sourceRefs: <Map<String, Object?>>[
          _scan(
            scanSource,
            index < 50 ? '卷九' : '卷十',
            scanLeaf: _bifaReviews[index].scanPage,
            pdfPage: _bifaReviews[index].scanPage,
            shortQuote: _bifaReviews[index].shortQuote,
            reviewer: 'C00 catalog first-pass scan audit',
            additionalReviewers: <String>['c00_bifa_recheck (Codex)'],
          ),
          _locator(
            source,
            index < 50
                ? 'docs/六壬大全/011巻十一 《毕法赋》上.md:L${5 + (index ~/ 2) * 2}'
                : 'docs/六壬大全/012巻十二 《毕法赋》下.md:L${5 + ((index - 50) ~/ 2) * 2}',
            _bifaReviews[index].name,
          ),
        ],
        variantGroupId: index == 75 ? 'dlr.variant.bifa-076-wording' : null,
        notes: <String>[
          if (index == 51) '固定转录重复“第五十三法”，实体卷首目录与详细题句均明确连续为第五十二、第五十三法。',
          if (index == 75) '卷首目录作“害相随”，详细题句作“祸相随”；目录身份采用，规范题名字形保持 disputed。',
          'printed leaf 尚未核定；不得把 PDF 页复制为版心叶码。',
          'adopted 仅表示百法目录身份采用；executableApproved 保持 false。',
        ],
      ),
  ];
  return _family(
    'bifa',
    'partial',
    '恰好一百个稳定毕法 ID；99 项题名与全部起始影印页已完成 B 级二审，第 76 项保留底本内部异文。',
    entries,
    expectedEntryCount: 100,
  );
}

Map<String, Object?> _nianming() {
  const String source = 'dlr.source.cunyan-transcription-d2a44794';
  final List<({String id, String name, String conditions, String evidence})>
      seeds = <({
    String id,
    String name,
    String conditions,
    String evidence,
  })>[
    (
      id: 'birth-pillar',
      name: '本命出生年柱',
      conditions: '保存明确的出生年干支；只有公历年份且无岁首口径时不得伪造年柱。',
      evidence: 'D'
    ),
    (
      id: 'birth-date',
      name: '精确出生日期',
      conditions: '若采用法依赖岁首或年龄边界，保存可校历的出生日期与时区；缺失时显式 unknown。',
      evidence: 'D'
    ),
    (
      id: 'sex',
      name: '性别输入',
      conditions: '只有核定的行年法确实使用性别时才要求该字段；不从姓名或文本猜测。',
      evidence: 'D'
    ),
    (
      id: 'age-method',
      name: '年龄算法',
      conditions: '明确周岁、虚岁及换岁边界；计算结果必须携带算法 ID。',
      evidence: 'D'
    ),
    (
      id: 'year-boundary',
      name: '岁首口径',
      conditions: '明确立春、正月初一或底本规定的换岁点；不得随历法库默认值静默变化。',
      evidence: 'D'
    ),
    (
      id: 'cast-year',
      name: '所占年份',
      conditions: '以规范化占时确定所占年柱，供行年计算；raw pillars 模式缺时间时要求显式输入。',
      evidence: 'D'
    ),
    (
      id: 'benming-fact',
      name: '本命事实',
      conditions: '足量输入与采用法齐备时计算本命；信息不足返回 unknown 而非沿用 inert birthYear。',
      evidence: 'C'
    ),
    (
      id: 'xingnian-fact',
      name: '行年事实',
      conditions: '按采用的性别、年龄与岁首规则计算行年，并记录所有输入和规则版本。',
      evidence: 'C'
    ),
  ];
  final List<Map<String, Object?>> entries = <Map<String, Object?>>[
    for (int index = 0; index < seeds.length; index++)
      _rule(
        id: 'dlr.rule.nianming.${(index + 1).toString().padLeft(3, '0')}.${seeds[index].id}',
        family: 'nianming',
        subfamily: index < 6 ? 'requiredInput' : 'derivedFact',
        ordinal: index + 1,
        name: seeds[index].name,
        conditions: seeds[index].conditions,
        interpretation: index < 6
            ? '这是实现本命/行年所需的显式输入契约；传统采用法尚须《指南》影印页冻结。'
            : '《六壬存验》课例反复使用本命/行年作为判断上下文，但固定转录不足以确定完整算法。',
        targetCapability: 'daliuren.nianming.${seeds[index].id}',
        targetCodeDomain: 'lib/domain/services/daliuren/',
        evidence: seeds[index].evidence,
        sourceRefs: index < 6
            ? <Map<String, Object?>>[]
            : <Map<String, Object?>>[
                _locator(
                    source, '六壬存验-清-吴师青.txt:L357-L390', '课例盘面同时记录年命或行年并参与断语。'),
              ],
      ),
  ];
  return _family(
      'nianming', 'unresolved', '本命/行年的有限输入与事实清单；算法口径未获影印页批准。', entries);
}

Map<String, Object?> _classSpirit() {
  const String source = 'dlr.source.cunyan-transcription-d2a44794';
  final List<({String id, String name, String locator})> seeds = <({
    String id,
    String name,
    String locator,
  })>[
    (id: 'general', name: '通用／未指定', locator: '六壬存验-清-吴师青.txt:L1-L15'),
    (id: 'migration', name: '迁移', locator: '六壬存验-清-吴师青.txt:L16'),
    (id: 'marriage', name: '婚姻', locator: '六壬存验-清-吴师青.txt:L29-L54'),
    (id: 'pregnancy', name: '孕产', locator: '六壬存验-清-吴师青.txt:L55-L89'),
    (id: 'illness', name: '疾病', locator: '六壬存验-清-吴师青.txt:L90-L118'),
    (id: 'travel', name: '出行', locator: '六壬存验-清-吴师青.txt:L119-L142'),
    (id: 'traveler-return', name: '行人', locator: '六壬存验-清-吴师青.txt:L143-L172'),
    (id: 'civil-exam', name: '选举／文试', locator: '六壬存验-清-吴师青.txt:L173-L187'),
    (id: 'military-exam', name: '武举', locator: '六壬存验-清-吴师青.txt:L188-L190'),
    (id: 'office', name: '仕宦', locator: '六壬存验-清-吴师青.txt:L191-L210'),
    (id: 'wealth', name: '求财', locator: '六壬存验-清-吴师青.txt:L211-L223'),
    (id: 'trade', name: '买卖', locator: '六壬存验-清-吴师青.txt:L224-L231'),
    (id: 'litigation', name: '诉讼', locator: '六壬存验-清-吴师青.txt:L232-L259'),
    (id: 'concealment', name: '隐遁', locator: '六壬存验-清-吴师青.txt:L260-L267'),
    (id: 'escape', name: '逃亡', locator: '六壬存验-清-吴师青.txt:L268-L274'),
    (id: 'theft', name: '贼盗', locator: '六壬存验-清-吴师青.txt:L275-L322'),
    (id: 'agriculture', name: '田蚕', locator: '六壬存验-清-吴师青.txt:L323-L324'),
    (id: 'livestock', name: '六畜', locator: '六壬存验-清-吴师青.txt:L325-L327'),
  ];
  final List<Map<String, Object?>> entries = <Map<String, Object?>>[
    for (int index = 0; index < seeds.length; index++)
      _rule(
        id: 'dlr.rule.class-spirit.${(index + 1).toString().padLeft(3, '0')}.${seeds[index].id}',
        family: 'classSpirit',
        subfamily: 'questionCategory',
        ordinal: index + 1,
        name: seeds[index].name,
        conditions: index == 0
            ? '用户未选择占类或证据不足以选类时使用，不静默猜唯一类神。'
            : '用户显式选择该占类时进入对应类神候选链；自由文本只能给出可覆盖建议。',
        interpretation: index == 0
            ? '现代产品的保守降级类别，不声称为古籍类神。'
            : '固定转录章节标题证明该事类存在；具体类神候选与优先级仍须回影印页核定。',
        targetCapability: 'daliuren.classSpirit.${seeds[index].id}',
        targetCodeDomain: 'lib/domain/services/daliuren/',
        evidence: index == 0 ? 'D' : 'C',
        sourceRefs: index == 0
            ? <Map<String, Object?>>[]
            : <Map<String, Object?>>[
                _locator(
                    source, seeds[index].locator, '占${seeds[index].name}。'),
              ],
      ),
  ];
  return _family(
      'classSpirit', 'locatorOnly', '有限占类 taxonomy；具体类神选择尚未获影印页批准。', entries);
}

Map<String, Object?> _judgment() {
  const String source = 'dlr.source.cunyan-transcription-d2a44794';
  final List<({String id, String name, String conditions})> seeds = <({
    String id,
    String name,
    String conditions,
  })>[
    (
      id: 'course-pattern',
      name: '课体基调',
      conditions: '保留九宗门、课经与毕法命中为独立因素，不用中文名称充当执行键。'
    ),
    (
      id: 'host-guest',
      name: '干支主客',
      conditions: '日干与日支及其上神分别作为人／事或主／客事实，适用语义由占类限定。'
    ),
    (
      id: 'transmission-flow',
      name: '三传始终与递生递克',
      conditions: '分别观察初中末传及递生、递克、入墓、空亡；相反因素可并存。'
    ),
    (id: 'generals', name: '天将因素', conditions: '天将只作为有来源的因素，不在事实层直接翻转总裁决。'),
    (
      id: 'shensha',
      name: '神煞因素',
      conditions: '只消费 C00/C06 已批准且 typed 位置可匹配的神煞；未核项不输出确定性标签。'
    ),
    (
      id: 'class-spirit',
      name: '类神因素',
      conditions: '按用户确认占类与类神候选链解释，不由自由文本静默确定。'
    ),
    (
      id: 'nianming',
      name: '本命行年因素',
      conditions: '仅在个人上下文足量且规则版本明确时加入；缺失时显式降级。'
    ),
    (
      id: 'adjudication',
      name: '相反证据裁决',
      conditions: '保留吉凶相反因素、来源、适用条件与优先级；不依赖服务调用或列表顺序。'
    ),
    (
      id: 'project-heuristic',
      name: '项目启发式隔离',
      conditions: '项目 v1/v2 启发式与古籍规则使用不同 rule kind 和 evidence，不伪装成传统唯一断法。'
    ),
  ];
  final List<Map<String, Object?>> entries = <Map<String, Object?>>[
    for (int index = 0; index < seeds.length; index++)
      _rule(
        id: 'dlr.rule.judgment.${(index + 1).toString().padLeft(3, '0')}.${seeds[index].id}',
        family: 'judgment',
        subfamily: 'judgmentInput',
        ordinal: index + 1,
        name: seeds[index].name,
        conditions: seeds[index].conditions,
        interpretation: '这是后续《指南》逐页规则研究的有限输入面；当前不定义确定性传统 verdict predicate。',
        targetCapability: 'daliuren.judgment.${seeds[index].id}',
        targetCodeDomain: 'lib/domain/services/daliuren/analysis/',
        evidence: index < 7 ? 'C' : 'D',
        sourceRefs: index < 7
            ? <Map<String, Object?>>[
                _locator(source, '六壬存验-清-吴师青.txt:L355-L390',
                    '课例以课体、三传、天将、年命等多项事实合参。'),
              ]
            : <Map<String, Object?>>[],
      ),
  ];
  return _family(
      'judgment', 'unresolved', '传统断课有限输入清单；尚无《指南》页级规则可批准。', entries);
}

Map<String, Object?> _timing() {
  const String daquan = 'dlr.source.daquan-transcription-aa7bc942';
  const String cunyan = 'dlr.source.cunyan-transcription-d2a44794';
  final List<Map<String, Object?>> entries = <Map<String, Object?>>[
    _rule(
      id: 'dlr.rule.timing.001.scale-by-calendar-context',
      family: 'timing',
      subfamily: 'scale',
      ordinal: 1,
      name: '年月日时尺度',
      conditions: '按问题与发用所值岁、月、旬、日、候等上下文选择尺度，不把地支候选固定解释为最近一日。',
      interpretation: '固定转录列出岁、月、旬、日、气候的应验层次，具体优先级仍须影印核页。',
      targetCapability: 'daliuren.timing.scale',
      targetCodeDomain:
          'lib/domain/services/daliuren/analysis/daliuren_ying_qi_service.dart',
      sourceRefs: <Map<String, Object?>>[
        _locator(
            daquan, 'docs/六壬大全/007巻七 课经集（一）.md:L73-L91', '日应日，时应时……取年月日时为应期。'),
      ],
    ),
    _rule(
      id: 'dlr.rule.timing.002.initial-transmission',
      family: 'timing',
      subfamily: 'candidate',
      ordinal: 2,
      name: '发用值期',
      conditions: '把初传所值支或干作为条件候选，保留来源 rule ID 与适用尺度。',
      interpretation: '只生成条件窗口，不单独翻转 verdict。',
      targetCapability: 'daliuren.timing.initialTransmission',
      targetCodeDomain:
          'lib/domain/services/daliuren/analysis/daliuren_ying_qi_service.dart',
      sourceRefs: <Map<String, Object?>>[
        _locator(
            daquan, 'docs/六壬大全/007巻七 课经集（一）.md:L73', '若正月建寅，用起功曹，则事应正月之内。'),
      ],
    ),
    _rule(
      id: 'dlr.rule.timing.003.terminal-transmission',
      family: 'timing',
      subfamily: 'candidate',
      ordinal: 3,
      name: '末传归结值期',
      conditions: '末传作为归结候选，必须与初中传路径及空亡条件同时报告。',
      interpretation: '候选理由与尺度不可只保存一个地支。',
      targetCapability: 'daliuren.timing.terminalTransmission',
      targetCodeDomain:
          'lib/domain/services/daliuren/analysis/daliuren_ying_qi_service.dart',
      sourceRefs: <Map<String, Object?>>[
        _locator(daquan, 'docs/六壬大全/007巻七 课经集（一）.md:L45', '末传为归结。'),
      ],
    ),
    _rule(
      id: 'dlr.rule.timing.004.kongwang-fill',
      family: 'timing',
      subfamily: 'candidate',
      ordinal: 4,
      name: '空亡填实／出旬',
      conditions: '只有裁决条件允许等待填实时，才按出旬或值支生成候选；明确无解条件不得同时产生解救窗口。',
      interpretation: '《存验》失马例以出旬填实断期，但仍是 C 级转录课例。',
      targetCapability: 'daliuren.timing.kongWangFill',
      targetCodeDomain:
          'lib/domain/services/daliuren/analysis/daliuren_ying_qi_service.dart',
      sourceRefs: <Map<String, Object?>>[
        _locator(cunyan, '六壬存验-清-吴师青.txt:L631-L636', '必俟出旬乙巳日填实，方能得马也。'),
      ],
    ),
    _rule(
      id: 'dlr.rule.timing.005.yima',
      family: 'timing',
      subfamily: 'candidate',
      ordinal: 5,
      name: '驿马动期',
      conditions: '驿马命中且事类相关时生成动期候选，并保留是否空墓及所临地盘。',
      interpretation: '驿马不等于无条件发生；空墓会改变候选条件。',
      targetCapability: 'daliuren.timing.yiMa',
      targetCodeDomain:
          'lib/domain/services/daliuren/analysis/daliuren_ying_qi_service.dart',
      sourceRefs: <Map<String, Object?>>[
        _locator(cunyan, '六壬存验-清-吴师青.txt:L781-L787', '亥为巳日之驿马……应于丙戌日到。'),
      ],
    ),
    _rule(
      id: 'dlr.rule.timing.006.chong-he',
      family: 'timing',
      subfamily: 'candidate',
      ordinal: 6,
      name: '冲动与合期',
      conditions: '伏吟、入墓或静象可在有证据的冲动／合住条件下生成候选；理由不得只用显示文本。',
      interpretation: '冲与合是候选条件，不是统一的确定性应期。',
      targetCapability: 'daliuren.timing.chongHe',
      targetCodeDomain:
          'lib/domain/services/daliuren/analysis/daliuren_ying_qi_service.dart',
      evidence: 'D',
      sourceRefs: <Map<String, Object?>>[],
    ),
    _rule(
      id: 'dlr.rule.timing.007.calendar-resolution',
      family: 'timing',
      subfamily: 'calendar',
      ordinal: 7,
      name: '候选落实际日期',
      conditions: '使用占时瞬时值、IANA 时区与尺度把干支候选解析为可重复的日期窗口。',
      interpretation: '这是现代历法产品契约，不声称古籍提供 IANA 时区算法。',
      targetCapability: 'daliuren.timing.calendarResolution',
      targetCodeDomain:
          'lib/domain/services/daliuren/analysis/daliuren_ying_qi_service.dart',
      evidence: 'D',
      sourceRefs: <Map<String, Object?>>[],
    ),
    _rule(
      id: 'dlr.rule.timing.008.no-verdict-override',
      family: 'timing',
      subfamily: 'contract',
      ordinal: 8,
      name: '应期不翻转裁决',
      conditions: '应期只表达条件窗口；不得单独把凶转吉、把无解改成可解或覆盖 verdict condition。',
      interpretation: '这是消除跨层互斥输出的项目契约，证据等级 D。',
      targetCapability: 'daliuren.timing.noVerdictOverride',
      targetCodeDomain: 'lib/domain/services/daliuren/analysis/',
      evidence: 'D',
      sourceRefs: <Map<String, Object?>>[],
    ),
  ];
  return _family('timing', 'locatorOnly', '传统应期候选与现代日期解析的有限清单。', entries);
}

Map<String, Object?> _variantOption({
  required String id,
  required String label,
  required String evidence,
  required String summary,
  List<Map<String, Object?>> sourceRefs = const <Map<String, Object?>>[],
}) =>
    <String, Object?>{
      'variantId': id,
      'label': label,
      'evidenceLevel': evidence,
      'sourceRefs': sourceRefs,
      'summary': summary,
    };

Map<String, Object?> _variantDecision({
  required String id,
  required String topic,
  required List<String> capabilities,
  required List<String> impact,
  required String status,
  required String rationale,
  required String displayStrategy,
  required List<String> blockingRuleIds,
  required List<Map<String, Object?>> options,
  String? adoptedVariantId,
}) =>
    <String, Object?>{
      'variantGroupId': id,
      'topic': topic,
      'affectedCapabilities': capabilities,
      'impact': impact,
      'status': status,
      'configurable': false,
      'adoptedVariantId': adoptedVariantId,
      'adoptionRationale': rationale,
      'nonAdoptedDisplayStrategy': displayStrategy,
      'blockingRuleIds': blockingRuleIds,
      'options': options,
    };

Map<String, Object?> _variants() {
  const String cunyan = 'dlr.source.cunyan-transcription-d2a44794';
  const String daquan = 'dlr.source.daquan-transcription-aa7bc942';
  const String siku = 'dlr.source.siku-liuren-daquan';
  const String zhizhi = 'dlr.source.yuding-liuren-zhizhi-candidate';
  return <String, Object?>{
    'schemaVersion': '1.0.0',
    'variants': <Object?>[
      _variantDecision(
        id: 'dlr.variant.shensha-zhi-hai-second-value',
        topic: '支害十二值第二字',
        capabilities: <String>['daliuren.shensha.053'],
        impact: <String>['决定丑日支害所临之支；任何修字都会改变神煞事实。'],
        status: 'unresolved',
        rationale: '主底本影印第二值似“子”，与常见成对六害结构冲突；没有异本复核前不得按常识改字。',
        displayStrategy: '保留主底本逐字短引和 disputed 状态，不提供运行时配置。',
        blockingRuleIds: <String>['dlr.rule.shensha.053'],
        options: <Map<String, Object?>>[
          _variantOption(
            id: 'siku-literal-zi',
            label: '主底本作子',
            evidence: 'B',
            summary: '四库影印所见第二值似子，按原字保存但不批准执行。',
            sourceRefs: <Map<String, Object?>>[
              _variantScan(
                siku,
                '卷一',
                scanLeaf: 33,
                pdfPage: 33,
                printedLeaf: '12a',
                shortQuote: '支害未子巳辰卯寅丑子亥戌酉申。',
              ),
            ],
          ),
          _variantOption(
            id: 'symmetric-liuhai-wu',
            label: '成对六害作午',
            evidence: 'D',
            summary: '按常见六害结构推得午，但本任务未取得可核异本页，不能采用。',
          ),
        ],
      ),
      _variantDecision(
        id: 'dlr.variant.shensha-guan-identity',
        topic: '单字关与时煞、关神的身份关系',
        capabilities: <String>[
          'daliuren.shensha.054',
          'daliuren.shensha.182',
          'daliuren.shensha.188',
        ],
        impact: <String>['影响三个题名应独立实现、合并为异名，或保留为不可执行候选。'],
        status: 'unresolved',
        rationale: 'PDF 33 清楚见单字“關”，固定转录却作“时煞”；PDF 39 又独立列关神与时煞，现有证据不能冻结三者关系。',
        displayStrategy: '三项分别登记；单字关保持 C/disputed，禁止按名称猜测合并。',
        blockingRuleIds: <String>[
          'dlr.rule.shensha.054',
          'dlr.rule.shensha.182',
          'dlr.rule.shensha.188',
        ],
        options: <Map<String, Object?>>[
          _variantOption(
            id: 'scan-distinct-guan',
            label: '影印单列关',
            evidence: 'C',
            summary: '按 PDF 33 单字题头另立候选；关系仍须异本或上下文复核。',
            sourceRefs: <Map<String, Object?>>[
              _variantScan(
                siku,
                '卷一',
                scanLeaf: 33,
                pdfPage: 33,
                printedLeaf: '12a',
                shortQuote: '關巳寅亥申巳寅亥申巳寅亥申。',
              ),
              _variantScan(
                siku,
                '卷一',
                scanLeaf: 39,
                pdfPage: 39,
                shortQuote: '逐月神煞表另列关神与时煞。',
              ),
            ],
          ),
          _variantOption(
            id: 'transcription-as-shisha',
            label: '固定转录作时煞',
            evidence: 'C',
            summary: '固定转录把同列写作时煞，但不能反向覆盖影印字形。',
            sourceRefs: <Map<String, Object?>>[
              _variantLocator(
                daquan,
                'docs/六壬大全/001巻一 起例.md:L141-L145',
                '支害……时煞……支仪。',
              ),
            ],
          ),
        ],
      ),
      _variantDecision(
        id: 'dlr.variant.shensha-gushen-guchen-identity',
        topic: '孤神与孤辰的身份关系',
        capabilities: <String>[
          'daliuren.shensha.104',
          'daliuren.shensha.193',
        ],
        impact: <String>['影响季节公式孤神与逐月表孤辰应独立实现，还是作为近名异文归并。'],
        status: 'unresolved',
        rationale:
            'PDF 36 正文明确列“孤神”，PDF 39、41、42 逐月表另见“孤辰”；现有证据支持分别登记，但不足以冻结 typed 规则间关系。',
        displayStrategy: '两项分别登记；禁止用逐月表 OCR 校正把正文孤神静默改成孤辰。',
        blockingRuleIds: <String>[
          'dlr.rule.shensha.104',
          'dlr.rule.shensha.193',
        ],
        options: <Map<String, Object?>>[
          _variantOption(
            id: 'scan-distinct-identities',
            label: '影印分别作孤神、孤辰',
            evidence: 'B',
            summary: '按各自影印题名保留两个目录身份，typed 关系仍待 C06 裁决。',
            sourceRefs: <Map<String, Object?>>[
              _variantScan(
                siku,
                '卷一',
                scanLeaf: 36,
                pdfPage: 36,
                printedLeaf: '13b',
                shortQuote: '喝散、禁神、孤神：春巳夏申秋亥冬寅。',
              ),
              _variantScan(
                siku,
                '卷一',
                scanLeaf: 39,
                pdfPage: 39,
                shortQuote: '逐月神煞表另列孤辰。',
              ),
            ],
          ),
          _variantOption(
            id: 'merge-as-near-name-variant',
            label: '按近名合并',
            evidence: 'D',
            summary: '仅凭名称相近推断同一规则，缺少本任务可核版本依据，不采用。',
          ),
        ],
      ),
      _variantDecision(
        id: 'dlr.variant.bifa-076-wording',
        topic: '毕法第七十六法害/祸字形',
        capabilities: <String>['daliuren.bifa.076'],
        impact: <String>['只影响规范题名、检索和证据展示；typed 条件尚未批准。'],
        status: 'unresolved',
        rationale: '同一底本卷首目录作“害相随”，卷十详细题句作“祸相随”，不能无说明择一。',
        displayStrategy: '规范题名并列两形并标未定，不提供运行时配置。',
        blockingRuleIds: <String>['dlr.rule.bifa.076'],
        options: <Map<String, Object?>>[
          _variantOption(
            id: 'index-hai',
            label: '卷首目录害相随',
            evidence: 'C',
            summary: '实体卷首目录所见字形；精确目录叶尚未在 rule sourceRef 单列。',
            sourceRefs: <Map<String, Object?>>[
              _variantLocator(
                siku,
                '卷九卷首目录 PDF 3-8',
                '彼此猜忌害相隨。',
              ),
            ],
          ),
          _variantOption(
            id: 'detail-huo',
            label: '详细题句祸相随',
            evidence: 'B',
            summary: '卷十详细题句起始页作祸相随。',
            sourceRefs: <Map<String, Object?>>[
              _variantScan(
                siku,
                '卷十',
                scanLeaf: 65,
                pdfPage: 65,
                shortQuote: '彼此猜忌禍相隨。',
              ),
            ],
          ),
        ],
      ),
      _variantDecision(
        id: 'dlr.variant.gui-ren-table',
        topic: '十干昼夜贵人表',
        capabilities: <String>[
          'daliuren.shenjiang.yangGuiTable',
          'daliuren.shenjiang.yinGuiTable',
        ],
        impact: <String>[
          '改变所选贵人天盘支。',
          '连锁改变十二天将、四课乘将与三传乘将。',
        ],
        status: 'unresolved',
        rationale: '固定转录只有 C 级 locator；候选《直指》虽有完整影印表，却与当前表在五干冲突且版本仍未批准。',
        displayStrategy: '不提供运行时配置；显示整表版本差异，并明确项目的仅甲日特例不能代表《直指》版本。',
        blockingRuleIds: <String>[
          'dlr.rule.shenjiang.002.yang-gui-table',
          'dlr.rule.shenjiang.003.yin-gui-table',
        ],
        options: <Map<String, Object?>>[
          _variantOption(
            id: 'cunyan-fixed-table',
            label: '《六壬存验》固定转录表',
            evidence: 'C',
            summary: '阳贵甲丑、己子等，阴贵甲未、己申等；尚无对应影印页。',
            sourceRefs: <Map<String, Object?>>[
              _variantLocator(
                cunyan,
                '六壬存验-清-吴师青.txt:L347-L349',
                '阳贵：甲丑，己子……阴贵：甲未，己申……',
              ),
            ],
          ),
          _variantOption(
            id: 'siku-adopted-table-unlocated',
            label: '四库本采用表',
            evidence: 'D',
            summary: '正面采用的贵人表尚未在主底本影印页中定位，不能由现有代码反推。',
          ),
          _variantOption(
            id: 'yuding-zhizhi-complete-table',
            label: '《御定六壬直指》完整表',
            evidence: 'C',
            summary: '阳贵甲未乙申丙酉辛寅壬卯，阴贵相应对调；与当前表在甲乙丙辛壬五干冲突。',
            sourceRefs: <Map<String, Object?>>[
              _variantScan(
                zhizhi,
                '上下卷附析义',
                scanLeaf: 17,
                pdfPage: 18,
                printedLeaf: '七',
                shortQuote: '正时自卯至申用昼贵……庚戊见牛甲在羊……甲贵阴牛庚戊羊。',
              ),
            ],
          ),
          _variantOption(
            id: 'project-jia-only-alternative',
            label: '项目仅甲日互换特例',
            evidence: 'D',
            summary: '现有配置只交换甲日，不能代表候选《直指》同时交换五干的完整版本。',
          ),
        ],
      ),
      _variantDecision(
        id: 'dlr.variant.gui-ren-direction',
        topic: '十二天将顺逆的决定依据',
        capabilities: <String>[
          'daliuren.shenjiang.actualDirection',
          'daliuren.shenjiang.dualCoordinates',
        ],
        impact: <String>[
          '改变十二天将在天盘支与地盘宫的完整分布。',
          '会改变四课、三传所乘天将及其后续分析。',
        ],
        status: 'adopted',
        adoptedVariantId: 'landing-palace-six-zones',
        rationale: '《直指》PDF 19 逐支明言亥子丑寅卯辰顺、巳午未申酉戌逆；《六壬大全》的地盘与天门地户原则是同一方法的交叉支持。昼顺夜逆图明言“近不用”，不采用。',
        displayStrategy: '不提供运行时方向开关；非采用的昼顺夜逆只作否定性史料展示，不得重新解释历史盘或驱动新盘。',
        blockingRuleIds: <String>[],
        options: <Map<String, Object?>>[
          _variantOption(
            id: 'landing-palace-six-zones',
            label: '贵人落地宫分顺逆六位',
            evidence: 'B',
            summary: '先求天盘贵人所临地宫，再按亥子丑寅卯辰顺、巳午未申酉戌逆；《直指》逐支明文与《大全》天门地户原则合并为同一采用项。',
            sourceRefs: <Map<String, Object?>>[
              _variantScan(
                zhizhi,
                '上下卷附析义',
                scanLeaf: 18,
                pdfPage: 19,
                printedLeaf: '八',
                shortQuote: '贵人加于亥子丑寅卯辰六位则顺行，加于巳午未申酉戌六位则逆行。',
              ),
              _variantScan(
                siku,
                '卷二',
                scanLeaf: 59,
                pdfPage: 59,
                shortQuote: '地盘一定顺逆之序，顺布者则背天门，逆布者则向地户。',
              ),
              _variantScan(
                siku,
                '卷二',
                scanLeaf: 62,
                pdfPage: 62,
                shortQuote: '顺治谓在天门之前、地户之后；逆治谓在地户之前、天门之后。',
              ),
              _variantLocator(
                cunyan,
                '六壬存验-清-吴师青.txt:L329',
                '贵临地盘亥子丑寅卯辰六位顺行……巳午未申酉戌六位逆行。',
              ),
            ],
          ),
          _variantOption(
            id: 'day-forward-night-reverse-disused',
            label: '昼顺夜逆图说',
            evidence: 'C',
            summary: '主底本影印页记录该说但明确称近不用，不能作为采用依据。',
            sourceRefs: <Map<String, Object?>>[
              _variantScan(
                siku,
                '卷一',
                scanLeaf: 100,
                pdfPage: 100,
                printedLeaf: '45b',
                shortQuote: '此贵神昼顺行夜逆行……其说甚有理而近不用。',
              ),
            ],
          ),
        ],
      ),
      _variantDecision(
        id: 'dlr.variant.shehai-tie-break',
        topic: '涉害同深候选的孟仲季与刚柔决胜',
        capabilities: <String>['daliuren.jiuzongmen.shehai'],
        impact: <String>['并列候选可产生不同初传，继而改变中末传。'],
        status: 'unresolved',
        rationale: '主底本页面只有首次视觉定位，细部解释和其他传承差异尚未独立复核。',
        displayStrategy: '保留候选说明；不得把服务现状包装成唯一古法。',
        blockingRuleIds: <String>[
          'dlr.rule.jiuzongmen.003.shehai',
        ],
        options: <Map<String, Object?>>[
          _variantOption(
            id: 'meng-zhong-then-gang-rou',
            label: '孟仲后以刚柔先见',
            evidence: 'C',
            summary: '固定转录称孟深仲浅季休，复等则柔辰刚日；尚待逐字二审。',
            sourceRefs: <Map<String, Object?>>[
              _variantLocator(
                daquan,
                'docs/六壬大全/001巻一 起例.md:L17-L19',
                '孟深仲浅季当休，复等柔辰刚日宜。',
              ),
            ],
          ),
          _variantOption(
            id: 'alternative-depth-tie-break',
            label: '其他涉害决胜次序',
            evidence: 'D',
            summary: '父任务已知存在传承差异，但尚无固定版本与页级短引可登记。',
          ),
        ],
      ),
      _variantDecision(
        id: 'dlr.variant.bieze-yang-method',
        topic: '别责刚日发用位置',
        capabilities: <String>['daliuren.jiuzongmen.bieze'],
        impact: <String>['刚日别责可能产生不同初传。'],
        status: 'unresolved',
        rationale: '固定转录支持干合上头神候选，但寄宫上神与本位取法的版本差异尚未完成影印裁决。',
        displayStrategy: '不提供配置；保留异文并阻塞确定性扩展。',
        blockingRuleIds: <String>['dlr.rule.jiuzongmen.006.bieze'],
        options: <Map<String, Object?>>[
          _variantOption(
            id: 'combined-stem-lodging-upper',
            label: '干合寄宫上神',
            evidence: 'C',
            summary: '按干合之干的寄宫再取天盘上神。',
            sourceRefs: <Map<String, Object?>>[
              _variantLocator(
                daquan,
                'docs/六壬大全/001巻一 起例.md:L29-L31',
                '刚日干合上头神，柔日支前三合取。',
              ),
            ],
          ),
          _variantOption(
            id: 'combined-stem-native-position',
            label: '干合本位取用',
            evidence: 'D',
            summary: '差异候选尚无本任务可核的固定底本页。',
          ),
        ],
      ),
      _variantDecision(
        id: 'dlr.variant.bazhuan-with-ke-label',
        topic: '八专有克时的课体归属',
        capabilities: <String>['daliuren.jiuzongmen.bazhuan'],
        impact: <String>['影响取传分派 trace 与课体显示，但不应凭标签改写克贼事实。'],
        status: 'unresolved',
        rationale: '主底本候选文字以两课无克为八专，现有代码的有克标注策略没有独立古籍依据。',
        displayStrategy: '显示真实取传路径；八专标签异文只进证据详情。',
        blockingRuleIds: <String>['dlr.rule.jiuzongmen.007.bazhuan'],
        options: <Map<String, Object?>>[
          _variantOption(
            id: 'no-overcoming-only',
            label: '仅两课无克称八专',
            evidence: 'C',
            summary: '固定转录以两课无克作为八专入口。',
            sourceRefs: <Map<String, Object?>>[
              _variantLocator(
                daquan,
                'docs/六壬大全/001巻一 起例.md:L33-L35',
                '两课无克号八专。',
              ),
            ],
          ),
          _variantOption(
            id: 'retain-label-when-overcoming',
            label: '有克仍保留八专标签',
            evidence: 'D',
            summary: '这是需要审计的项目行为，不能由当前代码自证为古法。',
          ),
        ],
      ),
      _variantDecision(
        id: 'dlr.variant.fanyin-terminology',
        topic: '返吟与反吟字形归一',
        capabilities: <String>['daliuren.jiuzongmen.fanyin'],
        impact: <String>['只影响稳定展示词和检索别名，不改变盘面或三传。'],
        status: 'rejected',
        rationale: '字形差异没有实质盘面影响，不满足运行时可配置条件；机器 ID 统一使用 fanyin。',
        displayStrategy: '正文统一显示反吟，证据短引保留原页返吟字形并建立检索别名。',
        blockingRuleIds: <String>[],
        options: <Map<String, Object?>>[
          _variantOption(
            id: 'return-character',
            label: '返吟',
            evidence: 'C',
            summary: '四库影印页与固定转录所见字形。',
            sourceRefs: <Map<String, Object?>>[
              _variantScan(
                siku,
                '卷一',
                scanLeaf: 15,
                pdfPage: 15,
                printedLeaf: '3a',
                shortQuote: '返吟有克亦为用，无克别有井栏名。',
              ),
            ],
          ),
          _variantOption(
            id: 'opposition-character',
            label: '反吟',
            evidence: 'D',
            summary: '项目统一展示字形；只作为别名归一，不声称是另一套古法。',
          ),
        ],
      ),
    ],
  };
}

Map<String, Object?> _duananCases() => <String, Object?>{
      'schemaVersion': '1.0.0',
      'sourceWork': '大六壬断案',
      'catalogStatus': 'locatorOnly',
      'limitations': <String>[
        '殆知阁链接最终指向 CTP wiki 转录（res=936550），页面明示版本暂缺。',
        'NDL 只查到 2012 年《大六壬断案疏正》纸本，无在线页图。',
        '以下课例只登记固定 locator；在找到可核影印本前不得提升为 A/B 或补造页码。',
      ],
      'cases': <Object?>[
        <String, Object?>{
          'caseId': 'dlr.case.duanan.han-taishou-pray-for-snow',
          'title': '韩太守占祈雪',
          'verificationStatus': 'pendingScan',
          'evidenceLevel': 'C',
          'locatorOnly': true,
          'sourceRef': _caseRef(
            'dlr.source.duanan-ctp-936550',
            'CTP wiki res=936550:元集/天时/韩太守占祈雪',
            '建炎三年己酉岁十一月初四己卯日寅将酉时，韩太守占祈雪。',
          ),
          'rawInput': <String, Object?>{
            'reignYearText': '建炎三年',
            'yearPillar': '己酉',
            'lunarMonthText': '十一月',
            'lunarDayText': '初四',
            'dayPillar': '己卯',
            'hourBranch': '酉',
            'monthGeneral': '寅',
            'civilDateTime': null,
            'timezone': null,
            'question': '祈雪',
            'personContext': <String, Object?>{'title': '韩太守'},
          },
          'expectedFacts': <String, Object?>{
            'transmissions': <Object?>[
              <String, Object?>{
                'stage': '初传',
                'branch': '巳',
                'general': '玄武',
              },
              <String, Object?>{
                'stage': '中传',
                'branch': '戌',
                'general': '朱雀',
              },
              <String, Object?>{
                'stage': '末传',
                'branch': '卯',
                'general': '白虎',
              },
            ],
          },
          'classicJudgment': '原断次日转寒并雨，继而降雪七寸；结果只作待影印复核的文本定位。',
          'expectedDerivation': <String, Object?>{
            'method': 'sourceTranscription',
            'usesProductionCode': false,
            'reviewer': 'C00 CTP locator review',
            'reviewedAt': '2026-07-28',
          },
          'unresolvedFields': <String>[
            'scanLeaf',
            'printedLeaf',
            'civilDateTime',
            'timezone',
            'hourPillar',
            'fourLessons',
            'courseNames',
          ],
          'adoptedAssumptions': <String>[
            '三传与天将只按当前可定位转录登记，不调用生产算法补齐。',
          ],
          'coveredRuleIds': <String>[],
          'targetCapabilityIds': <String>[
            'daliuren.externalCases.duanan',
          ],
        },
      ],
    };

Map<String, Object?> _caseRef(
  String sourceId,
  String locator,
  String quote,
) =>
    <String, Object?>{
      'sourceId': sourceId,
      'referenceKind': 'locator',
      'volume': null,
      'scanLeaf': null,
      'printedLeaf': null,
      'pdfPage': null,
      'imageLabel': null,
      'locator': locator,
      'shortQuote': quote,
    };

Map<String, Object?> _caseScanRef(
  String sourceId, {
  required String volume,
  required int scanLeaf,
  required int pdfPage,
  required String printedLeaf,
  required String quote,
}) =>
    <String, Object?>{
      'sourceId': sourceId,
      'referenceKind': 'scan',
      'volume': volume,
      'scanLeaf': scanLeaf,
      'printedLeaf': printedLeaf,
      'pdfPage': pdfPage,
      'imageLabel': null,
      'locator': null,
      'shortQuote': quote,
    };

Map<String, Object?> _zhinanCases() => <String, Object?>{
      'schemaVersion': '1.0.0',
      'sourceWork': '大六壬指南',
      'catalogStatus': 'approved',
      'limitations': <String>[
        '三例只批准影印页可直接读取和独立手排复核的盘面事实，不把原断结果作为现实预测验收。',
        '原书未给可唯一换算的公历时刻与时区，历法交节边界不由这些课例批准。',
      ],
      'cases': <Object?>[
        <String, Object?>{
          'caseId': 'dlr.case.zhinan.renyin-guimao-liu-tuizhai',
          'title': '丁丑八月壬寅日刘退斋太史索占',
          'verificationStatus': 'approved',
          'evidenceLevel': 'B',
          'locatorOnly': false,
          'sourceRef': _caseScanRef(
            'dlr.source.daliuren-zhinan-scan',
            volume: '全册',
            scanLeaf: 53,
            pdfPage: 54,
            printedLeaf: '49',
            quote: '丁丑八月壬寅日癸卯时，□中刘退斋太史索占。',
          ),
          'rawInput': <String, Object?>{
            'yearPillar': '丁丑',
            'lunarMonthText': '八月',
            'monthGeneral': '巳',
            'dayPillar': '壬寅',
            'hourPillar': '癸卯',
            'civilDateTime': null,
            'timezone': null,
            'question': '索占（原书未另题占类）',
            'personContext': <String, Object?>{
              'name': '刘退斋',
              'title': '太史',
              'placeText': null,
            },
          },
          'expectedFacts': <String, Object?>{
            'monthGeneral': '巳',
            'fourLessons': <Object?>[
              <String, Object?>{
                'ordinal': 1,
                'lower': '壬',
                'upper': '丑',
                'general': '太常',
              },
              <String, Object?>{
                'ordinal': 2,
                'lower': '丑',
                'upper': '卯',
                'general': '太阴',
              },
              <String, Object?>{
                'ordinal': 3,
                'lower': '寅',
                'upper': '辰',
                'general': '天后',
              },
              <String, Object?>{
                'ordinal': 4,
                'lower': '辰',
                'upper': '午',
                'general': '螣蛇',
              },
            ],
            'transmissions': <Object?>[
              <String, Object?>{
                'stage': '初传',
                'branch': '辰',
                'general': '天后',
                'sixRelation': '官鬼',
              },
              <String, Object?>{
                'stage': '中传',
                'branch': '午',
                'general': '螣蛇',
                'sixRelation': '妻财',
              },
              <String, Object?>{
                'stage': '末传',
                'branch': '申',
                'general': '六合',
                'sixRelation': '父母',
              },
            ],
            'courseNames': <String>['重审', '斩关'],
          },
          'classicJudgment': '此近君阴贵人也。',
          'expectedDerivation': <String, Object?>{
            'method': 'independentManual',
            'usesProductionCode': false,
            'reviewer': 'c00_independent_recheck (Codex)',
            'reviewedAt': '2026-07-28',
          },
          'unresolvedFields': <String>[
            'civilDateTime',
            'timezone',
            'solarTermInstant',
            'placeTextFirstCharacter',
          ],
          'adoptedAssumptions': <String>[
            '原题地名首字无法可靠辨认，登记为 unknown，不据上下文补字。',
            '四课和三传按影印盘式独立手排复核，未调用项目生产代码。',
          ],
          'coveredRuleIds': <String>[
            'dlr.rule.pan.001.month-general-by-zhongqi',
            'dlr.rule.pan.002.month-general-table',
            'dlr.rule.pan.003.heaven-plate-rotation',
            'dlr.rule.pan.005.first-lesson',
            'dlr.rule.pan.006.second-lesson',
            'dlr.rule.pan.007.third-lesson',
            'dlr.rule.pan.008.fourth-lesson',
            'dlr.rule.jiuzongmen.001.zeike',
            'dlr.rule.kejing.002',
            'dlr.rule.kejing.029',
          ],
          'targetCapabilityIds': <String>[
            'daliuren.pan.monthGeneral',
            'daliuren.pan.heavenPlate',
            'daliuren.pan.fourLessons',
            'daliuren.jiuzongmen.zeike',
            'daliuren.kejing.002',
            'daliuren.kejing.029',
          ],
        },
        <String, Object?>{
          'caseId': 'dlr.case.zhinan.yiwei-jimao-feng-yunsheng',
          'title': '丙子三月乙未日冯允升被逮求占',
          'verificationStatus': 'approved',
          'evidenceLevel': 'B',
          'locatorOnly': false,
          'sourceRef': _caseScanRef(
            'dlr.source.daliuren-zhinan-scan',
            volume: '全册',
            scanLeaf: 55,
            pdfPage: 56,
            printedLeaf: '51',
            quote: '丙子三月乙未日己卯时，御马监太监冯允升被逮刑部，已定重辟，求占。',
          ),
          'rawInput': <String, Object?>{
            'yearPillar': '丙子',
            'lunarMonthText': '三月',
            'monthGeneral': '戌',
            'dayPillar': '乙未',
            'hourPillar': '己卯',
            'civilDateTime': null,
            'timezone': null,
            'question': '被逮刑部、已定重辟，求占',
            'personContext': <String, Object?>{
              'name': '冯允升',
              'title': '御马监太监',
            },
          },
          'expectedFacts': <String, Object?>{
            'monthGeneral': '戌',
            'fourLessons': <Object?>[
              <String, Object?>{
                'ordinal': 1,
                'lower': '乙',
                'upper': '亥',
                'general': '螣蛇',
              },
              <String, Object?>{
                'ordinal': 2,
                'lower': '亥',
                'upper': '午',
                'general': '天空',
              },
              <String, Object?>{
                'ordinal': 3,
                'lower': '未',
                'upper': '寅',
                'general': '太阴',
              },
              <String, Object?>{
                'ordinal': 4,
                'lower': '寅',
                'upper': '酉',
                'general': '六合',
              },
            ],
            'transmissions': <Object?>[
              <String, Object?>{
                'stage': '初传',
                'branch': '午',
                'general': '天空',
                'sixRelation': '子孙',
              },
              <String, Object?>{
                'stage': '中传',
                'branch': '丑',
                'general': '天后',
                'sixRelation': '妻财',
              },
              <String, Object?>{
                'stage': '末传',
                'branch': '申',
                'general': '勾陈',
                'sixRelation': '官鬼',
              },
            ],
            'courseNames': <String>['重审'],
          },
          'classicJudgment': '此课必遇恩宥，仍救重刑之兆。',
          'expectedDerivation': <String, Object?>{
            'method': 'independentManual',
            'usesProductionCode': false,
            'reviewer': 'c00_independent_recheck (Codex)',
            'reviewedAt': '2026-07-28',
          },
          'unresolvedFields': <String>[
            'civilDateTime',
            'timezone',
            'solarTermInstant',
          ],
          'adoptedAssumptions': <String>[
            '四课和三传按影印盘式独立手排复核，未调用项目生产代码。',
          ],
          'coveredRuleIds': <String>[
            'dlr.rule.pan.001.month-general-by-zhongqi',
            'dlr.rule.pan.002.month-general-table',
            'dlr.rule.pan.003.heaven-plate-rotation',
            'dlr.rule.pan.005.first-lesson',
            'dlr.rule.pan.006.second-lesson',
            'dlr.rule.pan.007.third-lesson',
            'dlr.rule.pan.008.fourth-lesson',
            'dlr.rule.jiuzongmen.001.zeike',
            'dlr.rule.kejing.002',
          ],
          'targetCapabilityIds': <String>[
            'daliuren.pan.monthGeneral',
            'daliuren.pan.heavenPlate',
            'daliuren.pan.fourLessons',
            'daliuren.jiuzongmen.zeike',
            'daliuren.kejing.002',
          ],
        },
        <String, Object?>{
          'caseId': 'dlr.case.zhinan.gengyin-gengchen-ma-lianzhuang',
          'title': '戊辰十一月庚寅日马廉庄能拜相否',
          'verificationStatus': 'approved',
          'evidenceLevel': 'B',
          'locatorOnly': false,
          'sourceRef': _caseScanRef(
            'dlr.source.daliuren-zhinan-scan',
            volume: '全册',
            scanLeaf: 43,
            pdfPage: 44,
            printedLeaf: '39',
            quote: '戊辰年十一月庚寅日庚辰时，徽州汪仙民、邵无奇在京占少宗伯马廉庄能拜相否。',
          ),
          'rawInput': <String, Object?>{
            'yearPillar': '戊辰',
            'lunarMonthText': '十一月',
            'monthGeneral': '寅',
            'dayPillar': '庚寅',
            'hourPillar': '庚辰',
            'civilDateTime': null,
            'timezone': null,
            'question': '少宗伯马廉庄能拜相否',
            'personContext': <String, Object?>{
              'questioners': <String>['汪仙民', '邵无奇'],
              'subjectName': '马廉庄',
              'subjectTitle': '少宗伯',
              'placeText': '徽州／在京',
            },
          },
          'expectedFacts': <String, Object?>{
            'monthGeneral': '寅',
            'fourLessons': <Object?>[
              <String, Object?>{
                'ordinal': 1,
                'lower': '庚',
                'upper': '午',
                'general': '青龙',
              },
              <String, Object?>{
                'ordinal': 2,
                'lower': '午',
                'upper': '辰',
                'general': '六合',
              },
              <String, Object?>{
                'ordinal': 3,
                'lower': '寅',
                'upper': '子',
                'general': '天后',
              },
              <String, Object?>{
                'ordinal': 4,
                'lower': '子',
                'upper': '戌',
                'general': '玄武',
              },
            ],
            'transmissions': <Object?>[
              <String, Object?>{
                'stage': '初传',
                'branch': '午',
                'general': '青龙',
                'sixRelation': '官鬼',
              },
              <String, Object?>{
                'stage': '中传',
                'branch': '辰',
                'general': '六合',
                'sixRelation': '父母',
              },
              <String, Object?>{
                'stage': '末传',
                'branch': '寅',
                'general': '螣蛇',
                'sixRelation': '妻财',
              },
            ],
            'courseNames': <String>['涉害', '顾祖'],
          },
          'classicJudgment': '马宗伯不但不能入拜，且不日还乡矣。',
          'expectedDerivation': <String, Object?>{
            'method': 'independentManual',
            'usesProductionCode': false,
            'reviewer': 'c00_guide_shehai_review (Codex)',
            'reviewedAt': '2026-07-28',
          },
          'unresolvedFields': <String>[
            'civilDateTime',
            'timezone',
            'solarTermInstant',
            'uniqueCivilYear',
            'exactHourTime',
            'editionPublicationYear',
            'questionerSegmentation',
          ],
          'adoptedAssumptions': <String>[
            '寅将由同页盘式反推，并非原题直书；只批准本例盘面，不批准完整历法换将规则。',
            '原题无标点，汪仙民、邵无奇作为两名问占者仅为采用断句，不扩写精确地点。',
            '四课、三传和四害同深后孟申胜仲子的涉害结果均由影印盘式独立手排，未调用项目生产代码。',
          ],
          'coveredRuleIds': <String>[
            'dlr.rule.pan.003.heaven-plate-rotation',
            'dlr.rule.pan.005.first-lesson',
            'dlr.rule.pan.006.second-lesson',
            'dlr.rule.pan.007.third-lesson',
            'dlr.rule.pan.008.fourth-lesson',
            'dlr.rule.jiuzongmen.003.shehai',
            'dlr.rule.derived-facts.005.six-relations',
            'dlr.rule.kejing.004',
            'dlr.rule.kejing.061',
          ],
          'targetCapabilityIds': <String>[
            'daliuren.pan.heavenPlate',
            'daliuren.pan.fourLessons',
            'daliuren.jiuzongmen.shehai',
            'daliuren.derivedFacts.sixRelations',
            'daliuren.kejing.004',
            'daliuren.kejing.061',
          ],
        },
      ],
    };

Map<String, Object?> _cunyanCases() => <String, Object?>{
      'schemaVersion': '1.0.0',
      'sourceWork': '六壬存验',
      'catalogStatus': 'locatorOnly',
      'limitations': <String>[
        '固定提交可稳定定位文本行，但尚无逐页对应影印本。',
        '以下 expectedFacts 只转录盘面可直接读取字段，不调用生产算法补齐。',
        'civil date、时区、性别及无法从原文确定的盘面字段保持 unknown。',
      ],
      'cases': <Object?>[
        <String, Object?>{
          'caseId': 'dlr.case.cunyan.dingchou-yiyou-pregnancy',
          'title': '丁丑年四月乙酉日占六甲',
          'verificationStatus': 'pendingScan',
          'evidenceLevel': 'C',
          'locatorOnly': true,
          'sourceRef': _caseRef(
            'dlr.source.cunyan-transcription-d2a44794',
            '六壬存验-清-吴师青.txt:L357-L364',
            '丁丑年四月立夏酉将，乙酉日乙酉时，甲申旬，占六甲。',
          ),
          'rawInput': <String, Object?>{
            'yearPillar': '丁丑',
            'lunarMonthText': '四月',
            'solarTermText': '立夏',
            'monthGeneral': '酉',
            'dayPillar': '乙酉',
            'hourPillar': '乙酉',
            'xun': '甲申旬',
            'civilDateTime': null,
            'timezone': null,
            'question': '占六甲（孕产）',
            'personContext': <String, Object?>{},
          },
          'expectedFacts': <String, Object?>{
            'courseNames': <String>['重审', '斩关', '伏吟'],
            'transmissions': <Object?>[
              <String, Object?>{
                'stage': '初传',
                'dunGan': '壬',
                'branch': '辰',
                'general': '勾陈',
                'sixRelation': '妻财'
              },
              <String, Object?>{
                'stage': '中传',
                'dunGan': '乙',
                'branch': '酉',
                'general': '天后',
                'sixRelation': '官鬼'
              },
              <String, Object?>{
                'stage': '末传',
                'dunGan': '辛',
                'branch': '卯',
                'general': '青龙',
                'sixRelation': '兄弟'
              },
            ],
            'rawPlateLines': <String>[
              '后后 勾勾 / 酉酉 辰辰 / 酉酉 辰乙',
              '财 壬辰 勾；鬼 乙酉 后；兄 辛卯 青',
            ],
          },
          'classicJudgment': '原书断为双胎一男一女，并以胎神、生气、死气解释；该断语只作文本对照。',
          'expectedDerivation': <String, Object?>{
            'method': 'sourceTranscription',
            'usesProductionCode': false,
            'reviewer': 'C00 fixed-transcription review',
            'reviewedAt': '2026-07-28',
          },
          'unresolvedFields': <String>[
            'civilDateTime',
            'timezone',
            'sex',
            'birthContext',
            'scanLeaf',
            'printedLeaf',
            'fullHeavenPlateNormalization',
          ],
          'adoptedAssumptions': <String>[
            '三传按原文盘式右栏从上到下读为初、中、末。',
            '“勾、后、青”按十二天将全名展开。',
          ],
          'coveredRuleIds': <String>[
            'dlr.rule.jiuzongmen.001.zeike',
            'dlr.rule.kejing.002',
          ],
          'targetCapabilityIds': <String>[
            'daliuren.pan.monthGeneral',
            'daliuren.jiuzongmen.zeike',
            'daliuren.kejing.002',
            'daliuren.derivedFacts.transmissionDunGan',
          ],
        },
        <String, Object?>{
          'caseId': 'dlr.case.cunyan.renwu-bingxu-exam',
          'title': '壬午年五月丙戌日占考试',
          'verificationStatus': 'pendingScan',
          'evidenceLevel': 'C',
          'locatorOnly': true,
          'sourceRef': _caseRef(
            'dlr.source.cunyan-transcription-d2a44794',
            '六壬存验-清-吴师青.txt:L594-L603',
            '壬午五月芒种申将，丙戌日己丑时，甲申旬，占考试。',
          ),
          'rawInput': <String, Object?>{
            'yearPillar': '壬午',
            'lunarMonthText': '五月',
            'solarTermText': '芒种',
            'monthGeneral': '申',
            'dayPillar': '丙戌',
            'hourPillar': '己丑',
            'xun': '甲申旬',
            'civilDateTime': null,
            'timezone': null,
            'question': '占考试',
            'personContext': <String, Object?>{},
          },
          'expectedFacts': <String, Object?>{
            'courseNames': <String>['不备', '知一', '度厄'],
            'transmissions': <Object?>[
              <String, Object?>{
                'stage': '初传',
                'dunGan': '戊',
                'branch': '子',
                'general': '螣蛇',
                'sixRelation': '官鬼'
              },
              <String, Object?>{
                'stage': '中传',
                'dunGan': '乙',
                'branch': '未',
                'general': '太常',
                'sixRelation': '兄弟'
              },
              <String, Object?>{
                'stage': '末传',
                'dunGan': '庚',
                'branch': '寅',
                'general': '六合',
                'sixRelation': '父母'
              },
            ],
            'rawPlateLines': <String>[
              '蛇空 常蛇 / 子巳 未子 / 巳戌 子丙',
              '鬼 戊子 蛇；兄 乙未 常；父 庚寅 六',
            ],
          },
          'classicJudgment': '原书断院试必取、科举省试未遂，并另答迁任、女病和城防；只保留首问作课例对照。',
          'expectedDerivation': <String, Object?>{
            'method': 'sourceTranscription',
            'usesProductionCode': false,
            'reviewer': 'C00 fixed-transcription review',
            'reviewedAt': '2026-07-28',
          },
          'unresolvedFields': <String>[
            'civilDateTime',
            'timezone',
            'sex',
            'birthContext',
            'scanLeaf',
            'printedLeaf',
            'fullHeavenPlateNormalization',
          ],
          'adoptedAssumptions': <String>[
            '三传按原文盘式右栏从上到下读为初、中、末。',
            '“蛇、常、六”按十二天将全名展开。',
          ],
          'coveredRuleIds': <String>[
            'dlr.rule.jiuzongmen.002.biyong',
            'dlr.rule.kejing.003',
          ],
          'targetCapabilityIds': <String>[
            'daliuren.pan.monthGeneral',
            'daliuren.jiuzongmen.biyong',
            'daliuren.kejing.003',
            'daliuren.derivedFacts.transmissionDunGan',
          ],
        },
        <String, Object?>{
          'caseId': 'dlr.case.cunyan.wuzi-bingzi-promotion',
          'title': '戊子年三月丙子日占升迁',
          'verificationStatus': 'pendingScan',
          'evidenceLevel': 'C',
          'locatorOnly': true,
          'sourceRef': _caseRef(
            'dlr.source.cunyan-transcription-d2a44794',
            '六壬存验-清-吴师青.txt:L605-L612',
            '戊子年三月清明戌将，丙子日壬辰时，甲戌旬，占升迁，知一、反吟。',
          ),
          'rawInput': <String, Object?>{
            'yearPillar': '戊子',
            'lunarMonthText': '三月',
            'solarTermText': '清明',
            'monthGeneral': '戌',
            'dayPillar': '丙子',
            'hourPillar': '壬辰',
            'xun': '甲戌旬',
            'civilDateTime': null,
            'timezone': null,
            'question': '占升迁',
            'personContext': <String, Object?>{},
          },
          'expectedFacts': <String, Object?>{
            'courseNames': <String>['知一', '反吟'],
            'transmissions': <Object?>[
              <String, Object?>{
                'stage': '初传',
                'dunGan': '壬',
                'branch': '午',
                'general': '青龙',
                'sixRelation': '比肩'
              },
              <String, Object?>{
                'stage': '中传',
                'dunGan': '丙',
                'branch': '子',
                'general': '天后',
                'sixRelation': '官鬼'
              },
              <String, Object?>{
                'stage': '末传',
                'dunGan': '壬',
                'branch': '午',
                'general': '青龙',
                'sixRelation': '比肩'
              },
            ],
            'rawPlateLines': <String>[
              '后龙 空贵 / 子午 巳亥 / 午子 亥丙',
              '比 壬午 龙；鬼 丙子 后；比 壬午 龙',
            ],
          },
          'classicJudgment': '原书断升迁后有意外之忧，并记六月升迁、后发疽卒；结果只作原书对照。',
          'expectedDerivation': <String, Object?>{
            'method': 'sourceTranscription',
            'usesProductionCode': false,
            'reviewer': 'C00 fixed-transcription review',
            'reviewedAt': '2026-07-28',
          },
          'unresolvedFields': <String>[
            'civilDateTime',
            'timezone',
            'sex',
            'birthContext',
            'scanLeaf',
            'printedLeaf',
            'fullHeavenPlateNormalization',
          ],
          'adoptedAssumptions': <String>[
            '三传按原文盘式右栏从上到下读为初、中、末。',
            '原书“返吟”与标题“反吟”视为同一课体的字形差异。',
          ],
          'coveredRuleIds': <String>[
            'dlr.rule.jiuzongmen.002.biyong',
            'dlr.rule.jiuzongmen.009.fanyin',
            'dlr.rule.kejing.003',
            'dlr.rule.kejing.010',
          ],
          'targetCapabilityIds': <String>[
            'daliuren.pan.monthGeneral',
            'daliuren.jiuzongmen.biyong',
            'daliuren.jiuzongmen.fanyin',
            'daliuren.kejing.003',
            'daliuren.kejing.010',
          ],
        },
      ],
    };
