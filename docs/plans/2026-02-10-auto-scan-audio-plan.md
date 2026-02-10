# 自动扫描设备音频功能 - 实现计划

> 创建日期: 2026-02-10
> 状态: 待实现
> 目标: 添加类似 QQ 音乐的自动扫描设备检测可播放音频功能

---

## 一、背景

### 1.1 现状

| 方面 | 现状 |
|------|------|
| 导入方式 | 手动选择文件 (`file_selector`) |
| 数据库 | 已有 `local_music` 表 |
| 元数据提取 | `MetadataService` 已实现 |
| 支持格式 | mp3, m4a, flac, wav, ogg, wma, aac, opus |

### 1.2 相关文件

| 文件 | 功能 |
|------|------|
| `lib/presentation/viewmodels/library/local_music_viewmodel.dart` | 本地音乐 ViewModel |
| `lib/data/repositories/local_music_repository.dart` | 本地音乐数据仓库 |
| `lib/models/local_audio.dart` | 本地音频实体 |
| `lib/data/database/local_music_database.dart` | 本地音乐 SQLite 数据库 |
| `lib/services/metadata_service.dart` | 元数据提取服务 |

---

## 二、需求确认

| 配置项 | 决定 |
|--------|------|
| 扫描模式 | **快速扫描** - 仅扫描系统 MediaStore 已索引的音频 |
| 触发时机 | **手动触发** - 用户在设置页面点击扫描按钮 |
| 文件过滤 | **过滤 10 秒以下** - 跳过铃声、通知音等短音频 |

---

## 三、技术选型

### 3.1 核心依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| `on_audio_query` | ^2.9.0 | 扫描设备媒体库，获取音频元数据 |
| `permission_handler` | ^12.0.1 | 权限请求（项目已有） |

### 3.2 on_audio_query 功能

- 直接读取系统 MediaStore (Android) / MPMediaQuery (iOS)
- 自动获取元数据：标题、艺术家、专辑、时长、封面
- 支持 Android/iOS 双平台
- 性能优于手动文件遍历

### 3.3 API 参考

```dart
final OnAudioQuery _audioQuery = OnAudioQuery();

// 请求权限
bool hasPermission = await _audioQuery.checkAndRequest(retryRequest: false);

// 查询所有歌曲
List<SongModel> songs = await _audioQuery.querySongs(
  sortType: SongSortType.TITLE,
  orderType: OrderType.ASC_OR_SMALLER,
  uriType: UriType.EXTERNAL,
);

// 获取封面
Uint8List? artwork = await _audioQuery.queryArtwork(
  song.id,
  ArtworkType.AUDIO,
  size: 200,
  quality: 80,
);
```

---

## 四、架构设计

### 4.1 目录结构

```
lib/
├── services/
│   ├── metadata_service.dart              # 已有
│   └── media_scanner_service.dart         # [新增] 媒体扫描服务
├── presentation/
│   ├── viewmodels/
│   │   ├── library/
│   │   │   └── local_music_viewmodel.dart # 已有，可能需要扩展
│   │   └── settings/
│   │       └── scan_viewmodel.dart        # [新增] 扫描 ViewModel
│   └── views/
│       └── settings/
│           └── settings_page.dart         # 已有，添加扫描入口
├── data/
│   └── repositories/
│       └── local_music_repository.dart    # 已有，添加批量同步方法
└── core/
    └── permissions/
        └── media_permission_handler.dart  # [新增] 媒体权限处理（可选）
```

### 4.2 类设计

#### MediaScannerService

```dart
class MediaScannerService {
  final OnAudioQuery _audioQuery;
  final LocalMusicRepository _repository;
  final AppLogger _logger;

  /// 扫描设备音频
  Future<ScanResult> scanDeviceAudio({
    int minDurationSeconds = 10,
    bool skipExisting = true,
  });

  /// 获取权限状态
  Future<bool> hasPermission();

  /// 请求权限
  Future<bool> requestPermission();

  /// 将 SongModel 转换为 LocalAudio
  LocalAudio _mapToLocalAudio(SongModel song, Uint8List? artwork);
}

class ScanResult {
  final int addedCount;      // 新增数量
  final int skippedCount;    // 跳过数量（已存在）
  final int filteredCount;   // 过滤数量（时长不足）
  final List<LocalAudio> addedAudios;
}
```

#### ScanViewModel (Riverpod)

```dart
@riverpod
class Scan extends _$Scan {
  @override
  ScanState build() => const ScanState.idle();

  Future<void> startScan();
}

@freezed
class ScanState with _$ScanState {
  const factory ScanState.idle() = _Idle;
  const factory ScanState.requestingPermission() = _RequestingPermission;
  const factory ScanState.scanning({required double progress}) = _Scanning;
  const factory ScanState.completed({required ScanResult result}) = _Completed;
  const factory ScanState.error({required String message}) = _Error;
}
```

### 4.3 数据流

```
用户点击"扫描本地音乐"
    │
    ▼
┌─────────────────────────┐
│  ScanViewModel.startScan()  │
└─────────────────────────┘
    │
    ▼
┌─────────────────────────┐
│  MediaScannerService    │
│  .hasPermission()       │
└─────────────────────────┘
    │
    ├── 否 ──▶ requestPermission() ──▶ 用户授权
    │                                      │
    ▼                                      ▼
┌─────────────────────────┐
│  on_audio_query         │
│  .querySongs()          │
└─────────────────────────┘
    │
    ▼
┌─────────────────────────┐
│  过滤 < 10秒的音频       │
└─────────────────────────┘
    │
    ▼
┌─────────────────────────┐
│  LocalMusicRepository   │
│  .bulkSync()            │
│  对比 filePath 去重      │
└─────────────────────────┘
    │
    ▼
┌─────────────────────────┐
│  SQLite local_music     │
│  批量插入新音频          │
└─────────────────────────┘
    │
    ▼
返回 ScanResult
```

---

## 五、数据模型映射

### 5.1 SongModel → LocalAudio

| SongModel 字段 | LocalAudio 字段 | 说明 |
|---------------|-----------------|------|
| `data` | `filePath` | 文件路径 |
| `title` | `title` | 标题（若为空则用文件名） |
| `artist` | `artist` | 艺术家 |
| `album` | - | 专辑（当前模型未使用） |
| `duration` | `duration` | 时长（毫秒 → 秒） |
| `queryArtwork()` | `albumArt` | 封面图片 |
| - | `isFavorite` | 默认 false |
| - | `id` | 数据库自增 |

### 5.2 映射代码示例

```dart
LocalAudio _mapToLocalAudio(SongModel song, Uint8List? artwork) {
  return LocalAudio(
    id: null,
    filePath: song.data,
    title: song.title.isNotEmpty 
        ? song.title 
        : _extractFileName(song.data),
    artist: song.artist?.isNotEmpty == true 
        ? song.artist! 
        : 'Unknown Artist',
    duration: (song.duration ?? 0) ~/ 1000,
    albumArt: artwork,
    url: null,
    isFavorite: false,
  );
}
```

---

## 六、文件变更清单

### 6.1 新增文件

| 文件路径 | 说明 |
|----------|------|
| `lib/services/media_scanner_service.dart` | 媒体扫描服务 |
| `lib/presentation/viewmodels/settings/scan_viewmodel.dart` | 扫描 ViewModel |
| `lib/presentation/views/settings/widgets/scan_result_dialog.dart` | 扫描结果弹窗（可选） |

### 6.2 修改文件

| 文件路径 | 变更内容 |
|----------|----------|
| `pubspec.yaml` | 添加 `on_audio_query: ^2.9.0` |
| `android/app/src/main/AndroidManifest.xml` | 添加存储权限 |
| `ios/Runner/Info.plist` | 添加媒体库权限说明 |
| `lib/data/repositories/local_music_repository.dart` | 添加 `bulkSync()` 方法 |
| `lib/presentation/views/settings/settings_page.dart` | 添加扫描入口按钮 |

---

## 七、权限配置

### 7.1 Android (AndroidManifest.xml)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Android 12 (API 32) 及以下 -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="32" />
    
    <!-- Android 13 (API 33) 及以上 -->
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
    
</manifest>
```

### 7.2 iOS (Info.plist)

```xml
<dict>
    <key>NSAppleMusicUsageDescription</key>
    <string>Listen Vision 需要访问您的音乐库以扫描本地音频文件</string>
</dict>
```

---

## 八、UI 设计

### 8.1 设置页面入口

```
┌────────────────────────────────────┐
│  设置                              │
├────────────────────────────────────┤
│  本地音乐                          │
│  ├─ 扫描本地音乐         [按钮]    │
│  └─ 上次扫描: 2026-02-10 15:30    │
├────────────────────────────────────┤
│  ...其他设置...                    │
└────────────────────────────────────┘
```

### 8.2 扫描中状态

```
┌────────────────────────────────────┐
│  扫描中...                         │
│  ████████████░░░░░░░░  60%         │
│  正在扫描: 120 首歌曲               │
└────────────────────────────────────┘
```

### 8.3 扫描结果

```
┌────────────────────────────────────┐
│  扫描完成                          │
├────────────────────────────────────┤
│  ✓ 新增: 45 首                     │
│  ○ 跳过: 12 首（已存在）           │
│  ✗ 过滤: 8 首（时长不足10秒）      │
├────────────────────────────────────┤
│         [确定]                     │
└────────────────────────────────────┘
```

---

## 九、实现步骤

### Phase 1: 基础配置 (预计 15 分钟)

1. [ ] 添加 `on_audio_query` 依赖到 `pubspec.yaml`
2. [ ] 配置 Android 权限
3. [ ] 配置 iOS 权限
4. [ ] 运行 `flutter pub get`

### Phase 2: 服务层 (预计 30 分钟)

1. [ ] 创建 `MediaScannerService`
2. [ ] 实现权限检查和请求
3. [ ] 实现 `scanDeviceAudio()` 方法
4. [ ] 实现数据映射逻辑
5. [ ] 添加日志记录

### Phase 3: Repository 扩展 (预计 15 分钟)

1. [ ] 在 `LocalMusicRepository` 添加 `bulkSync()` 方法
2. [ ] 实现批量去重插入逻辑

### Phase 4: ViewModel (预计 20 分钟)

1. [ ] 创建 `ScanViewModel`
2. [ ] 定义 ScanState 状态类
3. [ ] 实现 `startScan()` 方法
4. [ ] 生成 Riverpod 代码

### Phase 5: UI 集成 (预计 20 分钟)

1. [ ] 在设置页面添加扫描按钮
2. [ ] 实现扫描状态 UI
3. [ ] 创建扫描结果弹窗

### Phase 6: 测试 (预计 20 分钟)

1. [ ] 单元测试：MediaScannerService
2. [ ] 单元测试：ScanViewModel
3. [ ] 手动测试：Android 设备
4. [ ] 手动测试：iOS 设备（如有）

---

## 十、风险与注意事项

### 10.1 已知问题

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| `on_audio_query` 最后更新于 2023 年 | 可能有兼容性问题 | 测试目标 Android/iOS 版本 |
| iOS 权限被拒绝后无法再次弹窗 | 用户体验差 | 引导用户到设置页面 |
| 大量音频扫描耗时 | UI 卡顿 | 显示进度，考虑后台执行 |
| 封面图片过大 | 内存占用高 | 限制 artwork size/quality |

### 10.2 兼容性矩阵

| 平台 | 最低版本 | 支持情况 |
|------|----------|----------|
| Android | API 21+ | ✅ 完全支持 |
| iOS | 10.0+ | ✅ 支持（部分功能受限） |
| Web | - | ❌ 不支持 |
| Windows | - | ❌ 不支持 |

---

## 十一、后续扩展（可选）

1. **自动扫描** - 应用启动时自动检查新音频
2. **指定文件夹扫描** - 深度扫描非 MediaStore 索引的目录
3. **后台监控** - 监听文件变更自动更新
4. **扫描历史** - 记录每次扫描的详情
5. **排除路径** - 用户可配置排除特定文件夹

---

## 十二、预估工时

| 阶段 | 时间 |
|------|------|
| Phase 1: 基础配置 | 15 分钟 |
| Phase 2: 服务层 | 30 分钟 |
| Phase 3: Repository 扩展 | 15 分钟 |
| Phase 4: ViewModel | 20 分钟 |
| Phase 5: UI 集成 | 20 分钟 |
| Phase 6: 测试 | 20 分钟 |
| **总计** | **约 2 小时** |

---

## 附录 A: 参考资料

- [on_audio_query - pub.dev](https://pub.dev/packages/on_audio_query)
- [on_audio_query - GitHub](https://github.com/LucJosin/on_audio_query)
- [permission_handler - pub.dev](https://pub.dev/packages/permission_handler)
- [Android Storage Permissions Guide](https://developer.android.com/about/versions/13/behavior-changes-13#granular-media-permissions)
