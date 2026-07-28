import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_enums.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_pan_params.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/services/qimen/qimen_constants.dart';

void main() {
  group('Qimen stable contracts', () {
    test('DivinationType uses the reviewed stable ID', () {
      expect(DivinationType.qiMen.displayName, '奇门遁甲');
      expect(DivinationType.qiMen.id, 'qimen');
      expect(DivinationType.fromId('qimen'), DivinationType.qiMen);
    });

    test('all Qimen enums round-trip their stable IDs', () {
      for (final value in QimenJuMethod.values) {
        expect(QimenJuMethod.fromId(value.id), value);
      }
      for (final value in QimenTimeBasis.values) {
        expect(QimenTimeBasis.fromId(value.id), value);
      }
      for (final value in QimenDayBoundary.values) {
        expect(QimenDayBoundary.fromId(value.id), value);
      }
      for (final value in QimenHostingMode.values) {
        expect(QimenHostingMode.fromId(value.id), value);
      }
      for (final value in QimenHiddenStemMode.values) {
        expect(QimenHiddenStemMode.fromId(value.id), value);
      }
      for (final value in QimenQuestionCategory.values) {
        expect(QimenQuestionCategory.fromId(value.id), value);
      }
    });

    test('defaults match the reviewed time-cast contract', () {
      const params = QimenPanParams();
      expect(params.juMethod, QimenJuMethod.chaiBu);
      expect(params.timeBasis, QimenTimeBasis.localCivil);
      expect(params.dayBoundary, QimenDayBoundary.ziInitial);
      expect(params.hostingMode, QimenHostingMode.kunTwo);
      expect(
        params.hiddenStemMode,
        QimenHiddenStemMode.dutyDoorHourStem,
      );
      expect(
          QimenPanParams.fromJson(params.toJson()).toJson(), params.toJson());
    });

    test('the single ju table covers all 24 terms and three yuan', () {
      const reviewed = <String, List<int>>{
        '冬至': <int>[1, 7, 4],
        '小寒': <int>[2, 8, 5],
        '大寒': <int>[3, 9, 6],
        '立春': <int>[8, 5, 2],
        '雨水': <int>[9, 6, 3],
        '惊蛰': <int>[1, 7, 4],
        '春分': <int>[3, 9, 6],
        '清明': <int>[4, 1, 7],
        '谷雨': <int>[5, 2, 8],
        '立夏': <int>[4, 1, 7],
        '小满': <int>[5, 2, 8],
        '芒种': <int>[6, 3, 9],
        '夏至': <int>[9, 3, 6],
        '小暑': <int>[8, 2, 5],
        '大暑': <int>[7, 1, 4],
        '立秋': <int>[2, 5, 8],
        '处暑': <int>[1, 4, 7],
        '白露': <int>[9, 3, 6],
        '秋分': <int>[7, 1, 4],
        '寒露': <int>[6, 9, 3],
        '霜降': <int>[5, 8, 2],
        '立冬': <int>[6, 9, 3],
        '小雪': <int>[5, 8, 2],
        '大雪': <int>[4, 7, 1],
      };
      expect(QimenConstants.juBySolarTerm, reviewed);
    });
  });
}
