import 'dart:async';
import 'package:demo/data/datasources/remote/bilibili_api_datasource.dart';
import 'package:flutter/foundation.dart';
import 'package:demo/core/utils/app_logger.dart';

/// QR码登录状态管理Provider
///
/// 职责：
/// - QR码生成和状态管理
/// - 轮询逻辑和生命周期管理
/// - 登录成功/失败处理
class QRLoginProvider extends ChangeNotifier {
  BilibiliApiService? _apiService;

  // ==================== 状态变量 ====================

  /// QR码登录状态
  String _qrLoginStatus = 'none'; // none|pending|scanned|success|expired
  String? _qrcodeKey;
  String? _qrcodeUrl;
  DateTime? _qrExpiresAt;
  Timer? _qrPollTimer;

  /// 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== Getters ====================

  String get qrLoginStatus => _qrLoginStatus;
  String? get qrcodeKey => _qrcodeKey;
  String? get qrcodeUrl => _qrcodeUrl;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// QR码是否有效（未过期）
  bool get isQrValid => _qrExpiresAt != null && DateTime.now().isBefore(_qrExpiresAt!);

  /// 是否正在轮询
  bool get isPolling => _qrPollTimer != null && _qrPollTimer!.isActive;

  // ==================== 初始化 ====================

  /// 更新认证Token
  void updateToken(String? token) {
    _apiService = BilibiliApiService();
    AppLogger.debug('QRLoginProvider', 'Token updated: ${token != null ? "set" : "cleared"}');
  }

  // ==================== QR码登录 ====================

  /// 开始QR码登录流程
  Future<bool> startQRLogin() async {
    if (_apiService == null) {
      _errorMessage = 'BilibiliApiService not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _apiService!.getQRCode();
      _qrcodeKey = result['qrcodeKey'];
      _qrcodeUrl = result['qrcodeUrl'];
      _qrExpiresAt = result['expiresAt'];
      _qrLoginStatus = 'pending';

      // 开始轮询
      _startQRPolling();

      AppLogger.info('QRLoginProvider', 'QR login started');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      AppLogger.error('QRLoginProvider', 'QR login start error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 开始轮询QR码状态
  void _startQRPolling() {
    _stopQRPolling();
    _qrPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      // 确保当前 timer 是最新创建的，防止旧 timer 继续执行
      if (_qrPollTimer == null || timer != _qrPollTimer) {
        timer.cancel();
        return;
      }

      if (!isQrValid) {
        _qrLoginStatus = 'expired';
        _stopQRPolling();
        notifyListeners();
        return;
      }

      try {
        await _checkQRStatus();
      } catch (e) {
        AppLogger.error('QRLoginProvider', 'QR polling error: $e');
      }
    });
  }

  /// 停止轮询
  void _stopQRPolling() {
    _qrPollTimer?.cancel();
    _qrPollTimer = null;
  }

  /// 检查QR码状态
  Future<void> _checkQRStatus() async {
    if (_qrcodeKey == null) return;

    try {
      final result = await _apiService!.checkQRLoginStatus(_qrcodeKey!);
      _qrLoginStatus = result['status'] ?? 'pending';

      if (_qrLoginStatus == 'success') {
        _stopQRPolling();
        AppLogger.debug('QRLoginProvider', 'QR login success');
      }

      notifyListeners();
    } catch (e) {
      AppLogger.error('QRLoginProvider', 'QR check error: $e');
    }
  }

  /// 取消QR码登录
  void cancelQRLogin() {
    _stopQRPolling();
    _qrLoginStatus = 'none';
    _qrcodeKey = null;
    _qrcodeUrl = null;
    _qrExpiresAt = null;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==================== 资源释放 ====================

  @override
  void dispose() {
    _stopQRPolling();
    super.dispose();
  }
}
