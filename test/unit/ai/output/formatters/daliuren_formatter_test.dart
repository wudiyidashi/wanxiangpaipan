import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/output/formatters/daliuren_formatter.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_system.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/pan_params.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/tianpan.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/san_chuan_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/shen_jiang_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/shen_sha_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/si_ke_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

/// 由位移 s 构造天盘映射（与分析层黄金课例同口径）
Map<String, String> _buildTianPanMap(int s) {
  const diZhi = DaLiuRenConstants.diZhi;
  return {
    for (var i = 0; i < 12; i++) diZhi[i]: diZhi[(i + s + 12) % 12],
  };
}

/// 直调排盘服务组装完整 DaLiuRenResult（不落库）
DaLiuRenResult _buildGoldenResult({
  required String riGan,
  required String riZhi,
  required int s,
  required List<String> kongWang,
  String yueJian = '寅',
  String shiZhi = '午',
}) {
  final tianPanMap = _buildTianPanMap(s);
  final shenJiangConfig = ShenJiangService.configureShenJiang(
    riGan: riGan,
    shiZhi: shiZhi,
    tianPanMap: tianPanMap,
  );
  final siKe = SiKeService.arrangeSiKe(
    riGan: riGan,
    riZhi: riZhi,
    tianPanMap: tianPanMap,
    shenJiangConfig: shenJiangConfig,
  );
  final sanChuan = SanChuanService.deriveSanChuan(
    siKe: siKe,
    tianPanMap: tianPanMap,
    shenJiangConfig: shenJiangConfig,
    kongWang: kongWang,
  );
  final shenShaList = ShenShaService.calculateShenSha(
    riGan: riGan,
    riZhi: riZhi,
    yueJian: yueJian,
    shiZhi: shiZhi,
  );
  return DaLiuRenResult(
    id: 'formatter-$riGan$riZhi-$s',
    castTime: DateTime(2026, 7, 27, 12),
    castMethod: CastMethod.time,
    lunarInfo: LunarInfo(
      yueJian: yueJian,
      riGan: riGan,
      riZhi: riZhi,
      riGanZhi: '$riGan$riZhi',
      kongWang: kongWang,
      yearGanZhi: '丙午',
      monthGanZhi: '壬寅',
    ),
    tianPan: TianPan(
      yueJiang: '亥',
      yueJiangName: '登明',
      shiZhi: shiZhi,
      tianPanMap: tianPanMap,
    ),
    siKe: siKe,
    sanChuan: sanChuan,
    shenJiangConfig: shenJiangConfig,
    shenShaList: shenShaList,
    panParams: const DaLiuRenPanParams(),
  );
}

void main() {
  group('DaLiuRenStructuredFormatter', () {
    test('should render agreed full structured template', () async {
      // 推导链（按 .trellis/tasks/07-27-daliuren-sanchuan-fix/design.md 手工复核）：
      // 2026-04-19 09:22 → 日柱癸亥，时支巳，月将戌加巳时（天盘支=地盘支+5）。
      // 癸寄丑（六壬寄宫口径）→ 一课上神=天盘[丑]=午，下神癸。
      // 四课：一课 午/癸（癸水克午火，下贼上）；二课 亥/午（上克下）；
      //       三课 辰/亥（上克下）；四课 酉/辰（下生上）。
      // 下贼上唯一 → 贼克（重审），初传取一课上神午；
      // 中传=天盘[午]=亥，末传=天盘[亥]=辰 → 三传 午亥辰。
      // 六亲（日干癸水）：午妻财、亥兄弟、辰官鬼；旬空子丑，三传皆非空亡。
      final system = DaLiuRenSystem();
      final formatter = DaLiuRenStructuredFormatter();

      final result = await system.cast(
        method: CastMethod.time,
        input: {},
        castTime: DateTime(2026, 4, 19, 9, 22),
      ) as DaLiuRenResult;

      final output = formatter.format(result, question: '问事业');
      final rendered = formatter.render(output);

      expect(output.summary, '贼克课 · 初传午 中传亥 末传辰');
      expect(rendered, startsWith('【大六壬完整结构化排盘】'));
      expect(rendered, contains('一、排盘总览'));
      expect(rendered, contains('- 起课：2026-04-19 09:22（农历三月初三）'));
      expect(rendered, contains('- 四柱：丙午年 壬辰月 癸亥日 丁巳时'));
      expect(rendered, contains('- 日主：癸'));
      expect(rendered, contains('- 月将：戌将（戌加巳时）'));
      expect(rendered, contains('- 昼夜：昼占'));
      expect(rendered, contains('- 贵人：昼贵巳'));
      expect(rendered, contains('- 课格：贼克课'));
      expect(rendered, contains('- 三传：午 → 亥 → 辰'));
      expect(rendered, contains('- 月建：辰'));
      expect(rendered, contains('- 日建：亥'));
      expect(rendered, contains('二、天地盘全宫（地盘→天盘）'));
      expect(rendered, contains('- 子→巳'));
      expect(rendered, contains('- 亥→辰'));
      expect(rendered, contains('三、十二天将完整分布'));
      expect(rendered, contains('- 贵人：巳（乘戌）'));
      expect(rendered, contains('- 天后：辰（乘酉）'));
      expect(rendered, contains('四、四课（天盘/地盘/天将/生克）'));
      expect(rendered, contains('- 一课：午 / 癸 / 腾蛇 / 下克上'));
      expect(rendered, contains('- 三课：辰 / 亥 / 天后 / 上克下'));
      expect(rendered, contains('五、三传'));
      expect(rendered, contains('- 取传依据：下贼上：第1课癸与午相克，取上神午发用（重审课）'));
      expect(rendered, contains('- 初传：午 / 妻财 / 腾蛇 / 非空亡'));
      expect(rendered, contains('- 末传：辰 / 官鬼 / 天后 / 非空亡'));
      expect(rendered, contains('六、神煞'));
      expect(rendered, contains('- 吉神：天德临壬、月德临壬、天喜临子、驿马临巳、天医临卯'));
      expect(rendered, contains('- 凶神：白虎临戌、丧门临巳、吊客临亥、劫煞临申、灾煞临酉、天狗临子'));
      expect(rendered, isNot(contains('二、起课参数')));
      expect(rendered, isNot(contains('关键标签')));
      expect(rendered, isNot(contains('排盘摘要')));
    });

    test('analysis section：黄金例 K（戊子元首）锁定课格/裁决/应期', () {
      // 戊子在甲申旬，空亡午未；s=+4 位移盘为分析层黄金例 K（元首课）
      final formatter = DaLiuRenStructuredFormatter();
      final result = _buildGoldenResult(
        riGan: '戊',
        riZhi: '子',
        s: 4,
        kongWang: const ['午', '未'],
      );

      final output = formatter.format(result, question: '问事业');
      final rendered = formatter.render(output);

      // 新增 analysis section 排在既有 sections 之后
      final analysis = output.getSection('analysis');
      expect(analysis, isNotNull);
      expect(analysis!.priority, 7);
      expect(analysis.content, contains('元首'));
      expect(analysis.content, contains('课格：课体贼克，格局元首（吉）'));
      expect(analysis.content, contains('干支主客：'));
      expect(analysis.content, contains('三传标签：'));
      expect(analysis.content, contains('- 初传：'));
      expect(analysis.content, contains('断曰'));
      expect(analysis.content, contains('应期候选：'));
      expect(rendered, contains('七、断课分析（规则标注）'));

      // coreData 增补字段
      expect(output.coreData['keGeName'], '元首');
      expect(output.coreData['verdictTrend'], isNotNull);

      // 既有字段不删不改
      expect(output.coreData['formatTitle'], '大六壬完整结构化排盘');
      expect(output.hasSection('overview'), true);
      expect(output.hasSection('shenSha'), true);
    });
  });
}
