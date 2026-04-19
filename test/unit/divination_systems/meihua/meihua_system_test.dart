import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/meihua/meihua_system.dart';
import 'package:wanxiang_paipan/divination_systems/meihua/models/meihua_result.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

void main() {
  group('MeiHuaSystem', () {
    late MeiHuaSystem system;

    setUp(() {
      system = MeiHuaSystem();
    });

    group('基本属性', () {
      test('应该返回正确的系统类型', () {
        expect(system.type, DivinationType.meiHua);
      });

      test('应该返回正确的系统名称', () {
        expect(system.name, '梅花易数');
      });

      test('应该返回正确的系统描述', () {
        expect(system.description, contains('梅花易数'));
        expect(system.description, contains('体用'));
      });

      test('应该已启用（isEnabled = true）', () {
        expect(system.isEnabled, true);
      });

      test('应该支持时间起卦、数字起卦和手动输入', () {
        expect(
          system.supportedMethods,
          equals([
            CastMethod.time,
            CastMethod.number,
            CastMethod.manual,
          ]),
        );
      });
    });

    group('validateInput', () {
      test('时间起卦只接受空输入', () {
        expect(system.validateInput(CastMethod.time, {}), true);
        expect(
          system.validateInput(CastMethod.time, {'unexpected': true}),
          false,
        );
      });

      test('数字起卦必须传 upperNumber 与 lowerNumber，且为正整数', () {
        expect(
          system.validateInput(
            CastMethod.number,
            {'upperNumber': 12, 'lowerNumber': 8},
          ),
          true,
        );
        expect(
          system.validateInput(
            CastMethod.number,
            {'upperNumber': 0, 'lowerNumber': 8},
          ),
          false,
        );
        expect(
          system.validateInput(
            CastMethod.number,
            {'number': 123},
          ),
          false,
        );
      });

      test('手动输入必须传合法八卦与动爻', () {
        expect(
          system.validateInput(
            CastMethod.manual,
            {
              'upperTrigram': '艮',
              'lowerTrigram': '离',
              'movingLine': 2,
            },
          ),
          true,
        );
        expect(
          system.validateInput(
            CastMethod.manual,
            {
              'upperTrigram': '天',
              'lowerTrigram': '离',
              'movingLine': 2,
            },
          ),
          false,
        );
        expect(
          system.validateInput(
            CastMethod.manual,
            {
              'upperTrigram': '艮',
              'lowerTrigram': '离',
              'movingLine': 7,
            },
          ),
          false,
        );
      });
    });

    group('cast', () {
      test('时间起卦应该按固定规则生成完整结果', () async {
        final result = await system.cast(
          method: CastMethod.time,
          input: const {},
          castTime: DateTime(2026, 4, 19, 9, 22),
        ) as MeiHuaResult;

        expect(result.castMethod, CastMethod.time);
        expect(result.source.methodLabel, '时间起卦');
        expect(result.source.yearBranch, '午');
        expect(result.source.yearNumber, 7);
        expect(result.source.monthNumber, 3);
        expect(result.source.dayNumber, 3);
        expect(result.source.hourBranch, '巳');
        expect(result.source.hourNumber, 6);
        expect(result.source.upperRawValue, 13);
        expect(result.source.lowerRawValue, 19);
        expect(result.source.movingRawValue, 19);
        expect(result.source.upperNumber, 5);
        expect(result.source.lowerNumber, 3);
        expect(result.source.movingLineNumber, 1);

        expect(result.benGua.name, '风火家人');
        expect(result.bianGua.name, '风山渐');
        expect(result.huGua.name, '火水未济');
        expect(result.movingLine, 1);
        expect(result.movingLineLabel, '初爻');
        expect(result.tiGua.name, '巽');
        expect(result.yongGua.name, '离');
        expect(result.bodyUseRule, '动爻落下卦（1-3爻），下卦为用，上卦为体');
        expect(result.wuXingRelation, '体生用');
        expect(result.getSummary(), '风火家人 → 风山渐 · 体生用');
      });

      test('数字起卦应该按上下数取卦并以合数取动爻', () async {
        final result = await system.cast(
          method: CastMethod.number,
          input: const {
            'upperNumber': 7,
            'lowerNumber': 3,
          },
          castTime: DateTime(2026, 4, 19, 9, 22),
        ) as MeiHuaResult;

        expect(result.source.methodLabel, '数字起卦');
        expect(result.source.upperInputNumber, 7);
        expect(result.source.lowerInputNumber, 3);
        expect(result.source.upperNumber, 7);
        expect(result.source.lowerNumber, 3);
        expect(result.source.movingLineNumber, 4);
        expect(result.benGua.name, '山火贲');
        expect(result.bianGua.name, '离为火');
        expect(result.tiGua.name, '离');
        expect(result.yongGua.name, '艮');
        expect(result.wuXingRelation, '体生用');
      });

      test('手动输入应该直接使用指定卦与动爻', () async {
        final result = await system.cast(
          method: CastMethod.manual,
          input: const {
            'upperTrigram': '艮',
            'lowerTrigram': '离',
            'movingLine': 2,
          },
          castTime: DateTime(2026, 4, 19, 9, 22),
        ) as MeiHuaResult;

        expect(result.source.methodLabel, '手动输入');
        expect(result.source.manualUpperTrigram, '艮');
        expect(result.source.manualLowerTrigram, '离');
        expect(result.benGua.name, '山火贲');
        expect(result.bianGua.name, '山天大畜');
        expect(result.huGua.name, '雷水解');
        expect(result.tiGua.name, '艮');
        expect(result.yongGua.name, '离');
        expect(result.wuXingRelation, '用生体');
      });

      test('非法输入应该抛出 ArgumentError', () async {
        expect(
          () => system.cast(
            method: CastMethod.number,
            input: const {'number': 123},
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('resultFromJson', () {
      test('应该能够从 JSON 反序列化结果', () async {
        final original = await system.cast(
          method: CastMethod.manual,
          input: const {
            'upperTrigram': '艮',
            'lowerTrigram': '离',
            'movingLine': 2,
          },
          castTime: DateTime(2026, 4, 19, 9, 22),
        ) as MeiHuaResult;

        final json = original.toJson();
        final result = system.resultFromJson(json) as MeiHuaResult;

        expect(result.systemType, DivinationType.meiHua);
        expect(result.castMethod, CastMethod.manual);
        expect(result.benGua.name, '山火贲');
        expect(result.bianGua.name, '山天大畜');
        expect(result.getSummary(), '山火贲 → 山天大畜 · 用生体');
      });
    });
  });

  group('MeiHuaResult', () {
    late MeiHuaResult result;

    setUp(() {
      result = MeiHuaResult(
        id: 'test-id',
        castTime: DateTime(2026, 4, 19, 9, 22),
        castMethod: CastMethod.manual,
        lunarInfo: const LunarInfo(
          yueJian: '辰',
          riGan: '癸',
          riZhi: '亥',
          riGanZhi: '癸亥',
          hourGanZhi: '丁巳',
          kongWang: ['子', '丑'],
          yearGanZhi: '丙午',
          monthGanZhi: '壬辰',
          solarTerm: '谷雨',
        ),
        source: const MeiHuaSource(
          methodLabel: '手动输入',
          upperNumber: 7,
          lowerNumber: 3,
          movingLineNumber: 2,
          manualUpperTrigram: '艮',
          manualLowerTrigram: '离',
        ),
        benGua: _hexagram(
            '山火贲',
            '101001',
            _trigram('艮', '山', '土', 7, [0, 0, 1]),
            _trigram('离', '火', '火', 3, [1, 0, 1])),
        bianGua: _hexagram(
            '山天大畜',
            '111001',
            _trigram('艮', '山', '土', 7, [0, 0, 1]),
            _trigram('乾', '天', '金', 1, [1, 1, 1])),
        huGua: _hexagram('雷水解', '010100', _trigram('震', '雷', '木', 4, [1, 0, 0]),
            _trigram('坎', '水', '水', 6, [0, 1, 0])),
        movingLine: 2,
        tiGua: _trigram('艮', '山', '土', 7, [0, 0, 1]),
        yongGua: _trigram('离', '火', '火', 3, [1, 0, 1]),
        bodyUseRule: '动爻落下卦（1-3爻），下卦为用，上卦为体',
        wuXingRelation: '用生体',
      );
    });

    test('应该返回正确的系统类型', () {
      expect(result.systemType, DivinationType.meiHua);
    });

    test('应该返回正确的摘要', () {
      expect(result.getSummary(), '山火贲 → 山天大畜 · 用生体');
    });

    test('应该能够序列化为 JSON', () {
      final json = result.toJson();

      expect(json['id'], 'test-id');
      expect(json['systemType'], 'meihua');
      expect(json['castMethod'], 'manual');
      expect(json['source'], isA<Map<String, dynamic>>());
      expect(json['benGua'], isA<Map<String, dynamic>>());
      expect(json['tiGua'], isA<Map<String, dynamic>>());
    });

    test('应该能够从 JSON 反序列化', () {
      final deserialized = MeiHuaResult.fromJson(result.toJson());

      expect(deserialized.id, result.id);
      expect(deserialized.castTime, result.castTime);
      expect(deserialized.castMethod, result.castMethod);
      expect(deserialized.benGua.name, result.benGua.name);
      expect(deserialized.bianGua.name, result.bianGua.name);
      expect(deserialized.wuXingRelation, result.wuXingRelation);
    });
  });
}

MeiHuaTrigram _trigram(
  String name,
  String symbol,
  String wuXing,
  int number,
  List<int> lines,
) {
  return MeiHuaTrigram(
    key: name,
    name: name,
    symbol: symbol,
    wuXing: wuXing,
    number: number,
    lines: lines,
  );
}

MeiHuaHexagram _hexagram(
  String name,
  String code,
  MeiHuaTrigram upper,
  MeiHuaTrigram lower,
) {
  return MeiHuaHexagram(
    code: code,
    name: name,
    upperTrigram: upper,
    lowerTrigram: lower,
    lines: [...lower.lines, ...upper.lines],
  );
}
