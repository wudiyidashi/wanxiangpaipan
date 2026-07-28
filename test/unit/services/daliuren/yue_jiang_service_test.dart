import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_cast_time.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/dlr_rule_contract.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/yue_jiang_service.dart';

typedef _BoundaryCase = ({
  String term,
  DateTime beijingWall,
  String previousGeneral,
  String currentGeneral,
});

DateTime _beijingWallToInstant(DateTime wall) => wall.subtract(
      const Duration(hours: 8),
    );

DlrMonthGeneralResolution _resolve(DateTime instant, {int offset = 480}) =>
    YueJiangService.resolve(
      DlrCivilTime(
        instant: instant,
        sourceUtcOffsetMinutes: offset,
      ),
    );

void main() {
  final boundaries = <_BoundaryCase>[
    (
      term: '大寒',
      beijingWall: DateTime.utc(2022, 1, 20, 10, 39, 6),
      previousGeneral: '丑',
      currentGeneral: '子',
    ),
    (
      term: '雨水',
      beijingWall: DateTime.utc(2022, 2, 19, 0, 43, 1),
      previousGeneral: '子',
      currentGeneral: '亥',
    ),
    (
      term: '春分',
      beijingWall: DateTime.utc(2022, 3, 20, 23, 33, 26),
      previousGeneral: '亥',
      currentGeneral: '戌',
    ),
    (
      term: '谷雨',
      beijingWall: DateTime.utc(2022, 4, 20, 10, 24, 18),
      previousGeneral: '戌',
      currentGeneral: '酉',
    ),
    (
      term: '小满',
      beijingWall: DateTime.utc(2022, 5, 21, 9, 22, 36),
      previousGeneral: '酉',
      currentGeneral: '申',
    ),
    (
      term: '夏至',
      beijingWall: DateTime.utc(2022, 6, 21, 17, 13, 51),
      previousGeneral: '申',
      currentGeneral: '未',
    ),
    (
      term: '大暑',
      beijingWall: DateTime.utc(2022, 7, 23, 4, 7),
      previousGeneral: '未',
      currentGeneral: '午',
    ),
    (
      term: '处暑',
      beijingWall: DateTime.utc(2022, 8, 23, 11, 16, 11),
      previousGeneral: '午',
      currentGeneral: '巳',
    ),
    (
      term: '秋分',
      beijingWall: DateTime.utc(2022, 9, 23, 9, 3, 43),
      previousGeneral: '巳',
      currentGeneral: '辰',
    ),
    (
      term: '霜降',
      beijingWall: DateTime.utc(2022, 10, 23, 18, 35, 43),
      previousGeneral: '辰',
      currentGeneral: '卯',
    ),
    (
      term: '小雪',
      beijingWall: DateTime.utc(2022, 11, 22, 16, 20, 30),
      previousGeneral: '卯',
      currentGeneral: '寅',
    ),
    (
      term: '冬至',
      beijingWall: DateTime.utc(2022, 12, 22, 5, 48, 12),
      previousGeneral: '寅',
      currentGeneral: '丑',
    ),
  ];

  group('YueJiangService', () {
    for (final testCase in boundaries) {
      test('${testCase.term} 在 t-1/t/t+1 秒切换月将', () {
        final boundary = _beijingWallToInstant(testCase.beijingWall);
        final before = _resolve(boundary.subtract(const Duration(seconds: 1)));
        final at = _resolve(boundary);
        final after = _resolve(boundary.add(const Duration(seconds: 1)));

        expect(before.yueJiang, testCase.previousGeneral);
        expect(at.yueJiang, testCase.currentGeneral);
        expect(after.yueJiang, testCase.currentGeneral);
        expect(at.effectiveZhongQi, testCase.term);
        expect(at.effectiveZhongQiInstantUtc, boundary);
      });
    }

    test('谷雨同一 absolute instant 不受来源 offset 影响', () {
      final instant = DateTime.utc(2022, 4, 20, 2, 24, 18);
      for (final offset in <int>[480, 0, 330]) {
        final result = _resolve(instant, offset: offset);
        expect(result.effectiveZhongQi, '谷雨', reason: '$offset');
        expect(result.yueJiang, '酉', reason: '$offset');
      }
    });

    test('清明是节，前一秒、当刻、后一秒均不换将', () {
      final boundary = DateTime.utc(2022, 4, 4, 19, 20, 14);
      for (final instant in <DateTime>[
        boundary.subtract(const Duration(seconds: 1)),
        boundary,
        boundary.add(const Duration(seconds: 1)),
      ]) {
        final result = _resolve(instant);
        expect(result.effectiveZhongQi, '春分');
        expect(result.yueJiang, '戌');
      }
    });

    test('typed provenance 区分 project execution 与 classic attribution', () {
      final result = _resolve(DateTime.utc(2022, 4, 20, 2, 24, 18));

      expect(result.calendarEngine, 'lunar');
      expect(result.calendarEngineVersion, '1.7.8');
      expect(result.executionRuleRef.kind, DlrRuleKind.project);
      expect(
        result.executionRuleRef.ruleId,
        DlrProjectPanRuleIds.monthGeneralByZhongQiInstant,
      );
      expect(result.executionRuleRef.executableApproved, isFalse);
      expect(
        result.classicAttributionRuleIds,
        YueJiangService.classicAttributionRuleIds,
      );
    });

    test('typed resolution 拒绝跨规则集或伪造的古籍 attribution', () {
      DlrMonthGeneralResolution build({
        required DlrRuleRef executionRuleRef,
        DlrMonthGeneralResolutionMode mode =
            DlrMonthGeneralResolutionMode.zhongQi,
        List<String> classicAttributionRuleIds = const <String>[],
      }) =>
          DlrMonthGeneralResolution(
            yueJiang: '酉',
            mode: mode,
            effectiveZhongQi:
                mode == DlrMonthGeneralResolutionMode.zhongQi ? '谷雨' : null,
            effectiveZhongQiInstantUtc:
                mode == DlrMonthGeneralResolutionMode.zhongQi
                    ? DateTime.utc(2022, 4, 20, 2, 24, 18)
                    : null,
            calendarEngine: 'lunar',
            calendarEngineVersion: '1.7.8',
            algorithmVersion: YueJiangService.algorithmVersion,
            executionRuleRef: executionRuleRef,
            classicAttributionRuleIds: classicAttributionRuleIds,
          );

      expect(
        () => build(
          executionRuleRef: DlrRuleRef.project(
            DlrProjectPanRuleIds.monthGeneralByZhongQiInstant,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => build(
          executionRuleRef: DlrRuleRef.projectPan(
            DlrProjectPanRuleIds.monthGeneralByZhongQiInstant,
          ),
          classicAttributionRuleIds: const <String>['not-a-classic-rule'],
        ),
        throwsArgumentError,
      );
      expect(
        () => build(
          executionRuleRef: DlrRuleRef.projectPan(
            DlrProjectPanRuleIds.manualMonthGeneralOverride,
          ),
          mode: DlrMonthGeneralResolutionMode.manualOverride,
          classicAttributionRuleIds: const <String>[
            'dlr.rule.pan.001.month-general-by-zhongqi',
          ],
        ),
        throwsArgumentError,
      );
    });

    test('未登记中气显式失败，不回退月建', () {
      expect(
        () => YueJiangService.getYueJiangByZhongQi('清明'),
        throwsStateError,
      );
    });
  });
}
