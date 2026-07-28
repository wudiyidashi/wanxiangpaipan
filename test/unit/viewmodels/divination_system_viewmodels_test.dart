import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/repositories/divination_repository_impl.dart';
import 'package:wanxiang_paipan/domain/divination_registry.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/dlr_cast_time_service.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_system.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_cast_time.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/pan_params.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/viewmodels/daliuren_viewmodel.dart';
import 'package:wanxiang_paipan/divination_systems/meihua/meihua_system.dart';
import 'package:wanxiang_paipan/divination_systems/meihua/viewmodels/meihua_viewmodel.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/models/xiaoliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/viewmodels/xiaoliuren_viewmodel.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/xiaoliuren_system.dart';

import '../data/repositories/divination_repository_test.dart'
    show MockSecureStorage;

void main() {
  group('Divination system viewmodels', () {
    late AppDatabase database;
    late MockSecureStorage secureStorage;
    late DivinationRegistry registry;
    late DivinationRepositoryImpl repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      secureStorage = MockSecureStorage();
      registry = DivinationRegistry();
      registry.clear();
      registry.register(DaLiuRenSystem());
      registry.register(MeiHuaSystem());
      registry.register(XiaoLiuRenSystem());

      repository = DivinationRepositoryImpl(
        database: database,
        secureStorage: secureStorage,
        registry: registry,
      );
    });

    tearDown(() async {
      await database.close();
      registry.clear();
    });

    test('MeiHuaViewModel 应能起卦并保存占问', () async {
      final viewModel = MeiHuaViewModel(
        system: MeiHuaSystem(),
        repository: repository,
      );

      await viewModel.castByNumbers(
        upperNumber: 3,
        lowerNumber: 5,
        castTime: DateTime(2026, 4, 19, 9, 22),
      );

      expect(viewModel.hasError, isFalse);
      expect(viewModel.hasResult, isTrue);
      expect(viewModel.benGuaName, isNotEmpty);
      expect(viewModel.bianGuaName, isNotEmpty);

      await viewModel.saveRecord(question: '测试梅花占问');

      expect(viewModel.question, '测试梅花占问');
      expect(await repository.getRecordCount(), 1);
      expect(
        await repository.readEncryptedField('question_${viewModel.result!.id}'),
        '测试梅花占问',
      );
    });

    test('XiaoLiuRenViewModel 应能起课并保存九宫记录', () async {
      final viewModel = XiaoLiuRenViewModel(
        system: XiaoLiuRenSystem(),
        repository: repository,
      );

      await viewModel.castByCharacterStrokes(
        firstStroke: 8,
        secondStroke: 11,
        thirdStroke: 6,
        palaceMode: XiaoLiuRenPalaceMode.ninePalaces,
        castTime: DateTime(2026, 4, 19, 9, 22),
      );

      expect(viewModel.hasError, isFalse);
      expect(viewModel.hasResult, isTrue);
      expect(viewModel.palaceMode, XiaoLiuRenPalaceMode.ninePalaces);
      expect(viewModel.finalPosition, isNotNull);

      await viewModel.saveRecord(question: '测试小六壬占问');

      final all = await repository.getAllRecords();
      expect(all, hasLength(1));
      expect(all.first, isA<XiaoLiuRenResult>());
      expect(
        await repository.readEncryptedField('question_${viewModel.result!.id}'),
        '测试小六壬占问',
      );
    });

    test('DaLiuRenViewModel 应能按参数起课并保存占问', () async {
      final viewModel = DaLiuRenViewModel(
        system: DaLiuRenSystem(),
        repository: repository,
      );

      await viewModel.castByTime(
        castTime: DateTime(2026, 4, 19, 9, 22),
        params: const DaLiuRenPanParams(
          guiRenVerse: DaLiuRenGuiRenVerse.classic,
          xunShouMode: DaLiuRenXunShouMode.day,
          showSanChuanOnTop: true,
        ),
      );

      expect(viewModel.hasError, isFalse);
      expect(viewModel.hasResult, isTrue);
      expect(viewModel.tianPan, isNotNull);
      expect(viewModel.panParams?.showSanChuanOnTop, isTrue);

      await viewModel.saveRecord(question: '测试大六壬占问');

      expect(viewModel.question, '测试大六壬占问');
      expect(await repository.getRecordCount(), 1);
      expect(
        await repository.readEncryptedField('question_${viewModel.result!.id}'),
        '测试大六壬占问',
      );
    });

    test('DaLiuRenViewModel 时间派生入口应传递一次捕获的来源 offset', () async {
      final viewModel = DaLiuRenViewModel(
        system: DaLiuRenSystem(),
        repository: repository,
      );
      final instant = DateTime.utc(2022, 4, 20, 2, 24, 18);

      await viewModel.castByTime(
        castTime: instant,
        sourceUtcOffsetMinutes: 330,
      );
      expect(viewModel.hasError, isFalse);
      expect(viewModel.result!.civilTime!.sourceUtcOffsetMinutes, 330);
      expect(viewModel.result!.castInputSnapshot!.utcOffsetMinutes, 330);

      await viewModel.castByReportNumber(
        7,
        castTime: instant,
        sourceUtcOffsetMinutes: -240,
      );
      expect(viewModel.hasError, isFalse);
      expect(viewModel.result!.civilTime!.sourceUtcOffsetMinutes, -240);
      expect(viewModel.result!.castInputSnapshot!.utcOffsetMinutes, -240);

      await viewModel.castByComputer(
        castTime: instant,
        sourceUtcOffsetMinutes: 60,
      );
      expect(viewModel.hasError, isFalse);
      expect(viewModel.result!.civilTime!.sourceUtcOffsetMinutes, 60);
      expect(viewModel.result!.castInputSnapshot!.utcOffsetMinutes, 60);
    });

    test('DaLiuRenViewModel raw 手工入口应强制显式月将并标记输入模式', () async {
      final viewModel = DaLiuRenViewModel(
        system: DaLiuRenSystem(),
        repository: repository,
      );

      await viewModel.castByManual(
        yearGanZhi: '甲辰',
        monthGanZhi: '丙寅',
        dayGanZhi: '甲子',
        hourGanZhi: '甲子',
        monthGeneral: '戌',
      );

      expect(viewModel.hasError, isFalse);
      expect(viewModel.result!.civilTime, isNull);
      expect(
        viewModel.result!.monthGeneralResolution!.mode,
        DlrMonthGeneralResolutionMode.manualOverride,
      );
      expect(viewModel.result!.panParams.monthGeneralMode,
          DaLiuRenMonthGeneralMode.manual);
      expect(viewModel.result!.panParams.manualMonthGeneral, '戌');
      expect(
        viewModel.result!.castInputSnapshot!.normalizedInput,
        containsPair('manualInputMode', DlrManualInputMode.rawPillars.id),
      );
      expect(
        viewModel.result!.castInputSnapshot!.normalizedInput,
        containsPair('calendarValidated', false),
      );
    });

    test('DaLiuRenViewModel calendar-backed 手工入口应提交 typed 预期四柱', () async {
      final viewModel = DaLiuRenViewModel(
        system: DaLiuRenSystem(),
        repository: repository,
      );
      final civilTime = DlrCivilTime(
        instant: DateTime.utc(2022, 4, 20, 2, 24, 18),
        sourceUtcOffsetMinutes: 480,
      );
      final expected = DlrCastTimeService.resolve(civilTime).pillars;

      await viewModel.castByCalendarBackedManual(
        manualCivilDateTime: civilTime.instantUtc,
        sourceUtcOffsetMinutes: civilTime.sourceUtcOffsetMinutes,
        expectedPillars: expected,
        castTime: DateTime.utc(2026, 7, 28, 12),
      );

      expect(viewModel.hasError, isFalse);
      expect(viewModel.result!.civilTime, civilTime);
      expect(viewModel.result!.panParams.monthGeneralMode,
          DaLiuRenMonthGeneralMode.auto);
      expect(
        viewModel.result!.castInputSnapshot!.normalizedInput,
        containsPair(
          'manualInputMode',
          DlrManualInputMode.calendarBacked.id,
        ),
      );
      expect(
        viewModel.result!.castInputSnapshot!.normalizedInput,
        containsPair('calendarValidated', true),
      );
    });
  });
}
