import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../divination_systems/liuyao/viewmodels/liuyao_viewmodel.dart';
import '../../../domain/divination_system.dart';
import '../../divination_ui_registry.dart';
import '../../widgets/antique/antique.dart';
import '../../widgets/cast/coin_cast_section.dart';
import '../../widgets/cast/computer_cast_section.dart';
import '../../widgets/cast/number_cast_section.dart';
import '../../widgets/cast/report_number_cast_section.dart';
import '../../widgets/cast/time_cast_section.dart';
import '../../widgets/cast/yao_name_cast_section.dart';

/// 统一起卦页面
///
/// 将方式选择和起卦操作合并为一个页面，支持六种起卦方式。
class UnifiedCastScreen extends StatefulWidget {
  const UnifiedCastScreen({super.key});

  @override
  State<UnifiedCastScreen> createState() => _UnifiedCastScreenState();
}

class _UnifiedCastScreenState extends State<UnifiedCastScreen> {
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
      if (_question.isNotEmpty) {
        await viewModel.saveRecord(question: _question);
      }
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
      if (_question.isNotEmpty) {
        await viewModel.saveRecord(question: _question);
      }
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
      if (_question.isNotEmpty) {
        await viewModel.saveRecord(question: _question);
      }
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
      if (_question.isNotEmpty) {
        await viewModel.saveRecord(question: _question);
      }
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
