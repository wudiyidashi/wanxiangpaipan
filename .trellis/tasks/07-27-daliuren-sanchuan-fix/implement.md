# 实施清单：九宗门三传正确性修复

规则唯一依据：本任务 `design.md`。禁止参考网络或凭记忆改规则；有疑问以 design.md 为准。

## Step 1 常量层（daliuren_constants.dart）

- [ ] 替换 `ganJiGong` 为六壬寄宫表（design §1.1）；`getGanJiGong` 兜底值改为返回原样或断言（不得再默认'子'——癸不寄子了，静默兜底会掩盖错误；改为 `ganJiGong[gan]!` 或抛 ArgumentError）。
- [ ] 新增 `gongJiGan`（宫→寄干反查，design §1.2）。
- [ ] 新增 `sanXing`（三刑表 §1.4）、`ganWuHe`（干五合 §1.5）、`yiMa`（驿马 §1.6）、`sanHeOrder`（三合局序 §1.7）与对应静态取值方法。
- [ ] 新增八专日判定 `isBaZhuanDay(gan, zhi)`（干寄宫==支）。

## Step 2 四课方向修正（si_ke_service.dart）

- [ ] `_createKe`：两方向独立判定；下克上→`isZeiKe=true`（下贼上），上克下→`isBiYong=true`；删除"上克下为正统当前优先发用"注释。
- [ ] `wuXingRelation` 字符串取值维持现状。

## Step 3 三传引擎重写（san_chuan_service.dart）

按 design §3 总流程与 §4 细则实现：

- [ ] 贼克：下贼上优先，初传取上神；元首/重审注入说明。
- [ ] 比用：同方向候选取比；不唯一→涉害。
- [ ] 涉害：深度计数（含临宫、不含本家；本气+寄干各计一害）→ 孟上 → 仲上 → 刚日干上/柔日支上；说明含深度数值。
- [ ] 遥克：二三四课上神，蒿矢先、弹射后，多者取比，再取课序前。
- [ ] 昴星：刚仰（地盘酉上神/中支上/末干上）、柔俯（天盘酉下之支/中干上/末支上）。
- [ ] 别责：刚日干合寄宫上神、柔日支前合；中末=干上神。
- [ ] 八专：无克时阳顺三/阴逆三（含本位），中末=干上神；有克走贼克流程但课体标 baZhuan。
- [ ] 伏吟：有克取克（贼克/比用裁选）；无克刚自任/柔自信；中末走刑传链＋自刑分支（§4.8）。
- [ ] 反吟：有克按贼克/比用/涉害取**上神**，中末天盘链；无克取日支驿马、中支上、末干上。
- [ ] 中末传通用规则仅用于 §3 标注的课体。

## Step 4 黄金课例测试

- [ ] 新建 `test/unit/services/daliuren/san_chuan_service_test.dart`：13 例（design §5 表）逐一构造 `SiKeService.arrangeSiKe(riGan, riZhi, tianPanMap)` + `SanChuanService.deriveSanChuan`，断言：keType、三传三支；K/B/A/C 例加断四课上下神；说明关键词（B:"下贼上"，C:"涉害"+深度，D:"弹射"，D2:"蒿矢"，H2:"自刑"，J:"驿马"）。
- [ ] tianPanMap 构造辅助：由位移 s 生成 12 项映射。
- [ ] 补 SiKeService 方向单测（design §7）。

## Step 5 波及面与既有测试

- [ ] 全库 grep `getGanJiGong` 调用点复核（当前仅 si_ke/san_chuan 两处 + 常量自身），UI 层如有寄宫展示一并核对。
- [ ] `daliuren_system_test.dart` 2026-04-18 样例：运行新引擎得到实际值，按 design 规则**手工逐步复推**（月将、天盘、四课、课体、三传）确认无误后更新期望值；在测试注释中写明推导链。
- [ ] `flutter analyze` 零新增告警。
- [ ] `flutter test` 全量通过；确认六爻侧测试零变化。

## Step 6 验证命令

```bash
flutter analyze
flutter test test/unit/services/daliuren/ test/unit/divination_systems/daliuren/
flutter test
```

## 回滚点

- 单 commit 完成；如需回滚 `git revert` 该提交即可。常量/服务无 schema 迁移。

## 明确不做

- 不改 UI 布局与文案结构；不迁移历史记录；不做课体派系可配置化；不动六爻侧文件；不提交工作区已有的 3 个六爻遗留改动。
