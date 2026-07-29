import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/tianpan.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/shen_jiang_service.dart';
import 'package:wanxiang_paipan/domain/services/daliuren/tianpan_service.dart';

Map<String, String> _rotation(int offset) {
  const branches = DaLiuRenConstants.diZhi;
  return <String, String>{
    for (var index = 0; index < branches.length; index++)
      branches[index]: branches[(index + offset) % branches.length],
  };
}

Map<String, String> _invalidKeyMap() {
  final map = _rotation(1)..remove('子');
  return map..['甲'] = '丑';
}

Map<String, String> _invalidValueMap() => _rotation(1)..['子'] = '甲';

Map<String, String> _duplicateValueMap() => _rotation(1)..['子'] = '寅';

Map<String, String> _scrambledBijection() {
  final map = _rotation(1);
  final first = map['子']!;
  map['子'] = map['丑']!;
  map['丑'] = first;
  return map;
}

void main() {
  group('TianPanService fixed cyclic rotation contract', () {
    test('all 12 month generals x 12 hour branches are complete rotations', () {
      const branches = DaLiuRenConstants.diZhi;
      for (final yueJiang in branches) {
        for (final shiZhi in branches) {
          final map = TianPanService.arrangeTianPan(yueJiang, shiZhi);

          expect(map.length, 12, reason: '$yueJiang将加$shiZhi时');
          expect(map.keys.toSet(), branches.toSet());
          expect(map.values.toSet(), branches.toSet());
          expect(map[shiZhi], yueJiang);
          for (var index = 0; index < branches.length; index++) {
            final nextGround = branches[(index + 1) % branches.length];
            final currentHeaven = branches.indexOf(map[branches[index]]!);
            expect(
              map[nextGround],
              branches[(currentHeaven + 1) % branches.length],
              reason: '$yueJiang将加$shiZhi时必须逐宫顺布',
            );
          }
          expect(() => map['子'] = '子', throwsUnsupportedError);
        }
      }
    });

    test('invalid month general and hour branch fail before rotation', () {
      expect(
        () => TianPanService.arrangeTianPan('甲', '子'),
        throwsArgumentError,
      );
      expect(
        () => TianPanService.arrangeTianPan('子', '甲'),
        throwsArgumentError,
      );
      expect(
        () => TianPanService.createTianPan(yueJiang: '', shiZhi: '子'),
        throwsArgumentError,
      );
    });

    test('public queries reject every malformed map class', () {
      final malformed = <Map<String, String>>[
        <String, String>{},
        _rotation(1)..remove('亥'),
        _invalidKeyMap(),
        _invalidValueMap(),
        _duplicateValueMap(),
        _scrambledBijection(),
      ];

      for (final map in malformed) {
        expect(
          () => TianPanService.getTianPanZhi(map, '子'),
          throwsArgumentError,
        );
        expect(
          () => TianPanService.getDiPanZhi(map, '子'),
          throwsArgumentError,
        );
      }
    });

    test('forward and reverse queries are total and unique', () {
      final map = _rotation(5);
      expect(TianPanService.getTianPanZhi(map, '子'), '巳');
      expect(TianPanService.getDiPanZhi(map, '巳'), <String>['子']);
      expect(
        () => TianPanService.getTianPanZhi(map, '甲'),
        throwsArgumentError,
      );
      expect(
        () => TianPanService.getDiPanZhi(map, '甲'),
        throwsArgumentError,
      );
    });
  });

  group('ShenJiangService heaven-plate boundary', () {
    test('rejects malformed plates before resolving any coordinates', () {
      final malformed = <Map<String, String>>[
        <String, String>{},
        _rotation(1)..remove('亥'),
        _invalidKeyMap(),
        _invalidValueMap(),
        _duplicateValueMap(),
        _scrambledBijection(),
      ];

      for (final map in malformed) {
        expect(
          () => ShenJiangService.configureShenJiang(
            riGan: '甲',
            shiZhi: '子',
            tianPanMap: map,
          ),
          throwsArgumentError,
        );
      }
    });

    test('projects a legal plate without changing coordinate semantics', () {
      final map = _rotation(3);
      final config = ShenJiangService.configureShenJiang(
        riGan: '甲',
        shiZhi: '子',
        tianPanMap: map,
      );

      expect(config.positions, hasLength(12));
      for (final position in config.positions) {
        expect(position.heavenBranch, map[position.earthPalace]);
      }
    });
  });

  group('TianPan model boundary', () {
    test('anchors month general to hour and snapshots caller map', () {
      final source = _rotation(2);
      final model = TianPan(
        yueJiang: '寅',
        yueJiangName: '功曹',
        shiZhi: '子',
        tianPanMap: source,
      );

      source['子'] = '子';
      expect(model.getTianPanZhi('子'), '寅');
      expect(model.fullDisplay, hasLength(12));
      expect(() => model.tianPanMap['子'] = '子', throwsUnsupportedError);
    });

    test('rejects scalar/map mismatch, malformed JSON, and invalid copyWith',
        () {
      final map = _rotation(2);
      expect(
        () => TianPan(
          yueJiang: '卯',
          yueJiangName: '太冲',
          shiZhi: '子',
          tianPanMap: map,
        ),
        throwsArgumentError,
      );
      expect(
        () => TianPan.fromJson(<String, dynamic>{
          'yueJiang': '寅',
          'yueJiangName': '功曹',
          'shiZhi': '子',
          'tianPanMap': _scrambledBijection(),
        }),
        throwsArgumentError,
      );
      expect(
        () => TianPan.fromJson(<String, dynamic>{
          'yueJiang': '卯',
          'yueJiangName': '太冲',
          'shiZhi': '子',
          'tianPanMap': map,
        }),
        throwsArgumentError,
      );
      expect(
        () => TianPan.fromJson(<String, dynamic>{
          'yueJiang': '寅',
          'yueJiangName': '功曹',
          'shiZhi': '子',
          'tianPanMap': 'not-a-map',
        }),
        throwsArgumentError,
      );
      expect(
        () => TianPan.fromJson(<String, dynamic>{
          'yueJiang': 2,
          'yueJiangName': '功曹',
          'shiZhi': '子',
          'tianPanMap': map,
        }),
        throwsArgumentError,
      );
      expect(
        () => TianPan.fromJson(<String, dynamic>{
          'yueJiang': '寅',
          'yueJiangName': '功曹',
          'shiZhi': '子',
          'tianPanMap': <Object, Object>{...map, '子': 2},
        }),
        throwsArgumentError,
      );

      final model = TianPan(
        yueJiang: '寅',
        yueJiangName: '功曹',
        shiZhi: '子',
        tianPanMap: map,
      );
      expect(() => model.copyWith(yueJiang: '卯'), throwsArgumentError);
    });

    test('valid JSON round-trip preserves the frozen field shape', () {
      final model = TianPan(
        yueJiang: '寅',
        yueJiangName: '功曹',
        shiZhi: '子',
        tianPanMap: _rotation(2),
      );
      final json = model.toJson();
      final decoded = TianPan.fromJson(json);

      expect(
        json.keys.toSet(),
        <String>{'yueJiang', 'yueJiangName', 'shiZhi', 'tianPanMap'},
      );
      expect(decoded, model);

      final encodedMap = json['tianPanMap']! as Map<String, String>;
      encodedMap['子'] = '子';
      expect(model.getTianPanZhi('子'), '寅');
      expect(decoded.getTianPanZhi('子'), '寅');
    });
  });
}
