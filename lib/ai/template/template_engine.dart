/// 提示词模板引擎
///
/// 解析和渲染提示词模板，支持：
/// - 变量替换: {{variable}}
/// - 属性访问: {{object.property}}
/// - 条件块: {{#if condition}}...{{/if}}
/// - 循环块: {{#each list}}...{{/each}}
library;

import 'prompt_template.dart';

/// 提示词模板引擎
class PromptTemplateEngine {
  /// 变量匹配模式: {{variable}} 或 {{object.property}}
  static final _variablePattern = RegExp(r'\{\{(\w+)(?:\.(\w+))?\}\}');

  /// 条件块匹配模式: {{#if condition}}...{{/if}}
  static final _conditionalPattern = RegExp(
    r'\{\{#if\s+(\w+)\}\}(.*?)\{\{/if\}\}',
    dotAll: true,
  );

  /// else 条件块匹配模式: {{#if condition}}...{{else}}...{{/if}}
  static final _conditionalElsePattern = RegExp(
    r'\{\{#if\s+(\w+)\}\}(.*?)\{\{else\}\}(.*?)\{\{/if\}\}',
    dotAll: true,
  );

  /// 循环块匹配模式: {{#each list}}...{{/each}}
  static final _loopPattern = RegExp(
    r'\{\{#each\s+(\w+)\}\}(.*?)\{\{/each\}\}',
    dotAll: true,
  );

  /// 渲染模板
  ///
  /// 参数：
  /// - [template]: 模板字符串
  /// - [context]: 上下文变量
  ///
  /// 返回渲染后的字符串
  String render(String template, Map<String, dynamic> context) {
    var result = template;

    // 1. 处理带 else 的条件块
    result = _processConditionalsWithElse(result, context);

    // 2. 处理简单条件块
    result = _processConditionals(result, context);

    // 3. 处理循环块
    result = _processLoops(result, context);

    // 4. 替换变量
    result = _replaceVariables(result, context);

    return result.trim();
  }

  String _processConditionalsWithElse(
    String template,
    Map<String, dynamic> context,
  ) {
    return template.replaceAllMapped(_conditionalElsePattern, (match) {
      final variable = match.group(1)!;
      final ifContent = match.group(2)!;
      final elseContent = match.group(3)!;
      final value = _resolveValue(variable, context);

      if (_isTruthy(value)) {
        return render(ifContent, context);
      } else {
        return render(elseContent, context);
      }
    });
  }

  String _processConditionals(String template, Map<String, dynamic> context) {
    return template.replaceAllMapped(_conditionalPattern, (match) {
      final variable = match.group(1)!;
      final content = match.group(2)!;
      final value = _resolveValue(variable, context);

      if (_isTruthy(value)) {
        return render(content, context);
      }
      return '';
    });
  }

  String _processLoops(String template, Map<String, dynamic> context) {
    return template.replaceAllMapped(_loopPattern, (match) {
      final variable = match.group(1)!;
      final content = match.group(2)!;
      final value = _resolveValue(variable, context);

      if (value is List) {
        final results = <String>[];
        for (var i = 0; i < value.length; i++) {
          final itemContext = Map<String, dynamic>.from(context);
          itemContext['item'] = value[i];
          itemContext['index'] = i;
          itemContext['isFirst'] = i == 0;
          itemContext['isLast'] = i == value.length - 1;
          results.add(render(content, itemContext));
        }
        return results.join('\n');
      }
      return '';
    });
  }

  String _replaceVariables(String template, Map<String, dynamic> context) {
    return template.replaceAllMapped(_variablePattern, (match) {
      final variable = match.group(1)!;
      final property = match.group(2);

      var value = _resolveValue(variable, context);
      if (property != null && value is Map) {
        value = value[property];
      }

      return value?.toString() ?? '';
    });
  }

  dynamic _resolveValue(String path, Map<String, dynamic> context) {
    final parts = path.split('.');
    dynamic value = context;

    for (final part in parts) {
      if (value is Map) {
        value = value[part];
      } else {
        return null;
      }
    }

    return value;
  }

  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is num) return value != 0;
    return true;
  }

  /// 提取模板中的变量名
  Set<String> extractVariables(String template) {
    final variables = <String>{};

    for (final match in _variablePattern.allMatches(template)) {
      variables.add(match.group(1)!);
    }

    // 也从条件块中提取
    for (final match in _conditionalPattern.allMatches(template)) {
      variables.add(match.group(1)!);
    }
    for (final match in _conditionalElsePattern.allMatches(template)) {
      variables.add(match.group(1)!);
    }

    // 从循环块中提取
    for (final match in _loopPattern.allMatches(template)) {
      variables.add(match.group(1)!);
    }

    return variables;
  }

  /// 验证模板语法
  TemplateValidationResult validate(String template) {
    final errors = <String>[];
    final warnings = <String>[];

    // 检查条件块闭合
    final ifOpens = RegExp(r'\{\{#if\s+').allMatches(template).length;
    final ifCloses = RegExp(r'\{\{/if\}\}').allMatches(template).length;
    if (ifOpens != ifCloses) {
      errors.add('条件块未正确闭合: {{#if}} 数量($ifOpens) != {{/if}} 数量($ifCloses)');
    }

    // 检查循环块闭合
    final eachOpens = RegExp(r'\{\{#each\s+').allMatches(template).length;
    final eachCloses = RegExp(r'\{\{/each\}\}').allMatches(template).length;
    if (eachOpens != eachCloses) {
      errors.add(
          '循环块未正确闭合: {{#each}} 数量($eachOpens) != {{/each}} 数量($eachCloses)');
    }

    // 检查 else 是否在 if 块内
    final elseCount = RegExp(r'\{\{else\}\}').allMatches(template).length;
    if (elseCount > ifOpens) {
      errors.add('{{else}} 数量超过了 {{#if}} 块数量');
    }

    // 检查变量名格式
    for (final match in _variablePattern.allMatches(template)) {
      final varName = match.group(1)!;
      if (varName.startsWith('_')) {
        warnings.add('变量名 "$varName" 以下划线开头，可能不是预期的变量');
      }
    }

    final variables = extractVariables(template);

    return TemplateValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      variables: variables,
    );
  }

  /// 预览模板渲染效果
  ///
  /// 使用示例数据预览模板效果
  String preview(String template, {Map<String, dynamic>? sampleData}) {
    final context = sampleData ?? _getDefaultSampleData();
    return render(template, context);
  }

  Map<String, dynamic> _getDefaultSampleData() {
    return {
      'structuredOutput': '[结构化排盘数据将在此处显示]',
      'question': '示例问题：今日求财是否顺利？',
      'hasMovingYao': true,
      'hasChangingGua': true,
      'mainGuaName': '天火同人',
      'changingGuaName': '天雷无妄',
      'movingYaoPositions': [2, 5],
      'customInstructions': '',
      'includeAdvice': true,
    };
  }
}
