# 网络状态监测与提示实现方案

**方案制定日期**: 2026-02-16
**关联主计划**: architecture-compliance-fix-plan.md
**优先级**: P1

---
## 一、目标

实现网络状态实时监测功能，当网络断开或恢复时能及时提示用户，并在网络请求前检查连接状态，提供更好的用户体验。

## 二、当前问题分析

### 2.1 网络监测功能缺失
系统中已定义了网络错误检测方法但未实际使用：
```dart
// core/utils/error_handler.dart:296
static bool isNetworkError(dynamic error) {
  if (error is NetworkException) {
    return true;
  }
  if (error is DioException) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }
  return false;
}
```

### 2.2 缺乏主动网络状态监测
目前没有主动监测网络状态变化的机制，用户无法提前知道网络状况。

### 2.3 网络断链提示不完善
没有在网络断开时给用户明确提示，也没有在网络恢复时通知用户。

## 三、解决方案设计

### 3.1 核心思路
1. 使用`connectivity_plus`插件实现实时网络状态监测
2. 创建Riverpod Provider管理网络状态
3. 在网络状态变化时提供用户提示
4. 在网络请求前检查连接状态

### 3.2 实现架构
```
网络状态Provider -> 监听网络变化 -> 状态更新 -> UI响应
                 -> 网络请求拦截 -> 状态检查 -> 允许/拒绝请求
```

## 四、详细实现步骤

### 4.1 添加依赖

**文件**: `pubspec.yaml`

添加`connectivity_plus`依赖：
```yaml
dependencies:
  flutter:
    sdk: flutter
  # 其他现有依赖...
  connectivity_plus: ^5.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  # 其他现有依赖...
```

### 4.2 创建网络状态模型

**新建文件**: `lib/core/models/network_status.dart`

```dart
enum NetworkConnectionType {
  none,      // 无网络
  wifi,      // WiFi
  mobile,    // 移动数据
  ethernet,  // 以太网
  bluetooth, // 蓝牙
  vpn,       // VPN
  other,     // 其他
}

class NetworkStatus {
  final bool isConnected;
  final NetworkConnectionType connectionType;
  final DateTime lastUpdated;
  
  NetworkStatus({
    required this.isConnected,
    required this.connectionType,
    required this.lastUpdated,
  });
  
  /// 是否为WiFi连接
  bool get isWifi => connectionType == NetworkConnectionType.wifi;
  
  /// 是否为移动数据连接
  bool get isMobile => connectionType == NetworkConnectionType.mobile;
  
  /// 获取连接类型描述
  String get connectionDescription {
    switch (connectionType) {
      case NetworkConnectionType.none:
        return '无网络';
      case NetworkConnectionType.wifi:
        return 'WiFi';
      case NetworkConnectionType.mobile:
        return '移动数据';
      case NetworkConnectionType.ethernet:
        return '以太网';
      case NetworkConnectionType.bluetooth:
        return '蓝牙';
      case NetworkConnectionType.vpn:
        return 'VPN';
      case NetworkConnectionType.other:
        return '其他网络';
    }
  }
  
  /// 创建未连接状态
  static NetworkStatus disconnected() {
    return NetworkStatus(
      isConnected: false,
      connectionType: NetworkConnectionType.none,
      lastUpdated: DateTime.now(),
    );
  }
  
  /// 创建连接状态
  static NetworkStatus connected(NetworkConnectionType type) {
    return NetworkStatus(
      isConnected: true,
      connectionType: type,
      lastUpdated: DateTime.now(),
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkStatus &&
        other.isConnected == isConnected &&
        other.connectionType == connectionType;
  }
  
  @override
  int get hashCode => Object.hash(isConnected, connectionType);
  
  @override
  String toString() {
    return 'NetworkStatus(isConnected: $isConnected, connectionType: $connectionType)';
  }
}
```

### 4.3 创建网络状态Provider

**新建文件**: `lib/core/network/network_status_provider.dart`

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod/riverpod.dart';
import '../models/network_status.dart';

/// 网络状态Provider
final networkStatusProvider = AsyncNotifierProvider<NetworkStatusNotifier, NetworkStatus>(() {
  return NetworkStatusNotifier();
});

class NetworkStatusNotifier extends AsyncNotifier<NetworkStatus> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  @override
  Future<NetworkStatus> build() async {
    // 初始化网络状态
    _startMonitoring();
    return await _getCurrentNetworkStatus();
  }
  
  /// 开始监控网络状态
  void _startMonitoring() {
    _connectivitySubscription?.cancel();
    
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
  }
  
  /// 处理网络状态变化
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final newStatus = await _mapConnectivityResults(results);
    // 只有当状态真正改变时才更新
    if (newStatus != state.asData?.value) {
      state = AsyncData(newStatus);
    }
  }
  
  /// 获取当前网络状态
  Future<NetworkStatus> _getCurrentNetworkStatus() async {
    try {
      final connectivity = Connectivity();
      final results = await connectivity.checkConnectivity();
      return await _mapConnectivityResults(results);
    } catch (e) {
      // 发生错误时返回未连接状态
      return NetworkStatus.disconnected();
    }
  }
  
  /// 映射ConnectivityResult到NetworkStatus
  Future<NetworkStatus> _mapConnectivityResults(List<ConnectivityResult> results) async {
    if (results.contains(ConnectivityResult.none)) {
      return NetworkStatus.disconnected();
    }
    
    // 优先级：Ethernet > WiFi > Mobile > 其他
    if (results.contains(ConnectivityResult.ethernet)) {
      return NetworkStatus.connected(NetworkConnectionType.ethernet);
    }
    
    if (results.contains(ConnectivityResult.wifi)) {
      return NetworkStatus.connected(NetworkConnectionType.wifi);
    }
    
    if (results.contains(ConnectivityResult.mobile)) {
      return NetworkStatus.connected(NetworkConnectionType.mobile);
    }
    
    if (results.contains(ConnectivityResult.bluetooth)) {
      return NetworkStatus.connected(NetworkConnectionType.bluetooth);
    }
    
    if (results.contains(ConnectivityResult.vpn)) {
      return NetworkStatus.connected(NetworkConnectionType.vpn);
    }
    
    return NetworkStatus.connected(NetworkConnectionType.other);
  }
  
  /// 手动刷新网络状态
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final status = await _getCurrentNetworkStatus();
      state = AsyncData(status);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// 网络连接状态简化Provider
final isConnectedProvider = Provider<bool>((ref) {
  final networkStatus = ref.watch(networkStatusProvider);
  return networkStatus.maybeWhen(
    data: (status) => status.isConnected,
    orElse: () => false,
  );
});

/// 网络连接类型Provider
final connectionTypeProvider = Provider<NetworkConnectionType?>((ref) {
  final networkStatus = ref.watch(networkStatusProvider);
  return networkStatus.maybeWhen(
    data: (status) => status.connectionType,
    orElse: () => null,
  );
});
```

### 4.4 创建网络状态监听Widget

**新建文件**: `lib/presentation/widgets/network_status_listener.dart`

```dart
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import '../../core/network/network_status_provider.dart';
import '../../core/models/network_status.dart';
import '../../presentation/utils/error_ui_handler.dart';

class NetworkStatusListener extends ConsumerWidget {
  final Widget child;
  
  const NetworkStatusListener({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听网络状态变化
    ref.listen<AsyncValue<NetworkStatus>>(networkStatusProvider, (previous, next) {
      next.maybeWhen(
        data: (status) {
          // 检查状态是否发生变化
          final previousStatus = previous?.asData?.value;
          if (previousStatus != null && previousStatus != status) {
            _handleNetworkStatusChange(context, previousStatus, status);
          }
        },
        error: (error, stackTrace) {
          // 网络状态监测出错
          debugPrint('网络状态监测出错: $error');
        },
        loading: () {
          // 正在加载网络状态
        },
        orElse: () {},
      );
    });
    
    return child;
  }
  
  /// 处理网络状态变化
  void _handleNetworkStatusChange(
    BuildContext context, 
    NetworkStatus previousStatus, 
    NetworkStatus currentStatus,
  ) {
    // 网络断开
    if (previousStatus.isConnected && !currentStatus.isConnected) {
      ErrorUIHandler.showError(
        context, 
        '网络连接已断开，请检查网络设置',
        title: '网络断开',
      );
      return;
    }
    
    // 网络恢复
    if (!previousStatus.isConnected && currentStatus.isConnected) {
      ErrorUIHandler.showSuccess(
        context, 
        '网络已恢复 (${currentStatus.connectionDescription})',
      );
      return;
    }
    
    // 连接类型变化（都在连接状态下）
    if (previousStatus.isConnected && 
        currentStatus.isConnected && 
        previousStatus.connectionType != currentStatus.connectionType) {
      ErrorUIHandler.showToast(
        context, 
        '网络切换到 ${currentStatus.connectionDescription}',
      );
    }
  }
}
```

### 4.5 更新主应用结构

**文件**: `lib/main.dart`

包装应用以监听网络状态：
```dart
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'my_app.dart';
import 'core/network/network_status_provider.dart';
import 'presentation/widgets/network_status_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化数据库等
  
  runApp(
    ProviderScope(
      child: MyAppWrapper(),
    ),
  );
}

class MyAppWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NetworkStatusListener(
      child: MyApp(),
    );
  }
}
```

### 4.6 创建网络请求拦截器

**新建文件**: `lib/core/network/network_interceptor.dart`

```dart
import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import '../network/network_status_provider.dart';
import '../utils/error_handler.dart';

class NetworkInterceptor extends Interceptor {
  final ProviderRef ref;
  
  NetworkInterceptor(this.ref);
  
  @override
  Future<void> onRequest(
    RequestOptions options, 
    RequestInterceptorHandler handler,
  ) async {
    // 检查网络连接状态
    final isConnected = ref.read(isConnectedProvider);
    
    if (!isConnected) {
      // 网络未连接，阻止请求
      handler.reject(
        DioException(
          error: NetworkException('网络未连接'),
          requestOptions: options,
        ),
      );
      return;
    }
    
    // 网络连接正常，继续请求
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 可以在这里添加额外的错误处理逻辑
    handler.next(err);
  }
}
```

### 4.7 更新API客户端

**文件**: `lib/data/network/api_client.dart`

集成网络拦截器：
```dart
import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import '../../core/network/network_interceptor.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});

class ApiClient {
  final Dio _dio;
  
  ApiClient(ProviderRef ref) : _dio = Dio() {
    // 添加网络拦截器
    _dio.interceptors.add(NetworkInterceptor(ref));
    
    // 其他拦截器...
  }
  
  // 现有API方法...
}
```

### 4.8 创建网络状态显示组件

**新建文件**: `lib/presentation/widgets/network_status_indicator.dart`

```dart
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import '../../core/network/network_status_provider.dart';

class NetworkStatusIndicator extends ConsumerWidget {
  final bool showLabel;
  
  const NetworkStatusIndicator({Key? key, this.showLabel = false}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);
    
    return networkStatus.when(
      data: (status) => _buildStatusIcon(status),
      loading: () => _buildLoadingIndicator(),
      error: (error, stack) => _buildErrorIndicator(),
    );
  }
  
  Widget _buildStatusIcon(NetworkStatus status) {
    final isConnected = status.isConnected;
    final icon = isConnected ? Icons.wifi : Icons.wifi_off;
    final color = isConnected ? Colors.green : Colors.red;
    
    if (showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 4),
          Text(
            status.connectionDescription,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      );
    }
    
    return Icon(icon, color: color, size: 16);
  }
  
  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
  
  Widget _buildErrorIndicator() {
    return const Icon(Icons.error, color: Colors.orange, size: 16);
  }
}
```

## 五、测试方案

### 5.1 单元测试

**测试文件**: `test/core/network/network_status_provider_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod/riverpod.dart';
import '../../../lib/core/network/network_status_provider.dart';
import '../../../lib/core/models/network_status.dart';

@GenerateMocks([Connectivity])
import 'network_status_provider_test.mocks.dart';

void main() {
  group('NetworkStatusProvider', () {
    late MockConnectivity mockConnectivity;
    late ProviderContainer container;
    
    setUp(() {
      mockConnectivity = MockConnectivity();
      container = ProviderContainer(
        overrides: [
          // 这里需要mock Connectivity，但在实际测试中可能需要更复杂的setup
        ],
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('初始状态应该是未连接或连接状态', () async {
      final provider = container.read(networkStatusProvider);
      
      // 由于异步初始化，我们需要等待
      await untilCalled(provider.future);
      
      expect(provider.maybeWhen(
        data: (status) => status.isConnected,
        orElse: () => false,
      ), isNotNull);
    });
    
    test('网络状态应该能够正确映射', () {
      final notifier = NetworkStatusNotifier();
      
      // 测试各种连接类型映射
      expect(notifier._mapConnectivityResults([ConnectivityResult.none]),
          completion(isA<NetworkStatus>().having((s) => s.isConnected, 'isConnected', false)));
          
      expect(notifier._mapConnectivityResults([ConnectivityResult.wifi]),
          completion(isA<NetworkStatus>().having((s) => s.connectionType, 'connectionType', NetworkConnectionType.wifi)));
    });
  });
}
```

### 5.2 集成测试

**测试文件**: `test/integration/network_monitoring_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod/riverpod.dart';
import '../../lib/core/network/network_status_provider.dart';

void main() {
  group('网络监测集成测试', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('网络状态Provider应该能够初始化', () async {
      final provider = container.read(networkStatusProvider);
      
      // 等待异步初始化完成
      await provider.future;
      
      expect(provider, isNotNull);
    });
    
    test('isConnectedProvider应该反映正确的连接状态', () async {
      final isConnected = container.read(isConnectedProvider);
      
      // isConnected应该是一个布尔值
      expect(isConnected, isA<bool>());
    });
  });
}
```

## 六、性能与资源考虑

### 6.1 资源使用
- `connectivity_plus`插件在后台使用系统原生API，资源消耗极小
- 网络状态变化监听不会显著影响应用性能
- 状态更新采用异步方式，不会阻塞UI线程

### 6.2 电池消耗
- 网络状态监听由操作系统管理，电池消耗可以忽略不计
- 避免频繁的状态查询，使用事件驱动方式

### 6.3 错误处理
- 网络监测失败时优雅降级到未连接状态
- 提供手动刷新机制以应对监测失败的情况

## 七、部署验证清单

- [ ] connectivity_plus依赖添加并安装
- [ ] NetworkStatus模型实现
- [ ] NetworkStatusProvider创建并通过单元测试
- [ ] NetworkStatusListener实现并在主应用中集成
- [ ] 网络状态变化时正确显示提示
- [ ] 网络断开和恢复时的用户提示验证
- [ ] 网络请求拦截器集成到API客户端
- [ ] 网络未连接时阻止网络请求验证
- [ ] NetworkStatusIndicator组件功能验证
- [ ] 不同平台(iOS/Android/Web)兼容性测试
- [ ] 性能基准测试(内存增加<1MB, CPU<1%)

---
**方案版本**: v1.0
**预计开发时间**: 4小时
**预计测试时间**: 2小时