import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/viewmodels/liuyao_analysis_controller.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/repositories/divination_repository.dart';
import 'package:wanxiang_paipan/domain/services/gua_calculator.dart';
import 'package:wanxiang_paipan/domain/services/shared/tiangan_dizhi_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';

class MockDivinationRepository extends Mock implements DivinationRepository {}

LiuYaoResult buildResult({int? yongShenPosition}) {
  const riGanZhi = '甲子';
  final split = TianGanDiZhiService.splitGanZhi(riGanZhi)!;
  return LiuYaoResult(
    id: 'test-id',
    castTime: DateTime(2026, 7, 1, 10),
    castMethod: CastMethod.manual,
    mainGua: GuaCalculator.calculateGua([7, 7, 7, 7, 7, 7]),
    lunarInfo: LunarInfo(
      yueJian: '午',
      riGan: split[0],
      riZhi: split[1],
      riGanZhi: riGanZhi,
      kongWang: TianGanDiZhiService.getKongWang(riGanZhi),
      yearGanZhi: '丙午',
      monthGanZhi: '甲午',
    ),
    liuShen: const ['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武'],
    yongShenPosition: yongShenPosition,
  );
}

void main() {
  late MockDivinationRepository repository;

  setUpAll(() {
    registerFallbackValue(buildResult());
  });

  setUp(() {
    repository = MockDivinationRepository();
    when(() => repository.updateRecord(any())).thenAnswer((_) async => true);
  });

  group('LiuYaoAnalysisController 初始化', () {
    test('无用神时报告只含客观分析', () {
      final controller = LiuYaoAnalysisController(
          result: buildResult(), repository: repository);
      expect(controller.hasYongShen, isFalse);
      expect(controller.report.yongShen, isNull);
      expect(controller.report.yaoTags, isNotEmpty);
    });

    test('已保存用神的记录重开时恢复推理链且不伪造应期', () {
      final controller = LiuYaoAnalysisController(
          result: buildResult(yongShenPosition: 2), repository: repository);
      expect(controller.hasYongShen, isTrue);
      expect(controller.report.yongShen!.position, 2);
      expect(controller.report.yingQi, isEmpty);
    });
  });

  group('LiuYaoAnalysisController 选择用神', () {
    test('选定后重算报告、通知监听并持久化', () async {
      final controller = LiuYaoAnalysisController(
          result: buildResult(), repository: repository);
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.selectYongShen(2);

      expect(notified, 1);
      expect(controller.yongShenPosition, 2);
      expect(controller.report.yongShen!.position, 2);
      expect(controller.report.verdictSummary, contains('妻财'));
      final captured = verify(() => repository.updateRecord(captureAny()))
          .captured
          .single as LiuYaoResult;
      expect(captured.yongShenPosition, 2);
    });

    test('重复选择同一爻位为无操作', () async {
      final controller = LiuYaoAnalysisController(
          result: buildResult(yongShenPosition: 2), repository: repository);
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.selectYongShen(2);

      expect(notified, 0);
      verifyNever(() => repository.updateRecord(any()));
    });

    test('换选用神即时切换推理链', () async {
      final controller = LiuYaoAnalysisController(
          result: buildResult(yongShenPosition: 2), repository: repository);
      await controller.selectYongShen(4);
      expect(controller.report.yongShen!.position, 4);
      expect(controller.report.verdictSummary, contains('官鬼'));
    });

    test('持久化失败不影响界面状态', () async {
      when(() => repository.updateRecord(any()))
          .thenThrow(Exception('db error'));
      final controller = LiuYaoAnalysisController(
          result: buildResult(), repository: repository);

      await controller.selectYongShen(2);

      expect(controller.yongShenPosition, 2);
      expect(controller.report.yongShen, isNotNull);
    });
  });

  group('LiuYaoAnalysisController 取消用神', () {
    test('取消后回到客观分析并持久化', () async {
      final controller = LiuYaoAnalysisController(
          result: buildResult(yongShenPosition: 2), repository: repository);

      await controller.clearYongShen();

      expect(controller.hasYongShen, isFalse);
      expect(controller.report.yongShen, isNull);
      final captured = verify(() => repository.updateRecord(captureAny()))
          .captured
          .single as LiuYaoResult;
      expect(captured.yongShenPosition, isNull);
    });

    test('未选用神时取消为无操作', () async {
      final controller = LiuYaoAnalysisController(
          result: buildResult(), repository: repository);
      await controller.clearYongShen();
      verifyNever(() => repository.updateRecord(any()));
    });
  });

  group('LiuYaoAnalysisController 四柱修改', () {
    test('updateLunar：月建/空亡/六神联动并持久化', () async {
      final controller = LiuYaoAnalysisController(
          result: buildResult(), repository: repository);

      await controller.updateLunar(
        yearGanZhi: '甲子',
        monthGanZhi: '己巳',
        riGanZhi: '乙亥',
        hourGanZhi: null,
      );

      final lunar = controller.result.lunarInfo;
      expect(lunar.yearGanZhi, '甲子');
      expect(lunar.monthGanZhi, '己巳');
      expect(lunar.yueJian, '巳'); // 月建取月支
      expect(lunar.riGanZhi, '乙亥');
      expect(lunar.kongWang, ['申', '酉']); // 乙亥在甲戌旬
      expect(lunar.hourGanZhi, isNull);
      expect(controller.result.liuShen.first, '青龙'); // 乙日起青龙
      verify(() => repository.updateRecord(any())).called(1);
    });

    test('updateLunar：非法干支拒绝且不落库', () async {
      final controller = LiuYaoAnalysisController(
          result: buildResult(), repository: repository);
      await controller.updateLunar(
        yearGanZhi: '甲子',
        monthGanZhi: '乙子', // 非法组合
        riGanZhi: '乙亥',
      );
      expect(controller.result.lunarInfo.yueJian, '午'); // 原值不变
      verifyNever(() => repository.updateRecord(any()));
    });
  });

  group('LiuYaoResult 序列化兼容', () {
    Map<String, dynamic> roundTrip(LiuYaoResult result) =>
        jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>;

    test('旧记录 JSON 无用神字段时反序列化为 null', () {
      final json = roundTrip(buildResult())
        ..remove('yongShenPosition')
        ..remove('yongShenIsFuShen');
      final decoded = LiuYaoResult.fromJson(json);
      expect(decoded.yongShenPosition, isNull);
      expect(decoded.yongShenIsFuShen, isFalse);
    });

    test('用神字段完整往返', () {
      final decoded =
          LiuYaoResult.fromJson(roundTrip(buildResult(yongShenPosition: 3)));
      expect(decoded.yongShenPosition, 3);
    });
  });
}
