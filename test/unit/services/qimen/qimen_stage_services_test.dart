import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_enums.dart';
import 'package:wanxiang_paipan/domain/services/qimen/qimen_door_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/qimen_duty_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/qimen_earth_plate_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/qimen_heaven_plate_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/qimen_hidden_stem_service.dart';
import 'package:wanxiang_paipan/domain/services/qimen/qimen_marker_service.dart';

void main() {
  group('Qimen earth plate', () {
    test('all yin/yang nine ju cover each stem and palace exactly once', () {
      for (final dun in QimenDun.values) {
        for (var ju = 1; ju <= 9; ju++) {
          final plate = QimenEarthPlateService.arrange(
            dun: dun,
            juNumber: ju,
            hostingMode: QimenHostingMode.kunTwo,
          );
          expect(plate.stems.keys.toSet(), <int>{1, 2, 3, 4, 5, 6, 7, 8, 9});
          expect(plate.stems.values.toSet(), hasLength(9));
          expect(plate.stems[ju], '戊');
        }
      }
    });

    test('compatibility hosting changes only yang dun target', () {
      final yang = QimenEarthPlateService.arrange(
        dun: QimenDun.yang,
        juNumber: 1,
        hostingMode: QimenHostingMode.yangEightYinTwo,
      );
      final yin = QimenEarthPlateService.arrange(
        dun: QimenDun.yin,
        juNumber: 1,
        hostingMode: QimenHostingMode.yangEightYinTwo,
      );
      expect(yang.hostingPalace, 8);
      expect(yin.hostingPalace, 2);
      expect(yang.stems[5], isNotNull);
      expect(yin.stems[5], isNotNull);
    });

    test('Tian Qin always follows Tian Rui while middle stem follows hosting',
        () {
      for (final mode in QimenHostingMode.values) {
        final plate = QimenEarthPlateService.arrange(
          dun: QimenDun.yang,
          juNumber: 1,
          hostingMode: mode,
        );
        final duty = QimenDutyService.resolve(
          hourGanZhi: '乙巳',
          dun: QimenDun.yang,
          earthPlate: plate,
        );
        final heaven = QimenHeavenPlateService.arrange(
          earthPlate: plate,
          duty: duty,
        );
        final tianRuiPalace = heaven.stars.entries
            .singleWhere((entry) => entry.value == '天芮')
            .key;

        expect(tianRuiPalace, duty.zhiFuPalace, reason: mode.id);
        expect(heaven.hostedStars, <int, String>{tianRuiPalace: '天禽'},
            reason: mode.id);
        expect(heaven.hostedStems.keys, <int>{duty.zhiFuPalace},
            reason: mode.id);
      }
    });
  });

  group('Qimen duty, hidden stems, and markers', () {
    final earth = QimenEarthPlateService.arrange(
      dun: QimenDun.yang,
      juNumber: 1,
      hostingMode: QimenHostingMode.kunTwo,
    );

    test('all six xun heads resolve complete duty facts', () {
      const cases = <String,
          ({
        String hidden,
        int origin,
        String star,
        int starPalace,
        String door,
        int doorPalace,
      })>{
        '甲子': (
          hidden: '戊',
          origin: 1,
          star: '天蓬',
          starPalace: 1,
          door: '休门',
          doorPalace: 1,
        ),
        '甲戌': (
          hidden: '己',
          origin: 2,
          star: '天芮',
          starPalace: 2,
          door: '死门',
          doorPalace: 2,
        ),
        '甲申': (
          hidden: '庚',
          origin: 3,
          star: '天冲',
          starPalace: 3,
          door: '伤门',
          doorPalace: 3,
        ),
        '甲午': (
          hidden: '辛',
          origin: 4,
          star: '天辅',
          starPalace: 4,
          door: '杜门',
          doorPalace: 4,
        ),
        '甲辰': (
          hidden: '壬',
          origin: 5,
          star: '天禽',
          starPalace: 2,
          door: '死门',
          doorPalace: 2,
        ),
        '甲寅': (
          hidden: '癸',
          origin: 6,
          star: '天心',
          starPalace: 6,
          door: '开门',
          doorPalace: 6,
        ),
      };
      for (final entry in cases.entries) {
        final duty = QimenDutyService.resolve(
          hourGanZhi: entry.key,
          dun: QimenDun.yang,
          earthPlate: earth,
        );
        expect(duty.xunShou, entry.key);
        expect(duty.xunHiddenStem, entry.value.hidden, reason: entry.key);
        expect(duty.dutyOriginPalace, entry.value.origin, reason: entry.key);
        expect(duty.zhiFuStar, entry.value.star, reason: entry.key);
        expect(duty.zhiFuPalace, entry.value.starPalace, reason: entry.key);
        expect(duty.zhiShiDoor, entry.value.door, reason: entry.key);
        expect(duty.zhiShiPalace, entry.value.doorPalace, reason: entry.key);
      }
    });

    test('middle-five duty door steps from raw palace in both hosting modes',
        () {
      for (final mode in QimenHostingMode.values) {
        final middleFiveEarth = QimenEarthPlateService.arrange(
          dun: QimenDun.yang,
          juNumber: 1,
          hostingMode: mode,
        );
        final duty = QimenDutyService.resolve(
          hourGanZhi: '乙巳',
          dun: QimenDun.yang,
          earthPlate: middleFiveEarth,
        );

        expect(duty.dutyOriginPalace, 5, reason: mode.id);
        expect(
          duty.dutyEffectiveOriginPalace,
          middleFiveEarth.hostingPalace,
          reason: mode.id,
        );
        expect(duty.zhiShiPalace, 6, reason: mode.id);
        expect(
          duty.zhiShiDoor,
          mode == QimenHostingMode.kunTwo ? '死门' : '生门',
          reason: mode.id,
        );
      }
    });

    test('both hidden-stem modes fill their defined slots', () {
      final duty = QimenDutyService.resolve(
        hourGanZhi: '庚午',
        dun: QimenDun.yang,
        earthPlate: earth,
      );
      final doors = QimenDoorService.arrange(earthPlate: earth, duty: duty);
      final flying = QimenHiddenStemService.arrange(
        mode: QimenHiddenStemMode.dutyDoorHourStem,
        dun: QimenDun.yang,
        hourGanZhi: '庚午',
        duty: duty,
        earthPlate: earth,
        doors: doors,
      );
      final origins = QimenHiddenStemService.arrange(
        mode: QimenHiddenStemMode.doorOriginEarthStem,
        dun: QimenDun.yang,
        hourGanZhi: '庚午',
        duty: duty,
        earthPlate: earth,
        doors: doors,
      );
      expect(flying, <int, String?>{
        1: '癸',
        2: '丁',
        3: '丙',
        4: '乙',
        5: '戊',
        6: '己',
        7: '庚',
        8: '辛',
        9: '壬',
      });
      expect(origins, <int, String?>{
        1: '庚',
        2: '癸',
        3: '乙',
        4: '己',
        5: null,
        6: '丙',
        7: '戊',
        8: '辛',
        9: '丁',
      });
    });

    test('hour xun void and three-harmony horse map to palace metadata', () {
      final markers = QimenMarkerService.resolve('庚午');
      expect(markers.kongWangBranches, <String>['戌', '亥']);
      expect(markers.voidByPalace[6], <String>['戌', '亥']);
      expect(markers.horseBranch, '申');
      expect(markers.horsePalace, 2);
    });
  });
}
