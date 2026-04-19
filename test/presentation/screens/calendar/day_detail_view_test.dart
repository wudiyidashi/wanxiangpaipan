import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/screens/calendar/widgets/festival_banner.dart';

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
}
