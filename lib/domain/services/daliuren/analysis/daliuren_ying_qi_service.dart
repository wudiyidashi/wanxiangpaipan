import '../../../../divination_systems/daliuren/daliuren_constants.dart';
import '../../../../divination_systems/daliuren/models/san_chuan.dart';
import '../../../../divination_systems/daliuren/models/shen_sha.dart';
import '../../shared/analysis/models/verdict_models.dart';

/// 大六壬应期层：产出应期候选（v1 全为日尺度）。
///
/// 规则为本项目约定（大六壬断课 v1）；空亡填实候选与
/// VerdictCondition.branch 按地支衔接。
class DaLiuRenYingQiService {
  DaLiuRenYingQiService._();

  /// 计算应期候选
  ///
  /// [conditions] 裁决层产出的悬置条件（衔接空亡填实候选）。
  static List<YingQiCandidate> calculate({
    required SanChuan sanChuan,
    required ShenShaList shenShaList,
    required List<VerdictCondition> conditions,
  }) {
    final candidates = <YingQiCandidate>[];
    final chuZhi = sanChuan.chuChuanDiZhi;
    final moZhi = sanChuan.moChuanDiZhi;

    // 1. 待填实之空亡传支值日（存在空亡悬置）
    for (final condition in conditions) {
      final branch = condition.branch;
      if (branch == null) {
        continue;
      }
      candidates.add(YingQiCandidate(
        label: '$branch日（${condition.label}）',
        branch: branch,
        scale: YingQiScale.ri,
        reason: '空亡传支$branch值日填实，${condition.label}',
        priority: 1,
      ));
    }

    // 2. 发用之期（初传支值日，恒有）
    candidates.add(YingQiCandidate(
      label: '$chuZhi日（发用之期）',
      branch: chuZhi,
      scale: YingQiScale.ri,
      reason: '初传$chuZhi值日，事应发用之机',
      priority: 2,
    ));

    // 3. 归宿之期（末传支值日，恒有；与初传同支时去重）
    if (moZhi != chuZhi) {
      candidates.add(YingQiCandidate(
        label: '$moZhi日（归宿之期）',
        branch: moZhi,
        scale: YingQiScale.ri,
        reason: '末传$moZhi值日，事应归宿之期',
        priority: 3,
      ));
    }

    // 4. 驿马临传，马支值日（神煞驿马命中三传）
    final chuanZhiSet = sanChuan.allChuan.map((c) => c.diZhi).toSet();
    final yiMaList = shenShaList.allShenSha
        .where((s) => s.name == '驿马' && chuanZhiSet.contains(s.diZhi));
    for (final yiMa in yiMaList) {
      candidates.add(YingQiCandidate(
        label: '${yiMa.diZhi}日（驿马动应）',
        branch: yiMa.diZhi,
        scale: YingQiScale.ri,
        reason: '驿马${yiMa.diZhi}临传，马支值日事动而速',
        priority: 2,
      ));
    }

    // 5. 伏吟冲动之期（初传冲支值日，课体伏吟）
    if (sanChuan.isFuYin) {
      final chongZhi = DaLiuRenConstants.getChongZhi(chuZhi);
      candidates.add(YingQiCandidate(
        label: '$chongZhi日（伏吟冲动之期）',
        branch: chongZhi,
        scale: YingQiScale.ri,
        reason: '伏吟事静，待$chongZhi日冲动初传$chuZhi，静极生动',
        priority: 2,
      ));
    }

    candidates.sort((a, b) => a.priority.compareTo(b.priority));
    return candidates;
  }
}
