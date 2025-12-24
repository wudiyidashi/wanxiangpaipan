import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/registry_bootstrap.dart';
import 'package:wanxiang_paipan/domain/divination_registry.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/presentation/divination_ui_registry.dart';

void main() {
  group('DivinationSystemBootstrap', () {
    setUp(() {
      // 每个测试前清空所有注册
      DivinationSystemBootstrap.clearAll();
    });

    tearDown(() {
      // 每个测试后清空所有注册
      DivinationSystemBootstrap.clearAll();
    });

    group('registerAll', () {
      test('应该成功注册所有系统和 UI 工厂', () {
        DivinationSystemBootstrap.registerAll();

        final registry = DivinationRegistry();
        final uiRegistry = DivinationUIRegistry();

        // 验证至少注册了六爻系统
        expect(registry.isRegistered(DivinationType.liuYao), true);
        expect(uiRegistry.isUIRegistered(DivinationType.liuYao), true);
      });

      test('应该在注册后可以获取系统', () {
        DivinationSystemBootstrap.registerAll();

        final registry = DivinationRegistry();
        final system = registry.getSystem(DivinationType.liuYao);

        expect(system, isNotNull);
        expect(system.type, DivinationType.liuYao);
        expect(system.isEnabled, true);
      });

      test('应该在注册后可以获取 UI 工厂', () {
        DivinationSystemBootstrap.registerAll();

        final uiRegistry = DivinationUIRegistry();
        final uiFactory = uiRegistry.getUIFactory(DivinationType.liuYao);

        expect(uiFactory, isNotNull);
        expect(uiFactory.systemType, DivinationType.liuYao);
      });

      test('应该支持重复注册（后注册覆盖先注册）', () {
        DivinationSystemBootstrap.registerAll();
        final registry1 = DivinationRegistry();
        final count1 = registry1.count;

        DivinationSystemBootstrap.registerAll();
        final registry2 = DivinationRegistry();
        final count2 = registry2.count;

        // 重复注册不会增加数量
        expect(count2, count1);
      });
    });

    group('registerLiuYaoSystem', () {
      test('应该成功注册六爻系统', () {
        DivinationSystemBootstrap.registerLiuYaoSystem();

        final registry = DivinationRegistry();
        final uiRegistry = DivinationUIRegistry();

        expect(registry.isRegistered(DivinationType.liuYao), true);
        expect(uiRegistry.isUIRegistered(DivinationType.liuYao), true);
      });

      test('应该在注册后可以获取六爻系统', () {
        DivinationSystemBootstrap.registerLiuYaoSystem();

        final registry = DivinationRegistry();
        final system = registry.getSystem(DivinationType.liuYao);

        expect(system.type, DivinationType.liuYao);
        expect(system.name, '六爻');
      });

      test('应该在注册后可以获取六爻 UI 工厂', () {
        DivinationSystemBootstrap.registerLiuYaoSystem();

        final uiRegistry = DivinationUIRegistry();
        final uiFactory = uiRegistry.getUIFactory(DivinationType.liuYao);

        expect(uiFactory.systemType, DivinationType.liuYao);
      });
    });

    group('verifyRegistration', () {
      test('应该在未注册时返回 false', () {
        final isValid = DivinationSystemBootstrap.verifyRegistration();
        expect(isValid, false);
      });

      test('应该在注册后返回 true', () {
        DivinationSystemBootstrap.registerAll();

        final isValid = DivinationSystemBootstrap.verifyRegistration();
        expect(isValid, true);
      });

      test('应该在只注册系统但未注册 UI 工厂时返回 false', () {
        final registry = DivinationRegistry();
        registry.register(
          _MockDivinationSystem(
            type: DivinationType.liuYao,
            isEnabled: true,
          ),
        );

        final isValid = DivinationSystemBootstrap.verifyRegistration();
        expect(isValid, false);
      });

      test('应该在系统禁用时不检查该系统', () {
        final registry = DivinationRegistry();
        registry.register(
          _MockDivinationSystem(
            type: DivinationType.liuYao,
            isEnabled: false,
          ),
        );

        // 禁用的系统不会被检查，所以返回 false（因为没有启用的系统）
        final isValid = DivinationSystemBootstrap.verifyRegistration();
        expect(isValid, false);
      });
    });

    group('clearAll', () {
      test('应该清空所有注册', () {
        DivinationSystemBootstrap.registerAll();

        final registry1 = DivinationRegistry();
        final uiRegistry1 = DivinationUIRegistry();
        expect(registry1.count, greaterThan(0));
        expect(uiRegistry1.count, greaterThan(0));

        DivinationSystemBootstrap.clearAll();

        final registry2 = DivinationRegistry();
        final uiRegistry2 = DivinationUIRegistry();
        expect(registry2.count, 0);
        expect(uiRegistry2.count, 0);
      });

      test('应该在清空后无法获取系统', () {
        DivinationSystemBootstrap.registerAll();
        DivinationSystemBootstrap.clearAll();

        final registry = DivinationRegistry();

        expect(
          () => registry.getSystem(DivinationType.liuYao),
          throwsA(isA<StateError>()),
        );
      });

      test('应该在清空后无法获取 UI 工厂', () {
        DivinationSystemBootstrap.registerAll();
        DivinationSystemBootstrap.clearAll();

        final uiRegistry = DivinationUIRegistry();

        expect(
          () => uiRegistry.getUIFactory(DivinationType.liuYao),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('getRegistrationSummary', () {
      test('应该在未注册时返回空摘要', () {
        final summary = DivinationSystemBootstrap.getRegistrationSummary();

        expect(summary['systemCount'], 0);
        expect(summary['uiFactoryCount'], 0);
        expect(summary['enabledSystemCount'], 0);
        expect(summary['allValid'], false);
      });

      test('应该在注册后返回正确的摘要', () {
        DivinationSystemBootstrap.registerAll();

        final summary = DivinationSystemBootstrap.getRegistrationSummary();

        expect(summary['systemCount'], greaterThan(0));
        expect(summary['uiFactoryCount'], greaterThan(0));
        expect(summary['enabledSystemCount'], greaterThan(0));
        expect(summary['allValid'], true);
      });

      test('应该返回包含所有必需字段的摘要', () {
        DivinationSystemBootstrap.registerAll();

        final summary = DivinationSystemBootstrap.getRegistrationSummary();

        expect(summary.containsKey('systemCount'), true);
        expect(summary.containsKey('uiFactoryCount'), true);
        expect(summary.containsKey('enabledSystemCount'), true);
        expect(summary.containsKey('allValid'), true);
      });
    });

    group('printRegistrationInfo', () {
      test('应该在注册后可以打印信息（不抛出异常）', () {
        DivinationSystemBootstrap.registerAll();

        // 这个方法只是打印信息，不应该抛出异常
        expect(
          () => DivinationSystemBootstrap.printRegistrationInfo(),
          returnsNormally,
        );
      });

      test('应该在未注册时也可以打印信息（不抛出异常）', () {
        // 即使没有注册，也应该能正常打印
        expect(
          () => DivinationSystemBootstrap.printRegistrationInfo(),
          returnsNormally,
        );
      });
    });

    group('集成测试', () {
      test('应该支持完整的注册-验证-清空流程', () {
        // 1. 注册
        DivinationSystemBootstrap.registerAll();
        expect(DivinationSystemBootstrap.verifyRegistration(), true);

        // 2. 获取系统
        final registry = DivinationRegistry();
        final system = registry.getSystem(DivinationType.liuYao);
        expect(system, isNotNull);

        // 3. 获取 UI 工厂
        final uiRegistry = DivinationUIRegistry();
        final uiFactory = uiRegistry.getUIFactory(DivinationType.liuYao);
        expect(uiFactory, isNotNull);

        // 4. 清空
        DivinationSystemBootstrap.clearAll();
        expect(DivinationSystemBootstrap.verifyRegistration(), false);
      });

      test('应该支持按需注册单个系统', () {
        // 只注册六爻系统
        DivinationSystemBootstrap.registerLiuYaoSystem();

        final registry = DivinationRegistry();
        final uiRegistry = DivinationUIRegistry();

        expect(registry.isRegistered(DivinationType.liuYao), true);
        expect(uiRegistry.isUIRegistered(DivinationType.liuYao), true);
      });

      test('应该在注册后可以执行起卦操作', () async {
        DivinationSystemBootstrap.registerAll();

        final registry = DivinationRegistry();
        final system = registry.getSystem(DivinationType.liuYao);

        // 验证系统支持的起卦方式
        expect(system.supportedMethods, isNotEmpty);
        expect(
          system.supportedMethods,
          contains(CastMethod.coin),
        );
      });
    });
  });
}

/// Mock 排盘（用于测试）
class _MockDivinationSystem implements DivinationSystem {
  @override
  final DivinationType type;

  @override
  final bool isEnabled;

  _MockDivinationSystem({
    required this.type,
    this.isEnabled = true,
  });

  @override
  String get name => type.displayName;

  @override
  String get description => 'Mock system for testing';

  @override
  List<CastMethod> get supportedMethods => [CastMethod.coin];

  @override
  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  }) async {
    throw UnimplementedError();
  }

  @override
  DivinationResult resultFromJson(Map<String, dynamic> json) {
    throw UnimplementedError();
  }

  @override
  bool validateInput(CastMethod method, Map<String, dynamic> input) {
    return true;
  }
}

