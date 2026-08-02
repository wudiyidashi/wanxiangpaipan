import '../../ai/model/cast_snapshot.dart';
import '../../domain/divination_system.dart';

/// Formats the immutable version metadata of one persisted AI conversation.
String? aiSnapshotVersionText({
  required DivinationType systemType,
  required CastSnapshot? snapshot,
}) {
  if (systemType != DivinationType.liuYao) return null;
  if (snapshot == null ||
      _isLegacy(snapshot.ruleSetVersion) ||
      _isLegacy(snapshot.projectionSchemaVersion) ||
      _isLegacy(snapshot.promptPolicyVersion)) {
    return '旧版冻结提示词';
  }
  return '冻结提示词 · 分析 ${snapshot.ruleSetVersion} · '
      '投影 ${snapshot.projectionSchemaVersion} · '
      '提示策略 ${_shortVersion(snapshot.promptPolicyVersion)}';
}

bool _isLegacy(String value) =>
    value.trim().isEmpty || value == 'legacyUnknown';

String _shortVersion(String value) {
  final separator = value.lastIndexOf('/');
  return separator == -1 ? value : value.substring(separator + 1);
}
