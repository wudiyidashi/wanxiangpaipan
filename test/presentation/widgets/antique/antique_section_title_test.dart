import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/core/theme/app_colors.dart';
import 'package:wanxiang_paipan/presentation/widgets/antique/antique_section_title.dart';

void main() {
  group('AntiqueSectionTitle', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AntiqueSectionTitle(title: '四课')),
        ),
      );
      expect(find.text('四课'), findsOneWidget);
    });

    testWidgets('title uses zhusha color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AntiqueSectionTitle(title: '四课')),
        ),
      );
      final text = tester.widget<Text>(find.text('四课'));
      expect(text.style?.color, AppColors.zhusha);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueSectionTitle(title: '四课', subtitle: '本课基础'),
          ),
        ),
      );
      expect(find.text('本课基础'), findsOneWidget);
    });

    testWidgets('shows trailing widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AntiqueSectionTitle(
              title: '历史',
              trailing: Icon(Icons.more_horiz, key: Key('trailing')),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('trailing')), findsOneWidget);
    });
  });
}
