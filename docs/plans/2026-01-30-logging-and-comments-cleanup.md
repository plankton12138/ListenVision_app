# 前端日志增强与代码注释规范化实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**目标：** 建立前端统一的日志检查点系统和规范的代码注释标准，提升代码可维护性和可调试性。

**架构：**
- 前端：扩展 AppLogger，添加用户操作追踪机制（导航、按钮点击、播放控制等）
- 后端：保持现有 Winston 日志系统，仅清理注释和补充算法文档
- 规范：制定统一的日志格式和注释标准

**技术栈：**
- 前端：AppLogger 单例 + Flutter NavigatorObserver
- 后端：Winston logger（现有）
- 文档：JSDoc / DartDoc 标准

---

## Part 1: 前端日志增强

### 日志架构说明

采用**双层日志**策略，实现用户操作到业务执行的全链路追踪：

```
UI 层日志 → Provider 层日志 → Controller 层日志
   ↓             ↓                ↓
用户点击      业务触发        执行结果
```

- **UI 层**：记录用户实际点击行为（按钮、输入、导航）
- **Provider 层**：记录业务逻辑触发（保持现有关键日志即可）
- **Controller 层**：记录执行状态和结果（现有日志已完善）

---

### Task 1: 扩展 AppLogger 支持用户操作追踪

**文件：**
- Modify: `frontend_flutter/lib/core/utils/app_logger.dart`

**Step 1: 添加用户操作日志方法**

在 `AppLogger` 类中添加：

```dart
/// 记录用户操作
///
/// 用于追踪用户在应用中的关键操作，如点击、导航、表单提交等
static void logUserAction(
  String feature,
  String action, {
  Map<String, dynamic>? parameters,
  String? userId,
}) {
  final data = <String, dynamic>{
    'action': action,
    'feature': feature,
    'timestamp': DateTime.now().toIso8601String(),
    if (userId != null) 'userId': userId,
    if (parameters != null) 'parameters': parameters,
  };

  info(feature, action, extra: data);
}

/// 记录页面导航
static void logNavigation(String from, String to, {String? userId}) {
  logUserAction(
    'Navigation',
    '页面跳转',
    parameters: {'from': from, 'to': to},
    userId: userId,
  );
}

/// 记录按钮点击
///
/// 参数：
/// - [button] 按钮名称（如 '播放', '暂停', '收藏'）
/// - [context] 所在页面/组件（如 'HomePage', 'PlayerBar'）
/// - [userId] 用户 ID（可选）
static void logButtonClick(String button, String context, {String? userId}) {
  logUserAction(
    context,
    '点击: $button',
    parameters: {'button': button},
    userId: userId,
  );
}

/// 记录表单提交
static void logFormSubmit(String formName, Map<String, dynamic> data, {String? userId}) {
  logUserAction(
    formName,
    '表单提交',
    parameters: {'fields': data.keys.toList()},
    userId: userId,
  );
}
```

**Step 2: 提交**

```bash
git add frontend_flutter/lib/core/utils/app_logger.dart
git commit -m "feat(logger): add UI action tracking methods"
```

---

### Task 2: 创建路由观察器记录导航日志

**文件：**
- Create: `frontend_flutter/lib/core/utils/app_route_observer.dart`

**Step 1: 实现路由观察器**

```dart
import 'package:flutter/material.dart';
import 'app_logger.dart';

/// 应用路由观察器
///
/// 功能：
/// - 记录所有页面导航事件
/// - 跟踪用户在应用中的路径
/// - 支持页面停留时间统计
class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  String? userId;

  String? _currentRoute;
  DateTime? _routeEnterTime;

  /// 设置用户 ID
  void setUserId(String? id) {
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

  void _logRouteChange(
    String action,
    Route<dynamic>? toRoute,
    Route<dynamic>? fromRoute,
  ) {
    final from = fromRoute?.settings.name ?? _getRouteName(fromRoute);
    final to = toRoute?.settings.name ?? _getRouteName(toRoute);

    if (_currentRoute != to && to != 'Unknown') {
      // 记录页面停留时间
      if (_routeEnterTime != null && _currentRoute != null) {
        final duration = DateTime.now().difference(_routeEnterTime!);
        AppLogger.debug(
          'RouteObserver',
          '页面停留: $_currentRoute (${duration.inSeconds}s)',
        );
      }

      AppLogger.logNavigation(from, to, userId: userId);

      _currentRoute = to;
      _routeEnterTime = DateTime.now();
    }
  }

  String _getRouteName(Route<dynamic>? route) {
    if (route == null) return 'Unknown';
    return route.settings.name ?? route.runtimeType.toString();
  }
}

/// 全局路由观察器实例
final appRouteObserver = AppRouteObserver();
```

**Step 2: 提交**

```bash
git add frontend_flutter/lib/core/utils/app_route_observer.dart
git commit -m "feat(logger): add route observer for navigation tracking"
```

---

### Task 3: 在主要 UI 页面添加按钮点击日志（核心任务）

**策略：在所有用户可交互的按钮 onPressed/onTap 处添加日志**

**文件清单：**
- `frontend_flutter/lib/presentation/pages/home_page.dart`
- `frontend_flutter/lib/presentation/pages/explore_page.dart`
- `frontend_flutter/lib/presentation/pages/play_history_page.dart`
- `frontend_flutter/lib/presentation/widgets/player_bar.dart`
- `frontend_flutter/lib/presentation/widgets/now_playing_bar.dart`

**Step 1: 在 HomePage 添加日志**

```dart
// 音频项点击 - 进入播放
onTap: () {
  AppLogger.logButtonClick('音频项-${audio.title}', 'HomePage');
  _playAudio(context, audio);
},

// 收藏按钮
onPressed: () {
  AppLogger.logButtonClick('收藏', 'HomePage');
  _toggleFavorite(audio);
},

// 更多选项
onPressed: () {
  AppLogger.logButtonClick('更多选项', 'HomePage');
  _showOptions(context, audio);
},
```

**Step 2: 在 ExplorePage 添加日志**

```dart
// 搜索按钮
onPressed: () {
  AppLogger.logButtonClick('搜索', 'ExplorePage', parameters: {'keyword': query});
  _performSearch(query);
},

// 筛选按钮
onPressed: () {
  AppLogger.logButtonClick('筛选', 'ExplorePage');
  _showFilterDialog();
},

// 音频项点击
onTap: () {
  AppLogger.logButtonClick('搜索结果-${audio.title}', 'ExplorePage');
  _playAudio(context, audio);
},
```

**Step 3: 在 PlayHistoryPage 添加日志**

```dart
// 历史记录项点击
onTap: () {
  AppLogger.logButtonClick('历史记录-${item.title}', 'PlayHistoryPage');
  _playFromHistory(context, item);
},

// 删除按钮
onPressed: () {
  AppLogger.logButtonClick('删除历史', 'PlayHistoryPage');
  _deleteHistory(item);
},

// 清空全部
onPressed: () {
  AppLogger.logButtonClick('清空历史', 'PlayHistoryPage');
  _clearAllHistory();
},
```

**Step 4: 在 PlayerBar 添加日志**

```dart
// 播放/暂停按钮
onPressed: () {
  if (isPlaying) {
    AppLogger.logButtonClick('暂停', 'PlayerBar');
  } else {
    AppLogger.logButtonClick('播放', 'PlayerBar');
  }
  _togglePlayPause();
},

// 下一首
onPressed: () {
  AppLogger.logButtonClick('下一首', 'PlayerBar');
  _playNext();
},

// 上一首
onPressed: () {
  AppLogger.logButtonClick('上一首', 'PlayerBar');
  _playPrevious();
},

// 进度条拖动
onChanged: (value) {
  AppLogger.logButtonClick('进度条', 'PlayerBar', parameters: {'position': value});
  _seekTo(value);
},
```

**Step 5: 在 NowPlayingBar 添加日志**

```dart
// 循环模式切换
onPressed: () {
  AppLogger.logButtonClick('循环模式', 'NowPlayingBar', parameters: {'mode': _nextMode()});
  _toggleLoopMode();
},

// 倍速切换
onPressed: () {
  AppLogger.logButtonClick('倍速', 'NowPlayingBar', parameters: {'speed': _nextSpeed()});
  _toggleSpeed();
},

// 收藏按钮
onPressed: () {
  AppLogger.logButtonClick('收藏', 'NowPlayingBar');
  _toggleFavorite();
},

// 下载按钮
onPressed: () {
  AppLogger.logButtonClick('下载', 'NowPlayingBar');
  _downloadAudio();
},
```

**Step 6: 提交**

```bash
git add frontend_flutter/lib/presentation/pages/ frontend_flutter/lib/presentation/widgets/
git commit -m "feat(ui): add button click logging to all interactive components"
```

---

### Task 4: 在对话框组件添加日志

**文件：**
- `frontend_flutter/lib/presentation/widgets/playlist_cover_dialog.dart`
- `frontend_flutter/lib/presentation/widgets/add_song_dialog.dart`
- `frontend_flutter/lib/presentation/widgets/add_playlist_dialog.dart`

**Step 1: 添加对话框操作日志**

```dart
// 确认按钮
onPressed: () {
  AppLogger.logButtonClick('确认-${dialogTitle}', dialogName);
  _submit();
},

// 取消按钮
onPressed: () {
  AppLogger.logButtonClick('取消-${dialogTitle}', dialogName);
  Navigator.pop(context);
},

// 输入变化
onChanged: (value) {
  AppLogger.debug(dialogName, '输入变化: ${value.length} 字符');
},
```

**Step 2: 提交**

```bash
git add frontend_flutter/lib/presentation/widgets/
git commit -m "feat(ui): add dialog action logging"
```

---

## Part 2: 代码注释规范化

### Task 5: 清理后端临时注释和调试代码

**文件：**
- Modify: `listen-vision_api/index.js`
- Modify: `listen-vision_api/services/*.js`

**Step 1: 查找并清理临时注释**

```bash
cd listen-vision_api
# 查找所有 TODO 注释
findstr /s /i "TODO" services\*.js controllers\*.js middleware\*.js

# 查找调试 console.log
findstr /s /i "console.log" *.js services\*.js controllers\*.js
```

**Step 2: 清理 index.js 中的调试代码**

将 `console.log('[DEBUG] ...')` 替换为 `logger.debug(...)`

**Step 3: 处理 TODO 注释**

- 已实现的功能：删除 TODO
- 未实现的功能：转为 GitHub Issue 或添加详细信息

**Step 4: 提交**

```bash
git add listen-vision_api/
git commit -m "refactor(api): clean up temporary comments and debug code"
```

---

### Task 6: 清理前端临时注释

**文件：**
- Modify: `frontend_flutter/lib/presentation/pages/*.dart`
- Modify: `frontend_flutter/lib/presentation/providers/*.dart`

**Step 1: 查找临时注释**

```bash
cd frontend_flutter
# 查找 TODO 注释
findstr /s /i "TODO" lib\presentation\*.dart lib\providers\*.dart

# 查找临时调试注释
findstr /s /i "// ✅" lib\presentation\*.dart lib\providers\*.dart
```

**Step 2: 处理 TODO 注释**

对于找到的 TODO：
- 评估是否仍有效
- 无效则删除，有效则转为 Issue 或添加实现计划

**Step 3: 清理优化和修复标记**

将 `// ✅ 优化：` 和 `// ✅ 修复：` 标记：
- 重要的架构决策 → 转为正式注释
- 临时标记 → 直接删除

**Step 4: 提交**

```bash
git add frontend_flutter/lib/
git commit -m "refactor(ui): clean up temporary comments and TODO markers"
```

---

### Task 7: 补充后端算法注释

**文件：**
- Modify: `listen-vision_api/services/recommendationService.js`
- Modify: `listen-vision_api/services/audioService.js`

**Step 1: 为推荐算法添加详细注释**

在 `recommendationService.js` 的推荐算法处添加：

```javascript
/**
 * 协同过滤推荐算法
 *
 * 算法流程：
 * 1. 获取用户的播放历史
 * 2. 找出相似用户（至少有 3 首共同歌曲）
 * 3. 基于相似用户的喜好推荐新内容
 *
 * 相似度计算：Jaccard 系数
 *   J(A,B) = |A ∩ B| / |A ∪ B|
 *
 * @param {number} userId - 用户 ID
 * @param {number} limit - 推荐数量限制
 * @returns {Promise<Array>} 推荐歌曲列表
 */
```

**Step 2: 为音频转换逻辑添加注释**

在 `audioService.js` 的 FFmpeg 转换处添加：

```javascript
/**
 * FFmpeg 转换参数说明
 *
 * -i: 输入文件
 * -vn: 不处理视频流
 * -acodec libmp3lame: 使用 MP3 编码器
 * -q:a 2: 音频质量 (0-9, 2 为高质量)
 * -ar 44100: 采样率 44.1kHz
 * -ac 2: 双声道
 * -y: 覆盖输出文件
 */
```

**Step 3: 提交**

```bash
git add listen-vision_api/services/
git commit -m "docs(api): add algorithm and complex logic comments"
```

---

### Task 8: 补充前端复杂逻辑注释

**文件：**
- Modify: `frontend_flutter/lib/presentation/providers/audio/playback_controller.dart`
- Modify: `frontend_flutter/lib/presentation/providers/audio/playback_queue.dart`

**Step 1: 为播放状态机添加注释**

在 `playback_controller.dart` 的状态转换逻辑处添加：

```dart
/// 播放状态机
///
/// 状态转换规则：
/// - idle -> loading: 开始加载音频
/// - loading -> ready: 音频加载完成，准备播放
/// - loading -> error: 加载失败
/// - ready -> playing: 开始播放
/// - playing -> paused: 用户暂停
/// - playing -> completed: 播放完成
/// - paused -> playing: 恢复播放
/// - * -> idle: 重置/停止
enum PlaybackState {
  /// 空闲状态，无音频加载
  idle,
  /// 加载中
  loading,
  /// 准备就绪
  ready,
  /// 播放中
  playing,
  /// 已暂停
  paused,
  /// 播放完成
  completed,
  /// 错误状态
  error,
}
```

**Step 2: 为队列逻辑添加注释**

在 `playback_queue.dart` 添加：

```dart
/// 播放队列管理
///
/// 队列操作：
/// - add: 添加到末尾
/// - addNext: 添加到下一首
/// - remove: 移除指定位置
/// - move: 移动歌曲位置
/// - clear: 清空队列
///
/// 循环模式：
/// - sequence: 顺序播放，到末尾停止
/// - loop: 列表循环
/// - loopOne: 单曲循环
/// - shuffle: 随机播放
```

**Step 3: 提交**

```bash
git add frontend_flutter/lib/presentation/providers/audio/
git commit -m "docs(ui): add complex logic comments for state machine and queue"
```

---

## Part 3: 文档和规范

### Task 9: 创建日志规范文档

**文件：**
- Create: `docs/LOGGING_STANDARDS.md`

**Step 1: 编写日志规范文档**

```markdown
# 日志记录规范

## 日志级别使用指南

### ERROR
- 系统错误、异常
- 用户操作失败
- 外部服务调用失败

### WARN
- 可能的问题
- 降级服务使用
- 重试操作

### INFO
- 用户操作（登录、播放、收藏等）
- 业务流程开始/完成
- 关键状态变化

### DEBUG
- 详细执行流程
- 中间变量值
- 性能数据

## 日志格式规范

### 后端日志格式
```javascript
logger.info('操作描述', {
  key1: value1,
  key2: value2,
});
```

### 前端日志格式
```dart
AppLogger.info('模块名', '操作描述', parameters: {...});
AppLogger.logUserAction('模块', '操作', parameters: {...});
```

## 必须记录的操作

### 用户操作
- [ ] 登录/登出
- [ ] 播放/暂停/停止
- [ ] 添加/删除收藏
- [ ] 创建/删除歌单
- [ ] 搜索
- [ ] 页面导航

### 系统操作
- [ ] API 请求/响应
- [ ] 数据库操作
- [ ] 文件操作
- [ ] 外部服务调用
- [ ] 缓存命中/未命中

## 敏感信息处理

以下字段必须脱敏：
- password -> [REDACTED]
- token -> [REDACTED]
- cookie -> [REDACTED]
- authCode -> [REDACTED]
```

**Step 2: 提交**

```bash
git add docs/LOGGING_STANDARDS.md
git commit -m "docs: add logging standards document"
```

---

### Task 10: 创建代码注释规范文档

**文件：**
- Create: `docs/CODE_COMMENT_STANDARDS.md`

**Step 1: 编写注释规范文档**

```markdown
# 代码注释规范

## 注释原则

1. **解释"为什么"而非"是什么"** - 代码说明做什么，注释说明为什么
2. **保持同步** - 代码修改时同步更新注释
3. **避免无意义注释** - 如 `i++; // i加1`
4. **使用专业术语** - 避免口语化表达

## 注释类型

### JSDoc (后端)
```javascript
/**
 * 函数简述
 *
 * 详细说明（可选）
 *
 * @param {Type} name - 参数说明
 * @returns {Type} 返回值说明
 * @throws {Error} 异常说明
 */
```

### DartDoc (前端)
```dart
/// 类/函数简述
///
/// 详细说明（可选）
///
/// - 参数说明
/// - 返回值说明
///
/// 示例：
/// ```dart
/// final result = function();
/// ```
```

## 禁止的注释

- ❌ `// TODO: 实现xxx` - 应转为 Issue
- ❌ `// HACK: xxx` - 应重构或解释
- ❌ `// FIXME: xxx` - 应立即修复或转为 Issue
- ❌ `// ✅ 优化：` - 临时标记，应删除
- ❌ `console.log('debug')` - 应使用 logger

## 必须注释的场景

1. **复杂算法** - 解释算法思路和复杂度
2. **业务规则** - 说明业务逻辑和约束
3. **外部调用** - 说明第三方 API 用途
4. **性能考虑** - 说明优化点和权衡
5. **安全考虑** - 说明安全措施
```

**Step 2: 提交**

```bash
git add docs/CODE_COMMENT_STANDARDS.md
git commit -m "docs: add code comment standards document"
```

---

### Task 11: 更新 CLAUDE.md 添加日志和注释规范

**文件：**
- Modify: `CLAUDE.md`

**Step 1: 在 CLAUDE.md 添加规范章节**

在项目状态章节后添加：

```markdown
## 代码规范

### 日志记录
- **后端**：使用 Winston logger，支持 error/warn/info/debug 四级
- **前端**：使用 AppLogger 单例，支持 DEBUG/INFO/WARN/ERROR 四级
- **规范文档**：[LOGGING_STANDARDS.md](./docs/LOGGING_STANDARDS.md)

### 代码注释
- **后端**：使用 JSDoc 标准注释函数和类
- **前端**：使用 DartDoc 标准注释类和函数
- **规范文档**：[CODE_COMMENT_STANDARDS.md](./docs/CODE_COMMENT_STANDARDS.md)

### 开发原则
1. 所有用户操作必须记录日志
2. 关键业务流程必须有开始/结束日志
3. 复杂算法必须有详细注释说明
4. 禁止提交临时调试代码和 TODO 注释
```

**Step 2: 提交**

```bash
git add CLAUDE.md
git commit -m "docs: add logging and comment standards to CLAUDE.md"
```

---

## Part 4: 验证和测试

### Task 12: 运行完整测试套件

**Step 1: 运行后端测试**

```bash
cd listen-vision_api
pnpm test
pnpm test:coverage
```

预期：所有测试通过，覆盖率 >= 70%

**Step 2: 运行前端测试**

```bash
cd frontend_flutter
flutter test
flutter test --coverage
```

预期：所有测试通过

**Step 3: 代码分析**

```bash
cd frontend_flutter
flutter analyze
```

预期：无警告，无错误

---

### Task 13: 日志输出验证

**Step 1: 启动前端并检查日志**

```bash
cd frontend_flutter
flutter run
```

执行以下操作并验证日志输出：
- [ ] 页面导航
- [ ] 按钮点击
- [ ] 播放控制
- [ ] 搜索操作

**Step 2: 检查后端日志**

```powershell
Get-Content "A:\Projects\Projects_ListenVison\listen-vision_api\logs\combined.log" -Tail 50
```

---

## 执行顺序总结

1. Part 1: 前端日志增强（Task 1-4）
2. Part 2: 代码注释规范化（Task 5-8）
3. Part 3: 文档和规范（Task 9-11）
4. Part 4: 验证和测试（Task 12-13）

---

## 预计影响范围

| 文件类型 | 数量 | 说明 |
|---------|------|------|
| 新建文件 | 3 | 1个路由观察器，2个规范文档 |
| 前端 Provider | 4 | audio/auth providers |
| 前端页面 | 3 | home/explore/play_history |
| 前端工具 | 1 | app_logger.dart |
| 后端服务 | 5 | audio/playlist/search/bilibili/recommendation |
| 配置文件 | 2 | index.js, CLAUDE.md |

---

## 相关 Issue

- 链接到相关的 GitHub Issue（如果存在）
