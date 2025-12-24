import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/services/shared/wuxing_service.dart';
import '../../../domain/services/shared/liuqin_service.dart';

part 'yao.freezed.dart';
part 'yao.g.dart';

/// 阴阳类型
enum YaoType {
  yin('阴'),
  yang('阳');

  const YaoType(this.name);
  final String name;
}

/// 爻的数字枚举
enum YaoNumber {
  @JsonValue(6)
  laoYin(6, '老阴', true, YaoType.yin),

  @JsonValue(7)
  shaoYang(7, '少阳', false, YaoType.yang),

  @JsonValue(8)
  shaoYin(8, '少阴', false, YaoType.yin),

  @JsonValue(9)
  laoYang(9, '老阳', true, YaoType.yang);

  const YaoNumber(this.value, this.name, this.isMoving, this.type);

  final int value;
  final String name;
  final bool isMoving;
  final YaoType type;
}

// WuXing 和 LiuQin 枚举已移动到共享服务层
// 请使用以下导入：
// import '../domain/services/shared/wuxing_service.dart';
// import '../domain/services/shared/liuqin_service.dart';

/// 爻模型
@freezed
class Yao with _$Yao {
  const factory Yao({
    required int position,
    required YaoNumber number,
    required String branch,
    required String stem,
    required LiuQin liuQin,
    required WuXing wuXing,
    required bool isSeYao,
    required bool isYingYao,
    String? liuShen,
  }) = _Yao;

  factory Yao.fromJson(Map<String, dynamic> json) => _$YaoFromJson(json);

  const Yao._();

  /// 是否为动爻
  bool get isMoving => number.isMoving;

  /// 是否为阴爻
  bool get isYin => number.type == YaoType.yin;

  /// 是否为阳爻
  bool get isYang => number.type == YaoType.yang;

  /// 变爻后的爻
  Yao toChangedYao() {
    if (!isMoving) return this;

    final newNumber = isYin ? YaoNumber.shaoYang : YaoNumber.shaoYin;
    return copyWith(number: newNumber);
  }
}
