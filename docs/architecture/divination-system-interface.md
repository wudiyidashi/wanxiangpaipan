# 排盘抽象接口设计文档

**版本**: 1.0
**创建日期**: 2025-01-15
**最后更新**: 2025-01-15
**状态**: 已完成

---

## 概述

本文档描述了多术数系统架构的核心抽象层设计，包括 `DivinationSystem` 接口、`DivinationResult` 基类、以及 `DivinationRegistry` 注册表的设计原则和使用方法。

## 设计目标

1. **统一接口**: 为所有术数系统（六爻、大六壬、小六壬、梅花易数）提供一致的 API
2. **类型安全**: 使用强类型枚举和泛型确保编译时类型检查
3. **可插拔架构**: 通过注册表动态管理系统，支持系统的启用/禁用
4. **纯 Dart 实现**: Domain 层无 Flutter 依赖，可独立测试
5. **易于扩展**: 新增术数系统只需实现接口并注册

## 架构层次

```
┌─────────────────────────────────────────────────────────┐
│              Domain Layer (纯 Dart)                      │
│  ┌──────────────────────────────────────────────────┐   │
│  │  DivinationSystem (抽象接口)                      │   │
│  │  + type: DivinationType                          │   │
│  │  + name: String                                  │   │
│  │  + supportedMethods: List<CastMethod>            │   │
│  │  + cast(): Future<DivinationResult>              │   │
│  │  + resultFromJson(): DivinationResult            │   │
│  │  + validateInput(): bool                         │   │
│  └──────────────────────────────────────────────────┘   │
│                      ↑ implements                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ LiuYaoSystem │  │ DaLiuRenSys  │  │ MeiHuaSys    │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │  DivinationRegistry (单例注册表)                  │   │
│  │  + register(system)                              │   │
│  │  + getSystem(type): DivinationSystem             │   │
│  │  + getEnabledSystems(): List<DivinationSystem>   │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## 核心组件

### 1. DivinationType 枚举

定义了应用支持的所有术数系统类型。

```dart
enum DivinationType {
  liuYao('六爻', 'liuyao'),
  daLiuRen('大六壬', 'daliuren'),
  xiaoLiuRen('小六壬', 'xiaoliuren'),
  meiHua('梅花易数', 'meihua');

  const DivinationType(this.displayName, this.id);
  final String displayName;  // UI 显示名称
  final String id;           // 序列化标识符
}
```

**设计要点**:
- `displayName`: 用于 UI 显示的中文名称
- `id`: 用于数据库存储和序列化的唯一标识符
- `fromId()`: 静态方法，从 ID 字符串反序列化枚举值

### 2. CastMethod 枚举

定义了各种术数系统支持的起卦方法。

```dart
enum CastMethod {
  coin('摇钱法', 'coin'),
  time('时间起卦', 'time'),
  manual('手动输入', 'manual'),
  number('数字起卦', 'number'),
  random('随机起卦', 'random');

  const CastMethod(this.displayName, this.id);
  final String displayName;
  final String id;
}
```

**不同系统支持的起卦方式**:
- **六爻**: coin, time, manual
- **大六壬**: time, manual
- **小六壬**: time, random
- **梅花易数**: time, number, random

### 3. DivinationResult 抽象基类

所有术数系统的结果都必须继承此类。

```dart
abstract class DivinationResult {
  String get id;                    // UUID
  DateTime get castTime;            // 起卦时间
  DivinationType get systemType;    // 系统类型
  CastMethod get castMethod;        // 起卦方式
  LunarInfo get lunarInfo;          // 农历信息

  Map<String, dynamic> toJson();    // 序列化
  String getSummary();              // 结果摘要
}
```

**设计要点**:
- 定义了所有术数系统共享的属性
- `getSummary()` 用于历史记录列表显示
- `toJson()` 用于数据库存储

**子类实现示例**:
```dart
class LiuYaoResult extends DivinationResult {
  final Gua mainGua;
  final Gua? changingGua;
  final List<String> liuShen;
  // ... 其他六爻特有属性

  @override
  String getSummary() => changingGua != null
      ? '「${mainGua.name}」变「${changingGua!.name}」'
      : '「${mainGua.name}」';
}
```

### 4. DivinationSystem 抽象接口

所有术数系统都必须实现此接口。

```dart
abstract class DivinationSystem {
  DivinationType get type;
  String get name;
  String get description;
  List<CastMethod> get supportedMethods;
  bool get isEnabled;

  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  });

  DivinationResult resultFromJson(Map<String, dynamic> json);
  bool validateInput(CastMethod method, Map<String, dynamic> input);
}
```

**核心方法详解**:

#### cast() - 执行起卦

```dart
Future<DivinationResult> cast({
  required CastMethod method,
  required Map<String, dynamic> input,
  DateTime? castTime,
});
```

**参数说明**:
- `method`: 起卦方式，必须在 `supportedMethods` 列表中
- `input`: 起卦输入参数，格式根据 `method` 不同而不同
- `castTime`: 起卦时间，可选，默认为当前时间

**输入参数格式**:
```dart
// 摇钱法
{'coins': [true, false, true, true, false, true]}  // 可选

// 时间起卦
{'time': DateTime.now()}  // 可选

// 手动输入（六爻）
{'yaoNumbers': [6, 7, 8, 9, 8, 7]}

// 数字起卦（梅花易数）
{'number': 123}

// 随机起卦
{}  // 无需参数
```

**异常处理**:
- `ArgumentError`: 如果 `method` 不在 `supportedMethods` 中
- `ArgumentError`: 如果 `input` 验证失败
- `StateError`: 如果系统未启用

#### validateInput() - 验证输入

```dart
bool validateInput(CastMethod method, Map<String, dynamic> input);
```

**验证规则示例**:
```dart
@override
bool validateInput(CastMethod method, Map<String, dynamic> input) {
  switch (method) {
    case CastMethod.coin:
      return true;  // 无需参数
    case CastMethod.time:
      return input['time'] == null || input['time'] is DateTime;
    case CastMethod.manual:
      final yaoNumbers = input['yaoNumbers'];
      return yaoNumbers is List &&
             yaoNumbers.length == 6 &&
             yaoNumbers.every((n) => n >= 6 && n <= 9);
    default:
      return false;
  }
}
```

#### resultFromJson() - 反序列化

```dart
DivinationResult resultFromJson(Map<String, dynamic> json);
```

用于从数据库加载历史记录，必须能够完整还原通过 `toJson()` 序列化的对象。

### 5. DivinationRegistry 注册表

单例模式的系统注册表，管理所有已注册的术数系统。

```dart
class DivinationRegistry {
  static final DivinationRegistry _instance = DivinationRegistry._internal();
  factory DivinationRegistry() => _instance;

  void register(DivinationSystem system);
  DivinationSystem getSystem(DivinationType type);
  List<DivinationSystem> getEnabledSystems();
  bool isRegistered(DivinationType type);
  void clear();
}
```

**核心方法**:

#### register() - 注册系统

```dart
void register(DivinationSystem system) {
  _systems[system.type] = system;
}
```

如果系统已注册，会覆盖旧的实例。

#### getSystem() - 获取系统

```dart
DivinationSystem getSystem(DivinationType type) {
  final system = _systems[type];
  if (system == null) {
    throw StateError('术数系统未注册: ${type.displayName}');
  }
  if (!system.isEnabled) {
    throw StateError('术数系统已禁用: ${type.displayName}');
  }
  return system;
}
```

**异常处理**:
- 系统未注册时抛出 `StateError`
- 系统已禁用时抛出 `StateError`

#### getEnabledSystems() - 获取启用的系统

```dart
List<DivinationSystem> getEnabledSystems() {
  return _systems.values.where((s) => s.isEnabled).toList();
}
```

用于主页显示可用的术数系统列表。

## 使用示例

### 1. 实现一个术数系统

```dart
class LiuYaoSystem implements DivinationSystem {
  @override
  DivinationType get type => DivinationType.liuYao;

  @override
  String get name => '六爻占卜';

  @override
  String get description => '传统六爻排盘，使用摇钱法、时间起卦或手动输入';

  @override
  List<CastMethod> get supportedMethods => [
    CastMethod.coin,
    CastMethod.time,
    CastMethod.manual,
  ];

  @override
  bool get isEnabled => true;

  @override
  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  }) async {
    // 1. 验证输入
    if (!validateInput(method, input)) {
      throw ArgumentError('无效的输入参数');
    }

    // 2. 获取起卦时间
    final time = castTime ?? DateTime.now();

    // 3. 计算农历信息
    final lunarInfo = LunarService.getLunarInfo(time);

    // 4. 根据起卦方式生成卦象
    final yaoNumbers = _getYaoNumbers(method, input);

    // 5. 计算卦象
    final mainGua = GuaCalculator.calculate(yaoNumbers, lunarInfo);
    final changingGua = GuaCalculator.calculateChangingGua(mainGua);

    // 6. 返回结果
    return LiuYaoResult(
      id: const Uuid().v4(),
      castTime: time,
      systemType: type,
      castMethod: method,
      lunarInfo: lunarInfo,
      mainGua: mainGua,
      changingGua: changingGua,
    );
  }

  @override
  DivinationResult resultFromJson(Map<String, dynamic> json) {
    return LiuYaoResult.fromJson(json);
  }

  @override
  bool validateInput(CastMethod method, Map<String, dynamic> input) {
    switch (method) {
      case CastMethod.coin:
        return true;
      case CastMethod.time:
        return input['time'] == null || input['time'] is DateTime;
      case CastMethod.manual:
        final yaoNumbers = input['yaoNumbers'];
        return yaoNumbers is List &&
               yaoNumbers.length == 6 &&
               yaoNumbers.every((n) => n >= 6 && n <= 9);
      default:
        return false;
    }
  }

  List<int> _getYaoNumbers(CastMethod method, Map<String, dynamic> input) {
    switch (method) {
      case CastMethod.coin:
        return QiguaService.coinCast();
      case CastMethod.time:
        final time = input['time'] as DateTime? ?? DateTime.now();
        return QiguaService.timeCast(time);
      case CastMethod.manual:
        return List<int>.from(input['yaoNumbers'] as List);
      default:
        throw UnsupportedError('不支持的起卦方式: ${method.displayName}');
    }
  }
}
```

### 2. 注册和使用系统

```dart
// 在 main.dart 中注册系统
void main() {
  // 注册所有术数系统
  final registry = DivinationRegistry();
  registry.register(LiuYaoSystem());
  registry.register(DaLiuRenSystem());
  registry.register(MeiHuaSystem());

  runApp(MyApp());
}

// 在 ViewModel 中使用
class DivinationViewModel extends ChangeNotifier {
  final DivinationRegistry _registry = DivinationRegistry();

  Future<DivinationResult> performDivination({
    required DivinationType systemType,
    required CastMethod method,
    required Map<String, dynamic> input,
  }) async {
    try {
      // 获取系统
      final system = _registry.getSystem(systemType);

      // 执行起卦
      final result = await system.cast(
        method: method,
        input: input,
      );

      return result;
    } catch (e) {
      // 错误处理
      rethrow;
    }
  }

  List<DivinationSystem> getAvailableSystems() {
    return _registry.getEnabledSystems();
  }
}
```

### 3. 在 UI 中显示可用系统

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final registry = DivinationRegistry();
    final systems = registry.getEnabledSystems();

    return ListView.builder(
      itemCount: systems.length,
      itemBuilder: (context, index) {
        final system = systems[index];
        return ListTile(
          title: Text(system.name),
          subtitle: Text(system.description),
          onTap: () {
            // 导航到起卦页面
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CastScreen(system: system),
              ),
            );
          },
        );
      },
    );
  }
}
```

## 设计原则

### 1. 单一职责原则 (SRP)

- `DivinationSystem`: 负责起卦逻辑
- `DivinationResult`: 负责结果数据
- `DivinationRegistry`: 负责系统管理

### 2. 开闭原则 (OCP)

- 接口对扩展开放：新增术数系统只需实现接口
- 接口对修改关闭：不需要修改现有代码

### 3. 里氏替换原则 (LSP)

- 所有 `DivinationSystem` 实现都可以互相替换
- 所有 `DivinationResult` 子类都可以互相替换

### 4. 接口隔离原则 (ISP)

- 接口方法精简，只包含必要的方法
- 不强制实现不需要的方法

### 5. 依赖倒置原则 (DIP)

- ViewModel 依赖 `DivinationSystem` 接口，而非具体实现
- 通过注册表解耦系统实现和使用方

## 扩展指南

### 添加新的术数系统

1. **定义结果类**:
```dart
class XiaoLiuRenResult extends DivinationResult {
  final String course;  // 课式
  final String prediction;  // 预测结果
  // ... 其他属性
}
```

2. **实现系统接口**:
```dart
class XiaoLiuRenSystem implements DivinationSystem {
  @override
  DivinationType get type => DivinationType.xiaoLiuRen;

  // ... 实现所有接口方法
}
```

3. **注册系统**:
```dart
DivinationRegistry().register(XiaoLiuRenSystem());
```

4. **编写测试**:
```dart
test('小六壬系统应该正确起卦', () async {
  final system = XiaoLiuRenSystem();
  final result = await system.cast(
    method: CastMethod.time,
    input: {},
  );
  expect(result, isA<XiaoLiuRenResult>());
});
```

### 添加新的起卦方式

1. **在 CastMethod 枚举中添加**:
```dart
enum CastMethod {
  // ... 现有方式
  voice('语音起卦', 'voice'),  // 新增
}
```

2. **在系统中支持**:
```dart
@override
List<CastMethod> get supportedMethods => [
  CastMethod.coin,
  CastMethod.time,
  CastMethod.voice,  // 新增
];
```

3. **实现验证和起卦逻辑**:
```dart
@override
bool validateInput(CastMethod method, Map<String, dynamic> input) {
  switch (method) {
    // ... 现有方式
    case CastMethod.voice:
      return input['audioData'] != null;
  }
}
```

## 测试策略

### 单元测试

- **枚举测试**: 验证 `fromId()` 方法和唯一性
- **注册表测试**: 验证注册、查询、启用/禁用逻辑
- **系统实现测试**: 验证每个术数系统的起卦逻辑

### 集成测试

- **端到端流程**: 从 UI 到数据库的完整流程
- **系统切换**: 验证不同系统之间的切换

### 测试覆盖率目标

- Domain 层: ≥ 90%
- 系统实现: ≥ 85%
- 注册表: 100%

## 已知限制

1. **线程安全**: 当前注册表实现非线程安全，但 Flutter 单线程模型下无问题
2. **系统禁用**: `getSystem()` 会检查 `isEnabled`，禁用的系统会抛出异常
3. **重复注册**: 后注册的系统会覆盖先注册的系统

## 未来改进

1. **插件化**: 支持动态加载术数系统插件
2. **配置化**: 通过配置文件管理系统启用状态
3. **版本管理**: 支持系统版本升级和数据迁移
4. **性能优化**: 缓存计算结果，减少重复计算

## 参考资料

- [SOLID 原则](https://en.wikipedia.org/wiki/SOLID)
- [Flutter 架构指南](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options)
- [Dart 语言规范](https://dart.dev/guides/language/language-tour)

---

**文档维护者**: James (Dev Agent)
**最后审核**: 2025-01-15
