import 'package:flutter/material.dart';
import 'app_logger.dart';

/// 应用路由观察器
///
/// 功能：
/// - 记录所有页面导航事件
/// - 跟踪用户在应用中的路径
/// - 支持页面停留时间统计
///
/// 使用方式：
/// 1. 在 MaterialApp 中添加观察器：
/// ```dart
/// MaterialApp(
///   navigatorObservers: [appRouteObserver],
///   ...
/// )
/// ```
///
/// 2. 在页面中注册（可选，用于获取用户 ID）：
/// ```dart
/// @override
/// void didChangeDependencies() {
///   super.didChangeDependencies();
///   final userId = context.read<AuthProvider>().userId;
///   appRouteObserver.userId = userId;
/// }
/// ```
class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  /// 当前用户 ID（可选）
  String? userId;

  /// 当前激活的页面路径
  String? _currentRoute;
  DateTime? _routeEnterTime;

  AppRouteObserver({this.userId});

  /// 设置当前用户 ID
  set setUserId(String? id) {
    userId = id;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRouteChange('didPush', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logRouteChange('didPop', previousRoute, route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logRouteChange('didReplace', newRoute, oldRoute);
  }

  void _logRouteChange(
    String action,
    Route<dynamic>? toRoute,
    Route<dynamic>? fromRoute,
  ) {
    final from = fromRoute?.settings.name ?? _getRouteName(fromRoute);
    final to = toRoute?.settings.name ?? _getRouteName(toRoute);

    if (_currentRoute != to && to != 'Unknown') {
      // 记录前一个页面的停留时间
      if (_routeEnterTime != null && _currentRoute != null) {
        final duration = DateTime.now().difference(_routeEnterTime!);
        AppLogger.debug(
          'RouteObserver',
          '页面停留: $_currentRoute (${duration.inSeconds}s)',
        );
      }

      // 记录导航事件
      AppLogger.logNavigation(from, to, userId: userId);

      _currentRoute = to;
      _routeEnterTime = DateTime.now();
    }
  }

  /// 从路由获取友好的页面名称
  String _getRouteName(Route<dynamic>? route) {
    if (route == null) return 'Unknown';

    final settings = route.settings;
    if (settings.name != null) {
      return settings.name!;
    }

    // 尝试从 Widget 类型获取名称
    if (route is MaterialPageRoute) {
      final builder = route.builder;
      // 这里可以添加更多逻辑来提取页面名称
      return 'MaterialPage';
    }

    return route.runtimeType.toString();
  }
}

/// 全局路由观察器实例
final appRouteObserver = AppRouteObserver();
