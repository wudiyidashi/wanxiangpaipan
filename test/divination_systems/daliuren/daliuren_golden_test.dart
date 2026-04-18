import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/core/theme/app_theme.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/ui/daliuren_ui_factory.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

void main() {
  group('DaLiuRen golden', () {
    testWidgets('cast screen baseline', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final factory = DaLiuRenUIFactory();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: factory.buildCastScreen(CastMethod.time),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/daliuren_cast.png'),
      );
    });

    // Result screen golden requires constructing a fixed DaLiuRenResult.
    // If fixture too complex, leave as TODO and rely on cast screen + manual QA.
  });
}
