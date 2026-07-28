import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/divination_system.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/widgets/history_record_card.dart';
import '../models/qimen_result.dart';
import 'qimen_cast_screen.dart';
import 'qimen_result_screen.dart';

class QimenUIFactory implements DivinationUIFactory {
  @override
  DivinationType get systemType => DivinationType.qiMen;

  @override
  Widget buildCastScreen(CastMethod method) {
    if (method != CastMethod.time && method != CastMethod.manual) {
      throw UnsupportedError('奇门遁甲不支持起局方式: ${method.id}');
    }
    return QimenCastScreen(initialMethod: method);
  }

  @override
  Widget buildResultScreen(DivinationResult result) {
    if (result is! QimenResult) {
      throw ArgumentError(
        '结果类型必须是 QimenResult，实际类型: ${result.runtimeType}',
      );
    }
    return QimenResultScreen(result: result);
  }

  @override
  Widget buildHistoryCard(DivinationResult result) {
    if (result is! QimenResult) {
      throw ArgumentError(
        '结果类型必须是 QimenResult，实际类型: ${result.runtimeType}',
      );
    }
    return HistoryRecordCard(
      result: result,
      methodLabel: switch (result.castMethod) {
        CastMethod.time => '时间起局',
        CastMethod.manual => '手动校盘',
        _ => result.castMethod.displayName,
      },
    );
  }

  @override
  IconData getSystemIcon() => Icons.grid_view_outlined;

  @override
  Color getSystemColor() => AppColors.qimenColor;
}
