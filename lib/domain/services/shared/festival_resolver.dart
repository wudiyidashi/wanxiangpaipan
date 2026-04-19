import 'package:lunar/lunar.dart';

/// 节日名解析：合并 lunar 传统节日 + 公历节日名。
/// 不处理放假/调休，那需要逐年变化的年表，本期不做。
class FestivalResolver {
  FestivalResolver._();

  static List<String> resolve(DateTime date, Lunar lunar) {
    final solar = lunar.getSolar();
    final names = <String>{};

    // 农历传统节日
    names.addAll(lunar.getFestivals());
    // 其他传统节日
    names.addAll(lunar.getOtherFestivals());
    // 公历节日
    names.addAll(solar.getFestivals());
    names.addAll(solar.getOtherFestivals());

    return names.toList();
  }
}
