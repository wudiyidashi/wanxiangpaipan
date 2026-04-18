# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Flutter** application for **多术数系统平台** (Multi-Divination System Platform). The app supports multiple Chinese divination systems including 六爻 (Liu Yao), 大六壬 (Da Liu Ren), 小六壬 (Xiao Liu Ren), and 梅花易数 (Mei Hua Yi Shu).

**Current Status**: 六爻系统和大六壬系统均已完整实现；小六壬、梅花易数为骨架（isEnabled=false）。AI 解卦（OpenAI 兼容）已集成于 `lib/ai/`。

## Architecture

The project follows **Multi-Divination System Architecture** with **MVVM Pattern** and **Repository Pattern**, designed for extensibility and type safety.

### Multi-Divination System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation Layer (lib/presentation/)                     │
│  ├─ Screens (home, cast, result, history)                   │
│  └─ Widgets (divination_system_card, etc.)                  │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  ViewModel Layer (lib/viewmodels/)                          │
│  ├─ DivinationViewModel<T> (泛型基类)                       │
│  └─ LiuYaoViewModel (六爻实现)                              │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  Divination System Layer (lib/divination_systems/)          │
│  ├─ DivinationSystem (接口)                                 │
│  ├─ DivinationRegistry (注册表)                             │
│  ├─ LiuYaoSystem ✅ (六爻完整实现)                          │
│  ├─ DaLiuRenSystem ✅ (大六壬完整实现)                      │
│  ├─ XiaoLiuRenSystem 🚧 (小六壬骨架)                        │
│  └─ MeiHuaSystem 🚧 (梅花易数骨架)                          │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  UI Factory Layer (lib/presentation/)                       │
│  ├─ DivinationUIFactory (接口)                              │
│  ├─ DivinationUIRegistry (注册表)                           │
│  ├─ LiuYaoUIFactory (六爻 UI 工厂)                          │
│  └─ DaLiuRenUIFactory (大六壬 UI 工厂)                      │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  AI Layer (lib/ai/)                                         │
│  ├─ LLMProviderRegistry (模型提供商注册表)                  │
│  ├─ OpenAI 兼容 Provider                                    │
│  ├─ AIAnalysisService (解卦调用入口)                        │
│  └─ 提示词模板（按系统分类）                                │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  Repository Layer (lib/domain/repositories/)                │
│  ├─ DivinationRepository (接口)                             │
│  └─ DivinationRepositoryImpl (实现)                         │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  Data Layer (lib/data/)                                     │
│  ├─ DivinationRecords 表 (新架构)                           │
│  ├─ GuaRecords 表 (旧架构，向后兼容)                        │
│  └─ SecureStorage (加密字段)                                │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  Shared Services (lib/domain/services/shared/)              │
│  ├─ TianGanDiZhiService (天干地支)                          │
│  ├─ WuXingService (五行)                                    │
│  ├─ LiuQinService (六亲)                                    │
│  └─ LunarService (农历)                                     │
└─────────────────────────────────────────────────────────────┘
```

### Layer Structure (MVVM Pattern)
```
Presentation Layer (lib/presentation/)
    ↓ listens to
ViewModel Layer (lib/viewmodels/) ← uses DivinationSystem
    ↓ calls
Divination System Layer (lib/divination_systems/) ← implements DivinationSystem
    ↓ uses
Repository Layer (lib/domain/repositories/) ← interface definition
    ↓ implements
Data Layer (lib/data/) ← implementation (Database + Storage)
    +
Shared Services (lib/domain/services/shared/) ← pure functions
```

### Critical Architecture Rules

1. **Separation of Concerns**: UI, business logic, and data access are clearly separated.

2. **Unidirectional Data Flow**: User Action → ViewModel → Repository → Data Source → notifyListeners() → UI Update

3. **Dependency Injection**: Use Provider to manage dependencies and avoid global state.

4. **Immutable Data Models**: Use `freezed` to generate immutable data classes.

5. **Pure Function Services**: Business logic (e.g., hexagram calculation) implemented as pure static functions.

### Directory Structure
```
/lib
├── main.dart                    # App entry point with DivinationSystemBootstrap
├── /core                        # Core infrastructure
│   ├── /constants               # App constants
│   ├── (router: 目前用 MaterialApp.routes 命名路由内联在 main.dart)
│   ├── /theme                   # App themes (Chinese traditional style)
│   └── /utils                   # Utilities (logger, error handler)
├── /divination_systems          # Multi-divination system implementations
│   ├── /liuyao                  # 六爻系统 (完整实现)
│   │   ├── liuyao_system.dart   # DivinationSystem implementation
│   │   ├── /models
│   │   │   └── liuyao_result.dart # DivinationResult implementation
│   │   ├── /ui
│   │   │   └── liuyao_ui_factory.dart # DivinationUIFactory implementation
│   │   └── /viewmodels
│   │       └── liuyao_viewmodel.dart # DivinationViewModel<LiuYaoResult>
│   ├── /daliuren                # 大六壬系统 (完整实现)
│   │   ├── daliuren_system.dart # DivinationSystem implementation
│   │   ├── /models              # SiKe / Chuan / TianPan / ShenJiang / ShenSha
│   │   │   └── daliuren_result.dart
│   │   └── /ui
│   │       └── daliuren_ui_factory.dart
│   ├── /xiaoliuren              # 小六壬系统 (骨架，isEnabled=false)
│   │   ├── xiaoliuren_system.dart
│   │   └── /models
│   │       └── xiaoliuren_result.dart
│   ├── /meihua                  # 梅花易数系统 (骨架，isEnabled=false)
│   │   ├── meihua_system.dart
│   │   └── /models
│   │       └── meihua_result.dart
│   └── registry_bootstrap.dart  # 自动注册所有术数系统
├── /models                      # Shared data models (freezed + json_serializable)
│   ├── yao.dart                 # Yao (Line) model (六爻专用)
│   ├── gua.dart                 # Gua (Hexagram) model (六爻专用)
│   └── lunar_info.dart          # Lunar calendar info model (共享)
├── /domain                      # Domain layer
│   ├── divination_system.dart   # DivinationSystem interface (核心接口)
│   ├── divination_registry.dart # DivinationRegistry (系统注册表)
│   ├── /repositories            # Repository interfaces (contracts)
│   │   └── divination_repository.dart # 统一的占卜记录仓库接口
│   └── /services                # Pure function business services
│       ├── /shared              # 跨系统共享服务
│       │   ├── tiangan_dizhi_service.dart # 天干地支计算
│       │   ├── wuxing_service.dart        # 五行计算
│       │   ├── liuqin_service.dart        # 六亲计算
│       │   └── lunar_service.dart         # 农历计算
│       └── gua_calculator.dart  # 六爻专用算法
├── /data                        # Data layer (implementations)
│   ├── /database                # Drift database
│   │   ├── app_database.dart    # Database definition
│   │   ├── tables.dart          # Table schemas (DivinationRecords + GuaRecords)
│   │   └── /daos                # Data Access Objects
│   │       └── divination_record_dao.dart
│   ├── /secure                  # flutter_secure_storage wrapper
│   │   └── secure_storage.dart
│   └── /repositories            # Repository implementations
│       └── divination_repository_impl.dart # 统一实现
├── /viewmodels                  # ViewModel layer (ChangeNotifier)
│   └── divination_viewmodel.dart # DivinationViewModel<T> 泛型基类
└── /presentation                # UI layer (Widgets & Screens)
    ├── divination_ui_registry.dart # DivinationUIRegistry (UI 工厂注册表)
    ├── /screens                 # Screen pages
    │   ├── /home                # 首页（Tab 结构：主页 + 历史 + 日历 + 我的）
    │   ├── /cast                # 统一起卦界面 UnifiedCastScreen
    │   ├── /result              # 结果展示
    │   ├── /history             # 统一历史记录列表
    │   └── /settings            # 设置 + AI 设置 + 模板编辑
    └── /widgets                 # Reusable UI components（含 /antique 组件库）

/lib/ai                          # AI 解卦层
├── ai_bootstrap.dart            # 启动注册 Provider + 加载模板
├── llm_provider.dart            # LLMProvider 接口
├── llm_provider_registry.dart
├── /providers                   # 具体实现（OpenAI 兼容）
├── /service
│   └── ai_analysis_service.dart # 解卦调用入口
├── /config                      # API 配置持久化
├── /template                    # 提示词模板（按系统分类）
└── /output                      # 结构化输出解析
```

## Core Data Models

### Multi-Divination System Interfaces

#### DivinationSystem (术数系统接口)
```dart
abstract class DivinationSystem {
  DivinationType get type;           // 系统类型
  String get name;                   // 系统名称
  String get description;            // 系统描述
  bool get isEnabled;                // 是否启用
  List<CastMethod> get supportedMethods; // 支持的起卦方式

  Future<DivinationResult> cast({    // 执行占卜
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  });

  DivinationResult resultFromJson(Map<String, dynamic> json);
  bool validateInput(CastMethod method, Map<String, dynamic> input);
}
```

#### DivinationResult (占卜结果接口)
```dart
abstract class DivinationResult {
  String get id;                     // 唯一标识
  DivinationType get systemType;     // 所属系统
  DateTime get castTime;             // 占卜时间
  CastMethod get castMethod;         // 起卦方式
  LunarInfo get lunarInfo;           // 农历信息

  String getSummary();               // 获取摘要
  Map<String, dynamic> toJson();     // 序列化
}
```

### Liu Yao Specific Models (六爻专用模型)

#### Yao (爻) - Line
- 6 lines per hexagram, indexed 1-6
- States: yin/yang, moving/static
- Numbers: 6 (老阴), 7 (少阳), 8 (少阴), 9 (老阳)
- Attributes: branch (地支), stem (天干), sixRelative (六亲), fiveElement (五行)

#### Gua (卦) - Hexagram
- Contains 6 Yao objects
- Belongs to one of 8 palaces (八宫)
- Has exactly one 世爻 (seYao) and one 应爻 (yingYao)
- May have changingGua if there are moving lines

#### LiuYaoResult - Liu Yao Divination Result
- Implements DivinationResult interface
- Contains main Gua and optional changing Gua
- Six spirits (六神) and empty branches (空亡)
- User's question and interpretation

### Shared Models (共享模型)

#### LunarInfo - Lunar Calendar Information
- 月建 (yueJian): Monthly branch
- 日干支 (riGanZhi): Day stem-branch
- 空亡 (kongWang): Empty branches
- Used by all divination systems

## Key Business Rules

### Multi-Divination System Rules

1. **System Registration**: All divination systems must be registered in DivinationRegistry via DivinationSystemBootstrap
2. **Type Safety**: Each system has a unique DivinationType enum value
3. **Result Polymorphism**: All results implement DivinationResult interface for unified storage
4. **UI Factory Pattern**: Each system provides its own DivinationUIFactory for custom UI rendering
5. **Zero Migration**: New DivinationRecords table coexists with legacy GuaRecords table

### Liu Yao Specific Rules

1. **Moving Lines**: 老阴(6) and 老阳(9) MUST be moving; 少阴(8) and 少阳(7) MUST be static
2. **World/Response**: Each hexagram has exactly one 世爻 and one 应爻, they cannot be the same line
3. **Empty Branches**: Calculated from day stem-branch, always 2 adjacent branches
4. **Six Spirits**: Order determined by day stem, cycles through 青龙→朱雀→勾陈→腾蛇→白虎→玄武
5. **Changing Hexagram**: Only generated when main hexagram has moving lines

## Data Security

- **Encrypted Fields**: question, detail, userInterpretation (using flutter_secure_storage)
- **Non-encrypted**: System-specific result data (for fast queries in Drift database)
- **Polymorphic Storage**: resultData stored as JSON string, deserialized via DivinationSystem.resultFromJson()
- **Offline-first**: All records stored locally, optional cloud sync

## Testing Strategy

- **Unit Tests**: 90%+ coverage for domain services (pure algorithms, fully testable)
- **Widget Tests**: 70%+ coverage for UI components
- **Integration Tests**: Cover critical user flows (casting hexagrams, viewing history)
- Use `flutter_test` for unit and widget tests, `mocktail` for mocking

## Development Priorities

### 已完成工作

**基础架构**
- ✅ 共享服务 (TianGanDiZhi, WuXing, LiuQin, Lunar)
- ✅ 核心接口 (DivinationSystem, DivinationResult, DivinationUIFactory)
- ✅ 注册表机制 (DivinationRegistry, DivinationUIRegistry)
- ✅ 泛型 ViewModel 基类 (DivinationViewModel<T>)
- ✅ 零迁移数据层 (DivinationRecords + GuaRecords)

**术数系统**
- ✅ 六爻系统（6 种起卦方式：钱币/爻名/数字/报数/时间/电脑）
- ✅ 大六壬系统（4 种起课方式、四课三传、十二天将、神煞）

**UI 与体验**
- ✅ 统一起卦界面 UnifiedCastScreen
- ✅ 统一历史记录 HistoryListScreen
- ✅ 仿古风设计体系（13 色 token、10+ antique 组件、a11y Semantics）详见 `docs/superpowers/plans/`
- ✅ AI 解卦（OpenAI 兼容接口 + 按系统分类的提示词模板）

**测试**
- ✅ 283 tests 全部通过（单元 + Widget + Golden）

### 待实现

**小六壬系统 (Xiao Liu Ren)**
- 六神推算 (大安、留连、速喜、赤口、小吉、空亡)
- 月日时三次推算

**梅花易数系统 (Mei Hua)**
- 时间起卦、数字起卦、物象起卦
- 体用判断
- 变卦、互卦推导

**其他**
- 暗黑模式（墨色主题）
- 云同步（可选）
- 多语言（英文）
- 导出/分享

## Technology Stack

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **Language** | Dart | 3.0+ | Strong type system |
| **Framework** | Flutter | 3.38+ | Cross-platform UI |
| **State Management** | Provider | 6.x | Official recommendation |
| **Immutable Models** | freezed | 2.x | Code generation for data classes |
| **JSON Serialization** | json_serializable | 6.x | Auto-generate serialization |
| **Routing** | Flutter Navigator + named routes | — | Shallow nav; migrate to go_router at cloud-sync phase (see docs/decisions/0001-routing-strategy.md) |
| **Local Database** | drift | 2.x | Type-safe SQL with encryption |
| **Secure Storage** | flutter_secure_storage | 9.x | Keychain/Keystore |
| **Key-Value Prefs** | shared_preferences | 2.x | Theme / AI config |
| **Lunar Calendar** | lunar | 1.7.8 | Stems/Branches calculation |
| **Markdown** | flutter_markdown | 0.7+ | AI analysis result rendering |
| **LLM Client** | openai_dart | 4.x | OpenAI-compatible LLM access |
| **Testing** | flutter_test + mocktail | - | Unit & widget tests |

## Code Style

- **Dart**: Use strong typing, avoid `dynamic` unless necessary
- **Naming**: PascalCase for classes/types, camelCase for variables/functions, UPPER_SNAKE_CASE for constants
- **Immutability**: Use `@freezed` for all data models
- **Pure Functions**: Domain services must be pure static functions (no side effects)
- **Dependency Injection**: Use Provider, no global state
- **Error Handling**: Use custom error classes (ValidationError, DomainError, SystemError)
- **Commits**: Follow Conventional Commits (feat/fix/docs/refactor/test/chore)

## Performance Targets

- Hexagram calculation: < 100ms
- History loading: < 500ms
- App startup: < 2s
- Crash rate: < 0.1%

## Important Notes

### Multi-Divination System Architecture

- **DivinationSystem Interface**: All divination systems must implement this interface
- **DivinationRegistry**: Centralized registry for all systems, accessed via singleton pattern
- **DivinationUIRegistry**: Centralized registry for all UI factories
- **Type Safety**: Use generic types (e.g., `DivinationViewModel<T extends DivinationResult>`) for type-safe state management
- **Polymorphic Storage**: Results stored as JSON in `resultData` field, deserialized via `DivinationSystem.resultFromJson()`
- **Zero Migration**: New `DivinationRecords` table coexists with legacy `GuaRecords` table for backward compatibility
- **Automatic Registration**: All systems registered in `DivinationSystemBootstrap.initialize()` called from `main.dart`

### SOLID Principles Application

- **Single Responsibility**: Each system handles only its own divination logic
- **Open/Closed**: Add new systems without modifying existing code
- **Liskov Substitution**: All DivinationResult implementations are interchangeable
- **Interface Segregation**: Separate interfaces for System, Result, and UIFactory
- **Dependency Inversion**: Depend on abstractions (interfaces) not concrete implementations

### Development Guidelines

- **Domain Services**: PURE functions - no side effects, no direct data access
- **Shared Services**: Extract common logic (TianGanDiZhi, WuXing, etc.) to `/domain/services/shared/`
- **ViewModels**: Extend `ChangeNotifier` and call `notifyListeners()` after state updates
- **UI Widgets**: Should be "dumb" - only rendering, no business logic
- **Chromeless / body-only**: Any screen that might be embedded into another screen (tab body / dialog / bottom sheet) must provide a `chromeless` constructor parameter. When `chromeless: true`, the screen should return body-only content without wrapping itself in `AntiqueScaffold` / `AntiqueAppBar`. Reference implementation: `HistoryListScreen(chromeless: true)` used by `HomeScreen` tab 1.
- **Provider**: Use `Provider.select` for precise state subscription to optimize rebuilds
- **Calendar**: Use the `lunar` package which supports 天干地支, 六十甲子, 空亡
- **Performance**: Use `const` constructors wherever possible
- **Security**: Encrypted data in `flutter_secure_storage`, system data in Drift database

### Adding New Divination Systems

1. Create system directory under `/lib/divination_systems/[system_name]/`
2. Implement `DivinationSystem` interface in `[system_name]_system.dart`
3. Implement `DivinationResult` interface in `models/[system_name]_result.dart`
4. Implement `DivinationUIFactory` interface in `ui/[system_name]_ui_factory.dart`
5. Create `DivinationViewModel<YourResult>` in `viewmodels/[system_name]_viewmodel.dart`
6. Register system in `DivinationSystemBootstrap.initialize()`
7. Register UI factory in `DivinationUIRegistry`
8. Write unit tests for all components

See `docs/architecture.md` for the Epic-1 era detailed architecture reference (code examples refer to pre-refactor class names; use this file as narrative context, not as the source of truth).

See `docs/superpowers/plans/` for the engineering plans that delivered the multi-system architecture and antique UI design system.
