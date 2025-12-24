import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/services/qigua_service.dart';
import '../../../divination_systems/liuyao/viewmodels/liuyao_viewmodel.dart';
import '../../../presentation/divination_ui_registry.dart';

/// 摇钱法起卦界面
class CoinCastScreen extends StatefulWidget {
  const CoinCastScreen({super.key});

  @override
  State<CoinCastScreen> createState() => _CoinCastScreenState();
}

class _CoinCastScreenState extends State<CoinCastScreen> {
  final List<int> _yaoNumbers = [];
  bool _isCasting = false;

  /// 执行起卦动画并调用 ViewModel
  Future<void> _cast() async {
    if (_isCasting) return;

    setState(() {
      _isCasting = true;
      _yaoNumbers.clear();
    });

    // 模拟投掷动画（显示过程）
    for (int i = 0; i < 6; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      setState(() {
        _yaoNumbers.add(QiGuaService.coinCastOnce());
      });
    }

    setState(() {
      _isCasting = false;
    });

    // 动画完成后，使用 ViewModel 执行完整的起卦流程
    if (mounted) {
      final viewModel = context.read<LiuYaoViewModel>();
      await viewModel.castByCoin();

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('摇钱法起卦'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '点击"摇卦"按钮，模拟投掷三枚硬币六次',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _yaoNumbers.isEmpty
                  ? const Center(
                      child: Text(
                        '准备开始',
                        style: TextStyle(fontSize: 24, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _yaoNumbers.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              '第${index + 1}爻：${_yaoNumbers[index]}',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isCasting ? null : _cast,
              icon: const Icon(Icons.casino),
              label: Text(_isCasting ? '投掷中...' : '摇卦'),
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
