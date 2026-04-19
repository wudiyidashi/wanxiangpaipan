import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/models/daily_almanac.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/almanac_header.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/festival_banner.dart';

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
    expect(find.textContaining('今日节气：清明'), findsOneWidget);
  });
}
