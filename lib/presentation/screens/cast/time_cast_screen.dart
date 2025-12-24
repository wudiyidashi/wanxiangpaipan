import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../domain/services/qigua_service.dart';
import '../../../divination_systems/liuyao/viewmodels/liuyao_viewmodel.dart';
import '../../../presentation/divination_ui_registry.dart';

/// 时间起卦界面
class TimeCastScreen extends StatefulWidget {
  const TimeCastScreen({super.key});

  @override
  State<TimeCastScreen> createState() => _TimeCastScreenState();
}

class _TimeCastScreenState extends State<TimeCastScreen> {
  List<int>? _yaoNumbers;

  /// 执行时间起卦并调用 ViewModel
  Future<void> _cast() async {
    final now = DateTime.now();

    setState(() {
      _yaoNumbers = QiGuaService.timeCast(now);
    });

    // 使用 ViewModel 执行完整的起卦流程
    if (mounted) {
      final viewModel = context.read<LiuYaoViewModel>();
      await viewModel.castByTime(castTime: now);

      // 检查是否有错误
      if (viewModel.hasError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(viewModel.errorMessage!)),
          );
        }
        return;
      }

      // 导航到结果页面（使用 UI 工厂动态构建）
      if (viewModel.hasResult && mounted) {
        final result = viewModel.result!;
        final uiRegistry = DivinationUIRegistry();
        final resultScreen = uiRegistry.buildResultScreen(result);

        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => resultScreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: const Text('时间起卦'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      '当前时间',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(now),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '根据当前时间自动计算卦象',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _yaoNumbers == null
                  ? const Center(
                      child: Text(
                        '点击"起卦"按钮开始',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _yaoNumbers!.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              '第${index + 1}爻：${_yaoNumbers![index]}',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cast,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('起卦'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
