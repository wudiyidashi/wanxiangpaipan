import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/core/theme/app_colors.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_divider.dart';

void main() {
  testWidgets('AntiqueDivider uses danjin color with 0.5 opacity',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AntiqueDivider())),
    );
    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.color, AppColors.danjin.withOpacity(0.5));
  });
}
