import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../ai/config/ai_config_manager.dart';
import '../../ai/config/ai_provider_profile.dart';
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
  });

  final int recordCount;
  final int aiProfileCount;
  final int templateCount;
  final int preferenceCount;
  final BackupImportMode mode;
}

class DataManagementSummary {
  const DataManagementSummary({
    required this.totalRecords,
    required this.liuyaoCount,
    required this.daliurenCount,
    required this.meihuaCount,
    required this.xiaoliurenCount,
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
      ]);

      recordPayload.add({
        'systemType': record.systemType.id,
        'result': record.toJson(),
        'question': encrypted['question_${record.id}'],
        'detail': encrypted['detail_${record.id}'],
        'interpretation': encrypted['interpretation_${record.id}'],
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
    final recordsPayload = List<Map<String, dynamic>>.from(
      (recordsJson['records'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );

    final aiProfilesJson = _readJsonMap(archive, 'ai_profiles.json');
    final activeProfileId = aiProfilesJson['activeProfileId'] as String?;
    final profilesPayload = List<Map<String, dynamic>>.from(
      (aiProfilesJson['profiles'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );

    final templatesJson = _readJsonMap(archive, 'prompt_templates.json');
    final templatesPayload = List<Map<String, dynamic>>.from(
      (templatesJson['templates'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );

    final preferencesJson = _readJsonMap(archive, 'preferences.json');
    final preferencesPayload = Map<String, String>.from(
      (preferencesJson['preferences'] as Map? ?? const <String, dynamic>{})
          .map((key, value) => MapEntry(key.toString(), value.toString())),
    );

    if (mode == BackupImportMode.overwrite) {
      if (recordsPayload.isNotEmpty) {
        await clearAllHistory();
      }
      if (profilesPayload.isNotEmpty) {
        await clearAllAIProfiles();
      }
      if (templatesPayload.isNotEmpty) {
        await manager.restoreBuiltInTemplates();
      }
      if (preferencesPayload.isNotEmpty) {
        await manager.replaceExportablePreferences(
          const <String, String>{},
          clearExisting: true,
        );
      }
    }

    var importedRecords = 0;
    for (final item in recordsPayload) {
      final systemType = DivinationType.fromId(item['systemType'] as String);
      final resultJson = Map<String, dynamic>.from(item['result'] as Map);
      final system = _registry.getSystem(systemType);
      final result = system.resultFromJson(resultJson);
      if (await _repository.recordExists(result.id)) {
        await _repository.updateRecord(result);
      } else {
        await _repository.saveRecord(result);
      }

      await _restoreEncryptedField(
        key: 'question_${result.id}',
        value: item['question'] as String?,
      );
      await _restoreEncryptedField(
        key: 'detail_${result.id}',
        value: item['detail'] as String?,
      );
      await _restoreEncryptedField(
        key: 'interpretation_${result.id}',
        value: item['interpretation'] as String?,
      );
      importedRecords++;
    }

    var importedProfiles = 0;
    for (final item in profilesPayload) {
      final existingProfile = mode == BackupImportMode.merge
          ? await manager.getProviderProfile(item['id'] as String? ?? '')
          : null;
      final importedApiKey = item['apiKey'] as String?;
      final profile = AIProviderProfile.fromJson(
        item,
        apiKey: importedApiKey?.trim().isNotEmpty == true
            ? importedApiKey!
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
    for (final item in templatesPayload) {
      final template = tmpl.PromptTemplate.fromJson(item);
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
    );
  }

  AIConfigManager _requireAIConfigManager() {
    final manager = _aiConfigManager;
    if (manager == null) {
      throw StateError('AI 模块尚未初始化完成');
    }
    return manager;
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
