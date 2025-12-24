import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/divination_registry.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

/// Mock 占卜结果（用于测试）
class MockDivinationResult implements DivinationResult {
  @override
  final String id;

  @override
  final DateTime castTime;

  @override
  final DivinationType systemType;

  @override
  final CastMethod castMethod;

  @override
  final LunarInfo lunarInfo;

  MockDivinationResult({
    required this.id,
    required this.castTime,
    required this.systemType,
    required this.castMethod,
    required this.lunarInfo,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'castTime': castTime.toIso8601String(),
        'systemType': systemType.id,
        'castMethod': castMethod.id,
      };

  @override
  String getSummary() => 'Mock Result';
}

/// Mock 排盘（用于测试）
class MockDivinationSystem implements DivinationSystem {
  @override
  final DivinationType type;

  @override
  final String name;

  @override
  final String description;

  @override
  final List<CastMethod> supportedMethods;

  @override
  final bool isEnabled;

  MockDivinationSystem({
    required this.type,
    required this.name,
    this.description = 'Mock System',
    this.supportedMethods = const [CastMethod.coin, CastMethod.time],
    this.isEnabled = true,
  });

  @override
  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  }) async {
    if (!supportedMethods.contains(method)) {
      throw ArgumentError('不支持的起卦方式: ${method.displayName}');
    }

    return MockDivinationResult(
      id: 'mock-id',
      castTime: castTime ?? DateTime.now(),
      systemType: type,
      castMethod: method,
      lunarInfo: const LunarInfo(
        yueJian: '寅',
        riGan: '甲',
        riZhi: '子',
        riGanZhi: '甲子',
        kongWang: ['戌', '亥'],
        yearGanZhi: '甲子',
        monthGanZhi: '丙寅',
      ),
    );
  }

  @override
  DivinationResult resultFromJson(Map<String, dynamic> json) {
    return MockDivinationResult(
      id: json['id'] as String,
      castTime: DateTime.parse(json['castTime'] as String),
      systemType: DivinationType.fromId(json['systemType'] as String),
      castMethod: CastMethod.fromId(json['castMethod'] as String),
      lunarInfo: const LunarInfo(
        yueJian: '寅',
        riGan: '甲',
        riZhi: '子',
        riGanZhi: '甲子',
        kongWang: ['戌', '亥'],
        yearGanZhi: '甲子',
        monthGanZhi: '丙寅',
      ),
    );
  }

  @override
  bool validateInput(CastMethod method, Map<String, dynamic> input) {
    return supportedMethods.contains(method);
  }
}

void main() {
  group('DivinationRegistry', () {
    late DivinationRegistry registry;

    setUp(() {
      registry = DivinationRegistry();
      // 清空注册表，确保每个测试都是独立的
      registry.clear();
    });

    tearDown(() {
      // 测试结束后清空注册表
      registry.clear();
    });

    group('单例模式', () {
      test('应该返回同一个实例', () {
        final registry1 = DivinationRegistry();
        final registry2 = DivinationRegistry();
        expect(identical(registry1, registry2), true);
      });

      test('多次调用应该共享相同的注册数据', () {
        final registry1 = DivinationRegistry();
        final registry2 = DivinationRegistry();

        registry1.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
        ));

        expect(registry2.isRegistered(DivinationType.liuYao), true);
      });
    });

    group('register', () {
      test('应该成功注册术数系统', () {
        final system = MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
        );

        registry.register(system);

        expect(registry.isRegistered(DivinationType.liuYao), true);
        expect(registry.count, 1);
      });

      test('应该覆盖已存在的系统', () {
        final system1 = MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻 v1',
        );
        final system2 = MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻 v2',
        );

        registry.register(system1);
        registry.register(system2);

        expect(registry.count, 1);
        expect(registry.getSystem(DivinationType.liuYao).name, '六爻 v2');
      });

      test('应该支持注册多个不同类型的系统', () {
        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
        ));
        registry.register(MockDivinationSystem(
          type: DivinationType.daLiuRen,
          name: '大六壬',
        ));

        expect(registry.count, 2);
        expect(registry.isRegistered(DivinationType.liuYao), true);
        expect(registry.isRegistered(DivinationType.daLiuRen), true);
      });
    });

    group('registerAll', () {
      test('应该批量注册多个系统', () {
        final systems = [
          MockDivinationSystem(type: DivinationType.liuYao, name: '六爻'),
          MockDivinationSystem(type: DivinationType.daLiuRen, name: '大六壬'),
          MockDivinationSystem(type: DivinationType.meiHua, name: '梅花易数'),
        ];

        registry.registerAll(systems);

        expect(registry.count, 3);
        expect(registry.isRegistered(DivinationType.liuYao), true);
        expect(registry.isRegistered(DivinationType.daLiuRen), true);
        expect(registry.isRegistered(DivinationType.meiHua), true);
      });
    });

    group('getSystem', () {
      test('应该返回已注册的系统', () {
        final system = MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
        );
        registry.register(system);

        final retrieved = registry.getSystem(DivinationType.liuYao);

        expect(retrieved, same(system));
        expect(retrieved.name, '六爻');
      });

      test('应该在系统未注册时抛出 StateError', () {
        expect(
          () => registry.getSystem(DivinationType.liuYao),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('未注册'),
          )),
        );
      });

      test('应该在系统已禁用时抛出 StateError', () {
        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
          isEnabled: false,
        ));

        expect(
          () => registry.getSystem(DivinationType.liuYao),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('已禁用'),
          )),
        );
      });
    });

    group('tryGetSystem', () {
      test('应该返回已注册的系统', () {
        final system = MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
        );
        registry.register(system);

        final retrieved = registry.tryGetSystem(DivinationType.liuYao);

        expect(retrieved, same(system));
      });

      test('应该在系统未注册时返回 null', () {
        final retrieved = registry.tryGetSystem(DivinationType.liuYao);
        expect(retrieved, isNull);
      });

      test('应该返回已禁用的系统（不检查 isEnabled）', () {
        final system = MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
          isEnabled: false,
        );
        registry.register(system);

        final retrieved = registry.tryGetSystem(DivinationType.liuYao);

        expect(retrieved, same(system));
      });
    });

    group('getEnabledSystems', () {
      test('应该只返回已启用的系统', () {
        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
          isEnabled: true,
        ));
        registry.register(MockDivinationSystem(
          type: DivinationType.daLiuRen,
          name: '大六壬',
          isEnabled: false,
        ));
        registry.register(MockDivinationSystem(
          type: DivinationType.meiHua,
          name: '梅花易数',
          isEnabled: true,
        ));

        final enabledSystems = registry.getEnabledSystems();

        expect(enabledSystems.length, 2);
        expect(enabledSystems.map((s) => s.type), containsAll([
          DivinationType.liuYao,
          DivinationType.meiHua,
        ]));
      });

      test('应该在没有启用的系统时返回空列表', () {
        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
          isEnabled: false,
        ));

        final enabledSystems = registry.getEnabledSystems();

        expect(enabledSystems, isEmpty);
      });
    });

    group('getAllSystems', () {
      test('应该返回所有已注册的系统（包括已禁用的）', () {
        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
          isEnabled: true,
        ));
        registry.register(MockDivinationSystem(
          type: DivinationType.daLiuRen,
          name: '大六壬',
          isEnabled: false,
        ));

        final allSystems = registry.getAllSystems();

        expect(allSystems.length, 2);
      });
    });

    group('isRegistered', () {
      test('应该在系统已注册时返回 true', () {
        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
        ));

        expect(registry.isRegistered(DivinationType.liuYao), true);
      });

      test('应该在系统未注册时返回 false', () {
        expect(registry.isRegistered(DivinationType.liuYao), false);
      });
    });

    group('isEnabled', () {
      test('应该在系统已注册且已启用时返回 true', () {
        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
          isEnabled: true,
        ));

        expect(registry.isEnabled(DivinationType.liuYao), true);
      });

      test('应该在系统已注册但已禁用时返回 false', () {
        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
          isEnabled: false,
        ));

        expect(registry.isEnabled(DivinationType.liuYao), false);
      });

      test('应该在系统未注册时返回 false', () {
        expect(registry.isEnabled(DivinationType.liuYao), false);
      });
    });

    group('unregister', () {
      test('应该成功取消注册系统', () {
        final system = MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
        );
        registry.register(system);

        final removed = registry.unregister(DivinationType.liuYao);

        expect(removed, same(system));
        expect(registry.isRegistered(DivinationType.liuYao), false);
        expect(registry.count, 0);
      });

      test('应该在系统未注册时返回 null', () {
        final removed = registry.unregister(DivinationType.liuYao);
        expect(removed, isNull);
      });
    });

    group('clear', () {
      test('应该清空所有已注册的系统', () {
        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
        ));
        registry.register(MockDivinationSystem(
          type: DivinationType.daLiuRen,
          name: '大六壬',
        ));

        registry.clear();

        expect(registry.count, 0);
        expect(registry.isRegistered(DivinationType.liuYao), false);
        expect(registry.isRegistered(DivinationType.daLiuRen), false);
      });
    });

    group('统计方法', () {
      test('count 应该返回已注册系统数量', () {
        expect(registry.count, 0);

        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
        ));
        expect(registry.count, 1);

        registry.register(MockDivinationSystem(
          type: DivinationType.daLiuRen,
          name: '大六壬',
        ));
        expect(registry.count, 2);
      });

      test('enabledCount 应该返回已启用系统数量', () {
        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
          isEnabled: true,
        ));
        registry.register(MockDivinationSystem(
          type: DivinationType.daLiuRen,
          name: '大六壬',
          isEnabled: false,
        ));
        registry.register(MockDivinationSystem(
          type: DivinationType.meiHua,
          name: '梅花易数',
          isEnabled: true,
        ));

        expect(registry.enabledCount, 2);
      });

      test('hasAnySystem 应该正确反映是否有系统注册', () {
        expect(registry.hasAnySystem, false);

        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
        ));

        expect(registry.hasAnySystem, true);
      });

      test('hasAnyEnabledSystem 应该正确反映是否有启用的系统', () {
        expect(registry.hasAnyEnabledSystem, false);

        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
          isEnabled: false,
        ));
        expect(registry.hasAnyEnabledSystem, false);

        registry.register(MockDivinationSystem(
          type: DivinationType.daLiuRen,
          name: '大六壬',
          isEnabled: true,
        ));
        expect(registry.hasAnyEnabledSystem, true);
      });
    });

    group('getRegisteredTypes', () {
      test('应该返回所有已注册的系统类型', () {
        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
        ));
        registry.register(MockDivinationSystem(
          type: DivinationType.daLiuRen,
          name: '大六壬',
        ));

        final types = registry.getRegisteredTypes();

        expect(types.length, 2);
        expect(types, containsAll([
          DivinationType.liuYao,
          DivinationType.daLiuRen,
        ]));
      });
    });

    group('getEnabledTypes', () {
      test('应该只返回已启用的系统类型', () {
        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻',
          isEnabled: true,
        ));
        registry.register(MockDivinationSystem(
          type: DivinationType.daLiuRen,
          name: '大六壬',
          isEnabled: false,
        ));

        final types = registry.getEnabledTypes();

        expect(types.length, 1);
        expect(types, contains(DivinationType.liuYao));
        expect(types, isNot(contains(DivinationType.daLiuRen)));
      });
    });

    group('getSystemsSummary', () {
      test('应该在没有系统时返回提示信息', () {
        final summary = registry.getSystemsSummary();
        expect(summary, contains('没有已注册的术数系统'));
      });

      test('应该返回所有系统的摘要信息', () {
        registry.register(MockDivinationSystem(
          type: DivinationType.liuYao,
          name: '六爻占卜',
          description: '传统六爻排盘',
          isEnabled: true,
        ));
        registry.register(MockDivinationSystem(
          type: DivinationType.daLiuRen,
          name: '大六壬',
          description: '大六壬排盘',
          isEnabled: false,
        ));

        final summary = registry.getSystemsSummary();

        expect(summary, contains('六爻'));
        expect(summary, contains('大六壬'));
        expect(summary, contains('✓ 已启用'));
        expect(summary, contains('✗ 已禁用'));
        expect(summary, contains('传统六爻排盘'));
      });
    });
  });
}

