# 历史记录卡片视觉重设计实施计划（Plan E-Card）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地 `docs/superpowers/specs/2026-04-18-history-card-visual-design.md`——新建 `HistoryRecordCard` 共享 widget（5 层 antique 笺纸风视觉 + 28% 系统背景图），两个系统工厂的 `buildHistoryCard` 退化为单行委托。

**Architecture:** 新建一个 `StatelessWidget`（约 180 行含 helpers + 10 个 widget tests），替代六爻 / 大六壬工厂当前各自内联的 history card class。工厂层 API 签名**不变**，内部实现极简化。这是 Plan E2 spec §8"页面层统一骨架 + 系统层提供摘要"的局部预演，但不触碰 `DivinationUIFactory` 接口。

**Tech Stack:** Flutter 3.38, antique design system（AntiqueCard / AntiqueTokens / AppColors / AppTextStyles）, FutureBuilder（异步解密占问）, Provider（注入 DivinationRepository）。

**Spec 来源:** `docs/superpowers/specs/2026-04-18-history-card-visual-design.md`（commit `7b00c2c`）

**前置事实**（scout 已核实）：
- `LiuYaoResult.getSummary()` 已是 `'${main.name} → ${changing!.name}'` 格式，直接复用
- `DaLiuRenResult.getSummary()` 只含"课体 + 初传"（line 78-79），**不够**——本 Plan 自建 summary 函数输出 3 传齐全
- `LiuYaoResult.questionId` / `DaLiuRenResult.questionId` 字段均存在（encrypted field key：`'question_${result.id}'`）
- `DivinationRepository.readEncryptedField(key)` 返回 `Future<String?>`
- 4 张背景图资源路径：`assets/images/screen_card/{liuyao,daliuren,xiaoliuren,meihua}_background.png`（均已在 pubspec 声明）

---

## 文件结构

### 新建
- `lib/presentation/widgets/history_record_card.dart` —— 共享 widget + 5 个 file-level helper 函数
- `test/presentation/widgets/history_record_card_test.dart` —— 10 个 widget tests

### 修改
- `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart` —— 删除内联 `_LiuYaoHistoryCard` class + 相关 helpers；`buildHistoryCard` 退化为 3 行
- `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart` —— 同样处理内联 history card 代码

---

## Task 1: 创建 `HistoryRecordCard` widget + 10 widget tests

**Files:**
- Create: `lib/presentation/widgets/history_record_card.dart`
- Create: `test/presentation/widgets/history_record_card_test.dart`

### Step 1: 创建 widget 实现

Create `lib/presentation/widgets/history_record_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/antique_tokens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../divination_systems/daliuren/models/daliuren_result.dart';
import '../../divination_systems/liuyao/liuyao_result.dart';
import '../../domain/divination_system.dart';
import '../../domain/repositories/divination_repository.dart';
import 'antique/antique.dart';

/// 历史记录卡片（跨术数统一骨架）。
///
/// 5 层信息：占问 / 时间 / 结果摘要 / 系统 tag / 方式 tag。
/// 背景为系统对应的 antique 底图 @ 28% opacity。
/// 见 `docs/superpowers/specs/2026-04-18-history-card-visual-design.md`。
class HistoryRecordCard extends StatelessWidget {
  const HistoryRecordCard({
    super.key,
    required this.result,
    this.onTap,
  });

  final DivinationResult result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<DivinationRepository>();
    final questionKey = 'question_${result.id}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: FutureBuilder<String?>(
        future: repository.readEncryptedField(questionKey),
        builder: (context, snapshot) {
          final question = snapshot.data ?? '';
          return _buildCard(context, question);
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, String question) {
    final bgPath = _systemBackground(result.systemType);
    return AntiqueCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      semanticsLabel: _buildSemanticsLabel(question),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AntiqueTokens.radiusCard),
        child: Stack(
          children: [
            if (bgPath != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.28,
                  child: Image.asset(
                    bgPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomRight,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Layer 1: 占问
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 24),
                    child: Text(
                      question,
                      style: AppTextStyles.antiqueTitle.copyWith(
                        fontSize: 17,
                        letterSpacing: 1,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Layer 2: 时间
                  Text(
                    _formatDateTime(result.castTime),
                    style: AppTextStyles.antiqueLabel.copyWith(
                      color: AppColors.guhe,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Layer 3: 结果摘要
                  Text(
                    _summary(result),
                    style: AppTextStyles.antiqueBody.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.zhusha,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  // Layer 4+5: tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildSystemTag(),
                      _buildMethodTag(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemTag() {
    final color = _systemColor(result.systemType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AntiqueTokens.radiusTag),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Text(
        result.systemType.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMethodTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AntiqueTokens.radiusTag),
        border: Border.all(color: AppColors.danjin, width: 1),
      ),
      child: Text(
        result.castMethod.displayName,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.5,
          color: AppColors.guhe,
        ),
      ),
    );
  }

  String _buildSemanticsLabel(String question) {
    final parts = <String>[];
    if (question.isNotEmpty) {
      parts.add('占问：$question');
    }
    parts.add(
        '${result.systemType.displayName}, ${result.castMethod.displayName}');
    parts.add(_summary(result));
    parts.add(_formatDateTime(result.castTime));
    return parts.join('。');
  }
}

// ==================== file-level helpers ====================

String _summary(DivinationResult r) {
  if (r is LiuYaoResult) {
    return r.changingGua == null
        ? r.mainGua.name
        : '${r.mainGua.name} → ${r.changingGua!.name}';
  }
  if (r is DaLiuRenResult) {
    return '${r.keTypeName}课 · 初传${r.chuChuan} '
        '中传${r.zhongChuan} 末传${r.moChuan}';
  }
  // 未来小六壬 / 梅花 / 紫微等系统接入时，在此 switch 补 case；
  // 兜底使用 DivinationResult.getSummary()
  return r.getSummary();
}

Color _systemColor(DivinationType t) {
  switch (t) {
    case DivinationType.liuYao:
      return AppColors.liuyaoColor;
    case DivinationType.daLiuRen:
      return AppColors.daliurenColor;
    case DivinationType.xiaoLiuRen:
      return AppColors.xiaoliurenColor;
    case DivinationType.meiHua:
      return AppColors.meihuaColor;
  }
}

String? _systemBackground(DivinationType t) {
  switch (t) {
    case DivinationType.liuYao:
      return 'assets/images/screen_card/liuyao_background.png';
    case DivinationType.daLiuRen:
      return 'assets/images/screen_card/daliuren_background.png';
    case DivinationType.xiaoLiuRen:
      return 'assets/images/screen_card/xiaoliuren_background.png';
    case DivinationType.meiHua:
      return 'assets/images/screen_card/meihua_background.png';
  }
}

String _formatDateTime(DateTime dt) {
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} '
      '${pad(dt.hour)}:${pad(dt.minute)}';
}
```

### Step 2: 创建 widget tests

Create `test/presentation/widgets/history_record_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:wanxiang_paipan/core/theme/app_colors.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/daliuren_result.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/san_chuan.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/si_ke.dart';
import 'package:wanxiang_paipan/divination_systems/daliuren/models/tian_pan.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/liuyao_result.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/gua.dart';
import 'package:wanxiang_paipan/divination_systems/liuyao/models/yao.dart';
import 'package:wanxiang_paipan/domain/divination_system.dart';
import 'package:wanxiang_paipan/domain/repositories/divination_repository.dart';
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
      riGanZhi: '戊午',
      shiGanZhi: '己未',
      yueJian: '寅',
      kongWang: ['子', '丑'],
    );

Yao _fakeYao(int index) => Yao(
      index: index,
      isYang: index.isOdd,
      isMoving: false,
      branch: '子',
      stem: '甲',
      sixRelative: '父母',
      fiveElement: '水',
    );

Gua _fakeGua(String name) => Gua(
      name: name,
      palace: '乾',
      yaos: [for (var i = 1; i <= 6; i++) _fakeYao(i)],
      seYaoIndex: 6,
      yingYaoIndex: 3,
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

DaLiuRenResult _daliurenResult({
  DateTime? castTime,
  String id = 'dlr-1',
}) {
  return DaLiuRenResult(
    id: id,
    castTime: castTime ?? DateTime(2026, 4, 18, 14, 32),
    castMethod: CastMethod.time,
    lunarInfo: _fakeLunar(),
    siKe: const SiKe(
      ke1: Ke(shangShen: '子', xiaShen: '午'),
      ke2: Ke(shangShen: '丑', xiaShen: '未'),
      ke3: Ke(shangShen: '寅', xiaShen: '申'),
      ke4: Ke(shangShen: '卯', xiaShen: '酉'),
      keType: KeType.sheHai,
    ),
    sanChuan: const SanChuan(
      chu: ChuanYao(diZhi: '申', tianJiang: '白虎', liuQin: '妻财'),
      zhong: ChuanYao(diZhi: '子', tianJiang: '玄武', liuQin: '子孙'),
      mo: ChuanYao(diZhi: '辰', tianJiang: '勾陈', liuQin: '父母'),
      keTypeName: '涉害',
    ),
    tianPan: const TianPan(
      dizhiMap: {
        '子': '申', '丑': '酉', '寅': '戌', '卯': '亥',
        '辰': '子', '巳': '丑', '午': '寅', '未': '卯',
        '申': '辰', '酉': '巳', '戌': '午', '亥': '未',
      },
    ),
    shiErShenJiang: const [],
    shenSha: const [],
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
```

### Step 3: 跑测试看结果

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter test test/presentation/widgets/history_record_card_test.dart
```

Expected: 10 个 tests 全过。

**如果测试失败**：

- "Type X not found"：可能是 fixture 里用的 `SiKe / KeType / ChuanYao / TianPan` 等类名跟实际 model 略有差异。打开 `lib/divination_systems/daliuren/models/` 下对应文件，把 fixture 里的构造器签名对齐到真实 model。**不要擅自改 widget**——错在 fixture。
- `_FakeRepository` 因其它 abstract 方法抱怨："Missing concrete implementations..."：`noSuchMethod` override + 只实现 `readEncryptedField` 的模式应该够用；如果编译器还要严格实现所有成员，用 `extends Mock` from `mocktail` 或给其它方法加 stub 抛 `UnimplementedError`。

### Step 4: Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/presentation/widgets/history_record_card.dart \
        test/presentation/widgets/history_record_card_test.dart
git commit -m "feat(history): add HistoryRecordCard shared widget

Per spec 2026-04-18-history-card-visual-design.md: antique 笺纸
视觉 + 5 层信息 + 系统背景图 @ 28% opacity，替代各工厂内联
实现。file-level helpers (_summary / _systemColor /
_systemBackground / _formatDateTime) switch on systemType 来
提供系统特定内容。

10 widget tests 覆盖：
- 6爻 / 大六壬 基础渲染
- 空占问 minHeight 占位
- 长文本 ellipsis
- 有/无变卦 summary 格式
- 大六壬 3 传 summary 完整
- 系统 tag 色匹配 AppColors
- 图加载失败 errorBuilder 兜底
- onTap 触发

工厂迁移由后续 task 单独 commit 以便 review。"
```

---

## Task 2: 六爻工厂迁移到 `HistoryRecordCard`

**Files:**
- Modify: `lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart`

### Step 1: 定位要删除的内联 history card class

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -nE "_LiuYaoHistoryCard|class _LiuYaoHistoryCard" lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart
```

应能看到 `class _LiuYaoHistoryCard extends StatelessWidget` 的定义（commit `a92fd95` 里写的）。记下其起止行号。

### Step 2: 改写 `buildHistoryCard` 方法

找到当前的 `Widget buildHistoryCard(DivinationResult result) { ... return _LiuYaoHistoryCard(...); }`，改为：

```dart
@override
Widget buildHistoryCard(DivinationResult result) {
  if (result is! LiuYaoResult) {
    throw ArgumentError('结果类型必须是 LiuYaoResult，实际类型: ${result.runtimeType}');
  }
  return HistoryRecordCard(result: result);
}
```

### Step 3: 删除内联 `_LiuYaoHistoryCard` class 及其私有 helpers

删除整个 `class _LiuYaoHistoryCard` 定义（含其所有 private methods：`_formatDateTime` / `_summary` 等）。

### Step 4: 更新 imports

在文件顶部删除可能变得未使用的 imports（比如如果 `AppTextStyles` 只被旧 card class 用过、现在 factory 本身不用），grep 下：

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -n "AppTextStyles\|AntiqueCard\|AntiqueTokens\|FutureBuilder" lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart
```

保留仍被其它 method（`buildResultScreen` / `buildSystemCard` / cast screen internals）引用的 imports。

**新增一条 import**：

```dart
import '../../../presentation/widgets/history_record_card.dart';
```

### Step 5: 验证

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/divination_systems/liuyao/
flutter test 2>&1 | tail -3
```

Expected: analyze 绿，全量测试过（315 = 305 baseline + 10 new widget tests）。

### Step 6: Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart
git commit -m "refactor(liuyao): delegate buildHistoryCard to HistoryRecordCard

Delete inline _LiuYaoHistoryCard class (~100 lines with helpers);
buildHistoryCard now 3 lines: type-check + return HistoryRecordCard.

Per spec 2026-04-18-history-card-visual-design §6.2. Factory
interface unchanged—internal implementation consolidation."
```

---

## Task 3: 大六壬工厂迁移到 `HistoryRecordCard`

**Files:**
- Modify: `lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart`

### Step 1: 定位内联 history card 代码

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -nE "Widget buildHistoryCard|class _DaLiuRenHistoryCard" lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart
```

DLR 的 history card 代码可能是 inline 在 `buildHistoryCard` 方法体里（没单独 class），也可能抽到了一个 private class。视实际结构调整。

### Step 2: 改写 `buildHistoryCard`

```dart
@override
Widget buildHistoryCard(DivinationResult result) {
  if (result is! DaLiuRenResult) {
    throw ArgumentError('结果类型必须是 DaLiuRenResult，实际类型: ${result.runtimeType}');
  }
  return HistoryRecordCard(result: result);
}
```

### Step 3: 删除内联 history card 相关代码

- 若是 inline 在 `buildHistoryCard` 里的 `Padding + AntiqueCard + Column` 块：直接替换掉整块
- 若有私有 class（比如 `_DaLiuRenHistoryCard`）：整个 class 删除
- 若有只被 history card 用的 helpers（`_formatDateTime` 等），顺手删

### Step 4: 更新 imports

```dart
import '../../../presentation/widgets/history_record_card.dart';
```

删除变得未使用的 imports（参考 Task 2 Step 4 做法）。

### Step 5: 验证

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze lib/divination_systems/daliuren/
flutter test 2>&1 | tail -3
```

Expected: analyze 绿，315 tests 过。

### Step 6: Commit

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git add lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart
git commit -m "refactor(daliuren): delegate buildHistoryCard to HistoryRecordCard

Mirror of Task 2 for the 大六壬 factory. Delete inline history
card code; single-line delegate to HistoryRecordCard. DLR now
gets the full antique 笺纸 card design (was using Material Card
wrappers historically until Bug 3 fix a92fd95, now unified)."
```

---

## Task 4: 全量验证

### Step 1: 全量 analyze + test

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
flutter analyze
flutter test 2>&1 | tail -5
bash tool/audit_hardcoded_colors.sh
```

Expected:
- analyze clean
- 315 tests 全过（305 baseline + 10 new widget tests）
- audit OK（HistoryRecordCard 里所有色走 `AppColors.*`，新增硬编码为 0）

### Step 2: grep 确认内联 history card 代码已清除

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -rn "_LiuYaoHistoryCard\|_DaLiuRenHistoryCard\|class.*HistoryCard" lib/divination_systems/ 2>/dev/null
```

Expected: 0 matches。`HistoryRecordCard` 是平台级共享 widget，不应在 `divination_systems/*/ui/` 下再定义同义 class。

### Step 3: grep 确认各工厂 buildHistoryCard 已单行化

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
grep -nA5 "Widget buildHistoryCard" lib/divination_systems/liuyao/ui/liuyao_ui_factory.dart lib/divination_systems/daliuren/ui/daliuren_ui_factory.dart
```

Expected: 每个 factory 的 `buildHistoryCard` 方法体只有 type check + return，总共 3-5 行。

### Step 4: 确认 Plan E-Card 所有 commits

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git log --oneline <plan-base>..HEAD
```

（`<plan-base>` = 合入 fix 分支后的 main HEAD，约 `248e958`）

Expected: 3-5 个 commits：spec commit + plan doc commit + 3 task commits（widget、liuyao、daliuren）。

### Step 5: 提交 plan 文档本身（如未提交）

```bash
cd "D:/SelfDeveloped/11.wanxiangpaipan"
git status
# 若 plan 尚未提交
git add docs/superpowers/plans/2026-04-18-history-card-visual-redesign.md
git commit -m "docs(plan): Plan E-Card - history card visual redesign"
```

### Step 6: 模拟器手工走查（用户侧）

> 前置：用户已预先开好模拟器（memory `feedback_emulator.md`），直接 `flutter run`。

Run: `cd "D:/SelfDeveloped/11.wanxiangpaipan" && flutter run`

验证项：

- [ ] 打开历史页，看到的每张卡片**顶部是占问文字**（不是卦名）
- [ ] 占问为空的记录：顶部有占位空行，**不显示**"未记录占问"字样
- [ ] 时间在占问下方，古褐色小字（11pt）
- [ ] 结果摘要朱砂色 bold（15pt），六爻是"乾为天 → 天风姤"、大六壬是"涉害课 · 初传申 中传子 末传辰"
- [ ] 两个 tag 横排：系统 tag 用对应系统色（六爻淡金棕、大六壬紫檀、梅花梅红、小六壬玉石青），方式 tag 统一 danjin 边 + guhe 字
- [ ] 背景图可辨（28% opacity）但不抢信息
- [ ] 点卡片有按压反馈（scale 0.98），长按弹确认对话框删除
- [ ] 4 种术数的卡片视觉一致（仅图 + 系统 tag 色不同）

---

## 完成标志

1. ✅ `lib/presentation/widgets/history_record_card.dart` 存在，5 个 helpers + 1 widget class
2. ✅ 10 个 widget tests 全过
3. ✅ 六爻工厂的 `buildHistoryCard` 退化为单行 delegate；`_LiuYaoHistoryCard` class 删除
4. ✅ 大六壬工厂的 `buildHistoryCard` 退化为单行 delegate；内联 history card 代码删除
5. ✅ `flutter analyze` 0 issues
6. ✅ `flutter test` 315 tests 全过
7. ✅ `bash tool/audit_hardcoded_colors.sh` OK
8. ✅ 用户模拟器走查视觉一致、图文共生可读

---

## 范围外

- **`DivinationUIFactory` 接口重构**（Plan E2 完整形态：`buildHistoryCard(result) → Widget` 改为 `buildHistorySummary(result) → HistorySummaryModel`）
- **小六壬 / 梅花 / 紫微的 history card**——需要对应系统实现起来后，在 `_summary` switch 补 case 即可，本 Plan 不涉及
- **收藏 / 笔记 / AI 解读标记**（需要数据层扩展，Plan E3）
- **详情页导航**（`onTap` 的 callback 目标，Plan E2 处理）
- **Golden test**（跨平台字体降级后 pixel-level 比较不稳，spec §7 已明确不做）
