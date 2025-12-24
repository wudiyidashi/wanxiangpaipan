/// 结构化输出格式化器
///
/// 定义将 DivinationResult 转换为结构化输出的接口和注册表。
library;

import '../../domain/divination_system.dart';
import 'structured_output.dart';

/// 结构化输出格式化器接口
///
/// 每个术数系统都需要实现此接口，将其排盘结果转换为标准的结构化输出格式。
abstract class StructuredOutputFormatter<T extends DivinationResult> {
  /// 对应的术数系统类型
  DivinationType get systemType;

  /// 将排盘结果转换为结构化输出
  ///
  /// 参数：
  /// - [result]: 排盘结果
  /// - [question]: 用户问题（可选）
  ///
  /// 返回结构化输出对象
  StructuredDivinationOutput format(T result, {String? question});

  /// 将结构化输出渲染为纯文本
  ///
  /// 参数：
  /// - [output]: 结构化输出对象
  ///
  /// 返回格式化的文本，用于传递给 LLM
  String render(StructuredDivinationOutput output);

  /// 渲染时间信息段落
  String renderTemporalInfo(TemporalInfo temporal) {
    final buffer = StringBuffer();
    buffer.writeln('【时间】');
    buffer.writeln('公历: ${_formatDateTime(temporal.solarTime)}');
    buffer.writeln('干支: ${temporal.yearGanZhi}年 '
        '${temporal.monthGanZhi}月 ${temporal.dayGanZhi}日');
    if (temporal.hourGanZhi != null) {
      buffer.writeln('时辰: ${temporal.hourGanZhi}');
    }
    if (temporal.yueJian != null) {
      buffer.writeln('月建: ${temporal.yueJian}');
    }
    buffer.writeln('空亡: ${temporal.kongWang.join("、")}');
    if (temporal.solarTerm != null) {
      buffer.writeln('节气: ${temporal.solarTerm}');
    }
    return buffer.toString();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}年${dt.month}月${dt.day}日 '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 结构化输出格式化器注册表
///
/// 管理所有术数系统的格式化器。
class StructuredOutputFormatterRegistry {
  static final StructuredOutputFormatterRegistry _instance =
      StructuredOutputFormatterRegistry._();
  static StructuredOutputFormatterRegistry get instance => _instance;

  StructuredOutputFormatterRegistry._();

  final Map<DivinationType, StructuredOutputFormatter> _formatters = {};

  /// 注册格式化器
  void register(StructuredOutputFormatter formatter) {
    _formatters[formatter.systemType] = formatter;
  }

  /// 获取格式化器
  ///
  /// 抛出 [StateError] 如果格式化器不存在
  StructuredOutputFormatter getFormatter(DivinationType type) {
    final formatter = _formatters[type];
    if (formatter == null) {
      throw StateError('No formatter registered for ${type.displayName}');
    }
    return formatter;
  }

  /// 检查是否已注册指定类型的格式化器
  bool hasFormatter(DivinationType type) {
    return _formatters.containsKey(type);
  }

  /// 获取所有已注册的格式化器类型
  List<DivinationType> get registeredTypes => _formatters.keys.toList();

  /// 格式化排盘结果
  ///
  /// 自动根据结果类型选择对应的格式化器
  StructuredDivinationOutput formatResult(
    DivinationResult result, {
    String? question,
  }) {
    final formatter = getFormatter(result.systemType);
    return formatter.format(result, question: question);
  }

  /// 渲染排盘结果为文本
  ///
  /// 自动根据结果类型选择对应的格式化器
  String renderResult(DivinationResult result, {String? question}) {
    final formatter = getFormatter(result.systemType);
    final output = formatter.format(result, question: question);
    return formatter.render(output);
  }

  /// 清空所有注册
  void clear() {
    _formatters.clear();
  }
}
