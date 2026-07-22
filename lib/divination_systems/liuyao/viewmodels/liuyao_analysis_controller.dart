import 'package:flutter/foundation.dart';

import '../../../domain/repositories/divination_repository.dart';
import '../../../domain/services/liuyao/analysis/liuyao_analyzer.dart';
import '../../../domain/services/liuyao/analysis/models/analysis_report.dart';
import '../liuyao_result.dart';

/// 六爻结果页分析状态层。
///
/// 持有用户选定的用神与派生的 [AnalysisReport]；
/// 报告为纯派生数据不落库，仅用神选择经 [DivinationRepository.updateRecord] 持久化。
/// 持久化失败不回滚界面状态（下次进入时以库中数据为准）。
class LiuYaoAnalysisController extends ChangeNotifier {
  LiuYaoAnalysisController({
    required LiuYaoResult result,
    DivinationRepository? repository,
  })  : _result = result,
        _repository = repository {
    _recompute();
  }

  LiuYaoResult _result;
  final DivinationRepository? _repository;
  late AnalysisReport _report;

  LiuYaoResult get result => _result;
  AnalysisReport get report => _report;
  int? get yongShenPosition => _result.yongShenPosition;
  bool get yongShenIsFuShen => _result.yongShenIsFuShen;
  bool get hasYongShen => _result.yongShenPosition != null;

  /// 选定用神并持久化；重复选择同一爻位为无操作
  Future<void> selectYongShen(int position, {bool isFuShen = false}) async {
    if (_result.yongShenPosition == position &&
        _result.yongShenIsFuShen == isFuShen) {
      return;
    }
    _result = _result.copyWith(
      yongShenPosition: position,
      yongShenIsFuShen: isFuShen,
    );
    _recompute();
    notifyListeners();
    await _persist();
  }

  /// 取消用神选择
  Future<void> clearYongShen() async {
    if (_result.yongShenPosition == null) return;
    _result = _result.copyWith(
      yongShenPosition: null,
      yongShenIsFuShen: false,
    );
    _recompute();
    notifyListeners();
    await _persist();
  }

  void _recompute() {
    _report = LiuYaoAnalyzer.analyze(
      _result.mainGua,
      _result.changingGua,
      _result.lunarInfo,
      yongShenPosition: _result.yongShenPosition,
      yongShenIsFuShen: _result.yongShenIsFuShen,
    );
  }

  Future<void> _persist() async {
    try {
      await _repository?.updateRecord(_result);
    } catch (e) {
      debugPrint('用神选择持久化失败: $e');
    }
  }
}
