import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/ui/widgets/daliuren_pan_disk_dialog.dart';

void main() {
  group('panDiskAngle 宫位角度换算', () {
    test('子宫在正下方（π/2）', () {
      expect(panDiskAngle(0), closeTo(math.pi / 2, 1e-9));
      expect(panDiskAngleForBranch('子'), closeTo(math.pi / 2, 1e-9));
    });

    test('顺时针每宫 30°：丑=子+30°，午在正上方', () {
      expect(
        panDiskAngle(1) - panDiskAngle(0),
        closeTo(math.pi / 6, 1e-9),
      );
      // 午（索引6）与子相隔 180°，位于正上方
      expect(
        panDiskAngleForBranch('午'),
        closeTo(math.pi / 2 + math.pi, 1e-9),
      );
    });

    test('十二宫全部相差 30° 且无效地支抛错', () {
      const branches = [
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
      for (var i = 1; i < branches.length; i++) {
        expect(
          panDiskAngleForBranch(branches[i]) -
              panDiskAngleForBranch(branches[i - 1]),
          closeTo(math.pi / 6, 1e-9),
        );
      }
      expect(() => panDiskAngleForBranch('无'), throwsArgumentError);
    });
  });

  group('panDiskPalaceOf 天盘映射反查', () {
    test('天盘支反查地盘宫位', () {
      // s=+2 位移盘：地盘子上天盘寅
      final tianPanMap = {
        for (var i = 0; i < 12; i++)
          [
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
          ][i]: [
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
          ][(i + 2) % 12],
      };
      expect(panDiskPalaceOf(tianPanMap, '寅'), '子');
      expect(panDiskPalaceOf(tianPanMap, '子'), '戌');
      expect(panDiskPalaceOf(tianPanMap, '不存在'), isNull);
    });
  });
}
