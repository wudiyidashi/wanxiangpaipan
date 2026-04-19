import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/models/xiaoliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/xiaoliuren_system.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

void main() {
  group('XiaoLiuRenSystem', () {
    late XiaoLiuRenSystem system;

    setUp(() {
      system = XiaoLiuRenSystem();
    });

    group('基本属性', () {
      test('应该返回正确的系统类型', () {
        expect(system.type, DivinationType.xiaoLiuRen);
      });

      test('应该返回正确的系统名称', () {
        expect(system.name, '小六壬');
      });

      test('应该返回正确的系统描述', () {
        expect(system.description, contains('小六壬'));
        expect(system.description, isNot(contains('物象声音起')));
      });

      test('应该暂时禁用', () {
        expect(system.isEnabled, false);
      });

      test('应该支持三种起课方式', () {
        expect(
          system.supportedMethods,
          equals([
            CastMethod.time,
            CastMethod.reportNumber,
            CastMethod.characterStroke,
          ]),
        );
      });
    });

    group('validateInput', () {
      test('时间起课只接受空输入', () {
        expect(system.validateInput(CastMethod.time, {}), true);
        expect(
          system.validateInput(
            CastMethod.time,
            const {'palaceMode': 'ninePalaces'},
          ),
          true,
        );
        expect(system.validateInput(CastMethod.time, {'month': 3}), false);
      });

      test('报数起课必须严格提供三个正整数', () {
        expect(
          system.validateInput(
            CastMethod.reportNumber,
            const {
              'firstNumber': 4,
              'secondNumber': 18,
              'thirdNumber': 7,
              'palaceMode': 'ninePalaces',
            },
          ),
          true,
        );
        expect(
          system.validateInput(
            CastMethod.reportNumber,
            const {
              'firstNumber': 4,
              'secondNumber': 18,
              'thirdNumber': 7,
              'palaceMode': 'invalid',
            },
          ),
          false,
        );
        expect(
          system.validateInput(
            CastMethod.reportNumber,
            const {
              'firstNumber': 4,
              'secondNumber': 18,
            },
          ),
          false,
        );
        expect(
          system.validateInput(
            CastMethod.reportNumber,
            const {
              'firstNumber': 4,
              'secondNumber': 18,
              'thirdNumber': 0,
            },
          ),
          false,
        );
        expect(
          system.validateInput(
            CastMethod.reportNumber,
            const {
              'firstNumber': 4,
              'secondNumber': 18,
              'thirdNumber': 7,
              'extra': 1,
            },
          ),
          false,
        );
      });

      test('笔画起课必须严格提供三个正整数', () {
        expect(
          system.validateInput(
            CastMethod.characterStroke,
            const {
              'firstStroke': 8,
              'secondStroke': 11,
              'thirdStroke': 6,
              'palaceMode': 'ninePalaces',
            },
          ),
          true,
        );
        expect(
          system.validateInput(
            CastMethod.characterStroke,
            const {
              'firstStroke': 8,
              'secondStroke': 11,
              'thirdStroke': -1,
            },
          ),
          false,
        );
      });

      test('物象声音起当前不纳入小六壬契约', () {
        expect(
          system.validateInput(
            CastMethod.objectSound,
            const {
              'firstNumber': 2,
              'secondNumber': 5,
              'thirdNumber': 9,
            },
          ),
          false,
        );
      });
    });

    group('cast', () {
      test('时间起课应该按农历月日时顺推得到最终落宫', () async {
        final result = await system.cast(
          method: CastMethod.time,
          input: const {},
          castTime: DateTime(2026, 4, 19, 9, 22),
        ) as XiaoLiuRenResult;

        expect(result.castMethod, CastMethod.time);
        expect(result.palaceMode, XiaoLiuRenPalaceMode.sixPalaces);
        expect(result.source.methodLabel, '时间起课');
        expect(result.source.firstLabel, '月数');
        expect(result.source.firstNumber, 3);
        expect(result.source.secondLabel, '日数');
        expect(result.source.secondNumber, 3);
        expect(result.source.thirdLabel, '时数');
        expect(result.source.thirdNumber, 6);
        expect(result.source.hourZhi, '巳');
        expect(result.source.usesLunarDate, true);
        expect(result.monthPosition.name, '速喜');
        expect(result.dayPosition.name, '小吉');
        expect(result.hourPosition.name, '赤口');
        expect(result.finalPosition.name, '赤口');
        expect(result.finalPosition.fortune, '凶');
        expect(result.getSummary(), '赤口 · 口舌是非');
        expect(result.judgement, '赤口，主口舌是非，宜谨言慎行。');
      });

      test('时间起课在九宫下应该按同样顺推规则计算', () async {
        final result = await system.cast(
          method: CastMethod.time,
          input: const {'palaceMode': 'ninePalaces'},
          castTime: DateTime(2026, 4, 19, 9, 22),
        ) as XiaoLiuRenResult;

        expect(result.castMethod, CastMethod.time);
        expect(result.palaceMode, XiaoLiuRenPalaceMode.ninePalaces);
        expect(result.source.firstNumber, 3);
        expect(result.source.secondNumber, 3);
        expect(result.source.thirdNumber, 6);
        expect(result.monthPosition.name, '速喜');
        expect(result.dayPosition.name, '小吉');
        expect(result.finalPosition.name, '大安');
        expect(result.getSummary(), '大安 · 诸事安稳');
      });

      test('报数起课应该按三个数字顺推', () async {
        final result = await system.cast(
          method: CastMethod.reportNumber,
          input: const {
            'firstNumber': 4,
            'secondNumber': 18,
            'thirdNumber': 7,
          },
          castTime: DateTime(2026, 4, 19, 9, 22),
        ) as XiaoLiuRenResult;

        expect(result.castMethod, CastMethod.reportNumber);
        expect(result.source.methodLabel, '报数起课');
        expect(result.source.firstNumber, 4);
        expect(result.source.secondNumber, 18);
        expect(result.source.thirdNumber, 7);
        expect(result.monthPosition.name, '赤口');
        expect(result.dayPosition.name, '速喜');
        expect(result.finalPosition.name, '速喜');
        expect(result.getSummary(), '速喜 · 喜信速来');
      });

      test('报数起课在九宫下应该走九神顺推', () async {
        final result = await system.cast(
          method: CastMethod.reportNumber,
          input: const {
            'firstNumber': 4,
            'secondNumber': 18,
            'thirdNumber': 7,
            'palaceMode': 'ninePalaces',
          },
          castTime: DateTime(2026, 4, 19, 9, 22),
        ) as XiaoLiuRenResult;

        expect(result.castMethod, CastMethod.reportNumber);
        expect(result.palaceMode, XiaoLiuRenPalaceMode.ninePalaces);
        expect(result.monthPosition.name, '赤口');
        expect(result.dayPosition.name, '速喜');
        expect(result.finalPosition.name, '天德');
        expect(result.getSummary(), '天德 · 贵人解厄');
      });

      test('笔画起课应该按三段笔画顺推', () async {
        final result = await system.cast(
          method: CastMethod.characterStroke,
          input: const {
            'firstStroke': 8,
            'secondStroke': 11,
            'thirdStroke': 6,
          },
          castTime: DateTime(2026, 4, 19, 9, 22),
        ) as XiaoLiuRenResult;

        expect(result.castMethod, CastMethod.characterStroke);
        expect(result.source.methodLabel, '汉字笔画起');
        expect(result.source.firstLabel, '首字笔画');
        expect(result.source.firstNumber, 8);
        expect(result.source.secondNumber, 11);
        expect(result.source.thirdNumber, 6);
        expect(result.monthPosition.name, '留连');
        expect(result.dayPosition.name, '空亡');
        expect(result.finalPosition.name, '小吉');
        expect(result.getSummary(), '小吉 · 小成可望');
      });

      test('笔画起课在九宫下应可落入新增九神', () async {
        final result = await system.cast(
          method: CastMethod.characterStroke,
          input: const {
            'firstStroke': 8,
            'secondStroke': 11,
            'thirdStroke': 6,
            'palaceMode': 'ninePalaces',
          },
          castTime: DateTime(2026, 4, 19, 9, 22),
        ) as XiaoLiuRenResult;

        expect(result.castMethod, CastMethod.characterStroke);
        expect(result.palaceMode, XiaoLiuRenPalaceMode.ninePalaces);
        expect(result.monthPosition.name, '桃花');
        expect(result.dayPosition.name, '天德');
        expect(result.finalPosition.name, '小吉');
        expect(result.getSummary(), '小吉 · 小成可望');
      });

      test('物象声音起当前应直接报不支持', () async {
        expect(
          () => system.cast(
            method: CastMethod.objectSound,
            input: const {
              'firstNumber': 2,
              'secondNumber': 5,
              'thirdNumber': 9,
            },
            castTime: DateTime(2026, 4, 19, 9, 22),
          ),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('非法输入应该抛出 ArgumentError', () async {
        expect(
          () => system.cast(
            method: CastMethod.characterStroke,
            input: const {
              'firstStroke': 8,
              'secondStroke': 11,
            },
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('resultFromJson', () {
      test('应该能够从 JSON 反序列化结果', () async {
        final original = await system.cast(
          method: CastMethod.characterStroke,
          input: const {
            'firstStroke': 8,
            'secondStroke': 11,
            'thirdStroke': 6,
            'palaceMode': 'ninePalaces',
          },
          castTime: DateTime(2026, 4, 19, 9, 22),
        ) as XiaoLiuRenResult;

        final result =
            system.resultFromJson(original.toJson()) as XiaoLiuRenResult;

        expect(result.systemType, DivinationType.xiaoLiuRen);
        expect(result.castMethod, CastMethod.characterStroke);
        expect(result.palaceMode, XiaoLiuRenPalaceMode.ninePalaces);
        expect(result.finalPosition.name, '小吉');
        expect(result.getSummary(), '小吉 · 小成可望');
      });
    });
  });

  group('XiaoLiuRenResult', () {
    late XiaoLiuRenResult result;

    setUp(() {
      const finalPosition = XiaoLiuRenPosition(
        index: 4,
        name: '赤口',
        fortune: '凶',
        keyword: '口舌是非',
        description: '主争执、冲突、言语失和，沟通宜谨慎，忌硬碰硬。',
        wuXing: '金',
        direction: '西方',
      );

      result = XiaoLiuRenResult(
        id: 'test-id',
        castTime: DateTime(2026, 4, 19, 9, 22),
        castMethod: CastMethod.time,
        lunarInfo: LunarInfo(
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
        palaceMode: XiaoLiuRenPalaceMode.sixPalaces,
        source: const XiaoLiuRenSource(
          methodLabel: '时间起课',
          firstNumber: 3,
          secondNumber: 3,
          thirdNumber: 6,
          firstLabel: '月数',
          secondLabel: '日数',
          thirdLabel: '时数',
          hourZhi: '巳',
          usesLunarDate: true,
          rule: '大安起月，月上起日，日上起时；各段均起点记 1 顺推',
        ),
        monthPosition: const XiaoLiuRenPosition(
          index: 3,
          name: '速喜',
          fortune: '吉',
          keyword: '喜信速来',
          description: '主喜讯、效率、结果加速，利会面、回音、推进。',
          wuXing: '火',
          direction: '南方',
        ),
        dayPosition: const XiaoLiuRenPosition(
          index: 5,
          name: '小吉',
          fortune: '吉',
          keyword: '小成可望',
          description: '主小利、人和、渐成，虽非大吉，但可稳步见好。',
          wuXing: '木',
          direction: '东方',
        ),
        hourPosition: finalPosition,
        finalPosition: finalPosition,
        judgement: '赤口，主口舌是非，宜谨言慎行。',
        detail: '测试详情',
      );
    });

    test('应该返回正确的系统类型', () {
      expect(result.systemType, DivinationType.xiaoLiuRen);
    });

    test('应该返回正确的摘要', () {
      expect(result.getSummary(), '赤口 · 口舌是非');
    });

    test('应该能够序列化为 JSON', () {
      final json = result.toJson();

      expect(json['id'], 'test-id');
      expect(json['systemType'], 'xiaoliuren');
      expect(json['castMethod'], 'time');
      expect(json['palaceMode'], 'sixPalaces');
      expect(json['source'], isA<Map<String, dynamic>>());
      expect(json['finalPosition'], isA<Map<String, dynamic>>());
    });

    test('应该能够从 JSON 反序列化', () {
      final deserialized = XiaoLiuRenResult.fromJson(result.toJson());

      expect(deserialized.id, result.id);
      expect(deserialized.castMethod, result.castMethod);
      expect(deserialized.palaceMode, result.palaceMode);
      expect(deserialized.monthPosition.name, result.monthPosition.name);
      expect(deserialized.finalPosition.name, result.finalPosition.name);
      expect(deserialized.judgement, result.judgement);
    });
  });
}
