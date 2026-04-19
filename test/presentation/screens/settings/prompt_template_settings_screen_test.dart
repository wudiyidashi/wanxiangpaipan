import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/template/prompt_template.dart' as tmpl;
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/presentation/screens/settings/prompt_template_settings_screen.dart';
import 'package:wanxiang_paipan/presentation/screens/settings/prompt_template_settings_viewmodel.dart';

class _FakePromptTemplateSettingsService
    implements PromptTemplateSettingsService {
  _FakePromptTemplateSettingsService(List<tmpl.PromptTemplate> templates)
      : _templates = List<tmpl.PromptTemplate>.from(templates);

  final List<tmpl.PromptTemplate> _templates;
  final List<tmpl.PromptTemplate> savedTemplates = [];

  @override
  Future<List<tmpl.PromptTemplate>> getAllTemplates() async {
    return List<tmpl.PromptTemplate>.from(_templates);
  }

  @override
  Future<void> saveTemplate(tmpl.PromptTemplate template) async {
    savedTemplates.add(template);
    final index = _templates.indexWhere((item) => item.id == template.id);
    if (index >= 0) {
      _templates[index] = template;
    } else {
      _templates.add(template);
    }
  }
}

void main() {
  group('PromptTemplateSettingsScreen', () {
    testWidgets('按系统分组展示模板并支持编辑保存', (tester) async {
      final service = _FakePromptTemplateSettingsService([
        _createTemplate(
          id: 'liuyao-analysis',
          systemType: DivinationType.liuYao.id,
          name: '六爻分析模板',
          content: '原始六爻内容',
          isBuiltIn: true,
        ),
        _createTemplate(
          id: 'meihua-summary',
          systemType: DivinationType.meiHua.id,
          name: '梅花摘要模板',
          content: '原始梅花内容',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: PromptTemplateSettingsScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('模板列表'), findsOneWidget);
      expect(find.text('六爻'), findsOneWidget);
      expect(find.text('梅花易数'), findsOneWidget);
      expect(find.text('六爻分析模板'), findsOneWidget);
      expect(find.text('梅花摘要模板'), findsOneWidget);

      await tester.tap(find.text('六爻分析模板'));
      await tester.pumpAndSettle();

      expect(find.text('编辑模板'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '六爻分析模板-已改');
      await tester.pump();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(service.savedTemplates, hasLength(1));
      expect(service.savedTemplates.single.name, '六爻分析模板-已改');
      expect(find.text('模板已保存'), findsOneWidget);
      expect(find.text('六爻分析模板-已改'), findsOneWidget);
    });

    testWidgets('无模板时展示空状态', (tester) async {
      final service = _FakePromptTemplateSettingsService(const []);

      await tester.pumpWidget(
        MaterialApp(
          home: PromptTemplateSettingsScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('暂无模板'), findsOneWidget);
    });
  });
}

tmpl.PromptTemplate _createTemplate({
  required String id,
  required String systemType,
  required String name,
  required String content,
  bool isBuiltIn = false,
}) {
  return tmpl.PromptTemplate(
    id: id,
    name: name,
    description: 'test template',
    systemType: systemType,
    templateType: tmpl.PromptTemplateType.analysis.id,
    content: content,
    variablesJson: '{}',
    isBuiltIn: isBuiltIn,
    isActive: true,
    createdAt: DateTime(2026, 4, 19, 9, 0),
    updatedAt: DateTime(2026, 4, 19, 9, 0),
  );
}
