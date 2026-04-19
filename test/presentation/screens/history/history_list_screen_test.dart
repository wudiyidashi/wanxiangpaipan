import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/repositories/divination_repository.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';
import 'package:wanxiang_paipan/presentation/divination_ui_registry.dart';
import 'package:wanxiang_paipan/presentation/screens/history/history_list_screen.dart';

class _FakeDivinationRepository implements DivinationRepository {
  _FakeDivinationRepository(List<DivinationResult> initialRecords)
      : _records = List<DivinationResult>.from(initialRecords);

  final List<DivinationResult> _records;
  final List<String> deletedIds = [];

  @override
  Future<List<DivinationResult>> getAllRecords() async =>
      List<DivinationResult>.from(_records);

  @override
  Future<int> deleteRecord(String id) async {
    deletedIds.add(id);
    _records.removeWhere((record) => record.id == id);
    return 1;
  }

  @override
  Future<String?> readEncryptedField(String key) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used in tests: ${invocation.memberName}');
}

class _FakeResult implements DivinationResult {
  const _FakeResult({
    required this.id,
    required this.systemType,
    required this.castMethod,
    required this.castTime,
    required this.summary,
  });

  @override
  final String id;

  @override
  final DivinationType systemType;

  @override
  final CastMethod castMethod;

  @override
  final DateTime castTime;

  final String summary;

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
  String getSummary() => summary;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'systemType': systemType.id,
        'castMethod': castMethod.id,
        'castTime': castTime.toIso8601String(),
        'summary': summary,
      };
}

Widget _wrapWithRepository({
  required DivinationRepository repository,
  bool chromeless = true,
}) {
  final screen = HistoryListScreen(chromeless: chromeless);
  return MaterialApp(
    home: Provider<DivinationRepository>.value(
      value: repository,
      child: chromeless ? Scaffold(body: screen) : screen,
    ),
  );
}

void main() {
  setUp(() {
    DivinationUIRegistry().clear();
  });

  group('HistoryListScreen', () {
    testWidgets('支持排序切换与关键字搜索', (tester) async {
      final now = DateTime.now();
      final repository = _FakeDivinationRepository([
        _FakeResult(
          id: 'newer',
          systemType: DivinationType.liuYao,
          castMethod: CastMethod.time,
          castTime: now.subtract(const Duration(minutes: 5)),
          summary: '较晚记录',
        ),
        _FakeResult(
          id: 'older',
          systemType: DivinationType.liuYao,
          castMethod: CastMethod.time,
          castTime: now.subtract(const Duration(hours: 2)),
          summary: '较早记录',
        ),
      ]);

      await tester.pumpWidget(
        _wrapWithRepository(repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('较晚记录'), findsOneWidget);
      expect(find.text('较早记录'), findsOneWidget);

      final newerDyBefore = tester.getTopLeft(find.text('较晚记录')).dy;
      final olderDyBefore = tester.getTopLeft(find.text('较早记录')).dy;
      expect(newerDyBefore, lessThan(olderDyBefore));

      await tester.tap(find.text('最早'));
      await tester.pumpAndSettle();

      final newerDyAfter = tester.getTopLeft(find.text('较晚记录')).dy;
      final olderDyAfter = tester.getTopLeft(find.text('较早记录')).dy;
      expect(olderDyAfter, lessThan(newerDyAfter));

      await tester.enterText(find.byType(TextField), '较晚');
      await tester.pumpAndSettle();

      expect(find.text('较晚记录'), findsOneWidget);
      expect(find.text('较早记录'), findsNothing);
      expect(find.textContaining('关键字: "较晚"'), findsOneWidget);
      expect(find.textContaining('共 1 条'), findsOneWidget);
    });

    testWidgets('支持系统筛选并可清除', (tester) async {
      final now = DateTime.now();
      final repository = _FakeDivinationRepository([
        _FakeResult(
          id: 'liuyao',
          systemType: DivinationType.liuYao,
          castMethod: CastMethod.time,
          castTime: now.subtract(const Duration(minutes: 10)),
          summary: '六爻问事',
        ),
        _FakeResult(
          id: 'meihua',
          systemType: DivinationType.meiHua,
          castMethod: CastMethod.number,
          castTime: now.subtract(const Duration(minutes: 20)),
          summary: '梅花问事',
        ),
      ]);

      await tester.pumpWidget(
        _wrapWithRepository(repository: repository, chromeless: false),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text(DivinationType.meiHua.displayName).last);
      await tester.pumpAndSettle();

      expect(find.text('梅花问事'), findsOneWidget);
      expect(find.text('六爻问事'), findsNothing);
      expect(
        find.textContaining('系统: ${DivinationType.meiHua.displayName}'),
        findsOneWidget,
      );

      await tester.tap(find.text('清除'));
      await tester.pumpAndSettle();

      expect(find.text('梅花问事'), findsOneWidget);
      expect(find.text('六爻问事'), findsOneWidget);
    });

    testWidgets('删除记录后显示空历史状态并提示成功', (tester) async {
      final repository = _FakeDivinationRepository([
        _FakeResult(
          id: 'to-delete',
          systemType: DivinationType.liuYao,
          castMethod: CastMethod.time,
          castTime: DateTime.now(),
          summary: '待删除记录',
        ),
      ]);

      await tester.pumpWidget(
        _wrapWithRepository(repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('待删除记录'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('确认删除'), findsOneWidget);

      await tester.tap(find.text('删除').last);
      await tester.pumpAndSettle();

      expect(repository.deletedIds, ['to-delete']);
      expect(find.text('待删除记录'), findsNothing);
      expect(find.text('暂无历史记录'), findsOneWidget);
      expect(find.text('记录已删除'), findsOneWidget);
    });
  });
}
