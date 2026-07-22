import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_report.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/models/analysis_tag.dart';
import 'package:wanxiang_paipan/domain/services/liuyao/analysis/ying_qi_service.dart';

import 'helpers/analysis_fixtures.dart';

YaoAnalysisTag tagOf(String term) => YaoAnalysisTag(
      term: term,
      category: TagCategory.kongWang,
      polarity: Polarity.neutral,
      priority: 10,
      reason: 'test',
    );

void main() {
  final lunar = buildLunar(yueJian: '午', riGanZhi: '甲子');

  group('YingQiService 状态驱动应期', () {
    test('静用神旬空：填实日与冲空日', () {
      // 上爻戌土静，甲子旬空
      final candidates = YingQiService.calculate(
        yongShen: makeYao(position: 6, branch: '戌'),
        yongShenTags: [tagOf('旬空')],
        lunarInfo: lunar,
      );
      final branches = candidates.map((c) => c.branch).toList();
      expect(branches, contains('戌')); // 填实
      expect(branches, contains('辰')); // 冲空
      expect(
          candidates.firstWhere((c) => c.branch == '戌').reason, contains('填实'));
      expect(candidates.map((c) => c.reason), isNot(contains('出空填实')));
    });

    test('用神月破：实破日与合破日', () {
      final candidates = YingQiService.calculate(
        yongShen: makeYao(position: 1, branch: '子'),
        yongShenTags: [tagOf('月破')],
        lunarInfo: lunar,
      );
      final branches = candidates.map((c) => c.branch).toList();
      expect(branches, contains('子')); // 值日实破
      expect(branches, contains('丑')); // 合破
      final outOfMonth = candidates.firstWhere(
        (candidate) => candidate.reason.contains('出月'),
      );
      expect(outOfMonth.branch, '未'); // 午月之后为未月
      expect(outOfMonth.scale, YingQiScale.yue);
      expect(
        candidates.firstWhere((candidate) => candidate.branch == '子').scale,
        YingQiScale.ri,
      );
    });

    test('用神入墓：冲开墓库之日', () {
      // 午火墓于戌，冲戌者辰
      final candidates = YingQiService.calculate(
        yongShen: makeYao(position: 4, branch: '午'),
        yongShenTags: [tagOf('入日墓')],
        lunarInfo: lunar,
      );
      final chongMu = candidates.firstWhere((c) => c.reason.contains('墓'));
      expect(chongMu.branch, '辰');
    });

    test('用神被合住：冲开之日', () {
      final candidates = YingQiService.calculate(
        yongShen: makeYao(position: 1, branch: '子'),
        yongShenTags: [tagOf('合住')],
        lunarInfo: lunar,
      );
      expect(candidates.any((c) => c.branch == '午' && c.reason.contains('冲开')),
          isFalse);
      expect(candidates.any((c) => c.branch == '午' && c.reason.contains('冲用神')),
          isTrue);
      expect(candidates.any((c) => c.branch == '未' && c.reason.contains('冲合神')),
          isTrue);
    });

    test('合处已经冲开时不再生成未来冲开候选', () {
      final candidates = YingQiService.calculate(
        yongShen: makeYao(position: 1, branch: '子'),
        yongShenTags: [tagOf('合住'), tagOf('冲开')],
        lunarInfo: lunar,
      );

      expect(candidates.any((candidate) => candidate.reason.contains('解合')),
          isFalse);
    });

    test('化空化破化墓按变爻状态生成候选', () {
      final candidates = YingQiService.calculate(
        yongShen: makeYao(position: 1, branch: '卯', moving: true),
        changedYao: makeYao(position: 1, branch: '戌'),
        yongShenTags: [tagOf('化空'), tagOf('化破'), tagOf('化墓')],
        lunarInfo: lunar,
      );

      expect(
        candidates.any((candidate) =>
            candidate.branch == '戌' && candidate.reason.contains('化空')),
        isTrue,
      );
      expect(
        candidates.any((candidate) =>
            candidate.scale == YingQiScale.yue &&
            candidate.reason.contains('化破')),
        isTrue,
      );
      expect(
        candidates.any((candidate) =>
            candidate.branch == '辰' && candidate.reason.contains('化墓')),
        isTrue,
      );
    });

    test('静而无事：值日或冲动之日', () {
      final candidates = YingQiService.calculate(
        yongShen: makeYao(position: 2, branch: '寅'),
        yongShenTags: const [],
        lunarInfo: lunar,
      );
      final branches = candidates.map((c) => c.branch).toList();
      expect(branches, contains('寅')); // 值日
      expect(branches, contains('申')); // 冲动
    });

    test('动而待合：值日或合日', () {
      final candidates = YingQiService.calculate(
        yongShen: makeYao(position: 4, branch: '午', moving: true),
        yongShenTags: const [],
        lunarInfo: lunar,
      );
      final branches = candidates.map((c) => c.branch).toList();
      expect(branches, contains('午')); // 值日
      expect(branches, contains('未')); // 合日
    });

    test('同支候选去重且按优先级排序', () {
      // 旬空 + 月破 都会给出值本支之日
      final candidates = YingQiService.calculate(
        yongShen: makeYao(position: 6, branch: '戌'),
        yongShenTags: [tagOf('旬空'), tagOf('入月墓')],
        lunarInfo: lunar,
      );
      final xuCount = candidates.where((c) => c.branch == '戌').length;
      expect(xuCount, 1);
      for (var i = 1; i < candidates.length; i++) {
        expect(candidates[i].priority,
            greaterThanOrEqualTo(candidates[i - 1].priority));
      }
    });
  });
}
