import 'package:flutter/material.dart';
import 'coin_cast_screen.dart';
import 'time_cast_screen.dart';
import 'manual_cast_screen.dart';

/// 起卦方式选择界面
class CastMethodScreen extends StatelessWidget {
  const CastMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择起卦方式'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMethodCard(
              context,
              title: '摇钱法',
              description: '模拟投掷硬币，随机生成卦象',
              icon: Icons.monetization_on,
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(builder: (_) => const CoinCastScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildMethodCard(
              context,
              title: '时间起卦',
              description: '根据当前时间计算卦象',
              icon: Icons.access_time,
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(builder: (_) => const TimeCastScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildMethodCard(
              context,
              title: '手动输入',
              description: '手动输入硬币正反面',
              icon: Icons.touch_app,
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const ManualCastScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
