import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wanxiang_paipan/ai/service/ai_analysis_service.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/pan_params.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/tianpan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/ui/daliuren_result_screen.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/ui/daliuren_result_sections.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/ui/widgets/daliuren_ke_ge_card.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/ui/widgets/daliuren_pan_disk_dialog.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/daliuren_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/models/daliuren_analysis_models.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/san_chuan_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/shen_jiang_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/shen_sha_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/si_ke_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/analysis/models/polarity.dart';
import 'package:wanxiang_paipan/domain/services/shared/analysis/models/verdict_models.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

/// 由位移 s 构造天盘映射（与分析层黄金课例同口径）
Map<String, String> buildTianPanMap(int s) {
  const diZhi = DaLiuRenConstants.diZhi;
  return {
    for (var i = 0; i < 12; i++) diZhi[i]: diZhi[(i + s + 12) % 12],
  };
}

/// 直调排盘服务组装完整 DaLiuRenResult（不落库）
DaLiuRenResult buildResult({
  required String riGan,
  required String riZhi,
  required int s,
  required List<String> kongWang,
  String yueJian = '寅',
  String shiZhi = '午',
}) {
  final tianPanMap = buildTianPanMap(s);
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
    id: 'test-$riGan$riZhi-$s',
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

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  // 黄金例 K：戊子 s=+4 元首课（甲申旬，空亡午未）
  final resultK = buildResult(
    riGan: '戊',
    riZhi: '子',
    s: 4,
    kongWang: const ['午', '未'],
  );
  final reportK = DaLiuRenAnalyzer.analyze(resultK);

  group('DaLiuRenKeGeCard', () {
    testWidgets('展示格名、课体、polarity 徽标与基调', (tester) async {
      await tester.pumpWidget(_wrap(DaLiuRenKeGeCard(report: reportK)));

      expect(find.text('课体断诀'), findsOneWidget);
      expect(find.text('元首'), findsOneWidget);
      expect(find.text('贼克课'), findsOneWidget);
      expect(find.text('吉'), findsOneWidget);
      expect(find.text('尊临卑、事顺理正'), findsOneWidget);
      // 裁决摘要
      expect(find.textContaining('断曰'), findsOneWidget);
    });

    testWidgets('未决条件 chips 与推理链展开', (tester) async {
      final report = DaLiuRenAnalysisReport(
        analysisRuleSetVersion: DlrRuleSetVersions.analysisCurrent,
        sourcePanRuleSetVersion: DlrRuleSetVersions.panCurrent,
        compatibilityStatus: DlrAnalysisCompatibility.current,
        keGe: KeGeInfo(
          ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeChongShen),
          keTypeName: '贼克',
          geName: '重审',
          polarity: Polarity.neutral,
          reason: '事从卑下而起，先难后易，审慎则吉',
        ),
        judgment: VerdictJudgment(
          trend: VerdictTrend.nanCheng,
          conditions: [
            VerdictCondition(
              label: '待发用填实',
              branch: '午',
              reason: '初传午落空',
            ),
            VerdictCondition(
              label: '待归宿填实',
              branch: '未',
              reason: '末传未落空',
              hasRescue: false,
            ),
          ],
          factors: [
            VerdictFactor(
              rule: '裁决·首尾俱空',
              effect: VerdictEffect.suspend,
              reason: '首尾俱空，事难成实',
              source: '本项目约定（大六壬断课 v1）',
            ),
          ],
          summary: '课体贼克（重审），断曰：难成。',
        ),
        verdictSummary: '课体贼克（重审），断曰：难成。',
      );
      await tester.pumpWidget(_wrap(DaLiuRenKeGeCard(report: report)));

      expect(find.text('未决条件'), findsOneWidget);
      expect(find.text('待发用填实（午）'), findsOneWidget);
      // hasRescue=false 追加"无解"标记
      expect(find.text('待归宿填实（未）·无解'), findsOneWidget);

      // 展开推理链
      await tester.tap(find.text('推理链'));
      await tester.pumpAndSettle();
      expect(find.text('裁决·首尾俱空｜首尾俱空，事难成实'), findsOneWidget);
      expect(find.text('本项目约定（大六壬断课 v1）'), findsOneWidget);
    });

    testWidgets('judgment 为 null 时只展示格名与基调', (tester) async {
      final report = DaLiuRenAnalysisReport(
        analysisRuleSetVersion: DlrRuleSetVersions.analysisCurrent,
        sourcePanRuleSetVersion: DlrRuleSetVersions.panCurrent,
        compatibilityStatus: DlrAnalysisCompatibility.current,
        keGe: KeGeInfo(
          ruleRef: DlrRuleRef.project(DlrProjectRuleIds.keGeZhiYi),
          keTypeName: '比用',
          geName: '知一',
          polarity: Polarity.neutral,
          reason: '事在同类，择亲近者而就',
        ),
      );
      await tester.pumpWidget(_wrap(DaLiuRenKeGeCard(report: report)));

      expect(find.text('知一'), findsOneWidget);
      expect(find.text('推理链'), findsNothing);
      expect(find.text('未决条件'), findsNothing);
    });
  });

  group('DaLiuRenSanChuanSection 徽标与详析弹层', () {
    testWidgets('无 report 时行为不变（无徽标提示）', (tester) async {
      await tester.pumpWidget(_wrap(DaLiuRenSanChuanSection(result: resultK)));
      expect(find.text('点击传柱查看该传详析'), findsNothing);
    });

    testWidgets('注入 report 后传行出现 top 标签', (tester) async {
      await tester.pumpWidget(
        _wrap(DaLiuRenSanChuanSection(result: resultK, report: reportK)),
      );
      final chuTop = reportK.topTagsForChuan(ChuanPosition.chu, count: 2);
      expect(chuTop, isNotEmpty);
      for (final tag in chuTop) {
        expect(find.text(tag.term), findsWidgets);
      }
      expect(find.text('点击传柱查看该传详析'), findsOneWidget);
    });

    testWidgets('360dp 窄屏下带徽标不溢出（回归：Row overflow 30px）', (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0; // 逻辑宽 360dp，对齐 MuMu 实机
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(DaLiuRenSanChuanSection(result: resultK, report: reportK)),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('点击传行弹出分类分组详析弹层', (tester) async {
      await tester.pumpWidget(
        _wrap(DaLiuRenSanChuanSection(result: resultK, report: reportK)),
      );
      await tester.tap(find.text('初传'));
      await tester.pumpAndSettle();

      // 弹层标题：初传 {支}（{六亲}·乘{天将}）
      final chu = resultK.sanChuan.chuChuan;
      expect(
        find.textContaining(
            '初传 ${chu.diZhi}（${chu.liuQin}·乘${chu.chengShenName}）'),
        findsOneWidget,
      );
      // 每传至少有天将标签 → 分类标题出现
      expect(find.text(DlrTagCategory.tianJiang.name), findsOneWidget);
      // 课局区块（K 例有课局标签时展示）
      if (reportK.juTags.isNotEmpty) {
        expect(find.text('课局'), findsOneWidget);
      }
    });
  });

  group('大六壬结果页装配', () {
    Widget buildScreen(DaLiuRenResult result) {
      return Provider<AIAnalysisService?>.value(
        value: null,
        child: MaterialApp(
          home: DaLiuRenResultScreen(result: result),
        ),
      );
    }

    testWidgets('出现课格卡、圆盘图入口与共享应期卡', (tester) async {
      await tester.pumpWidget(buildScreen(resultK));
      await tester.pumpAndSettle();

      expect(find.text('课体断诀'), findsOneWidget);
      expect(find.text('天地盘圆盘图'), findsOneWidget);
      expect(find.text('应期推算'), findsOneWidget);
    });

    testWidgets('点击入口弹出天地盘圆盘图 Dialog', (tester) async {
      await tester.pumpWidget(buildScreen(resultK));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('天地盘圆盘图'));
      await tester.tap(find.text('天地盘圆盘图'));
      await tester.pumpAndSettle();

      expect(find.byType(DaLiuRenPanDiskDialog), findsOneWidget);
      expect(find.text('初→中→末弦线'), findsOneWidget);
    });
  });
}
