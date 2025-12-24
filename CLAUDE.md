# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Flutter** application for **多术数系统平台** (Multi-Divination System Platform). The app supports multiple Chinese divination systems including 六爻 (Liu Yao), 大六壬 (Da Liu Ren), 小六壬 (Xiao Liu Ren), and 梅花易数 (Mei Hua Yi Shu).

**Current Status**: 六爻系统已完整实现，其他系统为骨架（isEnabled=false）

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
│  ├─ LiuYaoSystem (六爻实现)                                 │
│  ├─ DaLiuRenSystem (大六壬骨架)                             │
│  ├─ XiaoLiuRenSystem (小六壬骨架)                           │
│  └─ MeiHuaSystem (梅花易数骨架)                             │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  UI Factory Layer (lib/presentation/)                       │
│  ├─ DivinationUIFactory (接口)                              │
│  ├─ DivinationUIRegistry (注册表)                           │
│  └─ LiuYaoUIFactory (六爻 UI 工厂)                          │
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
│   ├── /router                  # go_router configuration
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
│   ├── /daliuren                # 大六壬系统 (骨架，isEnabled=false)
│   │   ├── daliuren_system.dart
│   │   └── /models
│   │       └── daliuren_result.dart
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
    │   ├── /home
    │   │   ├── home_screen.dart           # 系统选择主界面
    │   │   └── method_selector_screen.dart # 起卦方式选择
    │   ├── /cast                # 动态起卦界面（通过 UIFactory 构建）
    │   │   ├── coin_cast_screen.dart
    │   │   ├── time_cast_screen.dart
    │   │   └── manual_cast_screen.dart
    │   ├── /result              # 动态结果展示（通过 UIFactory 构建）
    │   │   └── result_screen.dart
    │   └── /history             # 统一历史记录列表
    │       └── history_list_screen.dart
    └── /widgets                 # Reusable UI components
        ├── divination_system_card.dart # 术数系统卡片
        ├── yao_display.dart     # Yao line display widget (六爻专用)
        ├── gua_card.dart        # Hexagram card widget (六爻专用)
        └── coin_animation.dart  # Coin toss animation
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

### Epic 6: Multi-Divination System Architecture (已完成 75%)

**Phase 1: Foundation (已完成)**
- ✅ 提取共享服务 (TianGanDiZhi, WuXing, LiuQin, Lunar)
- ✅ 定义核心接口 (DivinationSystem, DivinationResult)
- ✅ 创建 UI 工厂和注册表 (DivinationUIFactory, DivinationUIRegistry)

**Phase 2: Liu Yao Refactoring (已完成)**
- ✅ 重构六爻系统为 DivinationSystem 实现
- ✅ 创建泛型 ViewModel 基类 (DivinationViewModel<T>)
- ✅ 实现六爻 UI 工厂 (LiuYaoUIFactory)

**Phase 3: Data Layer & UI Integration (已完成)**
- ✅ 零迁移数据层 (DivinationRecords + GuaRecords)
- ✅ 仓库适配器模式 (DivinationRepositoryImpl)
- ✅ 自动注册机制 (DivinationSystemBootstrap)
- ✅ 动态主界面 (HomeScreen with system selector)
- ✅ 动态起卦界面 (CastScreen with UIFactory)
- ✅ 动态结果展示 (ResultScreen with UIFactory)
- ✅ 统一历史记录 (HistoryListScreen)
- ✅ 未来系统骨架 (DaLiuRen, XiaoLiuRen, MeiHua)

**Phase 4: Documentation & Testing (进行中)**
- ✅ 测试覆盖率 99.6% (227/228 tests passing)
- 🔄 文档更新 (Story 6.16 进行中)

### Future Development (未来系统实现)

**大六壬系统 (Da Liu Ren)**
- 四课三传算法
- 十二神将配置
- 神煞系统

**小六壬系统 (Xiao Liu Ren)**
- 六神推算 (大安、留连、速喜、赤口、小吉、空亡)
- 月日时三次推算

**梅花易数系统 (Mei Hua)**
- 时间起卦、数字起卦、物象起卦
- 体用判断
- 变卦、互卦推导

## Technology Stack

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **Language** | Dart | 3.0+ | Strong type system |
| **Framework** | Flutter | 3.24+ | Cross-platform UI |
| **State Management** | Provider | 6.x | Official recommendation |
| **Immutable Models** | freezed | 2.x | Code generation for data classes |
| **JSON Serialization** | json_serializable | 6.x | Auto-generate serialization |
| **Routing** | go_router | 14.x | Declarative routing |
| **Local Database** | drift | 2.x | Type-safe SQL with encryption |
| **Secure Storage** | flutter_secure_storage | 9.x | Keychain/Keystore |
| **Lunar Calendar** | lunar | 1.7.8 | Stems/Branches calculation |
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

See `docs/architecture/adding-new-system.md` for detailed guide.
