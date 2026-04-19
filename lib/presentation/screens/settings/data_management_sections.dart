import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/services/data_management_service.dart';
import '../../widgets/antique/antique.dart';

String formatDataManagementDateTime(DateTime time) {
  final year = time.year.toString().padLeft(4, '0');
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

Future<BackupImportMode?> showBackupImportModeDialog(
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
          '备份时间：${formatDataManagementDateTime(preview.exportedAt)}',
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
        onPressed: () => Navigator.of(context).pop(BackupImportMode.overwrite),
        variant: AntiqueButtonVariant.danger,
      ),
    ],
  );
}

class DataManagementUnavailableCard extends StatelessWidget {
  const DataManagementUnavailableCard({super.key});

  @override
  Widget build(BuildContext context) {
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
}

class DataManagementMessageCard extends StatelessWidget {
  const DataManagementMessageCard({
    super.key,
    required this.message,
    required this.color,
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
}

class DataManagementOverviewCard extends StatelessWidget {
  const DataManagementOverviewCard({
    super.key,
    required this.summary,
  });

  final DataManagementSummary? summary;

  @override
  Widget build(BuildContext context) {
    final value = summary;
    if (value == null) {
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
              AntiqueTag(label: '历史记录 ${value.totalRecords} 条'),
              AntiqueTag(label: 'AI 配置 ${value.aiProfileCount} 套'),
              AntiqueTag(label: '自定义模板 ${value.customTemplateCount} 条'),
            ],
          ),
          const SizedBox(height: 12),
          _DataManagementInfoRow(label: '六爻', value: '${value.liuyaoCount} 条'),
          _DataManagementInfoRow(
            label: '大六壬',
            value: '${value.daliurenCount} 条',
          ),
          _DataManagementInfoRow(
            label: '梅花易数',
            value: '${value.meihuaCount} 条',
          ),
          _DataManagementInfoRow(
            label: '小六壬',
            value: '${value.xiaoliurenCount} 条',
          ),
          _DataManagementInfoRow(
            label: '最近记录',
            value: value.latestRecordTime != null
                ? formatDataManagementDateTime(value.latestRecordTime!)
                : '暂无',
          ),
          _DataManagementInfoRow(
            label: '上次备份',
            value: value.lastBackupAt != null
                ? formatDataManagementDateTime(value.lastBackupAt!)
                : '尚未备份',
          ),
        ],
      ),
    );
  }
}

class DataManagementBackupSection extends StatelessWidget {
  const DataManagementBackupSection({
    super.key,
    required this.enabled,
    required this.activeBusyKey,
    required this.onExport,
    required this.onImport,
  });

  final bool enabled;
  final String? activeBusyKey;
  final VoidCallback onExport;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return _DataManagementSectionCard(
      title: '备份与迁移',
      description: '导出和导入完整备份。当前默认不包含 API Key，导入后如有需要请重新填写。',
      children: [
        _DataManagementActionTile(
          title: '导出完整备份',
          subtitle: '将历史、AI 配置元信息、提示词模板和偏好设置打包导出',
          icon: Icons.upload_file,
          busyKey: 'export_backup',
          activeBusyKey: activeBusyKey,
          onTap: enabled ? onExport : null,
        ),
        _DataManagementActionTile(
          title: '导入备份',
          subtitle: '支持合并导入或覆盖导入，导入前会先预览并校验备份包',
          icon: Icons.download,
          busyKey: 'import_backup',
          activeBusyKey: activeBusyKey,
          onTap: enabled ? onImport : null,
        ),
      ],
    );
  }
}

class DataManagementHistorySection extends StatelessWidget {
  const DataManagementHistorySection({
    super.key,
    required this.summary,
    required this.activeBusyKey,
    required this.onClearLiuYao,
    required this.onClearDaLiuRen,
    required this.onClearMeiHua,
    required this.onClearXiaoLiuRen,
    required this.onClearBefore30Days,
    required this.onClearAll,
  });

  final DataManagementSummary? summary;
  final String? activeBusyKey;
  final VoidCallback onClearLiuYao;
  final VoidCallback onClearDaLiuRen;
  final VoidCallback onClearMeiHua;
  final VoidCallback onClearXiaoLiuRen;
  final VoidCallback onClearBefore30Days;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final value = summary;
    if (value == null) {
      return const SizedBox.shrink();
    }

    return _DataManagementSectionCard(
      title: '历史记录管理',
      description: '历史清理仅影响排盘记录，不应触碰 AI Key、模板和其他偏好。',
      children: [
        _DataManagementActionTile(
          title: '清理六爻记录',
          subtitle: '当前 ${value.liuyaoCount} 条',
          icon: Icons.auto_stories_outlined,
          busyKey: 'clear_liuyao',
          activeBusyKey: activeBusyKey,
          onTap: value.liuyaoCount == 0 ? null : onClearLiuYao,
        ),
        _DataManagementActionTile(
          title: '清理大六壬记录',
          subtitle: '当前 ${value.daliurenCount} 条',
          icon: Icons.menu_book_outlined,
          busyKey: 'clear_daliuren',
          activeBusyKey: activeBusyKey,
          onTap: value.daliurenCount == 0 ? null : onClearDaLiuRen,
        ),
        _DataManagementActionTile(
          title: '清理梅花记录',
          subtitle: '当前 ${value.meihuaCount} 条',
          icon: Icons.filter_vintage_outlined,
          busyKey: 'clear_meihua',
          activeBusyKey: activeBusyKey,
          onTap: value.meihuaCount == 0 ? null : onClearMeiHua,
        ),
        _DataManagementActionTile(
          title: '清理小六壬记录',
          subtitle: '当前 ${value.xiaoliurenCount} 条',
          icon: Icons.grain_outlined,
          busyKey: 'clear_xiaoliuren',
          activeBusyKey: activeBusyKey,
          onTap: value.xiaoliurenCount == 0 ? null : onClearXiaoLiuRen,
        ),
        _DataManagementActionTile(
          title: '清理 30 天前记录',
          subtitle: '删除较久远的历史，保留最近一个月内的数据',
          icon: Icons.history_toggle_off,
          busyKey: 'clear_before_30',
          activeBusyKey: activeBusyKey,
          onTap: value.totalRecords == 0 ? null : onClearBefore30Days,
        ),
        _DataManagementActionTile(
          title: '清空全部历史记录',
          subtitle: '仅清空排盘历史，不影响 AI 配置、模板与偏好',
          icon: Icons.delete_sweep_outlined,
          busyKey: 'clear_history_all',
          activeBusyKey: activeBusyKey,
          isDanger: true,
          onTap: value.totalRecords == 0 ? null : onClearAll,
        ),
      ],
    );
  }
}

class DataManagementResetSection extends StatelessWidget {
  const DataManagementResetSection({
    super.key,
    required this.summary,
    required this.aiAvailable,
    required this.activeBusyKey,
    required this.onClearAIProfiles,
    required this.onRestoreTemplates,
    required this.onShowCacheNotice,
    required this.onShowGlobalResetNotice,
  });

  final DataManagementSummary? summary;
  final bool aiAvailable;
  final String? activeBusyKey;
  final VoidCallback onClearAIProfiles;
  final VoidCallback onRestoreTemplates;
  final VoidCallback onShowCacheNotice;
  final VoidCallback onShowGlobalResetNotice;

  @override
  Widget build(BuildContext context) {
    final value = summary;

    return _DataManagementSectionCard(
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
        _DataManagementActionTile(
          title: '清空 AI 接口配置',
          subtitle: value != null
              ? '当前 ${value.aiProfileCount} 套配置，将同时删除对应 API Key'
              : '删除所有接口参数和 API Key',
          icon: Icons.hub_outlined,
          busyKey: 'clear_ai_profiles',
          activeBusyKey: activeBusyKey,
          isDanger: true,
          onTap: !aiAvailable || value == null || value.aiProfileCount == 0
              ? null
              : onClearAIProfiles,
        ),
        _DataManagementActionTile(
          title: '恢复默认提示词',
          subtitle: value != null
              ? '当前 ${value.customTemplateCount} 条自定义模板将被清理'
              : '删除自定义模板并恢复内置模板默认内容',
          icon: Icons.restore_page_outlined,
          busyKey: 'restore_templates',
          activeBusyKey: activeBusyKey,
          onTap: !aiAvailable || value == null || value.customTemplateCount == 0
              ? null
              : onRestoreTemplates,
        ),
        _DataManagementActionTile(
          title: '清理缓存',
          subtitle: '临时导出文件和缓存清理将在下一阶段接入',
          icon: Icons.cleaning_services_outlined,
          activeBusyKey: activeBusyKey,
          onTap: onShowCacheNotice,
        ),
        _DataManagementActionTile(
          title: '清空全部本地数据',
          subtitle: '高风险操作，待完整备份与导入能力完成后再开放',
          icon: Icons.warning_amber_outlined,
          activeBusyKey: activeBusyKey,
          isDanger: true,
          onTap: onShowGlobalResetNotice,
        ),
      ],
    );
  }
}

class _DataManagementSectionCard extends StatelessWidget {
  const _DataManagementSectionCard({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
}

class _DataManagementActionTile extends StatelessWidget {
  const _DataManagementActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.busyKey,
    this.activeBusyKey,
    this.isDanger = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final String? busyKey;
  final String? activeBusyKey;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
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
                      color: onTap == null ? AppColors.qianhe : AppColors.xuanse,
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
}

class _DataManagementInfoRow extends StatelessWidget {
  const _DataManagementInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
}
