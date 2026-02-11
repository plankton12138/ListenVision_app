import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/state/state_utils.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/api/backend_api_client.dart';
import '../../../models/platform_account.dart' show NeteaseUserInfo;

part 'netease_auth_viewmodel.freezed.dart';
part 'netease_auth_viewmodel.g.dart';

enum NeteaseQRLoginStatus {
  none,
  pending,
  scanned,
  success,
  expired,
  failed,
}

@freezed
abstract class NeteaseAuthState with _$NeteaseAuthState {
  const factory NeteaseAuthState.initial() = NeteaseAuthStateInitial;
  const factory NeteaseAuthState.loading() = NeteaseAuthStateLoading;
  const factory NeteaseAuthState.bound({
    required NeteaseUserInfo account,
  }) = NeteaseAuthStateBound;
  const factory NeteaseAuthState.unbound() = NeteaseAuthStateUnbound;
  const factory NeteaseAuthState.qrLogin({
    required NeteaseQRLoginStatus status,
    String? qrimg,
    String? qrurl,
    String? key,
  }) = NeteaseAuthStateQRLogin;
  const factory NeteaseAuthState.error({
    required String message,
  }) = NeteaseAuthStateError;
}

@Riverpod(keepAlive: true)
class NeteaseAuthViewModel extends _$NeteaseAuthViewModel {
  BackendApiClient? _apiClient;
  Timer? _qrPollTimer;

  @override
  Future<NeteaseAuthState> build() async {
    _apiClient = BackendApiClient();

    ref.onDispose(() {
      _stopQRPolling();
    });

    try {
      AppLogger.info('NeteaseAuthViewModel', '初始化，检查绑定状态');
      return await _checkBindStatus();
    } catch (e) {
      AppLogger.error('NeteaseAuthViewModel', '初始化失败: $e');
      return const NeteaseAuthState.unbound();
    }
  }

  Future<NeteaseAuthState> _checkBindStatus() async {
    try {
      final statusData = await _apiClient!.getNeteaseStatus();
      final isBound = statusData['isBound'] as bool? ?? false;

      if (isBound) {
        final userInfo = statusData['userInfo'] as Map<String, dynamic>?;
        if (userInfo != null) {
          final account = NeteaseUserInfo.fromJson(userInfo);
          AppLogger.info('NeteaseAuthViewModel', '网易云已绑定: ${account.username}');
          return NeteaseAuthState.bound(account: account);
        }
      }

      return const NeteaseAuthState.unbound();
    } catch (e) {
      AppLogger.error('NeteaseAuthViewModel', '检查绑定状态失败: $e');
      return const NeteaseAuthState.unbound();
    }
  }

  Future<bool> startQRLogin() async {
    _stopQRPolling();

    try {
      if (!ref.mounted) return false;
      state = const AsyncData(NeteaseAuthState.qrLogin(
        status: NeteaseQRLoginStatus.pending,
      ));

      AppLogger.info('NeteaseAuthViewModel', '开始获取网易云QR码');

      final result = await _apiClient!.getNeteaseQRCode();

      if (!ref.mounted) return false;
      state = AsyncData(NeteaseAuthState.qrLogin(
        status: NeteaseQRLoginStatus.pending,
        qrimg: result['qrimg'],
        qrurl: result['qrurl'],
        key: result['key'],
      ));

      _startQRPolling(result['key']);

      return true;
    } catch (e) {
      AppLogger.error('NeteaseAuthViewModel', '获取QR码失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  void _startQRPolling(String key) {
    _stopQRPolling();

    _qrPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (timer != _qrPollTimer) {
        timer.cancel();
        return;
      }

      await _checkQRStatus(key);
    });
  }

  void _stopQRPolling() {
    _qrPollTimer?.cancel();
    _qrPollTimer = null;
  }

  Future<void> _checkQRStatus(String key) async {
    try {
      final result = await _apiClient!.checkNeteaseQRCode(key);
      final statusStr = result['status'] as String? ?? 'pending';

      final status = switch (statusStr) {
        'scanned' => NeteaseQRLoginStatus.scanned,
        'success' => NeteaseQRLoginStatus.success,
        'failed' => NeteaseQRLoginStatus.failed,
        'expired' => NeteaseQRLoginStatus.expired,
        _ => NeteaseQRLoginStatus.pending,
      };

      _updateQRStatus(status);

      if (status == NeteaseQRLoginStatus.success) {
        _stopQRPolling();
        await _handleLoginSuccess();
      } else if (status == NeteaseQRLoginStatus.failed ||
          status == NeteaseQRLoginStatus.expired) {
        _stopQRPolling();
      }
    } catch (e) {
      AppLogger.error('NeteaseAuthViewModel', '检查QR状态失败: $e');
    }
  }

  void _updateQRStatus(NeteaseQRLoginStatus status) {
    if (!ref.mounted) return;
    final current = state.valueOrNull;
    current?.maybeWhen(
      qrLogin: (_, qrimg, qrurl, key) {
        state = AsyncData(NeteaseAuthState.qrLogin(
          status: status,
          qrimg: qrimg,
          qrurl: qrurl,
          key: key,
        ));
        AppLogger.debug('NeteaseAuthViewModel', 'QR状态更新: $status');
      },
      orElse: () {},
    );
  }

  Future<void> _handleLoginSuccess() async {
    try {
      final statusData = await _apiClient!.getNeteaseStatus();
      final userInfo = statusData['userInfo'] as Map<String, dynamic>?;

      if (userInfo == null) {
        if (!ref.mounted) return;
        state = const AsyncData(NeteaseAuthState.error(message: '获取用户信息失败'));
        return;
      }

      final account = NeteaseUserInfo.fromJson(userInfo);

      AppLogger.logUserAction(
        'NeteaseAuth',
        '网易云绑定成功',
        parameters: {
          'id': account.id,
          'username': account.username,
        },
      );

      if (!ref.mounted) return;
      state = AsyncData(NeteaseAuthState.bound(account: account));
    } catch (e) {
      AppLogger.error('NeteaseAuthViewModel', '处理登录成功失败: $e');
      if (!ref.mounted) return;
      state = AsyncError(e, StackTrace.current);
    }
  }

  void cancelQRLogin() {
    _stopQRPolling();
    state = const AsyncData(NeteaseAuthState.unbound());
    AppLogger.debug('NeteaseAuthViewModel', '取消QR登录');
  }

  Future<bool> unbind() async {
    try {
      AppLogger.info('NeteaseAuthViewModel', '解绑网易云账号');

      await _apiClient!.unbindNetease();

      AppLogger.logUserAction(
        'NeteaseAuth',
        '网易云解绑成功',
      );

      if (!ref.mounted) return false;
      state = const AsyncData(NeteaseAuthState.unbound());
      return true;
    } catch (e) {
      AppLogger.error('NeteaseAuthViewModel', '解绑失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current is NeteaseAuthStateError) {
      state = const AsyncData(NeteaseAuthState.unbound());
    }
  }

  NeteaseUserInfo? getBoundAccount() {
    return state.valueOrNull?.maybeWhen(
      bound: (account) => account,
      orElse: () => null,
    );
  }

  bool get isBound {
    return state.valueOrNull?.maybeWhen(
      bound: (_) => true,
      orElse: () => false,
    ) ?? false;
  }

  Future<void> reset() async {
    _stopQRPolling();
    if (!ref.mounted) return;
    state = const AsyncData(NeteaseAuthState.unbound());
    AppLogger.info('NeteaseAuthViewModel', '状态已重置');
  }
}

@riverpod
NeteaseUserInfo? boundNeteaseAccount(Ref ref) {
  return ref.watch(neteaseAuthViewModelProvider.notifier).getBoundAccount();
}

@riverpod
bool isNeteaseBound(Ref ref) {
  return ref.watch(neteaseAuthViewModelProvider.notifier).isBound;
}
