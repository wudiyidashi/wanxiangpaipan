import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../ai/config/ai_config_manager.dart';
import '../../ai/config/ai_provider_profile.dart';
import '../../ai/model/ai_conversation.dart';
import '../../ai/service/ai_analysis_service.dart';
import '../../ai/template/prompt_template.dart' as tmpl;
import '../divination_system.dart';
import '../divination_registry.dart';
import '../repositories/divination_repository.dart';

enum BackupImportMode {
  merge('合并导入'),
  overwrite('覆盖导入');

  const BackupImportMode(this.displayName);
  final String displayName;
}

class BackupExportResult {
  const BackupExportResult({
    required this.filePath,
    required this.fileName,
    required this.recordCount,
    required this.aiProfileCount,
    required this.templateCount,
    required this.preferenceCount,
    required this.exportedAt,
  });

  final String filePath;
  final String fileName;
  final int recordCount;
  final int aiProfileCount;
  final int templateCount;
  final int preferenceCount;
  final DateTime exportedAt;
}

class BackupImportPreview {
  const BackupImportPreview({
    required this.formatVersion,
    required this.exportedAt,
    required this.recordCount,
    required this.aiProfileCount,
    required this.templateCount,
    required this.preferenceCount,
    required this.includesApiKeys,
  });

  final int formatVersion;
  final DateTime exportedAt;
  final int recordCount;
  final int aiProfileCount;
  final int templateCount;
  final int preferenceCount;
  final bool includesApiKeys;
}

class BackupImportResult {
  const BackupImportResult({
    required this.recordCount,
    required this.aiProfileCount,
    required this.templateCount,
    required this.preferenceCount,
    required this.mode,
    this.skippedRecords = const [],
  });

  final int recordCount;
  final int aiProfileCount;
  final int templateCount;
  final int preferenceCount;
  final BackupImportMode mode;
  final List<BackupSkippedRecord> skippedRecords;

  int get skippedRecordCount => skippedRecords.length;
}

class BackupSkippedRecord {
  const BackupSkippedRecord({
    required this.identifier,
    required this.reason,
  });

  final String identifier;
  final String reason;
}

class DataManagementSummary {
  const DataManagementSummary({
    required this.totalRecords,
    required this.liuyaoCount,
    required this.daliurenCount,
    required this.meihuaCount,
    required this.xiaoliurenCount,
    required this.qimenCount,
    required this.aiProfileCount,
    required this.customTemplateCount,
    this.latestRecordTime,
    this.lastBackupAt,
  });

  final int totalRecords;
  final int liuyaoCount;
  final int daliurenCount;
  final int meihuaCount;
  final int xiaoliurenCount;
  final int qimenCount;
  final int aiProfileCount;
  final int customTemplateCount;
  final DateTime? latestRecordTime;
  final DateTime? lastBackupAt;
}

class DataManagementService {
  DataManagementService({
    required DivinationRepository repository,
    AIConfigManager? aiConfigManager,
    AIAnalysisService? aiAnalysisService,
    DivinationRegistry? registry,
  })  : _repository = repository,
        _aiConfigManager = aiConfigManager,
        _aiAnalysisService = aiAnalysisService,
        _registry = registry ?? DivinationRegistry();

  final DivinationRepository _repository;
  final AIConfigManager? _aiConfigManager;
  final AIAnalysisService? _aiAnalysisService;
  final DivinationRegistry _registry;

  static const _backupFormatVersion = 1;
  static const _backupAppId = 'wanxiang_paipan';

  bool get isAIModuleAvailable => _aiConfigManager != null;

  Future<DataManagementSummary> loadSummary() async {
    final totalRecords = await _repository.getRecordCount();
    final liuyaoCount =
        await _repository.getRecordCountBySystemType(DivinationType.liuYao);
    final daliurenCount =
        await _repository.getRecordCountBySystemType(DivinationType.daLiuRen);
    final meihuaCount =
        await _repository.getRecordCountBySystemType(DivinationType.meiHua);
    final xiaoliurenCount =
        await _repository.getRecordCountBySystemType(DivinationType.xiaoLiuRen);
    final qimenCount =
        await _repository.getRecordCountBySystemType(DivinationType.qiMen);
    final latestRecord = await _repository.getLatestRecord();

    final aiProfileCount = isAIModuleAvailable
        ? await _aiConfigManager!.getProviderProfileCount()
        : 0;
    final customTemplateCount = isAIModuleAvailable
        ? await _aiConfigManager!.getCustomTemplateCount()
        : 0;
    final lastBackupAt =
        isAIModuleAvailable ? await _aiConfigManager!.getLastBackupAt() : null;

    return DataManagementSummary(
      totalRecords: totalRecords,
      liuyaoCount: liuyaoCount,
      daliurenCount: daliurenCount,
      meihuaCount: meihuaCount,
      xiaoliurenCount: xiaoliurenCount,
      qimenCount: qimenCount,
      aiProfileCount: aiProfileCount,
      customTemplateCount: customTemplateCount,
      latestRecordTime: latestRecord?.castTime,
      lastBackupAt: lastBackupAt,
    );
  }

  Future<int> clearHistoryBySystem(DivinationType systemType) {
    return _repository.deleteRecordsBySystemType(systemType);
  }

  Future<int> clearHistoryBefore(DateTime beforeTime) {
    return _repository.deleteRecordsBeforeTime(beforeTime);
  }

  Future<int> clearAllHistory() {
    return _repository.deleteAllRecords();
  }

  Future<int> clearAllAIProfiles() async {
    final aiAnalysisService = _aiAnalysisService;
    if (aiAnalysisService != null) {
      return aiAnalysisService.clearAllProviderProfiles();
    }
    final manager = _requireAIConfigManager();
    final count = await manager.getProviderProfileCount();
    await manager.clearAllProviderProfiles();
    return count;
  }

  Future<int> restoreDefaultPromptTemplates() {
    return _requireAIConfigManager().restoreBuiltInTemplates();
  }

  Future<BackupExportResult> exportBackup({
    Directory? outputDirectory,
  }) async {
    final exportedAt = DateTime.now();
    final manager = _requireAIConfigManager();

    final records = await _repository.getAllRecords();
    final profiles = await manager.getProviderProfiles();
    final templates = await manager.getAllTemplates();
    final preferences = await manager.getExportablePreferences();
    final activeProfileId = await manager.getActiveProviderProfileId();

    final recordPayload = <Map<String, dynamic>>[];
    for (final record in records) {
      final encrypted = await _repository.readEncryptedFieldsBatch([
        'question_${record.id}',
        'detail_${record.id}',
        'interpretation_${record.id}',
        'conversation_${record.id}',
      ]);

      recordPayload.add({
        'systemType': record.systemType.id,
        'result': record.toJson(),
        'question': encrypted['question_${record.id}'],
        'detail': encrypted['detail_${record.id}'],
        'interpretation': encrypted['interpretation_${record.id}'],
        'conversation': encrypted['conversation_${record.id}'],
      });
    }

    final archive = Archive();
    final manifest = {
      'app': _backupAppId,
      'formatVersion': _backupFormatVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'includesApiKeys': false,
      'counts': {
        'records': recordPayload.length,
        'aiProfiles': profiles.length,
        'promptTemplates': templates.length,
        'preferences': preferences.length,
      },
    };

    _addJsonFile(archive, 'manifest.json', manifest);
    _addJsonFile(archive, 'records.json', {'records': recordPayload});
    _addJsonFile(archive, 'ai_profiles.json', {
      'activeProfileId': activeProfileId,
      'profiles': profiles.map((item) => item.toJson()).toList(),
    });
    _addJsonFile(archive, 'prompt_templates.json', {
      'templates': templates.map((item) => item.toJson()).toList(),
    });
    _addJsonFile(archive, 'preferences.json', {
      'preferences': preferences,
    });

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw StateError('备份打包失败');
    }

    final directory = outputDirectory ?? await getTemporaryDirectory();
    final fileName = 'wanxiang_backup_${_formatFileTimestamp(exportedAt)}.zip';
    final file = File(p.join(directory.path, fileName));
    await file.writeAsBytes(zipBytes, flush: true);
    await manager.setLastBackupAt(exportedAt);

    return BackupExportResult(
      filePath: file.path,
      fileName: fileName,
      recordCount: recordPayload.length,
      aiProfileCount: profiles.length,
      templateCount: templates.length,
      preferenceCount: preferences.length,
      exportedAt: exportedAt,
    );
  }

  Future<BackupImportPreview> inspectBackup(File file) async {
    final archive = await _decodeArchive(file);
    final manifest = _readJsonMap(archive, 'manifest.json');
    final appId = manifest['app'] as String? ?? '';
    if (appId != _backupAppId) {
      throw StateError('不是万象排盘备份文件');
    }
    final formatVersion = manifest['formatVersion'] as int? ?? 0;
    if (formatVersion != _backupFormatVersion) {
      throw StateError('不支持的备份格式版本: $formatVersion');
    }

    final counts = Map<String, dynamic>.from(
      manifest['counts'] as Map? ?? const <String, dynamic>{},
    );

    return BackupImportPreview(
      formatVersion: formatVersion,
      exportedAt: DateTime.tryParse(manifest['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      recordCount: counts['records'] as int? ?? 0,
      aiProfileCount: counts['aiProfiles'] as int? ?? 0,
      templateCount: counts['promptTemplates'] as int? ?? 0,
      preferenceCount: counts['preferences'] as int? ?? 0,
      includesApiKeys: manifest['includesApiKeys'] as bool? ?? false,
    );
  }

  Future<BackupImportResult> importBackup(
    File file, {
    required BackupImportMode mode,
  }) async {
    final manager = _requireAIConfigManager();
    final archive = await _decodeArchive(file);
    await inspectBackup(file);

    final recordsJson = _readJsonMap(archive, 'records.json');
    final recordsPayload = _readJsonList(
      recordsJson,
      key: 'records',
      fileName: 'records.json',
    );

    final aiProfilesJson = _readJsonMap(archive, 'ai_profiles.json');
    final activeProfileId = _readOptionalString(
      aiProfilesJson,
      key: 'activeProfileId',
      fileName: 'ai_profiles.json',
    );
    final profilesPayload = _readJsonList(
      aiProfilesJson,
      key: 'profiles',
      fileName: 'ai_profiles.json',
    );

    final templatesJson = _readJsonMap(archive, 'prompt_templates.json');
    final templatesPayload = _readJsonList(
      templatesJson,
      key: 'templates',
      fileName: 'prompt_templates.json',
    );

    final preferencesJson = _readJsonMap(archive, 'preferences.json');
    final preferencesPayload = _preflightPreferences(
      preferencesJson['preferences'],
    );

    final preflightRecords = <_PreflightRecordPayload>[];
    final skippedRecords = <BackupSkippedRecord>[];
    for (var index = 0; index < recordsPayload.length; index++) {
      final item = recordsPayload[index];
      final identifier = _recordIdentifier(item, index);
      try {
        if (item is! Map) {
          throw const FormatException('记录条目不是 JSON 对象');
        }
        preflightRecords.add(
          _preflightRecord(Map<String, dynamic>.from(item)),
        );
      } catch (error) {
        skippedRecords.add(
          BackupSkippedRecord(
            identifier: identifier,
            reason: _describeImportError(error),
          ),
        );
      }
    }

    // Profiles and templates are all-or-nothing sections. Decode the entire
    // archive before overwrite clears any existing data.
    final preflightProfiles = <AIProviderProfile>[];
    for (var index = 0; index < profilesPayload.length; index++) {
      preflightProfiles.add(
        _preflightProfile(profilesPayload[index], index),
      );
    }
    final preflightTemplates = <tmpl.PromptTemplate>[];
    for (var index = 0; index < templatesPayload.length; index++) {
      preflightTemplates.add(
        _preflightTemplate(templatesPayload[index], index),
      );
    }
    if (activeProfileId != null &&
        activeProfileId.isNotEmpty &&
        !preflightProfiles.any((profile) => profile.id == activeProfileId)) {
      throw const FormatException('ai_profiles.json 的激活配置不在 profiles 中');
    }

    if (mode == BackupImportMode.overwrite) {
      await clearAllHistory();
      await clearAllAIProfiles();
      await manager.restoreBuiltInTemplates();
      await manager.replaceExportablePreferences(
        const <String, String>{},
        clearExisting: true,
      );
    }

    var importedRecords = 0;
    for (final item in preflightRecords) {
      final result = item.result;
      if (await _repository.recordExists(result.id)) {
        await _repository.updateRecord(result);
      } else {
        await _repository.saveRecord(result);
      }

      await _restoreEncryptedField(
        key: 'question_${result.id}',
        value: item.question,
      );
      await _restoreEncryptedField(
        key: 'detail_${result.id}',
        value: item.detail,
      );
      await _restoreEncryptedField(
        key: 'interpretation_${result.id}',
        value: item.interpretation,
      );
      await _restoreConversation(
        resultId: result.id,
        value: item.conversation,
      );
      importedRecords++;
    }

    var importedProfiles = 0;
    for (final decodedProfile in preflightProfiles) {
      final existingProfile = mode == BackupImportMode.merge
          ? await manager.getProviderProfile(decodedProfile.id)
          : null;
      final profile = decodedProfile.copyWith(
        apiKey: decodedProfile.apiKey.trim().isNotEmpty
            ? decodedProfile.apiKey
            : (existingProfile?.apiKey ?? ''),
      );
      await manager.saveProviderProfile(profile);
      importedProfiles++;
    }
    if (activeProfileId != null && activeProfileId.isNotEmpty) {
      await manager.setActiveProviderProfileId(activeProfileId);
    }
    final aiAnalysisService = _aiAnalysisService;
    if (aiAnalysisService != null) {
      await aiAnalysisService.syncActiveProviderProfile();
    }

    var importedTemplates = 0;
    for (final template in preflightTemplates) {
      await manager.saveTemplate(template);
      importedTemplates++;
    }

    if (preferencesPayload.isNotEmpty) {
      await manager.replaceExportablePreferences(
        preferencesPayload,
        clearExisting: false,
      );
    }

    return BackupImportResult(
      recordCount: importedRecords,
      aiProfileCount: importedProfiles,
      templateCount: importedTemplates,
      preferenceCount: preferencesPayload.length,
      mode: mode,
      skippedRecords: List.unmodifiable(skippedRecords),
    );
  }

  AIConfigManager _requireAIConfigManager() {
    final manager = _aiConfigManager;
    if (manager == null) {
      throw StateError('AI 模块尚未初始化完成');
    }
    return manager;
  }

  _PreflightRecordPayload _preflightRecord(Map<String, dynamic> item) {
    final rawSystemType = item['systemType'];
    if (rawSystemType is! String) {
      throw const FormatException('备份记录缺少合法 systemType');
    }
    final systemType = DivinationType.fromId(rawSystemType);
    final system = _registry.tryGetSystem(systemType);
    if (system == null) {
      throw StateError('备份记录对应术数系统未注册: $rawSystemType');
    }
    final rawResult = item['result'];
    if (rawResult is! Map) {
      throw const FormatException('备份记录 result 格式错误');
    }
    final result = system.resultFromJson(
      Map<String, dynamic>.from(rawResult),
    );
    if (result.systemType != systemType) {
      throw const FormatException('备份记录内外 systemType 不一致');
    }

    String? optionalString(String key) {
      final value = item[key];
      if (value == null) return null;
      if (value is! String) {
        throw FormatException('备份记录 $key 格式错误');
      }
      return value;
    }

    return _PreflightRecordPayload(
      result: result,
      question: optionalString('question'),
      detail: optionalString('detail'),
      interpretation: optionalString('interpretation'),
      conversation: _preflightConversation(
        optionalString('conversation'),
        result: result,
      ),
    );
  }

  AIProviderProfile _preflightProfile(Object? item, int index) {
    if (item is! Map) {
      throw FormatException('ai_profiles.json profiles[$index] 格式错误');
    }
    final json = Map<String, dynamic>.from(item);
    final apiKey = json['apiKey'];
    if (apiKey != null && apiKey is! String) {
      throw FormatException('ai_profiles.json profiles[$index].apiKey 格式错误');
    }
    final profile = AIProviderProfile.fromJson(
      json,
      apiKey: apiKey as String? ?? '',
    );
    if (profile.id.trim().isEmpty) {
      throw FormatException('ai_profiles.json profiles[$index].id 不能为空');
    }
    return profile;
  }

  tmpl.PromptTemplate _preflightTemplate(Object? item, int index) {
    if (item is! Map) {
      throw FormatException(
        'prompt_templates.json templates[$index] 格式错误',
      );
    }
    final template = tmpl.PromptTemplate.fromJson(
      Map<String, dynamic>.from(item),
    );
    if (template.id.trim().isEmpty) {
      throw FormatException(
        'prompt_templates.json templates[$index].id 不能为空',
      );
    }
    return template;
  }

  Map<String, String> _preflightPreferences(Object? payload) {
    if (payload is! Map) {
      throw const FormatException('preferences.json preferences 格式错误');
    }
    final preferences = <String, String>{};
    for (final entry in payload.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw const FormatException('preferences.json preferences 必须为字符串键值');
      }
      final key = entry.key as String;
      if (AIConfigManager.internalPreferenceKeys.contains(key)) {
        throw FormatException('preferences.json 包含内部偏好键: $key');
      }
      preferences[key] = entry.value as String;
    }
    return preferences;
  }

  String? _preflightConversation(
    String? raw, {
    required DivinationResult result,
  }) {
    if (raw == null) {
      return null;
    }
    if (raw.trim().isEmpty) {
      throw const FormatException('备份记录 conversation 格式错误');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('备份记录 conversation 格式错误');
    }
    final conversation = AIConversation.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    if (conversation.resultId != result.id) {
      throw const FormatException('备份记录 conversation 的 resultId 不一致');
    }
    if (conversation.systemType != result.systemType) {
      throw const FormatException('备份记录 conversation 的 systemType 不一致');
    }
    return raw;
  }

  List<Object?> _readJsonList(
    Map<String, dynamic> json, {
    required String key,
    required String fileName,
  }) {
    final value = json[key];
    if (value is! List) {
      throw FormatException('$fileName 的 $key 格式错误');
    }
    return List<Object?>.from(value);
  }

  String? _readOptionalString(
    Map<String, dynamic> json, {
    required String key,
    required String fileName,
  }) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('$fileName 的 $key 格式错误');
    }
    return value;
  }

  String _recordIdentifier(Object? item, int index) {
    if (item is Map) {
      final result = item['result'];
      if (result is Map) {
        final id = result['id'];
        if (id is String && id.trim().isNotEmpty) {
          return id;
        }
      }
      final id = item['id'];
      if (id is String && id.trim().isNotEmpty) {
        return id;
      }
    }
    return 'records[$index]';
  }

  String _describeImportError(Object error) {
    if (error is FormatException) {
      return error.message.toString();
    }
    if (error is ArgumentError) {
      return error.message?.toString() ?? error.toString();
    }
    return error.toString();
  }

  void _addJsonFile(Archive archive, String name, Object data) {
    final jsonText = const JsonEncoder.withIndent('  ').convert(data);
    final bytes = utf8.encode(jsonText);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  Future<Archive> _decodeArchive(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    return archive;
  }

  Map<String, dynamic> _readJsonMap(Archive archive, String name) {
    final file = archive.files.where((item) => item.name == name).firstOrNull;
    if (file == null) {
      throw StateError('备份文件缺少 $name');
    }

    final content = utf8.decode(file.content as List<int>);
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw StateError('$name 格式错误');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> _restoreEncryptedField({
    required String key,
    required String? value,
  }) async {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      await _repository.deleteEncryptedField(key);
      return;
    }
    await _repository.saveEncryptedField(key, normalized);
  }

  Future<void> _restoreConversation({
    required String resultId,
    required String? value,
  }) async {
    final key = 'conversation_$resultId';
    if (value == null) {
      await _repository.deleteEncryptedField(key);
      return;
    }
    await _repository.saveEncryptedField(key, value);
  }

  String _formatFileTimestamp(DateTime time) {
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$year$month${day}_$hour$minute$second';
  }
}

class _PreflightRecordPayload {
  const _PreflightRecordPayload({
    required this.result,
    required this.question,
    required this.detail,
    required this.interpretation,
    required this.conversation,
  });

  final DivinationResult result;
  final String? question;
  final String? detail;
  final String? interpretation;
  final String? conversation;
}
