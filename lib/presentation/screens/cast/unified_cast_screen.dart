import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../divination_systems/liuyao/viewmodels/liuyao_viewmodel.dart';
import '../../../domain/divination_system.dart';
import '../../divination_ui_registry.dart';
import '../../widgets/cast/coin_cast_section.dart';
import '../../widgets/cast/compass_background.dart';
import '../../widgets/cast/manual_cast_section.dart';
import '../../widgets/cast/time_cast_section.dart';

/// 统一起卦页面
///
/// 将方式选择和起卦操作合并为一个页面，支持摇钱法、时间起卦和手动输入。
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
    CastMethod.time,
    CastMethod.manual,
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
        backgroundColor: const Color(0xFF8B2020),
      ),
    );
  }

  Future<void> _handleCoinCast() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final viewModel = context.read<LiuYaoViewModel>();
      await viewModel.castByCoin(castTime: DateTime.now());
      if (viewModel.hasError) {
        _showError(viewModel.errorMessage ?? '起卦失败');
        return;
      }
      final question = _questionController.text.trim();
      if (question.isNotEmpty) {
        await viewModel.saveRecord(question: question);
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
      final question = _questionController.text.trim();
      if (question.isNotEmpty) {
        await viewModel.saveRecord(question: question);
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
      final question = _questionController.text.trim();
      await viewModel.castByManualYaoNumbers(
        yaoNumbers,
        castTime: castTime,
        question: question.isNotEmpty ? question : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('六爻起卦'),
      ),
      body: Stack(
        children: [
          // Xuan paper gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF7F7F5), Color(0xFFF0EDE8)],
              ),
            ),
          ),
          // Compass background overlay
          const CompassBackground(),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestionSection(),
                  const SizedBox(height: 16),
                  _buildMethodSelector(),
                  const SizedBox(height: 16),
                  Divider(
                    color: const Color(0x40B79452),
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 20),
                  _buildCastSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '占问事项',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF8B7355),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border.all(color: const Color(0x4DB79452)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: _questionController,
            style: const TextStyle(
              color: Color(0xFF2B4570),
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '请输入您想占问的事项...',
              hintStyle: TextStyle(
                color: Color(0xFFA0937E),
                fontSize: 13,
              ),
              isDense: true,
            ),
            maxLines: 2,
            minLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '起卦方式',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF8B7355),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            border: Border.all(color: const Color(0x4DB79452)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CastMethod>(
              value: _selectedMethod,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(
                color: Color(0xFF2B4570),
                fontSize: 13,
              ),
              items: _availableMethods.map((method) {
                return DropdownMenuItem<CastMethod>(
                  value: method,
                  child: Text(
                    method.displayName,
                    style: const TextStyle(
                      color: Color(0xFF2B4570),
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _onMethodChanged,
            ),
          ),
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
      case CastMethod.time:
        return TimeCastSection(
          onCast: _isProcessing ? null : _handleTimeCast,
          isLoading: _isProcessing,
        );
      case CastMethod.manual:
        return ManualCastSection(
          onCast: _isProcessing ? null : _handleManualCast,
          isLoading: _isProcessing,
        );
      default:
        return CoinCastSection(
          onCast: _isProcessing ? null : _handleCoinCast,
          isLoading: _isProcessing,
        );
    }
  }
}
