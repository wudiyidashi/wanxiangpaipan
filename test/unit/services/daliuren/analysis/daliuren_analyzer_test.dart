import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/pan_params.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/tianpan.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/analysis/daliuren_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/san_chuan_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/shen_jiang_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/shen_sha_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/si_ke_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

/// 由位移 s 构造天盘映射（与黄金课例同口径）
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

void main() {
  group('DaLiuRenAnalyzer 全链冒烟（design §7）', () {
    test('黄金例 K：戊子 s=+4 元首课，报告各区非空且摘要含格名', () {
      // 戊子在甲申旬，空亡午未
      final result = buildResult(
        riGan: '戊',
        riZhi: '子',
        s: 4,
        kongWang: const ['午', '未'],
      );
      final report = DaLiuRenAnalyzer.analyze(result);

      expect(report.keGe.geName, '元首');
      expect(report.ganZhiTags, isNotEmpty);
      expect(
        report.chuanTags.values.every((tags) => tags.isNotEmpty),
        true,
        reason: '每传至少有天将标签',
      );
      expect(report.yingQi, isNotEmpty);
      expect(report.judgment, isNotNull);
      expect(report.verdictSummary, contains('元首'));
      expect(report.verdictSummary, contains('贼克'));
    });

    test('黄金例 H2：丁亥 s=0 伏吟自信课，报告各区非空且摘要含格名', () {
      // 丁亥在甲申旬，空亡午未
      final result = buildResult(
        riGan: '丁',
        riZhi: '亥',
        s: 0,
        kongWang: const ['午', '未'],
      );
      final report = DaLiuRenAnalyzer.analyze(result);

      expect(report.keGe.geName, '自信');
      expect(report.ganZhiTags, isNotEmpty);
      expect(
        report.chuanTags.values.every((tags) => tags.isNotEmpty),
        true,
      );
      expect(report.yingQi, isNotEmpty);
      expect(report.judgment, isNotNull);
      expect(report.verdictSummary, contains('自信'));
      // 伏吟必有冲动之期候选
      expect(
        report.yingQi!.any((c) => c.label.contains('伏吟')),
        true,
      );
    });

    test('topTagsForChuan 按优先级取前 N 个', () {
      final result = buildResult(
        riGan: '戊',
        riZhi: '子',
        s: 4,
        kongWang: const ['午', '未'],
      );
      final report = DaLiuRenAnalyzer.analyze(result);
      for (final position in report.chuanTags.keys) {
        final top = report.topTagsForChuan(position, count: 2);
        expect(top.length, lessThanOrEqualTo(2));
        if (top.length == 2) {
          expect(top[0].priority, lessThanOrEqualTo(top[1].priority));
        }
      }
    });

    test('报告声明 analysis/source pan 版本并区分三种 compatibility', () {
      final legacy = buildResult(
        riGan: '戊',
        riZhi: '子',
        s: 4,
        kongWang: const ['午', '未'],
      );
      final currentSnapshot = DlrCastInputSnapshot.capture(
        castMethod: CastMethod.time,
        castTime: legacy.castTime,
        utcOffsetMinutes: legacy.castTime.timeZoneOffset.inMinutes,
        normalizedInput: const <String, dynamic>{
          'params': <String, dynamic>{},
        },
        replayStatus: DlrReplayStatus.complete,
      );
      final current = legacy.copyWith(
        panRuleSetVersion: DlrRuleSetVersions.panCurrent,
        castInputSnapshot: currentSnapshot,
      );
      final currentWithoutSnapshot = legacy.copyWith(
        panRuleSetVersion: DlrRuleSetVersions.panCurrent,
      );
      final future = legacy.copyWith(
        panRuleSetVersion: 'daliuren-pan/99.0.0',
      );

      final legacyReport = DaLiuRenAnalyzer.analyze(legacy);
      final currentReport = DaLiuRenAnalyzer.analyze(current);
      final currentWithoutSnapshotReport =
          DaLiuRenAnalyzer.analyze(currentWithoutSnapshot);
      final futureReport = DaLiuRenAnalyzer.analyze(future);

      expect(
        currentReport.analysisRuleSetVersion,
        DlrRuleSetVersions.analysisCurrent,
      );
      expect(
        currentReport.sourcePanRuleSetVersion,
        DlrRuleSetVersions.panCurrent,
      );
      expect(
        currentReport.compatibilityStatus,
        DlrAnalysisCompatibility.current,
      );
      expect(
        legacyReport.compatibilityStatus,
        DlrAnalysisCompatibility.legacyUnknown,
      );
      expect(
        currentWithoutSnapshotReport.compatibilityStatus,
        DlrAnalysisCompatibility.legacyUnknown,
      );
      expect(
        futureReport.compatibilityStatus,
        DlrAnalysisCompatibility.versionMismatch,
      );
    });

    test('所有当前分析生产者都显式产出 project-v1 ruleRef', () {
      final result = buildResult(
        riGan: '戊',
        riZhi: '子',
        s: 4,
        kongWang: const ['午', '未'],
      );
      final report = DaLiuRenAnalyzer.analyze(result);
      final refs = <DlrRuleRef>[
        report.keGe.ruleRef,
        ...report.ganZhiTags.map((tag) => tag.ruleRef),
        ...report.chuanTags.values
            .expand((tags) => tags)
            .map((tag) => tag.ruleRef),
        ...report.juTags.map((tag) => tag.ruleRef),
      ];

      expect(refs, isNotEmpty);
      expect(refs.every((ref) => ref.kind == DlrRuleKind.project), isTrue);
      expect(
        refs.every((ref) => ref.evidenceLevel == DlrEvidenceLevel.d),
        isTrue,
      );
      expect(
        refs.every(
          (ref) => ref.ruleSetVersion == DlrRuleSetVersions.analysisCurrent,
        ),
        isTrue,
      );
      expect(
        refs.every((ref) => ref.ruleId.startsWith('dlr.project.analysis.')),
        isTrue,
      );
    });
  });
}
