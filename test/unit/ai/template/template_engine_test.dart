import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/template/template_engine.dart';

void main() {
  group('PromptTemplateEngine', () {
    late PromptTemplateEngine engine;

    setUp(() {
      engine = PromptTemplateEngine();
    });

    test('render 应支持变量、条件和循环组合渲染', () {
      const template = '''
标题：{{title}}
{{#if hasQuestion}}问：{{question}}{{else}}无问句{{/if}}
{{#each items}}- {{item.name}}#{{index}}
{{/each}}''';

      final rendered = engine.render(template, {
        'title': '排盘',
        'hasQuestion': true,
        'question': '问财',
        'items': [
          {'name': '甲'},
          {'name': '乙'},
        ],
      });

      expect(
        rendered,
        '标题：排盘\n问：问财\n- 甲#0\n- 乙#1',
      );
    });

    test('extractVariables 应提取普通变量、条件变量和循环变量', () {
      final variables = engine.extractVariables(
        '{{title}}{{#if hasQuestion}}{{question}}{{/if}}'
        '{{#each items}}{{item.name}}{{/each}}',
      );

      expect(
        variables,
        containsAll(
            <String>['title', 'hasQuestion', 'question', 'items', 'item']),
      );
    });

    test('validate 应报告未闭合块并提示可疑变量名', () {
      final result = engine.validate('{{#if ok}}{{_hidden}}{{else}}内容');

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains(predicate<String>((item) => item.contains('条件块未正确闭合'))),
      );
      expect(
        result.warnings,
        contains(predicate<String>((item) => item.contains('_hidden'))),
      );
    });
  });
}
