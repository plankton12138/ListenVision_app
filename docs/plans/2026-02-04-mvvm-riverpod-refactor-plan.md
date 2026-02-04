# 2026-02-04 — 前端重构计划（轻量 MVVM + Riverpod）

> 本文档是为 ListenVision 前端（`frontend_flutter`）准备的**一次性完全重构**计划。目标是彻底替换现有 Clean Architecture + Provider，迁移为轻量化 MVVM + Riverpod 架构。

## 进度概览

| Phase | 名称 | 状态 | 完成日期 |
|-------|------|------|----------|
| 0 | 骨架搭建 | ✅ 已完成 | 2026-02-04 |
| 1 | Models 层迁移 | ⏳ 待开始 | - |
| 2 | Services 层构建 | ⏳ 待开始 | - |
| 3 | 数据层构建 | ⏳ 待开始 | - |
| 4 | 核心 ViewModels (Auth) | ⏳ 待开始 | - |
| 5 | 播放器 ViewModels | ⏳ 待开始 | - |
| 6 | 其他 ViewModels | ⏳ 待开始 | - |
| 7 | Views 迁移与解耦 | ⏳ 待开始 | - |
| 8 | Widgets 更新 | ⏳ 待开始 | - |
| 9 | 清理与收尾 | ⏳ 待开始 | - |

**整体进度**: `██████████░░░░░░░░░░░░░░░░░░` 10% (1/10)

---

## 目录
1. [重构范围与原则](#重构范围与原则)
2. [当前状态分析](#当前状态分析)
3. [目标架构](#目标架构)
4. [Provider → ViewModel 映射表](#provider--viewmodel-映射表)
5. [数据层设计](#数据层设计)
6. [API 变更对照](#api-变更对照)
7. [分阶段实施计划](#分阶段实施计划)
8. [分支策略](#分支策略)
9. [测试策略](#测试策略)
10. [风险与缓解](#风险与缓解)

---

## 重构范围与原则

### 核心原则
- **一次性重构**：不保留 Clean Architecture，彻底重写数据层和状态管理
- **无共存期**：不使用桥接文件，直接在新分支完成所有工作
- **功能等价**：所有现有功能必须在新架构中等价实现
- **测试先行**：每个 ViewModel 必须有配套单元测试

### 移除的架构组件
```
❌ domain/entities/        → models/
❌ domain/repositories/    → data/repositories/ (接口+实现合并)
❌ domain/usecases/        → 删除 (业务逻辑移至 ViewModel)
❌ data/datasources/       → data/api/
❌ presentation/providers/ → presentation/viewmodels/
❌ ProviderConfig + ServiceFactory → providers.dart (Riverpod)
```

---

## 当前状态分析

### 现有 Providers 清单（18 个）

| 目录 | Provider | 职责 | 依赖 |
|------|----------|------|------|
| `audio/` | `audio_provider.dart` | 音频播放状态 | 无 |
| `audio/` | `audio_metadata_loader.dart` | 元数据加载 | 无 |
| `audio/` | `playback_controller.dart` | 播放控制 | AudioProvider |
| `audio/` | `playback_queue.dart` | 播放队列 | 无 |
| `audio/` | `playback_queue_manager.dart` | 队列管理 | 无 |
| `audio/` | `playback_state.dart` | 播放状态 | 无 |
| `audio/` | `playback_state_manager.dart` | 状态管理 | 无 |
| `audio/` | `unified_playlist_manager.dart` | 歌单集成 | 无 |
| `auth/` | `auth_provider.dart` | 主账号认证 | 无 |
| `bilibili/` | `auth_provider.dart` | B站认证 | AuthProvider |
| `bilibili/` | `bilibili_provider.dart` | B站内容 | AuthProvider |
| `bilibili/` | `cache_provider.dart` | B站缓存 | AuthProvider |
| `bilibili/` | `qr_login_provider.dart` | QR登录 | AuthProvider |
| `download/` | `download_manager.dart` | 下载管理 | AuthProvider |
| `history/` | `play_history_provider.dart` | 播放历史(旧) | AuthProvider |
| `play_history/` | `play_history_provider.dart` | 播放历史(新) | AuthProvider |
| `playlist/` | `playlist_provider.dart` | 歌单管理 | AuthProvider |
| `search/` | `search_provider.dart` | 搜索 | AuthProvider |
| `theme/` | `theme_provider.dart` | 主题 | 无 |

### 现有 Entities 清单

| 文件 | 说明 | 保留 |
|------|------|------|
| `audio.dart` | 音频实体 | ✅ |
| `playlist.dart` | 歌单实体 | ✅ |
| `play_history.dart` | 播放历史 | ✅ |
| `user.dart` | 用户 | ✅ |
| `recommendation.dart` | 推荐 | ✅ |
| `download_task.dart` | 下载任务 | ✅ |
| `local_audio.dart` | 本地音频 | ✅ |
| `local_playable.dart` | 本地可播放 | ✅ |
| `online_playable.dart` | 在线可播放 | ✅ |
| `platform_account.dart` | 平台账号 | ✅ |
| `platform_types.dart` | 平台类型 | ✅ |
| `domain_types.dart` | 领域类型 | ✅ |

---

## 目标架构

### 最终目录结构

```
lib/
├── main.dart
├── app.dart                          # ProviderScope 包裹的入口
│
├── core/                             # 基础设施（无业务逻辑）
│   ├── constants/
│   │   ├── api_constants.dart
│   │   ├── app_constants.dart
│   │   ├── storage_constants.dart
│   │   └── playback_config.dart
│   ├── network/
│   │   ├── dio_client.dart           # Dio 单例，监听 token
│   │   └── adaptive_network_manager.dart
│   ├── storage/
│   │   ├── shared_storage_service.dart    # SharedPreferences wrapper
│   │   └── secure_storage_service.dart    # flutter_secure_storage wrapper
│   └── utils/
│       ├── app_logger.dart
│       ├── debounce_utils.dart
│       ├── dialog_helper.dart
│       └── ...
│
├── models/                           # 轻量实体（原 domain/entities）
│   ├── audio.dart
│   ├── playlist.dart
│   ├── user.dart
│   ├── play_history.dart
│   ├── local_audio.dart
│   ├── download_task.dart
│   ├── platform_account.dart
│   └── models_export.dart
│
├── data/                             # 数据访问层
│   ├── api/                          # API 客户端（原 datasources）
│   │   ├── backend_api_client.dart   # 后端 API
│   │   └── bilibili_api_client.dart  # B站 API
│   └── repositories/                 # Repository 实现
│       ├── auth_repository.dart
│       ├── playlist_repository.dart
│       ├── search_repository.dart
│       ├── history_repository.dart
│       └── download_repository.dart
│
├── services/                         # 有状态的服务（外部系统封装）
│   ├── audio_player_service.dart     # audioplayers 封装
│   ├── metadata_service.dart         # audio_metadata_reader 封装
│   └── download_service.dart         # 下载管理
│
├── presentation/
│   ├── providers.dart                # 所有 Riverpod providers 定义
│   │
│   ├── viewmodels/                   # StateNotifier/AsyncNotifier
│   │   ├── auth/
│   │   │   ├── auth_viewmodel.dart           # 主账号认证
│   │   │   └── platform_auth_viewmodel.dart  # B站/QQ等平台认证
│   │   ├── player/
│   │   │   ├── player_viewmodel.dart         # 播放控制
│   │   │   ├── queue_viewmodel.dart          # 播放队列
│   │   │   └── metadata_viewmodel.dart       # 元数据加载
│   │   ├── library/
│   │   │   ├── playlist_viewmodel.dart       # 歌单管理
│   │   │   └── history_viewmodel.dart        # 播放历史
│   │   ├── discovery/
│   │   │   └── search_viewmodel.dart         # 搜索
│   │   └── system/
│   │       ├── theme_viewmodel.dart          # 主题
│   │       └── download_viewmodel.dart       # 下载
│   │
│   ├── views/                        # 页面（按功能分组）
│   │   ├── discovery/                # 发现页
│   │   │   ├── search_page.dart
│   │   │   └── explore_page.dart
│   │   ├── player/                   # 播放器
│   │   │   └── ...
│   │   ├── library/                  # 资源库
│   │   │   ├── playlist_library_page.dart
│   │   │   ├── playlist_detail_page.dart
│   │   │   └── play_history_page.dart
│   │   ├── account/                  # 账号
│   │   │   ├── login_page.dart
│   │   │   ├── register_page.dart
│   │   │   └── settings_page.dart
│   │   └── not_found_page.dart
│   │
│   ├── widgets/
│   │   ├── cards/
│   │   ├── common/
│   │   └── ...
│   └── routes/
│       └── router.dart
│
└── test/
    ├── viewmodels/                   # ViewModel 单元测试
    ├── services/                     # Service 单元测试
    └── widgets/                      # Widget 测试
```

### 层级职责

| 层 | 职责 | 示例 | 状态 |
|----|------|------|------|
| `models/` | 数据结构定义 | `Audio`, `Playlist` | 无状态 |
| `data/api/` | 外部 API 调用 | `bilibili_api_client.dart` | 无状态 |
| `data/repositories/` | 数据聚合与缓存 | `playlist_repository.dart` | 无状态 |
| `services/` | 外部系统封装 | `audio_player_service.dart` | 有状态 |
| `viewmodels/` | UI 状态与业务逻辑 | `player_viewmodel.dart` | 有状态 |
| `views/` | 纯 UI 渲染 | `search_page.dart` | 无状态 |

---

## Provider → ViewModel 映射表

### 完整映射清单

| 原 Provider | 新 ViewModel | 新 Service | 合并说明 |
|-------------|--------------|------------|----------|
| `auth_provider.dart` | `auth_viewmodel.dart` | - | 主账号认证 |
| `bilibili/auth_provider.dart` `bilibili/qr_login_provider.dart` | `platform_auth_viewmodel.dart` | - | 合并平台认证 |
| `bilibili_provider.dart` | (删除) | - | 逻辑分散到各 viewmodel |
| `bilibili/cache_provider.dart` | (删除) | - | 缓存逻辑移至 repository |
| `audio_provider.dart` `playback_controller.dart` `playback_state_manager.dart` | `player_viewmodel.dart` | `audio_player_service.dart` | 合并播放控制 |
| `playback_queue.dart` `playback_queue_manager.dart` `unified_playlist_manager.dart` | `queue_viewmodel.dart` | - | 播放队列 |
| `audio_metadata_loader.dart` | `metadata_viewmodel.dart` | `metadata_service.dart` | 元数据加载 |
| `playlist_provider.dart` | `playlist_viewmodel.dart` | - | 歌单管理 |
| `play_history_provider.dart` (新旧) | `history_viewmodel.dart` | - | 播放历史 |
| `search_provider.dart` | `search_viewmodel.dart` | - | 搜索 |
| `download_manager.dart` | `download_viewmodel.dart` | `download_service.dart` | 下载 |
| `theme_provider.dart` | `theme_viewmodel.dart` | - | 主题 |

### 删除的组件

| 组件 | 删除原因 |
|------|----------|
| `domain/usecases/` | 业务逻辑移至 ViewModel |
| `data/datasources/` | 并入 `data/api/` |
| `ServiceFactory` | 被 Riverpod providers 替代 |
| `ProviderConfig` | 被 `providers.dart` 替代 |
| `base_provider.dart` | Riverpod 无需基类 |

---

## 数据层设计

### Models 层（原 domain/entities）

**保留原有实体，移除 BaseEntity 接口依赖**

```dart
// models/audio.dart
@freezed
class Audio with _$Audio {
  const factory Audio({
    required String id,
    required String title,
    String? artist,
    String? album,
    String? coverUrl,
    String? streamUrl,
    int? duration,
    // ...
  }) = _Audio;

  factory Audio.fromJson(Map<String, dynamic> json) => _$AudioFromJson(json);
  factory Audio.fromDto(Map<String, dynamic> json) { /* 保持现有逻辑 */ }
}
```

### API 层（原 datasources）

```dart
// data/api/bilibili_api_client.dart
class BilibiliApiClient {
  final Dio _dio;

  BilibiliApiClient(this._dio);

  Future<List<Audio>> searchAudio(String keyword) async { }
  Future<String> getStreamUrl(String bvid) async { }
  // ...
}
```

### Repository 层

**Repository 现在是具体类，不再有接口**

```dart
// data/repositories/playlist_repository.dart
class PlaylistRepository {
  final BackendApiClient _backendApi;
  final SharedStorageService _storage;

  PlaylistRepository(this._backendApi, this._storage);

  Future<List<Playlist>> getUserPlaylists(String userId) async { }
  Future<void> createPlaylist(Playlist playlist) async { }
  // ...
}
```

### Services 层

**封装有状态的外部系统**

```dart
// services/audio_player_service.dart
class AudioPlayerService {
  final Player _player = Player();

  final Stream<Duration> _positionStream = _player.positionStream;
  final Stream<Duration?> _durationStream = _player.durationStream;
  final Stream<PlayerState> _playerStateStream = _player.playerStateStream;

  Future<void> play(String source) async { }
  Future<void> pause() async { }
  Future<void> seek(Duration position) async { }
  // ...
}
```

---

## API 变更对照

### 状态读取

| 旧 API (Provider) | 新 API (Riverpod) |
|-------------------|-------------------|
| `context.watch<AudioProvider>()` | `ref.watch(playerViewModelProvider)` |
| `context.read<AudioProvider>()` | `ref.read(playerViewModelProvider.notifier)` |
| `Provider.of<AudioProvider>(context)` | `ref.read(playerViewModelProvider)` |

### 状态结构

```dart
// 旧: AudioProvider
class AudioProvider extends ChangeNotifier {
  Audio? currentAudio;
  bool isPlaying;
  List<Audio> queue;
  // ...
}

// 新: PlayerViewModel (StateNotifier)
@freezed
class PlayerState with _$PlayerState {
  const factory PlayerState({
    required Audio? currentAudio,
    required bool isPlaying,
    required List<Audio> queue,
    required int currentIndex,
    required AsyncValue<void> playStatus,
  }) = _PlayerState;
}

class PlayerViewModel extends StateNotifier<PlayerState> {
  PlayerViewModel(this._service) : super(PlayerState.initial());

  Future<void> play(Audio audio) async { }
  Future<void> pause() async { }
  // ...
}
```

### Dio Token 订阅

```dart
// 旧: DioProvider.instance 在 ProviderConfig 中更新

// 新: dioClientProvider 监听 authViewModelProvider
@riverpod
Dio dioClient(DioClientRef ref) {
  final authToken = ref.watch(authViewModelProvider).token;
  return DioClient(token: authToken);
}
```

---

## 分阶段实施计划

### Phase 0 — 骨架搭建（准备）✅

> **状态**: 已完成 (2026-02-04)

**目标**：创建新目录结构，添加依赖

**改动**：
- `pubspec.yaml` 添加 `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `riverpod_lint`, `build_runner`
- 创建目录结构（空文件占位）
- 添加 35 个占位文件

**验收**：项目可编译 ✅

**创建的文件**：
- `lib/app.dart`
- `lib/models/models_export.dart`
- `lib/data/api/backend_api_client.dart`, `bilibili_api_client.dart`
- `lib/data/repositories/` (5 个文件)
- `lib/services/` (3 个文件)
- `lib/core/storage/` (2 个文件)
- `lib/core/network/dio_client.dart`
- `lib/presentation/providers.dart`
- `lib/presentation/viewmodels/` (10 个文件)

---

### Phase 1 — Models 层迁移

**目标**：将 `domain/entities/` 迁移到 `models/`

**改动**：
- 移动所有实体文件到 `models/`
- 移除 `BaseEntity` 接口依赖
- 更新 import 路径

**验收**：所有 freezed 代码生成成功

---

### Phase 2 — Services 层构建

**目标**：创建有状态的服务封装

**改动**：
- `services/audio_player_service.dart`
- `services/metadata_service.dart`
- `services/download_service.dart`

**验收**：Service 单元测试通过

---

### Phase 3 — 数据层构建

**目标**：创建 API 客户端和 Repository

**改动**：
- `data/api/backend_api_client.dart`
- `data/api/bilibili_api_client.dart`
- `data/repositories/*.dart`（6个）

**验收**：Repository 单元测试通过（mock Dio）

---

### Phase 4 — 核心 ViewModels（Auth）

**目标**：迁移认证相关 Providers

**改动**：
- `viewmodels/auth/auth_viewmodel.dart`
- `viewmodels/auth/platform_auth_viewmodel.dart`
- `core/network/dio_client.dart`（订阅 token）
- `presentation/providers.dart`（auth 相关）

**验收**：
- 登录/登出流程正常
- Dio header 随 token 更新

---

### Phase 5 — 播放器 ViewModels

**目标**：迁移音频相关 Providers（最复杂）

**改动**：
- `viewmodels/player/player_viewmodel.dart`
- `viewmodels/player/queue_viewmodel.dart`
- `viewmodels/player/metadata_viewmodel.dart`

**验收**：
- Windows 播放不崩溃
- 播放/暂停/切歌/seek 正常
- 前后台切换正常

---

### Phase 6 — 其他 ViewModels

**目标**：迁移剩余 Providers

**改动**：
- `viewmodels/library/playlist_viewmodel.dart`
- `viewmodels/library/history_viewmodel.dart`
- `viewmodels/discovery/search_viewmodel.dart`
- `viewmodels/system/theme_viewmodel.dart`
- `viewmodels/system/download_viewmodel.dart`

**验收**：所有功能可用

---

### Phase 7 — Views 迁移与解耦

**目标**：迁移页面到新结构，移除 BilibiliProvider 直接依赖

**改动**：
- 重命名并移动页面到 `views/*`
- 更新所有 `context.watch/read` 为 `ref.watch/read`
- 移除 `BilibiliProvider` 直接调用

**验收**：所有页面渲染正常

---

### Phase 8 — Widgets 更新

**目标**：更新所有 Widgets 的 Provider 调用

**改动**：
- 20+ widgets 的 `context.watch/read` 替换
- 必要时用 `ConsumerWidget` / `ConsumerStatefulWidget`

**验收**：Widget 测试通过

---

### Phase 9 — 清理与收尾

**目标**：删除旧代码

**改动**：
- 删除 `domain/` 目录
- 删除 `presentation/providers/` 目录
- 删除 `core/di/provider_config.dart`, `service_factory.dart`
- 删除 `base_provider.dart`, `base_page.dart`
- 从 `pubspec.yaml` 移除 `provider` 依赖

**验收**：
- 无 `provider` 包依赖
- 项目编译运行正常
- 所有测试通过

---

## 分支策略

### Git 工作流

```
master (当前可用，标记 baseline)
  └── refactor/mvvm-riverpod (完全重构，约 8-10 周)
```

### Master 处理

- 重构期间 `master` **不接收新功能**
- 仅接受关键 bugfix（通过 cherry-pick 同步到 refactor 分支）
- 重构完成后，refactor 分支合并回 `master`

### 回滚策略

- **回滚触发条件**：Phase 5/6/7 任一阶段无法在 2 周内完成
- **回滚方式**：放弃 refactor 分支，从 master 重新评估方案
- **数据风险**：无（重构不影响后端和用户数据）

---

## 测试策略

### 单元测试

| 目标 | 工具 | 覆盖目标 |
|------|------|----------|
| ViewModels | `ProviderContainer` + mock | 80% |
| Services | mock external | 80% |
| Repositories | mock Dio | 70% |

### Widget 测试

- 关键 Widgets 使用 `ProviderScope` 覆盖
- 验证 UI 渲染与用户交互

### 集成测试

- Windows 完整播放流程
- Android 登录→搜索→播放→收藏流程

---

## 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| Windows 音频崩溃 | 高 | Phase 5 预留充足时间，优先集成测试 |
| 功能遗漏 | 高 | 对照表逐项验收 |
| 工期失控 | 中 | 设定阶段里程碑，超 2 周即评估 |
| 代码生成冲突 | 低 | 分阶段运行 build_runner |

---

## 验收清单

### 功能完整性

- [ ] 主账号登录/注册/登出
- [ ] B站 QR 扫码登录
- [ ] B站音频搜索与播放
- [ ] 本地音频扫描与播放
- [ ] 歌单 CRUD
- [ ] 收藏/取消收藏
- [ ] 播放历史记录
- [ ] 下载管理
- [ ] 主题切换
- [ ] Windows 平台稳定播放

### 代码质量

- [ ] 无 `provider` 包依赖
- [ ] 无 `domain/` 目录
- [ ] 无 `ProviderConfig` / `ServiceFactory`
- [ ] 关键 ViewModel 有单元测试
- [ ] 通过静态分析

---

## 附录：首个实施单元

**Phase 1 — Models 层迁移**

1. 创建 `models/` 目录
2. 移动所有实体文件
3. 移除 `implements BaseEntity`
4. 更新所有 import
5. 运行 `build_runner`
6. 验证编译

预计 0.5-1 天完成。

---

*本计划为一次性完全重构，执行前请确保：*
1. *Master 分支已打 tag 作为 baseline*
2. *所有现有功能已记录在验收清单*
3. *团队成员已了解新架构设计*
