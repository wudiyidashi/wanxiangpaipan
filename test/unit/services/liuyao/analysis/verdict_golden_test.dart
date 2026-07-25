import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/liuyao_analyzer.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_report.dart';

import 'helpers/analysis_fixtures.dart';

/// 黄金断例：按《增删卜易》断法原则构造的完整卦例，
/// 每例注明问事、月日、取用与判断依据，供领域复核。
/// 引擎裁决与断例期望不一致时，先怀疑断例构造再改引擎。
void main() {
  VerdictJudgment run(
    List<int> numbers, {
    required String yueJian,
    required String riGanZhi,
    required int position,
    bool withChanging = false,
  }) {
    final gua = buildGua(numbers);
    return LiuYaoAnalyzer.analyze(
      gua,
      withChanging ? buildChangingGua(gua) : null,
      buildLunar(yueJian: yueJian, riGanZhi: riGanZhi),
      yongShenPosition: position,
    ).judgment!;
  }

  group('黄金断例（增删卜易断法原则）', () {
    test('例一 占兄弟近况：乾卦安静，申月戊戌日，用神五爻兄弟申金'
        '——用神临月建得日生，忌神安静，断可成。'
        '依据：日月生扶、动爻不克则谋事可成（月将章/日辰章）', () {
      final j = run([7, 7, 7, 7, 7, 7],
          yueJian: '申', riGanZhi: '戊戌', position: 5);
      expect(j.trend, VerdictTrend.keCheng);
    });

    test('例二 占求财：坤卦安静，未月辛未日，用神五爻妻财亥水'
        '——亥水月日皆克又值旬空，休囚安静为真空，断难成。'
        '依据：休囚安静之空为真空，到底无用（旬空章）', () {
      final j = run([8, 8, 8, 8, 8, 8],
          yueJian: '未', riGanZhi: '辛未', position: 5);
      expect(j.trend, VerdictTrend.nanCheng);
      expect(j.conditions.any((c) => !c.hasRescue), isTrue);
    });

    test('例三 占谋官：震卦，午月辛卯日，三爻妻财辰土独发，用神五爻官鬼申金'
        '——用神月克休囚，喜元神辰土发动相生，断先难后成。'
        '依据：用神虽衰，元神动而生扶，先难后成（元神忌神章）', () {
      final j = run([7, 8, 6, 7, 8, 8],
          yueJian: '午', riGanZhi: '辛卯', position: 5, withChanging: true);
      expect(j.trend, VerdictTrend.daiTiaoJian);
      expect(j.nuance, '先难后成');
    });

    test('例四 占求财：乾卦，子月癸酉日，五爻兄弟申金独发，用神二爻妻财寅木'
        '——财爻虽得月生，然日克又兄弟劫财独发，无元神解救，断难成。'
        '依据：忌神独发，用神受克无生（忌神章）', () {
      final j = run([7, 7, 7, 7, 9, 7],
          yueJian: '子', riGanZhi: '癸酉', position: 2, withChanging: true);
      expect(j.trend, VerdictTrend.nanCheng);
    });

    test('例五 占事体成否：乾卦，午月丙寅日，四爻官鬼午火独发化未土'
        '——用神临月建得日生而旺，动化午未合，合则绊住，断成而有待，冲开之日应。'
        '依据：动而逢合则绊，待冲开之日（合冲章）', () {
      final j = run([7, 7, 7, 9, 7, 7],
          yueJian: '午', riGanZhi: '丙寅', position: 4, withChanging: true);
      expect(j.trend, VerdictTrend.daiTiaoJian);
      expect(j.conditions.map((c) => c.label), contains('待冲开'));
    });

    test('例六 占兄弟事：兑卦，酉月戊辰日，初爻官鬼巳火独发，用神五爻兄弟酉金'
        '——用神临月建、日辰生扶，忌神虽动难伤，断吉中有阻、终可就。'
        '依据：用神旺相日月生扶者，忌动凶不为凶（生克章）', () {
      final j = run([9, 7, 8, 7, 7, 8],
          yueJian: '酉', riGanZhi: '戊辰', position: 5, withChanging: true);
      expect(j.trend, VerdictTrend.daiTiaoJian);
      expect(j.nuance, '吉中有阻');
    });

    test('例七 占求财：乾卦安静，申月丁亥日，用神二爻妻财寅木'
        '——财爻月破，幸得日辰亥水生合，不作到底之凶，断出月再验。'
        '依据：月破之爻，出月不破，实破填合之日应之（月破章）', () {
      final j = run([7, 7, 7, 7, 7, 7],
          yueJian: '申', riGanZhi: '丁亥', position: 2);
      expect(j.trend, VerdictTrend.daiTiaoJian);
      expect(j.conditions.map((c) => c.label), contains('待出月'));
    });

    test('例八 占谋官：坤卦，申月甲戌日，三爻官鬼卯木独发化申金'
        '——官鬼月克休囚，动化申金回头克又化绝，衰而无救，断难成。'
        '依据：动而化绝化回头克，衰而无救者凶（动变章）', () {
      final j = run([8, 8, 6, 8, 8, 8],
          yueJian: '申', riGanZhi: '甲戌', position: 3, withChanging: true);
      expect(j.trend, VerdictTrend.nanCheng);
      expect(j.factors.map((f) => f.rule), contains('回头克'));
    });
  });
}
