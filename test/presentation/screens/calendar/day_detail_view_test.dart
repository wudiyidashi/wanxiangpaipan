import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/models/daily_almanac.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/almanac_header.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/festival_banner.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/four_pillars_card.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/yiji_panel.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/time_hour_bar.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/moon_phase_kongwang.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/pengzu_card.dart';

DailyAlmanac _fixture({
  String? currentJieQi,
  String nextJieQi = '立夏',
  int nextJieQiDaysAway = 17,
  List<String> festivals = const [],
  List<HourAlmanac> twelveHours = const [],
}) =>
    DailyAlmanac(
      date: DateTime(2026, 4, 18),
      lunarDate: '农历三月初二',
      weekday: '星期六',
      currentJieQi: currentJieQi,
      nextJieQi: nextJieQi,
      nextJieQiDaysAway: nextJieQiDaysAway,
      yearGZ: '丙午',
      monthGZ: '壬辰',
      dayGZ: '乙卯',
      yueXiang: '上弦',
      kongWang: ['子', '丑'],
      yi: ['祭祀'],
      ji: ['动土'],
      pengZuGan: '甲不开仓',
      pengZuZhi: '子不问卜',
      festivals: festivals,
      twelveHours: twelveHours,
    );

HourAlmanac _h(String zhi, String luck) => HourAlmanac(
  zhi: zhi,
  ganZhi: '$zhi$zhi',
  tianShen: '青龙',
  huangHei: '黄',
  luck: luck,
  yi: [],
  ji: [],
  startHour: 0,
  endHour: 2,
);

void main() {
  testWidgets('FestivalBanner hides when festivals is empty', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: FestivalBanner(festivals: [])),
    ));
    // Widget should render as SizedBox.shrink() — no decoration container
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('FestivalBanner shows names joined by ·', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: FestivalBanner(festivals: ['春节', '情人节'])),
    ));
    expect(find.text('春节 · 情人节'), findsOneWidget);
  });

  testWidgets('AlmanacHeader shows primary line with date/weekday/lunar', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: AlmanacHeader(almanac: _fixture())),
    ));
    expect(find.textContaining('2026年4月18日'), findsOneWidget);
    expect(find.textContaining('星期六'), findsOneWidget);
    expect(find.textContaining('农历三月初二'), findsOneWidget);
  });

  testWidgets('AlmanacHeader shows nextJieQi countdown when currentJieQi is null', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: AlmanacHeader(almanac: _fixture())),
    ));
    expect(find.textContaining('距立夏 17 天'), findsOneWidget);
  });

  testWidgets('AlmanacHeader shows current jieQi when present', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: AlmanacHeader(almanac: _fixture(currentJieQi: '清明'))),
    ));
    expect(find.textContaining('清明'), findsOneWidget);
  });

  testWidgets('FourPillarsCard shows 4 gz pairs', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
          body: FourPillarsCard(
        almanac: _fixture(),
        hourGanZhi: '庚午',
      )),
    ));
    expect(find.text('丙午'), findsOneWidget); // yearGZ
    expect(find.text('壬辰'), findsOneWidget); // monthGZ
    expect(find.text('乙卯'), findsOneWidget); // dayGZ
    expect(find.text('庚午'), findsOneWidget); // hourGanZhi
  });

  testWidgets('FourPillarsCard exposes 时柱 via Key', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
          body: FourPillarsCard(
        almanac: _fixture(),
        hourGanZhi: '庚午',
      )),
    ));
    final hourText = t.widget<Text>(find.byKey(const Key('pillar-hour-gz')));
    expect(hourText.data, '庚午');
  });

  testWidgets('YijiPanel shows yi and ji items', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: YijiPanel(yi: ['祭祀', '祈福'], ji: ['动土'])),
    ));
    expect(find.text('祭祀'), findsOneWidget);
    expect(find.text('祈福'), findsOneWidget);
    expect(find.text('动土'), findsOneWidget);
  });

  testWidgets('YijiPanel shows em-dash when list is empty', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: YijiPanel(yi: [], ji: [])),
    ));
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('TimeHourBar fires onSelect with tapped zhi', (t) async {
    String? picked;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TimeHourBar(
          hours: [_h('子', '吉'), _h('丑', '凶'), _h('寅', '吉')],
          selectedZhi: null,
          onSelect: (z) => picked = z,
        ),
      ),
    ));
    await t.tap(find.byKey(const ValueKey('hour-丑')));
    await t.pumpAndSettle();
    expect(picked, '丑');
  });

  testWidgets('TimeHourBar renders 12 zhi keys', (t) async {
    final hours = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥']
        .map((z) => _h(z, '吉'))
        .toList();
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TimeHourBar(
          hours: hours,
          selectedZhi: '未',
          onSelect: (_) {},
        ),
      ),
    ));
    // 验证 12 个 key 全部存在
    for (final z in ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥']) {
      expect(find.byKey(ValueKey('hour-$z')), findsOneWidget);
    }
  });

  testWidgets('MoonPhaseKongwang renders combined string', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body:
      MoonPhaseKongwang(yueXiang: '上弦', kongWang: ['子', '丑']))));
    expect(find.text('月相：上弦 · 空亡：子丑'), findsOneWidget);
  });

  testWidgets('MoonPhaseKongwang shows em-dash when kongWang empty', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body:
      MoonPhaseKongwang(yueXiang: '上弦', kongWang: []))));
    expect(find.text('月相：上弦 · 空亡：—'), findsOneWidget);
  });

  testWidgets('PengzuCard shows gan and zhi lines', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body:
      PengzuCard(gan: '甲不开仓', zhi: '子不问卜'))));
    expect(find.text('甲不开仓'), findsOneWidget);
    expect(find.text('子不问卜'), findsOneWidget);
    expect(find.text('彭祖百忌'), findsOneWidget);
  });
}
