import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../ai/service/ai_analysis_service.dart';
import 'ai_settings_sections.dart';
import 'ai_settings_viewmodel.dart';

class AISettingsScreen extends StatelessWidget {
  const AISettingsScreen({
    super.key,
    AISettingsService? service,
    AIModelFetcher? modelFetcher,
  })  : _service = service,
        _modelFetcher = modelFetcher;

  final AISettingsService? _service;
  final AIModelFetcher? _modelFetcher;

  static const presets = [
    AIPreset('OpenAI', 'https://api.openai.com/v1', Icons.cloud),
    AIPreset('DeepSeek', 'https://api.deepseek.com/v1', Icons.auto_awesome),
    AIPreset(
      'Gemini',
      'https://generativelanguage.googleapis.com/v1beta/openai/',
      Icons.diamond,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AISettingsViewModel>(
      create: (context) => AISettingsViewModel(
        service: _service ?? _buildSettingsService(context),
        modelFetcher: _modelFetcher,
      )..initialize(),
      child: const AISettingsBody(presets: presets),
    );
  }

  AISettingsService? _buildSettingsService(BuildContext context) {
    try {
      final aiService = context.read<AIAnalysisService>();
      return AIAnalysisSettingsService(aiService);
    } catch (_) {
      return null;
    }
  }
}
