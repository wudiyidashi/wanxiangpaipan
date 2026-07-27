import '../../../../divination_systems/daliuren/models/daliuren_result.dart';
import 'chuan_analysis_service.dart';
import 'daliuren_verdict_service.dart';
import 'daliuren_ying_qi_service.dart';
import 'gan_zhi_zhu_ke_service.dart';
import 'ke_ge_service.dart';
import 'models/daliuren_analysis_models.dart';
import 'shen_sha_chuan_service.dart';

/// 大六壬断课分析编排器：唯一对上层暴露的分析入口。
///
/// 事实层（课格/干支主客/三传结构/神煞落传）→ 裁决层（决策表首行命中）
/// → 应期层，组装完整报告。分析结果为运行时派生数据，任何路径不落库。
class DaLiuRenAnalyzer {
  DaLiuRenAnalyzer._();

  static DaLiuRenAnalysisReport analyze(DaLiuRenResult result) {
    final siKe = result.siKe;
    final sanChuan = result.sanChuan;
    final kongWang = result.lunarInfo.kongWang;

    // 3.1 课格定性
    final keGe = KeGeService.analyze(sanChuan: sanChuan, siKe: siKe);

    // 3.2 干支主客
    final ganZhiTags = GanZhiZhuKeService.analyze(
      siKe: siKe,
      kongWang: kongWang,
    );

    // 3.3 三传结构（每传 + 课局级）
    final chuanTags = ChuanAnalysisService.analyzeChuanTags(
      sanChuan: sanChuan,
      riGan: siKe.riGan,
    );
    final juTags = ChuanAnalysisService.analyzeJuTags(
      sanChuan: sanChuan,
      riGan: siKe.riGan,
    );

    // 3.4 神煞落传（并入每传标签）
    final shenShaTags = ShenShaChuanService.analyze(
      sanChuan: sanChuan,
      shenShaList: result.shenShaList,
    );
    shenShaTags.forEach((position, tags) {
      chuanTags[position]!.addAll(tags);
    });

    // 4. 裁决
    final judgment = DaLiuRenVerdictService.judge(
      keGe: keGe,
      ganZhiTags: ganZhiTags,
      chuanTags: chuanTags,
      juTags: juTags,
      chuChuanZhi: sanChuan.chuChuanDiZhi,
      moChuanZhi: sanChuan.moChuanDiZhi,
      chuKongWang: sanChuan.chuChuan.isKongWang,
      zhongKongWang: sanChuan.zhongChuan.isKongWang,
      moKongWang: sanChuan.moChuan.isKongWang,
    );

    // 5. 应期
    final yingQi = DaLiuRenYingQiService.calculate(
      sanChuan: sanChuan,
      shenShaList: result.shenShaList,
      conditions: judgment.conditions,
    );

    return DaLiuRenAnalysisReport(
      keGe: keGe,
      ganZhiTags: ganZhiTags,
      chuanTags: chuanTags,
      juTags: juTags,
      yingQi: yingQi,
      judgment: judgment,
      verdictSummary: judgment.summary,
    );
  }
}
