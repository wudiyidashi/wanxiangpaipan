import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/repositories/divination_repository.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';
import 'package:wanxiang_paipan/presentation/divination/divination_result_page.dart';

class _FakeDivinationRepository implements DivinationRepository {
  _FakeDivinationRepository({this.question});

  final String? question;

  @override
  Future<String?> readEncryptedField(String key) async => question;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used in test: ${invocation.memberName}');
}

class _FakeResult implements DivinationResult {
  _FakeResult({
    required this.id,
    required this.questionId,
  });

  @override
  final String id;

  final String questionId;

  @override
  DateTime get castTime => DateTime(2026, 4, 19, 9, 22);

  @override
  CastMethod get castMethod => CastMethod.time;

  @override
  LunarInfo get lunarInfo => const LunarInfo(
        yueJian: '辰',
        riGan: '癸',
        riZhi: '亥',
        riGanZhi: '癸亥',
        hourGanZhi: '丁巳',
        kongWang: ['子', '丑'],
        yearGanZhi: '丙午',
        monthGanZhi: '壬辰',
      );

  @override
  DivinationType get systemType => DivinationType.meiHua;

  @override
  String getSummary() => 'fake summary';

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'questionId': questionId,
      };
}

Widget _wrapWithRepository({
  required Widget child,
  String? question,
}) {
  return MaterialApp(
    home: Provider<DivinationRepository>.value(
      value: _FakeDivinationRepository(question: question),
      child: child,
    ),
  );
}

void main() {
  group('DivinationResultPage', () {
    testWidgets('优先读取加密占问并传给结果区块', (tester) async {
      final result = _FakeResult(id: 'result-1', questionId: '旧占问');

      await tester.pumpWidget(
        _wrapWithRepository(
          question: '加密占问',
          child: DivinationResultPage(
            result: result,
            title: '测试结果页',
            fallbackQuestion: result.questionId,
            includeAiAnalysis: false,
            buildSections: (context, question) => [
              Text(question.isEmpty ? 'EMPTY' : question),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('测试结果页'), findsOneWidget);
      expect(find.text('加密占问'), findsOneWidget);
      expect(find.text('旧占问'), findsNothing);
    });

    testWidgets('仓库不可用时回退到 fallbackQuestion', (tester) async {
      final result = _FakeResult(id: 'result-2', questionId: '回退占问');

      await tester.pumpWidget(
        MaterialApp(
          home: DivinationResultPage(
            result: result,
            title: '测试结果页',
            fallbackQuestion: result.questionId,
            includeAiAnalysis: false,
            buildSections: (context, question) => [
              Text(question.isEmpty ? 'EMPTY' : question),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('回退占问'), findsOneWidget);
    });
  });
}
