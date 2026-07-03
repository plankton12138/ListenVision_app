# 下载格式切换 — 支持 MP3 下载

**日期**: 2026-07-03
**状态**: 已批准

---

## 背景

B站 DASH 音频流为 AAC/M4A 格式。用户希望下载时可选择 MP3 格式，以获得更好的跨平台兼容性（部分老旧设备/播放器对 M4A 支持不佳）。

### 现有基础设施

| 组件 | 状态 |
|------|------|
| 设置页 MP3/M4A Switch 开关 | ✅ 已存在，写入 `StorageKeys.downloadFormat` |
| `AudioOutputFormat` 枚举 (`m4a`, `mp3`, `aac`) | ✅ 已存在 |
| `FfmpegService` 类 | ⚠️ 骨架存在但 `isAvailable()` 返回 `false` |
| `BilibiliDownloader` 格式转换代码 | ⚠️ 代码存在但从未被触发 |
| `download_repository` 格式传递 | ❌ 读取格式后只打日志，不传参 |
| `savePath` 后缀 | ❌ 硬编码 `.mp3` |

---

## 设计

### 1. FFmpeg 集成

重新引入 `ffmpeg_kit_flutter_min_gpl: ^6.0.3`（包含 libmp3lame MP3 编码器）。

**`FfmpegService.convert()`** 实现：

```
M4A → M4A: 直接返回原路径（零转换）
M4A → MP3: ffmpeg -i input.m4a -codec:a libmp3lame -q:a 2 output.mp3
```

- `-q:a 2`: VBR ~190kbps，高质量
- `isAvailable()` 返回 FFmpeg 初始化是否成功
- 同步执行（下载已在后台 isolate 中运行）

### 2. 格式参数传递

**修改 `download_repository.dart`** — 将存储的格式字符串转为 `AudioOutputFormat` 枚举，传入 `BilibiliDownloader.download(format: ...)`。

```dart
final formatStr = SharedStorageService.instance.getDownloadFormat();
final format = AudioOutputFormat.values.firstWhere(
  (f) => f.extension == formatStr,
  orElse: () => AudioOutputFormat.m4a,
);
```

`BilibiliDownloader` 内已有完整的转换代码块（line 132-146），收到 `format` 参数后自动执行转换，失败时回退到 M4A。

### 3. 保存路径修正

`audio_action_menu.dart` 和 `playlist_detail_page.dart` 中将硬编码 `.mp3` 改为根据 `getDownloadFormat()` 动态选择后缀。

---

## 文件变更清单

| 文件 | 改动 |
|------|------|
| `pubspec.yaml` | 添加 `ffmpeg_kit_flutter_min_gpl` |
| `lib/services/ffmpeg_service.dart` | 实现 `convert()` 和 `isAvailable()` |
| `lib/data/repositories/download_repository.dart` | `getDownloadFormat()` → `AudioOutputFormat` → 传入 downloader |
| `lib/presentation/widgets/audio/audio_action_menu.dart` | savePath 后缀动态化 |
| `lib/presentation/views/library/playlist_detail_page.dart` | savePath 后缀动态化 |

**共 5 个文件**，无新增文件，无新建目录。

---

## 用户可见行为

1. 设置页"下载音质"开关：默认 M4A，可选 MP3
2. 选 MP3 后下载：`.m4a` 下载完成 → FFmpeg 转 `.mp3` → 删除原 `.m4a`
3. 选 M4A：与现有行为一致，零转换
4. 如 FFmpeg 初始化失败：显示警告，回退到 M4A

---

## 技术风险

- **包体积增加**: `ffmpeg_kit_flutter_min_gpl` 约增加 10-15MB（含 libmp3lame）
- **转换耗时**: 一首 5 分钟 320kbps AAC 转 MP3 约 2-5 秒
- **首次加载**: FFmpeg 库首次加载有约 1 秒初始化延迟
