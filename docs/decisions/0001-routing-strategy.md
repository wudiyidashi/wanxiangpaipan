# ADR 0001: 路由策略——目前用命令式，云端阶段再迁 go_router

**Status**: Accepted
**Date**: 2026-04-18
**Scope**: 全应用导航

---

## 背景

项目初始化（2026-01）时把 `go_router: ^14.3.0` 加进了 `pubspec.yaml`，但后续开发中**从未真正接入**——`lib/` 下零引用。实际导航走的是：

1. `MaterialApp.home = HomeScreen`（根页）
2. `MaterialApp.routes = { '/history': ..., '/settings': ..., '/ai-settings': ... }`（Flutter 1.x 风格命名路由，3 个二级页）
3. `Navigator.push(MaterialPageRoute(...))`（详情页）
4. 首页 4 个 tab 用 `AnimatedSwitcher + _currentNavIndex` 本地状态切换（不是路由）

2026-04 Dependabot 开了 PR #13 想把 go_router 升到 17.2.0（跨 3 主版本，API 破坏），CI 挂掉。审查时发现它根本没用。

## 决策

**目前阶段**：
- 从 `pubspec.yaml` **移除** `go_router` 死依赖
- 关闭 Dependabot PR #13
- 继续用**命令式导航 + 命名路由**

**未来触发迁移**的任何一条满足：
1. **决定出 web 版本** — URL 是硬需求
2. **接入云同步 + 账户登录** — 需要全局 `redirect` 守卫做权限拦截
3. **做深链接分享**（如分享某条历史排盘结果的 URL）
4. **首页 tab 要独立 Navigator 栈** — `StatefulShellRoute` 的典型场景

**迁移时**：直接从 go_router 当时最新版起步，不要中间升级。

## 理由

### 为什么现在不用 go_router

- 移动端 only（Android + iOS），无 URL 路由需求
- 浅栈导航（home + 3 二级 + push 详情），Navigator API 够用
- 无鉴权、无深链，路由守卫场景缺席
- go_router 14→15→16→17 每步都有 breaking，维护成本不低
- 死依赖占 pubspec 位置还会被 Dependabot 反复提醒

### 为什么不是"提前布局"

跨版本迁移（无论哪个声明式路由库）的**已知成本**一直比"需要时一次迁到当时最新版"高：
- 现在引入 14.x → 用不上 → 每 6 个月被 Dependabot 提醒
- 每次提醒都要读 changelog 判断是否升级，否则 pubspec.lock 会过时
- 真到要用时，API 已经变成 17.x+，历史的 14.x 用法要重写

所以**保持零负担**、**真需要时一次到位**更划算。

### 触发 #1 的云端计划

用户已明确表态"以后肯定要做云端"，所以触发迁移几乎必然发生。记录在 README roadmap Phase 3 的"云同步"条目下——做云同步 plan 时，先把路由迁到 go_router 作为前置任务。

## 影响

**立即**：
- 移除 pubspec 死依赖
- `flutter pub get` 更新 lockfile
- 关闭 PR #13
- 清理 CLAUDE.md / README 里对 go_router 和 `lib/core/router/` 目录的误引用

**长期**：
- Roadmap Phase 3 云同步 plan 需要包含"迁移到 go_router"作为前置子任务
- 无需现在学习 go_router API

## 不采纳的替代方案

**A. 保留 pubspec 声明但不用**
- 缺点：Dependabot 会持续开 PR，手动 ignore 规则要进 `.github/dependabot.yml`
- 每次 ignore 也是一种噪声
- 否决

**B. 合并 PR #13 升到 17.2.0**
- 缺点：升级一个没被引用的依赖，意义为零，还要改 CI 配置让 17.x 通过
- 否决

**C. 现在就接上 go_router 14.x**（为未来铺路）
- 缺点：当前 3 个命名路由用 go_router 反而是**降级**——boilerplate 更多、类型不更强、视觉无差别
- 在真正需要 URL / 守卫 / shell route 之前写的 go_router 配置大概率在云端 plan 里推翻重写
- 否决

## 参考

- PR #13（已关闭）：https://github.com/wudiyidashi/wanxiangpaipan/pull/13
- go_router CHANGELOG: https://pub.dev/packages/go_router/changelog
- 讨论语境：Plan C2 收尾后整理 Dependabot 时的决策（commits 2a791fc → e131ad7 附近）
