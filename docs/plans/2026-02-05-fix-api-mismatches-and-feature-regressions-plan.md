# 修复计划：API 不匹配与功能回归（2026-02-05）

> **版本**: v2.1 (补充搜索与本地导入功能)
> **状态**: Phase 1-5 已完成 (2026-02-05)
> **预计工期**: 4-5 天（单人）

---

## 1. 概述

### 1.1 目标
1. 修复前后端 API 契约不匹配导致的功能不可用问题
2. 完善环境配置校验
3. 定位并修复主题切换问题
4. **实现搜索功能（B站网络搜索）**
5. **实现本地音频导入功能（非上传到服务器）**
6. 补充测试覆盖防止回归

### 1.2 产品定位澄清

**重要区分**：
- **导入本地音频** ✅ 需要实现 - 用户选择本地音频文件，应用提取元数据并添加到本地数据库，可在应用内播放管理
- **上传音频到服务器** ❌ 不需要 - 本项目没有云端存储需求，所有音频文件均存储在用户设备本地

### 1.3 影响范围
| 模块 | 文件 | 影响功能 |
|------|------|----------|
| 后端路由 | `listen-vision_api/routes/playlists.js` | 歌单项获取 404 |
| 后端控制器 | `listen-vision_api/controllers/*.js` | 收藏状态、元数据格式 |
| 后端启动 | `listen-vision_api/index.js` | JWT 配置校验 |
| 前端 API 客户端 | `frontend_flutter/lib/data/api/backend_api_client.dart` | 字段解析 |
| 前端主题 | `frontend_flutter/lib/presentation/viewmodels/system/theme_viewmodel.dart` | 主题切换 |
| **前端搜索** | `frontend_flutter/lib/presentation/views/discovery/search_page.dart` | **B站搜索功能实现** |
| **前端本地音频** | `frontend_flutter/lib/data/repositories/local_music_repository.dart` | **本地音乐歌单导入** |

### 1.4 问题清单（已验证）

| ID | 问题描述 | 严重程度 | 验证位置 |
|----|----------|----------|----------|
| P1 | 前端调用 `GET /playlists/:id/items`，后端未实现该路由 | 严重 | [api_constants.dart:67](../frontend_flutter/lib/core/constants/api_constants.dart#L67) |
| P2 | 后端返回 `favorited`，前端期望 `isFavorite` | 严重 | [playlistController.js:159](../listen-vision_api/controllers/playlistController.js#L159) |
| P3 | 批量元数据返回嵌套数组，格式可能不符合前端预期 | 中 | [audioController.js:84](../listen-vision_api/controllers/audioController.js#L84) |
| P4 | 缺少 JWT_SECRET 启动校验，导致运行时报错 | 中 | [index.js:1-80](../listen-vision_api/index.js#L1-L80) |
| P5 | 主题切换日志显示状态变更，但 UI 未更新（根因待查） | 中 | [app.dart:15](../frontend_flutter/lib/app.dart#L15) |
| **P6** | **搜索页面只有 UI 壳，无实际B站搜索功能** | **高** | [search_page.dart:33](../frontend_flutter/lib/presentation/views/discovery/search_page.dart#L33) |
| **P7** | **本地音频导入功能完全未实现（仅有入口按钮，导入后应作为"本地音乐"歌单管理）** | **高** | [home_page.dart:46](../frontend_flutter/lib/presentation/views/player/home_page.dart#L46) |

---

## 2. 分阶段执行计划

### Phase 1: API 契约修复（高优先级）

**目标**: 恢复歌单、收藏等核心功能
**预计工时**: 0.75 天

#### 1.1 后端添加歌单项路由

**文件**: `listen-vision_api/routes/playlists.js`

```javascript
// 在第 92 行后添加
/**
 * @swagger
 * /api/playlists/{id}/items:
 *   get:
 *     tags: [歌单]
 *     summary: 获取歌单项列表
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: 获取成功
 */
router.get('/:id/items', authMiddleware, playlistController.getPlaylistItems);
```

**文件**: `listen-vision_api/controllers/playlistController.js`

```javascript
// 在 module.exports 前添加方法
const getPlaylistItems = catchAsync(async (req, res) => {
  const { id } = req.params;

  // 复用现有的 getPlaylistDetail 服务方法
  const detail = await playlistService.getPlaylistDetail(
    parseInt(id),
    req.user.id,
    'position_asc'
  );

  return successResponse(res, { items: detail.items }, '获取歌单项成功');
});

// 在 module.exports 中导出
module.exports = {
  // ...
  getPlaylistItems,  // 新增
  // ...
};
```

**验证**: 运行后端，curl 测试 `GET /api/v1/playlists/1/items` 返回 200 且包含 items 数组

---

#### 1.2 收藏字段兼容

**文件**: `listen-vision_api/controllers/playlistController.js:154-160`

```javascript
const checkFavorite = catchAsync(async (req, res) => {
  const { bvid } = req.params;

  const favorited = await playlistService.isFavorited(req.user.id, bvid);

  // 兼容双字段，前端可使用任一字段
  return successResponse(res, {
    favorited,
    isFavorite: favorited  // 新增兼容字段
  }, '检查收藏状态成功');
});
```

**验证**: curl 测试 `GET /api/v1/playlists/favorites/check/BV1xx411c7mD` 返回包含 `favorited` 和 `isFavorite` 字段

---

#### 1.3 批量元数据格式统一

**文件**: `listen-vision_api/controllers/audioController.js:68-96`

```javascript
const getMultipleMetadata = async (req, res) => {
  try {
    const { bvids } = req.body;

    if (!Array.isArray(bvids) || bvids.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'bvids 参数必须是非空数组'
      });
    }

    const limitedBvids = bvids.slice(0, 50);

    const metadataMap = await audioService.getMultipleMetadata(limitedBvids);

    // 改为对象格式，key 为 bvid
    const metadataObj = {};
    for (const [bvid, data] of metadataMap.entries()) {
      metadataObj[bvid] = data;
    }

    successResponse(res, { metadata: metadataObj });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};
```

**验证**: POST 测试包含多个 bvid 的请求，返回格式为 `{ metadata: { "BV1xx": { ... }, ... } }`

---

### Phase 2: 环境配置校验（中优先级）

**目标**: 确保服务启动时环境变量完整
**预计工时**: 0.25 天

#### 2.1 添加启动时环境检查

**文件**: `listen-vision_api/index.js`

```javascript
// 在第 3 行 dotenv.config() 后添加

// ========== 环境变量校验 ==========
const requiredEnvVars = ['JWT_SECRET', 'DATABASE_PATH'];
const missingEnvVars = requiredEnvVars.filter(key => !process.env[key]);

if (missingEnvVars.length > 0) {
  console.error('❌ 缺少必需的环境变量:');
  missingEnvVars.forEach(key => console.error(`   - ${key}`));
  console.error('\n请在 .env 文件中配置上述变量，参考 .env.example');
  process.exit(1);
}

logger.info('✅ 环境变量校验通过');
```

#### 2.2 更新 .env.example

**文件**: `listen-vision_api/.env.example`

```bash
# JWT 配置
JWT_SECRET=your_jwt_secret_key_here_change_it_in_production
JWT_EXPIRES_IN=7d

# 数据库
DATABASE_PATH=./data/listen-vision.db

# 邮件服务配置（可选）
SMTP_HOST=smtp.qq.com
SMTP_PORT=465
SMTP_SECURE=true
SMTP_USER=your_email@qq.com
SMTP_PASS=your_smtp_authorization_code

# 服务器配置
PORT=3000
NODE_ENV=development
```

**验证**:
1. 删除 .env 中的 JWT_SECRET，启动服务应报错并退出
2. 恢复 JWT_SECRET，服务正常启动

---

### Phase 3: 主题切换问题排查（中优先级）

**目标**: 定位并修复主题切换后 UI 不更新的问题
**预计工时**: 0.5 天

#### 3.1 问题诊断

**注意**: 原方案对主题切换的分析有误。当前代码使用 `ref.watch` 是**正确**的 Riverpod 模式，`ref.read` 不会触发重建。

**可能根因**:
1. `lightMode` / `darkMode` 常量对象引用未变化
2. `_loadThemePreference()` 异步加载延迟
3. `ThemeData` 对象比较问题

#### 3.2 诊断步骤

**文件**: `frontend_flutter/lib/presentation/viewmodels/system/theme_viewmodel.dart`

```dart
// 在 toggleTheme() 中添加诊断日志
void toggleTheme() {
  final oldState = state;
  if (state == lightMode) {
    state = darkMode;
  } else {
    state = lightMode;
  }
  AppLogger.info('ThemeViewModel', '主题切换: ${oldState == state ? "未变化" : "已变化"}');
  AppLogger.info('ThemeViewModel', '新主题引用: ${state.hashCode}');
  _saveThemePreference();
}
```

**文件**: `frontend_flutter/lib/app.dart`

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final themeNotifier = ref.watch(themeViewModelProvider);

  // 添加监听日志
  ref.listen<ThemeData>(themeViewModelProvider, (previous, next) {
    AppLogger.debug('App', 'Theme changed: prev=${previous.hashCode} next=${next.hashCode}');
  });

  return MaterialApp.router(
    title: 'ListenVision',
    debugShowCheckedModeBanner: false,
    theme: themeNotifier.themeData,  // 直接使用 ThemeData
    routerConfig: routerConfig,
  );
}
```

#### 3.3 修复方案（推荐：使用 ThemeMode 模式）

**文件**: `frontend_flutter/lib/presentation/viewmodels/system/theme_viewmodel.dart`

```dart
/// 主题模式枚举
enum AppThemeMode {
  light,
  dark,
  system,
}

/// 主题 ViewModel
@riverpod
class ThemeViewModel extends _$ThemeViewModel {
  @override
  AppThemeMode build() => AppThemeMode.light;

  void toggleTheme() {
    state = state == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light;
    _saveThemePreference();
  }

  void setLightMode() {
    state = AppThemeMode.light;
    _saveThemePreference();
  }

  void setDarkMode() {
    state = AppThemeMode.dark;
    _saveThemePreference();
  }

  Future<void> _loadThemePreference() async {
    // ... 从本地加载
  }

  Future<void> _saveThemePreference() async {
    // ... 保存到本地
  }
}
```

**文件**: `frontend_flutter/lib/app.dart`

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final themeMode = ref.watch(themeViewModelProvider);

  return MaterialApp.router(
    title: 'ListenVision',
    debugShowCheckedModeBanner: false,
    themeMode: themeMode == AppThemeMode.light ? ThemeMode.light : ThemeMode.dark,
    theme: lightMode,
    darkTheme: darkMode,
    routerConfig: routerConfig,
  );
}
```

**验证**: 切换主题后 MaterialApp 实际应用新主题

---

### Phase 4: 搜索功能完整实现（高优先级）

**目标**: 实现搜索页面功能，仅支持B站网络搜索
**预计工时**: 1 天

#### 4.1 搜索功能架构说明

搜索功能仅支持**网络搜索**，用于发现新的音频内容：

| 搜索类型 | 用途 | 后端端点 | 状态 |
|---------|------|----------|------|
| **B站搜索** | 搜索 Bilibili 视频音频 | `GET /api/v1/bilibili/search` | ✅ 当前可用 |
| **其他平台** | 预留扩展（网易云、QQ音乐等） | - | ⏳ 未来扩展 |

**重要澄清**：
- ✅ **网络搜索** - 搜索B站等在线平台的音频内容
- ❌ **本地搜索** - 不在搜索页面提供，本地音频通过"本地音乐"歌单单独管理

**决策**: 搜索页面仅保留B站搜索，保持界面简洁。为将来可能添加的其他平台预留架构。

#### 4.2 更新 SearchViewModel

**文件**: `frontend_flutter/lib/presentation/viewmodels/discovery/search_viewmodel.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/api/backend_api_client.dart';

part 'search_viewmodel.freezed.dart';
part 'search_viewmodel.g.dart';

/// 搜索平台枚举（预留扩展）
enum SearchPlatform {
  bilibili,  // B站（当前唯一可用）
  // netease,   // 网易云音乐（未来扩展）
  // qqmusic,   // QQ音乐（未来扩展）
}

/// 搜索状态
@freezed
class SearchState with _$SearchState {
  /// 初始状态
  const factory SearchState.initial() = SearchStateInitial;

  /// 加载中
  const factory SearchState.loading() = SearchStateLoading;

  /// 搜索结果已加载
  const factory SearchState.resultsLoaded({
    required List<SearchResultItem> results,
    required String query,
    required SearchPlatform platform,
  }) = SearchStateResultsLoaded;

  /// 空闲状态
  const factory SearchState.idle({
    @Default([]) List<String> searchHistory,
    @Default([]) List<String> suggestions,
    @Default(SearchPlatform.bilibili) SearchPlatform platform,
  }) = SearchStateIdle;

  /// 错误
  const factory SearchState.error({
    required String message,
  }) = SearchStateError;
}

/// 搜索结果项
class SearchResultItem {
  final String bvid;
  final String title;
  final String? author;
  final String? coverUrl;
  final int? duration;
  final SearchPlatform platform;

  SearchResultItem({
    required this.bvid,
    required this.title,
    this.author,
    this.coverUrl,
    this.duration,
    required this.platform,
  });
}

/// 搜索 ViewModel
///
/// 职责：
/// 1. B站网络搜索
/// 2. 搜索历史管理
/// 3. 搜索建议
class SearchViewModel extends StateNotifier<SearchState> {
  final BackendApiClient _apiClient;

  SearchViewModel(this._apiClient) : super(const SearchState.initial()) {
    _initialize();
  }

  /// 初始化：加载搜索历史
  Future<void> _initialize() async {
    try {
      AppLogger.debug('SearchViewModel', '初始化');

      // 加载搜索历史
      final history = await _loadSearchHistoryFromServer();

      state = SearchState.idle(
        searchHistory: history,
        suggestions: const [],
      );

      AppLogger.debug('SearchViewModel', '初始化完成');
    } catch (e) {
      AppLogger.error('SearchViewModel', '初始化失败: $e');
      state = const SearchState.idle();
    }
  }

  /// 执行B站搜索
  ///
  /// @param keyword 搜索关键词
  /// @returns 是否成功
  Future<bool> search(String keyword) async {
    if (keyword.trim().isEmpty) {
      state = SearchState.resultsLoaded(
        results: const [],
        query: keyword,
        platform: SearchPlatform.bilibili,
      );
      return false;
    }

    try {
      AppLogger.info('SearchViewModel', 'B站搜索: $keyword');

      state = const SearchState.loading();

      final data = await _apiClient.searchBilibili(keyword);
      final videos = data['videos'] as List? ?? [];

      final results = videos.map((v) => SearchResultItem(
        bvid: v['bvid'] as String,
        title: v['title'] as String,
        author: v['author'] as String?,
        coverUrl: v['cover'] as String?,
        duration: _parseDuration(v['duration']),
        platform: SearchPlatform.bilibili,
      )).toList();

      state = SearchState.resultsLoaded(
        results: results,
        query: keyword,
        platform: SearchPlatform.bilibili,
      );

      // 添加到搜索历史
      await _addToSearchHistory(keyword);

      AppLogger.info('SearchViewModel', '搜索成功: ${results.length}条结果');
      return true;
    } catch (e) {
      AppLogger.error('SearchViewModel', '搜索失败: $e');
      state = SearchState.error(message: e.toString());
      return false;
    }
  }

  /// 获取搜索建议
  Future<bool> getSearchSuggestions(String prefix) async {
    if (prefix.trim().isEmpty) {
      _updateIdleState(suggestions: const []);
      return false;
    }

    try {
      AppLogger.debug('SearchViewModel', '获取搜索建议: $prefix');

      // B站搜索建议（可接入B站API）
      final suggestions = await _apiClient.getBilibiliSearchSuggestions(prefix);

      _updateIdleState(suggestions: suggestions);

      AppLogger.debug('SearchViewModel', '搜索建议: ${suggestions.length}条');
      return true;
    } catch (e) {
      AppLogger.error('SearchViewModel', '获取搜索建议失败: $e');
      return false;
    }
  }

  /// 清空搜索建议
  void clearSearchSuggestions() {
    _updateIdleState(suggestions: const []);
  }

  /// 加载用户搜索历史
  Future<bool> loadSearchHistory() async {
    try {
      AppLogger.debug('SearchViewModel', '加载搜索历史');

      final history = await _loadSearchHistoryFromServer();

      state.maybeWhen(
        idle: (_, suggestions) {
          state = SearchState.idle(
            searchHistory: history,
            suggestions: suggestions,
          );
        },
        orElse: () {
          state = SearchState.idle(
            searchHistory: history,
            suggestions: const [],
          );
        },
      );

      AppLogger.debug('SearchViewModel', '搜索历史: ${history.length}条');
      return true;
    } catch (e) {
      AppLogger.error('SearchViewModel', '加载搜索历史失败: $e');
      return false;
    }
  }

  /// 从搜索历史中删除关键词
  void removeFromHistory(String keyword) {
    state.maybeWhen(
      idle: (history, suggestions) {
        final updatedHistory = List<String>.from(history)..remove(keyword);
        state = SearchState.idle(
          searchHistory: updatedHistory,
          suggestions: suggestions,
        );
      },
      orElse: () {},
    );
  }

  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    try {
      await _apiClient.clearBilibiliSearchHistory();

      state.maybeWhen(
        idle: (_, suggestions) {
          state = SearchState.idle(
            searchHistory: const [],
            suggestions: suggestions,
          );
        },
        orElse: () {},
      );

      AppLogger.info('SearchViewModel', '清空搜索历史成功');
    } catch (e) {
      AppLogger.error('SearchViewModel', '清空搜索历史失败: $e');
    }
  }

  /// 清空搜索结果
  void clearSearchResults() {
    state.maybeWhen(
      resultsLoaded: (_, __, ___) {
        state = SearchState.idle(
          searchHistory: state.maybeWhen(
            idle: (history, _) => history,
            orElse: () => const [],
          ),
          suggestions: state.maybeWhen(
            idle: (_, suggestions) => suggestions,
            orElse: () => const [],
          ),
        );
      },
      orElse: () {},
    );
  }

  /// 清除错误信息
  void clearError() {
    state.maybeWhen(
      error: (_) {
        state = const SearchState.idle();
      },
      orElse: () {},
    );
  }

  // ==================== 私有方法 ====================

  Future<List<String>> _loadSearchHistoryFromServer() async {
    try {
      return await _apiClient.getBilibiliSearchHistory();
    } catch (e) {
      AppLogger.error('SearchViewModel', '加载搜索历史失败: $e');
      return const [];
    }
  }

  Future<void> _addToSearchHistory(String keyword) async {
    try {
      await _apiClient.addBilibiliSearchHistory(keyword);
    } catch (e) {
      AppLogger.error('SearchViewModel', '添加搜索历史失败: $e');
    }
  }

  void _updateIdleState({
    List<String>? searchHistory,
    List<String>? suggestions,
  }) {
    state.maybeWhen(
      idle: (history, currentSuggestions) {
        state = SearchState.idle(
          searchHistory: searchHistory ?? history,
          suggestions: suggestions ?? currentSuggestions,
        );
      },
      orElse: () {
        state = SearchState.idle(
          searchHistory: searchHistory ?? const [],
          suggestions: suggestions ?? const [],
        );
      },
    );
  }

  /// 解析时长字符串（如 "03:45" -> 225秒）
  int? _parseDuration(dynamic duration) {
    if (duration == null) return null;
    if (duration is int) return duration;
    if (duration is String) {
      final parts = duration.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        return minutes * 60 + seconds;
      }
    }
    return null;
  }
}

/// Provider 定义
@riverpod
BackendApiClient searchBackendApiClient(SearchBackendApiClientRef ref) {
  return BackendApiClient();
}

@riverpod
SearchViewModel searchViewModel(SearchViewModelRef ref) {
  final apiClient = ref.watch(searchBackendApiClientProvider);
  return SearchViewModel(apiClient);
}
```

#### 4.3 更新 SearchPage

**文件**: `frontend_flutter/lib/presentation/views/discovery/search_page.dart`

```dart
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/viewmodels/discovery/search_viewmodel.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 搜索页面
///
/// 仅支持B站网络搜索，用于发现新的音频内容
/// 本地音频通过"本地音乐"歌单单独管理
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // 调用 SearchViewModel 执行B站搜索
    ref.read(searchViewModelProvider.notifier).search(query);
  }

  void _onResultTap(SearchResultItem item) {
    // 导航到播放器页面，播放B站音频
    context.push('/player?bvid=${item.bvid}');
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '搜索B站',
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      hintText: '搜索B站音频...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _performSearch(),
                    onChanged: (value) {
                      // 获取搜索建议
                      if (value.length >= 2) {
                        ref.read(searchViewModelProvider.notifier)
                            .getSearchSuggestions(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('搜索'),
                ),
              ],
            ),
          ),
          // 平台指示器（简洁显示）
          _buildPlatformIndicator(),
          // 搜索结果或状态
          Expanded(
            child: searchState.when(
              initial: () => _buildInitialState(),
              loading: () => const Center(child: CircularProgressIndicator()),
              resultsLoaded: (results, query, platform) => _buildResultsList(results),
              idle: (history, suggestions, platform) => _buildIdleState(history, suggestions),
              error: (message) => Center(child: Text('错误: $message')),
            ),
          ),
        ],
      ),
    );
  }

  /// 初始状态
  Widget _buildInitialState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('请输入关键词搜索B站音频'),
        ],
      ),
    );
  }

  /// 平台指示器（简洁显示当前平台）
  Widget _buildPlatformIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.video_library,
                  size: 14,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  'Bilibili',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '搜索B站视频音频内容',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 搜索结果列表
  Widget _buildResultsList(List<SearchResultItem> results) {
    if (results.isEmpty) {
      return const Center(child: Text('未找到结果'));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          leading: item.coverUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    item.coverUrl!,
                    width: 80,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note),
                    ),
                  ),
                )
              : Container(
                  width: 80,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.music_note),
                ),
          title: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${item.author ?? '未知UP主'} · ${_formatDuration(item.duration)}',
          ),
          onTap: () => _onResultTap(item),
        );
      },
    );
  }

  /// 空闲状态（搜索历史和搜索建议）
  Widget _buildIdleState(List<String> history, List<String> suggestions) {
    return ListView(
      children: [
        // 搜索建议
        if (suggestions.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '搜索建议',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...suggestions.map((s) => ListTile(
            leading: const Icon(Icons.search, color: Colors.grey),
            title: Text(s),
            dense: true,
            onTap: () {
              _searchController.text = s;
              _performSearch();
            },
          )),
        ],
        // 搜索历史
        if (history.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '搜索历史',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(searchViewModelProvider.notifier).clearSearchHistory();
                  },
                  child: const Text('清空'),
                ),
              ],
            ),
          ),
          ...history.map((h) => ListTile(
            leading: const Icon(Icons.history, color: Colors.grey),
            title: Text(h),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                ref.read(searchViewModelProvider.notifier).removeFromHistory(h);
              },
            ),
            dense: true,
            onTap: () {
              _searchController.text = h;
              _performSearch();
            },
          )),
        ],
        // 为空状态
        if (history.isEmpty && suggestions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                '输入关键词开始搜索B站音频',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  /// 格式化时长
  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
```

#### 4.4 BackendApiClient 添加B站搜索方法

**文件**: `frontend_flutter/lib/data/api/backend_api_client.dart`

在 `BackendApiClient` 类中添加以下方法：

```dart
  // ==================== B站搜索 API ====================

  /// B站搜索
  Future<Map<String, dynamic>> searchBilibili(String keyword) async {
    try {
      final response = await _dioClient.get(
        BilibiliEndpoints.search,
        queryParameters: {'keyword': keyword},
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('BackendApiClient', 'B站搜索失败: $e');
      rethrow;
    }
  }

  /// 获取B站搜索建议
  Future<List<String>> getBilibiliSearchSuggestions(String keyword) async {
    try {
      final response = await _dioClient.get(
        BilibiliEndpoints.searchRecent,
        queryParameters: {'keyword': keyword},
      );
      final data = _handleResponse(response);
      final suggestions = data['suggestions'] as List?;
      return suggestions?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取B站搜索建议失败: $e');
      return [];
    }
  }

  /// 获取B站搜索历史
  Future<List<String>> getBilibiliSearchHistory() async {
    try {
      final response = await _dioClient.get(BilibiliEndpoints.searchRecent);
      final data = _handleResponse(response);
      final history = data['history'] as List?;
      return history?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      AppLogger.error('BackendApiClient', '获取B站搜索历史失败: $e');
      return [];
    }
  }

  /// 添加B站搜索历史
  Future<void> addBilibiliSearchHistory(String keyword) async {
    try {
      await _dioClient.post(
        BilibiliEndpoints.searchRecent,
        data: {'keyword': keyword},
      );
    } catch (e) {
      AppLogger.error('BackendApiClient', '添加B站搜索历史失败: $e');
    }
  }

  /// 清空B站搜索历史
  Future<void> clearBilibiliSearchHistory() async {
    try {
      await _dioClient.delete(BilibiliEndpoints.searchRecent);
    } catch (e) {
      AppLogger.error('BackendApiClient', '清空B站搜索历史失败: $e');
    }
  }
```

#### 4.5 验收标准

- [ ] 搜索页面显示B站平台标识
- [ ] B站搜索返回视频列表，点击可播放
- [ ] 搜索历史正确保存和显示
- [ ] 搜索建议功能正常工作
- [ ] 界面保持简洁，无多余选项

---

### Phase 5: 本地音频导入功能实现（高优先级）

**目标**: 实现本地音频文件导入功能（非上传到服务器），导入后以"本地音乐"歌单形式管理
**预计工时**: 1 天

#### 5.1 功能说明

**本地音频导入** 是指：
1. 用户从设备存储选择音频文件（MP3, M4A, FLAC 等）
2. 应用提取音频元数据（标题、艺术家、专辑、封面）
3. 保存文件路径和元数据到本地 SQLite 数据库
4. **导入的本地音频以"本地音乐"歌单形式展示和管理**

**重要区分**：
- ✅ **本地音频** = 以特殊歌单形式管理（类似"本地音乐"歌单）
- ❌ **搜索本地音频** = 不在搜索页面提供，直接在"本地音乐"歌单中查看
- ❌ **上传到服务器** = 不涉及，所有数据存储在用户设备本地

**管理方式**：
- 本地音频作为**系统预设的特殊歌单**"本地音乐"管理
- 可在歌单列表中看到"本地音乐"歌单
- 点击进入可查看、播放所有导入的本地音频
- 支持添加/删除本地音频文件

#### 5.2 本地音乐歌单模型

**文件**: `frontend_flutter/lib/models/local_music_playlist.dart` (新建)

```dart
import 'dart:typed_data';

/// 本地音乐项
///
/// 表示一个导入的本地音频文件
class LocalMusicItem {
  final String id;
  final String filePath;
  final String title;
  final String? artist;
  final String? album;
  final int? duration;  // 秒
  final String? coverPath;  // 封面缓存路径
  final DateTime addedAt;

  LocalMusicItem({
    required this.id,
    required this.filePath,
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.coverPath,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'file_path': filePath,
    'title': title,
    'artist': artist,
    'album': album,
    'duration': duration,
    'cover_path': coverPath,
    'added_at': addedAt.toIso8601String(),
  };

  factory LocalMusicItem.fromJson(Map<String, dynamic> json) => LocalMusicItem(
    id: json['id'] as String,
    filePath: json['file_path'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String?,
    album: json['album'] as String?,
    duration: json['duration'] as int?,
    coverPath: json['cover_path'] as String?,
    addedAt: DateTime.parse(json['added_at'] as String),
  );

  LocalMusicItem copyWith({
    String? id,
    String? filePath,
    String? title,
    String? artist,
    String? album,
    int? duration,
    String? coverPath,
    DateTime? addedAt,
  }) => LocalMusicItem(
    id: id ?? this.id,
    filePath: filePath ?? this.filePath,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    album: album ?? this.album,
    duration: duration ?? this.duration,
    coverPath: coverPath ?? this.coverPath,
    addedAt: addedAt ?? this.addedAt,
  );
}

/// 本地音乐歌单
///
/// 系统预设的特殊歌单，管理所有导入的本地音频
class LocalMusicPlaylist {
  static const String playlistId = 'local_music';
  static const String playlistName = '本地音乐';
  static const String playlistDescription = '导入的本地音频文件';

  final List<LocalMusicItem> items;
  final DateTime updatedAt;

  LocalMusicPlaylist({
    required this.items,
    required this.updatedAt,
  });

  int get itemCount => items.length;

  int get totalDuration => items.fold(0, (sum, item) => sum + (item.duration ?? 0));

  String? get coverUrl => items.isNotEmpty ? items.first.coverPath : null;
}
```

```dart
import '../../core/utils/app_logger.dart';
import '../../models/local_audio.dart';
import '../api/local_audio_database.dart';  // 本地数据库操作

/// 本地音频仓库
///
/// 负责本地音频文件的元数据管理和数据库操作
class LocalAudioRepository {
  final LocalAudioDatabase _database;

  LocalAudioRepository({LocalAudioDatabase? database})
      : _database = database ?? LocalAudioDatabase.instance;

  /// 获取所有本地音频
  Future<List<LocalAudio>> getAllLocalAudios() async {
    try {
      return await _database.getAllAudios();
    } catch (e) {
      AppLogger.error('LocalAudioRepository', '获取本地音频失败: $e');
      return [];
    }
  }

  /// 根据 ID 获取本地音频
  Future<LocalAudio?> getLocalAudioById(String id) async {
    try {
      return await _database.getAudioById(id);
    } catch (e) {
      AppLogger.error('LocalAudioRepository', '获取本地音频失败: $e');
      return null;
    }
  }

  /// 添加本地音频
  Future<LocalAudio> addLocalAudio(LocalAudio audio) async {
    try {
      final id = await _database.insertAudio(audio);
      return audio.copyWith(id: id.toString());
    } catch (e) {
      AppLogger.error('LocalAudioRepository', '添加本地音频失败: $e');
      rethrow;
    }
  }

  /// 更新本地音频
  Future<bool> updateLocalAudio(LocalAudio audio) async {
    try {
      await _database.updateAudio(audio);
      return true;
    } catch (e) {
      AppLogger.error('LocalAudioRepository', '更新本地音频失败: $e');
      return false;
    }
  }

  /// 删除本地音频（仅删除数据库记录，不删除文件）
  Future<bool> deleteLocalAudio(String id) async {
    try {
      await _database.deleteAudio(id);
      return true;
    } catch (e) {
      AppLogger.error('LocalAudioRepository', '删除本地音频失败: $e');
      return false;
    }
  }

  /// 搜索本地音频
  Future<List<LocalAudio>> searchLocalAudios(String keyword) async {
    try {
      return await _database.searchAudios(keyword);
    } catch (e) {
      AppLogger.error('LocalAudioRepository', '搜索本地音频失败: $e');
      return [];
    }
  }
}
```

#### 5.3 数据层实现

**文件**: `frontend_flutter/lib/data/repositories/local_music_repository.dart` (新建)

```dart
import '../../core/utils/app_logger.dart';
import '../../models/local_music_playlist.dart';
import '../database/local_music_database.dart';

/// 本地音乐仓库
///
/// 负责本地音乐歌单的数据管理
class LocalMusicRepository {
  final LocalMusicDatabase _database;

  LocalMusicRepository({LocalMusicDatabase? database})
      : _database = database ?? LocalMusicDatabase.instance;

  /// 获取本地音乐歌单
  Future<LocalMusicPlaylist> getLocalMusicPlaylist() async {
    try {
      final items = await _database.getAllItems();
      return LocalMusicPlaylist(
        items: items,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('LocalMusicRepository', '获取本地音乐歌单失败: $e');
      return LocalMusicPlaylist(items: [], updatedAt: DateTime.now());
    }
  }

  /// 添加本地音乐项
  Future<LocalMusicItem> addLocalMusic(LocalMusicItem item) async {
    try {
      final newItem = item.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        addedAt: DateTime.now(),
      );
      await _database.insertItem(newItem);
      return newItem;
    } catch (e) {
      AppLogger.error('LocalMusicRepository', '添加本地音乐失败: $e');
      rethrow;
    }
  }

  /// 删除本地音乐项
  Future<bool> deleteLocalMusic(String id) async {
    try {
      await _database.deleteItem(id);
      return true;
    } catch (e) {
      AppLogger.error('LocalMusicRepository', '删除本地音乐失败: $e');
      return false;
    }
  }

  /// 检查文件是否已导入
  Future<bool> isFileImported(String filePath) async {
    try {
      return await _database.existsByFilePath(filePath);
    } catch (e) {
      AppLogger.error('LocalMusicRepository', '检查文件导入状态失败: $e');
      return false;
    }
  }
}
```

#### 5.4 本地数据库实现

**文件**: `frontend_flutter/lib/data/database/local_music_database.dart` (新建)

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../core/utils/app_logger.dart';
import '../../models/local_music_playlist.dart';

/// 本地音乐数据库
///
/// 使用 SQLite 存储本地音乐歌单的元数据
class LocalMusicDatabase {
  static final LocalAudioDatabase instance = LocalAudioDatabase._init();
  static Database? _database;

  LocalAudioDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('local_audio.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const intType = 'INTEGER';

    await db.execute('''
      CREATE TABLE local_audios (
        id $idType,
        file_path $textType NOT NULL,
        title $textType,
        artist $textType,
        album $textType,
        duration $intType,
        cover_path $textType,
        added_at $textType,
        updated_at $textType
      )
    ''');

    // 创建全文搜索索引
    await db.execute('''
      CREATE VIRTUAL TABLE local_audios_fts USING fts5(
        title,
        artist,
        album,
        content='local_audios',
        content_rowid='id'
      )
    ''');
  }

  /// 插入音乐项
  Future<int> insertItem(LocalMusicItem item) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final data = item.copyWith(id: id).toJson();
    
    await db.insert('local_audios', data);
    
    // 同步到 FTS 索引（用于后续可能的本地音乐内搜索）
    await db.execute('''
      INSERT INTO local_audios_fts(title, artist, album)
      VALUES (?, ?, ?)
    ''', [item.title, item.artist, item.album]);
    
    AppLogger.info('LocalMusicDatabase', '插入音乐项: $id - ${item.title}');
    return int.parse(id);
  }

  /// 获取所有音乐项
  Future<List<LocalMusicItem>> getAllItems() async {
    final db = await database;
    final maps = await db.query('local_audios', orderBy: 'added_at DESC');
    return maps.map((m) => LocalMusicItem.fromJson(m)).toList();
  }

  /// 根据 ID 获取音乐项
  Future<LocalMusicItem?> getItemById(String id) async {
    final db = await database;
    final maps = await db.query(
      'local_audios',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return LocalMusicItem.fromJson(maps.first);
    }
    return null;
  }

  /// 根据文件路径检查是否已存在
  Future<bool> existsByFilePath(String filePath) async {
    final db = await database;
    final maps = await db.query(
      'local_audios',
      where: 'file_path = ?',
      whereArgs: [filePath],
    );
    return maps.isNotEmpty;
  }

  /// 删除音乐项
  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete(
      'local_audios',
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'local_audios_fts',
      where: 'rowid = ?',
      whereArgs: [id],
    );
  }
}
```

#### 5.5 ViewModel 实现

**文件**: `frontend_flutter/lib/presentation/viewmodels/library/local_music_viewmodel.dart` (新建)

```dart
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/file_picker_helper.dart';
import '../../../data/repositories/local_music_repository.dart';
import '../../../models/local_music_playlist.dart';
import '../../../services/metadata_service.dart';

part 'local_music_viewmodel.freezed.dart';
part 'local_music_viewmodel.g.dart';

/// 本地音乐状态
@freezed
class LocalMusicState with _$LocalMusicState {
  const factory LocalMusicState.initial() = LocalMusicStateInitial;
  const factory LocalMusicState.loading() = LocalMusicStateLoading;
  const factory LocalMusicState.loaded({
    required LocalMusicPlaylist playlist,
  }) = LocalMusicStateLoaded;
  const factory LocalMusicState.importing({
    required int current,
    required int total,
    required String currentFile,
  }) = LocalMusicStateImporting;
  const factory LocalMusicState.error({
    required String message,
  }) = LocalMusicStateError;
}

/// 本地音乐 ViewModel
///
/// 负责本地音乐歌单的管理和导入
@riverpod
class LocalMusicViewModel extends _$LocalMusicViewModel {
  late final LocalMusicRepository _repository;
  late final MetadataService _metadataService;
  late final FilePickerService _filePicker;

  @override
  LocalMusicState build() {
    _repository = ref.read(localMusicRepositoryProvider);
    _metadataService = ref.read(metadataServiceProvider);
    _filePicker = FilePickerService();
    _loadPlaylist();
    return const LocalMusicState.initial();
  }

  /// 加载本地音乐歌单
  Future<void> _loadPlaylist() async {
    state = const LocalMusicState.loading();
    try {
      final playlist = await _repository.getLocalMusicPlaylist();
      state = LocalMusicState.loaded(playlist: playlist);
    } catch (e) {
      AppLogger.error('LocalMusicViewModel', '加载歌单失败: $e');
      state = LocalMusicState.error(message: e.toString());
    }
  }

  /// 刷新列表
  Future<void> refresh() async {
    await _loadPlaylist();
  }

  /// 导入音频文件
  ///
  /// 选择文件并提取元数据，保存到"本地音乐"歌单
  Future<void> importAudioFiles() async {
    try {
      // 选择文件
      final filePath = await _filePicker.pickAudioFile();
      if (filePath == null) return;

      // 检查文件是否已导入
      final isImported = await _repository.isFileImported(filePath);
      if (isImported) {
        AppLogger.info('LocalMusicViewModel', '文件已导入: $filePath');
        return;
      }

      state = const LocalMusicState.importing(
        current: 1,
        total: 1,
        currentFile: '',
      );

      // 提取元数据
      final metadata = await _metadataService.extractFromFile(filePath);

      // 保存封面图片（如果有）
      String? coverPath;
      if (metadata.cover != null) {
        coverPath = await _saveCoverImage(filePath, metadata.cover!);
      }

      // 创建本地音乐项
      final localMusicItem = LocalMusicItem(
        id: '',  // 将由数据库生成
        filePath: filePath,
        title: metadata.title.isNotEmpty ? metadata.title : _getFileName(filePath),
        artist: metadata.artist,
        album: metadata.album,
        duration: metadata.duration,
        coverPath: coverPath,
        addedAt: DateTime.now(),
      );

      // 保存到数据库
      await _repository.addLocalMusic(localMusicItem);

      // 刷新列表
      await _loadPlaylist();

      AppLogger.info('LocalMusicViewModel', '导入成功: ${localMusicItem.title}');
    } catch (e) {
      AppLogger.error('LocalMusicViewModel', '导入失败: $e');
      state = LocalMusicState.error(message: e.toString());
    }
  }

  /// 删除本地音乐
  Future<void> deleteLocalMusic(String id) async {
    try {
      final success = await _repository.deleteLocalMusic(id);
      if (success) {
        await _loadPlaylist();
      }
    } catch (e) {
      AppLogger.error('LocalMusicViewModel', '删除失败: $e');
    }
  }

  /// 批量导入音频文件
  Future<void> importMultipleFiles(List<String> filePaths) async {
    if (filePaths.isEmpty) return;

    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < filePaths.length; i++) {
      final filePath = filePaths[i];
      state = LocalMusicState.importing(
        current: i + 1,
        total: filePaths.length,
        currentFile: _getFileName(filePath),
      );

      try {
        // 检查是否已导入
        final isImported = await _repository.isFileImported(filePath);
        if (isImported) {
          continue;
        }

        // 提取元数据
        final metadata = await _metadataService.extractFromFile(filePath);

        // 保存封面
        String? coverPath;
        if (metadata.cover != null) {
          coverPath = await _saveCoverImage(filePath, metadata.cover!);
        }

        // 创建并保存
        final localMusicItem = LocalMusicItem(
          id: '',
          filePath: filePath,
          title: metadata.title.isNotEmpty ? metadata.title : _getFileName(filePath),
          artist: metadata.artist,
          album: metadata.album,
          duration: metadata.duration,
          coverPath: coverPath,
          addedAt: DateTime.now(),
        );

        await _repository.addLocalMusic(localMusicItem);
        successCount++;
      } catch (e) {
        AppLogger.error('LocalMusicViewModel', '导入文件失败: $filePath - $e');
        failCount++;
      }
    }

    await _loadPlaylist();

    AppLogger.info('LocalMusicViewModel', 
        '批量导入完成: 成功 $successCount, 失败 $failCount');
  }

  /// 删除本地音频
  Future<void> deleteLocalAudio(String id) async {
    try {
      final success = await _repository.deleteLocalAudio(id);
      if (success) {
        await _loadAudios();
      }
    } catch (e) {
      AppLogger.error('LocalAudioViewModel', '删除失败: $e');
    }
  }

  /// 保存封面图片到应用缓存目录
  Future<String> _saveCoverImage(String audioPath, Uint8List coverData) async {
    final appDir = await getApplicationDocumentsDirectory();
    final coverDir = Directory('${appDir.path}/covers');
    if (!await coverDir.exists()) {
      await coverDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final coverFile = File('${coverDir.path}/$fileName');
    await coverFile.writeAsBytes(coverData);

    return coverFile.path;
  }

  /// 从文件路径获取文件名（无扩展名）
  String _getFileName(String filePath) {
    final fileName = filePath.split(RegExp(r'[\/]')).last;
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex > 0) {
      return fileName.substring(0, lastDotIndex);
    }
    return fileName;
  }
}

/// Provider 定义
@riverpod
LocalAudioRepository localAudioRepository(LocalAudioRepositoryRef ref) {
  return LocalAudioRepository();
}

@riverpod
MetadataService metadataService(MetadataServiceRef ref) {
  return MetadataService();
}
```

#### 5.6 更新 HomePage 导入按钮

**文件**: `frontend_flutter/lib/presentation/views/player/home_page.dart`

```dart
Future<void> _handleFilePicker(BuildContext context, WidgetRef ref) async {
  try {
    // 调用 LocalMusicViewModel 导入音频到本地音乐歌单
    await ref.read(localMusicViewModelProvider.notifier).importAudioFiles();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已导入到"本地音乐"歌单')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: ${e.toString()}')),
      );
    }
  }
}
```

#### 5.7 本地音乐歌单页面

**文件**: `frontend_flutter/lib/presentation/views/library/local_music_playlist_page.dart` (新建)

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/local_music_playlist.dart';
import '../../viewmodels/library/local_music_viewmodel.dart';

/// 本地音乐歌单页面
///
/// 展示和管理"本地音乐"歌单中的音频文件
class LocalMusicPlaylistPage extends ConsumerWidget {
  const LocalMusicPlaylistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localMusicViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('本地音乐'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '导入音频',
            onPressed: () {
              ref.read(localMusicViewModelProvider.notifier).importAudioFiles();
            },
          ),
        ],
      ),
      body: state.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (playlist) => _buildPlaylistView(context, playlist, ref),
        importing: (current, total, currentFile) => _buildImportingView(context, current, total, currentFile),
        error: (message) => _buildErrorView(context, message),
      ),
    );
  }

  /// 歌单内容视图
  Widget _buildPlaylistView(BuildContext context, LocalMusicPlaylist playlist, WidgetRef ref) {
    if (playlist.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('本地音乐歌单是空的'),
            const SizedBox(height: 8),
            const Text(
              '导入的本地音频将显示在这里',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(localMusicViewModelProvider.notifier).importAudioFiles();
              },
              icon: const Icon(Icons.add),
              label: const Text('导入音频'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 歌单信息头
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: playlist.coverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(playlist.coverUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 40),
                        ),
                      )
                    : const Icon(Icons.music_note, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '本地音乐',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.itemCount}首歌曲',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        // 播放全部按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              // 播放全部本地音乐
              if (playlist.items.isNotEmpty) {
                context.push('/player?localId=${playlist.items.first.id}');
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('播放全部'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        // 歌曲列表
        Expanded(
          child: ListView.builder(
            itemCount: playlist.items.length,
            itemBuilder: (context, index) {
              final item = playlist.items[index];
              return ListTile(
                leading: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                title: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${item.artist ?? '未知艺术家'} · ${_formatDuration(item.duration)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showItemMenu(context, item, ref),
                ),
                onTap: () {
                  context.push('/player?localId=${item.id}');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// 导入中视图
  Widget _buildImportingView(BuildContext context, int current, int total, String currentFile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: current / total,
              strokeWidth: 6,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '导入中... $current/$total',
            style: const TextStyle(fontSize: 16),
          ),
          if (currentFile.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              currentFile,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// 错误视图
  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败: $message'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // 重试
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 显示歌曲菜单
  void _showItemMenu(BuildContext context, LocalMusicItem item, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(item.artist ?? '未知艺术家'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('播放'),
              onTap: () {
                Navigator.pop(context);
                context.push('/player?localId=${item.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('从歌单移除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, item, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 确认删除
  void _confirmDelete(BuildContext context, LocalMusicItem item, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要从"本地音乐"歌单中移除"${item.title}"吗？\n\n（不会删除原始文件）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(localMusicViewModelProvider.notifier).deleteLocalMusic(item.id);
            },
            child: const Text('移除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 格式化时长
  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
```

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../viewmodels/library/local_audio_viewmodel.dart';

/// 本地音频库页面
///
/// 展示和管理用户导入的本地音频文件
class LocalAudioLibraryPage extends ConsumerWidget {
  const LocalAudioLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localAudioViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('本地音频'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ref.read(localAudioViewModelProvider.notifier).importAudioFiles();
            },
          ),
        ],
      ),
      body: state.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (audios) {
          if (audios.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_note, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无本地音频'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(localAudioViewModelProvider.notifier).importAudioFiles();
                    },
                    child: const Text('导入音频'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: audios.length,
            itemBuilder: (context, index) {
              final audio = audios[index];
              return ListTile(
                leading: audio.coverPath != null
                    ? Image.file(
                        File(audio.coverPath!),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
                      )
                    : const Icon(Icons.music_note),
                title: Text(audio.title ?? '未知标题'),
                subtitle: Text(audio.artist ?? '未知艺术家'),
                trailing: Text(
                  _formatDuration(audio.duration),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  // 播放本地音频
                  context.push('/player?localId=${audio.id}');
                },
              );
            },
          );
        },
        importing: (current, total, currentFile) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: current / total,
              ),
              const SizedBox(height: 16),
              Text('导入中: $current/$total'),
              if (currentFile.isNotEmpty)
                Text(currentFile, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        error: (message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('错误: $message'),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
```

#### 5.8 在歌单列表中显示本地音乐歌单

**文件**: `frontend_flutter/lib/presentation/views/library/playlists_page.dart`

在歌单列表中添加特殊的"本地音乐"歌单项：

```dart
// 在歌单列表开头添加本地音乐歌单项
Widget _buildLocalMusicPlaylistTile(BuildContext context) {
  return ListTile(
    leading: Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.folder_special,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    ),
    title: const Text('本地音乐'),
    subtitle: Consumer(
      builder: (context, ref, child) {
        final localMusicState = ref.watch(localMusicViewModelProvider);
        return localMusicState.maybeWhen(
          loaded: (playlist) => Text('${playlist.itemCount}首歌曲'),
          orElse: () => const Text('导入的本地音频'),
        );
      },
    ),
    onTap: () {
      context.push('/playlist/local');
    },
  );
}
```

#### 5.9 路由配置

**文件**: `frontend_flutter/lib/core/router/router_config.dart`

添加本地音乐歌单页面路由：

```dart
GoRoute(
  path: '/playlist/local',
  builder: (context, state) => const LocalMusicPlaylistPage(),
),
```

#### 5.10 验收标准

- [ ] 点击首页导入按钮可以选择本地音频文件
- [ ] 选择后自动提取元数据（标题、艺术家、封面）
- [ ] 导入的音频保存到"本地音乐"歌单
- [ ] 在歌单列表中可以看到"本地音乐"歌单
- [ ] 进入本地音乐歌单可以查看所有导入的音频
- [ ] 可以播放本地音乐歌单中的音频
- [ ] 可以从歌单中移除音频（不删除原文件）

---

### Phase 6: 测试覆盖增强（中优先级）

**目标**: 防止回归，确保契约稳定
**预计工时**: 0.75 天

#### 6.1 后端集成测试

**文件**: `listen-vision_api/tests/integration/playlist.test.js` (新建)

```javascript
describe('GET /api/v1/playlists/:id/items', () => {
  it('应该返回歌单项列表', async () => {
    const response = await request(app)
      .get('/api/v1/playlists/1/items')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(Array.isArray(response.body.data.items)).toBe(true);
  });
});
```

#### 6.2 字段一致性测试

```javascript
describe('GET /api/v1/playlists/favorites/check/:bvid', () => {
  it('应同时返回 favorited 和 isFavorite 字段', async () => {
    const response = await request(app)
      .get('/api/v1/playlists/favorites/check/BV1test')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(response.body.data).toHaveProperty('favorited');
    expect(response.body.data).toHaveProperty('isFavorite');
    expect(response.body.data.favorited).toBe(response.body.data.isFavorite);
  });
});
```

#### 6.3 JWT 环境变量测试

```javascript
describe('环境变量校验', () => {
  const originalSecret = process.env.JWT_SECRET;

  afterEach(() => {
    process.env.JWT_SECRET = originalSecret;
  });

  it('缺少 JWT_SECRET 时应退出', () => {
    delete process.env.JWT_SECRET;
    expect(() => require('../../index')).toThrow();
  });
});
```

---

## 3. 验收标准

### Phase 1 验收
- [x] `GET /api/v1/playlists/:id/items` 返回 200 且包含 items 数组
- [x] `GET /api/v1/playlists/favorites/check/:bvid` 同时返回 favorited 和 isFavorite
- [x] `POST /api/v1/audio/metadata/batch` 返回对象格式 `{ "BV1xx": {...} }`

### Phase 2 验收
- [x] 无 JWT_SECRET 时服务启动失败并显示清晰错误信息
- [x] .env.example 包含所有必需变量

### Phase 3 验收
- [x] 主题切换后 UI 实时更新
- [x] 主题偏好持久化正确

### Phase 4 验收（搜索功能）
- [x] 搜索页面仅显示B站平台标识，保持简洁
- [x] B站搜索返回视频列表，点击可播放
- [x] 搜索历史正确保存和显示
- [x] 搜索建议功能正常工作

### Phase 5 验收（本地音频导入）
- [x] 点击首页导入按钮可以选择本地音频文件
- [x] 选择后自动提取元数据并保存到数据库
- [x] 导入的音频保存到"本地音乐"歌单
- [x] 在歌单列表中可以看到"本地音乐"歌单
- [x] 可以播放本地音乐歌单中的音频
- [x] 可以从歌单中移除音频（不删除原文件）

### Phase 6 验收
- [ ] 新增测试用例通过
- [ ] 测试覆盖率报告更新

---

## 4. 回滚策略

| 变更类型 | 回滚方式 | 风险等级 |
|----------|----------|----------|
| 后端新增路由 | 删除路由代码 | 低 |
| 后端字段兼容 | 删除 isFavorite 字段 | 低 |
| 元数据格式修改 | 恢复数组格式 | 中（前端需同步） |
| 环境校验 | 注释校验代码 | 低 |
| 搜索功能 | 回滚 SearchPage 和 ViewModel | 低 |
| 本地音频导入 | 删除 Repository 和 ViewModel | 低 |

---

## 5. 时间线总览

```
Day 1 上午: Phase 1.1-1.2 (歌单项路由 + 收藏字段)
Day 1 下午: Phase 1.3 (元数据格式) + Phase 2 (环境校验)
Day 2 上午: Phase 3 (主题排查 + 修复)
Day 2 下午: Phase 4 (搜索功能完整实现)
Day 3 上午: Phase 5 (本地音频导入功能)
Day 3 下午: Phase 6 (测试覆盖) + 回归测试
Day 4:      缓冲时间 + 文档更新
```

---

## 6. 参考资料

- [Riverpod 官方文档](../../references/riverpod/)
- [项目 RIVERPOD_GUIDE.md](../../docs/RIVERPOD_GUIDE.md)
- [后端 API 路由](../../listen-vision_api/routes/)
- [前端 API 客户端](../../frontend_flutter/lib/data/api/backend_api_client.dart)
- [产品需求文档 PRD.md](../../docs/PRD.md) - 本地音乐管理需求（第13项，第一阶段）
