import 'package:freezed_annotation/freezed_annotation.dart';
import 'yao.dart';

part 'gua.freezed.dart';
part 'gua.g.dart';

/// 八宫
enum BaGong {
  qian('乾宫'),
  kun('坤宫'),
  zhen('震宫'),
  xun('巽宫'),
  kan('坎宫'),
  li('离宫'),
  gen('艮宫'),
  dui('兑宫');

  const BaGong(this.name);
  final String name;
}

/// 卦的特殊类型
enum GuaSpecialType {
  liuChong('六冲'),
  liuHe('六合'),
  youHun('游魂'),
  guiHun('归魂'),
  none('');

  const GuaSpecialType(this.name);
  final String name;
}

/// 卦模型
@freezed
class Gua with _$Gua {
  const factory Gua({
    required String id,
    required String name,
    required List<Yao> yaos,
    required BaGong baGong,
    required int seYaoPosition,
    required int yingYaoPosition,
    @Default(GuaSpecialType.none) GuaSpecialType specialType,
  }) = _Gua;

  factory Gua.fromJson(Map<String, dynamic> json) => _$GuaFromJson(json);

  const Gua._();

  /// 是否有动爻
  bool get hasMovingYao => yaos.any((yao) => yao.isMoving);

  /// 获取所有动爻
  List<Yao> get movingYaos => yaos.where((yao) => yao.isMoving).toList();

  /// 获取世爻
  Yao get seYao => yaos[seYaoPosition - 1];

  /// 获取应爻
  Yao get yingYao => yaos[yingYaoPosition - 1];
}
