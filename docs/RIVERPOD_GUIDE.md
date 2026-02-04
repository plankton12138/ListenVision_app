# Riverpod 使用指南

> 本文档基于 [Riverpod 官方仓库](../references/riverpod) 的最新文档整理，适用于 ListenVision 项目。

## 目录

1. [快速参考](#快速参考)
2. [代码生成模式](#代码生成模式)
3. [Provider 类型](#provider-类型)
4. [StateNotifier 模式](#statenotifier-模式)
5. [最佳实践](#最佳实践)
6. [常见问题](#常见问题)

---

## 快速参考

### 基本概念

| 概念 | 说明 |
|------|------|
| `Provider` | 共享状态的访问点，类似不可变全局变量 |
| `Ref` | Provider 内部使用的对象，用于读取其他 provider 或监听生命周期 |
| `WidgetRef` | Widget 中使用的 ref，通过 `ref.watch/read` 访问 provider |
| `ConsumerWidget` | 使用 ref 的无状态 Widget |
| `ConsumerStatefulWidget` | 使用 ref 的有状态 Widget |

### 读取状态

```dart
// 监听状态变化，重建 widget
final state = ref.watch(myProvider);

// 读取一次，不监听变化
final value = ref.read(myProvider);

// 获取 notifier（用于调用方法）
final notifier = ref.read(myProvider.notifier);
```

---

## 代码生成模式

项目使用 `riverpod_generator` 通过注解自动生成 provider 代码。

### 安装依赖

```yaml
dependencies:
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x

dev_dependencies:
  build_runner: ^2.x
  riverpod_generator: ^2.x
  riverpod_lint: ^2.x
```

### 定义 Provider

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'my_file.g.dart';

// 1. 简单 Provider
@riverpod
String appName(Ref ref) => 'ListenVision';

// 使用: ref.watch(appNameProvider)

// 2. 带参数的 Provider (自动 family)
@riverpod
Future<List<Audio>> fetchAudios(Ref ref, {required String keyword, int page = 1}) async {
  final api = ref.watch(apiClientProvider);
  return api.search(keyword, page);
}

// 使用: ref.watch(fetchAudiosProvider(keyword: 'music', page: 1))

// 3. StateNotifier Provider
@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() => const AuthState.initial();

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    // ...
  }
}

// 使用: ref.watch(authProvider) / ref.read(authProvider.notifier).login(...)
```

### 运行代码生成

```bash
# 一次性生成
flutter pub run build_runner build --delete-conflicting-outputs

# 监听模式（开发时推荐）
flutter pub run build_runner watch
```

---

## Provider 类型

### @riverpod 注解自动推断类型

| 函数返回类型 | 生成的 Provider 类型 | 说明 |
|-------------|---------------------|------|
| `T` | `Provider<T>` | 不可变值 |
| `Future<T>` | `FutureProvider<T>` | 异步值 |
| `Stream<T>` | `StreamProvider<T>` | 流 |
| `StateNotifier<T>` | 使用 `@riverpod class` | 可变状态 |

### StateNotifier 类定义

```dart
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  MyState build() {
    // 初始化状态
    return MyState.initial();
  }

  // 修改状态的方法
  void updateValue(String newValue) {
    state = state.copyWith(value: newValue);
  }

  Future<void> fetchData() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _service.fetch();
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
```

---

## StateNotifier 模式

### 项目中的实现模式

```dart
// 1. 定义 State (使用 freezed)
@freezed
class PlayerState with _$PlayerState {
  const factory PlayerState({
    PlayableAudio? currentPlayable,
    @Default(false) bool isPlaying,
    @Default(Duration.zero) Duration position,
    Duration? duration,
  }) = _PlayerState;
}

// 2. 定义 ViewModel (StateNotifier)
class PlayerViewModel extends StateNotifier<PlayerState> {
  final AudioPlayerService _service;

  PlayerViewModel(this._service) : super(const PlayerState()) {
    _init();
  }

  void _init() {
    // 初始化逻辑
  }

  Future<void> play() async {
    await _service.play();
    state = state.copyWith(isPlaying: true);
  }
}

// 3. 定义 Provider
@riverpod
PlayerViewModel playerViewModel(PlayerViewModelRef ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return PlayerViewModel(service);
}
```

---

## 最佳实践

### 1. Provider 命名规范

```dart
// Service: 小驼峰 + Service
@riverpod
AudioPlayerService audioPlayerService(AudioPlayerServiceRef ref) {
  return AudioPlayerService();
}

// ViewModel: 小驼峰 + ViewModel
@riverpod
PlayerViewModel playerViewModel(PlayerViewModelRef ref) {
  return PlayerViewModel(ref.watch(audioPlayerServiceProvider));
}

// 衍生值: 描述性名称
@riverpod
bool isLoggedIn(IsLoggedInRef ref) {
  return ref.watch(authViewModelProvider).isLoggedIn;
}
```

### 2. 依赖注入

```dart
// 正确：通过 ref.watch 注入依赖
@riverpod
PlaylistViewModel playlistViewModel(PlaylistViewModelRef ref) {
  final repository = ref.watch(playlistRepositoryProvider);
  final storage = ref.watch(sharedStorageServiceProvider);
  return PlaylistViewModel(repository: repository, storage: storage);
}

// 错误：直接 new 创建依赖
@riverpod
PlaylistViewModel playlistViewModel(PlaylistViewModelRef ref) {
  return PlaylistViewModel(
    repository: PlaylistRepository(), // ❌ 无法 mock 测试
  );
}
```

### 3. 生命周期管理

```dart
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  MyState build() {
    // ref.onDispose 在 provider 销毁时调用
    ref.onDispose(() {
      // 清理资源：关闭 stream、取消订阅等
      _controller.close();
      _subscription.cancel();
    });

    return MyState.initial();
  }
}
```

### 4. 读取其他 Provider

```dart
@riverpod
Future<List<Audio>> searchAudios(SearchAudiosRef ref, {required String keyword}) async {
  // 方式1: 监听依赖变化（推荐）
  final api = ref.watch(apiClientProvider);

  // 方式2: 读取一次（不监听变化）
  final token = ref.read(authTokenProvider);

  return api.search(keyword);
}
```

---

## 常见问题

### Q: 如何处理 AsyncValue？

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(fetchProductsProvider);

    return asyncValue.when(
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (products) => ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) => Text(products[index].name),
      ),
    );
  }
}
```

### Q: 如何在回调中读取 Provider？

```dart
onPressed: () {
  // 错误：不能在回调中使用 ref.watch
  // final value = ref.watch(myProvider);

  // 正确：使用 ref.read
  final notifier = ref.read(myProvider.notifier);
  notifier.doSomething();
}
```

### Q: @riverpod 注解的函数参数规则

```dart
// 第一个参数必须是 Ref
@riverpod
String myFunction(Ref ref, {required int id, String name = ''}) {
  // Ref 后可以有任意多个参数
  // 支持命名参数、可选参数、默认值
  return 'value';
}

// 生成的 provider: myFunctionProvider(id: 1, name: 'test')
```

### Q: Deprecated 警告

```dart
// 这些类型已废弃，改用 Ref
// ❌ AudioPlayerServiceRef, PlayerViewModelRef
// ✅ 直接使用 Ref

@riverpod
AudioPlayerService audioPlayerService(Ref ref) {  // ✅
  return AudioPlayerService();
}
```

---

## 参考文档

| 文档 | 路径 |
|------|------|
| Riverpod 官方文档 | `references/riverpod/` |
| Providers 详解 | `references/riverpod/packages/flutter_riverpod/dartdoc/providers.md` |
| Notifiers 详解 | `references/riverpod/packages/flutter_riverpod/dartdoc/notifiers.md` |
| Generator 文档 | `references/riverpod/packages/riverpod_generator/README.md` |
| 在线文档 | https://riverpod.dev |

---

## 项目示例

查看项目中已实现的 ViewModels：

| 文件 | 说明 |
|------|------|
| [lib/presentation/viewmodels/auth/auth_viewmodel.dart](../frontend_flutter/lib/presentation/viewmodels/auth/auth_viewmodel.dart) | 认证状态管理 |
| [lib/presentation/viewmodels/player/player_viewmodel.dart](../frontend_flutter/lib/presentation/viewmodels/player/player_viewmodel.dart) | 播放器控制 |
| [lib/presentation/viewmodels/player/queue_viewmodel.dart](../frontend_flutter/lib/presentation/viewmodels/player/queue_viewmodel.dart) | 播放队列 |
| [lib/presentation/viewmodels/player/metadata_viewmodel.dart](../frontend_flutter/lib/presentation/viewmodels/player/metadata_viewmodel.dart) | 元数据加载 |
