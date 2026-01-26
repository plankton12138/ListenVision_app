import 'package:flutter/foundation.dart';
import 'package:demo/core/network/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/core/utils/app_logger.dart';

/// B站认证状态管理
///
/// 负责：
/// 1. QR码登录
/// 2. Token管理
/// 3. Cookie 加密存储
/// 4. API 代理
class BilibiliAuthProvider extends ChangeNotifier {
  final DioProvider _dioProvider;

  // ==================== 状态变量 ====================

  /// 当前状态
  bool _isLoggedIn = false;

  /// 当前 Token
  String? _token;

  /// 绑定二维码
  String? _qrcodeUrl;

  /// 过期时间
  DateTime? _expiresAt;

  /// 用户号信息
  String? _mid;

  /// 加载状态
  bool _isLoading = false;

  /// 错误信息
  String? _errorMessage;

  // ==================== Getters ====================

  bool get isLoggedIn => _isLoggedIn;
  String? get qrCodeUrl => _qrcodeUrl;
  DateTime? get expiresAt => _expiresAt;
  String? get mid => _mid;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== 初始化 ====================

  BilibiliAuthProvider({DioProvider? dioProvider})
      : _dioProvider = dioProvider ?? DioProvider.instance;

  /// 初始化（从本地存储加载）
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('bilibiliToken');
      _mid = prefs.getString('bilibiliMid');

      if (_token != null && _mid != null) {
        _isLoggedIn = true;
        AppLogger.debug('BilibiliAuthProvider', '从本地存储恢复登录状态');
      }
    } catch (e) {
      AppLogger.error('BilibiliAuthProvider', '初始化异常: $e');
    }
  }

  // ==================== QR 码登录 ====================

  /// 获取登录 QR 码
  Future<Map<String, dynamic>?> getQRCode() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      AppLogger.info('BilibiliAuthProvider', '开始获取QR码');

      final response = await _dioProvider.get('/bilibili/qrcode');

      if (response['success'] == true && response['data'] != null) {
        _qrcodeUrl = response['data']['qrCodeUrl'];
        _expiresAt = DateTime.parse(response['data']['expiresAt']);
        _mid = response['data']['mid'];
        AppLogger.info('BilibiliAuthProvider', 'QR码获取成功');
        notifyListeners();

        return {
          'qrCodeUrl': _qrcodeUrl,
          'expiresAt': _expiresAt,
          'mid': _mid,
        };
      } else {
        throw Exception(response['message'] ?? 'QR码获取失败');
      }
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliAuthProvider', 'QR码获取异常: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 验证二维码
  Future<bool> verifyQRCode() async {
    if (_qrcodeUrl == null) {
      AppLogger.debug('BilibiliAuthProvider', 'QR码URL为空，无法验证');
      _errorMessage = 'QR码URL为空';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _dioProvider.get('/bilibili/verify-qr');

      if (response['success'] == true && response['data'] != null) {
        _token = response['data']['token'];
        _mid = response['data']['mid'];
        _isLoggedIn = true;

        // 保存到本地存储
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bilibiliToken', _token!);
        await prefs.setString('bilibiliMid', _mid!);

        AppLogger.info('BilibiliAuthProvider', '二维码验证成功');
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? '二维码验证失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('BilibiliAuthProvider', '二维码验证异常: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 检查登录状态
  Future<Map<String, dynamic>> checkLoginStatus() async {
    try {
      if (_token == null || _mid == null) {
        return {
          'isLoggedIn': false,
          'mid': '',
          'qrCodeUrl': '',
          'expiresAt': null,
        };
      }

      final response = await _dioProvider.get('/bilibili/check-login');

      if (response['success'] == true) {
        return {
          'isLoggedIn': true,
          'mid': _mid,
          'qrCodeUrl': _qrcodeUrl,
          'expiresAt': _expiresAt,
        };
      } else {
        // 登录失效
        await logout();
        return {
          'isLoggedIn': false,
          'mid': '',
          'qrCodeUrl': '',
          'expiresAt': null,
        };
      }
    } catch (e) {
      AppLogger.error('BilibiliAuthProvider', '检查登录状态异常: $e');
      return {
        'isLoggedIn': false,
        'mid': '',
        'qrCodeUrl': '',
        'expiresAt': null,
      };
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      _isLoggedIn = false;
      _token = null;
      _qrcodeUrl = null;
      _expiresAt = null;
      _mid = null;
      _errorMessage = null;

      // 清空本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bilibiliToken');
      await prefs.remove('bilibiliMid');

      notifyListeners();
      AppLogger.info('BilibiliAuthProvider', '登出完成');
    } catch (e) {
      AppLogger.error('BilibiliAuthProvider', '登出异常: $e');
      rethrow;
    }
  }

  // ==================== 释放资源 ====================

  @override
  void dispose() {
    super.dispose();
  }
}