import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 加密存储服务
/// 负责敏感信息（如 Cookies、API 密钥等）的加密存储和读取
/// 使用 flutter_secure_storage 包，在各平台使用系统级别的加密：
/// - Android: Android Keystore
/// - iOS: Keychain
/// - Windows: Credential Manager
/// - Linux: 需要安装 libsecret
class SecureStorageService {
  static const String _keyPrefix = 'user_';
  static const String _cookieKeySuffix = '_cookie';
  static const String _platformKeyPrefix = 'platform_';

  final FlutterSecureStorage _storage;

  SecureStorageService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  /// 生成 Cookie 存储的键名
  /// 格式: user_{userId}_platform_{platform}_cookie
  String _generateCookieKey(int userId, String platformType) {
    return '$_keyPrefix${userId}_${_platformKeyPrefix}${platformType}$_cookieKeySuffix';
  }

  /// 生成通用敏感信息存储的键名
  String _generateStorageKey(int userId, String key) {
    return '$_keyPrefix${userId}_$key';
  }

  /// 保存用户的 Cookie（加密）
  ///
  /// 参数:
  /// - userId: 应用内用户 ID
  /// - platformType: 平台类型 (如 'bilibili')
  /// - cookie: Cookie 字符串
  Future<void> saveCookie(int userId, String platformType, String cookie) async {
    try {
      final key = _generateCookieKey(userId, platformType);
      await _storage.write(key: key, value: cookie);
      debugPrint('✅ Cookie 已保存: $platformType');
    } catch (e) {
      debugPrint('❌ 保存 Cookie 失败: $e');
      rethrow;
    }
  }

  /// 读取用户的 Cookie（解密）
  ///
  /// 参数:
  /// - userId: 应用内用户 ID
  /// - platformType: 平台类型 (如 'bilibili')
  ///
  /// 返回: Cookie 字符串，如果不存在返回 null
  Future<String?> getCookie(int userId, String platformType) async {
    try {
      final key = _generateCookieKey(userId, platformType);
      final cookie = await _storage.read(key: key);
      if (cookie != null) {
        debugPrint('✅ Cookie 已读取: $platformType');
      } else {
        debugPrint('⚠️ Cookie 不存在: $platformType');
      }
      return cookie;
    } catch (e) {
      debugPrint('❌ 读取 Cookie 失败: $e');
      return null;
    }
  }

  /// 删除用户的 Cookie
  ///
  /// 参数:
  /// - userId: 应用内用户 ID
  /// - platformType: 平台类型 (如 'bilibili')
  Future<void> deleteCookie(int userId, String platformType) async {
    try {
      final key = _generateCookieKey(userId, platformType);
      await _storage.delete(key: key);
      debugPrint('✅ Cookie 已删除: $platformType');
    } catch (e) {
      debugPrint('❌ 删除 Cookie 失败: $e');
      rethrow;
    }
  }

  /// 检查用户的 Cookie 是否存在
  Future<bool> hasCookie(int userId, String platformType) async {
    try {
      final key = _generateCookieKey(userId, platformType);
      final cookie = await _storage.read(key: key);
      return cookie != null && cookie.isNotEmpty;
    } catch (e) {
      debugPrint('❌ 检查 Cookie 失败: $e');
      return false;
    }
  }

  /// 保存通用敏感信息（如 API 密钥）
  ///
  /// 参数:
  /// - userId: 应用内用户 ID
  /// - key: 信息键名
  /// - value: 信息值
  Future<void> saveSensitiveData(int userId, String key, String value) async {
    try {
      final storageKey = _generateStorageKey(userId, key);
      await _storage.write(key: storageKey, value: value);
      debugPrint('✅ 敏感数据已保存: $key');
    } catch (e) {
      debugPrint('❌ 保存敏感数据失败: $e');
      rethrow;
    }
  }

  /// 读取通用敏感信息
  Future<String?> getSensitiveData(int userId, String key) async {
    try {
      final storageKey = _generateStorageKey(userId, key);
      final value = await _storage.read(key: storageKey);
      if (value != null) {
        debugPrint('✅ 敏感数据已读取: $key');
      } else {
        debugPrint('⚠️ 敏感数据不存在: $key');
      }
      return value;
    } catch (e) {
      debugPrint('❌ 读取敏感数据失败: $e');
      return null;
    }
  }

  /// 删除通用敏感信息
  Future<void> deleteSensitiveData(int userId, String key) async {
    try {
      final storageKey = _generateStorageKey(userId, key);
      await _storage.delete(key: storageKey);
      debugPrint('✅ 敏感数据已删除: $key');
    } catch (e) {
      debugPrint('❌ 删除敏感数据失败: $e');
      rethrow;
    }
  }

  /// 清除用户的所有敏感信息
  /// 用于用户登出或删除账号时
  Future<void> clearAllUserData(int userId) async {
    try {
      final allKeys = await _storage.readAll();
      final userPrefix = '$_keyPrefix$userId';

      for (final key in allKeys.keys) {
        if (key.startsWith(userPrefix)) {
          await _storage.delete(key: key);
        }
      }
      debugPrint('✅ 用户所有敏感数据已清除: userId=$userId');
    } catch (e) {
      debugPrint('❌ 清除用户数据失败: $e');
      rethrow;
    }
  }

  /// 为了调试：获取所有存储的键（不包括值，出于安全考虑）
  /// 仅在开发模式下使用
  Future<List<String>> getAllStorageKeys() async {
    try {
      final allKeys = await _storage.readAll();
      return allKeys.keys.toList();
    } catch (e) {
      debugPrint('❌ 读取存储键失败: $e');
      return [];
    }
  }
}

// 调试打印辅助函数
void debugPrint(String message) {
  // 在实际使用中，这里可以连接到 logger
  print('[SecureStorage] $message');
}
