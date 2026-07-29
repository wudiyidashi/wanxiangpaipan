import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/pan_params.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/shen_jiang_config.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/san_chuan_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/shen_jiang_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/si_ke_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/tianpan_service.dart';

const _branches = <String>[
  '子',
  '丑',
  '寅',
  '卯',
  '辰',
  '巳',
  '午',
  '未',
  '申',
  '酉',
  '戌',
  '亥',
];

const _expectedGeneralOrder = <ShenJiang>[
  ShenJiang.guiRen,
  ShenJiang.tengShe,
  ShenJiang.zhuQue,
  ShenJiang.liuHe,
  ShenJiang.gouChen,
  ShenJiang.qingLong,
  ShenJiang.tianKong,
  ShenJiang.baiHu,
  ShenJiang.taiChang,
  ShenJiang.xuanWu,
  ShenJiang.taiYin,
  ShenJiang.tianHou,
];

Map<String, String> _rotation(int offset) => <String, String>{
      for (var index = 0; index < _branches.length; index++)
        _branches[index]: _branches[(index + offset) % _branches.length],
    };

class _PlacementCase {
  const _PlacementCase({
    required this.name,
    required this.hourBranch,
    required this.offset,
    required this.isYangGui,
    required this.selectedGuiRenTianBranch,
    required this.guiRenEarthPalace,
    required this.direction,
    required this.expectedEarthPalaces,
    required this.expectedHeavenBranches,
  });

  final String name;
  final String hourBranch;
  final int offset;
  final bool isYangGui;
  final String selectedGuiRenTianBranch;
  final String guiRenEarthPalace;
  final ShenJiangDirection direction;
  final List<String> expectedEarthPalaces;
  final List<String> expectedHeavenBranches;
}

const _placementCases = <_PlacementCase>[
  _PlacementCase(
    name: '昼贵落子顺布',
    hourBranch: '卯',
    offset: 1,
    isYangGui: true,
    selectedGuiRenTianBranch: '丑',
    guiRenEarthPalace: '子',
    direction: ShenJiangDirection.shun,
    expectedEarthPalaces: <String>[
      '子',
      '丑',
      '寅',
      '卯',
      '辰',
      '巳',
      '午',
      '未',
      '申',
      '酉',
      '戌',
      '亥',
    ],
    expectedHeavenBranches: <String>[
      '丑',
      '寅',
      '卯',
      '辰',
      '巳',
      '午',
      '未',
      '申',
      '酉',
      '戌',
      '亥',
      '子',
    ],
  ),
  _PlacementCase(
    name: '昼贵落巳逆布',
    hourBranch: '卯',
    offset: 8,
    isYangGui: true,
    selectedGuiRenTianBranch: '丑',
    guiRenEarthPalace: '巳',
    direction: ShenJiangDirection.ni,
    expectedEarthPalaces: <String>[
      '巳',
      '辰',
      '卯',
      '寅',
      '丑',
      '子',
      '亥',
      '戌',
      '酉',
      '申',
      '未',
      '午',
    ],
    expectedHeavenBranches: <String>[
      '丑',
      '子',
      '亥',
      '戌',
      '酉',
      '申',
      '未',
      '午',
      '巳',
      '辰',
      '卯',
      '寅',
    ],
  ),
  _PlacementCase(
    name: '夜贵落辰顺布',
    hourBranch: '酉',
    offset: 3,
    isYangGui: false,
    selectedGuiRenTianBranch: '未',
    guiRenEarthPalace: '辰',
    direction: ShenJiangDirection.shun,
    expectedEarthPalaces: <String>[
      '辰',
      '巳',
      '午',
      '未',
      '申',
      '酉',
      '戌',
      '亥',
      '子',
      '丑',
      '寅',
      '卯',
    ],
    expectedHeavenBranches: <String>[
      '未',
      '申',
      '酉',
      '戌',
      '亥',
      '子',
      '丑',
      '寅',
      '卯',
      '辰',
      '巳',
      '午',
    ],
  ),
  _PlacementCase(
    name: '夜贵落酉逆布',
    hourBranch: '酉',
    offset: 10,
    isYangGui: false,
    selectedGuiRenTianBranch: '未',
    guiRenEarthPalace: '酉',
    direction: ShenJiangDirection.ni,
    expectedEarthPalaces: <String>[
      '酉',
      '申',
      '未',
      '午',
      '巳',
      '辰',
      '卯',
      '寅',
      '丑',
      '子',
      '亥',
      '戌',
    ],
    expectedHeavenBranches: <String>[
      '未',
      '午',
      '巳',
      '辰',
      '卯',
      '寅',
      '丑',
      '子',
      '亥',
      '戌',
      '酉',
      '申',
    ],
  ),
];

void main() {
  group('ShenJiangService coordinate placement', () {
    for (final placementCase in _placementCases) {
      test(placementCase.name, () {
        final tianPanMap = _rotation(placementCase.offset);
        final config = ShenJiangService.configureShenJiang(
          riGan: '甲',
          shiZhi: placementCase.hourBranch,
          tianPanMap: tianPanMap,
        );
        final expectedHeavenMap = Map<String, ShenJiang>.fromIterables(
          placementCase.expectedHeavenBranches,
          _expectedGeneralOrder,
        );
        final expectedEarthMap = Map<String, ShenJiang>.fromIterables(
          placementCase.expectedEarthPalaces,
          _expectedGeneralOrder,
        );

        expect(config.isYangGui, placementCase.isYangGui);
        expect(
          config.selectedGuiRenTianBranch,
          placementCase.selectedGuiRenTianBranch,
        );
        expect(config.guiRenEarthPalace, placementCase.guiRenEarthPalace);
        expect(config.actualDirection, placementCase.direction);
        expect(config.tianBranchToGeneral, expectedHeavenMap);
        expect(config.earthPalaceToGeneral, expectedEarthMap);
        expect(config.positions, hasLength(12));
        for (var index = 0; index < 12; index++) {
          final position = config.positions[index];
          expect(position.shenJiang, _expectedGeneralOrder[index]);
          expect(
            position.heavenBranch,
            placementCase.expectedHeavenBranches[index],
          );
          expect(
            position.earthPalace,
            placementCase.expectedEarthPalaces[index],
          );
        }
        expect(
          config.executionRuleRef.ruleId,
          'dlr.project.pan.shenjiang.landing-palace-layout',
        );
        expect(
          config.classicAttributionRuleIds,
          <String>[
            'dlr.rule.shenjiang.001.day-night-selection',
            'dlr.rule.shenjiang.004.direction-by-earth-palace',
            'dlr.rule.shenjiang.005.twelve-generals-order',
            'dlr.rule.shenjiang.006.dual-coordinate-layout',
          ],
        );

        final siKe = SiKeService.arrangeSiKe(
          riGan: '甲',
          riZhi: '子',
          tianPanMap: tianPanMap,
          resolveChengShen: config.generalForHeavenBranch,
        );
        for (final lesson in siKe.allKe) {
          expect(
            lesson.chengShen,
            expectedHeavenMap[lesson.shangShen],
            reason: '${placementCase.name} 四课按天盘支取将',
          );
        }

        final sanChuan = SanChuanService.deriveSanChuan(
          siKe: siKe,
          tianPanMap: tianPanMap,
          shenJiangConfig: config,
        );
        for (final transmission in sanChuan.allChuan) {
          expect(
            transmission.chengShen,
            expectedHeavenMap[transmission.diZhi],
            reason: '${placementCase.name} 三传按天盘支取将',
          );
        }
      });
    }

    test('强制昼夜只覆盖贵人选择，不覆盖落宫所定方向', () {
      final forcedDay = ShenJiangService.configureShenJiang(
        riGan: '甲',
        shiZhi: '子',
        tianPanMap: _rotation(8),
        dayNightMode: DaLiuRenDayNightMode.day,
      );
      final forcedNight = ShenJiangService.configureShenJiang(
        riGan: '甲',
        shiZhi: '卯',
        tianPanMap: _rotation(3),
        dayNightMode: DaLiuRenDayNightMode.night,
      );

      expect(forcedDay.isYangGui, isTrue);
      expect(forcedDay.selectedGuiRenTianBranch, '丑');
      expect(forcedDay.actualDirection, ShenJiangDirection.ni);
      expect(forcedNight.isYangGui, isFalse);
      expect(forcedNight.selectedGuiRenTianBranch, '未');
      expect(forcedNight.actualDirection, ShenJiangDirection.shun);
    });

    test('自动模式逐支按卯至申取昼贵、酉至寅取夜贵', () {
      const expectedDayByHour = <String, bool>{
        '子': false,
        '丑': false,
        '寅': false,
        '卯': true,
        '辰': true,
        '巳': true,
        '午': true,
        '未': true,
        '申': true,
        '酉': false,
        '戌': false,
        '亥': false,
      };

      for (final entry in expectedDayByHour.entries) {
        final config = ShenJiangService.configureShenJiang(
          riGan: '甲',
          shiZhi: entry.key,
          tianPanMap: _rotation(1),
        );
        expect(config.isYangGui, entry.value, reason: '${entry.key}时昼夜取贵');
        expect(
          config.selectedGuiRenTianBranch,
          entry.value ? '丑' : '未',
          reason: '${entry.key}时所选贵人天盘支',
        );
      }
    });
  });

  group('approved Guide noble-general oracles', () {
    const cases = <({
      String dayStem,
      String hourBranch,
      String monthGeneral,
      String selectedHeaven,
      String earthPalace,
      ShenJiangDirection direction,
    })>[
      (
        dayStem: '壬',
        hourBranch: '卯',
        monthGeneral: '巳',
        selectedHeaven: '巳',
        earthPalace: '卯',
        direction: ShenJiangDirection.shun,
      ),
      (
        dayStem: '乙',
        hourBranch: '卯',
        monthGeneral: '戌',
        selectedHeaven: '子',
        earthPalace: '巳',
        direction: ShenJiangDirection.ni,
      ),
      (
        dayStem: '庚',
        hourBranch: '辰',
        monthGeneral: '寅',
        selectedHeaven: '丑',
        earthPalace: '卯',
        direction: ShenJiangDirection.shun,
      ),
    ];

    test('三张已批准古例固定贵人天盘支、落宫和顺逆', () {
      for (final oracle in cases) {
        final tianPanMap = TianPanService.arrangeTianPan(
          oracle.monthGeneral,
          oracle.hourBranch,
        );
        final config = ShenJiangService.configureShenJiang(
          riGan: oracle.dayStem,
          shiZhi: oracle.hourBranch,
          tianPanMap: tianPanMap,
        );

        expect(config.isYangGui, isTrue);
        expect(config.selectedGuiRenTianBranch, oracle.selectedHeaven);
        expect(config.guiRenEarthPalace, oracle.earthPalace);
        expect(config.actualDirection, oracle.direction);
      }
    });
  });

  group('strict input boundary', () {
    test('非法天干、时支和天盘均失败', () {
      expect(
        () => ShenJiangService.configureShenJiang(
          riGan: '子',
          shiZhi: '卯',
          tianPanMap: _rotation(1),
        ),
        throwsArgumentError,
      );
      for (final mode in DaLiuRenDayNightMode.values) {
        expect(
          () => ShenJiangService.configureShenJiang(
            riGan: '甲',
            shiZhi: '甲',
            tianPanMap: _rotation(1),
            dayNightMode: mode,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => ShenJiangService.configureShenJiang(
          riGan: '甲',
          shiZhi: '卯',
          tianPanMap: <String, String>{'子': '丑'},
        ),
        throwsArgumentError,
      );
    });

    test('jiaDayAlt 仅可历史解码，不得生成新盘', () {
      expect(
        () => ShenJiangService.configureShenJiang(
          riGan: '甲',
          shiZhi: '卯',
          tianPanMap: _rotation(1),
          guiRenVerse: DaLiuRenGuiRenVerse.jiaDayAlt,
        ),
        throwsArgumentError,
      );
      expect(
        () => ShenJiangService.configureShenJiang(
          riGan: '乙',
          shiZhi: '卯',
          tianPanMap: _rotation(1),
          guiRenVerse: DaLiuRenGuiRenVerse.jiaDayAlt,
        ),
        throwsArgumentError,
      );
    });

    test('贵人常量查询不再为非法日干回退丑未', () {
      expect(
        () => DaLiuRenConstants.getGuiRenPosition('子'),
        throwsArgumentError,
      );
    });
  });
}
