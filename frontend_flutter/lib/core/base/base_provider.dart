import 'package:flutter/foundation.dart';

/// Provider基类
///
/// 提供统一的状态管理和错误处理
/// 所有Provider应继承此类以获得一致的行为
abstract class BaseProvider extends ChangeNotifier {
  // ==================== 状态变量 ====================

  bool _isLoading = false;
  String? _errorMessage;

  // ==================== Getters ====================

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isReady => !_isLoading && !hasError;

  // ==================== 状态管理 ====================

  /// 设置加载状态
  @protected
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 设置错误信息
  @protected
  void setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      notifyListeners();
    }
  }

  /// 清除错误
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// 设置就绪状态（清除加载和错误）
  @protected
  void setReady() {
    final changed = _isLoading || _errorMessage != null;
    _isLoading = false;
    _errorMessage = null;
    if (changed) notifyListeners();
  }

  // ==================== 异步操作包装 ====================

  /// 执行异步操作的包装方法
  ///
  /// 统一处理加载状态、错误清除和异常捕获
  /// 返回操作结果，null表示失败
  @protected
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    void Function(T)? onSuccess,
    void Function(dynamic)? onError,
    bool showError = true,
  }) async {
    try {
      setLoading(true);
      clearError();

      final result = await operation();

      if (onSuccess != null) {
        onSuccess(result);
      }

      return result;
    } catch (e) {
      if (showError) {
        setError(e.toString());
      }
      if (onError != null) {
        onError(e);
      }
      debugPrint('[$runtimeType] executeAsync error: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// 静默执行异步操作（不显示错误状态）
  @protected
  Future<T?> executeSilent<T>(Future<T> Function() operation) async {
    return executeAsync<T>(
      operation,
      showError: false,
    );
  }

  // ==================== 防抖处理 ====================

  DateTime? _lastOperationTime;
  static const _debounceDelay = Duration(milliseconds: 500);

  /// 防抖执行操作
  ///
  /// 在指定时间内只执行最后一次操作
  @protected
  Future<void> debouncedExecute(Future<void> Function() operation) async {
    final now = DateTime.now();
    if (_lastOperationTime != null &&
        now.difference(_lastOperationTime!) < _debounceDelay) {
      return;
    }
    _lastOperationTime = now;
    await operation();
  }

  // ==================== 资源释放 ====================

  @override
  void dispose() {
    _errorMessage = null;
    super.dispose();
  }
}
