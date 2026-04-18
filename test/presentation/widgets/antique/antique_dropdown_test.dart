import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_dropdown.dart';

void main() {
  group('AntiqueDropdown', () {
    testWidgets('renders selected value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueDropdown<String>(
              value: 'time',
              items: const [
                AntiqueDropdownItem(value: 'time', label: '时间起课'),
                AntiqueDropdownItem(value: 'manual', label: '指定起课'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('时间起课'), findsOneWidget);
    });

    testWidgets('forwards selection change', (tester) async {
      String? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AntiqueDropdown<String>(
              value: 'time',
              items: const [
                AntiqueDropdownItem(value: 'time', label: '时间起课'),
                AntiqueDropdownItem(value: 'manual', label: '指定起课'),
              ],
              onChanged: (v) => captured = v,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AntiqueDropdown<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('指定起课').last);
      await tester.pumpAndSettle();
      expect(captured, 'manual');
    });
  });
}
