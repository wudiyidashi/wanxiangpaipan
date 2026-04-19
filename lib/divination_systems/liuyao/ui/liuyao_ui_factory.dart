import 'package:flutter/material.dart';

import '../../../domain/divination_system.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/widgets/history_record_card.dart';
import '../liuyao_result.dart';
import 'liuyao_cast_screen.dart';
import 'liuyao_result_screen.dart';

/// 六爻 UI 工厂
///
/// 仅负责装配起卦页、结果页与历史卡片。
class LiuYaoUIFactory implements DivinationUIFactory {
  @override
  DivinationType get systemType => DivinationType.liuYao;

  @override
  Widget buildCastScreen(CastMethod method) => const LiuYaoCastScreen();

  @override
  Widget buildResultScreen(DivinationResult result) {
    if (result is! LiuYaoResult) {
      throw ArgumentError('结果类型必须是 LiuYaoResult，实际类型: ${result.runtimeType}');
    }
    return LiuYaoResultScreen(result: result);
  }

  @override
  Widget buildHistoryCard(DivinationResult result) =>
      HistoryRecordCard(result: result);

  @override
  IconData? getSystemIcon() => Icons.hexagon;

  @override
  Color? getSystemColor() => const Color(0xFFD32F2F);
}
