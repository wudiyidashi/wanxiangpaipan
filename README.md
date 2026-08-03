# 万象排盘 - 多术数系统平台

<div align="center">

**专业的中国传统术数占卜应用 | 可扩展的多系统架构 | AI 解卦**

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![codecov](https://codecov.io/gh/wudiyidashi/wanxiangpaipan/branch/main/graph/badge.svg)](https://codecov.io/gh/wudiyidashi/wanxiangpaipan)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)

</div>

---

## 最新更新

### 2026-08-03 · v1.6.1 - v1.6.2

- 设置中的“关于”弹窗现在显示实际安装版本和构建号，不再固定显示 `1.0.0`。
- GitHub Release 恢复提供可直接安装的 Android APK，并同时提供用于应用商店发布的 AAB。
- 六爻对“是否顺利”改用形成、得失、持续性和纠缠四阶段判断；事情能签成或开始，不再被等同为全程顺利。
- 六合改为随主证解释的关系黏合与牵绊，只参与事情形成和持续纠缠，不能单独决定最终吉凶。
- 动爻前段作用与变爻后段限制分别保留，回头克、化退、化绝等不会再追溯抹掉已经发生的前段作用。
- 租房解读会分别检查签约入住、出租权与合同主体、收费、交付占有和完整租期，并保持风险提示在盘面证据允许的范围内。
- 卦名卦阳历模式现在保存用户实际选择的起卦时间；未选用神时 AI 会明确止断，有程序阶段裁决时才解释结论。
- 无条件、无应期的新解读只说明当前状态，不再从审计摘要扩写等待、择日或未来释放路径；既有对话仍按原快照重放。

[查看完整发布说明](docs/releases/release-notes.md)

---

## 📖 项目简介

万象排盘是一款基于 Flutter 开发的**跨平台多术数系统平台**，旨在为传统术数爱好者和专业从业者提供专业、准确、易用的数字化工具。

### 🎯 项目愿景

- **多系统支持**: 统一平台支持六爻、大六壬、奇门遁甲、小六壬和梅花易数
- **专业准确**: 严格遵循传统术数理论，提供准确的卦象计算和解析
- **开放扩展**: 基于插件化架构，开发者可轻松添加新的术数系统
- **隐私安全**: 所有数据本地加密存储，完全离线可用
- **AI 增强**: 可选接入大模型进行卦象辅助解读或者自己复制后自行查询

### ✨ 核心特性

#### 🔮 已完整实现的系统

**六爻系统** (Liu Yao)
- ✅ **六种起卦方式**：钱币卦、爻名卦、数字卦、报数卦、时间卦、电脑卦
- ✅ 完整纳甲装卦（地支、天干、六亲、五行）
- ✅ 世应定位、动爻变卦、伏神
- ✅ 六神配置（青龙、朱雀、勾陈、腾蛇、白虎、玄武）
- ✅ 空亡计算、农历信息、特殊卦型（六冲/六合/游魂/归魂）

**大六壬系统** (Da Liu Ren)
- ✅ **四种起课方式**：时间起课、报数起课、手动输入、电脑随机
- ✅ 四课三传完整推演（九宗门课体：贼克/比用/涉害/遥克/昴星/别责/八专/返吟/伏吟）
- ✅ 十二天将配置（含昼贵/夜贵、贵人口诀切换）
- ✅ 天盘地盘、月将月建（自动/手动切换）
- ✅ 神煞系统（吉神 / 凶神）
- ✅ 旬遁干（日柱 / 时柱）

**奇门遁甲系统** (Qi Men Dun Jia)
- ✅ **两种起局方式**：自动时间起局、手动四柱校盘
- ✅ 拆补 / 茅山 / 置闰，支持当地民用时间、北京时间和真太阳时
- ✅ 洛书九宫完整盘面、值符值使、寄宫、暗干、旬空和驿马
- ✅ 本地四值裁决、焦点与事实、冲突压制、规则来源和应期观察窗口
- ✅ 历史重开、按系统数据管理、结构化 AI 解读和受控降级

**梅花易数系统** (Mei Hua)
- ✅ **三种起卦方式**：时间起卦、数字起卦、手动输入
- ✅ 本卦 / 变卦 / 互卦完整推导
- ✅ 单动爻 + 体卦 / 用卦判定
- ✅ 体用五行关系（体生用 / 用生体 / 体克用 / 用克体 / 体用比和）

**小六壬系统** (Xiao Liu Ren)
- ✅ **三种起课方式**：时间起课、报数起课、汉字笔画起
- ✅ 六宫 / 九宫两种盘式（六宫：大安/留连/速喜/赤口/小吉/空亡；九宫另加病符/桃花/天德）
- ✅ 三段顺推链（起点记 1 → 顺推落宫 → 最终宫）

#### 🤖 AI 解卦

- ✅ OpenAI 兼容接口（支持自建 API、代理和第三方模型服务）
- ✅ 按术数系统分类的提示词模板管理（可编辑、可自定义）
- ✅ 结构化输出（Markdown 渲染）

#### 🛠️ 平台功能

- **每系统独立起卦界面**: 各术数系统通过 `DivinationUIFactory` 提供自己的起卦页与结果页；起卦方式切换在系统内部完成
- **起卦历史**: 用户的每次起卦都会存在历史面板中
- **数据管理**: 支持全量备份、导入恢复、按术数统计和独立清理
- **加密存储**: 用户问题和解读信息端到端加密（flutter_secure_storage）
- **离线优先**: 所有功能完全离线可用（AI 功能除外）
- **无障碍支持**: 核心组件带 Semantics 标签，支持 VoiceOver / TalkBack

---

## 🏗️ 架构设计

### 多术数系统架构

本项目的核心创新在于**可扩展的多系统架构**，通过接口抽象和注册表模式实现术数系统的插件化。

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation Layer (lib/presentation/)                     │
│  └─ 动态 UI（通过 DivinationUIFactory 构建）                │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  ViewModel Layer (lib/viewmodels/)                          │
│  └─ DivinationViewModel<T>（泛型基类）                      │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  Divination System Layer (lib/divination_systems/)          │
│  ├─ DivinationSystem（接口）                                │
│  ├─ DivinationRegistry（系统注册表）                        │
│  ├─ LiuYaoSystem ✅（六爻完整实现）                         │
│  ├─ DaLiuRenSystem ✅（大六壬完整实现）                     │
│  ├─ MeiHuaSystem ✅（梅花易数完整实现）                     │
│  ├─ XiaoLiuRenSystem ✅（小六壬完整实现）                   │
│  └─ QimenSystem ✅（奇门遁甲完整实现）                      │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  AI Layer (lib/ai/)                                         │
│  ├─ LLMProviderRegistry（模型提供商注册表）                 │
│  ├─ OpenAI 兼容 Provider                                    │
│  ├─ AIAnalysisService（解卦调用入口）                       │
│  └─ 提示词模板（按系统分类，可编辑）                        │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  Repository Layer (lib/domain/repositories/)                │
│  └─ 统一的 DivinationRepository（多态存储）                 │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  Data Layer (lib/data/)                                     │
│  └─ DivinationRecords 表（多态存储）                        │
└─────────────────────────────────────────────────────────────┘
                          ↓ uses
┌─────────────────────────────────────────────────────────────┐
│  Shared Services (lib/domain/services/shared/)              │
│  ├─ TianGanDiZhiService（天干地支计算）                     │
│  ├─ WuXingService（五行生克）                               │
│  ├─ LiuQinService（六亲推算）                               │
│  └─ LunarService（农历转换）                                │
└─────────────────────────────────────────────────────────────┘
```

### 核心接口设计

#### DivinationSystem（术数系统接口）

所有术数系统都必须实现此接口：

```dart
abstract class DivinationSystem {
  DivinationType get type;                 // 系统类型枚举
  String get name;                         // 系统名称
  String get description;                  // 系统描述
  bool get isEnabled;                      // 是否启用
  List<CastMethod> get supportedMethods;   // 支持的起卦方式

  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  });

  DivinationResult resultFromJson(Map<String, dynamic> json);
  bool validateInput(CastMethod method, Map<String, dynamic> input);
}
```

#### DivinationResult（占卜结果接口）

```dart
abstract class DivinationResult {
  String get id;
  DivinationType get systemType;
  DateTime get castTime;
  CastMethod get castMethod;
  LunarInfo get lunarInfo;

  String getSummary();
  Map<String, dynamic> toJson();
}
```

### MVVM + Repository 模式

```
User Action → ViewModel → Repository → Data Source
                ↓
         notifyListeners()
                ↓
            UI Update
```

### 架构优势

- ✅ **零迁移扩展**: 添加新系统无需修改现有代码或数据库结构
- ✅ **类型安全**: 泛型设计保证编译期类型检查
- ✅ **统一存储**: 多态 JSON 存储，统一查询接口
- ✅ **UI 解耦**: 每个系统自定义 UI，通过工厂模式动态构建
- ✅ **AI 分层**: 大模型调用独立在 `lib/ai/`，可按术数类型切换提示词模板
- ✅ **测试友好**: 接口驱动设计，易于 Mock 和单元测试

---

## 🚀 快速开始

### 前置要求

- Flutter SDK >= 3.38.0
- Dart SDK >= 3.0.0
- Android Studio / Xcode（用于运行模拟器）
- Git

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/wudiyidashi/wanxiangpaipan.git
   cd wanxiangpaipan
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **代码生成**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **运行应用**
   ```bash
   # iOS
   flutter run -d ios

   # Android
   flutter run -d android

   # 所有设备
   flutter run
   ```

### 开发模式

```bash
# 代码生成监听模式（推荐开发时使用）
dart run build_runner watch --delete-conflicting-outputs

# 代码分析
flutter analyze

# 运行测试
flutter test

# 测试覆盖率
flutter test --coverage
```

---

## 📁 项目结构

```
lib/
├── main.dart                          # 应用入口 + 系统注册
├── /core                              # 核心基础设施
│   ├── /constants                     # 常量定义
│   ├── /router                        # 路由配置
│   ├── /theme                         # 主题配置
│   └── /utils                         # 工具函数
├── /ai                                # 🔥 AI 解卦层
│   ├── ai_bootstrap.dart              # 启动时注册 Provider / 加载模板
│   ├── llm_provider.dart              # LLMProvider 接口
│   ├── llm_provider_registry.dart     # Provider 注册表
│   ├── /providers
│   │   └── openai_compatible_provider.dart
│   ├── /service
│   │   └── ai_analysis_service.dart   # 解卦调用入口
│   ├── /config                        # API 配置持久化
│   ├── /template                      # 提示词模板（按系统分类）
│   └── /output                        # 结构化输出解析
├── /divination_systems                # 🔥 多术数系统实现
│   ├── registry_bootstrap.dart        # 自动注册所有系统
│   ├── /liuyao                        # 六爻系统 ✅
│   │   ├── liuyao_system.dart
│   │   ├── /models
│   │   ├── /ui                        # UI 工厂
│   │   └── /viewmodels
│   ├── /daliuren                      # 大六壬系统 ✅
│   │   ├── daliuren_system.dart
│   │   ├── /models                    # SiKe / Chuan / TianPan / ShenJiang / ShenSha / PanParams
│   │   └── /ui                        # UI 工厂
│   ├── /qimen                         # 奇门遁甲系统 ✅
│   │   ├── qimen_system.dart
│   │   ├── /models                    # 时间口径 / 定局 / 九宫强类型结果
│   │   ├── /ui                        # 起局、九宫、详情、裁决与应期
│   │   └── /viewmodels                # cast -> save 提交状态机
│   ├── /meihua                        # 梅花易数系统 ✅
│   │   ├── meihua_system.dart
│   │   ├── /models                    # Trigram / Hexagram / Source
│   │   └── /ui                        # UI 工厂 + 独立自绘卦图
│   └── /xiaoliuren                    # 小六壬系统 ✅
│       ├── xiaoliuren_system.dart
│       ├── /models                    # Source / Position (六宫/九宫)
│       └── /ui                        # UI 工厂 + 独立自绘顺推链
├── /models                            # 共享数据模型
│   ├── yao.dart                       # 爻模型（六爻专用）
│   ├── gua.dart                       # 卦模型（六爻专用）
│   └── lunar_info.dart                # 农历信息（跨系统共享）
├── /domain                            # 领域层（纯函数）
│   ├── divination_system.dart         # 🔥 核心接口 + CastMethod 枚举
│   ├── divination_registry.dart       # 🔥 系统注册表
│   ├── /repositories
│   │   └── divination_repository.dart # 统一占卜记录仓库
│   └── /services
│       ├── /shared                    # 🔥 跨系统共享服务
│       │   ├── tiangan_dizhi_service.dart
│       │   ├── wuxing_service.dart
│       │   ├── liuqin_service.dart
│       │   └── lunar_service.dart
│       ├── last_cast_method_service.dart # 🔥 跨系统起卦方式记忆
│       └── gua_calculator.dart        # 六爻专用算法
├── /data                              # 数据层
│   ├── /database                      # Drift 数据库
│   │   ├── app_database.dart
│   │   └── tables.dart                # DivinationRecords
│   ├── /secure                        # 加密存储
│   └── /repositories
│       └── divination_repository_impl.dart
├── /viewmodels                        # ViewModel 层
│   └── divination_viewmodel.dart      # 🔥 泛型基类
└── /presentation                      # UI 层
    ├── divination_ui_registry.dart    # 🔥 UI 工厂注册表
    ├── /screens
    │   ├── /home                      # 首页（系统选择 + 历史 + 日历 + 我的）
    │   ├── /result                    # 结果展示（各系统 UI 工厂内实现）
    │   ├── /history                   # 历史记录（统一列表）
    │   └── /settings                  # 设置 + AI 设置 + 模板编辑
    └── /widgets                       # 可复用组件

core/navigation/route_observer.dart    # 🔥 全局 RouteObserver，驱动 pop 后刷新

test/                                  # 测试（1,100+ tests passing）
docs/                                  # 文档
└── /superpowers                       # 工程实施计划与 spec 归档
```

---

## 🧰 技术栈

| 类别 | 技术 | 版本 | 用途 |
|------|------|------|------|
| **语言** | Dart | 3.0+ | 强类型系统 |
| **框架** | Flutter | 3.38+ | 跨平台 UI 框架 |
| **状态管理** | Provider | 6.x | 依赖注入 + 响应式状态 |
| **不可变模型** | freezed | 2.x | 代码生成（数据类） |
| **JSON 序列化** | json_serializable | 6.x | JSON 序列化 |
| **路由** | Flutter Navigator + 命名路由 | — | 浅栈导航；云同步阶段再迁 go_router（[ADR-0001](docs/decisions/0001-routing-strategy.md)） |
| **本地数据库** | drift | 2.x | 类型安全 SQL |
| **加密存储** | flutter_secure_storage | 9.x | Keychain/Keystore |
| **轻量持久化** | shared_preferences | - | 主题、API 配置等偏好 |
| **农历计算** | lunar | 1.7.8 | 天干地支、六十甲子 |
| **Markdown** | flutter_markdown | - | AI 解卦结果渲染 |
| **测试** | flutter_test + mocktail | - | 单元/Widget 测试 |

---

## 🔌 如何添加新的术数系统

本项目的核心优势是**零迁移扩展性**。添加新系统只需以下步骤：

### 1. 创建系统目录结构

```bash
lib/divination_systems/your_system/
├── your_system_system.dart       # 实现 DivinationSystem
├── /models
│   └── your_system_result.dart   # 实现 DivinationResult
├── /ui
│   └── your_system_ui_factory.dart # 实现 DivinationUIFactory
└── /viewmodels
    └── your_system_viewmodel.dart  # 扩展 DivinationViewModel<T>
```

### 2. 实现核心接口

```dart
// your_system_system.dart
class YourSystem implements DivinationSystem {
  @override
  DivinationType get type => DivinationType.yourSystem;

  @override
  String get name => '你的系统名称';

  @override
  bool get isEnabled => true;

  @override
  List<CastMethod> get supportedMethods => [
        CastMethod.time,
        CastMethod.manual,
      ];

  @override
  Future<DivinationResult> cast(...) async {
    // 实现占卜逻辑
  }

  @override
  DivinationResult resultFromJson(Map<String, dynamic> json) {
    return YourSystemResult.fromJson(json);
  }
}
```

### 3. 注册系统

在 `lib/divination_systems/registry_bootstrap.dart` 中注册：

```dart
void registerDivinationSystems() {
  final registry = DivinationRegistry.instance;

  registry.register(YourSystem());

  DivinationUIRegistry.instance.register(
    DivinationType.yourSystem,
    YourSystemUIFactory(),
  );
}
```

### 4. （可选）为新系统配置 AI 解卦模板

在 `lib/ai/template/` 下放置对应系统的提示词模板；用户可在"AI 设置"中查看/编辑。

### 5. 完成！🎉

无需修改数据库、路由或任何现有代码。新系统会自动出现在主界面，起卦/保存/历史/AI 解卦全部开箱即用。

**详细指南**: 参见 [docs/architecture.md](docs/architecture.md)

---

## 🧪 测试策略

项目采用**测试驱动开发**，当前 **1,100+ tests 全部通过**。

### 测试层次

- **Domain Services**: 纯函数，完全可测试（天干地支 / 五行 / 六亲 / 农历）
- **ViewModel Layer**: 泛型基类 + 具体实现
- **Widget Layer**: antique 组件库 widget tests（29+ tests）+ 页面关键路径
- **Golden Tests**: 大六壬起课页视觉回归基线

```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/unit/domain/services/

# 生成覆盖率报告
flutter test --coverage

# 更新 golden baseline（视觉回归）
flutter test --update-goldens
```

---

## 🤝 贡献指南

欢迎任何形式的贡献——新功能、Bug 修复、文档改进都可以。

### 贡献流程

1. **Fork 本项目**
2. **创建功能分支** (`git checkout -b feature/AmazingFeature`)
3. **提交代码** (`git commit -m 'feat: Add some AmazingFeature'`)
4. **推送到分支** (`git push origin feature/AmazingFeature`)
5. **提交 Pull Request**

### 提交规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建/工具链配置

### 代码风格

- 使用 `flutter analyze` 检查代码质量
- 使用 `dart format` 格式化代码
- 所有 PR 必须通过 CI 测试
- 新功能需包含单元测试

---

## 📋 开发路线图

### ✅ Phase 1: 基础架构（已完成）

- [x] 多术数系统架构设计
- [x] 泛型 ViewModel 基类
- [x] 零迁移数据层
- [x] 六爻系统完整实现（6 种起卦方式）

### ✅ Phase 2: 五大系统全面上线（已完成）

- [x] 大六壬系统完整实现（4 种起课方式、九宗门课体、十二天将、神煞）
- [x] 梅花易数系统完整实现（时间/数字/手动起卦、本变互卦、体用五行）
- [x] 小六壬系统完整实现（时间/报数/笔画起课、六宫/九宫、三段顺推）
- [x] 奇门遁甲完整实现（时间/手动起局、九宫、本地规则分析、应期与历史闭环）
- [x] AI 解卦（OpenAI 兼容接口 + 五系统各自提示词模板）
- [x] 各系统独立起卦页 + 自绘卦图 / 顺推链
- [x] 跨系统起卦方式记忆（LastCastMethodService，历史记录即真相源）
- [x] RouteObserver 驱动的 pop 刷新（首页 QuickHistoryBar + 历史独立路由）
- [x] 数据导入 / 导出、按系统统计与独立清理
- [x] 全量 1,100+ 测试通过
- [x] GitHub Actions Release 流水线（Android APK + AAB 自动打包）

### 🔮 Phase 3: 增强功能（计划中）

- [ ] 结果图片 / 文本分享
- [ ] 暗黑模式（墨色主题）
- [ ] 云同步（可选）
- [ ] 多语言支持（英文）
- [ ] 更丰富的起卦方式（摇卦动画、语音输入）
- [ ] iOS / macOS 签名发布

---

## 📄 许可证

本项目采用 [Apache License 2.0](LICENSE) 许可证。

---

## 📞 联系方式

- **Issues**: [GitHub Issues](https://github.com/wudiyidashi/wanxiangpaipan/issues)
- **讨论**: [GitHub Discussions](https://github.com/wudiyidashi/wanxiangpaipan/discussions)

---

## 🙏 致谢

感谢所有为本项目做出贡献的开发者！

特别感谢：
- [lunar](https://pub.dev/packages/lunar) - 农历计算库
- [drift](https://pub.dev/packages/drift) - 高性能本地数据库
- Flutter 社区的所有贡献者

---

<div align="center">

**如果这个项目对你有帮助，请给一个 ⭐️ Star！**

Made with ❤️ by Chinese Divination Enthusiasts

</div>
