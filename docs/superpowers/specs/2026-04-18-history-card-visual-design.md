# 历史记录卡片视觉设计规格

**日期**：2026-04-18
**状态**：Draft（待用户审阅）
**Spec 类型**：视觉设计规格 / 组件骨架收敛
**目标组件**：`lib/presentation/widgets/history_record_card.dart`（新建）
**相关既有 spec**：`docs/superpowers/specs/2026-04-18-history-screen-design.md`（历史页整体设计）

---

## 1. 背景

历史页在 Plan E1 完成功能升级（搜索/排序/时间分组/4 类状态页）后，Bug 3 fix（commit `a92fd95`）把六爻 + 大六壬的 `buildHistoryCard` 统一到了 5 层信息结构：

- Layer 1：占问事项
- Layer 2：时间
- Layer 3：结果摘要
- Layer 4：系统 tag
- Layer 5：起卦方式 tag

但 Bug 3 只做了**信息层级**的统一，视觉上每张卡还是"一段纯文字堆叠"——无装饰、无色彩层次、无图形元素。用户反馈："缺少美感"。

本 spec 从美学方向（笺纸式 antique）、图形要素（系统背景图作水印）、typography 层级、空间节奏、组件拆分五个维度把卡片视觉完整规格化，终结"美感靠感觉"的状态。

---

## 2. 美学方向

历史卡片采用**antique 笺纸**风格：每张卡视觉上是"一页带底纹的小笺"，每种术数有自己的背景图作为视觉身份，主信息层保持克制，**三色分层**（朱砂 / 淡金 / 玄色 + 辅助 guhe）明确。

被否决的替代方向：

| 方向 | 为何不选 |
|---|---|
| Reading-list 简素 | 和整体仿古调不搭，是当前"缺美感"的根源 |
| 单字章水印 | 汉字印章在 antique 已有组件（`AntiqueWatermark`）上用过；这里不是最佳——图片资源已经就位，且图比汉字信息更丰富 |
| 印章（章角贴标） | 装饰密度过高，列表扫读成本被分散 |

---

## 3. 总体结构

水平双重心：左列承载占问 + tag，右列承载时间 + 结果摘要。

```
┌──────────────────────────────────────────────┐
│                                              │
│ 占问事项（左, 17pt bold 玄色）  2026-04-18   │
│ 两行 + ellipsis                  14:32（右） │
│                                              │
│                            乾为天 → 天风姤   │
│                            （右对齐 15pt     │
│                              bold 朱砂）     │
│                                              │
│ [六爻] [时间卦]                …图@28%…     │
└──────────────────────────────────────────────┘
   ↑ AntiqueCard (padding: EdgeInsets.zero)
   └─ ClipRRect (radius: 8)
      └─ Stack
         ├─ Positioned.fill: Image @ 28% opacity
         └─ Padding(16): IntrinsicHeight · Row
            ├─ Expanded(flex 5): 左列 Column
            │    · spaceBetween
            │    · [L1 占问] ─── [L4+L5 tags]
            └─ Expanded(flex 4): 右列 Column
                 · spaceBetween, crossAxisEnd
                 · [L2 时间] ─── [L3 结果摘要]
```

两列 `mainAxisAlignment: spaceBetween` + `IntrinsicHeight` 保证：问题 1 行或 2 行时，左右两列同高；左底 tag 与右底摘要自然对齐在同一水平线。

**列表级节奏**：
- 水平边距：16px
- 卡片间垂直间距：12px（通过每张卡 `vertical: 6` padding 叠加）

---

## 4. Token 规格

### 4.1 字体（5 层）

| 层 | 样式 |
|---|---|
| L1 占问 | `antiqueTitle.copyWith(fontSize: 17, fontWeight: bold, letterSpacing: 1, color: xuanse, height: 1.4)` |
| L2 时间 | `antiqueLabel.copyWith(fontSize: 11, color: guhe, letterSpacing: 0.5)` |
| L3 结果摘要 | `antiqueBody.copyWith(fontSize: 15, fontWeight: bold, letterSpacing: 0.5, color: zhusha)` |
| L4 系统 tag label | `fontSize: 10, fontWeight: w500, letterSpacing: 0.5` |
| L5 方式 tag label | `fontSize: 10, fontWeight: normal, letterSpacing: 0.5` |

### 4.2 两列节奏

**左列（`Expanded flex: 5`，`crossAxis: start`，`mainAxis: spaceBetween`）**
```
[L1 占问]                ← minHeight: 24（空时也占这么高），maxLines: 2 + ellipsis
   ⇩ SizedBox(14)（question 1 行时由 spaceBetween 补齐额外空隙）
[L4+L5 tags] Wrap(spacing: 8, runSpacing: 4)
```

**右列（`Expanded flex: 4`，`crossAxis: end`，`mainAxis: spaceBetween`）**
```
[L2 时间]（textAlign: right）
   ⇩ SizedBox(8)（question 1 行时由 spaceBetween 补齐额外空隙）
[L3 结果摘要]（textAlign: right, maxLines: 2 + ellipsis）
```

两列之间水平间距：`SizedBox(width: 12)`。`IntrinsicHeight` 保证列高一致，`spaceBetween` 把剩余空间塞到中段，形成"顶上贴顶、底下贴底"的双重心节律。

### 4.3 Tag 色规格

**系统 tag**（使用各自系统色 token，均已在 `AppColors`）：

| 系统 | bg | border | text |
|---|---|---|---|
| 六爻 | `liuyaoColor @ 0.12` | `@ 0.35 w:1` | `liuyaoColor` |
| 大六壬 | `daliurenColor @ 0.12` | `@ 0.35 w:1` | `daliurenColor` |
| 小六壬 | `xiaoliurenColor @ 0.12` | `@ 0.35 w:1` | `xiaoliurenColor` |
| 梅花 | `meihuaColor @ 0.12` | `@ 0.35 w:1` | `meihuaColor` |

**方式 tag**（全部统一，不按方式区分色）：
- bg：`transparent`
- border：`danjin w:1`
- text：`guhe`

内 padding：`EdgeInsets.symmetric(horizontal: 10, vertical: 3)`。

### 4.4 背景图

```dart
Positioned.fill(
  child: Opacity(
    opacity: 0.28,
    child: Image.asset(
      backgroundPath,
      fit: BoxFit.cover,
      alignment: Alignment.bottomRight,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    ),
  ),
)
```

路径映射（4 张现有资源，首页 Bento 已在用）：
- `liuYao` → `assets/images/screen_card/liuyao_background.png`
- `daLiuRen` → `assets/images/screen_card/daliuren_background.png`
- `xiaoLiuRen` → `assets/images/screen_card/xiaoliuren_background.png`
- `meiHua` → `assets/images/screen_card/meihua_background.png`

opacity **28%**（不是首页的 60%）：历史列表叠加 20+ 条卡片，装饰要比入口页更克制。

---

## 5. 图文共生 & 边界

### 5.1 装配结构

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  child: AntiqueCard(
    onTap: onTap,
    padding: EdgeInsets.zero,               // 让 Stack 从卡边铺起
    semanticsLabel: _buildSemanticsLabel(...),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AntiqueTokens.radiusCard),
      child: Stack(
        children: [
          // 背景图
          Positioned.fill(child: Opacity(opacity: 0.28, child: Image.asset(...))),
          // 内容
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(...),
          ),
        ],
      ),
    ),
  ),
)
```

关键：
1. `AntiqueCard(padding: EdgeInsets.zero)` —— 把默认 16px padding 交给内部 `Padding` 管，这样 `Stack` 能从卡片边缘铺起
2. `ClipRRect` 在 Stack 外 —— `BoxFit.cover` 图超出时被圆角 clip，不溢出到卡外

### 5.2 文字可读性（无需 scrim）

4 张图构图都是**焦点在下半 / 右下**（铜钱在中右下、式盘居中、梅花在右下、手掌在右下）。`cover + bottomRight` alignment 把焦点压到卡下半——card 上 2/3（L1-L3 文字区）是图的稀薄纹路区，28% opacity 下可读性不受影响。

tag 区（card 下部）和图焦点重叠，但 tag 自带 bg 色块 + border，视觉"底板"充分，不依赖周围环境。

**不需要 white → transparent 遮罩层**。如果未来接入焦点在顶部的图才需要加。

### 5.3 边界情况

**L1 占问**：

| 情况 | 处理 |
|---|---|
| 30+ 字 | `maxLines: 2, overflow: ellipsis` |
| 单字 | 正常显示 |
| 空 | `minHeight: 24` 占位，不显示 placeholder 字 |
| 解密加载中 | 视作空（不显示 loading spinner） |
| 解密失败 | 视作空（不显示错误提示，保持列表纯净） |

**L3 结果摘要 format**：

- 六爻：`'$main'` 或 `'$main → $changing'`（例：`乾为天 → 天风姤`）
- 大六壬：`'${keType}课 · 初传${chu} 中传${zhong} 末传${mo}'`（例：`涉害课 · 初传申 中传子 末传辰`）
- `maxLines: 1, overflow: ellipsis`——典型长度都 1 行可容

**L4+L5 tag 区**：
- `Wrap(spacing: 8, runSpacing: 4)`——窄屏自动换行
- 顺序固定：系统 tag 在前、方式 tag 在后（符合"大类 → 小类"认知）

**背景图加载失败**：`errorBuilder` 返回空 widget，卡片正常渲染（没底纹）。

### 5.4 交互

- **点击**：`AntiqueCard` 自带 press scale 0.98 + 80ms ease-out。`onTap` 导航到详情页（Plan E2 实装，本 spec 暂留 `// TODO`，落地时 callback 可为 null）
- **长按删除**：由 list 层（`history_list_screen.dart`）的 `GestureDetector` 托管——卡片内部不需要管
- **滑动手势**（swipe-to-delete）：本次不做，Plan E3 考虑

### 5.5 a11y

`AntiqueCard.semanticsLabel` 传综合语义标签：

```dart
String _buildSemanticsLabel(String? question, DivinationResult result) {
  final parts = <String>[];
  if (question != null && question.isNotEmpty) {
    parts.add('占问：$question');
  }
  parts.add('${result.systemType.displayName}, ${result.castMethod.displayName}');
  parts.add(_summary(result));
  parts.add(_formatDateTime(result.castTime));
  return parts.join('。');
}
```

读屏器一句读出：`"占问：想换工作。六爻, 时间卦。乾为天 → 天风姤。2026-04-18 14:32"`。

卡片已通过 `AntiqueCard` 的 onTap 自动带 `isButton: true` semantics。

---

## 6. 实现架构

### 6.1 新建共享 widget

**`lib/presentation/widgets/history_record_card.dart`**：

```dart
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
    return FutureBuilder<String?>(
      future: repository.readEncryptedField('question_${result.id}'),
      builder: (context, snapshot) {
        final question = snapshot.data ?? '';
        return _buildCard(context, question);
      },
    );
  }

  Widget _buildCard(BuildContext context, String question) { /* ... */ }
}

// 私有 helpers (file-level)
String _summary(DivinationResult r) { /* switch on runtimeType */ }
String _systemLabel(DivinationType t) { /* from type.displayName */ }
Color _systemColor(DivinationType t) { /* from AppColors */ }
String? _systemBackground(DivinationType t) { /* from asset path mapping */ }
String _formatDateTime(DateTime dt) { /* yyyy-MM-dd HH:mm */ }
```

### 6.2 工厂调用退化

六爻 / 大六壬工厂的 `buildHistoryCard` 简化：

```dart
// liuyao_ui_factory.dart
@override
Widget buildHistoryCard(DivinationResult result) {
  if (result is! LiuYaoResult) {
    throw ArgumentError('结果类型必须是 LiuYaoResult');
  }
  return HistoryRecordCard(result: result);
}

// daliuren_ui_factory.dart（结构完全相同）
```

每工厂文件净减 ~80 行（删掉内联的 history card widget class + helpers）。

### 6.3 与 Plan E2 的关系

Plan E2 spec §8 主张"页面层统一骨架 + 系统层提供摘要"。完整形态是**改 `DivinationUIFactory` 接口**：`buildHistoryCard(result) → Widget` 改为 `buildHistorySummary(result) → HistorySummaryModel`，页面层统一画外壳。

本 spec **不改接口**，只通过共享 widget 实现等效效果——更稳妥：

- 不影响 `DivinationUIFactory` 其他调用点（registry docstring、未来的 `buildResultScreen` 等）
- 共享 widget 内部保留 typed result 访问（`is LiuYaoResult` / `is DaLiuRenResult`），不损失类型信息
- 未来决定真正重构接口时，`HistoryRecordCard` 是现成骨架

Plan E2 的 Phase 2 接口重构可保留作为未来优化，但不是必需——本 spec 落地后，历史卡片的"视觉 + 架构"两项都已达标。

---

## 7. 测试

`test/presentation/widgets/history_record_card_test.dart`，约 10 个 widget tests：

1. `renders 5 layers for LiuYaoResult`
2. `renders 5 layers for DaLiuRenResult`
3. `empty question preserves minHeight 24`
4. `long question (>40 chars) truncates after 2 lines with ellipsis`
5. `liuyao summary includes changing gua when present`
6. `liuyao summary shows only main gua when no changing`
7. `daliuren summary includes 课体 + 3 chuan`
8. `system tag text color matches AppColors.liuyaoColor for LiuYao`
9. `image errorBuilder renders SizedBox.shrink when asset missing`
10. `onTap triggers callback`

**不做**：
- Golden test（跨平台字体已降级承诺，pixel-level 比较不稳）
- 独立 a11y test（Semantics 通过 `AntiqueCard.semanticsLabel` 参数已被 Plan C2 的 AntiqueCard 测试覆盖）

---

## 8. 验收标准

1. ✅ `HistoryRecordCard` 存在，替代六爻 / 大六壬两个工厂内联的 history card
2. ✅ 6 爻 / 大六壬工厂的 `buildHistoryCard` 退化为单行 `return HistoryRecordCard(result: result)`
3. ✅ 5 层信息按第 4 节 token 渲染
4. ✅ 背景图 `Alignment.bottomRight` + 28% opacity 覆盖（4 种系统 + fallback）
5. ✅ 空占问不显示 placeholder 字，保留 24px 占位
6. ✅ 长占问 2 行 + ellipsis；长摘要 2 行 + ellipsis（右列宽，允许换行）
7. ✅ tag 颜色按系统区分，方式 tag 统一 guhe
8. ✅ `flutter analyze` 干净；10 个 widget tests 全过
9. ✅ 实模拟器走查：4 种术数的历史记录视觉一致、图文共生可读

---

## 9. 范围外

- **`DivinationUIFactory` 接口重构**（Plan E2 完整形态）
- **收藏 / 笔记状态 / AI 解读标记**（需要数据层扩展）
- **批量管理 / 滑动操作**（Plan E3）
- **详情页**（`onTap` 导航目标——Plan E2）
- **紫微斗数 / 奇门遁甲的背景图**（等系统骨架实现时补）
