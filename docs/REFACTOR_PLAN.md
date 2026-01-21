# Flutter 代码重构计划

> **创建日期**: 2026-01-20
>
> **状态**: 📋 规划中（不计入Phase）
>
> **目标**: 解决代码质量问题，提升可维护性和应用性能

---

## 一、项目评估

### 整体架构评分: **6.5/10**

| 评分项 | 得分 | 说明 |
|--------|------|------|
| 代码组织 | 7/10 | 分层清晰，但职责划分不够明确 |
| 代码复用 | 5/10 | 存在较多重复代码 |
| 状态管理 | 6/10 | Provider使用规范，但嵌套过深 |
| 性能优化 | 5/10 | 存在不必要的rebuild和列表性能问题 |
| 错误处理 | 4/10 | 异常处理过于简单，缺少降级方案 |
| 内存管理 | 5/10 | 存在Timer内存泄漏风险 |

---

## 二、严重问题清单（P0 - 立即修复）

### 1. Timer 内存泄漏 🔴

**位置**: `lib/providers/bilibili_provider.dart:128-141`

```dart
void _startQRPolling() {
  _qrPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
    // 轮询逻辑
  });
}
```

**问题**: Timer在Provider dispose时可能未完全清理

**修复方案**:
```dart
@override
void dispose() {
  _stopQRPolling();
  _qrPollTimer?.cancel();  // 确保取消
  _qrPollTimer = null;
  super.dispose();
}
```

---

### 2. ListView 性能问题 🔴

**位置**: `lib/ui/pages/explore_page.dart:276-284`

```dart
ListView(
  children: [
    ..._musicZoneData.map((item) => _buildMusicZoneCard(item)),
  ],
)
```

**问题**: 对长列表使用`children`而非`builder`，所有子widget一次性构建

**修复方案**:
```dart
ListView.builder(
  itemCount: _musicZoneData.length,
  itemBuilder: (context, index) {
    return _buildMusicZoneCard(_musicZoneData[index]);
  },
)
```

---

### 3. 图片加载无缓存 🔴

**问题**: 大量使用`Image.network`，无缓存机制

**修复方案**: 引入`cached_network_image`包

```yaml
dependencies:
  cached_network_image: ^3.3.0
```

---

## 三、中等问题清单（P1 - 短期重构）

### 1. Provider 职责过重 🟡

**位置**: `lib/providers/bilibili_provider.dart` (662行)

**问题**: 单个Provider承担太多职责：
- QR码登录管理
- 搜索功能
- 推荐内容获取
- 视频信息缓存
- 资源URL代理

**重构方案**: 拆分为多个Provider

| 新Provider | 职责 |
|------------|------|
| `QRLoginProvider` | QR码登录状态管理 |
| `SearchProvider` | 搜索功能（已有） |
| `RecommendationProvider` | 推荐内容获取 |
| `BilibiliCacheProvider` | 视频信息缓存 |

---

### 2. 重复的UI组件 🟡

| 组件 | 重复位置 | 建议 |
|------|----------|------|
| `_buildPlaylistCard` | `explore_page.dart:489-537`<br>`playlist_library_page.dart:428-486` | 提取到 `components/playlist_card.dart` |
| 错误提示逻辑 | 多个Provider | 创建 `utils/error_handler.dart` |
| 加载状态处理 | 每个页面都有 `_isLoading` | 创建 `widgets/loading_overlay.dart` |

---

### 3. 过度使用 context.watch 🟡

**问题**: 许多地方使用`context.watch<Provider>()`，导致整个widget重建

**优化方案**: 使用`Selector`或`Consumer`限制rebuild范围

```dart
// Before - 整个widget重建
Widget build(BuildContext context) {
  final provider = context.watch<AudioProvider>();
  return Text(provider.title);
}

// After - 仅重建必要部分
Widget build(BuildContext context) {
  return Selector<AudioProvider, String>(
    selector: (context, provider) => provider.title,
    builder: (context, title, child) {
      return Text(title);
    },
  );
}
```

---

## 四、架构改进建议（P2 - 长期优化）

### 当前结构问题

```
lib/
├── providers/      ← 状态管理混杂业务逻辑
├── services/       ← 服务层职责不清
├── ui/
│   ├── pages/     ← 页面组件包含太多逻辑
│   └── components/
├── models/        ← 数据模型设计不一致
└── utils/
```

### 推荐: Clean Architecture

```
lib/
├── core/           # 核心功能
│   ├── constants/
│   ├── exceptions/
│   ├── base/       # BaseProvider, BaseEntity等
│   └── utils/
├── data/           # 数据层
│   ├── models/     # 数据模型
│   ├── repositories/  # 数据仓储实现
│   └── datasources/   # API/本地数据源
├── domain/         # 领域层
│   ├── entities/   # 领域实体
│   └── repositories/  # 仓储接口
└── presentation/   # 表现层
    ├── providers/  # 状态管理
    ├── pages/      # 页面
    ├── widgets/    # 可复用组件
    └── routes/     # 路由配置
```

---

## 五、与业界标准对比

参考: [netease-cloud-music](https://github.com/boyan01/netease-cloud-music)

| 维度 | 本项目 | 业界标准 | 差距 |
|------|--------|----------|------|
| 状态管理 | Provider（混用） | Provider + Repository | ⚠️ 需改进 |
| 网络层 | Dio简单封装 | Dio + 拦截器 + 缓存 | ⚠️ 需改进 |
| 图片加载 | Image.network | cached_network_image | ❌ 需改进 |
| 列表性能 | ListView(children) | ListView.builder | ❌ 需改进 |
| 代码生成 | 手写fromJson/toJson | freezed/json_serializable | ⚠️ 建议引入 |

---

## 六、实施计划

### P0 - 立即修复（影响稳定性）

| 任务 | 预计工作量 | 优先级 |
|------|------------|--------|
| 修复Timer内存泄漏 | 1小时 | 🔴 |
| 优化ListView性能 | 2小时 | 🔴 |
| 引入图片缓存 | 3小时 | 🔴 |

### P1 - 短期重构（影响可维护性）

| 任务 | 预计工作量 | 优先级 |
|------|------------|--------|
| 拆分BilibiliProvider | 1天 | 🟡 |
| 提取重复UI组件 | 1天 | 🟡 |
| 创建BaseProvider基类 | 0.5天 | 🟡 |
| 优化context.watch使用 | 1天 | 🟡 |

### P2 - 长期优化（提升代码质量）

| 任务 | 预计工作量 | 优先级 |
|------|------------|--------|
| 重构为Clean Architecture | 3-5天 | 🟢 |
| 引入freezed代码生成 | 2天 | 🟢 |
| 完善单元测试 | 5天+ | 🟢 |

---

## 七、冗余代码清单

### 可删除的文件

| 文件 | 原因 | 确认状态 |
|------|------|----------|
| `ui/components/video_card.dart` | 未被发现使用 | ⚠️ 需确认 |

### 可合并的文件

| 文件 | 建议 |
|------|------|
| `services/bilibiliApiService.dart` | 与 `BilibiliProvider` 合并或分离职责 |

---

## 八、知识点说明

1. **内存泄漏**: Timer/Timer.periodic 必须在 dispose 时 cancel
2. **ListView性能**: builder模式按需构建，children模式一次性构建全部
3. **Selector优化**: 只监听特定字段变化，减少rebuild范围
4. **Clean Architecture**: 分层架构，确保业务逻辑与UI解耦

---

## 九、进度跟踪

### P2 Clean Architecture 迁移进度

| 阶段 | 状态 | 完成日期 |
|------|------|----------|
| Week 1: Core + Domain 层 | ✅ 完成 | 2026-01-20 |
| Week 2: Data 层 | ✅ 完成 | 2026-01-20 |
| Week 3: Presentation 层 | ✅ 完成 | 2026-01-21 |
| Week 4: 数据层完善 | ✅ 完成 | 2026-01-21 |
| Week 5: 基础设施 (DioProvider, ServiceFactory) | ✅ 完成 | 2026-01-21 |
| Week 5: main.dart 集成 | ✅ 完成 | 2026-01-21 |
| Week 5: 组件迁移 (8个) | ✅ 完成 | 2026-01-21 |
| Week 5: 路由迁移 | ✅ 完成 | 2026-01-21 |
| Week 5: 页面迁移 (13个) | ✅ 完成 | 2026-01-21 |
| Week 5: 清理旧代码 | ✅ 完成 | 2026-01-21 |

**P2 总进度: 100% ✅**

### 已完成工作

#### Week 1: Core + Domain 层
- ✅ `lib/core/errors/exceptions.dart` - 异常类定义
- ✅ `lib/core/errors/failures.dart` - Failure 类 (freezed)
- ✅ `lib/core/constants/api_constants.dart` - API 常量
- ✅ `lib/core/constants/app_constants.dart` - 应用常量
- ✅ `lib/core/base/base_entity.dart` - 实体基类
- ✅ `lib/domain/entities/user.dart` - 用户实体
- ✅ `lib/domain/entities/playlist.dart` - 歌单实体
- ✅ `lib/domain/entities/audio.dart` - 音频实体
- ✅ `lib/domain/entities/play_history.dart` - 播放历史实体
- ✅ `lib/domain/entities/recommendation.dart` - 推荐内容实体
- ✅ `lib/domain/repositories/*_repository.dart` - Repository 接口
- ✅ `lib/domain/usecases/**/*_usecase.dart` - UseCase 类

#### Week 2: Data 层
- ✅ `lib/data/datasources/remote/auth_remote_datasource.dart`
- ✅ `lib/data/datasources/local/auth_local_datasource.dart`
- ✅ `lib/data/datasources/remote/bilibili_remote_datasource.dart`
- ✅ `lib/data/repositories/auth_repository_impl.dart`
- ✅ `lib/data/repositories/bilibili_repository_impl.dart`
- ✅ `pubspec.yaml` - 添加 dartz, freezed_annotation, json_annotation

#### build_runner 代码生成
- ✅ 成功生成 3 个 `.freezed.dart` 和 `.g.dart` 文件
- ✅ 修复 settings_page.dart 语法错误

#### Week 3: Presentation 层
- ✅ `lib/presentation/providers/base/base_provider.dart` - Provider 基类
- ✅ `lib/presentation/providers/auth_provider.dart` - 认证状态管理
- ✅ `lib/presentation/providers/playlist_provider.dart` - 歌单状态管理
- ✅ `lib/presentation/providers/bilibili_provider.dart` - B站功能状态管理
- ✅ `lib/presentation/widgets/async_builder.dart` - 异步构建器组件
- ✅ `lib/presentation/widgets/error_banner.dart` - 错误提示组件
- ✅ `lib/presentation/widgets/empty_state.dart` - 空状态组件
- ✅ `lib/presentation/widgets/playlist_card.dart` - 歌单卡片组件
- ✅ `lib/presentation/widgets/widgets.dart` - Widgets 统一导出

#### Week 4: 数据层完善
- ✅ `lib/data/datasources/remote/playlist_remote_datasource.dart` - 歌单 API 调用
- ✅ `lib/data/datasources/remote/play_history_remote_datasource.dart` - 播放历史 API 调用
- ✅ `lib/data/datasources/remote/search_remote_datasource.dart` - 搜索 API 调用
- ✅ `lib/data/repositories/playlist_repository_impl.dart` - 歌单仓储实现
- ✅ `lib/data/repositories/play_history_repository_impl.dart` - 播放历史仓储实现
- ✅ `lib/data/repositories/search_repository_impl.dart` - 搜索仓储实现
- ✅ `lib/core/constants/storage_constants.dart` - 存储常量定义
- ✅ 修复所有编译错误（0 errors, ~130 warnings）

#### Week 5: 基础设施 + Token 管理
- ✅ `lib/core/network/dio_provider.dart` - Dio 单例管理
- ✅ `lib/core/di/service_factory.dart` - 依赖注入工厂
- ✅ 更新 RemoteDataSource 使用共享 Dio 实例
- ✅ 移除 PlaylistRemoteDataSource 和 Repository 中的 token 参数
- ✅ 验证编译通过（0 errors）

#### Week 5: main.dart 集成
- ✅ 初始化 `ServiceFactory.init()`（在 main() 函数中）
- ✅ 从 SharedPreferences 恢复 token 到 DioProvider
- ✅ 注册所有 Repository 到 MultiProvider
  - `AuthRepository`
  - `PlaylistRepository`
  - `BilibiliRepository`
  - `PlayHistoryRepository`
  - `SearchRepository`
- ✅ 保留旧 Providers 暂时共存（渐进式迁移策略）

#### Week 5: 组件迁移
- ✅ `lib/presentation/widgets/common/loading_overlay.dart`
- ✅ `lib/presentation/widgets/common/error_view.dart`
- ✅ `lib/presentation/widgets/common/empty_state_view.dart`
- ✅ `lib/presentation/widgets/cards/music_zone_card.dart`
- ✅ `lib/presentation/widgets/cards/playlist_card.dart`
- ✅ `lib/presentation/widgets/controls_panel.dart`
- ✅ `lib/presentation/widgets/audio_info.dart`
- ✅ `lib/presentation/widgets/my_drawer.dart`

#### Week 5: 路由迁移
- ✅ `lib/routes/router.dart` → `lib/presentation/routes/router.dart`
- ✅ 更新 main.dart 导入路径

#### Week 5: 页面迁移
- ✅ `lib/ui/pages/` → `lib/presentation/pages/` (13个页面)
- ✅ `home_page.dart`
- ✅ `login_page.dart`
- ✅ `register_page.dart`
- ✅ `reset_password_page.dart`
- ✅ `settings_page.dart`
- ✅ `search_page.dart`
- ✅ `explore_page.dart`
- ✅ `playlist_library_page.dart`
- ✅ `playlist_detail_page.dart`
- ✅ `play_history_page.dart`
- ✅ `play_list_page.dart`
- ✅ `download_list_page.dart`
- ✅ `backend_download_page.dart`

#### Week 5: 清理旧代码
- ✅ 删除 `lib/ui/pages/`
- ✅ 删除 `lib/ui/components/`
- ✅ 删除 `lib/ui/`
- ✅ 删除 `lib/routes/`

### P0 - 立即修复
| 任务 | 预计工作量 | 状态 |
|------|------------|------|
| 修复Timer内存泄漏 | 1小时 | ⏸️ 待开始 |
| 优化ListView性能 | 2小时 | ⏸️ 待开始 |
| 引入图片缓存 | 3小时 | ✅ 已完成 (cached_network_image) |

### P1 - 短期重构
| 任务 | 预计工作量 | 状态 |
|------|------------|------|
| 拆分BilibiliProvider | 1天 | 🚧 P2中统一重构 |
| 提取重复UI组件 | 1天 | 🚧 P2中统一重构 |
| 创建BaseProvider基类 | 0.5天 | ✅ 已完成 |
| 优化context.watch使用 | 1天 | 🚧 P2中统一重构 |

### P2 - 长期优化
| 任务 | 预计工作量 | 状态 |
|------|------------|------|
| 重构为Clean Architecture | 3-5天 | ✅ 已完成 (100%) |
| 引入freezed代码生成 | 2天 | ✅ 已完成 |
| 完善单元测试 | 5天+ | ⏸️ 待开始 |

### P3 - 完全迁移进度

**完成日期**: 2026-01-21

| 阶段 | 任务 | 状态 |
|------|------|------|
| 阶段 1 | Models 整合 | ✅ 保留 lib/models/ 作为兼容层 |
| 阶段 2 | Providers 迁移 | ✅ 完成 |
| 阶段 3 | Services 整合 | ✅ 完成 |
| 阶段 4 | 常量和异常整合 | ✅ 保留现有结构 |
| 阶段 5 | 最终验证 | ✅ 0 errors |

**P3 完成内容**:

#### Providers 迁移到 presentation/providers/
- ✅ `lib/presentation/providers/audio/audio_provider.dart`
- ✅ `lib/presentation/providers/auth/auth_provider.dart`
- ✅ `lib/presentation/providers/bilibili/bilibili_provider.dart`
- ✅ `lib/presentation/providers/bilibili/qr_login_provider.dart`
- ✅ `lib/presentation/providers/bilibili/cache_provider.dart`
- ✅ `lib/presentation/providers/playlist/playlist_provider.dart`
- ✅ `lib/presentation/providers/play_history/play_history_provider.dart`
- ✅ `lib/presentation/providers/search/search_provider.dart`
- ✅ `lib/presentation/providers/theme/theme_provider.dart`

#### Services 整合
- ✅ `lib/data/managers/playlist_manager.dart` (从 services/ 迁移)
- ✅ `lib/utils/file_picker.dart` (从 services/ 迁移)
- ✅ 删除 `lib/services/secure_storage_service.dart` (未使用)

#### 保留的结构
- `lib/models/` - 作为兼容层保留（与 domain/entities/ 共存）
- `lib/constants/` - dimens.dart 仍在使用
- `lib/exceptions/` - api_exception.dart 仍在使用
- `lib/services/api_service.dart` - 保留（大量依赖）
- `lib/services/bilibiliApiService.dart` - 保留（大量依赖）
- `lib/services/download_manager.dart` - 独立下载功能
- `lib/services/download/` - 下载模块

#### 最终目录结构
```
lib/
├── core/                    # 核心层
│   ├── base/
│   ├── constants/
│   ├── network/
│   ├── di/
│   └── errors/
├── domain/                  # 领域层
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/                    # 数据层
│   ├── datasources/
│   ├── repositories/
│   └── managers/           ← 新增
├── presentation/            # 表现层
│   ├── providers/          # 按功能分目录
│   │   ├── audio/
│   │   ├── auth/
│   │   ├── bilibili/
│   │   ├── playlist/
│   │   ├── play_history/
│   │   ├── search/
│   │   └── theme/
│   ├── pages/
│   ├── widgets/
│   └── routes/
├── services/               # 独立服务
│   ├── download/
│   ├── api_service.dart
│   ├── bilibiliApiService.dart
│   └── download_manager.dart
├── models/                 # 兼容层（保留）
├── constants/              # UI常量（保留）
├── exceptions/             # 异常类（保留）
├── theme/
└── utils/
```

**编译状态**: ✅ 0 errors

---

*本文档由 Claude Code 生成 | 创建: 2026-01-20 | 最后更新: 2026-01-21*
