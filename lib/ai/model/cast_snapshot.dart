import 'package:freezed_annotation/freezed_annotation.dart';

part 'cast_snapshot.freezed.dart';
part 'cast_snapshot.g.dart';

/// 冻结初始分析时使用的 prompt 和模型，保证后续轮次上下文稳定。
@freezed
class CastSnapshot with _$CastSnapshot {
  const factory CastSnapshot({
    required String systemPrompt,
    required String castUserPrompt,
    required String model,
    required DateTime assembledAt,
  }) = _CastSnapshot;

  const CastSnapshot._();

  factory CastSnapshot.fromJson(Map<String, dynamic> json) =>
      _$CastSnapshotFromJson(json);
}
