import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/api/bilibili_api_client.dart';
import '../../../models/platform_account.dart' show BilibiliUserInfo;

part 'platform_auth_viewmodel.freezed.dart';
part 'platform_auth_viewmodel.g.dart';

/// QR 码登录状态
enum QRLoginStatus {
  /// 无状态
  none,

  /// 等待扫描
  pending,

  /// 已扫描
  scanned,

  /// 登录成功
  success,

  /// 已过期
  expired,

  /// 登录失败
  failed,
}

/// 平台认证状态
@freezed
class PlatformAuthState with _$PlatformAuthState {
  /// 初始状态
  const factory PlatformAuthState.initial() = PlatformAuthStateInitial;

  /// 加载中
  const factory PlatformAuthState.loading() = PlatformAuthStateLoading;

  /// 已绑定B站账号
  const factory PlatformAuthState.bound({
    required BilibiliUserInfo account,
  }) = PlatformAuthStateBound;

  /// 未绑定平台账号
  const factory PlatformAuthState.unbound() = PlatformAuthStateUnbound;

  /// QR 码登录中
  const factory PlatformAuthState.qrLogin({
    required QRLoginStatus status,
    String? qrcodeUrl,
    String? qrcodeKey,
    DateTime? expiresAt,
  }) = PlatformAuthStateQRLogin;

  /// 错误
  const factory PlatformAuthState.error({
    required String message,
  }) = PlatformAuthStateError;
}

/// 平台认证 ViewModel
///
/// 负责第三方平台（B站）的认证
class PlatformAuthViewModel extends StateNotifier<PlatformAuthState> {
  final BilibiliApiClient _bilibiliApi;
  final SecureStorageService _secureStorage;

  /// QR 码轮询定时器
  Timer? _qrPollTimer;

  PlatformAuthViewModel({
    BilibiliApiClient? bilibiliApi,
    SecureStorageService? secureStorage,
  })  : _bilibiliApi = bilibiliApi ?? BilibiliApiClient(),
        _secureStorage = secureStorage ?? SecureStorageService.instance,
        super(const PlatformAuthState.initial()) {
    _initialize();
  }

  /// 初始化：检查绑定状态
  Future<void> _initialize() async {
    try {
      AppLogger.info('PlatformAuthViewModel', '初始化，检查B站绑定状态');
      await _checkBilibiliBindStatus();
    } catch (e) {
      AppLogger.error('PlatformAuthViewModel', '初始化失败: $e');
      state = const PlatformAuthState.unbound();
    }
  }

  /// 检查 B站 绑定状态
  Future<void> _checkBilibiliBindStatus() async {
    try {
      final isBound = await _secureStorage.isBilibiliBound();
      if (isBound) {
        final accountData = await _secureStorage.getBilibiliAccount();
        if (accountData != null) {
          final account = BilibiliUserInfo.fromJson(accountData);
          state = PlatformAuthState.bound(account: account);
          AppLogger.info('PlatformAuthViewModel', 'B站已绑定: ${account.uname}');
          return;
        }
      }
      state = const PlatformAuthState.unbound();
    } catch (e) {
      AppLogger.error('PlatformAuthViewModel', '检查B站绑定状态失败: $e');
      state = const PlatformAuthState.unbound();
    }
  }

  /// 开始 QR 码登录
  Future<bool> startQRLogin() async {
    _stopQRPolling();

    try {
      state = const PlatformAuthState.qrLogin(
        status: QRLoginStatus.pending,
      );

      AppLogger.info('PlatformAuthViewModel', '开始获取B站QR码');

      final result = await _bilibiliApi.getQRCode();

      state = PlatformAuthState.qrLogin(
        status: QRLoginStatus.pending,
        qrcodeUrl: result['qrcodeUrl'],
        qrcodeKey: result['qrcodeKey'],
        expiresAt: result['expiresAt'],
      );

      // 开始轮询
      _startQRPolling(result['qrcodeKey']!, result['expiresAt']!);

      return true;
    } catch (e) {
      AppLogger.error('PlatformAuthViewModel', '获取QR码失败: $e');
      state = PlatformAuthState.error(message: e.toString());
      return false;
    }
  }

  /// 开始轮询 QR 码状态
  void _startQRPolling(String qrcodeKey, DateTime expiresAt) {
    _stopQRPolling();

    _qrPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (timer != _qrPollTimer) {
        timer.cancel();
        return;
      }

      // 检查是否过期
      if (DateTime.now().isAfter(expiresAt)) {
        _updateQRStatus(QRLoginStatus.expired);
        _stopQRPolling();
        return;
      }

      _checkQRStatus(qrcodeKey);
    });
  }

  /// 停止轮询
  void _stopQRPolling() {
    _qrPollTimer?.cancel();
    _qrPollTimer = null;
  }

  /// 检查 QR 码状态
  Future<void> _checkQRStatus(String qrcodeKey) async {
    try {
      final result = await _bilibiliApi.checkQRLoginStatus(qrcodeKey);
      final statusStr = result['status'] as String? ?? 'pending';

      final status = switch (statusStr) {
        'scanned' => QRLoginStatus.scanned,
        'success' => QRLoginStatus.success,
        'failed' => QRLoginStatus.failed,
        'expired' => QRLoginStatus.expired,
        _ => QRLoginStatus.pending,
      };

      _updateQRStatus(status, userInfo: result['userInfo']);

      if (status == QRLoginStatus.success) {
        _stopQRPolling();
        await _handleLoginSuccess(result['userInfo']);
      } else if (status == QRLoginStatus.failed ||
          status == QRLoginStatus.expired) {
        _stopQRPolling();
      }
    } catch (e) {
      AppLogger.error('PlatformAuthViewModel', '检查QR状态失败: $e');
    }
  }

  /// 更新 QR 状态
  void _updateQRStatus(QRLoginStatus status, {Map<String, dynamic>? userInfo}) {
    state.maybeWhen(
      qrLogin: (_, qrcodeUrl, qrcodeKey, expiresAt) {
        state = PlatformAuthState.qrLogin(
          status: status,
          qrcodeUrl: qrcodeUrl,
          qrcodeKey: qrcodeKey,
          expiresAt: expiresAt,
        );
        AppLogger.debug('PlatformAuthViewModel', 'QR状态更新: $status');
      },
      orElse: () {},
    );
  }

  /// 处理登录成功
  Future<void> _handleLoginSuccess(Map<String, dynamic>? userInfo) async {
    if (userInfo == null) {
      state = const PlatformAuthState.error(message: '获取用户信息失败');
      return;
    }

    try {
      final account = BilibiliUserInfo.fromJson(userInfo);

      // 保存到安全存储
      await _secureStorage.setBilibiliAccount(userInfo);
      await _secureStorage.setBilibiliBound(true);

      AppLogger.logUserAction(
        'PlatformAuth',
        'B站绑定成功',
        parameters: {
          'mid': account.mid,
          'uname': account.uname,
        },
        userId: account.mid,
      );

      state = PlatformAuthState.bound(account: account);
    } catch (e) {
      AppLogger.error('PlatformAuthViewModel', '保存绑定信息失败: $e');
      state = PlatformAuthState.error(message: e.toString());
    }
  }

  /// 取消 QR 码登录
  void cancelQRLogin() {
    _stopQRPolling();
    state = const PlatformAuthState.unbound();
    AppLogger.debug('PlatformAuthViewModel', '取消QR登录');
  }

  /// 解绑B站账号
  Future<bool> unbind() async {
    try {
      AppLogger.info('PlatformAuthViewModel', '解绑B站账号');

      // 调用后端解绑接口
      await _bilibiliApi.unbindAccount();

      // 清除本地存储
      await _secureStorage.clearBilibiliAccount();
      await _secureStorage.clearBilibiliCookie();
      await _secureStorage.setBilibiliBound(false);

      AppLogger.logUserAction(
        'PlatformAuth',
        'B站解绑成功',
        parameters: {'platform': 'bilibili'},
      );

      state = const PlatformAuthState.unbound();
      return true;
    } catch (e) {
      AppLogger.error('PlatformAuthViewModel', '解绑失败: $e');
      state = PlatformAuthState.error(message: e.toString());
      return false;
    }
  }

  /// 获取当前状态（公开 getter）
  PlatformAuthState get platformAuthState => state;

  /// 获取当前绑定的账号
  BilibiliUserInfo? getBoundAccount() {
    return state.maybeWhen(
      bound: (account) => account,
      orElse: () => null,
    );
  }

  /// 是否已绑定
  bool get isBound {
    return state.maybeWhen(
      bound: (_) => true,
      orElse: () => false,
    );
  }

  /// 清除错误状态
  void clearError() {
    state.maybeWhen(
      error: (_) => state = const PlatformAuthState.unbound(),
      orElse: () {},
    );
  }

  @override
  void dispose() {
    _stopQRPolling();
    super.dispose();
  }
}

/// Provider 定义
@riverpod
PlatformAuthViewModel platformAuthViewModel(PlatformAuthViewModelRef ref) {
  return PlatformAuthViewModel();
}

/// 当前绑定的B站账号 Provider
@riverpod
BilibiliUserInfo? boundBilibiliAccount(BoundBilibiliAccountRef ref) {
  return ref.watch(platformAuthViewModelProvider).getBoundAccount();
}

/// 是否已绑定B站 Provider
@riverpod
bool isBilibiliBound(IsBilibiliBoundRef ref) {
  return ref.watch(platformAuthViewModelProvider).isBound;
}
