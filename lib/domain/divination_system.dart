/// 排盘抽象接口定义
///
/// 本文件定义了多术数系统架构的核心抽象层，包括：
/// - [DivinationType]: 术数系统类型枚举
/// - [CastMethod]: 起卦方式枚举
/// - [DivinationResult]: 占卜结果抽象基类
/// - [DivinationSystem]: 排盘抽象接口
///
/// 设计原则：
/// 1. 纯 Dart 接口，无 Flutter 依赖
/// 2. 所有术数系统（六爻、大六壬、小六壬、梅花易数）都必须实现 [DivinationSystem] 接口
/// 3. 使用强类型枚举和泛型确保类型安全
/// 4. 支持系统启用/禁用控制
///
/// 架构层次：
/// ```
/// DivinationSystem (抽象接口)
///       ↑ implements
/// ┌─────┴─────┬─────────────┬──────────────┐
/// │           │             │              │
/// LiuYaoSystem DaLiuRenSystem XiaoLiuRenSystem MeiHuaSystem
/// ```
library;

import '../models/lunar_info.dart';

/// 术数系统类型枚举
///
/// 定义了应用支持的所有术数系统类型。
/// 每个枚举值包含：
/// - [displayName]: 用于 UI 显示的中文名称
/// - [id]: 用于序列化和数据库存储的唯一标识符
enum DivinationType {
  /// 六爻排盘
  liuYao('六爻', 'liuyao'),

  /// 大六壬排盘
  daLiuRen('大六壬', 'daliuren'),

  /// 小六壬排盘
  xiaoLiuRen('小六壬', 'xiaoliuren'),

  /// 梅花易数排盘
  meiHua('梅花易数', 'meihua');

  const DivinationType(this.displayName, this.id);

  /// UI 显示名称
  final String displayName;

  /// 唯一标识符（用于序列化）
  final String id;

  /// 从 ID 字符串获取枚举值
  ///
  /// 抛出 [ArgumentError] 如果 ID 不存在
  static DivinationType fromId(String id) {
    return DivinationType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => throw ArgumentError('Unknown divination type ID: $id'),
    );
  }
}

/// 起卦方式枚举
///
/// 定义了各种术数系统支持的起卦方法。
/// 不同的术数系统支持不同的起卦方式组合。
///
/// 例如：
/// - 六爻支持：coin, time, manual
/// - 梅花易数支持：time, number, random
enum CastMethod {
  /// 摇钱法（三枚铜钱摇六次）
  coin('摇钱法', 'coin'),

  /// 时间起卦（根据起卦时间计算）
  time('时间起卦', 'time'),

  /// 手动输入（用户直接输入卦象）
  manual('手动输入', 'manual'),

  /// 数字起卦（用户输入数字）
  number('数字起卦', 'number'),

  /// 随机起卦（系统随机生成）
  random('随机起卦', 'random');

  const CastMethod(this.displayName, this.id);

  /// UI 显示名称
  final String displayName;

  /// 唯一标识符（用于序列化）
  final String id;

  /// 从 ID 字符串获取枚举值
  ///
  /// 抛出 [ArgumentError] 如果 ID 不存在
  static CastMethod fromId(String id) {
    return CastMethod.values.firstWhere(
      (method) => method.id == id,
      orElse: () => throw ArgumentError('Unknown cast method ID: $id'),
    );
  }
}

/// 占卜结果抽象基类
///
/// 所有术数系统的结果都必须继承此类。
/// 定义了通用的属性和方法，用于：
/// - 历史记录管理
/// - UI 显示
/// - 数据库存储
///
/// 子类实现示例：
/// ```dart
/// class LiuYaoResult extends DivinationResult {
///   final Gua mainGua;
///   final Gua? changingGua;
///   // ... 其他六爻特有属性
/// }
/// ```
abstract class DivinationResult {
  /// 唯一标识符（UUID）
  ///
  /// 用于数据库主键和记录查询
  String get id;

  /// 起卦时间
  ///
  /// 记录用户执行占卜的时间，用于历史记录排序
  DateTime get castTime;

  /// 术数系统类型
  ///
  /// 标识此结果属于哪个术数系统
  DivinationType get systemType;

  /// 起卦方式
  ///
  /// 记录用户使用的起卦方法（摇钱法、时间起卦等）
  CastMethod get castMethod;

  /// 农历信息
  ///
  /// 包含月建、日干支、空亡等农历数据，
  /// 所有术数系统都需要农历信息进行计算
  LunarInfo get lunarInfo;

  /// 序列化为 JSON
  ///
  /// 用于数据库存储和网络传输。
  /// 子类必须实现完整的序列化逻辑。
  ///
  /// 返回的 Map 必须包含所有必要字段，
  /// 能够通过 [DivinationSystem.resultFromJson] 完整还原对象。
  Map<String, dynamic> toJson();

  /// 获取结果摘要
  ///
  /// 用于历史记录列表显示，应返回简洁的一行文本。
  ///
  /// 示例：
  /// - 六爻：「天雷无妄」变「天风姤」
  /// - 大六壬：「贵登天门」课体
  /// - 梅花易数：「山火贲」之「山天大畜」
  String getSummary();
}

/// 排盘抽象接口
///
/// 所有术数系统（六爻、大六壬、小六壬、梅花易数）都必须实现此接口。
/// 接口定义了统一的：
/// - 系统元数据（名称、描述、支持的起卦方式）
/// - 起卦方法 [cast]
/// - 结果反序列化方法 [resultFromJson]
/// - 输入验证方法 [validateInput]
///
/// 实现示例：
/// ```dart
/// class LiuYaoSystem implements DivinationSystem {
///   @override
///   DivinationType get type => DivinationType.liuYao;
///
///   @override
///   String get name => '六爻占卜';
///
///   @override
///   List<CastMethod> get supportedMethods => [
///     CastMethod.coin,
///     CastMethod.time,
///     CastMethod.manual,
///   ];
///
///   @override
///   Future<DivinationResult> cast({
///     required CastMethod method,
///     required Map<String, dynamic> input,
///     DateTime? castTime,
///   }) async {
///     // 实现六爻起卦逻辑
///   }
///
///   // ... 其他方法实现
/// }
/// ```
abstract class DivinationSystem {
  /// 术数系统类型
  ///
  /// 返回此系统的类型枚举值，用于注册表管理和类型识别
  DivinationType get type;

  /// 系统名称
  ///
  /// 用于 UI 显示的系统名称，例如："六爻占卜"、"大六壬"
  String get name;

  /// 系统描述
  ///
  /// 用于帮助文档和系统介绍，应简要说明系统特点和用途
  String get description;

  /// 支持的起卦方式列表
  ///
  /// 返回此系统支持的所有起卦方法。
  ///
  /// 例如：
  /// - 六爻支持：[CastMethod.coin, CastMethod.time, CastMethod.manual]
  /// - 梅花易数支持：[CastMethod.time, CastMethod.number, CastMethod.random]
  List<CastMethod> get supportedMethods;

  /// 系统是否启用
  ///
  /// 返回 true 表示系统已完成开发，可在 UI 中显示。
  /// 返回 false 表示系统正在开发中，不会在 UI 中显示。
  ///
  /// 注册表的 [DivinationRegistry.getSystem] 方法会检查此属性，
  /// 禁用的系统会抛出 [StateError]。
  bool get isEnabled;

  /// 执行起卦操作
  ///
  /// 根据指定的起卦方式和输入参数，执行占卜计算并返回结果。
  ///
  /// 参数：
  /// - [method]: 起卦方式，必须在 [supportedMethods] 列表中
  /// - [input]: 起卦输入参数，格式根据 [method] 不同而不同：
  ///   - coin: {} (无需参数，系统随机生成)
  ///   - time: {'time': DateTime} (可选，默认当前时间)
  ///   - manual: {'yaoNumbers': [6,7,8,9,8,7]} (六个爻的数字)
  ///   - number: {'number': 123} (用户输入的数字)
  ///   - random: {} (无需参数)
  /// - [castTime]: 起卦时间，可选，默认为当前时间
  ///
  /// 返回：
  /// 返回对应术数系统的结果对象（继承自 [DivinationResult]）
  ///
  /// 异常：
  /// - [ArgumentError]: 如果 [method] 不在 [supportedMethods] 中
  /// - [ArgumentError]: 如果 [input] 验证失败（通过 [validateInput] 检查）
  /// - [StateError]: 如果系统未启用（[isEnabled] 为 false）
  ///
  /// 实现注意事项：
  /// 1. 必须先调用 [validateInput] 验证输入
  /// 2. 使用 [castTime] 或当前时间计算农历信息
  /// 3. 执行术数系统特定的计算逻辑
  /// 4. 返回完整的结果对象
  Future<DivinationResult> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  });

  /// 从 JSON 反序列化结果对象
  ///
  /// 用于从数据库加载历史记录。
  /// 必须能够完整还原通过 [DivinationResult.toJson] 序列化的对象。
  ///
  /// 参数：
  /// - [json]: 序列化的 JSON 数据
  ///
  /// 返回：
  /// 返回对应术数系统的结果对象
  ///
  /// 异常：
  /// - [FormatException]: 如果 JSON 格式不正确
  /// - [ArgumentError]: 如果必需字段缺失
  DivinationResult resultFromJson(Map<String, dynamic> json);

  /// 验证起卦输入参数
  ///
  /// 在执行 [cast] 之前验证输入参数的有效性。
  ///
  /// 参数：
  /// - [method]: 起卦方式
  /// - [input]: 输入参数
  ///
  /// 返回：
  /// - true: 验证通过，可以执行起卦
  /// - false: 验证失败，输入参数不符合要求
  ///
  /// 验证规则示例：
  /// - coin: 无需参数，始终返回 true
  /// - time: 检查 'time' 字段是否为有效的 DateTime
  /// - manual: 检查 'yaoNumbers' 是否为长度为 6 的数组，且每个元素在 6-9 之间
  /// - number: 检查 'number' 字段是否为正整数
  /// - random: 无需参数，始终返回 true
  bool validateInput(CastMethod method, Map<String, dynamic> input);
}
