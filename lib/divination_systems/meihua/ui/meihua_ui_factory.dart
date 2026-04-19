import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/divination_system.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/widgets/history_record_card.dart';
import '../models/meihua_result.dart';
import 'meihua_cast_screen.dart';
import 'meihua_result_screen.dart';

/// 梅花易数 UI 工厂
///
/// 仅负责装配起卦页、结果页与历史卡片。
class MeiHuaUIFactory implements DivinationUIFactory {
  @override
  DivinationType get systemType => DivinationType.meiHua;

  @override
  Widget buildCastScreen(CastMethod method) => const MeiHuaCastScreen();

  @override
  Widget buildResultScreen(DivinationResult result) {
    if (result is! MeiHuaResult) {
      throw ArgumentError(
        '结果类型必须是 MeiHuaResult，实际类型: ${result.runtimeType}',
      );
    }
    return MeiHuaResultScreen(result: result);
  }

  @override
  Widget buildHistoryCard(DivinationResult result) =>
      HistoryRecordCard(result: result);

  @override
  IconData? getSystemIcon() => Icons.local_florist;

  @override
  Color? getSystemColor() => AppColors.meihuaColor;
}
