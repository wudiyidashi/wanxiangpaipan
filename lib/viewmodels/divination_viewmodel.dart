import 'package:flutter/foundation.dart';
import '../domain/divination_system.dart';
import '../domain/repositories/divination_repository.dart';

/// 起卦状态
enum CastState {
  idle, // 空闲
  casting, // 起卦中
  calculating, // 计算中
  success, // 成功
  error, // 错误
}

/// 占卜 ViewModel 泛型基类
///
/// 所有术数系统的 ViewModel 都应该继承此类。
/// 使用泛型确保类型安全，避免运行时类型转换。
///
/// 类型参数：
/// - [T] 继承自 DivinationResult 的具体结果类型
///
/// 示例：
/// ```dart
/// class LiuYaoViewModel extends DivinationViewModel<LiuYaoResult> {
///   LiuYaoViewModel({
///     required LiuYaoSystem system,
///     required GuaRepository repository,
///   }) : super(system: system, repository: repository);
///
///   // 六爻特定的便捷方法
///   Gua? get mainGua => result?.mainGua;
///   bool get hasMovingYao => result?.hasMovingYao ?? false;
/// }
/// ```
abstract class DivinationViewModel<T extends DivinationResult>
    extends ChangeNotifier {
  /// 排盘实例
  final DivinationSystem system;

  /// 数据仓库
  final DivinationRepository repository;

  /// 构造函数
  DivinationViewModel({
    required this.system,
    required this.repository,
  });

  // ==================== 状态属性 ====================

  /// 当前状态
  CastState _state = CastState.idle;
  CastState get state => _state;

  /// 占卜结果
  T? _result;
  T? get result => _result;

  /// 错误信息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 是否正在加载
  bool get isLoading =>
      _state == CastState.casting || _state == CastState.calculating;

  /// 是否有结果
  bool get hasResult => _result != null;

  /// 是否有错误
  bool get hasError => _state == CastState.error;

  // ==================== 核心方法 ====================

  /// 执行起卦
  ///
  /// 这是核心方法，根据起卦方式和输入参数生成占卜结果。
  ///
  /// [method] 起卦方式
  /// [input] 输入参数
  /// [castTime] 起卦时间，如果为 null 则使用当前时间
  Future<void> cast({
    required CastMethod method,
    required Map<String, dynamic> input,
    DateTime? castTime,
  }) async {
    _setState(CastState.casting);
    _clearError();

    try {
      // 调用系统的 cast 方法
      final rawResult = await system.cast(
        method: method,
        input: input,
        castTime: castTime,
      );

      // 类型安全的转换
      _result = rawResult as T;
      _setState(CastState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(CastState.error);
    }
  }

  /// 保存占卜记录
  ///
  /// 将当前的占卜结果保存到数据库。
  /// 可选地保存问事、详情、解读等加密字段。
  ///
  /// [question] 问事主题
  /// [detail] 详细说明
  /// [interpretation] 个人解读
  Future<void> saveRecord({
    String? question,
    String? detail,
    String? interpretation,
  }) async {
    if (_result == null) {
      throw StateError('没有可保存的占卜结果');
    }

    try {
      // 1. 保存占卜结果到数据库
      await repository.saveRecord(_result!);

      // 2. 保存加密字段（如果提供）
      final encryptedFields = <String, String>{};

      if (question != null && question.isNotEmpty) {
        encryptedFields['question_${_result!.id}'] = question;
      }

      if (detail != null && detail.isNotEmpty) {
        encryptedFields['detail_${_result!.id}'] = detail;
      }

      if (interpretation != null && interpretation.isNotEmpty) {
        encryptedFields['interpretation_${_result!.id}'] = interpretation;
      }

      if (encryptedFields.isNotEmpty) {
        await repository.saveEncryptedFieldsBatch(encryptedFields);
      }
    } catch (e) {
      throw Exception('保存占卜记录失败: $e');
    }
  }

  /// 重置状态
  ///
  /// 清除当前结果和错误状态，用于用户重新起卦时清理状态。
  void reset() {
    _result = null;
    _errorMessage = null;
    _setState(CastState.idle);
  }

  // ==================== 私有方法 ====================

  /// 设置状态
  void _setState(CastState newState) {
    _state = newState;
    notifyListeners();
  }

  /// 清除错误
  void _clearError() {
    _errorMessage = null;
  }

  // ==================== 生命周期 ====================

  @override
  void dispose() {
    super.dispose();
  }
}
