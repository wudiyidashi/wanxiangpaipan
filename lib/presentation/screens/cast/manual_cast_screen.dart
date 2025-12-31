import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../divination_systems/liuyao/viewmodels/liuyao_viewmodel.dart';
import '../../../presentation/divination_ui_registry.dart';

/// 手动输入起卦界面
class ManualCastScreen extends StatefulWidget {
  const ManualCastScreen({super.key});

  @override
  State<ManualCastScreen> createState() => _ManualCastScreenState();
}

class _ManualCastScreenState extends State<ManualCastScreen> {
  final TextEditingController _questionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // 六个爻的值，初爻(index 0)到六爻(index 5)，null 表示未选择
  final List<int?> _yaoValues = List.filled(6, null);

  bool _isProcessing = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  /// 选择日期
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// 选择时间
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  /// 检查是否所有爻位都已选择
  bool get _allYaosSelected => _yaoValues.every((v) => v != null);

  /// 完成起卦
  Future<void> _finishCast() async {
    if (_isProcessing || !_allYaosSelected) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final castTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // 使用 ViewModel 执行完整的起卦流程
      final viewModel = context.read<LiuYaoViewModel>();

      final question = _questionController.text.trim();
      await viewModel.castByManualYaoNumbers(
        _yaoValues.cast<int>(), // 已经验证全部非 null
        castTime: castTime,
        question: question.isEmpty ? null : question,
      );

      // 检查是否有错误
      if (viewModel.hasError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(viewModel.errorMessage!)),
          );
        }
        return;
      }

      // 导航到结果页面
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
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('手动输入'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 占问事宜区域
            _buildQuestionSection(),
            const SizedBox(height: 24),

            // 排盘日期时间
            _buildDateTimeSection(),
            const SizedBox(height: 24),

            // 爻位选择区域
            _buildYaoSelectionSection(),
            const SizedBox(height: 24),

            // 排盘按钮
            ElevatedButton(
              onPressed:
                  _allYaosSelected && !_isProcessing ? _finishCast : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isProcessing ? '排盘中...' : '排盘',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建占问事宜区域
  Widget _buildQuestionSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.question_answer_outlined,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '占问事宜',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: '占问内容（可选）',
                hintText: '请输入您想占卜的问题或事宜',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建日期时间选择区域
  Widget _buildDateTimeSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '排盘时间',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建爻位选择区域
  Widget _buildYaoSelectionSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.casino_outlined,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '爻位选择',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            const Text(
              '从上到下依次选择六个爻位的硬币组合',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            // 从上到下：六爻、五爻、四爻、三爻、二爻、初爻
            ...List.generate(6, (displayIndex) {
              // displayIndex: 0=六爻, 1=五爻, ..., 5=初爻
              // 实际存储索引：5=六爻, 4=五爻, ..., 0=初爻
              final actualIndex = 5 - displayIndex;
              final yaoName = _getYaoName(actualIndex);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildYaoSelector(actualIndex, yaoName),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 获取爻位名称
  String _getYaoName(int index) {
    const names = ['初爻', '二爻', '三爻', '四爻', '五爻', '六爻'];
    return names[index];
  }

  /// 构建单个爻位选择器
  Widget _buildYaoSelector(int index, String yaoName) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            yaoName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _yaoValues[index],
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              hintText: '请选择...',
              filled: true,
              fillColor: _yaoValues[index] != null
                  ? Colors.green.shade50
                  : Colors.grey.shade50,
            ),
            items: const [
              DropdownMenuItem(value: 6, child: Text('背背正 (老阴 ▬ ▬)')),
              DropdownMenuItem(value: 7, child: Text('背正正 (少阳 ▬▬▬)')),
              DropdownMenuItem(value: 8, child: Text('正正正 (少阴 ▬ ▬)')),
              DropdownMenuItem(value: 9, child: Text('背背背 (老阳 ▬▬▬)')),
            ],
            onChanged: (value) {
              setState(() {
                _yaoValues[index] = value;
              });
            },
          ),
        ),
      ],
    );
  }
}
