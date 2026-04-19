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
                        _buildUnavailableCard(),
                        const SizedBox(height: 16),
                      ],
                      if (viewModel.errorMessage != null) ...[
                        _buildMessageCard(
                          viewModel.errorMessage!,
                          color: AppColors.zhusha,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildOverviewCard(viewModel.summary),
                      const SizedBox(height: 16),
                      _buildBackupSection(context, viewModel),
                      const SizedBox(height: 16),
                      _buildHistorySection(context, viewModel),
                      const SizedBox(height: 16),
                      _buildResetSection(context, viewModel),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildUnavailableCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Text(
        '数据服务尚未初始化完成，当前页面暂不可操作。',
        style: AppTextStyles.antiqueBody.copyWith(color: AppColors.guhe),
      ),
    );
  }

  Widget _buildMessageCard(String message, {required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        message,
        style: AppTextStyles.antiqueBody.copyWith(color: color),
      ),
    );
  }

  Widget _buildOverviewCard(DataManagementSummary? summary) {
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('存储概览', style: AppTextStyles.antiqueSection),
          const SizedBox(height: 6),
          Text(
            '先看清当前有哪些本地数据，再决定备份、清理或重置。',
            style: AppTextStyles.antiqueLabel,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricTag('历史记录 ${summary.totalRecords} 条'),
              _buildMetricTag('AI 配置 ${summary.aiProfileCount} 套'),
              _buildMetricTag('自定义模板 ${summary.customTemplateCount} 条'),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('六爻', '${summary.liuyaoCount} 条'),
          _buildInfoRow('大六壬', '${summary.daliurenCount} 条'),
          _buildInfoRow('梅花易数', '${summary.meihuaCount} 条'),
          _buildInfoRow('小六壬', '${summary.xiaoliurenCount} 条'),
          _buildInfoRow(
            '最近记录',
            summary.latestRecordTime != null
                ? _formatDateTime(summary.latestRecordTime!)
                : '暂无',
          ),
          _buildInfoRow(
            '上次备份',
            summary.lastBackupAt != null
                ? _formatDateTime(summary.lastBackupAt!)
                : '尚未备份',
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection(
    BuildContext context,
    DataManagementViewModel viewModel,
  ) {
    return _buildSectionCard(
      title: '备份与迁移',
      description: '导出和导入完整备份。当前默认不包含 API Key，导入后如有需要请重新填写。',
      children: [
        _buildActionTile(
          title: '导出完整备份',
          subtitle: '将历史、AI 配置元信息、提示词模板和偏好设置打包导出',
          icon: Icons.upload_file,
          busyKey: 'export_backup',
          activeBusyKey: viewModel.busyKey,
          onTap: viewModel.serviceAvailable
              ? () => _handleExportBackup(context, viewModel)
              : null,
        ),
        _buildActionTile(
          title: '导入备份',
          subtitle: '支持合并导入或覆盖导入，导入前会先预览并校验备份包',
          icon: Icons.download,
          busyKey: 'import_backup',
          activeBusyKey: viewModel.busyKey,
          onTap: viewModel.serviceAvailable
              ? () => _handleImportBackup(context, viewModel)
              : null,
        ),
      ],
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    DataManagementViewModel viewModel,
  ) {
    final summary = viewModel.summary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return _buildSectionCard(
      title: '历史记录管理',
      description: '历史清理仅影响排盘记录，不应触碰 AI Key、模板和其他偏好。',
      children: [
        _buildActionTile(
          title: '清理六爻记录',
          subtitle: '当前 ${summary.liuyaoCount} 条',
          icon: Icons.auto_stories_outlined,
          busyKey: 'clear_${DivinationType.liuYao.id}',
          activeBusyKey: viewModel.busyKey,
          onTap: summary.liuyaoCount == 0
              ? null
              : () => _confirmAndRun(
                    context: context,
                    title: '清理六爻记录',
                    message: '将删除全部六爻历史记录，不影响其他术数、AI 配置和模板。',
                    isDanger: true,
                    action: () =>
                        viewModel.clearHistoryBySystem(DivinationType.liuYao),
                  ),
        ),
        _buildActionTile(
          title: '清理大六壬记录',
          subtitle: '当前 ${summary.daliurenCount} 条',
          icon: Icons.menu_book_outlined,
          busyKey: 'clear_${DivinationType.daLiuRen.id}',
          activeBusyKey: viewModel.busyKey,
          onTap: summary.daliurenCount == 0
              ? null
              : () => _confirmAndRun(
                    context: context,
                    title: '清理大六壬记录',
                    message: '将删除全部大六壬历史记录，不影响其他术数、AI 配置和模板。',
                    isDanger: true,
                    action: () =>
                        viewModel.clearHistoryBySystem(DivinationType.daLiuRen),
                  ),
        ),
        _buildActionTile(
          title: '清理梅花记录',
          subtitle: '当前 ${summary.meihuaCount} 条',
          icon: Icons.filter_vintage_outlined,
          busyKey: 'clear_${DivinationType.meiHua.id}',
          activeBusyKey: viewModel.busyKey,
          onTap: summary.meihuaCount == 0
              ? null
              : () => _confirmAndRun(
                    context: context,
                    title: '清理梅花记录',
                    message: '将删除全部梅花易数历史记录，不影响其他术数、AI 配置和模板。',
                    isDanger: true,
                    action: () =>
                        viewModel.clearHistoryBySystem(DivinationType.meiHua),
                  ),
        ),
        _buildActionTile(
          title: '清理小六壬记录',
          subtitle: '当前 ${summary.xiaoliurenCount} 条',
          icon: Icons.grain_outlined,
          busyKey: 'clear_${DivinationType.xiaoLiuRen.id}',
          activeBusyKey: viewModel.busyKey,
          onTap: summary.xiaoliurenCount == 0
              ? null
              : () => _confirmAndRun(
                    context: context,
                    title: '清理小六壬记录',
                    message: '将删除全部小六壬历史记录，不影响其他术数、AI 配置和模板。',
                    isDanger: true,
                    action: () => viewModel.clearHistoryBySystem(
                      DivinationType.xiaoLiuRen,
                    ),
                  ),
        ),
        _buildActionTile(
          title: '清理 30 天前记录',
          subtitle: '删除较久远的历史，保留最近一个月内的数据',
          icon: Icons.history_toggle_off,
          busyKey: 'clear_before_30',
          activeBusyKey: viewModel.busyKey,
          onTap: summary.totalRecords == 0
              ? null
              : () => _confirmAndRun(
                    context: context,
                    title: '清理 30 天前记录',
                    message: '将删除 30 天前的历史记录，不影响 AI 配置和提示词模板。',
                    isDanger: true,
                    action: () => viewModel.clearHistoryBefore(
                      DateTime.now().subtract(const Duration(days: 30)),
                    ),
                  ),
        ),
        _buildActionTile(
          title: '清空全部历史记录',
          subtitle: '仅清空排盘历史，不影响 AI 配置、模板与偏好',
          icon: Icons.delete_sweep_outlined,
          busyKey: 'clear_history_all',
          activeBusyKey: viewModel.busyKey,
          isDanger: true,
          onTap: summary.totalRecords == 0
              ? null
              : () => _confirmAndRun(
                    context: context,
                    title: '清空全部历史记录',
                    message: '将删除全部排盘历史记录，但不会删除 AI 接口配置、API Key、提示词模板和其他偏好。',
                    isDanger: true,
                    action: viewModel.clearAllHistory,
                  ),
        ),
      ],
    );
  }

  Widget _buildResetSection(
    BuildContext context,
    DataManagementViewModel viewModel,
  ) {
    final summary = viewModel.summary;
    final aiAvailable = viewModel.isAIModuleAvailable;

    return _buildSectionCard(
      title: '清理与重置',
      description: '这一组只放明确边界的重置项。高风险全局重置暂不开放。',
      children: [
        if (!aiAvailable)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.25)),
            ),
            child: Text(
              'AI 模块尚未初始化完成，AI 配置与模板相关操作暂不可用。',
              style: AppTextStyles.antiqueLabel,
            ),
          ),
        _buildActionTile(
          title: '清空 AI 接口配置',
          subtitle: summary != null
              ? '当前 ${summary.aiProfileCount} 套配置，将同时删除对应 API Key'
              : '删除所有接口参数和 API Key',
          icon: Icons.hub_outlined,
          busyKey: 'clear_ai_profiles',
          activeBusyKey: viewModel.busyKey,
          isDanger: true,
          onTap: !aiAvailable || summary == null || summary.aiProfileCount == 0
              ? null
              : () => _confirmAndRun(
                    context: context,
                    title: '清空 AI 接口配置',
                    message: '将删除所有已保存的 AI 接口配置和 API Key，不影响历史记录与提示词模板。',
                    isDanger: true,
                    action: viewModel.clearAllAIProfiles,
                  ),
        ),
        _buildActionTile(
          title: '恢复默认提示词',
          subtitle: summary != null
              ? '当前 ${summary.customTemplateCount} 条自定义模板将被清理'
              : '删除自定义模板并恢复内置模板默认内容',
          icon: Icons.restore_page_outlined,
          busyKey: 'restore_templates',
          activeBusyKey: viewModel.busyKey,
          onTap: !aiAvailable ||
                  summary == null ||
                  summary.customTemplateCount == 0
              ? null
              : () => _confirmAndRun(
                    context: context,
                    title: '恢复默认提示词',
                    message: '将删除自定义模板，并把内置模板内容恢复为默认版本，不影响历史记录与 AI 配置。',
                    isDanger: true,
                    action: viewModel.restoreDefaultPromptTemplates,
                  ),
        ),
        _buildActionTile(
          title: '清理缓存',
          subtitle: '临时导出文件和缓存清理将在下一阶段接入',
          icon: Icons.cleaning_services_outlined,
          activeBusyKey: viewModel.busyKey,
          onTap: () => _showMessage(context, '缓存清理将在下一阶段实现'),
        ),
        _buildActionTile(
          title: '清空全部本地数据',
          subtitle: '高风险操作，待完整备份与导入能力完成后再开放',
          icon: Icons.warning_amber_outlined,
          activeBusyKey: viewModel.busyKey,
          isDanger: true,
          onTap: () => _showMessage(
            context,
            '全局重置暂未开放，待备份能力完成后再接入',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return AntiqueCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.antiqueSection),
          const SizedBox(height: 4),
          Text(description, style: AppTextStyles.antiqueLabel),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
    String? busyKey,
    String? activeBusyKey,
    bool isDanger = false,
  }) {
    final busy = busyKey != null && activeBusyKey == busyKey;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AntiqueCard(
        onTap: busy ? null : onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDanger ? AppColors.zhusha : AppColors.guhe,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.antiqueBody.copyWith(
                      color:
                          onTap == null ? AppColors.qianhe : AppColors.xuanse,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.antiqueLabel.copyWith(
                      color: onTap == null ? AppColors.qianhe : AppColors.guhe,
                    ),
                  ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right,
                color: onTap == null ? AppColors.qianhe : AppColors.guhe,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTag(String label) {
    return AntiqueTag(label: label);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(label, style: AppTextStyles.antiqueLabel),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.antiqueBody),
          ),
        ],
      ),
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

    final mode = await _showImportModeDialog(context, preview);
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

  Future<BackupImportMode?> _showImportModeDialog(
    BuildContext context,
    BackupImportPreview preview,
  ) {
    return showAntiqueDialog<BackupImportMode>(
      context: context,
      title: '导入备份',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '备份时间：${_formatDateTime(preview.exportedAt)}',
            style: AppTextStyles.antiqueBody,
          ),
          const SizedBox(height: 8),
          Text(
            '历史 ${preview.recordCount} 条 · AI 配置 ${preview.aiProfileCount} 套 · 模板 ${preview.templateCount} 条 · 偏好 ${preview.preferenceCount} 项',
            style: AppTextStyles.antiqueBody,
          ),
          const SizedBox(height: 8),
          Text(
            preview.includesApiKeys
                ? '该备份包含敏感信息。'
                : '该备份不包含 API Key，导入后需重新填写密钥。',
            style: AppTextStyles.antiqueLabel,
          ),
          const SizedBox(height: 8),
          Text(
            '合并导入会保留现有数据；覆盖导入会先清空备份涉及的范围再导入。',
            style: AppTextStyles.antiqueLabel,
          ),
        ],
      ),
      actions: [
        AntiqueButton(
          label: '取消',
          onPressed: () => Navigator.of(context).pop(),
          variant: AntiqueButtonVariant.ghost,
        ),
        AntiqueButton(
          label: BackupImportMode.merge.displayName,
          onPressed: () => Navigator.of(context).pop(BackupImportMode.merge),
          variant: AntiqueButtonVariant.primary,
        ),
        AntiqueButton(
          label: BackupImportMode.overwrite.displayName,
          onPressed: () =>
              Navigator.of(context).pop(BackupImportMode.overwrite),
          variant: AntiqueButtonVariant.danger,
        ),
      ],
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDateTime(DateTime time) {
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}
