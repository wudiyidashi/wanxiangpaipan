import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/qimen_system.dart';
import 'package:wanxiang_paipan/presentation/widgets/divination_system_card.dart';

void main() {
  const assetPath = 'assets/images/screen_card/qimen_background.png';

  testWidgets('Qimen background decodes and contains visible pixel detail',
      (tester) async {
    await tester.runAsync(() async {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        expect(image.width, 1024);
        expect(image.height, 1536);

        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(rgba, isNotNull);
        final bytes = rgba!.buffer.asUint8List();
        var minimum = 255;
        var maximum = 0;
        var visibleSamples = 0;
        final sampleStride = math.max(4, (bytes.length ~/ 4096) ~/ 4 * 4);
        for (var offset = 0;
            offset + 3 < bytes.length;
            offset += sampleStride) {
          final red = bytes[offset];
          final green = bytes[offset + 1];
          final blue = bytes[offset + 2];
          final alpha = bytes[offset + 3];
          if (alpha == 0) continue;
          visibleSamples += 1;
          final luminance = (red * 299 + green * 587 + blue * 114) ~/ 1000;
          minimum = math.min(minimum, luminance);
          maximum = math.max(maximum, luminance);
        }

        expect(visibleSamples, greaterThan(100));
        expect(maximum - minimum, greaterThan(35));
      } finally {
        image.dispose();
        codec.dispose();
      }
    });
  });

  testWidgets('home card renders the bitmap at the real three-column cell size',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390,
              height: 150,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: 1,
                  itemBuilder: (_, __) => DivinationSystemCard(
                    system: QimenSystem(),
                    enableAnimation: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final imageFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == assetPath,
    );
    expect(imageFinder, findsOneWidget);
    expect(find.text('奇门遁甲'), findsOneWidget);
    expect(find.text('时空、运筹'), findsOneWidget);
    final cardSize = tester.getSize(find.byType(DivinationSystemCard));
    expect(cardSize.width, closeTo(112.67, 0.1));
    expect(cardSize.height, closeTo(125.19, 0.1));
    expect(tester.takeException(), isNull);
  });
}
