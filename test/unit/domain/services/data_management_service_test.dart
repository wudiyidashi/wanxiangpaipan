import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/config/ai_config_manager.dart';
import 'package:wanxiang_paipan/ai/config/ai_provider_profile.dart';
import 'package:wanxiang_paipan/ai/template/prompt_template.dart' as tmpl;
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/repositories/divination_repository_impl.dart';
import 'package:wanxiang_paipan/data/secure/secure_storage.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/gua.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/yao.dart';
import 'package:wanxiang_paipan/domain/divination_registry.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/data_management_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/liuqin_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

class _MockSecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<bool> containsKey(String key) async => _storage.containsKey(key);

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<String?> read(String key) async => _storage[key];

  @override
  Future<Map<String, String>> readMultiple(List<String> keys) async {
    final result = <String, String>{};
    for (final key in keys) {
      final value = _storage[key];
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  @override
  Future<Map<String, String>> readAll() async => Map.unmodifiable(_storage);

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }
}

class _TestHarness {
  _TestHarness({
    required this.database,
    required this.secureStorage,
    required this.manager,
    required this.repository,
    required this.service,
  });

  final AppDatabase database;
  final _MockSecureStorage secureStorage;
  final AIConfigManager manager;
  final DivinationRepositoryImpl repository;
  final DataManagementService service;

  Future<void> dispose() => database.close();
}

void main() {
  group('DataManagementService', () {
    late DivinationRegistry registry;
    final disposers = <Future<void> Function()>[];

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      registry = DivinationRegistry();
      registry.clear();
      registry.register(LiuYaoSystem());
      disposers.clear();
    });

    tearDown(() async {
      for (final dispose in disposers.reversed) {
        await dispose();
      }
      registry.clear();
    });

    test('exportBackup 应打包历史、模板、偏好并排除 API Key', () async {
      final harness = await _createHarness(registry);
      disposers.add(harness.dispose);

      await _seedSourceData(harness);
      final templateCount = (await harness.manager.getAllTemplates()).length;
      final tempDir = await Directory.systemTemp.createTemp('wanxiang_export_');
      disposers.add(() => tempDir.delete(recursive: true));

      final result =
          await harness.service.exportBackup(outputDirectory: tempDir);
      final preview =
          await harness.service.inspectBackup(File(result.filePath));
      final archive = _decodeArchive(File(result.filePath));
      final manifest = _readArchiveJson(archive, 'manifest.json');
      final recordsJson = _readArchiveJson(archive, 'records.json');
      final profilesJson = _readArchiveJson(archive, 'ai_profiles.json');
      final preferencesJson = _readArchiveJson(archive, 'preferences.json');

      expect(File(result.filePath).existsSync(), isTrue);
      expect(result.recordCount, 1);
      expect(result.aiProfileCount, 1);
      expect(result.templateCount, templateCount);
      expect(preview.recordCount, 1);
      expect(preview.aiProfileCount, 1);
      expect(preview.templateCount, templateCount);
      expect(preview.includesApiKeys, isFalse);
      expect(manifest['app'], 'wanxiang_paipan');
      expect(manifest['includesApiKeys'], isFalse);

      final records = List<Map<String, dynamic>>.from(
        (recordsJson['records'] as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      expect(records.single['question'], '源备份问题');
      expect(records.single['detail'], '源备份详情');
      expect(records.single['interpretation'], '源备份解读');

      final profiles = List<Map<String, dynamic>>.from(
        (profilesJson['profiles'] as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      expect(profiles.single.containsKey('apiKey'), isFalse);

      final preferences = Map<String, dynamic>.from(
        preferencesJson['preferences'] as Map,
      );
      expect(preferences['theme_mode'], 'antique');
      expect(preferences.containsKey(AIConfigManager.keyLastBackupAt), isFalse);
    });

    test('merge 导入应保留已有同名配置的 API Key 并补齐备份数据', () async {
      final source = await _createHarness(registry);
      final target = await _createHarness(registry);
      disposers
        ..add(source.dispose)
        ..add(target.dispose);

      await _seedSourceData(source);
      await target.repository.saveRecord(
        _createMockLiuYaoResult(
          id: 'target-existing-record',
          castTime: DateTime(2026, 4, 19, 10, 0),
        ),
      );
      await target.manager.saveProviderProfile(
        _createProfile(
          id: 'profile_main',
          apiKey: 'existing-key',
          model: 'old-model',
        ),
      );
      await target.manager.setString('local_only_preference', 'keep');
      await target.manager.saveTemplate(
        _createCustomTemplate(
          id: 'target_custom_template',
          content: 'target only',
        ),
      );

      final tempDir = await Directory.systemTemp.createTemp('wanxiang_merge_');
      disposers.add(() => tempDir.delete(recursive: true));
      final export =
          await source.service.exportBackup(outputDirectory: tempDir);

      final result = await target.service.importBackup(
        File(export.filePath),
        mode: BackupImportMode.merge,
      );

      expect(result.recordCount, 1);
      expect(
        await target.repository.recordExists('target-existing-record'),
        isTrue,
      );
      expect(await target.repository.recordExists('source-record'), isTrue);
      expect(
        await target.repository.readEncryptedField('question_source-record'),
        '源备份问题',
      );

      final mergedProfile =
          await target.manager.getProviderProfile('profile_main');
      expect(mergedProfile, isNotNull);
      expect(mergedProfile!.apiKey, 'existing-key');
      expect(mergedProfile.model, 'deepseek-chat');
      expect(await target.manager.getString('theme_mode'), 'antique');
      expect(
        await target.manager.getString('local_only_preference'),
        'keep',
      );
      expect(
        await _hasTemplate(target.manager, 'source_custom_template'),
        isTrue,
      );
      expect(
        await _hasTemplate(target.manager, 'target_custom_template'),
        isTrue,
      );
    });

    test('overwrite 导入应清理旧范围并导入备份内容', () async {
      final source = await _createHarness(registry);
      final target = await _createHarness(registry);
      disposers
        ..add(source.dispose)
        ..add(target.dispose);

      await _seedSourceData(source);

      await target.repository.saveRecord(
        _createMockLiuYaoResult(
          id: 'stale-record',
          castTime: DateTime(2025, 1, 1),
        ),
      );
      await target.repository
          .saveEncryptedField('question_stale-record', '旧问题');
      await target.manager.saveProviderProfile(
        _createProfile(
          id: 'stale-profile',
          apiKey: 'stale-key',
          model: 'stale-model',
        ),
      );
      await target.manager.saveTemplate(
        _createCustomTemplate(
          id: 'stale_custom_template',
          content: 'stale template',
        ),
      );
      await target.manager.setString('stale_preference', 'remove-me');

      final tempDir =
          await Directory.systemTemp.createTemp('wanxiang_overwrite_');
      disposers.add(() => tempDir.delete(recursive: true));
      final export =
          await source.service.exportBackup(outputDirectory: tempDir);

      final result = await target.service.importBackup(
        File(export.filePath),
        mode: BackupImportMode.overwrite,
      );

      expect(result.recordCount, 1);
      expect(await target.repository.recordExists('stale-record'), isFalse);
      expect(
        await target.repository.readEncryptedField('question_stale-record'),
        isNull,
      );
      expect(await target.repository.recordExists('source-record'), isTrue);

      final importedProfile =
          await target.manager.getProviderProfile('profile_main');
      expect(importedProfile, isNotNull);
      expect(importedProfile!.apiKey, isEmpty);
      expect(
        await target.manager.getProviderProfile('stale-profile'),
        isNull,
      );

      expect(
        await _hasTemplate(target.manager, 'stale_custom_template'),
        isFalse,
      );
      expect(
        await _hasTemplate(target.manager, 'source_custom_template'),
        isTrue,
      );
      expect(await target.manager.getString('stale_preference'), isNull);
      expect(await target.manager.getString('theme_mode'), 'antique');
    });
  });
}

Future<_TestHarness> _createHarness(DivinationRegistry registry) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final secureStorage = _MockSecureStorage();
  final manager = AIConfigManager(
    database: database,
    secureStorage: secureStorage,
  );
  await manager.initializeBuiltInTemplates();

  final repository = DivinationRepositoryImpl(
    database: database,
    secureStorage: secureStorage,
    registry: registry,
  );

  final service = DataManagementService(
    repository: repository,
    aiConfigManager: manager,
    registry: registry,
  );

  return _TestHarness(
    database: database,
    secureStorage: secureStorage,
    manager: manager,
    repository: repository,
    service: service,
  );
}

Future<void> _seedSourceData(_TestHarness harness) async {
  await harness.repository.saveRecord(
    _createMockLiuYaoResult(
      id: 'source-record',
      castTime: DateTime(2026, 4, 19, 9, 22),
    ),
  );
  await harness.repository.saveEncryptedFieldsBatch({
    'question_source-record': '源备份问题',
    'detail_source-record': '源备份详情',
    'interpretation_source-record': '源备份解读',
  });

  final profile = _createProfile(
    id: 'profile_main',
    apiKey: 'source-secret-key',
    model: 'deepseek-chat',
  );
  await harness.manager.saveProviderProfile(profile);
  await harness.manager.setActiveProviderProfileId(profile.id);
  await harness.manager.setDefaultProviderId(profile.providerId);

  await harness.manager.saveTemplate(
    _createCustomTemplate(
      id: 'source_custom_template',
      content: 'source custom template',
    ),
  );
  await harness.manager.setString('theme_mode', 'antique');
}

AIProviderProfile _createProfile({
  required String id,
  required String apiKey,
  required String model,
}) {
  return AIProviderProfile(
    id: id,
    providerId: 'openai_compatible',
    name: '主配置',
    apiKey: apiKey,
    baseUrl: 'https://api.deepseek.com/v1',
    model: model,
    createdAt: DateTime(2026, 4, 19, 9, 0),
    updatedAt: DateTime(2026, 4, 19, 9, 0),
  );
}

tmpl.PromptTemplate _createCustomTemplate({
  required String id,
  required String content,
}) {
  return tmpl.PromptTemplate(
    id: id,
    name: '自定义模板',
    description: 'for backup test',
    systemType: DivinationType.liuYao.id,
    templateType: tmpl.PromptTemplateType.analysis.id,
    content: content,
    variablesJson: '{}',
    isBuiltIn: false,
    isActive: true,
    createdAt: DateTime(2026, 4, 19, 9, 0),
    updatedAt: DateTime(2026, 4, 19, 9, 0),
  );
}

Archive _decodeArchive(File file) {
  final bytes = file.readAsBytesSync();
  return ZipDecoder().decodeBytes(bytes);
}

Map<String, dynamic> _readArchiveJson(Archive archive, String name) {
  final file = archive.files.firstWhere((item) => item.name == name);
  final content = utf8.decode(file.content as List<int>);
  return Map<String, dynamic>.from(jsonDecode(content) as Map);
}

Future<bool> _hasTemplate(AIConfigManager manager, String templateId) async {
  final templates = await manager.getAllTemplates();
  return templates.any((item) => item.id == templateId);
}

LiuYaoResult _createMockLiuYaoResult({
  required String id,
  required DateTime castTime,
}) {
  return LiuYaoResult(
    id: id,
    castTime: castTime,
    castMethod: CastMethod.coin,
    mainGua: _createMockGua(),
    changingGua: null,
    lunarInfo: const LunarInfo(
      yueJian: '寅',
      riGan: '甲',
      riZhi: '子',
      riGanZhi: '甲子',
      kongWang: ['戌', '亥'],
      yearGanZhi: '甲子',
      monthGanZhi: '丙寅',
    ),
    liuShen: ['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武'],
  );
}

Gua _createMockGua() {
  final yaos = List.generate(
    6,
    (index) => Yao(
      position: index + 1,
      number: YaoNumber.shaoYang,
      branch: '子',
      stem: '甲',
      liuQin: LiuQin.fuMu,
      wuXing: WuXing.shui,
      isSeYao: index == 4,
      isYingYao: index == 1,
    ),
  );

  return Gua(
    id: 'mock-gua-id',
    yaos: yaos,
    name: '天雷无妄',
    baGong: BaGong.qian,
    seYaoPosition: 5,
    yingYaoPosition: 2,
  );
}
