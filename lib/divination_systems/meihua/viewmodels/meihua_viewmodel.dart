import '../../../domain/divination_system.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../viewmodels/divination_viewmodel.dart';
import '../meihua_system.dart';
import '../models/meihua_result.dart';

class MeiHuaViewModel extends DivinationViewModel<MeiHuaResult> {
  MeiHuaViewModel({
    required MeiHuaSystem system,
    required DivinationRepository repository,
  }) : super(system: system, repository: repository);

  MeiHuaResult? get meihuaResult => result;
  String? get benGuaName => result?.benGua.name;
  String? get bianGuaName => result?.bianGua.name;
  String? get huGuaName => result?.huGua.name;
  int? get movingLine => result?.movingLine;
  String? get movingLineLabel => result?.movingLineLabel;
  String? get wuXingRelation => result?.wuXingRelation;
  String? get tiGuaName => result?.tiGua.name;
  String? get yongGuaName => result?.yongGua.name;

  Future<void> castByTime({DateTime? castTime}) async {
    await cast(
      method: CastMethod.time,
      input: const {},
      castTime: castTime,
    );
  }

  Future<void> castByNumbers({
    required int upperNumber,
    required int lowerNumber,
    DateTime? castTime,
  }) async {
    await cast(
      method: CastMethod.number,
      input: {
        'upperNumber': upperNumber,
        'lowerNumber': lowerNumber,
      },
      castTime: castTime,
    );
  }

  Future<void> castByManual({
    required String upperTrigram,
    required String lowerTrigram,
    required int movingLine,
    DateTime? castTime,
  }) async {
    await cast(
      method: CastMethod.manual,
      input: {
        'upperTrigram': upperTrigram,
        'lowerTrigram': lowerTrigram,
        'movingLine': movingLine,
      },
      castTime: castTime,
    );
  }
}
