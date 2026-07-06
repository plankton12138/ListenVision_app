# 浮动播放条 & 全屏播放面板 设计规格

> 状态：设计完成，待用户审核  
> 日期：2026-07-06

---

## 一、功能概述

在任意页面（除 HomePage 播放器主页外）底部显示浮动播放条，展示当前曲目信息和基本播放控制。点击浮动条展开全屏播放面板，提供完整的播放控制能力。

核心目标：
1. 用户在浏览搜索、播放列表、设置等页面时，可以持续看到当前播放状态并进行基础操作
2. 页面切换和 App 切换不影响音频播放（由 media_kit 和 keepAlive Provider 已天然保证）
3. 类似 Spotify / 网易云音乐的底部迷你播放器体验

---

## 二、实现方案

采用 **App 级 Stack 覆盖层**（方案 A）。

在 `app.dart` 的 `MaterialApp.router` 的 `builder` 中，用 `Stack` 将 GoRouter 页面内容和浮动播放条叠放。

### 选择理由
- 改动最小：仅修改 `app.dart`（~15行） + 新建 2 个 Widget 文件
- 零侵入：不修改路由、不修改 HomePage、不修改任何 ViewModel
- 与 GoRouter 完全兼容，浮动条独立于导航系统

---

## 三、架构设计

### 3.1 组件层级

```
app.dart → builder
  └── Stack
      ├── child  ← GoRouter 管理的页面
      └── Positioned(bottom: 0)
          └── AnimatedSlide / AnimatedContainer
              └── FloatingPlayerBar  ← 浮动播放条
                    │ 点击 →
                    └── showModalBottomSheet
                        └── ExpandedPlayerPanel  ← 全屏播放面板
```

### 3.2 状态绑定

```
FloatingPlayerBar (ConsumerWidget)
  ├── 读取 playbackViewModelProvider
  │     → title, artist, coverData, coverUrl, isPlaying, position, duration
  ├── 读取 queueViewModelProvider
  │     → queue.isEmpty (显隐), playMode (模式切换)
  ├── 隐藏: queue.isEmpty → 返回 SizedBox.shrink()
  ├── 隐藏: GoRouterState.of(context).uri.toString() == '/' → 返回 SizedBox.shrink()
  └── 交互: 调用 playbackViewModel.{togglePlayPause, next}
           调用 queueViewModel.togglePlayMode()

ExpandedPlayerPanel (ConsumerWidget / ConsumerStatefulWidget)
  ├── 复用 PlayerActionBar Widget（收藏 / 添加到列表 / 更多）
  ├── 读取 playbackViewModelProvider → 全部播放状态
  ├── 读取 queueViewModelProvider → 播放模式
  └── 交互: 完整播放控制（播放/暂停/上下首/切换模式/进度拖拽）
```

### 3.3 文件清单

| 操作 | 文件 | 说明 |
|------|------|------|
| 新增 | `presentation/widgets/player/floating_player_bar.dart` | 浮动底部条 |
| 新增 | `presentation/widgets/player/expanded_player_panel.dart` | 全屏展开面板 |
| 修改 | `app.dart` | builder 中添加 Stack 包裹 |

**不修改**：
- `controls_panel.dart` — 不动
- `audio_info.dart` — 不动
- `player_action_bar.dart` — 直接 import 复用
- `router.dart` — 不动
- `providers.dart` — 不动
- `home_page.dart` — 不动

**不做的事**：
- 不提取公共组件（进度条、控制按钮在每个文件中自包含，避免为了复用而过度拆分）
- 不新建 Provider/ViewModel（现有 `PlaybackViewModel` 和 `QueueViewModel` 已满足所有需要）

---

## 四、UI/UX 设计

### 4.1 浮动条（FloatingPlayerBar）

```
┌──────────────────────────────────────────────────────────────┐
│ ████████████████████████████████░░░░░░░░░░░░░░░░░  ← 2px 进度条
│ ♫ [封面40] 青花瓷 ─ 周杰伦        [🔀] [⏮] [▶⏸] [⏭]  ← 56px 主体
└──────────────────────────────────────────────────────────────┘
```

- **总高度**：~58px（2px 进度条 + 56px 主体）
- **进度条**：2px 高线性渐变条，float 在内容区顶部
  - 进度 = `position / duration`，没有 duration 时隐藏
- **左侧区域**：封面缩略图 (40×40, 圆角 6px) + 标题 + "─" 分隔符 + 作者
  - 标题超出用 `TextOverflow.ellipsis` 截断
  - 使用 `Flexible` + `Expanded` 确保右侧按钮不被挤压
- **右侧按钮区**：4 个 36×36 `IconButton`
  - 🔀 播放模式切换（点击循环：顺序→随机→单曲循环→列表循环）
  - ⏮ 上一首
  - ▶⏸ 播放/暂停（根据 isPlaying 切换图标）
  - ⏭ 下一首
- **背景**：`Theme.of(context).colorScheme.surface` + 顶部 1px `outlineVariant` 分隔线
- **阴影**：`elevation: 4`
- **底部安全区**：留 `MediaQuery.of(context).padding.bottom`（适配全面屏）
- **点击封面区域**：触发 `showModalBottomSheet` → 打开 `ExpandedPlayerPanel`
- **向上滑动**：支持 `GestureDetector` 垂直拖动 → 展开全屏面板

### 4.2 全屏播放面板（ExpandedPlayerPanel）

展开方式：`showModalBottomSheet(isScrollControlled: true)`，占屏幕约 90% 高度。

```
┌──────────────────────────────┐
│  ←                          │  ← AppBar: 仅返回箭头
│                             │
│       ┌─────────────────┐   │
│       │                 │   │
│       │   封面大图       │   │  ← 270×270, 圆角 16px
│       │   (270×270)     │   │
│       │                 │   │
│       └─────────────────┘   │
│                             │
│   青花瓷                     │  ← 22px bold, 居中
│   周杰伦 · 我很忙            │  ← 14px, 副色, 居中
│                             │
│   ████████████████░░░░░░    │  ← 进度条 (Slider)
│   02:34              04:12  │  ← 时间显示 (12px monospace)
│                             │
│     🔀    ⏮    ▶⏸    ⏭      │  ← 4个控制按钮 (48px), 均匀分布
│                             │
│   ♥ 收藏  ➕ 添加到列表  ⋯  │  ← PlayerActionBar (直接复用)
│                             │
│  ┌─────────────────────────┐│
│  │ 📃 播放列表 (12)    >   ││  ← 可点击跳转到 QueueBottomSheet
│  │ 📜 播放历史    >        ││  ← 可点击跳转到 History 页
│  └─────────────────────────┘│
└──────────────────────────────┘
```

面板内容从上到下：
1. **AppBar**：`leading: IconButton(arrow_back)` 收起面板
2. **封面区**：270×270 固定尺寸，圆角 16px，居中。封面来源优先级同 `AudioInfo`（coverData > sidecar > URL > 默认图标）
3. **曲目信息**：标题（22px bold）+ albumTitle（14px secondary），均居中
4. **进度条区**：`Slider` + `position / duration` 时间显示
   - Slider 拖动 seek → 调用 `playbackViewModel.seek()`
5. **控制按钮行**：4 个 48px 按钮（与浮动条按钮一一对应）
   - 🔀 播放模式 → `queueViewModel.togglePlayMode()`，图标根据当前模式变化
   - ⏮ 上一首 → `playbackViewModel.previous()`
   - ▶⏸ 播放/暂停 → `playbackViewModel.togglePlayPause()`，图标根据 isPlaying 切换
   - ⏭ 下一首 → `playbackViewModel.next()`
6. **操作栏**：`PlayerActionBar` Widget 直接复用
7. **底部入口**：两个 `ListTile`
   - "播放列表 (N)" → 关闭面板后打开 `QueueBottomSheet`
   - "播放历史" → 关闭面板后 `context.go('/history')`

### 4.3 显隐逻辑

```
显示浮动条条件:
  queue.isNotEmpty          ← 有播放内容
  AND location != '/'       ← 不在 HomePage

否则: 返回 SizedBox.shrink()
```

| 场景 | 队列 | 当前页面 | 浮动条 |
|------|------|----------|--------|
| 从搜索页播放了一首歌 | 有 | /search | ✅ 显示 |
| 在设置页（有队列） | 有 | /settings | ✅ 显示 |
| 在播放列表页 | 有 | /playlists/xxx | ✅ 显示 |
| 在 HomePage 播放中 | 有 | / | ❌ 隐藏（HomePage 自己展示完整播放器） |
| 启动后未播放任何内容 | 空 | 任意 | ❌ 隐藏 |
| 队列被清空 | 空 | 任意 | ❌ 隐藏（动画滑出） |

### 4.4 动画

- **浮动条出现/消失**：使用 `AnimatedSize` + `AnimatedSlide`
  - 从底部滑入（offset: 0→1 → 0），duration: 200ms
  - 滑出时反向，duration: 200ms
- **全屏面板**：`showModalBottomSheet` 默认向上展开动画（Material Design）

---

## 五、边界情况

| 场景 | 处理方式 |
|------|----------|
| 队列为空 | 浮动条完全隐藏（`SizedBox.shrink()`） |
| 播放出错 | 浮动条继续显示，显示错误状态（标题变红或显示"播放失败"） |
| 加载中 | 播放/暂停按钮显示 `CircularProgressIndicator` (14px) |
| 没有封面 | 显示默认音乐图标（`Icons.music_note`） |
| 没有 duration（直播流） | 进度条隐藏，时间不显示 |
| 没有 artist | 只显示标题，不显示分隔符和作者 |
| 标题过长 | `TextOverflow.ellipsis` 截断 |
| 横屏模式 | 全屏面板内容可滚动（`SingleChildScrollView`），浮动条保持不变 |
| 键盘弹出 | 浮动条隐藏（`MediaQuery.of(context).viewInsets.bottom > 0` 时隐藏） |
| HomePage 路由匹配 | 使用 `GoRouterState.of(context).uri.toString() == '/'` 精确匹配（不走 startsWith） |

---

## 六、测试要点

1. **浮动条显隐**：验证 queue 为空时隐藏、有内容时显示、HomePage 上隐藏
2. **路由切换**：从 HomePage 切到搜索页 → 浮动条出现；切回 HomePage → 浮动条消失
3. **播放控制**：浮动条上播放/暂停/下一首功能正常
4. **全屏面板**：点击展开 → 所有控件可交互 → 返回箭头收起
5. **进度条**：浮动条和全屏面板上的进度条实时更新
6. **模式切换**：浮动条上切换播放模式生效
7. **封面显示**：本地封面 / 网络封面 / 无封面三种情况正常
8. **空状态**：启动 App 不播放任何内容 → 浮动条不显示
9. **App 切换**：切到后台再回来 → 浮动条状态保持（keepAlive Provider 保证）
