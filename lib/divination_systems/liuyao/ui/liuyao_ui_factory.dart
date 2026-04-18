import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/repositories/divination_repository.dart';
import '../../../domain/divination_system.dart';
import '../models/gua.dart';
import '../../../presentation/divination_ui_registry.dart';
import '../../../presentation/widgets/ai_analysis_widget.dart';
import '../../../presentation/widgets/antique/antique.dart';
import '../../../presentation/widgets/cast/coin_cast_section.dart';
import '../../../presentation/widgets/cast/computer_cast_section.dart';
import '../../../presentation/widgets/cast/number_cast_section.dart';
import '../../../presentation/widgets/cast/report_number_cast_section.dart';
import '../../../presentation/widgets/cast/time_cast_section.dart';
import '../../../presentation/widgets/cast/yao_name_cast_section.dart';
import '../../../presentation/widgets/diagram_comparison_row.dart';
import '../../../presentation/widgets/question_section.dart';
import '../../../presentation/widgets/extended_info_section.dart';
import '../../../presentation/widgets/special_relation_section.dart';
import '../liuyao_result.dart';
import '../viewmodels/liuyao_viewmodel.dart';

/// 六爻 UI 工厂
///
/// 实现 DivinationUIFactory 接口，提供六爻特定的 UI 组件。
/// 复用现有的六爻 UI 组件，确保用户体验保持一致。
class LiuYaoUIFactory implements DivinationUIFactory {
  @override
  DivinationType get systemType => DivinationType.liuYao;

  @override
  Widget buildCastScreen(CastMethod method) {
    return const _LiuYaoCastScreen();
  }

  @override
  Widget buildResultScreen(DivinationResult result) {
    // 类型检查
    if (result is! LiuYaoResult) {
      throw ArgumentError('结果类型必须是 LiuYaoResult，实际类型: ${result.runtimeType}');
    }

    // 返回包含 AI 分析功能的结果页面
    return _LiuYaoResultScreenWithAI(result: result);
  }

  @override
  Widget buildHistoryCard(DivinationResult result) {
    // 类型检查
    if (result is! LiuYaoResult) {
      throw ArgumentError('结果类型必须是 LiuYaoResult，实际类型: ${result.runtimeType}');
    }

    return _LiuYaoHistoryCard(result: result);
  }

  @override
  IconData? getSystemIcon() {
    // 返回六爻系统的图标（使用六边形代表六爻）
    return Icons.hexagon;
  }

  @override
  Color? getSystemColor() {
    // 返回六爻系统的主题色（中国传统色：朱红）
    return const Color(0xFFD32F2F); // 六爻系统专属主题色，非通用 token（deferred to semantic-color pass）
  }

}

/// 六爻历史记录卡片（统一 5 层信息层级）
class _LiuYaoHistoryCard extends StatelessWidget {
  final LiuYaoResult result;

  const _LiuYaoHistoryCard({required this.result});

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get _summary {
    final main = result.mainGua.name;
    final changing = result.changingGua?.name;
    return changing != null ? '$main → $changing' : main;
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<DivinationRepository>();
    final questionKey = 'question_${result.id}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AntiqueCard(
        onTap: () {
          // TODO: 导航到详情页面
        },
        child: FutureBuilder<String?>(
          future: repository.readEncryptedField(questionKey),
          builder: (context, snapshot) {
            final question = snapshot.data ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 层 1: 占问事项（空时保留高度占位）
                SizedBox(
                  height: 24,
                  child: Text(
                    question.isNotEmpty ? question : ' ',
                    style: AppTextStyles.antiqueTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),

                // 层 2: 时间
                Text(
                  _formatDateTime(result.castTime),
                  style: AppTextStyles.antiqueLabel.copyWith(color: AppColors.guhe),
                ),
                const SizedBox(height: 8),

                // 层 3: 结果摘要（主卦 → 变卦 or 主卦）
                Text(
                  _summary,
                  style: AppTextStyles.antiqueBody,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // 层 4/5: 排盘类型 + 排盘方式 badges
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    AntiqueTag(
                      label: '六爻',
                      color: AppColors.liuyaoColor,
                    ),
                    AntiqueTag(
                      label: result.castMethod.displayName,
                      color: AppColors.guhe,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 六爻结果页面（包含 AI 分析功能）
///
/// 这是一个内部组件，用于在结果页面中集成 AI 分析功能。
class _LiuYaoResultScreenWithAI extends StatelessWidget {
  final LiuYaoResult result;

  const _LiuYaoResultScreenWithAI({required this.result});

  @override
  Widget build(BuildContext context) {
    return AntiqueScaffold(
      appBar: const AntiqueAppBar(title: '排盘结果'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // 占问信息区块
            Builder(builder: (context) {
              final question =
                  context.select<LiuYaoViewModel, String?>((vm) => vm.question);
              if (question == null || question.isEmpty) {
                return const SizedBox.shrink();
              }
              return QuestionSection(
                subject: null,
                question: question,
              );
            }),

            // 扩展信息区块（农历、节气、神煞）
            ExtendedInfoSection(
              castTime: result.castTime,
              lunarInfo: result.lunarInfo,
              liuShen: result.liuShen,
              shenShaInfo: null,
            ),

            // 卦象横向对比布局
            DiagramComparisonRow(
              mainGua: result.mainGua,
              changingGua: result.changingGua,
              liuShen: result.liuShen,
            ),

            // 特殊关系解析区块
            SpecialRelationSection(
              relationType: _getSpecialRelationType(result.mainGua),
              description: _getSpecialRelationDescription(result.mainGua),
            ),

            // AI 分析区块
            Builder(builder: (context) {
              final question =
                  context.select<LiuYaoViewModel, String?>((vm) => vm.question);
              return AIAnalysisWidget(
                result: result,
                question: question,
              );
            }),

            // 底部间距
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

  /// 获取特殊关系类型
  String? _getSpecialRelationType(Gua gua) {
    if (gua.specialType == GuaSpecialType.none) {
      return null;
    }
    return gua.specialType.name;
  }

  /// 获取特殊关系描述
  String? _getSpecialRelationDescription(Gua gua) {
    return switch (gua.specialType) {
      GuaSpecialType.youHun => '游魂卦，主动荡不安，事多变化。',
      GuaSpecialType.guiHun => '归魂卦，主稳定，事归本源。',
      GuaSpecialType.liuChong => '六冲卦，主冲突激烈，事难成。',
      GuaSpecialType.liuHe => '六合卦，主和谐顺利，事易成。',
      GuaSpecialType.none => null,
    };
  }
}

/// 六爻起卦页面（文件私有）
///
/// 此前作为 platform-level `UnifiedCastScreen` 存在于
/// `lib/presentation/screens/cast/unified_cast_screen.dart`。
/// 收敛 spec §3.3.1 明确该 widget 实际只服务六爻，
/// 已迁至六爻 UI 工厂内部为文件私有类。
class _LiuYaoCastScreen extends StatefulWidget {
  const _LiuYaoCastScreen();

  @override
  State<_LiuYaoCastScreen> createState() => _LiuYaoCastScreenState();
}

class _LiuYaoCastScreenState extends State<_LiuYaoCastScreen> {
  static const _prefKey = 'liuyao_last_cast_method';

  CastMethod _selectedMethod = CastMethod.coin;
  bool _isProcessing = false;
  final TextEditingController _questionController = TextEditingController();

  static const List<CastMethod> _availableMethods = [
    CastMethod.coin,
    CastMethod.manual,
    CastMethod.number,
    CastMethod.reportNumber,
    CastMethod.time,
    CastMethod.computer,
  ];

  @override
  void initState() {
    super.initState();
    _loadLastMethod();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadLastMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefKey);
    if (id != null) {
      try {
        final method = CastMethod.fromId(id);
        if (_availableMethods.contains(method)) {
          setState(() => _selectedMethod = method);
        }
      } catch (_) {
        // unknown id — ignore
      }
    }
  }

  Future<void> _saveLastMethod(CastMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, method.id);
  }

  void _onMethodChanged(CastMethod? method) {
    if (method == null) return;
    setState(() => _selectedMethod = method);
    _saveLastMethod(method);
  }

  Future<void> _navigateToResult(
      BuildContext context, LiuYaoViewModel viewModel) async {
    if (!viewModel.hasResult) return;
    // 确保占问事项在结果页可见
    if (_question.isNotEmpty && (viewModel.question == null || viewModel.question!.isEmpty)) {
      await viewModel.saveRecord(question: _question);
    }
    final result = viewModel.result!;
    final resultScreen = DivinationUIRegistry().buildResultScreen(result);
    if (!context.mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => resultScreen),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorDeep,
      ),
    );
  }

  String get _question => _questionController.text.trim();

  Future<void> _handleCoinCast(List<int> yaoNumbers) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final viewModel = context.read<LiuYaoViewModel>();
      await viewModel.castByManualYaoNumbers(
        yaoNumbers,
        castTime: DateTime.now(),
        question: _question.isNotEmpty ? _question : null,
      );
      if (viewModel.hasError) {
        _showError(viewModel.errorMessage ?? '起卦失败');
        return;
      }
      if (mounted) await _navigateToResult(context, viewModel);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleTimeCast() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final viewModel = context.read<LiuYaoViewModel>();
      await viewModel.castByTime(castTime: DateTime.now());
      if (viewModel.hasError) {
        _showError(viewModel.errorMessage ?? '起卦失败');
        return;
      }
      await viewModel.saveRecord(
        question: _question.isNotEmpty ? _question : null,
      );
      if (mounted) await _navigateToResult(context, viewModel);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleManualCast(
      List<int> yaoNumbers, DateTime castTime) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final viewModel = context.read<LiuYaoViewModel>();
      await viewModel.castByManualYaoNumbers(
        yaoNumbers,
        castTime: castTime,
        question: _question.isNotEmpty ? _question : null,
      );
      if (viewModel.hasError) {
        _showError(viewModel.errorMessage ?? '起卦失败');
        return;
      }
      if (mounted) await _navigateToResult(context, viewModel);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleNumberCast(int number) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final viewModel = context.read<LiuYaoViewModel>();
      await viewModel.castByNumber(number, castTime: DateTime.now());
      if (viewModel.hasError) {
        _showError(viewModel.errorMessage ?? '起卦失败');
        return;
      }
      await viewModel.saveRecord(
        question: _question.isNotEmpty ? _question : null,
      );
      if (mounted) await _navigateToResult(context, viewModel);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReportNumberCast(
      int upperNum, int lowerNum, int movingNum) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final viewModel = context.read<LiuYaoViewModel>();
      await viewModel.castByReportNumber(upperNum, lowerNum, movingNum,
          castTime: DateTime.now());
      if (viewModel.hasError) {
        _showError(viewModel.errorMessage ?? '起卦失败');
        return;
      }
      await viewModel.saveRecord(
        question: _question.isNotEmpty ? _question : null,
      );
      if (mounted) await _navigateToResult(context, viewModel);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleComputerCast() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final viewModel = context.read<LiuYaoViewModel>();
      await viewModel.castByComputer(castTime: DateTime.now());
      if (viewModel.hasError) {
        _showError(viewModel.errorMessage ?? '起卦失败');
        return;
      }
      await viewModel.saveRecord(
        question: _question.isNotEmpty ? _question : null,
      );
      if (mounted) await _navigateToResult(context, viewModel);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AntiqueScaffold(
      showCompass: true,
      appBar: const AntiqueAppBar(title: '六爻起卦'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuestionSection(),
              const SizedBox(height: 16),
              _buildMethodSelector(),
              const SizedBox(height: 16),
              const AntiqueDivider(),
              const SizedBox(height: 20),
              _buildCastSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('占问事项', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueTextField(
          controller: _questionController,
          hint: '请输入您想占问的事项...',
          maxLines: 2,
          minLines: 1,
        ),
      ],
    );
  }

  Widget _buildMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('起卦方式', style: AppTextStyles.antiqueLabel),
        const SizedBox(height: 6),
        AntiqueDropdown<CastMethod>(
          value: _selectedMethod,
          items: _availableMethods
              .map((m) => AntiqueDropdownItem<CastMethod>(
                    value: m,
                    label: m.displayName,
                  ))
              .toList(),
          onChanged: _onMethodChanged,
        ),
      ],
    );
  }

  Widget _buildCastSection() {
    switch (_selectedMethod) {
      case CastMethod.coin:
        return CoinCastSection(
          onCast: _isProcessing ? null : _handleCoinCast,
          isLoading: _isProcessing,
        );
      case CastMethod.manual:
        return YaoNameCastSection(
          onCast: _isProcessing ? null : _handleManualCast,
          isLoading: _isProcessing,
        );
      case CastMethod.number:
        return NumberCastSection(
          onCast: _isProcessing ? null : _handleNumberCast,
          isLoading: _isProcessing,
        );
      case CastMethod.reportNumber:
        return ReportNumberCastSection(
          onCast: _isProcessing ? null : _handleReportNumberCast,
          isLoading: _isProcessing,
        );
      case CastMethod.time:
        return TimeCastSection(
          onCast: _isProcessing ? null : _handleTimeCast,
          isLoading: _isProcessing,
        );
      case CastMethod.computer:
        return ComputerCastSection(
          onCast: _isProcessing ? null : _handleComputerCast,
          isLoading: _isProcessing,
        );
    }
  }
}
