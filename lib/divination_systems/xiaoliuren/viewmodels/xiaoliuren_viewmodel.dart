import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../viewmodels/divination_viewmodel.dart';
import '../models/xiaoliuren_result.dart';
import '../xiaoliuren_system.dart';

class XiaoLiuRenViewModel extends DivinationViewModel<XiaoLiuRenResult> {
  XiaoLiuRenViewModel({
    required XiaoLiuRenSystem system,
    required DivinationRepository repository,
  }) : super(system: system, repository: repository);

  XiaoLiuRenResult? get xiaoliurenResult => result;
  XiaoLiuRenPalaceMode? get palaceMode => result?.palaceMode;
  XiaoLiuRenPosition? get finalPosition => result?.finalPosition;
  XiaoLiuRenPosition? get monthPosition => result?.monthPosition;
  XiaoLiuRenPosition? get dayPosition => result?.dayPosition;
  XiaoLiuRenPosition? get hourPosition => result?.hourPosition;

  Future<void> castByTime({
    required XiaoLiuRenPalaceMode palaceMode,
    DateTime? castTime,
  }) async {
    await cast(
      method: CastMethod.time,
      input: {'palaceMode': palaceMode.id},
      castTime: castTime,
    );
  }

  Future<void> castByReportNumbers({
    required int firstNumber,
    required int secondNumber,
    required int thirdNumber,
    required XiaoLiuRenPalaceMode palaceMode,
    DateTime? castTime,
  }) async {
    await cast(
      method: CastMethod.reportNumber,
      input: {
        'firstNumber': firstNumber,
        'secondNumber': secondNumber,
        'thirdNumber': thirdNumber,
        'palaceMode': palaceMode.id,
      },
      castTime: castTime,
    );
  }

  Future<void> castByCharacterStrokes({
    required int firstStroke,
    required int secondStroke,
    required int thirdStroke,
    required XiaoLiuRenPalaceMode palaceMode,
    DateTime? castTime,
  }) async {
    await cast(
      method: CastMethod.characterStroke,
      input: {
        'firstStroke': firstStroke,
        'secondStroke': secondStroke,
        'thirdStroke': thirdStroke,
        'palaceMode': palaceMode.id,
      },
      castTime: castTime,
    );
  }
}
