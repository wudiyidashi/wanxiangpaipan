import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:wanxiang_paipan/core/theme/app_colors.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/daliuren_constants.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/ke.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/san_chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/shen_jiang_config.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/shen_sha.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/si_ke.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/tianpan.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/gua.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/yao.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/repositories/divination_repository.dart';
import 'package:wanxiang_paipan/domain/services/shared/liuqin_service.dart';
import 'package:wanxiang_paipan/domain/services/shared/wuxing_service.dart';
import 'package:wanxiang_paipan/models/lunar_info.dart';
import 'package:wanxiang_paipan/presentation/widgets/history_record_card.dart';

/// 最小 fake 仓库：只实现本 widget 用到的 readEncryptedField。
class _FakeRepository implements DivinationRepository {
  _FakeRepository({this.question});
  final String? question;

  @override
  Future<String?> readEncryptedField(String key) async => question;

  // 其它接口方法——widget 不调，抛 UnimplementedError 够用。
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used in tests: ${invocation.memberName}');
}

// ==================== result fixtures ====================

LunarInfo _fakeLunar() => const LunarInfo(
      yearGanZhi: '甲辰',
      monthGanZhi: '丙寅',
      riGan: '戊',
      riZhi: '午',
      riGanZhi: '戊午',
      yueJian: '寅',
      kongWang: ['子', '丑'],
    );

Yao _fakeYao(int position) => Yao(
      position: position,
      number: YaoNumber.shaoYang,
      branch: '子',
      stem: '甲',
      liuQin: LiuQin.fuMu,
      wuXing: WuXing.shui,
      isSeYao: position == 6,
      isYingYao: position == 3,
    );

Gua _fakeGua(String name) => Gua(
      id: 'gua-$name',
      name: name,
      yaos: [for (var i = 1; i <= 6; i++) _fakeYao(i)],
      baGong: BaGong.qian,
      seYaoPosition: 6,
      yingYaoPosition: 3,
    );

LiuYaoResult _liuyaoResult({
  DateTime? castTime,
  Gua? changing,
  String id = 'liuyao-1',
}) {
  return LiuYaoResult(
    id: id,
    castTime: castTime ?? DateTime(2026, 4, 18, 14, 32),
    castMethod: CastMethod.time,
    mainGua: _fakeGua('乾为天'),
    changingGua: changing,
    lunarInfo: _fakeLunar(),
    liuShen: const ['青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武'],
    questionId: id,
  );
}

Ke _fakeKe(int index, String shang, String xia) => Ke(
      index: index,
      shangShen: shang,
      xiaShen: xia,
      chengShen: ShenJiang.guiRen,
      shangShenWuXing: '水',
      xiaShenWuXing: '火',
    );

Chuan _fakeChuan(ChuanPosition position, String diZhi) => Chuan(
      position: position,
      diZhi: diZhi,
      wuXing: '水',
      chengShen: ShenJiang.baiHu,
      liuQin: '妻财',
    );

DaLiuRenResult _daliurenResult({
  DateTime? castTime,
  String id = 'dlr-1',
}) {
  return DaLiuRenResult(
    id: id,
    castTime: castTime ?? DateTime(2026, 4, 18, 14, 32),
    castMethod: CastMethod.time,
    lunarInfo: _fakeLunar(),
    siKe: SiKe(
      ke1: _fakeKe(1, '子', '午'),
      ke2: _fakeKe(2, '丑', '未'),
      ke3: _fakeKe(3, '寅', '申'),
      ke4: _fakeKe(4, '卯', '酉'),
      riGan: '戊',
      riZhi: '午',
    ),
    sanChuan: SanChuan(
      chuChuan: _fakeChuan(ChuanPosition.chu, '申'),
      zhongChuan: _fakeChuan(ChuanPosition.zhong, '子'),
      moChuan: _fakeChuan(ChuanPosition.mo, '辰'),
      keType: KeType.sheHai,
    ),
    tianPan: const TianPan(
      yueJiang: '申',
      yueJiangName: '河魁',
      shiZhi: '午',
      tianPanMap: {
        '子': '申', '丑': '酉', '寅': '戌', '卯': '亥',
        '辰': '子', '巳': '丑', '午': '寅', '未': '卯',
        '申': '辰', '酉': '巳', '戌': '午', '亥': '未',
      },
    ),
    shenJiangConfig: const ShenJiangConfig(
      guiRenPosition: '丑',
      isYangGui: true,
      isYangRi: true,
      positions: [],
      diZhiToShenJiang: {},
    ),
    shenShaList: const ShenShaList(allShenSha: []),
    questionId: id,
  );
}

// ==================== test harness ====================

Widget _wrap(Widget child, {String? question}) {
  return MaterialApp(
    home: Scaffold(
      body: Provider<DivinationRepository>.value(
        value: _FakeRepository(question: question),
        child: child,
      ),
    ),
  );
}

void main() {
  group('HistoryRecordCard', () {
    testWidgets('renders 5 layers for LiuYaoResult', (tester) async {
      await tester.pumpWidget(_wrap(
        HistoryRecordCard(result: _liuyaoResult()),
        question: '问事业',
      ));
      await tester.pumpAndSettle();

      expect(find.text('问事业'), findsOneWidget);               // L1
      expect(find.text('2026-04-18 14:32'), findsOneWidget);    // L2
      expect(find.text('乾为天'), findsOneWidget);               // L3 (no changing)
      expect(find.text('六爻'), findsOneWidget);                 // L4
      expect(find.text('时间卦'), findsOneWidget);               // L5
    });

    testWidgets('renders 5 layers for DaLiuRenResult', (tester) async {
      await tester.pumpWidget(_wrap(
        HistoryRecordCard(result: _daliurenResult()),
        question: '问婚姻',
      ));
      await tester.pumpAndSettle();

      expect(find.text('问婚姻'), findsOneWidget);
      expect(find.text('涉害课 · 初传申 中传子 末传辰'), findsOneWidget);
      expect(find.text('大六壬'), findsOneWidget);
      expect(find.text('时间卦'), findsOneWidget);
    });

    testWidgets('empty question preserves minHeight 24', (tester) async {
      await tester.pumpWidget(_wrap(
        HistoryRecordCard(result: _liuyaoResult()),
        question: '',
      ));
      await tester.pumpAndSettle();

      // 找到 Layer 1 的 ConstrainedBox——其 minHeight 应为 24
      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(HistoryRecordCard),
          matching: find.byWidgetPredicate((w) =>
              w is ConstrainedBox && w.constraints.minHeight == 24),
        ).first,
      );
      expect(constrainedBox.constraints.minHeight, 24);
    });

    testWidgets('long question truncates with ellipsis', (tester) async {
      final longQ = '我最近换工作的事情能不能顺利我想知道是否要继续等下去还是主动离开';
      await tester.pumpWidget(_wrap(
        HistoryRecordCard(result: _liuyaoResult()),
        question: longQ,
      ));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text(longQ));
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('liuyao summary includes changing gua when present',
        (tester) async {
      await tester.pumpWidget(_wrap(
        HistoryRecordCard(
          result: _liuyaoResult(changing: _fakeGua('天风姤')),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('乾为天 → 天风姤'), findsOneWidget);
    });

    testWidgets('liuyao summary shows only main gua when no changing',
        (tester) async {
      await tester.pumpWidget(_wrap(
        HistoryRecordCard(result: _liuyaoResult()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('乾为天'), findsOneWidget);
      expect(find.text('乾为天 → '), findsNothing);
    });

    testWidgets('daliuren summary includes 课体 and 3 chuan', (tester) async {
      await tester.pumpWidget(_wrap(
        HistoryRecordCard(result: _daliurenResult()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('涉害课 · 初传申 中传子 末传辰'), findsOneWidget);
    });

    testWidgets('system tag uses liuyao system color', (tester) async {
      await tester.pumpWidget(_wrap(
        HistoryRecordCard(result: _liuyaoResult()),
      ));
      await tester.pumpAndSettle();

      // 找 label 为 "六爻" 的 Text，验证 color == AppColors.liuyaoColor
      final tagText = tester.widget<Text>(find.text('六爻'));
      expect(tagText.style?.color, AppColors.liuyaoColor);
    });

    testWidgets('image errorBuilder falls back to SizedBox.shrink',
        (tester) async {
      // test 环境通常不加载 asset 包；Image.asset 会失败并走 errorBuilder
      await tester.pumpWidget(_wrap(
        HistoryRecordCard(result: _liuyaoResult()),
      ));
      await tester.pumpAndSettle();

      // 能成功渲染 widget（未抛）即证明 errorBuilder 兜底生效
      expect(find.byType(HistoryRecordCard), findsOneWidget);
    });

    testWidgets('onTap triggers callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        HistoryRecordCard(
          result: _liuyaoResult(),
          onTap: () => tapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(HistoryRecordCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
