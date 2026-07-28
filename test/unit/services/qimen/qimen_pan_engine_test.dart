import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_enums.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_palace.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/models/qimen_result.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/qimen_system.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

import 'fixtures/qimen_golden_fixtures.dart';

void main() {
  group('Qimen pan public golden', () {
    late QimenResult qimen;

    setUpAll(() async {
      qimen = await QimenSystem().cast(
        method: CastMethod.time,
        input: qimenPublicGoldenTimeInput,
        // 2008-11-04 12:30 in Beijing (UTC+08:00).
        castTime: DateTime.utc(2008, 11, 4, 4, 30),
      ) as QimenResult;
    });

    test('matches the sourced ju, xun, void, and duty facts', () {
      final reason = <Object>[
        qimenManualGoldenSources,
        qimenManualGoldenLineageDisclosure,
      ].join('\n');

      expect(qimen.palaces, hasLength(9));
      expect(qimen.temporalContext.yearGanZhi, '戊子', reason: reason);
      expect(qimen.temporalContext.monthGanZhi, '壬戌', reason: reason);
      expect(qimen.temporalContext.dayGanZhi, '戊申', reason: reason);
      expect(qimen.temporalContext.hourGanZhi, '戊午', reason: reason);
      expect(qimen.temporalContext.currentSolarTerm, '霜降', reason: reason);
      expect(qimen.juInfo.method, QimenJuMethod.chaiBu);
      expect(qimen.juInfo.dun, QimenDun.yin);
      expect(qimen.juInfo.juNumber, 2);
      expect(qimen.juInfo.yuan, QimenYuan.lower);
      expect(qimen.xunShou, '甲寅', reason: reason);
      expect(qimen.kongWangBranches, <String>['子', '丑'], reason: reason);
      expect(qimen.zhiFuStar, '天心', reason: reason);
      expect(qimen.zhiFuPalace, 2, reason: reason);
      expect(qimen.zhiShiDoor, '开门', reason: reason);
      expect(qimen.zhiShiPalace, 2, reason: reason);
      expect(qimen.getSummary(), '阴遁2局 · 天心值符 / 开门值使');
    });

    test('matches only palace facts explicit in the pinned public case', () {
      final reason = <Object>[
        qimenManualGoldenSources,
        qimenManualGoldenLineageDisclosure,
      ].join('\n');

      for (final expected in qimenManualGoldenPalaceFacts) {
        final palace = qimen.palaces.singleWhere(
          (QimenPalace palace) => palace.number == expected['number'],
        );
        final actual = palace.toJson();

        for (final fact in expected.entries) {
          expect(
            actual[fact.key],
            fact.value,
            reason: '${fact.key} in palace ${palace.number}\n$reason',
          );
        }
      }
    });
  });
}
