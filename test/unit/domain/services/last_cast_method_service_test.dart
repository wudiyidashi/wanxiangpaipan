import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/repositories/divination_repository.dart';
import 'package:wanxiang_paipan/domain/services/last_cast_method_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

void main() {
  group('LastCastMethodService', () {
    late _FakeRepository repository;
    late LastCastMethodService service;

    setUp(() {
      repository = _FakeRepository();
      service = LastCastMethodService(repository: repository);
    });

    test('无历史记录时返回 null', () async {
      final method = await service.getLastMethod(
        DivinationType.liuYao,
        allowed: CastMethod.values,
      );
      expect(method, isNull);
    });

    test('返回目标系统最近一条记录的起卦方式', () async {
      repository.records = [
        _record(DivinationType.liuYao, CastMethod.time, DateTime(2026, 4, 19)),
        _record(DivinationType.liuYao, CastMethod.coin, DateTime(2026, 4, 18)),
      ];
      final method = await service.getLastMethod(
        DivinationType.liuYao,
        allowed: CastMethod.values,
      );
      expect(method, CastMethod.time);
    });

    test('历史记录里的方式不在 allowed 中时返回 null', () async {
      repository.records = [
        _record(DivinationType.liuYao, CastMethod.reportNumber, DateTime.now()),
      ];
      final method = await service.getLastMethod(
        DivinationType.liuYao,
        allowed: const [CastMethod.coin, CastMethod.time],
      );
      expect(method, isNull);
    });

    test('只看目标系统的记录，不跨系统串读', () async {
      repository.records = [
        _record(DivinationType.liuYao, CastMethod.coin, DateTime(2026, 4, 19)),
      ];
      final method = await service.getLastMethod(
        DivinationType.meiHua,
        allowed: CastMethod.values,
      );
      expect(method, isNull);
    });
  });
}

class _FakeRepository implements DivinationRepository {
  List<DivinationResult> records = [];

  @override
  Future<List<DivinationResult>> getRecordsBySystemType(
      DivinationType systemType) async {
    return records.where((r) => r.systemType == systemType).toList()
      ..sort((a, b) => b.castTime.compareTo(a.castTime));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

DivinationResult _record(
    DivinationType type, CastMethod method, DateTime time) {
  return _StubResult(type: type, method: method, time: time);
}

class _StubResult implements DivinationResult {
  _StubResult({
    required DivinationType type,
    required CastMethod method,
    required DateTime time,
  })  : _type = type,
        _method = method,
        _time = time;

  final DivinationType _type;
  final CastMethod _method;
  final DateTime _time;

  @override
  String get id => 'stub';

  @override
  DateTime get castTime => _time;

  @override
  CastMethod get castMethod => _method;

  @override
  DivinationType get systemType => _type;

  @override
  LunarInfo get lunarInfo => const LunarInfo(
        yueJian: '',
        riGan: '',
        riZhi: '',
        riGanZhi: '',
        kongWang: [],
        yearGanZhi: '',
        monthGanZhi: '',
      );

  @override
  String getSummary() => '';

  @override
  Map<String, dynamic> toJson() => {};
}
