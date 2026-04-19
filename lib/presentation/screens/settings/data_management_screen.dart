import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/divination_system.dart';
import '../../../domain/services/data_management_service.dart';
import '../../widgets/antique/antique.dart';
import 'data_management_sections.dart';
import 'data_management_viewmodel.dart';

typedef BackupFilePicker = Future<File?> Function(BuildContext context);
typedef BackupShareHandler = Future<void> Function(BackupExportResult result);

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({
    super.key,
    DataManagementActionsService? service,
    BackupFilePicker? backupFilePicker,
    BackupShareHandler? backupShareHandler,
  })  : _service = service,
        _backupFilePicker = backupFilePicker,
        _backupShareHandler = backupShareHandler;

  final DataManagementActionsService? _service;
  final BackupFilePicker? _backupFilePicker;
  final BackupShareHandler? _backupShareHandler;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DataManagementViewModel>(
      create: (context) => DataManagementViewModel(
        service: _service ?? _buildService(context),
      )..initialize(),
      child: _DataManagementBody(
        backupFilePicker: _backupFilePicker ?? _defaultBackupFilePicker,
        backupShareHandler: _backupShareHandler ?? _defaultBackupShareHandler,
      ),
    );
  }

  DataManagementActionsService? _buildService(BuildContext context) {
    try {
      final service = context.read<DataManagementService>();
      return DefaultDataManagementActionsService(service);
    } catch (_) {
      return null;
    }
  }

  static Future<File?> _defaultBackupFilePicker(BuildContext context) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: '选择万象排盘备份文件',
    );
    final path =
        picked == null || picked.files.isEmpty ? null : picked.files.first.path;
    if (path == null || path.isEmpty) {
      return null;
    }
    return File(path);
  }

  static Future<void> _defaultBackupShareHandler(
    BackupExportResult result,
  ) async {
    await Share.shareXFiles(
      [XFile(result.filePath)],
      text:
          '万象排盘备份 ${result.fileName}\n历史 ${result.recordCount} 条，AI 配置 ${result.aiProfileCount} 套，模板 ${result.templateCount} 条。\n本次备份默认不包含 API Key。',
      subject: result.fileName,
    );
  }
}

class _DataManagementBody extends StatelessWidget {
  const _DataManagementBody({
    required this.backupFilePicker,
    required this.backupShareHandler,
  });

  final BackupFilePicker backupFilePicker;
  final BackupShareHandler backupShareHandler;

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManagementViewModel>(
      builder: (context, viewModel, _) {
        return AntiqueScaffold(
          appBar: AntiqueAppBar(
            title: '数据管理',
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: '刷新',
                  onPressed: viewModel.isLoading ? null : viewModel.loadSummary,
                  icon: const Icon(Icons.refresh, color: AppColors.guhe),
                ),
              ),
            ],
          ),
          body: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: viewModel.loadSummary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      if (!viewModel.serviceAvailable) ...[
                        const DataManagementUnavailableCard(),
                        const SizedBox(height: 16),
                      ],
                      if (viewModel.errorMessage != null) ...[
                        DataManagementMessageCard(
                          message: viewModel.errorMessage!,
                          color: AppColors.zhusha,
                        ),
                        const SizedBox(height: 16),
                      ],
                      DataManagementOverviewCard(summary: viewModel.summary),
                      const SizedBox(height: 16),
                      DataManagementBackupSection(
                        enabled: viewModel.serviceAvailable,
                        activeBusyKey: viewModel.busyKey,
                        onExport: () => _handleExportBackup(context, viewModel),
                        onImport: () => _handleImportBackup(context, viewModel),
                      ),
                      const SizedBox(height: 16),
                      DataManagementHistorySection(
                        summary: viewModel.summary,
                        activeBusyKey: viewModel.busyKey,
                        onClearLiuYao: () => _confirmAndRun(
                          context: context,
                          title: '清理六爻记录',
                          message: '将删除全部六爻历史记录，不影响其他术数、AI 配置和模板。',
                          isDanger: true,
                          action: () => viewModel.clearHistoryBySystem(
                            DivinationType.liuYao,
                          ),
                        ),
                        onClearDaLiuRen: () => _confirmAndRun(
                          context: context,
                          title: '清理大六壬记录',
                          message: '将删除全部大六壬历史记录，不影响其他术数、AI 配置和模板。',
                          isDanger: true,
                          action: () => viewModel.clearHistoryBySystem(
                            DivinationType.daLiuRen,
                          ),
                        ),
                        onClearMeiHua: () => _confirmAndRun(
                          context: context,
                          title: '清理梅花记录',
                          message: '将删除全部梅花易数历史记录，不影响其他术数、AI 配置和模板。',
                          isDanger: true,
                          action: () => viewModel.clearHistoryBySystem(
                            DivinationType.meiHua,
                          ),
                        ),
                        onClearXiaoLiuRen: () => _confirmAndRun(
                          context: context,
                          title: '清理小六壬记录',
                          message: '将删除全部小六壬历史记录，不影响其他术数、AI 配置和模板。',
                          isDanger: true,
                          action: () => viewModel.clearHistoryBySystem(
                            DivinationType.xiaoLiuRen,
                          ),
                        ),
                        onClearBefore30Days: () => _confirmAndRun(
                          context: context,
                          title: '清理 30 天前记录',
                          message: '将删除 30 天前的历史记录，不影响 AI 配置和提示词模板。',
                          isDanger: true,
                          action: () => viewModel.clearHistoryBefore(
                            DateTime.now().subtract(const Duration(days: 30)),
                          ),
                        ),
                        onClearAll: () => _confirmAndRun(
                          context: context,
                          title: '清空全部历史记录',
                          message:
                              '将删除全部排盘历史记录，但不会删除 AI 接口配置、API Key、提示词模板和其他偏好。',
                          isDanger: true,
                          action: viewModel.clearAllHistory,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DataManagementResetSection(
                        summary: viewModel.summary,
                        aiAvailable: viewModel.isAIModuleAvailable,
                        activeBusyKey: viewModel.busyKey,
                        onClearAIProfiles: () => _confirmAndRun(
                          context: context,
                          title: '清空 AI 接口配置',
                          message: '将删除所有已保存的 AI 接口配置和 API Key，不影响历史记录与提示词模板。',
                          isDanger: true,
                          action: viewModel.clearAllAIProfiles,
                        ),
                        onRestoreTemplates: () => _confirmAndRun(
                          context: context,
                          title: '恢复默认提示词',
                          message: '将删除自定义模板，并把内置模板内容恢复为默认版本，不影响历史记录与 AI 配置。',
                          isDanger: true,
                          action: viewModel.restoreDefaultPromptTemplates,
                        ),
                        onShowCacheNotice: () =>
                            _showMessage(context, '缓存清理将在下一阶段实现'),
                        onShowGlobalResetNotice: () => _showMessage(
                          context,
                          '全局重置暂未开放，待备份能力完成后再接入',
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<void> _handleExportBackup(
    BuildContext context,
    DataManagementViewModel viewModel,
  ) async {
    try {
      final result = await viewModel.exportBackup();
      await backupShareHandler(result);
      if (!context.mounted) {
        return;
      }
      _showMessage(
        context,
        '备份已生成，已调用系统分享。API Key 默认不会进入备份包。',
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, '操作失败: $e');
    }
  }

  Future<void> _handleImportBackup(
    BuildContext context,
    DataManagementViewModel viewModel,
  ) async {
    final file = await backupFilePicker(context);
    if (file == null) {
      return;
    }

    BackupImportPreview preview;
    try {
      preview = await viewModel.inspectBackup(file);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, '备份校验失败: $e');
      return;
    }
    if (!context.mounted) {
      return;
    }

    final mode = await showBackupImportModeDialog(context, preview);
    if (!context.mounted) {
      return;
    }
    if (mode == null) {
      return;
    }

    try {
      final result = await viewModel.importBackup(file, mode: mode);
      if (!context.mounted) {
        return;
      }
      _showMessage(
        context,
        '导入完成：历史 ${result.recordCount} 条，AI 配置 ${result.aiProfileCount} 套，模板 ${result.templateCount} 条，偏好 ${result.preferenceCount} 项。',
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, '操作失败: $e');
    }
  }

  Future<void> _confirmAndRun({
    required BuildContext context,
    required String title,
    required String message,
    required Future<String> Function() action,
    bool isDanger = false,
  }) async {
    final confirmed = await showAntiqueDialog<bool>(
          context: context,
          title: title,
          content: Text(message, style: AppTextStyles.antiqueBody),
          actions: [
            AntiqueButton(
              label: '取消',
              onPressed: () => Navigator.of(context).pop(false),
              variant: AntiqueButtonVariant.ghost,
            ),
            AntiqueButton(
              label: '确认',
              onPressed: () => Navigator.of(context).pop(true),
              variant: isDanger
                  ? AntiqueButtonVariant.danger
                  : AntiqueButtonVariant.primary,
            ),
          ],
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      final message = await action();
      if (!context.mounted) {
        return;
      }
      _showMessage(context, message);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, '操作失败: $e');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
