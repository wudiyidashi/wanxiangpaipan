import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/divination_system.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/widgets/history_record_card.dart';
import '../models/daliuren_result.dart';
import 'daliuren_cast_screen.dart';
import 'daliuren_result_screen.dart';

/// 大六壬 UI 工厂
///
/// 仅负责装配起课页、结果页和历史卡片，具体页面实现拆分到独立文件。
class DaLiuRenUIFactory implements DivinationUIFactory {
  @override
  DivinationType get systemType => DivinationType.daLiuRen;

  @override
  Widget buildCastScreen(CastMethod method) {
    return const DaLiuRenCastScreen();
  }

  @override
  Widget buildResultScreen(DivinationResult result) {
    if (result is! DaLiuRenResult) {
      throw ArgumentError('结果类型必须是 DaLiuRenResult，实际类型: ${result.runtimeType}');
    }
    return DaLiuRenResultScreen(result: result);
  }

  @override
  Widget buildHistoryCard(DivinationResult result) =>
      HistoryRecordCard(result: result);

  @override
  IconData? getSystemIcon() => Icons.wb_sunny;

  @override
  Color? getSystemColor() => AppColors.daliurenColor;
}
