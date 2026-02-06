# Riverpod 3.0 快速参考卡

> 本文档提供 Riverpod 3.0 迁移的速查信息  
> 创建日期: 2026-02-06

---

## 🔑 关键变化速查

### Provider 类型变化

| Riverpod 2.x (废弃) | Riverpod 3.0 (推荐) | 适用场景 |
|--------------------|--------------------|---------|
| `StateNotifier` | `Notifier` | 同步状态 |
| `StateNotifier` | `AsyncNotifier` | 需要异步初始化 |
| `StateNotifierProvider` | `NotifierProvider` | - |
| `FutureProvider` | `AsyncNotifierProvider` | 复杂异步状态 |
| `StreamProvider` | `StreamNotifier` | 流式数据 |
| - | `Mutation` | 副作用管理 |

### 导入变化

```dart
// ❌ Riverpod 2.x
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ Riverpod 3.0
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// StateNotifier 现在需要从 legacy 导入（不推荐）
import 'package:flutter_riverpod/legacy.dart';
```

---

## 📝 代码模板

### 1. Notifier (同步状态)

```dart
@Riverpod(keepAlive: true)
class ThemeViewModel extends _$ThemeViewModel {
  @override
  AppThemeMode build() {
    // 初始化逻辑
    return AppThemeMode.system;
  }

  void toggleTheme() {
    state = state == AppThemeMode.dark 
      ? AppThemeMode.light 
      : AppThemeMode.dark;
  }
}
```

### 2. AsyncNotifier (异步初始化)

```dart
@Riverpod(keepAlive: true)
class DownloadViewModel extends _$DownloadViewModel {
  DownloadRepository? _repository;

  @override
  Future<DownloadModelState> build() async {
    _repository = ref.watch(downloadRepositoryProvider);
    
    // 清理回调
    ref.onDispose(() {
      // 清理资源
    });
    
    // 异步初始化
    final tasks = await _repository!.getAllTasks();
    return DownloadModelState.loaded(downloads: tasks);
  }

  Future<void> addDownload(...) async {
    state = const AsyncLoading(); // 可选：显示加载状态
    
    try {
      await _repository!.addDownload(...);
      final tasks = await _repository!.getAllTasks();
      state = AsyncData(DownloadModelState.loaded(downloads: tasks));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}
```

### 3. Widget 监听

```dart
// ✅ 方式 1: 使用 AsyncValue.when (推荐用于异步状态)
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(downloadViewModelProvider);
    
    return asyncState.when(
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
      data: (state) => _buildContent(state),
    );
  }
}

// ✅ 方式 2: 使用 select (性能优化)
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(
      downloadViewModelProvider.select(
        (s) => s.valueOrNull?.downloads ?? []
      )
    );
    
    return ListView.builder(
      itemCount: downloads.length,
      itemBuilder: (context, index) => DownloadTile(downloads[index]),
    );
  }
}

// ✅ 方式 3: 调用方法
class MyButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        ref.read(downloadViewModelProvider.notifier).pauseDownload(id);
      },
      child: Text('暂停'),
    );
  }
}
```

### 4. Mutation (副作用管理)

```dart
// 定义 mutation (全局)
final pauseDownloadMutation = Mutation<void>();

// Widget 中使用
class DownloadButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutation = ref.watch(pauseDownloadMutation);
    
    return switch (mutation) {
      MutationIdle() => IconButton(
        icon: Icon(Icons.pause),
        onPressed: () => pauseDownloadMutation.run(ref, (tx) async {
          await tx.get(downloadViewModelProvider.notifier).pauseDownload(id);
        }),
      ),
      MutationPending() => CircularProgressIndicator(),
      MutationError() => IconButton(
        icon: Icon(Icons.error),
        onPressed: () => {/* 显示错误 */},
      ),
      MutationSuccess() => Icon(Icons.check),
    };
  }
}
```

---

## 🔄 常见迁移场景

### 场景 1: StateNotifier -> AsyncNotifier

```dart
// ❌ 旧代码
class DownloadViewModel extends StateNotifier<DownloadModelState> {
  DownloadViewModel(this._repository) : super(const DownloadModelState.initial());
  
  DownloadModelState get downloadState => state;
}

@riverpod
DownloadViewModel downloadViewModel(DownloadViewModelRef ref) {
  return DownloadViewModel(ref.watch(downloadRepositoryProvider));
}

// ✅ 新代码
@Riverpod(keepAlive: true)
class DownloadViewModel extends _$DownloadViewModel {
  DownloadRepository? _repository;
  
  @override
  Future<DownloadModelState> build() async {
    _repository = ref.watch(downloadRepositoryProvider);
    final tasks = await _repository!.getAllTasks();
    return DownloadModelState.loaded(downloads: tasks);
  }
}
```

### 场景 2: Widget 监听修复

```dart
// ❌ 旧代码
final viewModel = ref.watch(downloadViewModelProvider);
final state = viewModel.downloadState;  // 不会触发重建！

// ✅ 新代码
final asyncState = ref.watch(downloadViewModelProvider);
final state = asyncState.valueOrNull;  // 会触发重建
```

### 场景 3: 方法调用

```dart
// ❌ 旧代码
ref.read(downloadViewModelProvider).pauseDownload(id);

// ✅ 新代码
ref.read(downloadViewModelProvider.notifier).pauseDownload(id);
```

---

## 🔧 常用工具方法

### AsyncValue 扩展

```dart
extension AsyncValueX<T> on AsyncValue<T> {
  /// 获取值或 null
  T? get valueOrNull => whenOrNull(data: (v) => v);
  
  /// 获取错误或 null
  Object? get errorOrNull => whenOrNull(error: (e, _) => e);
  
  /// 是否加载中
  bool get isLoading => this is AsyncLoading;
  
  /// 是否错误
  bool get isError => this is AsyncError;
  
  /// 是否数据
  bool get isData => this is AsyncData;
}
```

### 安全状态设置

```dart
extension AsyncNotifierX<T> on AsyncNotifier<T> {
  /// 仅在 mounted 时设置状态
  void safeSetData(T value) {
    if (ref.mounted) {
      state = AsyncData(value);
    }
  }
  
  /// 仅在 mounted 时设置错误
  void safeSetError(Object error, StackTrace stack) {
    if (ref.mounted) {
      state = AsyncError(error, stack);
    }
  }
}
```

---

## 🧪 测试模板

### 单元测试

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

test('DownloadViewModel 暂停下载', () async {
  final container = ProviderContainer.test(
    overrides: [
      downloadRepositoryProvider.overrideWithValue(mockRepository),
    ],
  );
  
  addTearDown(container.dispose);
  
  // 等待初始化完成
  await container.read(downloadViewModelProvider.future);
  
  // 执行操作
  await container.read(downloadViewModelProvider.notifier).pauseDownload(1);
  
  // 验证状态
  final state = await container.read(downloadViewModelProvider.future);
  expect(state.downloads.first.status, equals(DownloadStatus.paused));
});
```

### Widget 测试

```dart
testWidgets('显示下载列表', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        downloadViewModelProvider.overrideWith(
          () => MockDownloadViewModel(),
        ),
      ],
      child: MaterialApp(home: BackendDownloadPage()),
    ),
  );
  
  // 等待异步加载
  await tester.pumpAndSettle();
  
  expect(find.text('下载任务'), findsOneWidget);
});
```

---

## ⚠️ 常见陷阱

| 问题 | 原因 | 解决方案 |
|-----|------|---------|
| UI 不刷新 | 监听的是 ViewModel 实例而非 state | 使用 `ref.watch(provider)` 而非 `ref.watch(provider).state` |
| 方法调用报错 "notifier was disposed" | 在 async gap 后调用 | 使用 `ref.mounted` 检查或使用 Mutation |
| 编译错误 "g.dart not found" | 未运行代码生成 | 运行 `build_runner build` |
| 状态丢失 | 未使用 keepAlive | 添加 `@Riverpod(keepAlive: true)` |
| 初始化重复执行 | 依赖变化导致 rebuild | 使用 `ref.watch` 而非 `ref.read` 获取依赖 |

---

## 📚 相关链接

- [Riverpod 3.0 官方文档](https://riverpod.dev/docs/whats_new)
- [Riverpod 3.0 迁移指南](https://riverpod.dev/docs/migration/3.0.0)
- [Mutations 文档](https://riverpod.dev/docs/concepts/mutations)
- [项目迁移计划](./2026-02-06-riverpod-3-migration-plan.md)
- [项目迁移跟踪](./2026-02-06-riverpod-3-migration-tracking.md)
