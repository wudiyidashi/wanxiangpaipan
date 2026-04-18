import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/screens/history/history_filter.dart';

class _FakeRecord {
  _FakeRecord({
    required this.id,
    required this.systemName,
    required this.summary,
    required this.castTime,
  });
  final String id;
  final String systemName;
  final String summary;
  final DateTime castTime;
}

void main() {
  group('applySearch', () {
    final records = [
      _FakeRecord(id: 'r1', systemName: '六爻', summary: '问事业 乾为天 → 天风姤', castTime: DateTime(2026, 4, 18, 10)),
      _FakeRecord(id: 'r2', systemName: '大六壬', summary: '问婚姻 涉害课', castTime: DateTime(2026, 4, 17, 10)),
      _FakeRecord(id: 'r3', systemName: '六爻', summary: '求财 坤为地', castTime: DateTime(2026, 4, 16, 10)),
    ];

    test('empty query returns all records', () {
      final r = applySearch<_FakeRecord>(
        records,
        query: '',
        extractor: (x) => '${x.systemName} ${x.summary}',
      );
      expect(r.length, 3);
    });

    test('matches systemName', () {
      final r = applySearch<_FakeRecord>(
        records,
        query: '大六壬',
        extractor: (x) => '${x.systemName} ${x.summary}',
      );
      expect(r.map((e) => e.id), ['r2']);
    });

    test('matches summary keyword', () {
      final r = applySearch<_FakeRecord>(
        records,
        query: '事业',
        extractor: (x) => '${x.systemName} ${x.summary}',
      );
      expect(r.map((e) => e.id), ['r1']);
    });

    test('case-insensitive', () {
      final r = applySearch<_FakeRecord>(
        records,
        query: 'KUN',
        extractor: (x) => '${x.systemName} ${x.summary}',
      );
      // 中文字符不受大小写影响，但英文应命中
      expect(r.length, 0); // 'kun' 不在任何 summary 里
    });

    test('trims whitespace', () {
      final r = applySearch<_FakeRecord>(
        records,
        query: '   事业   ',
        extractor: (x) => '${x.systemName} ${x.summary}',
      );
      expect(r.length, 1);
    });
  });

  group('applySort', () {
    final records = [
      _FakeRecord(id: 'a', systemName: 'x', summary: '', castTime: DateTime(2026, 1, 1)),
      _FakeRecord(id: 'b', systemName: 'x', summary: '', castTime: DateTime(2026, 3, 1)),
      _FakeRecord(id: 'c', systemName: 'x', summary: '', castTime: DateTime(2026, 2, 1)),
    ];

    test('newestFirst orders descending', () {
      final r = applySort<_FakeRecord>(
        records,
        order: SortOrder.newestFirst,
        timeExtractor: (x) => x.castTime,
      );
      expect(r.map((e) => e.id), ['b', 'c', 'a']);
    });

    test('oldestFirst orders ascending', () {
      final r = applySort<_FakeRecord>(
        records,
        order: SortOrder.oldestFirst,
        timeExtractor: (x) => x.castTime,
      );
      expect(r.map((e) => e.id), ['a', 'c', 'b']);
    });

    test('returns new list without mutating input', () {
      final input = [...records];
      applySort<_FakeRecord>(
        input,
        order: SortOrder.newestFirst,
        timeExtractor: (x) => x.castTime,
      );
      expect(input.map((e) => e.id), ['a', 'b', 'c']); // 原序未变
    });
  });

  group('groupByTime', () {
    final now = DateTime(2026, 4, 18, 12);

    test('today records go to today bucket', () {
      final records = [
        _FakeRecord(id: 't1', systemName: 'x', summary: '', castTime: DateTime(2026, 4, 18, 9)),
      ];
      final groups = groupByTime<_FakeRecord>(
        records,
        now: now,
        timeExtractor: (x) => x.castTime,
      );
      expect(groups[TimeGroup.today]!.length, 1);
      expect(groups[TimeGroup.lastSevenDays]!.length, 0);
      expect(groups[TimeGroup.earlier]!.length, 0);
    });

    test('yesterday goes to lastSevenDays bucket', () {
      final records = [
        _FakeRecord(id: 'y1', systemName: 'x', summary: '', castTime: DateTime(2026, 4, 17, 9)),
      ];
      final groups = groupByTime<_FakeRecord>(
        records,
        now: now,
        timeExtractor: (x) => x.castTime,
      );
      expect(groups[TimeGroup.today]!.length, 0);
      expect(groups[TimeGroup.lastSevenDays]!.length, 1);
    });

    test('8 days ago goes to earlier bucket', () {
      final records = [
        _FakeRecord(id: 'e1', systemName: 'x', summary: '', castTime: DateTime(2026, 4, 10, 9)),
      ];
      final groups = groupByTime<_FakeRecord>(
        records,
        now: now,
        timeExtractor: (x) => x.castTime,
      );
      expect(groups[TimeGroup.today]!.length, 0);
      expect(groups[TimeGroup.lastSevenDays]!.length, 0);
      expect(groups[TimeGroup.earlier]!.length, 1);
    });

    test('preserves input order within each bucket', () {
      final records = [
        _FakeRecord(id: 't1', systemName: 'x', summary: '', castTime: DateTime(2026, 4, 18, 10)),
        _FakeRecord(id: 't2', systemName: 'x', summary: '', castTime: DateTime(2026, 4, 18, 8)),
      ];
      final groups = groupByTime<_FakeRecord>(
        records,
        now: now,
        timeExtractor: (x) => x.castTime,
      );
      expect(groups[TimeGroup.today]!.map((e) => e.id), ['t1', 't2']);
    });

    test('always returns all three bucket keys (even empty)', () {
      final groups = groupByTime<_FakeRecord>(
        [],
        now: now,
        timeExtractor: (x) => x.castTime,
      );
      expect(groups.keys, containsAll([TimeGroup.today, TimeGroup.lastSevenDays, TimeGroup.earlier]));
    });
  });
}
