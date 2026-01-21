import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../core/errors/failures.dart';

/// Presentation 层基类 Provider
///
/// 提供统一的状态管理和错误处理
abstract class BaseProvider extends ChangeNotifier {
  /// 是否正在加载
  bool _isLoading = false;

  /// 错误消息
  Failure? _failure;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 是否有错误
  bool get hasError => _failure != null;

  /// 错误消息
  String? get errorMessage => _failure?.message;

  /// 错误代码
  String? get errorCode => _failure?.code;

  /// 设置加载状态
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// 设置错误（protected 方法，子类可调用）
  void setError(Failure? failure) {
    _failure = failure;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _failure = null;
    notifyListeners();
  }

  /// 执行异步操作（统一错误处理）
  ///
  /// 自动处理加载状态和错误，返回 [Either<Failure, T>] 结果
  /// 返回 null 表示操作失败且已处理错误
  /// 返回非 null 表示操作成功
  Future<T?> executeAsync<T>(Future<Either<Failure, T>> Function() operation) async {
    _setLoading(true);
    _failure = null;

    try {
      final result = await operation();

      return result.fold(
        (failure) {
          _failure = failure;
          notifyListeners();
          return null;
        },
        (data) {
          return data;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  /// 执行不带返回值的异步操作
  Future<bool> executeVoidAsync(Future<Either<Failure, void>> Function() operation) async {
    _setLoading(true);
    _failure = null;

    try {
      final result = await operation();

      return result.fold(
        (failure) {
          _failure = failure;
          notifyListeners();
          return false;
        },
        (_) {
          return true;
        },
      );
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _failure = null;
    super.dispose();
  }
}
