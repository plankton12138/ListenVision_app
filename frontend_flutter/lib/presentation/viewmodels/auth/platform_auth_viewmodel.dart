import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/state/state_utils.dart';
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
@Riverpod(keepAlive: true)
class PlatformAuthViewModel extends _$PlatformAuthViewModel {
  BilibiliApiClient? _bilibiliApi;
  SecureStorageService? _secureStorage;

  /// QR 码轮询定时器
  Timer? _qrPollTimer;

  @override
  Future<PlatformAuthState> build() async {
    _bilibiliApi = BilibiliApiClient();
    _secureStorage = SecureStorageService.instance;

    // 设置清理回调
    ref.onDispose(() {
      _stopQRPolling();
    });

    try {
      AppLogger.info('PlatformAuthViewModel', '初始化，检查B站绑定状态');
      return await _checkBilibiliBindStatus();
    } catch (e) {
      AppLogger.error('PlatformAuthViewModel', '初始化失败: $e');
      return const PlatformAuthState.unbound();
    }
  }

  /// 检查 B站 绑定状态
  Future<PlatformAuthState> _checkBilibiliBindStatus() async {
    try {
      final isBound = await _secureStorage!.isBilibiliBound();
      if (isBound) {
        final accountData = await _secureStorage!.getBilibiliAccount();
        if (accountData != null) {
          final account = BilibiliUserInfo.fromJson(accountData);
          AppLogger.info('PlatformAuthViewModel', 'B站已绑定: ${account.uname}');
          return PlatformAuthState.bound(account: account);
        }
      }
      return const PlatformAuthState.unbound();
    } catch (e) {
      AppLogger.error('PlatformAuthViewModel', '检查B站绑定状态失败: $e');
      return const PlatformAuthState.unbound();
    }
  }

  /// 开始 QR 码登录
  Future<bool> startQRLogin() async {
    _stopQRPolling();

    try {
      if (!ref.mounted) return false;
      state = const AsyncData(PlatformAuthState.qrLogin(
        status: QRLoginStatus.pending,
      ));

      AppLogger.info('PlatformAuthViewModel', '开始获取B站QR码');

      final result = await _bilibiliApi!.getQRCode();

      if (!ref.mounted) return false;
      state = AsyncData(PlatformAuthState.qrLogin(
        status: QRLoginStatus.pending,
        qrcodeUrl: result['qrcodeUrl'],
        qrcodeKey: result['qrcodeKey'],
        expiresAt: result['expiresAt'],
      ));

      // 开始轮询
      _startQRPolling(result['qrcodeKey']!, result['expiresAt']!);

      return true;
    } catch (e) {
      AppLogger.error('PlatformAuthViewModel', '获取QR码失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
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
      final result = await _bilibiliApi!.checkQRLoginStatus(qrcodeKey);
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
    if (!ref.mounted) return;
    final current = state.valueOrNull;
    current?.maybeWhen(
      qrLogin: (_, qrcodeUrl, qrcodeKey, expiresAt) {
        state = AsyncData(PlatformAuthState.qrLogin(
          status: status,
          qrcodeUrl: qrcodeUrl,
          qrcodeKey: qrcodeKey,
          expiresAt: expiresAt,
        ));
        AppLogger.debug('PlatformAuthViewModel', 'QR状态更新: $status');
      },
      orElse: () {},
    );
  }

  /// 处理登录成功
  Future<void> _handleLoginSuccess(Map<String, dynamic>? userInfo) async {
    if (userInfo == null) {
      if (!ref.mounted) return;
      state = const AsyncData(PlatformAuthState.error(message: '获取用户信息失败'));
      return;
    }

    try {
      final account = BilibiliUserInfo.fromJson(userInfo);

      // 保存到安全存储
      await _secureStorage!.setBilibiliAccount(userInfo);
      await _secureStorage!.setBilibiliBound(true);

      AppLogger.logUserAction(
        'PlatformAuth',
        'B站绑定成功',
        parameters: {
          'mid': account.mid,
          'uname': account.uname,
        },
        userId: account.mid,
      );

      if (!ref.mounted) return;
      state = AsyncData(PlatformAuthState.bound(account: account));
    } catch (e) {
      AppLogger.error('PlatformAuthViewModel', '保存绑定信息失败: $e');
      if (!ref.mounted) return;
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// 取消 QR 码登录
  void cancelQRLogin() {
    _stopQRPolling();
    state = const AsyncData(PlatformAuthState.unbound());
    AppLogger.debug('PlatformAuthViewModel', '取消QR登录');
  }

  /// 解绑B站账号
  Future<bool> unbind() async {
    try {
      AppLogger.info('PlatformAuthViewModel', '解绑B站账号');

      // 调用后端解绑接口
      await _bilibiliApi!.unbindAccount();

      // 清除本地存储
      await _secureStorage!.clearBilibiliAccount();
      await _secureStorage!.clearBilibiliCookie();
      await _secureStorage!.setBilibiliBound(false);

      AppLogger.logUserAction(
        'PlatformAuth',
        'B站解绑成功',
        parameters: {'platform': 'bilibili'},
      );

      if (!ref.mounted) return false;
      state = const AsyncData(PlatformAuthState.unbound());
      return true;
    } catch (e) {
      AppLogger.error('PlatformAuthViewModel', '解绑失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// 清除错误状态
  void clearError() {
    final current = state.valueOrNull;
    if (current is PlatformAuthStateError) {
      state = const AsyncData(PlatformAuthState.unbound());
    }
  }

  /// 获取当前绑定的账号
  BilibiliUserInfo? getBoundAccount() {
    return state.valueOrNull?.maybeWhen(
      bound: (account) => account,
      orElse: () => null,
    );
  }

  /// 是否已绑定
  bool get isBound {
    return state.valueOrNull?.maybeWhen(
      bound: (_) => true,
      orElse: () => false,
    ) ?? false;
  }
}

/// 当前绑定的B站账号 Provider
@riverpod
BilibiliUserInfo? boundBilibiliAccount(Ref ref) {
  return ref.watch(platformAuthViewModelProvider.notifier).getBoundAccount();
}

/// 是否已绑定B站 Provider
@riverpod
bool isBilibiliBound(Ref ref) {
  return ref.watch(platformAuthViewModelProvider.notifier).isBound;
}
