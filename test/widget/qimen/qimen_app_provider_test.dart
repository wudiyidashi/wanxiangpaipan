import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wanxiang_paipan/ai/ai_bootstrap.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/qimen_system.dart';
import 'package:wanxiang_paipan/divination_systems/qimen/viewmodels/qimen_viewmodel.dart';
import 'package:wanxiang_paipan/divination_systems/registry_bootstrap.dart';
import 'package:wanxiang_paipan/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AIBootstrap.reset();
    AIBootstrap.registerFormatters();
    DivinationSystemBootstrap.registerAll(
      qimenProvidersReady: WanxiangPaipanApp.qimenProvidersReady,
    );
  });
  tearDown(() {
    AIBootstrap.reset();
    DivinationSystemBootstrap.clearAll();
  });

  testWidgets('application root provides enabled Qimen system and view model',
      (tester) async {
    await tester.pumpWidget(const WanxiangPaipanApp());

    final appContext = tester.element(find.byType(MaterialApp));
    final system = appContext.read<QimenSystem>();
    final viewModel = appContext.read<QimenViewModel>();

    expect(WanxiangPaipanApp.qimenProvidersReady, isTrue);
    expect(DivinationSystemBootstrap.qimenProductReadiness.isReady, isTrue);
    expect(system.isEnabled, isTrue);
    expect(viewModel.submissionPhase, QimenSubmissionPhase.idle);
    expect(viewModel.result, isNull);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
