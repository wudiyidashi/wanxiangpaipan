import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wanxiang_paipan/data/database/app_database.dart';
import 'package:wanxiang_paipan/data/repositories/divination_repository_impl.dart';
import 'package:wanxiang_paipan/domain/divination_registry.dart';
import 'package:wanxiang_paipan/divination_systems/meihua/meihua_system.dart';
import 'package:wanxiang_paipan/divination_systems/meihua/viewmodels/meihua_viewmodel.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/models/xiaoliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/viewmodels/xiaoliuren_viewmodel.dart';
import 'package:wanxiang_paipan/divination_systems/xiaoliuren/xiaoliuren_system.dart';

import '../data/repositories/divination_repository_test.dart'
    show MockSecureStorage;

void main() {
  group('Divination system viewmodels', () {
    late AppDatabase database;
    late MockSecureStorage secureStorage;
    late DivinationRegistry registry;
    late DivinationRepositoryImpl repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      secureStorage = MockSecureStorage();
      registry = DivinationRegistry();
      registry.clear();
      registry.register(MeiHuaSystem());
      registry.register(XiaoLiuRenSystem());

      repository = DivinationRepositoryImpl(
        database: database,
        secureStorage: secureStorage,
        registry: registry,
      );
    });

    tearDown(() async {
      await database.close();
      registry.clear();
    });

    test('MeiHuaViewModel 应能起卦并保存占问', () async {
      final viewModel = MeiHuaViewModel(
        system: MeiHuaSystem(),
        repository: repository,
      );

      await viewModel.castByNumbers(
        upperNumber: 3,
        lowerNumber: 5,
        castTime: DateTime(2026, 4, 19, 9, 22),
      );

      expect(viewModel.hasError, isFalse);
      expect(viewModel.hasResult, isTrue);
      expect(viewModel.benGuaName, isNotEmpty);
      expect(viewModel.bianGuaName, isNotEmpty);

      await viewModel.saveRecord(question: '测试梅花占问');

      expect(viewModel.question, '测试梅花占问');
      expect(await repository.getRecordCount(), 1);
      expect(
        await repository.readEncryptedField('question_${viewModel.result!.id}'),
        '测试梅花占问',
      );
    });

    test('XiaoLiuRenViewModel 应能起课并保存九宫记录', () async {
      final viewModel = XiaoLiuRenViewModel(
        system: XiaoLiuRenSystem(),
        repository: repository,
      );

      await viewModel.castByCharacterStrokes(
        firstStroke: 8,
        secondStroke: 11,
        thirdStroke: 6,
        palaceMode: XiaoLiuRenPalaceMode.ninePalaces,
        castTime: DateTime(2026, 4, 19, 9, 22),
      );

      expect(viewModel.hasError, isFalse);
      expect(viewModel.hasResult, isTrue);
      expect(viewModel.palaceMode, XiaoLiuRenPalaceMode.ninePalaces);
      expect(viewModel.finalPosition, isNotNull);

      await viewModel.saveRecord(question: '测试小六壬占问');

      final all = await repository.getAllRecords();
      expect(all, hasLength(1));
      expect(all.first, isA<XiaoLiuRenResult>());
      expect(
        await repository.readEncryptedField('question_${viewModel.result!.id}'),
        '测试小六壬占问',
      );
    });
  });
}
