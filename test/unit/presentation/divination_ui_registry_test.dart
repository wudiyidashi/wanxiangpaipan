import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';
import 'package:wanxiang_paipan/presentation/divination_ui_registry.dart';
import '../../mocks/mock_divination_ui_factory.dart';

void main() {
  group('DivinationUIRegistry', () {
    late DivinationUIRegistry registry;

    setUp(() {
      registry = DivinationUIRegistry();
      // 清空注册表，确保每个测试都是独立的
      registry.clear();
    });

    tearDown(() {
      // 测试结束后清空注册表
      registry.clear();
    });

    group('单例模式', () {
      test('应该返回同一个实例', () {
        final registry1 = DivinationUIRegistry();
        final registry2 = DivinationUIRegistry();
        expect(identical(registry1, registry2), true);
      });

      test('多次调用应该共享相同的注册数据', () {
        final registry1 = DivinationUIRegistry();
        final registry2 = DivinationUIRegistry();

        registry1.registerUI(MockLiuYaoUIFactory());

        expect(registry2.isUIRegistered(DivinationType.liuYao), true);
      });
    });

    group('registerUI', () {
      test('应该成功注册 UI 工厂', () {
        final factory = MockLiuYaoUIFactory();

        registry.registerUI(factory);

        expect(registry.isUIRegistered(DivinationType.liuYao), true);
        expect(registry.count, 1);
      });

      test('应该覆盖已存在的 UI 工厂', () {
        final factory1 = MockDivinationUIFactory(
          systemType: DivinationType.liuYao,
          systemIcon: Icons.star,
        );
        final factory2 = MockDivinationUIFactory(
          systemType: DivinationType.liuYao,
          systemIcon: Icons.favorite,
        );

        registry.registerUI(factory1);
        registry.registerUI(factory2);

        expect(registry.count, 1);
        final retrieved = registry.getUIFactory(DivinationType.liuYao);
        expect(retrieved.getSystemIcon(), Icons.favorite);
      });

      test('应该支持注册多个不同类型的 UI 工厂', () {
        registry.registerUI(MockLiuYaoUIFactory());
        registry.registerUI(MockDaLiuRenUIFactory());
        registry.registerUI(MockMeiHuaUIFactory());

        expect(registry.count, 3);
        expect(registry.isUIRegistered(DivinationType.liuYao), true);
        expect(registry.isUIRegistered(DivinationType.daLiuRen), true);
        expect(registry.isUIRegistered(DivinationType.meiHua), true);
      });
    });

    group('registerAllUI', () {
      test('应该批量注册多个 UI 工厂', () {
        final factories = [
          MockLiuYaoUIFactory(),
          MockDaLiuRenUIFactory(),
          MockMeiHuaUIFactory(),
        ];

        registry.registerAllUI(factories);

        expect(registry.count, 3);
        expect(registry.isUIRegistered(DivinationType.liuYao), true);
        expect(registry.isUIRegistered(DivinationType.daLiuRen), true);
        expect(registry.isUIRegistered(DivinationType.meiHua), true);
      });
    });

    group('getUIFactory', () {
      test('应该返回已注册的 UI 工厂', () {
        final factory = MockLiuYaoUIFactory();
        registry.registerUI(factory);

        final retrieved = registry.getUIFactory(DivinationType.liuYao);

        expect(retrieved, same(factory));
        expect(retrieved.systemType, DivinationType.liuYao);
      });

      test('应该在 UI 工厂未注册时抛出 StateError', () {
        expect(
          () => registry.getUIFactory(DivinationType.liuYao),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('未注册'),
          )),
        );
      });
    });

    group('tryGetUIFactory', () {
      test('应该返回已注册的 UI 工厂', () {
        final factory = MockLiuYaoUIFactory();
        registry.registerUI(factory);

        final retrieved = registry.tryGetUIFactory(DivinationType.liuYao);

        expect(retrieved, same(factory));
      });

      test('应该在 UI 工厂未注册时返回 null', () {
        final retrieved = registry.tryGetUIFactory(DivinationType.liuYao);
        expect(retrieved, isNull);
      });
    });

    group('isUIRegistered', () {
      test('应该在 UI 工厂已注册时返回 true', () {
        registry.registerUI(MockLiuYaoUIFactory());

        expect(registry.isUIRegistered(DivinationType.liuYao), true);
      });

      test('应该在 UI 工厂未注册时返回 false', () {
        expect(registry.isUIRegistered(DivinationType.liuYao), false);
      });
    });

    group('getAllUIFactories', () {
      test('应该返回所有已注册的 UI 工厂', () {
        registry.registerUI(MockLiuYaoUIFactory());
        registry.registerUI(MockDaLiuRenUIFactory());

        final allFactories = registry.getAllUIFactories();

        expect(allFactories.length, 2);
      });

      test('应该在没有注册时返回空列表', () {
        final allFactories = registry.getAllUIFactories();
        expect(allFactories, isEmpty);
      });
    });

    group('getRegisteredTypes', () {
      test('应该返回所有已注册的系统类型', () {
        registry.registerUI(MockLiuYaoUIFactory());
        registry.registerUI(MockDaLiuRenUIFactory());

        final types = registry.getRegisteredTypes();

        expect(types.length, 2);
        expect(types, containsAll([
          DivinationType.liuYao,
          DivinationType.daLiuRen,
        ]));
      });
    });

    group('unregisterUI', () {
      test('应该成功取消注册 UI 工厂', () {
        final factory = MockLiuYaoUIFactory();
        registry.registerUI(factory);

        final removed = registry.unregisterUI(DivinationType.liuYao);

        expect(removed, same(factory));
        expect(registry.isUIRegistered(DivinationType.liuYao), false);
        expect(registry.count, 0);
      });

      test('应该在 UI 工厂未注册时返回 null', () {
        final removed = registry.unregisterUI(DivinationType.liuYao);
        expect(removed, isNull);
      });
    });

    group('clear', () {
      test('应该清空所有已注册的 UI 工厂', () {
        registry.registerUI(MockLiuYaoUIFactory());
        registry.registerUI(MockDaLiuRenUIFactory());

        registry.clear();

        expect(registry.count, 0);
        expect(registry.isUIRegistered(DivinationType.liuYao), false);
        expect(registry.isUIRegistered(DivinationType.daLiuRen), false);
      });
    });

    group('统计方法', () {
      test('count 应该返回已注册 UI 工厂数量', () {
        expect(registry.count, 0);

        registry.registerUI(MockLiuYaoUIFactory());
        expect(registry.count, 1);

        registry.registerUI(MockDaLiuRenUIFactory());
        expect(registry.count, 2);
      });

      test('hasAnyUIFactory 应该正确反映是否有 UI 工厂注册', () {
        expect(registry.hasAnyUIFactory, false);

        registry.registerUI(MockLiuYaoUIFactory());

        expect(registry.hasAnyUIFactory, true);
      });
    });

    group('便捷方法', () {
      testWidgets('buildCastScreen 应该动态构建起卦页面',
          (WidgetTester tester) async {
        registry.registerUI(MockLiuYaoUIFactory());

        final castScreen = registry.buildCastScreen(
          DivinationType.liuYao,
          CastMethod.coin,
        );

        await tester.pumpWidget(MaterialApp(home: castScreen));

        expect(find.text('Mock Cast Screen'), findsOneWidget);
        expect(find.text('系统: 六爻'), findsOneWidget);
        expect(find.text('起卦方式: 摇钱法'), findsOneWidget);
      });

      testWidgets('buildCastScreen 应该在 UI 工厂未注册时抛出异常',
          (WidgetTester tester) async {
        expect(
          () => registry.buildCastScreen(
            DivinationType.liuYao,
            CastMethod.coin,
          ),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('getUIFactoriesSummary', () {
      test('应该在没有 UI 工厂时返回提示信息', () {
        final summary = registry.getUIFactoriesSummary();
        expect(summary, contains('没有已注册的 UI 工厂'));
      });

      test('应该返回所有 UI 工厂的摘要信息', () {
        registry.registerUI(MockLiuYaoUIFactory());
        registry.registerUI(MockDaLiuRenUIFactory());

        final summary = registry.getUIFactoriesSummary();

        expect(summary, contains('六爻'));
        expect(summary, contains('大六壬'));
        expect(summary, contains('图标'));
        expect(summary, contains('主题色'));
      });
    });
  });

  group('MockDivinationUIFactory', () {
    testWidgets('buildCastScreen 应该返回有效的 Widget',
        (WidgetTester tester) async {
      final factory = MockLiuYaoUIFactory();
      final castScreen = factory.buildCastScreen(CastMethod.coin);

      await tester.pumpWidget(MaterialApp(home: castScreen));

      expect(find.text('Mock Cast Screen'), findsOneWidget);
      expect(find.byIcon(Icons.casino), findsOneWidget);
    });

    testWidgets('buildResultScreen 应该返回有效的 Widget',
        (WidgetTester tester) async {
      final factory = MockLiuYaoUIFactory();

      // 创建一个简单的 Mock Result
      final result = _MockResult(
        systemType: DivinationType.liuYao,
        castMethod: CastMethod.coin,
      );

      final resultScreen = factory.buildResultScreen(result);

      await tester.pumpWidget(MaterialApp(home: resultScreen));

      // 使用 findsWidgets 因为文本出现在 AppBar 和 Body 中
      expect(find.text('Mock Result Screen'), findsWidgets);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('系统: 六爻'), findsOneWidget);
    });

    testWidgets('buildHistoryCard 应该返回有效的 Widget',
        (WidgetTester tester) async {
      final factory = MockLiuYaoUIFactory();

      final result = _MockResult(
        systemType: DivinationType.liuYao,
        castMethod: CastMethod.coin,
      );

      final historyCard = factory.buildHistoryCard(result);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: historyCard)));

      expect(find.text('Mock History Card - 六爻'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('buildSystemCard 应该返回有效的 Widget',
        (WidgetTester tester) async {
      final factory = MockLiuYaoUIFactory();
      final systemCard = factory.buildSystemCard();

      expect(systemCard, isNotNull);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: systemCard!)));

      expect(find.text('Mock System Card - 六爻'), findsOneWidget);
    });

    test('getSystemIcon 应该返回正确的图标', () {
      final factory = MockLiuYaoUIFactory();
      expect(factory.getSystemIcon(), Icons.auto_awesome);
    });

    test('getSystemColor 应该返回正确的颜色', () {
      final factory = MockLiuYaoUIFactory();
      expect(factory.getSystemColor(), Colors.blue);
    });
  });
}

/// 简单的 Mock Result 用于测试
class _MockResult implements DivinationResult {
  @override
  final DivinationType systemType;

  @override
  final CastMethod castMethod;

  @override
  final String id = 'mock-id';

  @override
  final DateTime castTime = DateTime(2025, 1, 15);

  _MockResult({
    required this.systemType,
    required this.castMethod,
  });

  @override
  get lunarInfo => const LunarInfo(
        yueJian: '寅',
        riGan: '甲',
        riZhi: '子',
        riGanZhi: '甲子',
        kongWang: ['戌', '亥'],
        yearGanZhi: '甲子',
        monthGanZhi: '丙寅',
      );

  @override
  Map<String, dynamic> toJson() => {};

  @override
  String getSummary() => 'Mock Summary';
}

