import 'package:flutter/material.dart';
import '../../../domain/services/gua_calculator.dart';
import '../../../domain/services/liushen_service.dart';
import '../../../domain/services/shared/lunar_service.dart';
import '../../../domain/services/qigua_service.dart';

/// 功能测试界面
class TestScreen extends StatefulWidget {
  const TestScreen({super.key, this.yaoNumbers});

  final List<int>? yaoNumbers;

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late String _result;

  void _testLunar() {
    final lunarInfo = LunarService.getLunarInfo(DateTime.now());
    setState(() {
      _result = '''
农历信息测试：
年干支：${lunarInfo.yearGanZhi}
月干支：${lunarInfo.monthGanZhi}
日干支：${lunarInfo.riGanZhi}
月建：${lunarInfo.yueJian}
空亡：${lunarInfo.kongWang.join('、')}
节气：${lunarInfo.solarTerm ?? '无'}
''';
    });
  }

  void _testLiuShen() {
    final dayGan = LunarService.getDayGan(DateTime.now());
    final liuShen = LiuShenService.calculateLiuShen(dayGan);
    setState(() {
      _result = '''
六神计算测试：
日干：$dayGan
六神顺序：
${liuShen.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}
''';
    });
  }

  void _testQiGua() {
    final yaoNumbers = QiGuaService.coinCast();
    setState(() {
      _result = '''
起卦测试（摇钱法）：
${yaoNumbers.asMap().entries.map((e) => '第${e.key + 1}爻：${e.value}').join('\n')}
''';
    });
  }

  void _testGuaCalculator() {
    final yaoNumbers = [7, 8, 7, 9, 8, 7];
    final gua = GuaCalculator.calculateGua(yaoNumbers);
    setState(() {
      _result = '''
卦象计算测试：
卦名：${gua.name}
八宫：${gua.baGong.name}
世爻：第${gua.seYaoPosition}爻
应爻：第${gua.yingYaoPosition}爻

六爻详情：
${gua.yaos.asMap().entries.map((e) {
        final yao = e.value;
        return '第${e.key + 1}爻：${yao.number.name} ${yao.branch}${yao.stem} ${yao.wuXing.name} ${yao.liuQin.name}${yao.isSeYao ? ' [世]' : ''}${yao.isYingYao ? ' [应]' : ''}';
      }).join('\n')}
''';
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.yaoNumbers != null) {
      final gua = GuaCalculator.calculateGua(widget.yaoNumbers!);
      _result = '''
起卦结果：
爻数：${widget.yaoNumbers!.join(', ')}

卦名：${gua.name}
八宫：${gua.baGong.name}
世爻：第${gua.seYaoPosition}爻
应爻：第${gua.yingYaoPosition}爻

六爻详情：
${gua.yaos.asMap().entries.map((e) {
        final yao = e.value;
        return '第${e.key + 1}爻：${yao.number.name} ${yao.branch}${yao.stem} ${yao.wuXing.name} ${yao.liuQin.name}${yao.isSeYao ? ' [世]' : ''}${yao.isYingYao ? ' [应]' : ''}';
      }).join('\n')}
''';
    } else {
      _result = '点击按钮测试功能';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('功能测试'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _testLunar,
              child: const Text('测试农历计算'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testLiuShen,
              child: const Text('测试六神计算'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testQiGua,
              child: const Text('测试起卦功能'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testGuaCalculator,
              child: const Text('测试卦象计算'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
