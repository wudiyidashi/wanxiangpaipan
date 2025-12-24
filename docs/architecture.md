# 万象排盘 Flutter 架构设计文档

**版本**: 1.0
**创建日期**: 2025-01-14
**架构师**: Winston
**状态**: 草稿

---

## 目录

1. [架构概览](#架构概览)
2. [技术栈](#技术栈)
3. [项目结构](#项目结构)
4. [数据模型层](#数据模型层)
5. [Domain 服务层](#domain-服务层)
6. [Repository 层](#repository-层)
7. [ViewModel 层](#viewmodel-层)
8. [Presentation 层](#presentation-层)
9. [数据持久化](#数据持久化)
10. [路由与导航](#路由与导航)
11. [依赖注入](#依赖注入)
12. [测试策略](#测试策略)
13. [性能优化](#性能优化)
14. [安全性](#安全性)
15. [历史变更与缺陷修复](#历史变更与缺陷修复)
16. [扩展性与多术数方案](#扩展性与多术数方案)

---

## 架构概览

### MVVM 架构图

```
┌─────────────────────────────────────────────────────────┐
│                  Presentation Layer                     │
│         (Flutter Widgets - "Dumb" Views)                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ HomeScreen   │  │ CastScreen   │  │ ResultScreen │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │
│         │                  │                  │          │
│         └──────────────────┼──────────────────┘          │
└─────────────────────────────┼────────────────────────────┘
                              │ Consumer / Selector
                              │ (listens to notifyListeners)
┌─────────────────────────────┼────────────────────────────┐
│                     ViewModel Layer                       │
│             (Business Logic + UI State)                   │
│  ┌──────────────────────────────────────────────────┐   │
│  │  CastViewModel (ChangeNotifier)                  │   │
│  │  - castCoins()                                   │   │
│  │  - generateGua()                                 │   │
│  │  - notifyListeners()                             │   │
│  └───────────────────┬──────────────────────────────┘   │
└────────────────────────┼───────────────────────────────────┘
                         │ calls methods
┌────────────────────────┼───────────────────────────────────┐
│              Repository Layer (Interfaces)                 │
│  ┌─────────────────────────────────────────────────┐     │
│  │  abstract class GuaRepository                   │     │
│  │  - Future<void> saveRecord(GuaRecord)           │     │
│  │  - Future<List<GuaRecord>> getAllRecords()      │     │
│  │  - Future<GuaRecord?> getRecordById(String id)  │     │
│  └──────────────────────┬──────────────────────────┘     │
└───────────────────────────┼────────────────────────────────┘
                            │ implements
┌───────────────────────────┼────────────────────────────────┐
│                  Data Layer (Implementations)              │
│  ┌──────────────────────────────────────────────────┐    │
│  │  GuaRepositoryImpl implements GuaRepository      │    │
│  │  - uses AppDatabase (Drift)                      │    │
│  │  - uses SecureStorage (flutter_secure_storage)   │    │
│  └──────────────────────────────────────────────────┘    │
│                                                            │
│  [Drift Database] ← SQL persistence                       │
│  [SecureStorage] ← Encrypted sensitive data               │
│                                                            │
└────────────────────────────────────────────────────────────┘
                         ↑ uses
┌────────────────────────┼────────────────────────────────────┐
│            Domain Services (Pure Functions)                 │
│  ┌──────────────────────────────────────────────────┐     │
│  │  GuaCalculator - calculateYao(), identifySeYao() │     │
│  │  LunarService - getLunarInfo(), getKongWang()    │     │
│  │  LiuShenService - calculateLiuShen()             │     │
│  │  QiGuaService - coinCast(), timeCast()           │     │
│  └──────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### 架构原则

1. **单向数据流**: User Action → ViewModel → Repository → Data Source → notifyListeners() → UI Update
2. **关注点分离**: UI 只负责渲染，业务逻辑在 ViewModel，数据访问在 Repository
3. **依赖倒置**: ViewModel 依赖 Repository 接口，不依赖具体实现
4. **不可变数据**: 使用 `freezed` 生成不可变数据类
5. **纯函数服务**: 核心算法实现为纯静态函数，易于测试
6. **依赖注入**: 使用 Provider 管理依赖，避免全局状态

---

## 技术栈

| 类别 | 技术 | 版本 | 用途 |
|------|------|------|------|
| **语言** | Dart | 3.5+ | 强类型系统 |
| **框架** | Flutter | 3.24+ | 跨平台 UI 框架 |
| **状态管理** | Provider | 6.1.2+ | 依赖注入 + 状态管理 |
| **不可变模型** | freezed | 2.5.7+ | 代码生成（不可变类） |
| **JSON 序列化** | json_serializable | 6.8.0+ | JSON 序列化代码生成 |
| **路由** | go_router | 14.3.0+ | 声明式路由 |
| **本地数据库** | drift | 2.20.3+ | 类型安全 SQL |
| **加密存储** | flutter_secure_storage | 9.2.2+ | Keychain/Keystore |
| **农历计算** | lunar | 1.7.8+ | 天干地支、空亡计算 |
| **代码生成** | build_runner | 2.4.13+ | 运行代码生成器 |
| **测试** | mocktail | 1.0.4+ | Mock 框架 |

---

## 项目结构

```
wanxiang_paipan/
├── lib/
│   ├── main.dart                         # 应用入口 + Provider 配置
│   │
│   ├── core/                             # 核心基础设施
│   │   ├── constants/
│   │   │   ├── app_constants.dart        # 应用常量
│   │   │   ├── yao_constants.dart        # 六爻常量（天干地支等）
│   │   │   └── colors.dart               # 颜色常量
│   │   ├── router/
│   │   │   └── app_router.dart           # go_router 配置
│   │   ├── theme/
│   │   │   ├── app_theme.dart            # Material 主题
│   │   │   └── chinese_theme.dart        # 中国风配色
│   │   └── utils/
│   │       ├── logger.dart               # 日志工具
│   │       └── error_handler.dart        # 错误处理
│   │
│   ├── models/                           # 数据模型（freezed）
│   │   ├── yao.dart                      # 爻模型
│   │   ├── yao.freezed.dart              # 生成文件
│   │   ├── yao.g.dart                    # 生成文件
│   │   ├── gua.dart                      # 卦模型
│   │   ├── gua_record.dart               # 占卜记录
│   │   └── lunar_info.dart               # 农历信息
│   │
│   ├── domain/                           # 领域层
│   │   ├── repositories/                 # Repository 接口
│   │   │   ├── gua_repository.dart
│   │   │   └── settings_repository.dart
│   │   └── services/                     # 纯函数服务
│   │       ├── gua_calculator.dart       # 卦象计算算法
│   │       ├── lunar_service.dart        # 农历计算
│   │       ├── qigua_service.dart        # 起卦逻辑
│   │       └── liushen_service.dart      # 六神计算
│   │
│   ├── data/                             # 数据层
│   │   ├── database/
│   │   │   ├── app_database.dart         # Drift 数据库定义
│   │   │   ├── app_database.g.dart       # 生成文件
│   │   │   ├── tables.dart               # 表定义
│   │   │   └── daos/
│   │   │       └── gua_dao.dart          # DAO
│   │   ├── secure/
│   │   │   └── secure_storage.dart       # 加密存储服务
│   │   └── repositories/
│   │       ├── gua_repository_impl.dart  # Repository 实现
│   │       └── settings_repository_impl.dart
│   │
│   ├── viewmodels/                       # ViewModel 层
│   │   ├── cast_viewmodel.dart           # 起卦 VM
│   │   ├── gua_result_viewmodel.dart     # 卦象结果 VM
│   │   └── history_viewmodel.dart        # 历史记录 VM
│   │
│   └── presentation/                     # UI 层
│       ├── screens/
│       │   ├── home/
│       │   │   └── home_screen.dart
│       │   ├── cast/
│       │   │   ├── coin_cast_screen.dart
│       │   │   ├── time_cast_screen.dart
│       │   │   └── manual_cast_screen.dart
│       │   ├── result/
│       │   │   └── gua_result_screen.dart
│       │   └── history/
│       │       ├── history_list_screen.dart
│       │       └── record_detail_screen.dart
│       └── widgets/
│           ├── yao_display.dart          # 爻显示组件
│           ├── gua_card.dart             # 卦象卡片
│           └── coin_animation.dart       # 硬币动画
│
├── test/                                 # 测试
│   ├── unit/
│   │   ├── services/
│   │   └── viewmodels/
│   ├── widget/
│   └── integration/
│
├── pubspec.yaml                          # 依赖配置
├── analysis_options.yaml                 # 代码分析配置
└── build.yaml                            # build_runner 配置
```

---

## 数据模型层

### 基础模型设计

使用 `freezed` 生成不可变数据类，确保数据安全和 copyWith 功能。

#### 1. Yao (爻) 模型

```dart
// lib/models/yao.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'yao.freezed.dart';
part 'yao.g.dart';

/// 爻的数字枚举
enum YaoNumber {
  @JsonValue(6)
  laoYin(6, '老阴', true, YaoType.yin),

  @JsonValue(7)
  shaoYang(7, '少阳', false, YaoType.yang),

  @JsonValue(8)
  shaoYin(8, '少阴', false, YaoType.yin),

  @JsonValue(9)
  laoYang(9, '老阳', true, YaoType.yang);

  const YaoNumber(this.value, this.name, this.isMoving, this.type);

  final int value;
  final String name;
  final bool isMoving;
  final YaoType type;
}

/// 阴阳类型
enum YaoType {
  yin('阴'),
  yang('阳');

  const YaoType(this.name);
  final String name;
}

/// 五行
enum WuXing {
  jin('金'),
  mu('木'),
  shui('水'),
  huo('火'),
  tu('土');

  const WuXing(this.name);
  final String name;
}

/// 六亲
enum LiuQin {
  fuMu('父母'),
  xiongDi('兄弟'),
  ziSun('子孙'),
  qiCai('妻财'),
  guanGui('官鬼');

  const LiuQin(this.name);
  final String name;
}

/// 爻模型
@freezed
class Yao with _$Yao {
  const factory Yao({
    required int position,           // 爻位：1-6 (从下到上)
    required YaoNumber number,       // 爻数：6/7/8/9
    required String branch,          // 地支
    required String stem,            // 天干
    required LiuQin liuQin,         // 六亲
    required WuXing wuXing,         // 五行
    required bool isSeYao,          // 是否为世爻
    required bool isYingYao,        // 是否为应爻
    String? liuShen,                // 六神（青龙、朱雀等）
  }) = _Yao;

  factory Yao.fromJson(Map<String, dynamic> json) => _$YaoFromJson(json);

  const Yao._();

  /// 是否为动爻
  bool get isMoving => number.isMoving;

  /// 是否为阴爻
  bool get isYin => number.type == YaoType.yin;

  /// 是否为阳爻
  bool get isYang => number.type == YaoType.yang;

  /// 变爻后的爻
  Yao toChangedYao() {
    if (!isMoving) return this;

    final newNumber = isYin ? YaoNumber.shaoYang : YaoNumber.shaoYin;
    return copyWith(number: newNumber);
  }
}
```

#### 2. Gua (卦) 模型

```dart
// lib/models/gua.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'yao.dart';

part 'gua.freezed.dart';
part 'gua.g.dart';

/// 八宫
enum BaGong {
  qian('乾宫'),
  kun('坤宫'),
  zhen('震宫'),
  xun('巽宫'),
  kan('坎宫'),
  li('离宫'),
  gen('艮宫'),
  dui('兑宫');

  const BaGong(this.name);
  final String name;
}

/// 卦模型
@freezed
class Gua with _$Gua {
  const factory Gua({
    required String id,              // 卦象ID（64卦编号或名称）
    required String name,            // 卦名（如"乾为天"）
    required List<Yao> yaos,        // 六爻列表（从下到上）
    required BaGong baGong,         // 所属八宫
    required int seYaoPosition,     // 世爻位置 (1-6)
    required int yingYaoPosition,   // 应爻位置 (1-6)
  }) = _Gua;

  factory Gua.fromJson(Map<String, dynamic> json) => _$GuaFromJson(json);

  const Gua._();

  /// 是否有动爻
  bool get hasMovingYao => yaos.any((yao) => yao.isMoving);

  /// 获取所有动爻
  List<Yao> get movingYaos => yaos.where((yao) => yao.isMoving).toList();

  /// 获取世爻
  Yao get seYao => yaos[seYaoPosition - 1];

  /// 获取应爻
  Yao get yingYao => yaos[yingYaoPosition - 1];
}
```

#### 3. LunarInfo (农历信息) 模型

```dart
// lib/models/lunar_info.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'lunar_info.freezed.dart';
part 'lunar_info.g.dart';

/// 农历信息模型
@freezed
class LunarInfo with _$LunarInfo {
  const factory LunarInfo({
    required String yueJian,         // 月建（地支）
    required String riGan,           // 日干
    required String riZhi,           // 日支
    required String riGanZhi,        // 日干支组合
    required List<String> kongWang,  // 空亡（两个地支）
    required String yearGanZhi,      // 年干支
    required String monthGanZhi,     // 月干支
    String? solarTerm,               // 节气（可选）
  }) = _LunarInfo;

  factory LunarInfo.fromJson(Map<String, dynamic> json)
    => _$LunarInfoFromJson(json);

  const LunarInfo._();

  /// 检查某个地支是否空亡
  bool isKongWang(String branch) => kongWang.contains(branch);
}
```

#### 4. GuaRecord (占卜记录) 模型

```dart
// lib/models/gua_record.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'gua.dart';
import 'lunar_info.dart';

part 'gua_record.freezed.dart';
part 'gua_record.g.dart';

/// 起卦方式
enum CastMethod {
  coin('摇钱法'),
  time('时间起卦'),
  manual('手动输入');

  const CastMethod(this.name);
  final String name;
}

/// 占卜记录模型
@freezed
class GuaRecord with _$GuaRecord {
  const factory GuaRecord({
    required String id,                  // 记录ID（UUID）
    required DateTime castTime,          // 起卦时间
    required CastMethod castMethod,      // 起卦方式
    required Gua mainGua,               // 主卦
    Gua? changingGua,                   // 变卦（可选）
    required LunarInfo lunarInfo,       // 农历信息
    required List<String> liuShen,      // 六神列表（6个）

    // 以下字段存储在加密存储中，仅保存 ID 引用
    @Default('') String questionId,      // 问事主题的加密存储 key
    @Default('') String detailId,        // 详细说明的加密存储 key
    @Default('') String interpretationId, // 个人解读的加密存储 key
  }) = _GuaRecord;

  factory GuaRecord.fromJson(Map<String, dynamic> json)
    => _$GuaRecordFromJson(json);

  const GuaRecord._();

  /// 是否有变卦
  bool get hasChangingGua => changingGua != null;
}
```

---

## Domain 服务层

### 纯函数业务逻辑

所有 Domain 服务都是纯静态函数，无副作用，易于测试。

#### 1. LunarService - 农历计算

```dart
// lib/domain/services/lunar_service.dart
import 'package:lunar/lunar.dart';
import '../../models/lunar_info.dart';

/// 农历计算服务（封装 lunar 库）
class LunarService {
  LunarService._(); // 私有构造函数，防止实例化

  /// 根据公历时间获取农历信息
  static LunarInfo getLunarInfo(DateTime dateTime) {
    final solar = Solar.fromDate(dateTime);
    final lunar = solar.getLunar();

    // 获取日干支
    final riGanZhi = lunar.getDayInGanZhi();
    final riGan = lunar.getDayGan();
    final riZhi = lunar.getDayZhi();

    // 获取月建（月支）
    final yueJian = lunar.getMonthZhi();

    // 计算空亡
    final kongWang = _calculateKongWang(lunar);

    // 获取年月干支
    final yearGanZhi = lunar.getYearInGanZhi();
    final monthGanZhi = lunar.getMonthInGanZhi();

    // 获取节气
    final jieQi = solar.getJieQi();

    return LunarInfo(
      yueJian: yueJian,
      riGan: riGan,
      riZhi: riZhi,
      riGanZhi: riGanZhi,
      kongWang: kongWang,
      yearGanZhi: yearGanZhi,
      monthGanZhi: monthGanZhi,
      solarTerm: jieQi,
    );
  }

  /// 计算空亡（两个相邻地支）
  static List<String> _calculateKongWang(Lunar lunar) {
    // 使用 lunar 库的旬空计算
    final xunKong = lunar.getDayXunKong();
    return [xunKong]; // lunar 库返回格式需要适配
  }

  /// 获取日干（用于六神计算）
  static String getDayGan(DateTime dateTime) {
    final solar = Solar.fromDate(dateTime);
    final lunar = solar.getLunar();
    return lunar.getDayGan();
  }
}
```

#### 2. LiuShenService - 六神计算

```dart
// lib/domain/services/liushen_service.dart

/// 六神计算服务
class LiuShenService {
  LiuShenService._();

  /// 六神顺序
  static const List<String> _liushenOrder = [
    '青龙', '朱雀', '勾陈', '腾蛇', '白虎', '玄武'
  ];

  /// 天干对应六神起始索引
  static const Map<String, int> _ganToLiuShenStart = {
    '甲': 0, '乙': 0,  // 青龙
    '丙': 1, '丁': 1,  // 朱雀
    '戊': 3, '己': 3,  // 腾蛇（戊日起腾蛇）
    '庚': 4, '辛': 4,  // 白虎
    '壬': 5, '癸': 5,  // 玄武
  };

  /// 根据日干计算六神顺序（从初爻到六爻）
  static List<String> calculateLiuShen(String dayGan) {
    final startIndex = _ganToLiuShenStart[dayGan] ?? 0;

    return List.generate(6, (i) =>
      _liushenOrder[(startIndex + i) % 6]
    );
  }
}
```

#### 3. GuaCalculator - 卦象计算（核心算法）

```dart
// lib/domain/services/gua_calculator.dart
import '../../models/yao.dart';
import '../../models/gua.dart';
import '../../core/constants/yao_constants.dart';

/// 卦象计算核心算法
class GuaCalculator {
  GuaCalculator._();

  /// 根据六个爻数生成完整卦象
  static Gua calculateGua({
    required List<int> yaoNumbers,  // 6个爻数（从下到上）
    required List<String> liuShen,  // 六神列表
  }) {
    assert(yaoNumbers.length == 6, '必须有6个爻');
    assert(liuShen.length == 6, '必须有6个六神');

    // 1. 根据六个爻数识别卦象
    final guaId = _identifyGuaId(yaoNumbers);
    final guaName = YaoConstants.guaNames[guaId] ?? '未知卦';
    final baGong = _identifyBaGong(guaId);

    // 2. 确定世应位置
    final seYaoPos = _identifySeYaoPosition(guaId);
    final yingYaoPos = _getYingYaoPosition(seYaoPos);

    // 3. 计算每一爻的详细属性
    final yaos = <Yao>[];
    for (int i = 0; i < 6; i++) {
      final yao = _calculateYaoAttributes(
        position: i + 1,
        number: yaoNumbers[i],
        guaId: guaId,
        isSeYao: i + 1 == seYaoPos,
        isYingYao: i + 1 == yingYaoPos,
        liuShen: liuShen[i],
      );
      yaos.add(yao);
    }

    return Gua(
      id: guaId,
      name: guaName,
      yaos: yaos,
      baGong: baGong,
      seYaoPosition: seYaoPos,
      yingYaoPosition: yingYaoPos,
    );
  }

  /// 计算单个爻的属性
  static Yao _calculateYaoAttributes({
    required int position,
    required int number,
    required String guaId,
    required bool isSeYao,
    required bool isYingYao,
    required String liuShen,
  }) {
    // 根据卦象和位置获取纳甲地支
    final branch = _getNaJiaBranch(guaId, position);

    // 根据地支获取天干
    final stem = _getStemFromBranch(branch);

    // 根据地支获取五行
    final wuXing = _getWuXingFromBranch(branch);

    // 根据宫位和地支计算六亲
    final liuQin = _calculateLiuQin(guaId, branch);

    final yaoNumber = _parseYaoNumber(number);

    return Yao(
      position: position,
      number: yaoNumber,
      branch: branch,
      stem: stem,
      liuQin: liuQin,
      wuXing: wuXing,
      isSeYao: isSeYao,
      isYingYao: isYingYao,
      liuShen: liuShen,
    );
  }

  /// 根据爻数识别卦象ID
  static String _identifyGuaId(List<int> yaoNumbers) {
    // 将爻数转换为二进制（7/9为阳=1，6/8为阴=0）
    final binary = yaoNumbers.map((n) => (n == 7 || n == 9) ? '1' : '0').join();

    // 根据二进制查找卦象（需要预定义64卦映射表）
    return YaoConstants.binaryToGuaId[binary] ?? 'unknown';
  }

  /// 识别八宫归属
  static BaGong _identifyBaGong(String guaId) {
    // 根据卦象ID查找八宫（需要预定义映射表）
    final gongName = YaoConstants.guaToBaGong[guaId] ?? 'qian';
    return BaGong.values.firstWhere(
      (g) => g.name.startsWith(gongName),
      orElse: () => BaGong.qian,
    );
  }

  /// 识别世爻位置（基于八宫系统）
  static int _identifySeYaoPosition(String guaId) {
    // 根据八宫卦序确定世爻位置
    // 本宫卦（第1卦）：世在六爻
    // 一世卦（第2卦）：世在初爻
    // 二世卦（第3卦）：世在二爻
    // ... 详细规则需要查表
    return YaoConstants.guaToSeYaoPos[guaId] ?? 6;
  }

  /// 根据世爻位置计算应爻位置
  static int _getYingYaoPosition(int seYaoPos) {
    // 应爻与世爻的关系：世应相距三爻（间隔两爻）
    return (seYaoPos + 3) > 6 ? (seYaoPos - 3) : (seYaoPos + 3);
  }

  /// 获取纳甲地支
  static String _getNaJiaBranch(String guaId, int position) {
    // 根据卦象和爻位查找纳甲地支（需要预定义纳甲表）
    final key = '${guaId}_$position';
    return YaoConstants.naJiaTable[key] ?? '未知';
  }

  /// 根据地支推导天干
  static String _getStemFromBranch(String branch) {
    return YaoConstants.branchToStem[branch] ?? '';
  }

  /// 根据地支获取五行
  static WuXing _getWuXingFromBranch(String branch) {
    final wuXingName = YaoConstants.branchToWuXing[branch] ?? 'tu';
    return WuXing.values.firstWhere(
      (w) => w.name == wuXingName,
      orElse: () => WuXing.tu,
    );
  }

  /// 计算六亲
  static LiuQin _calculateLiuQin(String guaId, String branch) {
    // 六亲计算：根据宫位五行与地支五行的生克关系
    // 我生者为子孙，生我者为父母，克我者为官鬼，我克者为妻财，比和者为兄弟
    final gongWuXing = _getGongWuXing(guaId);
    final branchWuXing = YaoConstants.branchToWuXing[branch] ?? 'tu';

    final relation = _getWuXingRelation(gongWuXing, branchWuXing);

    return _relationToLiuQin(relation);
  }

  /// 获取宫位五行
  static String _getGongWuXing(String guaId) {
    final baGong = _identifyBaGong(guaId);
    return YaoConstants.baGongToWuXing[baGong.name] ?? 'jin';
  }

  /// 计算五行生克关系
  static String _getWuXingRelation(String gongWX, String branchWX) {
    if (gongWX == branchWX) return '比和';
    if (YaoConstants.wuXingSheng[gongWX] == branchWX) return '我生';
    if (YaoConstants.wuXingSheng[branchWX] == gongWX) return '生我';
    if (YaoConstants.wuXingKe[gongWX] == branchWX) return '我克';
    if (YaoConstants.wuXingKe[branchWX] == gongWX) return '克我';
    return '未知';
  }

  /// 关系转六亲
  static LiuQin _relationToLiuQin(String relation) {
    switch (relation) {
      case '我生': return LiuQin.ziSun;
      case '生我': return LiuQin.fuMu;
      case '克我': return LiuQin.guanGui;
      case '我克': return LiuQin.qiCai;
      case '比和': return LiuQin.xiongDi;
      default: return LiuQin.xiongDi;
    }
  }

  /// 解析爻数枚举
  static YaoNumber _parseYaoNumber(int number) {
    return YaoNumber.values.firstWhere(
      (yn) => yn.value == number,
      orElse: () => YaoNumber.shaoYang,
    );
  }
}
```

#### 4. QiGuaService - 起卦方法

```dart
// lib/domain/services/qigua_service.dart
import 'dart:math';

/// 硬币面
enum CoinFace {
  front('正面'),  // 代表阳
  back('反面');   // 代表阴

  const CoinFace(this.name);
  final String name;
}

/// 起卦服务
class QiGuaService {
  QiGuaService._();

  static final _random = Random();

  /// 摇钱法：模拟三枚硬币投掷，返回一个爻数
  /// 规则：3个正面=老阳(9)，3个反面=老阴(6)，2正1反=少阳(7)，2反1正=少阴(8)
  static int coinCastOnce() {
    final coin1 = _random.nextBool();
    final coin2 = _random.nextBool();
    final coin3 = _random.nextBool();

    final frontCount = [coin1, coin2, coin3].where((c) => c).length;

    switch (frontCount) {
      case 3: return 9;  // 老阳
      case 2: return 7;  // 少阳
      case 1: return 8;  // 少阴
      case 0: return 6;  // 老阴
      default: return 7;
    }
  }

  /// 完整摇钱法：返回6个爻数（从下到上）
  static List<int> coinCast() {
    return List.generate(6, (_) => coinCastOnce());
  }

  /// 时间起卦法：根据时间计算卦象
  /// 算法：年月日时之和除以8取余得上卦，年月日时之和加时除以8取余得下卦
  /// 年月日时之和除以6取余得动爻
  static List<int> timeCast(DateTime time) {
    final year = time.year % 12 + 1;  // 转为地支数
    final month = time.month;
    final day = time.day;
    final hour = _getShiChen(time.hour);  // 转为时辰数(1-12)

    final sum = year + month + day + hour;

    // 使用 ((x - 1) % n) + 1 确保结果在 1-n 范围内
    final upperGua = ((sum - 1) % 8) + 1;
    final lowerGua = ((sum + hour - 1) % 8) + 1;
    final movingYao = ((sum - 1) % 6) + 1;

    // 根据上下卦组合生成六爻数字
    return _generateYaoNumbersFromGua(upperGua, lowerGua, movingYao);
  }

  /// 手动输入法：根据用户输入的硬币正反面生成爻数
  static int manualCastOnce(List<CoinFace> faces) {
    assert(faces.length == 3, '必须输入3枚硬币');

    final frontCount = faces.where((f) => f == CoinFace.front).length;

    switch (frontCount) {
      case 3: return 9;
      case 2: return 7;
      case 1: return 8;
      case 0: return 6;
      default: return 7;
    }
  }

  /// 完整手动输入：用户输入6次，每次3枚硬币
  static List<int> manualCast(List<List<CoinFace>> allFaces) {
    assert(allFaces.length == 6, '必须输入6次');
    return allFaces.map((faces) => manualCastOnce(faces)).toList();
  }

  /// 获取时辰数（1-12）
  static int _getShiChen(int hour) {
    // 23-1点=子时(1), 1-3点=丑时(2), ..., 21-23点=亥时(12)
    if (hour == 23 || hour == 0) return 1;
    return ((hour + 1) ~/ 2) + 1;
  }

  /// 根据上下卦和动爻生成爻数
  static List<int> _generateYaoNumbersFromGua(int upper, int lower, int moving) {
    // 将八卦数转换为三个爻（示例简化版，实际需要查八卦表）
    final upperYaos = _guaNumberToYaos(upper);
    final lowerYaos = _guaNumberToYaos(lower);

    final allYaos = [...lowerYaos, ...upperYaos];

    // 设置动爻（moving=0表示第6爻，1表示第1爻，以此类推）
    final movingPos = moving == 0 ? 5 : moving - 1;
    allYaos[movingPos] = allYaos[movingPos] == 7 ? 9 : 6;  // 阳变老阳，阴变老阴

    return allYaos;
  }

  /// 八卦数转三个爻（乾1=111, 兑2=110, 离3=101, 震4=001, 巽5=011, 坎6=010, 艮7=100, 坤8=000）
  static List<int> _guaNumberToYaos(int guaNum) {
    const Map<int, List<int>> guaToYaos = {
      1: [7, 7, 7],  // 乾 ☰
      2: [8, 7, 7],  // 兑 ☱
      3: [7, 8, 7],  // 离 ☲
      4: [8, 8, 7],  // 震 ☳
      5: [7, 7, 8],  // 巽 ☴
      6: [8, 7, 8],  // 坎 ☵
      7: [7, 8, 8],  // 艮 ☶
      8: [8, 8, 8],  // 坤 ☷
    };

    return guaToYaos[guaNum] ?? [7, 7, 7];
  }
}
```

---

## Repository 层

### Repository 接口定义

```dart
// lib/domain/repositories/gua_repository.dart
import '../../models/gua_record.dart';

/// 卦象记录 Repository 接口
abstract class GuaRepository {
  /// 保存占卜记录
  Future<void> saveRecord(GuaRecord record);

  /// 更新占卜记录
  Future<void> updateRecord(GuaRecord record);

  /// 删除占卜记录
  Future<void> deleteRecord(String id);

  /// 根据ID获取记录
  Future<GuaRecord?> getRecordById(String id);

  /// 获取所有记录（按时间倒序）
  Future<List<GuaRecord>> getAllRecords({
    int limit = 100,
    int offset = 0,
  });

  /// 搜索记录（按问事内容）
  ///
  /// [keyword] 搜索关键词
  /// [limit] 每页记录数（默认100）
  /// [offset] 偏移量（默认0）
  Future<List<GuaRecord>> searchRecords(
    String keyword, {
    int limit = 100,
    int offset = 0,
  });

  /// 保存加密字段（问事、解读等）
  Future<void> saveEncryptedField(String key, String value);

  /// 获取加密字段
  Future<String?> getEncryptedField(String key);

  /// 删除加密字段
  Future<void> deleteEncryptedField(String key);
}
```

### Repository 实现

```dart
// lib/data/repositories/gua_repository_impl.dart
import '../../domain/repositories/gua_repository.dart';
import '../../models/gua_record.dart';
import '../database/app_database.dart';
import '../secure/secure_storage.dart';

/// GuaRepository 的实现
class GuaRepositoryImpl implements GuaRepository {
  final AppDatabase _database;
  final SecureStorage _secureStorage;

  GuaRepositoryImpl({
    required AppDatabase database,
    required SecureStorage secureStorage,
  })  : _database = database,
        _secureStorage = secureStorage;

  @Override
  Future<void> saveRecord(GuaRecord record) async {
    await _database.guaDao.insertRecord(record);
  }

  @Override
  Future<void> updateRecord(GuaRecord record) async {
    await _database.guaDao.updateRecord(record);
  }

  @Override
  Future<void> deleteRecord(String id) async {
    // 先获取记录，提取加密字段的 key
    final record = await getRecordById(id);

    if (record == null) {
      // 记录不存在，可能已被删除
      return;
    }

    // 然后删除数据库记录
    await _database.guaDao.deleteRecord(id);

    // 最后清理加密字段
    final keysToDelete = [
      if (record.questionId.isNotEmpty) record.questionId,
      if (record.detailId.isNotEmpty) record.detailId,
      if (record.interpretationId.isNotEmpty) record.interpretationId,
    ];

    for (final key in keysToDelete) {
      try {
        await deleteEncryptedField(key);
      } catch (e) {
        // 记录错误但继续清理其他 key
        print('Failed to delete encrypted field $key: $e');
      }
    }
  }

  @Override
  Future<GuaRecord?> getRecordById(String id) async {
    return await _database.guaDao.getRecordById(id);
  }

  @Override
  Future<List<GuaRecord>> getAllRecords({
    int limit = 100,
    int offset = 0,
  }) async {
    return await _database.guaDao.getAllRecords(limit: limit, offset: offset);
  }

  @Override
  Future<List<GuaRecord>> searchRecords(
    String keyword, {
    int limit = 100,
    int offset = 0,
  }) async {
    // 注意：加密字段无法直接在数据库中搜索
    // 需要加载记录，解密后在内存中搜索
    // ✅ 支持分页，不限制在1000条
    final allRecords = await getAllRecords(limit: limit, offset: offset);

    if (keyword.trim().isEmpty) {
      return allRecords;
    }

    // ✅ 并行解密所有记录的问题字段
    final results = <GuaRecord>[];

    await Future.wait(
      allRecords.map((record) async {
        // 跳过没有问题的记录
        if (record.questionId.isEmpty) {
          return;
        }

        final question = await getEncryptedField(record.questionId);
        if (question != null && question.contains(keyword)) {
          results.add(record);
        }
      }),
    );

    return results;
  }

  @Override
  Future<void> saveEncryptedField(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  @Override
  Future<String?> getEncryptedField(String key) async {
    return await _secureStorage.read(key: key);
  }

  @Override
  Future<void> deleteEncryptedField(String key) async {
    await _secureStorage.delete(key: key);
  }
}
```

---

## ViewModel 层

### ViewModel 设计原则

1. 继承 `ChangeNotifier`，通过 `notifyListeners()` 通知 UI 更新
2. 只包含业务逻辑和 UI 状态，不包含 UI 代码
3. 通过构造函数注入 Repository 依赖
4. 使用私有方法实现内部逻辑，公开方法供 UI 调用
5. 处理异步操作和错误

### CastViewModel - 起卦页面 ViewModel

```dart
// lib/viewmodels/cast_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/gua.dart';
import '../models/gua_record.dart';
import '../models/lunar_info.dart';
import '../domain/services/qigua_service.dart';
import '../domain/services/gua_calculator.dart';
import '../domain/services/lunar_service.dart';
import '../domain/services/liushen_service.dart';
import '../domain/repositories/gua_repository.dart';

/// 起卦状态
enum CastState {
  idle,           // 空闲
  casting,        // 起卦中
  calculating,    // 计算中
  success,        // 成功
  error,          // 错误
}

/// 起卦页面 ViewModel
class CastViewModel extends ChangeNotifier {
  final GuaRepository _repository;

  CastViewModel({required GuaRepository repository})
      : _repository = repository;

  // 状态
  CastState _state = CastState.idle;
  CastState get state => _state;

  CastMethod _selectedMethod = CastMethod.coin;
  CastMethod get selectedMethod => _selectedMethod;

  // 当前起卦过程中的爻数列表（6个）
  List<int> _currentYaoNumbers = [];
  List<int> get currentYaoNumbers => List.unmodifiable(_currentYaoNumbers);

  // 计算结果
  GuaRecord? _result;
  GuaRecord? get result => _result;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 硬币投掷动画状态（用于UI）
  bool _isAnimating = false;
  bool get isAnimating => _isAnimating;

  // 存储当前起卦时间
  DateTime? _castTime;

  /// 选择起卦方式
  void selectCastMethod(CastMethod method) {
    _selectedMethod = method;
    _reset();
    notifyListeners();
  }

  /// 摇钱法：投掷一次
  Future<void> castCoinOnce() async {
    if (_currentYaoNumbers.length >= 6) return;

    _setState(CastState.casting);
    _isAnimating = true;
    notifyListeners();

    // 第一次投掷时记录时间
    _castTime ??= DateTime.now();

    // 模拟动画延迟
    await Future.delayed(const Duration(milliseconds: 800));

    final yaoNumber = QiGuaService.coinCastOnce();
    _currentYaoNumbers.add(yaoNumber);

    _isAnimating = false;

    if (_currentYaoNumbers.length == 6) {
      await _calculateGua(_castTime!);
    } else {
      _setState(CastState.idle);
    }
  }

  /// 摇钱法：一次性投掷6次
  Future<void> castCoinAll() async {
    _setState(CastState.casting);

    _castTime = DateTime.now();
    final yaoNumbers = QiGuaService.coinCast();
    _currentYaoNumbers = yaoNumbers;

    await _calculateGua(_castTime!);
  }

  /// 时间起卦
  Future<void> castByTime([DateTime? customTime]) async {
    _setState(CastState.casting);

    _castTime = customTime ?? DateTime.now();
    final yaoNumbers = QiGuaService.timeCast(_castTime!);
    _currentYaoNumbers = yaoNumbers;

    await _calculateGua(_castTime!);
  }

  /// 手动输入：硬币正反面（符合 PRD FR1 要求）
  void inputCoins(List<CoinFace> coins) {
    assert(coins.length == 3, '每次必须输入3枚硬币');

    // 第一次输入时记录时间
    _castTime ??= DateTime.now();

    // 调用 Domain Service 计算爻数
    final yaoNumber = QiGuaService.manualCastOnce(coins);
    _currentYaoNumbers.add(yaoNumber);

    if (_currentYaoNumbers.length == 6) {
      _calculateGua(_castTime!);
    } else {
      notifyListeners();
    }
  }

  /// 手动输入：直接输入爻数（高级模式，用于专业用户）
  void manualInputYao(int position, int yaoNumber) {
    assert(position >= 1 && position <= 6);
    assert([6, 7, 8, 9].contains(yaoNumber));

    // 第一次输入时记录时间
    _castTime ??= DateTime.now();

    if (_currentYaoNumbers.length < position) {
      _currentYaoNumbers.add(yaoNumber);
    } else {
      _currentYaoNumbers[position - 1] = yaoNumber;
    }

    if (_currentYaoNumbers.length == 6) {
      _calculateGua(_castTime!);
    } else {
      notifyListeners();
    }
  }

  /// 计算卦象 - 现在接受时间参数
  Future<void> _calculateGua(DateTime castTime) async {
    _setState(CastState.calculating);

    try {
      // 1. 获取农历信息 - 使用传入的起卦时间，而非 now()
      final lunarInfo = LunarService.getLunarInfo(castTime);

      // 2. 计算六神
      final liuShen = LiuShenService.calculateLiuShen(lunarInfo.riGan);

      // 3. 计算主卦
      final mainGua = GuaCalculator.calculateGua(
        yaoNumbers: _currentYaoNumbers,
        liuShen: liuShen,
      );

      // 4. 正确计算变卦（重新计算整个卦象，而非简单 copyWith）
      Gua? changingGua;
      if (mainGua.hasMovingYao) {
        // 生成变化后的爻数
        final changedYaoNumbers = mainGua.yaos.map((yao) {
          if (yao.isMoving) {
            return yao.isYin ? 7 : 8;  // 老阴→少阳，老阳→少阴
          } else {
            return yao.number.value;   // 静爻不变
          }
        }).toList();

        // 重新计算变卦
        changingGua = GuaCalculator.calculateGua(
          yaoNumbers: changedYaoNumbers,
          liuShen: liuShen,  // 六神保持一致
        );
      }

      // 5. 创建占卜记录
      final record = GuaRecord(
        id: const Uuid().v4(),
        castTime: castTime,  // 使用起卦时间
        castMethod: _selectedMethod,
        mainGua: mainGua,
        changingGua: changingGua,  // 正确的变卦
        lunarInfo: lunarInfo,
        liuShen: liuShen,
      );

      _result = record;
      _setState(CastState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(CastState.error);
    }
  }

  /// 保存占卜记录
  Future<void> saveRecord({
    String? question,
    String? detail,
    String? interpretation,
  }) async {
    if (_result == null) return;

    try {
      // 保存加密字段
      String questionId = '';
      String detailId = '';
      String interpretationId = '';

      if (question != null && question.isNotEmpty) {
        questionId = 'question_${_result!.id}';
        await _repository.saveEncryptedField(questionId, question);
      }

      if (detail != null && detail.isNotEmpty) {
        detailId = 'detail_${_result!.id}';
        await _repository.saveEncryptedField(detailId, detail);
      }

      if (interpretation != null && interpretation.isNotEmpty) {
        interpretationId = 'interpretation_${_result!.id}';
        await _repository.saveEncryptedField(interpretationId, interpretation);
      }

      // 更新记录
      final updatedRecord = _result!.copyWith(
        questionId: questionId,
        detailId: detailId,
        interpretationId: interpretationId,
      );

      // 保存到数据库
      await _repository.saveRecord(updatedRecord);

      _result = updatedRecord;
      notifyListeners();
    } catch (e) {
      _errorMessage = '保存失败: $e';
      _setState(CastState.error);
    }
  }

  /// 重置
  void _reset() {
    _currentYaoNumbers.clear();
    _result = null;
    _errorMessage = null;
    _castTime = null;  // 重置时间
    _setState(CastState.idle);
  }

  /// 设置状态
  void _setState(CastState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
```

### HistoryViewModel - 历史记录 ViewModel

```dart
// lib/viewmodels/history_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/gua_record.dart';
import '../domain/repositories/gua_repository.dart';

/// 历史记录状态
enum HistoryState {
  loading,
  loaded,
  error,
  empty,
}

/// 历史记录 ViewModel
class HistoryViewModel extends ChangeNotifier {
  final GuaRepository _repository;

  HistoryViewModel({required GuaRepository repository})
      : _repository = repository {
    loadRecords();
  }

  HistoryState _state = HistoryState.loading;
  HistoryState get state => _state;

  List<GuaRecord> _records = [];
  List<GuaRecord> get records => List.unmodifiable(_records);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 分页参数
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // 搜索状态
  bool _isSearchMode = false;
  bool get isSearchMode => _isSearchMode;
  String _currentSearchKeyword = '';
  String get currentSearchKeyword => _currentSearchKeyword;

  /// 加载记录（首次加载）
  Future<void> loadRecords() async {
    _setState(HistoryState.loading);

    try {
      // 退出搜索模式
      _isSearchMode = false;
      _currentSearchKeyword = '';
      _currentPage = 0;
      _records = await _repository.getAllRecords(
        limit: _pageSize,
        offset: 0,
      );

      _hasMore = _records.length == _pageSize;

      if (_records.isEmpty) {
        _setState(HistoryState.empty);
      } else {
        _setState(HistoryState.loaded);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setState(HistoryState.error);
    }
  }

  /// 加载更多记录（分页）
  Future<void> loadMore() async {
    if (!_hasMore || _state == HistoryState.loading) return;

    // 搜索模式下禁用分页加载，因为搜索结果已经是完整的
    if (_isSearchMode) return;

    try {
      _currentPage++;
      final moreRecords = await _repository.getAllRecords(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      _records.addAll(moreRecords);
      _hasMore = moreRecords.length == _pageSize;

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 刷新记录
  Future<void> refresh() async {
    await loadRecords();
  }

  /// 删除记录
  Future<void> deleteRecord(String id) async {
    try {
      await _repository.deleteRecord(id);
      _records.removeWhere((r) => r.id == id);

      if (_records.isEmpty) {
        _setState(HistoryState.empty);
      } else {
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 搜索记录
  Future<void> search(String keyword) async {
    if (keyword.trim().isEmpty) {
      await loadRecords();
      return;
    }

    _setState(HistoryState.loading);

    try {
      // 进入搜索模式
      _isSearchMode = true;
      _currentSearchKeyword = keyword;
      // 重置分页状态（搜索结果是一次性返回的完整列表）
      _currentPage = 0;
      _hasMore = false;

      // ✅ 搜索所有记录（使用足够大的limit）
      _records = await _repository.searchRecords(keyword, limit: 9999);

      if (_records.isEmpty) {
        _setState(HistoryState.empty);
      } else {
        _setState(HistoryState.loaded);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setState(HistoryState.error);
    }
  }

  /// 获取加密字段
  Future<String?> getQuestion(String questionId) async {
    if (questionId.isEmpty) return null;
    return await _repository.getEncryptedField(questionId);
  }

  Future<String?> getDetail(String detailId) async {
    if (detailId.isEmpty) return null;
    return await _repository.getEncryptedField(detailId);
  }

  Future<String?> getInterpretation(String interpretationId) async {
    if (interpretationId.isEmpty) return null;
    return await _repository.getEncryptedField(interpretationId);
  }

  void _setState(HistoryState newState) {
    _state = newState;
    notifyListeners();
  }
}
```

### GuaResultViewModel - 卦象结果 ViewModel

```dart
// lib/viewmodels/gua_result_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/gua_record.dart';
import '../domain/repositories/gua_repository.dart';

/// 卦象结果页面 ViewModel
class GuaResultViewModel extends ChangeNotifier {
  final GuaRepository _repository;

  GuaResultViewModel({required GuaRepository repository})
      : _repository = repository;

  GuaRecord? _record;
  GuaRecord? get record => _record;

  String? _question;
  String? get question => _question;

  String? _detail;
  String? get detail => _detail;

  String? _interpretation;
  String? get interpretation => _interpretation;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 加载记录
  Future<void> loadRecord(String recordId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _record = await _repository.getRecordById(recordId);

      if (_record != null) {
        // 加载加密字段
        _question = await _repository.getEncryptedField(_record!.questionId);
        _detail = await _repository.getEncryptedField(_record!.detailId);
        _interpretation = await _repository.getEncryptedField(
          _record!.interpretationId,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 设置记录（从起卦页面传入）
  void setRecord(GuaRecord record) {
    _record = record;
    notifyListeners();
  }

  /// 更新问事
  Future<void> updateQuestion(String newQuestion) async {
    if (_record == null) return;

    final questionId = 'question_${_record!.id}';
    await _repository.saveEncryptedField(questionId, newQuestion);

    final updatedRecord = _record!.copyWith(questionId: questionId);
    await _repository.updateRecord(updatedRecord);

    _record = updatedRecord;
    _question = newQuestion;
    notifyListeners();
  }

  /// 更新解读
  Future<void> updateInterpretation(String newInterpretation) async {
    if (_record == null) return;

    final interpretationId = 'interpretation_${_record!.id}';
    await _repository.saveEncryptedField(interpretationId, newInterpretation);

    final updatedRecord = _record!.copyWith(
      interpretationId: interpretationId,
    );
    await _repository.updateRecord(updatedRecord);

    _record = updatedRecord;
    _interpretation = newInterpretation;
    notifyListeners();
  }
}
```

---

## Presentation 层

### UI 设计原则

1. Widgets 应该是"哑"的，只负责渲染
2. 使用 `Consumer` 或 `Selector` 订阅 ViewModel
3. 使用 `const` 构造函数优化性能
4. 复杂组件拆分为小组件
5. 统一的错误处理和加载状态显示

### 核心 Widget 示例

#### YaoDisplay - 爻显示组件

```dart
// lib/presentation/widgets/yao_display.dart
import 'package:flutter/material.dart';
import '../../models/yao.dart';

/// 爻显示组件
class YaoDisplay extends StatelessWidget {
  final Yao yao;
  final bool showDetails;

  const YaoDisplay({
    super.key,
    required this.yao,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 爻位
            _buildPosition(),
            const SizedBox(width: 16),

            // 阴阳符号
            _buildYaoSymbol(),
            const SizedBox(width: 16),

            // 详细信息
            if (showDetails) Expanded(child: _buildDetails()),
          ],
        ),
      ),
    );
  }

  Widget _buildPosition() {
    String positionName;
    switch (yao.position) {
      case 1: positionName = '初爻'; break;
      case 2: positionName = '二爻'; break;
      case 3: positionName = '三爻'; break;
      case 4: positionName = '四爻'; break;
      case 5: positionName = '五爻'; break;
      case 6: positionName = '上爻'; break;
      default: positionName = '${yao.position}爻';
    }

    return Container(
      width: 48,
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            positionName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (yao.isSeYao)
            const Text('世', style: TextStyle(color: Colors.red)),
          if (yao.isYingYao)
            const Text('应', style: TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildYaoSymbol() {
    return Container(
      width: 80,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomPaint(
        painter: _YaoSymbolPainter(
          isYang: yao.isYang,
          isMoving: yao.isMoving,
        ),
      ),
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${yao.stem}${yao.branch} ${yao.wuXing.name}'),
        Text('${yao.liuQin.name}'),
        if (yao.liuShen != null) Text(yao.liuShen!),
        if (yao.isMoving)
          const Text(
            '动',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}

/// 爻符号绘制
class _YaoSymbolPainter extends CustomPainter {
  final bool isYang;
  final bool isMoving;

  _YaoSymbolPainter({required this.isYang, required this.isMoving});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isMoving ? Colors.orange : Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;

    if (isYang) {
      // 阳爻：一条长线
      canvas.drawLine(
        Offset(8, y),
        Offset(size.width - 8, y),
        paint,
      );
    } else {
      // 阴爻：两条短线
      final gap = size.width * 0.15;
      canvas.drawLine(
        Offset(8, y),
        Offset(size.width / 2 - gap / 2, y),
        paint,
      );
      canvas.drawLine(
        Offset(size.width / 2 + gap / 2, y),
        Offset(size.width - 8, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_YaoSymbolPainter oldDelegate) {
    return oldDelegate.isYang != isYang || oldDelegate.isMoving != isMoving;
  }
}
```

#### GuaCard - 卦象卡片组件

```dart
// lib/presentation/widgets/gua_card.dart
import 'package:flutter/material.dart';
import '../../models/gua.dart';
import 'yao_display.dart';

/// 卦象卡片组件
class GuaCard extends StatelessWidget {
  final Gua gua;
  final String? title;
  final bool showDetails;

  const GuaCard({
    super.key,
    required this.gua,
    this.title,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            if (title != null)
              Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium,
              ),

            // 卦名和八宫
            Text(
              gua.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              gua.baGong.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const Divider(),

            // 六爻（从上到下显示，所以反转）
            ...gua.yaos.reversed.map((yao) =>
              YaoDisplay(yao: yao, showDetails: showDetails),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### CoinCastScreen - 摇钱法起卦页面

```dart
// lib/presentation/screens/cast/coin_cast_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/cast_viewmodel.dart';
import 'package:go_router/go_router.dart';

class CoinCastScreen extends StatelessWidget {
  const CoinCastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('摇钱法起卦'),
      ),
      body: Consumer<CastViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              // 进度指示
              _buildProgress(viewModel),

              const SizedBox(height: 32),

              // 硬币动画区域
              Expanded(
                child: Center(
                  child: _buildCoinArea(context, viewModel),
                ),
              ),

              // 操作按钮
              _buildActions(context, viewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgress(CastViewModel viewModel) {
    final count = viewModel.currentYaoNumbers.length;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '第 ${count + 1} 爻',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: count / 6,
          ),
          const SizedBox(height: 8),
          Text('已投掷 $count 次，还需 ${6 - count} 次'),
        ],
      ),
    );
  }

  Widget _buildCoinArea(BuildContext context, CastViewModel viewModel) {
    if (viewModel.isAnimating) {
      return const CircularProgressIndicator();
    }

    return ElevatedButton(
      onPressed: viewModel.state == CastState.casting
          ? null
          : () => viewModel.castCoinOnce(),
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(64),
      ),
      child: const Icon(Icons.monetization_on, size: 64),
    );
  }

  Widget _buildActions(BuildContext context, CastViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              viewModel.selectCastMethod(CastMethod.coin);
            },
            child: const Text('重新开始'),
          ),
          ElevatedButton(
            onPressed: viewModel.currentYaoNumbers.length == 6
                ? () {
                    // 导航到结果页面
                    context.push('/result');
                  }
                : null,
            child: const Text('查看结果'),
          ),
        ],
      ),
    );
  }
}
```

---

## 数据持久化

### Drift 数据库设计

#### 表定义

```dart
// lib/data/database/tables.dart
import 'package:drift/drift.dart';

/// 占卜记录表
@DataClassName('GuaRecordData')
class GuaRecords extends Table {
  // 主键
  TextColumn get id => text()();

  // 基本信息
  DateTimeColumn get castTime => dateTime()();
  IntColumn get castMethod => integer()();  // CastMethod 枚举值

  // 卦象数据（JSON 存储）
  TextColumn get mainGuaJson => text()();
  TextColumn get changingGuaJson => text().nullable()();

  // 农历信息（JSON 存储）
  TextColumn get lunarInfoJson => text()();

  // 六神（JSON 数组）
  TextColumn get liushenJson => text()();

  // 加密字段的 key（实际内容存储在 SecureStorage）
  TextColumn get questionId => text().withDefault(const Constant(''))();
  TextColumn get detailId => text().withDefault(const Constant(''))();
  TextColumn get interpretationId => text().withDefault(const Constant(''))();

  // 创建和更新时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 设置表（用于存储应用设置）
@DataClassName('SettingData')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
```

#### 数据库定义

```dart
// lib/data/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'tables.dart';
import 'daos/gua_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [GuaRecords, Settings],
  daos: [GuaDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // 未来版本升级逻辑
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wanxiang_paipan.db'));
    return NativeDatabase(file);
  });
}
```

#### DAO 实现

```dart
// lib/data/database/daos/gua_dao.dart
import 'package:drift/drift.dart';
import 'dart:convert';
import '../app_database.dart';
import '../tables.dart';
import '../../../models/gua_record.dart';
import '../../../models/gua.dart';
import '../../../models/lunar_info.dart';

part 'gua_dao.g.dart';

@DriftAccessor(tables: [GuaRecords])
class GuaDao extends DatabaseAccessor<AppDatabase> with _$GuaDaoMixin {
  GuaDao(AppDatabase db) : super(db);

  /// 插入记录
  Future<void> insertRecord(GuaRecord record) async {
    await into(guaRecords).insert(
      GuaRecordsCompanion.insert(
        id: record.id,
        castTime: record.castTime,
        castMethod: record.castMethod.index,
        mainGuaJson: jsonEncode(record.mainGua.toJson()),
        changingGuaJson: record.changingGua != null
            ? Value(jsonEncode(record.changingGua!.toJson()))
            : const Value(null),
        lunarInfoJson: jsonEncode(record.lunarInfo.toJson()),
        liushenJson: jsonEncode(record.liuShen),
        questionId: Value(record.questionId),
        detailId: Value(record.detailId),
        interpretationId: Value(record.interpretationId),
      ),
    );
  }

  /// 更新记录
  Future<void> updateRecord(GuaRecord record) async {
    await (update(guaRecords)..where((t) => t.id.equals(record.id))).write(
      GuaRecordsCompanion(
        mainGuaJson: Value(jsonEncode(record.mainGua.toJson())),
        changingGuaJson: record.changingGua != null
            ? Value(jsonEncode(record.changingGua!.toJson()))
            : const Value(null),
        lunarInfoJson: Value(jsonEncode(record.lunarInfo.toJson())),
        liushenJson: Value(jsonEncode(record.liuShen)),
        questionId: Value(record.questionId),
        detailId: Value(record.detailId),
        interpretationId: Value(record.interpretationId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 删除记录
  Future<void> deleteRecord(String id) async {
    await (delete(guaRecords)..where((t) => t.id.equals(id))).go();
  }

  /// 根据 ID 获取记录
  Future<GuaRecord?> getRecordById(String id) async {
    final data = await (select(guaRecords)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    return data != null ? _dataToModel(data) : null;
  }

  /// 获取所有记录（分页）
  Future<List<GuaRecord>> getAllRecords({
    int limit = 100,
    int offset = 0,
  }) async {
    final query = select(guaRecords)
      ..orderBy([
        (t) => OrderingTerm(expression: t.castTime, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);

    final results = await query.get();
    return results.map(_dataToModel).toList();
  }

  /// 将数据库记录转换为模型
  GuaRecord _dataToModel(GuaRecordData data) {
    return GuaRecord(
      id: data.id,
      castTime: data.castTime,
      castMethod: CastMethod.values[data.castMethod],
      mainGua: Gua.fromJson(jsonDecode(data.mainGuaJson)),
      changingGua: data.changingGuaJson != null
          ? Gua.fromJson(jsonDecode(data.changingGuaJson!))
          : null,
      lunarInfo: LunarInfo.fromJson(jsonDecode(data.lunarInfoJson)),
      liuShen: List<String>.from(jsonDecode(data.liushenJson)),
      questionId: data.questionId,
      detailId: data.detailId,
      interpretationId: data.interpretationId,
    );
  }
}
```

#### SecureStorage 封装

```dart
// lib/data/secure/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 加密存储服务（封装 flutter_secure_storage）
class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  /// 写入
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// 读取
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  /// 删除
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  /// 清空所有
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// 是否包含
  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(key: key);
  }
}
```

---

---

## 路由与导航

### go_router 配置

应用统一使用 `go_router` 进行导航，保证声明式路由、深链接和类型安全的参数传递。所有页面均通过集中路由表注册：

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/cast/coin_cast_screen.dart';
import '../../presentation/screens/cast/time_cast_screen.dart';
import '../../presentation/screens/cast/manual_cast_screen.dart';
import '../../presentation/screens/result/result_screen.dart';
import '../../presentation/screens/history/history_list_screen.dart';
import '../../presentation/screens/history/history_detail_screen.dart';
import '../../models/gua.dart';
import '../../models/lunar_info.dart';
import '../../models/gua_record.dart';

class ResultScreenArgs {
  const ResultScreenArgs({
    required this.mainGua,
    required this.changingGua,
    required this.lunarInfo,
    required this.liuShen,
    required this.castMethod,
  });

  final Gua mainGua;
  final Gua? changingGua;
  final LunarInfo lunarInfo;
  final List<String> liuShen;
  final CastMethod castMethod;
}

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', name: 'home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/cast/coin', name: 'coin-cast', builder: (_, __) => const CoinCastScreen()),
    GoRoute(path: '/cast/time', name: 'time-cast', builder: (_, __) => const TimeCastScreen()),
    GoRoute(path: '/cast/manual', name: 'manual-cast', builder: (_, __) => const ManualCastScreen()),
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (_, state) {
        final args = state.extra! as ResultScreenArgs;
        return ResultScreen(
          mainGua: args.mainGua,
          changingGua: args.changingGua,
          lunarInfo: args.lunarInfo,
          liuShen: args.liuShen,
          castMethod: args.castMethod,
        );
      },
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (_, __) => const HistoryListScreen(),
      routes: [
        GoRoute(
          path: 'detail/:id',
          name: 'history-detail',
          builder: (_, state) => HistoryDetailScreen(recordId: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    appBar: AppBar(title: const Text('错误')),
    body: Center(child: Text('页面未找到: ${state.uri}')),
  ),
  debugLogDiagnostics: true,
);
```

### 导航约定

- 编写 `GoRouterExtensions` 简化导航调用，例如 `context.goToResult(recordId: id)`、`context.goToHistoryDetail(id)`。
- 起卦流程固定为 `Home → Cast → Result → History/Detail`，所有模块只依赖扩展方法，不直接硬编码路由字符串，便于后续支持其它术数页面。

---

## 依赖注入

### Provider 配置

`main.dart` 使用 `MultiProvider` 将数据库、加密存储、Repository 与 ViewModel 注入整个 Widget 树：

```dart
return MultiProvider(
  providers: [
    Provider<AppDatabase>(create: (_) => AppDatabase(), dispose: (_, db) => db.close()),
    Provider<SecureStorage>(create: (_) => SecureStorage()),
    ProxyProvider2<AppDatabase, SecureStorage, GuaRepository>(
      update: (_, db, storage, previous) => previous ?? GuaRepositoryImpl(db, storage),
    ),
    ChangeNotifierProxyProvider<GuaRepository, HistoryViewModel>(
      create: (context) => HistoryViewModel(context.read<GuaRepository>()),
      update: (_, repository, previous) => previous ?? HistoryViewModel(repository),
    ),
    ChangeNotifierProxyProvider<GuaRepository, CastViewModel>(
      create: (context) => CastViewModel(context.read<GuaRepository>()),
      update: (_, repository, previous) => previous ?? CastViewModel(repository),
    ),
  ],
  child: MaterialApp(
    title: '万象排盘',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
    debugShowCheckedModeBanner: false,
    home: const HomeScreen(),
  ),
);
```

- 所有 ViewModel 通过 `ChangeNotifierProxyProvider` 关联 Repository，保持单一数据源。
- 若未来启用 `go_router`，可将 `MaterialApp` 替换为 `MaterialApp.router` 并注入 `routerConfig: goRouter`。

---

## 测试策略

- **Domain/Service 层**：使用 `flutter_test` + `mocktail`，针对 `QiGuaService`、`GuaCalculator`、`LunarService`、`LiuShenService` 编写纯函数测试（参见 `test/unit/services`）。
- **ViewModel 层**：`test/viewmodels/cast_viewmodel_test.dart`、`history_viewmodel_test.dart` 验证状态流转、通知次数、错误处理和仓储交互。
- **Widget 层**：对核心组件（`GuaDisplay`、结果/历史页面）编写 `WidgetTester`，确保路由、Semantics 与响应式布局满足 PRD。
- **集成测试**：通过 `integration_test/` 模拟完整流程（起卦 → 保存 → 查看历史），为后续多术数扩展保留脚本骨架。

---

## 性能优化

- 大量列表使用 `ListView.builder`/`Paged` 模式，历史记录分页常量 `_pageSize = 20`，滚动接近底部时自动触发 `loadMore`。
- 复用 `const` 构造与 `Selector` 减少 `Consumer` 重建，避免全树刷新。
- 数据库查询添加索引并按 `castTime DESC` 排序；搜索采用分页 + 并行解密策略，来自 `architecture_part2` 的优化建议已在 DAO 中实现。
- `flutter run --profile` 审查帧率，必要时对起卦动画使用 `TickerProvider` 替代 `Future.delayed`。

---

## 安全性

- **加密存储**：敏感字段（问题描述、详细解读）放入 `SecureStorage`，只在需要时解密；`GuaRecords` 中保存脱敏后的结构化卦象 JSON。
- **证书固定**：网络层预留证书固定开关，使用 `--dart-define=ENABLE_CERT_PINNING=false` 控制环境，生产模式必须启用并监控证书到期。
- **代码混淆**：Android `proguard`、iOS `--obfuscate --split-debug-info=./debug-info`，发布包默认启用资源压缩与混淆。
- **最小权限**：仅保留 `INTERNET` 及必要的存储/相册权限，避免多余声明。  
- **安全审计**：定期执行依赖更新、加密密钥轮换、日志审查，并将证书更新流程记录在 README。

---

## 历史变更与缺陷修复

源自 `architecture_fixes.md` 的 10 个关键缺陷已经并入本架构说明，核心修复包括：

1. **时间起卦时间戳**：`CastViewModel` 记录 `_castTime` 并在 `_calculateAndCreateRecord` 中传递，确保农历、六神、历史记录使用真实起卦时间。
2. **加密数据泄露**：Repository 在写入/查询时严格区分 `SecureStorage` 字段，移除任何日志输出，敏感内容只在内存中短暂存在。
3. **取模算法**：`QiGuaService.timeCast` 的上下卦、动爻计算统一以 `% 8`、`% 6` 方式实现，与 PRD 推导一致。
4. **变卦计算**：`GuaCalculator.generateChangingGua` 根据动爻翻转阴阳，输出合法的 6 爻结构，不再出现无效卦象。
5. **空 ID 与分页问题**：历史列表和搜索入口校验 ID/查询条件，分页时携带过滤条件，防止 API/DAO 返回未过滤结果。
6. **硬币输入**：手动输入流程支持三枚硬币面转爻 (`CoinFace`)，满足“钱币正反输入”需求。
7. **证书策略/性能**：补全证书轮换策略与搜索性能优化章，现已合并至“安全性”和“性能优化”章节。

> 未来如再发现架构级缺陷，请在此章节追加条目，记录问题背景、修复策略与对应代码片段，保持单一真相来源。

---

## 扩展性与多术数方案

为支持大六壬、小六壬、梅花易数等多种术数，结合 `docs/multi-divination-architecture-prd.md` 的规划，我们在架构层明确如下演进策略：

### Domain 抽象

- 定义 `DivinationSystem` 接口（纯 Dart），包含 `cast`, `validateInput`, `resultFromJson` 等方法。
- 所有术数的结果类型实现 `DivinationResult` 抽象基类；六爻当前实现为 `LiuYaoResult`，未来可添加 `DaLiuRenResult`。
- 抽离共享服务：`TianGanDiZhiService`、`WuXingService`、`LiuQinService`、`LunarService` 等供各术数重用。

### UI 工厂与 ViewModel

- 引入 `DivinationUIFactory`、`DivinationUIRegistry`，每个术数提供自己的起卦页、结果页、历史详情组件。
- `DivinationViewModel<T extends DivinationResult>` 成为泛型基类，六爻当前继承实现；新术数按需扩展专有方法。
- `DivinationSystemBootstrap` 统一注册系统/工厂，并暴露 `isEnabled` 标志，方便按配置启用术数模块。

### 数据层演进

- 保留 `GuaRecords` 以零迁移方式保存现有六爻数据。
- 新增 `DivinationRecords` 表存储其它术数，字段包含 `systemType`、`payloadJson`、`summary` 等，与 Repository 适配器组合提供统一查询接口。
- 历史列表通过联合查询（`GuaRecords ∪ DivinationRecords`）按时间排序，UI 根据 `systemType` 决定使用哪套展示组件。

### 实施步骤

1. Phase 1：提取共享服务、定义接口和 UI 工厂（Story 1.1-1.3）。
2. Phase 2：将现有六爻实现改造为 `LiuYaoSystem` 并接入泛型 ViewModel（Story 1.4-1.6）。
3. Phase 3：实现零迁移数据层和 Repository 适配器（Story 1.7-1.8）。
4. Phase 4：落地自动注册、主页选择器、动态起卦/结果/历史页面（Story 1.9-1.13）。
5. Phase 5：为未来术数提供骨架、补齐测试与文档（Story 1.14-1.16）。

该章节作为未来重构的官方指导，PRD 文档仅保留业务需求与验收标准，具体技术细节请以此处为准。

---

**架构文档版本**: 2.0  
**最后更新**: 2025-01-15  
**作者**: Winston (Architect) / 更新：Codex  
**状态**: ✅ 已合并 architecture_part2、architecture_fixes、multi-divination-architecture-prd 的关键内容


