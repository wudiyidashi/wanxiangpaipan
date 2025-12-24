import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_system.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

void main() {
  group('DaLiuRenSystem', () {
    late DaLiuRenSystem system;
    late LunarInfo testLunarInfo;

    setUp(() {
      system = DaLiuRenSystem();
      testLunarInfo = LunarInfo(
        yueJian: '丑',
        riGan: '戊',
        riZhi: '寅',
        riGanZhi: '戊寅',
        yearGanZhi: '甲辰',
        monthGanZhi: '丁丑',
        kongWang: ['戌', '亥'],
      );
    });

    group('基本属性', () {
      test('应该返回正确的系统类型', () {
        expect(system.type, DivinationType.daLiuRen);
      });

      test('应该返回正确的系统名称', () {
        expect(system.name, '大六壬');
      });

      test('应该返回正确的系统描述', () {
        expect(system.description, isNotEmpty);
        expect(system.description, contains('大六壬'));
      });

      test('应该暂时禁用（isEnabled = false）', () {
        expect(system.isEnabled, false);
      });

      test('应该支持时间起卦和手动输入', () {
        expect(system.supportedMethods, contains(CastMethod.time));
        expect(system.supportedMethods, contains(CastMethod.manual));
      });
    });

    group('cast 方法', () {
      test('应该抛出 UnimplementedError', () async {
        expect(
          () => system.cast(
            method: CastMethod.time,
            input: {},
          ),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('抛出的错误应该包含实现提示', () async {
        try {
          await system.cast(
            method: CastMethod.time,
            input: {},
          );
          fail('应该抛出 UnimplementedError');
        } catch (e) {
          expect(e, isA<UnimplementedError>());
          expect(e.toString(), contains('大六壬系统尚未实现'));
          expect(e.toString(), contains('四课排列算法'));
          expect(e.toString(), contains('三传推导算法'));
        }
      });
    });

    group('resultFromJson', () {
      test('应该能够从 JSON 反序列化结果', () {
        final json = {
          'id': 'test-id',
          'systemType': 'daLiuRen',
          'castTime': '2025-01-16T12:00:00.000',
          'castMethod': 'time',
          'lunarInfo': testLunarInfo.toJson(),
          'placeholderData': {},
        };

        final result = system.resultFromJson(json);

        expect(result, isA<DaLiuRenResult>());
        expect(result.id, 'test-id');
        expect(result.systemType, DivinationType.daLiuRen);
        expect(result.castMethod, CastMethod.time);
      });
    });
  });

  group('DaLiuRenResult', () {
    late DaLiuRenResult result;
    late LunarInfo testLunarInfo;

    setUp(() {
      testLunarInfo = LunarInfo(
        yueJian: '丑',
        riGan: '戊',
        riZhi: '寅',
        riGanZhi: '戊寅',
        yearGanZhi: '甲辰',
        monthGanZhi: '丁丑',
        kongWang: ['戌', '亥'],
      );

      result = DaLiuRenResult(
        id: 'test-id',
        castTime: DateTime(2025, 1, 16, 12, 0),
        castMethod: CastMethod.time,
        lunarInfo: testLunarInfo,
      );
    });

    test('应该返回正确的系统类型', () {
      expect(result.systemType, DivinationType.daLiuRen);
    });

    test('应该返回正确的摘要', () {
      expect(result.getSummary(), '大六壬占卜（未实现）');
    });

    test('应该能够序列化为 JSON', () {
      final json = result.toJson();

      expect(json['id'], 'test-id');
      expect(json['systemType'], 'daLiuRen');
      expect(json['castMethod'], 'time');
      expect(json['placeholderData'], isA<Map>());
    });

    test('应该能够从 JSON 反序列化', () {
      final json = result.toJson();
      final deserialized = DaLiuRenResult.fromJson(json);

      expect(deserialized.id, result.id);
      expect(deserialized.systemType, result.systemType);
      expect(deserialized.castTime, result.castTime);
      expect(deserialized.castMethod, result.castMethod);
    });
  });
}

