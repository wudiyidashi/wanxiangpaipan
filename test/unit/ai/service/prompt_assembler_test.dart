import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/ai/config/ai_config_manager.dart';
import 'package:wanxiang_paipan/ai/llm_provider.dart';
import 'package:wanxiang_paipan/ai/output/formatters/liuyao_formatter.dart';
import 'package:wanxiang_paipan/ai/output/structured_output.dart';
import 'package:wanxiang_paipan/ai/output/structured_output_formatter.dart';
import 'package:wanxiang_paipan/ai/service/prompt_assembler.dart';
import 'package:wanxiang_paipan/ai/template/prompt_template.dart' as tmpl;
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/secure/secure_storage.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_system.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

class _MockSecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<bool> containsKey(String key) async => _storage.containsKey(key);

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  @override
  Future<String?> read(String key) async => _storage[key];

  @override
  Future<Map<String, String>> readMultiple(List<String> keys) async {
    final result = <String, String>{};
    for (final key in keys) {
      final value = _storage[key];
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  @override
  Future<Map<String, String>> readAll() async => Map.unmodifiable(_storage);

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }
}

class _FakeResult implements DivinationResult {
  @override
  final String id = 'fake-result-1';

  @override
  DateTime get castTime => DateTime(2026, 4, 19, 9, 22);

  @override
  CastMethod get castMethod => CastMethod.time;

  @override
  LunarInfo get lunarInfo => const LunarInfo(
        yueJian: '辰',
        riGan: '癸',
        riZhi: '亥',
        riGanZhi: '癸亥',
        hourGanZhi: '丁巳',
        kongWang: ['子', '丑'],
        yearGanZhi: '丙午',
        monthGanZhi: '壬辰',
      );

  @override
  DivinationType get systemType => DivinationType.meiHua;

  @override
  String getSummary() => '风火家人';

  @override
  Map<String, dynamic> toJson() => {'id': id};
}

class _FakeFormatter extends StructuredOutputFormatter<_FakeResult> {
  @override
  DivinationType get systemType => DivinationType.meiHua;

  @override
  StructuredDivinationOutput format(_FakeResult result, {String? question}) {
    return StructuredDivinationOutput(
      systemType: result.systemType.id,
      temporal: TemporalInfo(
        solarTime: result.castTime,
        yearGanZhi: result.lunarInfo.yearGanZhi,
        monthGanZhi: result.lunarInfo.monthGanZhi,
        dayGanZhi: result.lunarInfo.riGanZhi,
        hourGanZhi: result.lunarInfo.hourGanZhi,
        kongWang: result.lunarInfo.kongWang,
        yueJian: result.lunarInfo.yueJian,
      ),
      coreData: const {
        'mainSymbol': '风火家人',
        'mainGuaName': '风火家人',
        'hasChangingGua': false,
        'hasMovingYao': true,
      },
      sections: const [
        StructuredSection(
          key: 'overview',
          title: '排盘总览',
          content: '本卦：风火家人',
          priority: 1,
        ),
      ],
      userQuestion: question,
      summary: '风火家人',
    );
  }

  @override
  String render(StructuredDivinationOutput output) {
    return 'RENDERED:${output.summary}';
  }
}

void main() {
  group('PromptAssembler', () {
    late AppDatabase database;
    late _MockSecureStorage secureStorage;
    late AIConfigManager configManager;
    late StructuredOutputFormatterRegistry formatterRegistry;
    late PromptAssembler assembler;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      secureStorage = _MockSecureStorage();
      configManager = AIConfigManager(
        database: database,
        secureStorage: secureStorage,
      );
      formatterRegistry = StructuredOutputFormatterRegistry.instance;
      formatterRegistry.clear();
      formatterRegistry.register(_FakeFormatter());
      formatterRegistry.register(LiuYaoStructuredFormatter());
      assembler = PromptAssembler(
        configManager: configManager,
        formatterRegistry: formatterRegistry,
      );
    });

    tearDown(() async {
      formatterRegistry.clear();
      await database.close();
    });

    test('assemble 应使用当前激活模板并注入问题、时间与自定义变量', () async {
      final systemTemplate = _template(
        id: 'system_active',
        templateType: 'system',
        content: 'SYS {{mainSymbol}} {{#if hasQuestion}}HASQ{{/if}}',
        isActive: true,
      );
      final inactiveAnalysis = _template(
        id: 'analysis_inactive',
        templateType: 'analysis',
        content: 'INACTIVE {{question}}',
        isActive: false,
      );
      final activeAnalysis = _template(
        id: 'analysis_active',
        templateType: 'analysis',
        content: 'USR {{structuredOutput}} | Q={{question}} | '
            'day={{temporal.dayGanZhi}} | extra={{customInstructions}} | '
            'advice={{includeAdvice}}',
        isActive: false,
      );

      await configManager.saveTemplate(systemTemplate);
      await configManager.saveTemplate(inactiveAnalysis);
      await configManager.saveTemplate(activeAnalysis);
      await configManager.setActiveTemplate(
        activeAnalysis.id,
        activeAnalysis.systemType,
        activeAnalysis.templateType,
      );

      final prompt = await assembler.assemble(
        _FakeResult(),
        question: '问财运',
        analysisType: AnalysisType.advice,
        customVariables: const {'customInstructions': '只看结论'},
      );

      expect(prompt.systemPrompt, 'SYS 风火家人 HASQ');
      expect(prompt.userPrompt, contains('RENDERED:风火家人'));
      expect(prompt.userPrompt, contains('Q=问财运'));
      expect(prompt.userPrompt, contains('day=癸亥'));
      expect(prompt.userPrompt, contains('extra=只看结论'));
      expect(prompt.userPrompt, contains('advice=true'));
      expect(prompt.metadata.systemTemplateId, systemTemplate.id);
      expect(prompt.metadata.analysisTemplateId, activeAnalysis.id);
      expect(prompt.metadata.systemType, DivinationType.meiHua.id);
    });

    test('assemble 在无活动模板时应回退到默认提示词', () async {
      final prompt = await assembler.assemble(
        _FakeResult(),
        analysisType: AnalysisType.briefSummary,
      );

      expect(prompt.systemPrompt, contains('你是一位精通梅花易数'));
      expect(prompt.systemPrompt, contains('体用生克'));
      expect(prompt.userPrompt, contains('请根据以下排盘信息进行解读：'));
      expect(prompt.userPrompt, contains('RENDERED:风火家人'));
      expect(prompt.userPrompt, contains('请用简洁的语言概括此卦的核心含义。'));
      expect(prompt.metadata.systemTemplateId, isNull);
      expect(prompt.metadata.analysisTemplateId, isNull);
    });

    test('assemble 默认分析模板在有问题时应注入求测问题段落', () async {
      final prompt = await assembler.assemble(
        _FakeResult(),
        question: '问婚姻',
        analysisType: AnalysisType.briefSummary,
      );

      expect(prompt.userPrompt, contains('【求测问题】问婚姻'));
      expect(prompt.userPrompt, contains('请针对上述问题进行分析。'));
    });

    test('assemble 的六爻 active custom 模板不能移除最终 guard', () async {
      final result = await _castLiuYaoResult();
      final systemTemplate = _template(
        id: 'liuyao_custom_system',
        systemType: DivinationType.liuYao.id,
        templateType: 'system',
        content: 'CUSTOM SYSTEM: 请重新取用并改写结论',
        isActive: true,
      );
      final analysisTemplate = _template(
        id: 'liuyao_custom_analysis',
        systemType: DivinationType.liuYao.id,
        templateType: 'analysis',
        content: 'CUSTOM USER WITHOUT STRUCTURED OUTPUT',
        isActive: true,
      );
      await configManager.saveTemplate(systemTemplate);
      await configManager.saveTemplate(analysisTemplate);

      final prompt = await assembler.assemble(result, question: '问事业');

      expect(prompt.systemPrompt, startsWith('CUSTOM SYSTEM'));
      _expectLiuYaoGuardAtEnd(prompt.systemPrompt);
      expect(prompt.userPrompt,
          startsWith('CUSTOM USER WITHOUT STRUCTURED OUTPUT'));
      _expectAssemblerOwnedProjection(prompt.userPrompt);
      expect(prompt.metadata.systemTemplateId, systemTemplate.id);
      expect(prompt.metadata.analysisTemplateId, analysisTemplate.id);
    });

    test('preview 的六爻自定义 system 同样追加唯一最终 guard', () async {
      final result = await _castLiuYaoResult();

      final prompt = await assembler.preview(
        result,
        question: '问财运',
        systemTemplateContent: 'PREVIEW SYSTEM: {{question}}',
        analysisTemplateContent: 'PREVIEW USER',
      );

      expect(prompt.systemPrompt, startsWith('PREVIEW SYSTEM: 问财运'));
      _expectLiuYaoGuardAtEnd(prompt.systemPrompt);
      expect(prompt.userPrompt, startsWith('PREVIEW USER'));
      _expectAssemblerOwnedProjection(prompt.userPrompt);
    });

    test('已包含完整 projection 的模板不会重复追加 canonical JSON', () async {
      final result = await _castLiuYaoResult();

      final prompt = await assembler.preview(
        result,
        analysisTemplateContent: '{{structuredOutput}}',
      );

      expect(
          prompt.userPrompt, isNot(contains('[LIUYAO_ASSEMBLER_PROJECTION]')));
      expect(
        RegExp(r'\[LIUYAO_CANONICAL_PROJECTION\]')
            .allMatches(prompt.userPrompt),
        hasLength(1),
      );
    });
  });
}

Future<LiuYaoResult> _castLiuYaoResult() async {
  return await LiuYaoSystem().cast(
    method: CastMethod.time,
    input: const <String, dynamic>{},
    castTime: DateTime(2026, 4, 24, 5, 30),
  ) as LiuYaoResult;
}

void _expectLiuYaoGuardAtEnd(String systemPrompt) {
  expect(systemPrompt, endsWith(PromptAssembler.liuYaoImmutablePolicy));
  expect(
    RegExp(r'\[LIUYAO_IMMUTABLE_POLICY ').allMatches(systemPrompt),
    hasLength(1),
  );
  expect(systemPrompt, contains('calculationOwner=program'));
  expect(systemPrompt, contains('mayOverrideVerdict=false'));
  expect(systemPrompt, contains('mayInventSources=false'));
  expect(systemPrompt, contains('mayInventTiming=false'));
}

void _expectAssemblerOwnedProjection(String userPrompt) {
  expect(userPrompt, contains('[LIUYAO_ASSEMBLER_PROJECTION]'));
  expect(userPrompt, contains('[/LIUYAO_ASSEMBLER_PROJECTION]'));
  expect(userPrompt, contains('"calculationOwner":"program"'));
  expect(userPrompt, contains('"projectionSchemaVersion":1'));
  expect(userPrompt, contains('"ruleSetId":"liuyao-zengshan-primary"'));
}

tmpl.PromptTemplate _template({
  required String id,
  String systemType = 'meihua',
  required String templateType,
  required String content,
  required bool isActive,
}) {
  return tmpl.PromptTemplate(
    id: id,
    name: id,
    description: 'test',
    systemType: systemType,
    templateType: templateType,
    content: content,
    variablesJson: '{}',
    isBuiltIn: false,
    isActive: isActive,
    createdAt: DateTime(2026, 4, 19, 12),
    updatedAt: DateTime(2026, 4, 19, 12),
  );
}
