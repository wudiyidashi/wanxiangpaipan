import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';
import 'package:wanxiang_paipan/presentation/screens/history/history_filter.dart';
import 'package:wanxiang_paipan/presentation/screens/history/history_list_viewmodel.dart';

class _FakeHistoryListService implements HistoryListService {
  _FakeHistoryListService(List<DivinationResult> initialRecords)
      : _records = List<DivinationResult>.from(initialRecords);

  final List<DivinationResult> _records;

  @override
  Future<int> deleteRecord(String id) async {
    _records.removeWhere((record) => record.id == id);
    return 1;
  }

  @override
  Future<List<DivinationResult>> getAllRecords() async =>
      List<DivinationResult>.from(_records);
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

void main() {
  group('HistoryListViewModel', () {
    test('initialize 应加载记录并默认按最新优先', () async {
      final now = DateTime(2026, 4, 19, 10, 0);
      final viewModel = HistoryListViewModel(
        service: _FakeHistoryListService([
          _FakeResult(
            id: 'older',
            systemType: DivinationType.liuYao,
            castMethod: CastMethod.time,
            castTime: now.subtract(const Duration(hours: 2)),
            summary: '较早记录',
          ),
          _FakeResult(
            id: 'newer',
            systemType: DivinationType.meiHua,
            castMethod: CastMethod.number,
            castTime: now.subtract(const Duration(minutes: 10)),
            summary: '较晚记录',
          ),
        ]),
      );

      await viewModel.initialize();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.records, hasLength(2));
      expect(viewModel.filteredRecords.map((e) => e.id), ['newer', 'older']);
      expect(viewModel.sortOrder, SortOrder.newestFirst);
    });

    test('筛选、搜索和排序应联动生效', () async {
      final now = DateTime(2026, 4, 19, 10, 0);
      final viewModel = HistoryListViewModel(
        service: _FakeHistoryListService([
          _FakeResult(
            id: 'liuyao-new',
            systemType: DivinationType.liuYao,
            castMethod: CastMethod.time,
            castTime: now.subtract(const Duration(minutes: 5)),
            summary: '事业进展',
          ),
          _FakeResult(
            id: 'liuyao-old',
            systemType: DivinationType.liuYao,
            castMethod: CastMethod.time,
            castTime: now.subtract(const Duration(hours: 3)),
            summary: '感情走向',
          ),
          _FakeResult(
            id: 'meihua',
            systemType: DivinationType.meiHua,
            castMethod: CastMethod.number,
            castTime: now.subtract(const Duration(minutes: 15)),
            summary: '事业选择',
          ),
        ]),
      );

      await viewModel.initialize();
      viewModel.setSystemType(DivinationType.liuYao);
      viewModel.setSearchQuery('感情');

      expect(viewModel.hasActiveFilter, isTrue);
      expect(viewModel.filteredRecords.map((e) => e.id), ['liuyao-old']);

      viewModel.setSearchQuery('');
      viewModel.setSortOrder(SortOrder.oldestFirst);

      expect(viewModel.filteredRecords.map((e) => e.id), [
        'liuyao-old',
        'liuyao-new',
      ]);

      viewModel.clearFilters();

      expect(viewModel.selectedSystemType, isNull);
      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.filteredRecords, hasLength(3));
    });

    test('deleteRecord 应更新原始列表与筛选结果', () async {
      final now = DateTime(2026, 4, 19, 10, 0);
      final viewModel = HistoryListViewModel(
        service: _FakeHistoryListService([
          _FakeResult(
            id: 'delete-me',
            systemType: DivinationType.xiaoLiuRen,
            castMethod: CastMethod.reportNumber,
            castTime: now,
            summary: '待删除',
          ),
          _FakeResult(
            id: 'keep-me',
            systemType: DivinationType.xiaoLiuRen,
            castMethod: CastMethod.time,
            castTime: now.subtract(const Duration(hours: 1)),
            summary: '保留',
          ),
        ]),
      );

      await viewModel.initialize();
      viewModel.setSearchQuery('待删');

      expect(viewModel.filteredRecords.map((e) => e.id), ['delete-me']);

      final message = await viewModel.deleteRecord('delete-me');

      expect(message, '记录已删除');
      expect(viewModel.records.map((e) => e.id), ['keep-me']);
      expect(viewModel.filteredRecords, isEmpty);
    });
  });
}
