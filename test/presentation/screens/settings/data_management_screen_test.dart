import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/data_management_service.dart';
import 'package:wanxiang_paipan/presentation/screens/settings/data_management_screen.dart';
import 'package:wanxiang_paipan/presentation/screens/settings/data_management_viewmodel.dart';

class _FakeDataManagementActionsService
    implements DataManagementActionsService {
  _FakeDataManagementActionsService({
    required DataManagementSummary summary,
    BackupExportResult? exportResult,
    BackupImportPreview? importPreview,
    BackupImportResult? importResult,
  })  : _summary = summary,
        _exportResult = exportResult ??
            BackupExportResult(
              filePath: 'D:/tmp/mock-backup.zip',
              fileName: 'mock-backup.zip',
              recordCount: summary.totalRecords,
              aiProfileCount: summary.aiProfileCount,
              templateCount: summary.customTemplateCount,
              preferenceCount: 2,
              exportedAt: DateTime(2026, 4, 19, 9, 30),
            ),
        _importPreview = importPreview ??
            BackupImportPreview(
              formatVersion: 1,
              exportedAt: DateTime(2026, 4, 19, 9, 30),
              recordCount: 6,
              aiProfileCount: 2,
              templateCount: 3,
              preferenceCount: 4,
              includesApiKeys: false,
            ),
        _importResult = importResult ??
            const BackupImportResult(
              recordCount: 6,
              aiProfileCount: 2,
              templateCount: 3,
              preferenceCount: 4,
              mode: BackupImportMode.merge,
            );

  DataManagementSummary _summary;
  final BackupExportResult _exportResult;
  final BackupImportPreview _importPreview;
  final BackupImportResult _importResult;

  final List<DivinationType> clearedSystems = [];
  int exportCount = 0;
  int importCount = 0;
  int inspectCount = 0;

  @override
  final bool isAIModuleAvailable = true;

  @override
  Future<int> clearAllAIProfiles() async {
    final count = _summary.aiProfileCount;
    _summary = _replaceSummary(_summary, aiProfileCount: 0);
    return count;
  }

  @override
  Future<int> clearAllHistory() async {
    final count = _summary.totalRecords;
    _summary = _replaceSummary(
      _summary,
      totalRecords: 0,
      liuyaoCount: 0,
      daliurenCount: 0,
      meihuaCount: 0,
      xiaoliurenCount: 0,
    );
    return count;
  }

  @override
  Future<int> clearHistoryBefore(DateTime beforeTime) async {
    final removed = _summary.totalRecords > 2 ? 2 : _summary.totalRecords;
    _summary = _replaceSummary(
      _summary,
      totalRecords: _summary.totalRecords - removed,
    );
    return removed;
  }

  @override
  Future<int> clearHistoryBySystem(DivinationType systemType) async {
    clearedSystems.add(systemType);
    switch (systemType) {
      case DivinationType.liuYao:
        final removed = _summary.liuyaoCount;
        _summary = _replaceSummary(
          _summary,
          totalRecords: _summary.totalRecords - removed,
          liuyaoCount: 0,
        );
        return removed;
      case DivinationType.daLiuRen:
        final removed = _summary.daliurenCount;
        _summary = _replaceSummary(
          _summary,
          totalRecords: _summary.totalRecords - removed,
          daliurenCount: 0,
        );
        return removed;
      case DivinationType.meiHua:
        final removed = _summary.meihuaCount;
        _summary = _replaceSummary(
          _summary,
          totalRecords: _summary.totalRecords - removed,
          meihuaCount: 0,
        );
        return removed;
      case DivinationType.xiaoLiuRen:
        final removed = _summary.xiaoliurenCount;
        _summary = _replaceSummary(
          _summary,
          totalRecords: _summary.totalRecords - removed,
          xiaoliurenCount: 0,
        );
        return removed;
    }
  }

  @override
  Future<BackupExportResult> exportBackup() async {
    exportCount += 1;
    return _exportResult;
  }

  @override
  Future<BackupImportPreview> inspectBackup(File file) async {
    inspectCount += 1;
    return _importPreview;
  }

  @override
  Future<BackupImportResult> importBackup(
    File file, {
    required BackupImportMode mode,
  }) async {
    importCount += 1;
    _summary = _replaceSummary(
      _summary,
      totalRecords: _importResult.recordCount,
      aiProfileCount: _importResult.aiProfileCount,
      customTemplateCount: _importResult.templateCount,
    );
    return BackupImportResult(
      recordCount: _importResult.recordCount,
      aiProfileCount: _importResult.aiProfileCount,
      templateCount: _importResult.templateCount,
      preferenceCount: _importResult.preferenceCount,
      mode: mode,
    );
  }

  @override
  Future<DataManagementSummary> loadSummary() async => _summary;

  @override
  Future<int> restoreDefaultPromptTemplates() async {
    final count = _summary.customTemplateCount;
    _summary = _replaceSummary(_summary, customTemplateCount: 0);
    return count;
  }
}

void main() {
  group('DataManagementScreen', () {
    testWidgets('清理历史记录后应刷新概览并提示成功', (tester) async {
      final service = _FakeDataManagementActionsService(
        summary: _createSummary(
          totalRecords: 10,
          liuyaoCount: 2,
          daliurenCount: 3,
          meihuaCount: 4,
          xiaoliurenCount: 1,
          aiProfileCount: 2,
          customTemplateCount: 5,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DataManagementScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('历史记录 10 条'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('清理大六壬记录'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('当前 3 条'), findsOneWidget);

      await tester.tap(find.text('清理大六壬记录'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(service.clearedSystems, [DivinationType.daLiuRen]);
      await tester.drag(find.byType(ListView), const Offset(0, 1200));
      await tester.pumpAndSettle();
      expect(find.text('历史记录 7 条'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('清理大六壬记录'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('当前 0 条'), findsOneWidget);
    });

    testWidgets('导出与导入备份走注入回调和服务', (tester) async {
      final service = _FakeDataManagementActionsService(
        summary: _createSummary(
          totalRecords: 8,
          liuyaoCount: 2,
          daliurenCount: 2,
          meihuaCount: 2,
          xiaoliurenCount: 2,
          aiProfileCount: 1,
          customTemplateCount: 2,
        ),
      );
      var sharedFileName = '';

      await tester.pumpWidget(
        MaterialApp(
          home: DataManagementScreen(
            service: service,
            backupShareHandler: (result) async {
              sharedFileName = result.fileName;
            },
            backupFilePicker: (_) async => File('mock-import.zip'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('导出完整备份'));
      await tester.pumpAndSettle();

      expect(service.exportCount, 1);
      expect(sharedFileName, 'mock-backup.zip');
      expect(find.textContaining('备份已生成'), findsOneWidget);

      await tester.tap(find.text('导入备份'));
      await tester.pumpAndSettle();
      expect(find.textContaining('备份时间：2026-04-19 09:30'), findsOneWidget);
      expect(find.textContaining('历史 6 条'), findsOneWidget);

      await tester.tap(find.text(BackupImportMode.merge.displayName));
      await tester.pumpAndSettle();

      expect(service.inspectCount, 1);
      expect(service.importCount, 1);
      await tester.drag(find.byType(ListView), const Offset(0, 1200));
      await tester.pumpAndSettle();
      expect(find.text('历史记录 6 条'), findsOneWidget);
      expect(find.text('AI 配置 2 套'), findsOneWidget);
    });
  });
}

DataManagementSummary _createSummary({
  required int totalRecords,
  required int liuyaoCount,
  required int daliurenCount,
  required int meihuaCount,
  required int xiaoliurenCount,
  required int aiProfileCount,
  required int customTemplateCount,
}) {
  return DataManagementSummary(
    totalRecords: totalRecords,
    liuyaoCount: liuyaoCount,
    daliurenCount: daliurenCount,
    meihuaCount: meihuaCount,
    xiaoliurenCount: xiaoliurenCount,
    aiProfileCount: aiProfileCount,
    customTemplateCount: customTemplateCount,
    latestRecordTime: DateTime(2026, 4, 19, 9, 22),
    lastBackupAt: DateTime(2026, 4, 19, 8, 40),
  );
}

DataManagementSummary _replaceSummary(
  DataManagementSummary summary, {
  int? totalRecords,
  int? liuyaoCount,
  int? daliurenCount,
  int? meihuaCount,
  int? xiaoliurenCount,
  int? aiProfileCount,
  int? customTemplateCount,
}) {
  return DataManagementSummary(
    totalRecords: totalRecords ?? summary.totalRecords,
    liuyaoCount: liuyaoCount ?? summary.liuyaoCount,
    daliurenCount: daliurenCount ?? summary.daliurenCount,
    meihuaCount: meihuaCount ?? summary.meihuaCount,
    xiaoliurenCount: xiaoliurenCount ?? summary.xiaoliurenCount,
    aiProfileCount: aiProfileCount ?? summary.aiProfileCount,
    customTemplateCount: customTemplateCount ?? summary.customTemplateCount,
    latestRecordTime: summary.latestRecordTime,
    lastBackupAt: summary.lastBackupAt,
  );
}
