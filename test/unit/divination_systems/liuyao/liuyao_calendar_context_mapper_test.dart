import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/ui/liuyao_calendar_context_mapper.dart';
import 'package:wanxiang_paipan/domain/services/shared/analysis/models/verdict_models.dart';

void main() {
  test('生产映射按尺度写入日角标与月提示条通道', () {
    const daily = YingQiCandidate(
      label: '卯日（值日填实）',
      branch: '卯',
      scale: YingQiScale.ri,
      reason: '值日填实月破',
      priority: 10,
    );
    const monthly = YingQiCandidate(
      label: '戌月（出月）',
      branch: '戌',
      scale: YingQiScale.yue,
      reason: '出月解除月破',
      priority: 20,
    );

    final context = LiuYaoCalendarContextMapper.build(
      title: '兑为泽 · 用神妻财卯木',
      yongShenBranch: '卯',
      candidates: const <YingQiCandidate>[daily, monthly],
    );

    expect(context.title, '兑为泽 · 用神妻财卯木');
    expect(context.yongShenBranch, '卯');
    expect(context.yingQiByBranch, <String, String>{
      '卯': '值日填实月破',
    });
    expect(context.yingQiMonthByBranch, <String, String>{
      '戌': '出月解除月破',
    });
    expect(context.monthYingQiReason('戌'), '出月解除月破');
    expect(context.monthYingQiReason('卯'), isNull);
  });
}
