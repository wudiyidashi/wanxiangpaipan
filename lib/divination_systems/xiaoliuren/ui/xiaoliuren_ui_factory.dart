import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/divination_system.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/widgets/history_record_card.dart';
import '../models/xiaoliuren_result.dart';
import 'xiaoliuren_cast_screen.dart';
import 'xiaoliuren_result_screen.dart';

/// 小六壬 UI 工厂
///
/// 仅负责装配起课页、结果页与历史卡片。
class XiaoLiuRenUIFactory implements DivinationUIFactory {
  @override
  DivinationType get systemType => DivinationType.xiaoLiuRen;

  @override
  Widget buildCastScreen(CastMethod method) => const XiaoLiuRenCastScreen();

  @override
  Widget buildResultScreen(DivinationResult result) {
    if (result is! XiaoLiuRenResult) {
      throw ArgumentError(
        '结果类型必须是 XiaoLiuRenResult，实际类型: ${result.runtimeType}',
      );
    }
    return XiaoLiuRenResultScreen(result: result);
  }

  @override
  Widget buildHistoryCard(DivinationResult result) =>
      HistoryRecordCard(result: result);

  @override
  IconData? getSystemIcon() => Icons.hub;

  @override
  Color? getSystemColor() => AppColors.xiaoliurenColor;
}
