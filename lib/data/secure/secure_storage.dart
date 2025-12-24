import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 加密存储服务
class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// 写入加密数据
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// 读取加密数据
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// 批量读取加密数据
  Future<Map<String, String>> readMultiple(List<String> keys) async {
    final results = <String, String>{};
    for (final key in keys) {
      final value = await _storage.read(key: key);
      if (value != null) {
        results[key] = value;
      }
    }
    return results;
  }

  /// 删除加密数据
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// 检查键是否存在
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// 删除所有数据
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
