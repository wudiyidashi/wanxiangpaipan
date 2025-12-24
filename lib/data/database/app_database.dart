import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';
import 'daos/divination_record_dao.dart';
import 'daos/ai_config_dao.dart';

part 'app_database.g.dart';

/// 应用数据库（新架构）
///
/// 使用 DivinationRecords 表支持多术数系统。
@DriftDatabase(
  tables: [DivinationRecords, ProviderConfigs, PromptTemplates, UserPreferences],
  daos: [DivinationRecordDao, AIConfigDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          // 创建所有表
          await migrator.createAll();

          // 创建索引以优化查询性能
          await _createIndexes(migrator);
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(divinationRecords);
            await _createIndexes(migrator);
          }
          if (from < 3) {
            // 添加 AI 配置相关表
            await migrator.createTable(providerConfigs);
            await migrator.createTable(promptTemplates);
            await migrator.createTable(userPreferences);
            await _createAIIndexes(migrator);
          }
        },
      );

  Future<void> _createIndexes(Migrator migrator) async {
    await migrator.createIndex(
      Index(
        'idx_divination_cast_time',
        'CREATE INDEX IF NOT EXISTS idx_divination_cast_time '
            'ON divination_records (cast_time DESC)',
      ),
    );

    await migrator.createIndex(
      Index(
        'idx_divination_system_type',
        'CREATE INDEX IF NOT EXISTS idx_divination_system_type '
            'ON divination_records (system_type)',
      ),
    );
  }

  Future<void> _createAIIndexes(Migrator migrator) async {
    await migrator.createIndex(
      Index(
        'idx_prompt_templates_system_type',
        'CREATE INDEX IF NOT EXISTS idx_prompt_templates_system_type '
            'ON prompt_templates (system_type, template_type)',
      ),
    );

    await migrator.createIndex(
      Index(
        'idx_prompt_templates_active',
        'CREATE INDEX IF NOT EXISTS idx_prompt_templates_active '
            'ON prompt_templates (system_type, template_type, is_active)',
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wanxiang_paipan.db'));
    return NativeDatabase(file);
  });
}

