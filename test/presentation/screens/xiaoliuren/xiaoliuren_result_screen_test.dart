import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wanxiang_paipan/ai/service/ai_analysis_service.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/models/xiaoliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/ui/xiaoliuren_result_screen.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/xiaoliuren_system.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';

void main() {
  group('XiaoLiuRenResultScreen', () {
    late XiaoLiuRenResult result;

    setUp(() async {
      final system = XiaoLiuRenSystem();
      result = await system.cast(
        method: CastMethod.time,
        input: const {},
        castTime: DateTime(2026, 4, 19, 9, 22),
      ) as XiaoLiuRenResult;
    });

    testWidgets('三段顺推不再对第三段做星标强调，并支持切换宫位信息', (tester) async {
      await tester.pumpWidget(
        Provider<AIAnalysisService?>.value(
          value: null,
          child: MaterialApp(
            home: XiaoLiuRenResultScreen(result: result),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.text('宫位信息'), findsOneWidget);
      expect(find.text('第一段 · 速喜'), findsOneWidget);
      expect(find.text('喜信速来'), findsWidgets);

      await tester.ensureVisible(
        find.byKey(const ValueKey('xiaoliuren-palace-step-1')),
      );
      await tester.tap(find.byKey(const ValueKey('xiaoliuren-palace-step-1')));
      await tester.pumpAndSettle();

      expect(find.text('第二段 · 小吉'), findsOneWidget);
      expect(find.text('小成可望'), findsWidgets);

      await tester.ensureVisible(
        find.byKey(const ValueKey('xiaoliuren-palace-step-2')),
      );
      await tester.tap(find.byKey(const ValueKey('xiaoliuren-palace-step-2')));
      await tester.pumpAndSettle();

      expect(find.text('第三段 · 赤口'), findsOneWidget);
      expect(find.text('口舌是非'), findsWidgets);
    });
  });
}
