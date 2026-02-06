/// Riverpod 3.0 AsyncValue 扩展工具
///
/// 用途：简化 AsyncValue 的常用操作
///
/// 官方文档: https://riverpod.dev/docs/whats_new
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AsyncValue 扩展方法
///
/// 简化 AsyncValue 的常用操作
extension AsyncValueX<T> on AsyncValue<T> {
  /// 是否加载中
  bool get isLoading => this is AsyncLoading;

  /// 是否错误状态
  bool get isError => this is AsyncError;

  /// 是否数据状态
  bool get isData => this is AsyncData;

  /// 获取数据值或 null
  ///
  /// 使用示例：
  /// ```dart
  /// final downloads = asyncState.valueOrNull?.downloads ?? [];
  /// ```
  T? get valueOrNull => whenOrNull(data: (value) => value);

  /// 获取错误对象或 null
  Object? get errorOrNull => whenOrNull(error: (error, _) => error);

  /// 获取错误消息或 null
  String? get errorMessageOrNull => whenOrNull(
        error: (error, _) => error.toString(),
      );
}
