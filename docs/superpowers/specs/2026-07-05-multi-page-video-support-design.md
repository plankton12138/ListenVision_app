# 多P视频（合集）支持设计

**日期**：2026-07-05
**状态**：设计中

---

## 背景

B站搜索 API 返回的视频中，部分是多P视频（`videos` 字段 > 1，如系列合集）。此时返回的 `duration` 是所有分P的总时长，但当前代码：

- 搜索时忽略 `videos` 字段，UI 无法区分多P视频
- 忽略 `cid` 字段，播放时只取默认第一个 CID
- 没有分P展开逻辑，用户只能听到第一P

**表现**：搜索结果时长显示为合集总时长（如 15:30），但播放只播第一P（如 5:00）。

---

## 设计目标

- 搜索结果中多P视频可被识别（"共N P"标签）
- 点击多P视频弹出分P选择面板
- 支持播放指定分P 或 一键播放全部
- 单P视频体验不变

---

## 交互流程

```
搜索结果列表
  ├─ videos == 1 → 点击直接播放（现有逻辑不变）
  └─ videos > 1
       ├─ 标题右侧显示 "共3P" 标签
       └─ 点击
            ├─ 调 getVideoInfo 获取 pages（loading）
            └─ 弹出底部面板
                 ├─ 标题：歌曲名
                 ├─ 列表：P1 xxx  05:00
                 │       P2 xxx  05:00
                 │       P3 xxx  05:30
                 └─ 按钮："播放全部 (15:30)"
                      ├─ 点击某一P → 该P加入队列并播放
                      ├─ 点击"播放全部" → 全部分P依次入队，从P1播放
                      └─ 点外部关闭 → 取消
```

---

## 数据层

### `Audio` 模型（`models/audio.dart`）

新增字段：

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `videos` | `int` | 1 | 分P总数 |
| `pages` | `List<AudioPage>?` | null | 分P列表，单P时为 null |

### `AudioPage`（新增简单数据类）

```dart
class AudioPage {
  final int cid;       // 分P的CID
  final String title;  // 分P标题（如 "P1 开场"）
  final int duration;  // 该P时长（秒）
}
```

### `Audio.fromDto` 解析

- 从 DTO 读取 `videos`（默认 1）
- `duration` 保持为总时长（搜索结果展示用）
- `pages` 不在此处填充——搜索 API 只返回 `videos` 数量，不返回分P详情。`pages` 由 UI 层点击多P视频时通过 `getVideoPages()` 按需获取

### 唯一标识

多P视频的不同分P使用 `bvid + cid` 组合作为唯一标识，避免队列去重时 P1 和 P2 被当成同一首歌。

---

## API/Service 层

### `bilibili_api_service.dart`

**`search()` 改动**（第 157-165 行）：

DTO map 中增加 `'videos': item['videos']`，传入 `Audio.fromDto`。不额外请求 pages（按需获取）。

**`getAudioStreams()` 改动**（第 95-134 行）：

加可选参数 `int? cid`。如果传入则直接使用，跳过 `getVideoInfo` 的 CID 查询：

```dart
Future<AudioStreamsData> getAudioStreams(String bvid, {int? cid, Map<String, String>? cookies})
```

**新增 `getVideoPages()` 方法**：

复用现有 `getVideoInfo()`，解析 `pages` 数组返回 `List<AudioPage>`。

策略：**按需获取** — 搜索时不预加载 pages，点击多P视频时才请求。

---

## 播放层

### `OnlinePlayable`（`models/online_playable.dart`）

新增可选字段 `int? cid`，传递给 `getAudioStreams` 以获取指定分P的音频流。

### `PlaybackViewModel._resolveOnlineStreamUrl`（`playback_viewmodel.dart:286`）

将 `playable.cid` 传入 `api.getAudioStreams(bvid, cid: cid)`。

### 去重逻辑

`QueueViewModel.add()` 中去重用 `bvid + cid` 组合键替代单纯 `bvid`，确保 P1 和 P2 不会互相去重，但同一分P不会重复添加。

---

## UI 层

### 搜索结果列表（`search_page.dart`）

- 多P视频在标题行末尾显示 `共N P` 标签（次要色 Chip/Container）
- `_onResultTap` 中判断 `videos > 1` 分支逻辑

### 分P选择面板（新建 Widget）

**文件**：`presentation/widgets/video_pages_sheet.dart`

底部弹出面板（`showModalBottomSheet`）：
- 顶部：歌曲标题
- 中间：分P列表（ListView），每行显示 `P{n} {title}  {duration}`
- 底部：`播放全部 (总时长)` 按钮
- 支持拖拽关闭

---

## 改动文件清单

| 文件 | 改动类型 | 说明 |
|------|----------|------|
| `models/audio.dart` | 修改 | 新增 `videos`、`pages` 字段，新增 `AudioPage` 类 |
| `models/online_playable.dart` | 修改 | 新增 `cid` 可选字段 |
| `services/bilibili_api_service.dart` | 修改 | `search()` 传递 `videos`；`getAudioStreams()` 支持 `cid`；新增 `getVideoPages()` |
| `presentation/views/discovery/search_page.dart` | 修改 | 多P标签；`_onResultTap` 分P分支 |
| `presentation/widgets/video_pages_sheet.dart` | **新建** | 分P选择底部面板 |
| `presentation/viewmodels/player/queue_viewmodel.dart` | 修改 | 去重逻辑用 `bvid + cid` |
| `presentation/viewmodels/player/playback_viewmodel.dart` | 修改 | `cid` 传入 `getAudioStreams` |

---

## 边缘情况

| 场景 | 处理 |
|------|------|
| 单P视频 | 行为完全不变，不弹出面板 |
| 网络错误无法获取 pages | Toast 提示，不弹出面板 |
| 多P视频只有 1 个 page | 降级为单P处理（直接播放） |
| 某一P的音频流获取失败 | 跳过该P，Toast 提示，继续播下一P |
| 队列已有 P1，再点"播放全部" | P1 去重跳过，其他P正常加入 |
