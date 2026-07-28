import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/si_ke_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/tianpan_service.dart';

Map<String, String> _rotation(int offset) {
  const branches = DaLiuRenConstants.diZhi;
  return <String, String>{
    for (var index = 0; index < branches.length; index++)
      branches[index]: branches[(index + offset) % branches.length],
  };
}

ShenJiang? _testResolver(String _) => ShenJiang.guiRen;

const _guideOracles = <String, Map<String, Object>>{
  'dlr.case.zhinan.renyin-guimao-liu-tuizhai': <String, Object>{
    'dayPillar': '壬寅',
    'hourPillar': '癸卯',
    'monthGeneral': '巳',
    'reviewer': 'c00_independent_recheck (Codex)',
    'lessons': <String>['壬/丑', '丑/卯', '寅/辰', '辰/午'],
  },
  'dlr.case.zhinan.yiwei-jimao-feng-yunsheng': <String, Object>{
    'dayPillar': '乙未',
    'hourPillar': '己卯',
    'monthGeneral': '戌',
    'reviewer': 'c00_independent_recheck (Codex)',
    'lessons': <String>['乙/亥', '亥/午', '未/寅', '寅/酉'],
  },
  'dlr.case.zhinan.gengyin-gengchen-ma-lianzhuang': <String, Object>{
    'dayPillar': '庚寅',
    'hourPillar': '庚辰',
    'monthGeneral': '寅',
    'reviewer': 'c00_guide_shehai_review (Codex)',
    'lessons': <String>['庚/午', '午/辰', '寅/子', '子/戌'],
  },
};

void main() {
  group('SiKeService strict construction', () {
    test('rejects invalid day stem/branch pairs and malformed plates', () {
      final validMap = _rotation(1);
      for (final day in <(String, String)>[
        ('甲', '丑'),
        ('甲', '甲'),
        ('子', '子'),
      ]) {
        expect(
          () => SiKeService.arrangeSiKe(
            riGan: day.$1,
            riZhi: day.$2,
            tianPanMap: validMap,
            resolveChengShen: _testResolver,
          ),
          throwsArgumentError,
        );
      }

      final malformed = <Map<String, String>>[
        <String, String>{},
        _rotation(1)..remove('亥'),
        (() {
          final map = _rotation(1)..remove('子');
          return map..['甲'] = '丑';
        })(),
        _rotation(1)..['子'] = '甲',
        _rotation(1)..['子'] = '寅',
        (() {
          final map = _rotation(1);
          final first = map['子']!;
          map['子'] = map['丑']!;
          map['丑'] = first;
          return map;
        })(),
      ];
      for (final map in malformed) {
        expect(
          () => SiKeService.arrangeSiKe(
            riGan: '甲',
            riZhi: '子',
            tianPanMap: map,
            resolveChengShen: _testResolver,
          ),
          throwsArgumentError,
        );
      }
    });

    test('resolver is required for every upper deity and null fails', () {
      final resolved = <String>[];
      expect(
        () => SiKeService.arrangeSiKe(
          riGan: '甲',
          riZhi: '子',
          tianPanMap: _rotation(1),
          resolveChengShen: (branch) {
            resolved.add(branch);
            return resolved.length == 3 ? null : ShenJiang.guiRen;
          },
        ),
        throwsStateError,
      );
      expect(resolved, <String>['卯', '辰', '丑']);
    });

    test('five-element relation text and direction flags agree', () {
      final controlling = SiKeService.arrangeSiKe(
        riGan: '甲',
        riZhi: '子',
        tianPanMap: _rotation(1),
        resolveChengShen: _testResolver,
      );
      expect(controlling.ke1.wuXingRelation, '比和');
      expect(controlling.ke2.wuXingRelation, '下克上');
      expect(controlling.ke2.isZeiKe, isTrue);
      expect(controlling.ke2.isBiYong, isFalse);
      expect(controlling.ke3.wuXingRelation, '上克下');
      expect(controlling.ke3.isZeiKe, isFalse);
      expect(controlling.ke3.isBiYong, isTrue);

      final upperGenerates = SiKeService.arrangeSiKe(
        riGan: '丙',
        riZhi: '午',
        tianPanMap: _rotation(8),
        resolveChengShen: _testResolver,
      );
      expect(upperGenerates.ke3.wuXingRelation, '上生下');
      expect(upperGenerates.ke3.hasKe, isFalse);

      final lowerGenerates = SiKeService.arrangeSiKe(
        riGan: '甲',
        riZhi: '寅',
        tianPanMap: _rotation(4),
        resolveChengShen: _testResolver,
      );
      expect(lowerGenerates.ke3.wuXingRelation, '下生上');
      expect(lowerGenerates.ke3.hasKe, isFalse);
    });
  });

  group('approved Guide fixtures', () {
    test('three independent manual plates lock all four lessons', () {
      final catalog = jsonDecode(
        File('assets/data/daliuren/classics/cases/zhinan.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final cases = catalog['cases'] as List<dynamic>;

      expect(cases, hasLength(3));
      expect(
        cases
            .map((rawCase) =>
                (rawCase as Map<String, dynamic>)['caseId'] as String)
            .toSet(),
        _guideOracles.keys.toSet(),
      );
      for (final rawCase in cases) {
        final fixture = rawCase as Map<String, dynamic>;
        final caseId = fixture['caseId'] as String;
        final oracle = _guideOracles[caseId]!;
        expect(fixture['verificationStatus'], 'approved');
        expect(fixture['evidenceLevel'], 'B');
        expect(fixture['locatorOnly'], isFalse);
        final derivation =
            fixture['expectedDerivation'] as Map<String, dynamic>;
        expect(derivation['method'], 'independentManual');
        expect(derivation['usesProductionCode'], isFalse);
        expect(derivation['reviewer'], oracle['reviewer']);

        final input = fixture['rawInput'] as Map<String, dynamic>;
        final day = input['dayPillar'] as String;
        final hour = input['hourPillar'] as String;
        final monthGeneral = input['monthGeneral'] as String;
        expect(day, oracle['dayPillar']);
        expect(hour, oracle['hourPillar']);
        expect(monthGeneral, oracle['monthGeneral']);
        final map = TianPanService.arrangeTianPan(monthGeneral, hour[1]);
        expect(map[hour[1]], monthGeneral);
        final siKe = SiKeService.arrangeSiKe(
          riGan: day[0],
          riZhi: day[1],
          tianPanMap: map,
          resolveChengShen: _testResolver,
        );
        final expected = (fixture['expectedFacts']
            as Map<String, dynamic>)['fourLessons'] as List<dynamic>;
        expect(expected, hasLength(4));
        expect(
          expected.map((rawLesson) {
            final lesson = rawLesson as Map<String, dynamic>;
            return '${lesson['lower']}/${lesson['upper']}';
          }).toList(),
          oracle['lessons'],
        );

        for (var index = 0; index < expected.length; index++) {
          final lesson = expected[index] as Map<String, dynamic>;
          expect(siKe.allKe[index].index, lesson['ordinal']);
          expect(siKe.allKe[index].xiaShen, lesson['lower']);
          expect(siKe.allKe[index].shangShen, lesson['upper']);
        }
      }
    });
  });

  group('complete fu-yin and fan-yin semantics', () {
    test('only complete identity/opposition plates return true', () {
      expect(SiKeService.isFuYin(_rotation(0)), isTrue);
      expect(SiKeService.isFanYin(_rotation(0)), isFalse);
      expect(SiKeService.isFuYin(_rotation(6)), isFalse);
      expect(SiKeService.isFanYin(_rotation(6)), isTrue);
      expect(SiKeService.isFuYin(_rotation(2)), isFalse);
      expect(SiKeService.isFanYin(_rotation(2)), isFalse);
    });

    test('empty and partial plates fail instead of returning booleans', () {
      expect(
          () => SiKeService.isFuYin(<String, String>{}), throwsArgumentError);
      expect(
          () => SiKeService.isFanYin(<String, String>{}), throwsArgumentError);
      expect(
        () => SiKeService.isFuYin(<String, String>{'子': '子'}),
        throwsArgumentError,
      );
      expect(
        () => SiKeService.isFanYin(<String, String>{'子': '午'}),
        throwsArgumentError,
      );
    });
  });
}
