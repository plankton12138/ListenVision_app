# ListenVision 优化评审报告

**评审日期**：2026-10-20
**评审范围**：`frontend_flutter/lib`（146 个手写 Dart 文件，33,459 行）+ 构建配置 + 平台清单
**结论**：代码整洁度良好（`flutter analyze` 零问题、无 TODO、仅 3 个 StatefulWidget），主要优化空间集中在 **Android 后台播放能力缺失**、**网络层双轨制**、**播放状态高频重建** 与 **历史遗留死代码** 四处。

---

## 一、先看做得好的地方

避免只列问题，以下这些已经到位，优化时不要破坏：

| 项 | 现状 |
|---|---|
| 静态分析 | `flutter analyze` → `No issues found`（15.7s） |
| 数据库调优 | WAL + `synchronous=NORMAL` + 64MB cache + `temp_store=MEMORY`（`app_database.dart:41-44`），13 张索引覆盖常用查询 |
| 分层 | models → data → services → presentation 清晰，ViewModel 不直接依赖第三方库 |
| 状态管理 | 仅 3 个 `StatefulWidget`，32 个 `ConsumerWidget`，`setState` 只出现在 2 个页面 |
| 代码卫生 | 无 TODO/FIXME，`print` 仅 9 处，日志统一走 AppLogger |

---

## 二、P0：功能正确性风险（建议本周处理）

### 2.1 Android 后台播放 / 锁屏控制实际不可用

README 写「支持后台播放和锁屏收听」，但工程里没有对应实现：

- `android/app/src/main/AndroidManifest.xml:18` 只声明了 `FOREGROUND_SERVICE` 权限
- **没有** `<service>` 节点，**没有** `FOREGROUND_SERVICE_MEDIA_PLAYBACK`（Android 14+ 必需），**没有** `WAKE_LOCK`
- `pubspec.yaml` 无 `audio_service` / `just_audio_background` / `wakelock_plus`
- 播放器是 `media_kit`（libmpv），本身不提供前台服务与 MediaSession

后果：App 切到后台后，Android 12+ 会因无前台服务而限制进程，播放被掐断；锁屏 / 通知栏无控制。Android 14 上即使补了 service 声明，缺 `FOREGROUND_SERVICE_MEDIA_PLAYBACK` 也会直接抛 `SecurityException`。

**建议**：接入 `audio_service`（保留 media_kit 作为底层播放引擎，用自定义 `BaseAudioHandler` 桥接），在 manifest 补：

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<service android:name="com.ryanheise.audioservice.AudioService"
         android:foregroundServiceType="mediaPlayback" android:exported="true"/>
```

同时 `RECORD_AUDIO` 权限（manifest:16）代码中零引用，属多余敏感权限，建议删除（上架审核会追问）。

### 2.2 B站 API 走的是「裸 Dio」，没有超时也没有重试

```dart
// lib/services/bilibili_api_service.dart:42-43
BilibiliApiService({Dio? dio}) : _dio = dio ?? Dio();
```

`Dio()` 默认 `connectTimeout` 为 null（无限等待）。B站接口在弱网/被限流时会让请求长期挂起，UI 停在 loading 无法恢复。项目里其实已经写好了一套带超时、重试、网络质量自适应的客户端（`core/network/dio_client.dart`、`dio_provider.dart`，共 524 行），但**没有任何文件引用它们**。

**建议**：二选一保留，把 `BilibiliApiService` 改成从 provider 注入同一个 Dio 实例，并统一配置：

```dart
BaseOptions(connectTimeout: 10s, receiveTimeout: 15s)
  + RetryInterceptor(maxRetries: 2)
  + 统一 UA/Referer 拦截器（替换散落的 bilibili_headers）
```

### 2.3 7 个服务各自 `new Dio()`，连接池与配置全部割裂

`metadata_writer.dart:75`、`bilibili_downloader.dart:30`、`download_service.dart:61`、`metadata_service.dart:89`、`resumable_download_service.dart:100`、`bilibili_api_service.dart:43`，加上 `dio_client`/`dio_provider` 自己各建一个。

后果：无法复用 TCP 连接、无法统一加日志/重试/鉴权、每个实例独立的连接池与 Cookie 管理。配合 2.2 一起改，收益最大。

---

## 三、P1：性能（用户可感知）

### 3.1 播放位置每秒多次写全局 state，拖垮整棵播放器 UI

```dart
// playback_viewmodel.dart:169-172
_audioService!.positionStream.listen((position) {
  state = state.copyWith(position: position);   // 每次都产生新 state 对象
});
```

而下列 7 个组件 `ref.watch` 的是**整个** `PlaybackState`（含 position）：

| 文件 | 行 |
|---|---|
| `widgets/audio_info.dart` | 16 |
| `widgets/controls_panel.dart` | 16 |
| `widgets/player/expanded_player_panel.dart` | 18 |
| `widgets/player/floating_player_bar.dart` | 20 |
| `widgets/player_action_bar.dart` | 17 |
| `widgets/speed_button.dart` | 27 |
| `widgets/volume_slider.dart` | 13 |

全项目只有 **1 处** 使用 `.select()`。等于进度条每跳一次，封面、标题、音量、倍速按钮、悬浮条全部重建一遍 —— 这是当前最主要的 jank 来源。

**建议**（按性价比排序）：

1. 把 position 从 `PlaybackState` 拆出去，单独开 `playbackPositionProvider`（`StreamProvider` 或 `ValueNotifier`），只有进度条/时间文本监听它；
2. 其余组件改 `ref.watch(playbackViewModelProvider.select((s) => s.isPlaying))` 之类；
3. 如果暂时不改结构，至少在 VM 里对 position 做 200~500ms 节流。

### 3.2 封面图 11 处绕过缓存，直接 `Image.network`

`ImageHelper.cachedNetworkImage` 已经做了磁盘缓存 + `memCacheWidth/Height` 限尺寸（`core/utils/image_helper.dart:37-68`），但只有 2 个文件在用（`search_page.dart:533`、`playlist_library_page.dart:162`）；另外 11 处直接 `Image.network`（`explore_page.dart:193`、`playlist_detail_page.dart:272`、`play_history_page.dart:241`、`audio_action_menu.dart:142/569`、`audio_info.dart:80`、`music_zone_card.dart:77`、`expanded_player_panel.dart:77`、`floating_player_bar.dart:203`、`queue_tab_view.dart:113`、`player_action_bar.dart:334`）。

后果：列表滚动时重复下载同一张封面（B站 CDN 图片普遍 200KB+），且按原图分辨率解码进内存（一张 1080p 封面 ≈ 8MB 位图），长列表容易 OOM。

### 3.3 安装包 83MB，没有按 ABI 拆分

`releases/*.apk` 均为 83MB 的 fat APK。建议构建命令改为：

```bash
flutter build apk --release --split-per-abi --tree-shake-icons
```

arm64 单包通常可降到 40MB 以内。另可核查 `assets/images/` 是否有未压缩大图（启动图、图标）。

### 3.4 五个依赖零引用，一个依赖已停止维护

| 依赖 | 引用文件数 | 处理 |
|---|---|---|
| `dartz` | 0 | 删除（Clean Architecture 遗留） |
| `flutter_cache_manager` | 0 | 删除（`cached_network_image` 已内含） |
| `crypto` | 0 | 删除（文件校验逻辑未落地） |
| `mime` | 0 | 删除 |
| `html` | 0 | 删除 |
| `on_audio_query` | 1（`android_media_scanner.dart:3`） | 已长期停更，建议换 `on_audio_query_pluse` 或直接走 MediaStore 通道 |

---

## 四、P1：架构与可维护性

### 4.1 `AudioPlayerService` 有 6 个语义重叠的「设源」方法

`setSource`、`playFile`、`playUrl`、`setSourceAndPlayFile`、`setSourceAndPlayUrl`、`prepareSource`（`audio_player_service.dart:273-407`）内部都是 `_player.open(Media(...))`，只差 headers 与 `play:false`。其中：

- `setSource` 的 `if/else` 两个分支代码完全相同（`:276-280`），是死分支
- `setSourceAndPlayFile`、`setSourceAndPlayUrl`、`prepareSource`、`release` **零调用**
- `@mustCallSuper` 加在非 override 方法上（`:481`），没有实际约束力

**建议**收敛为一个入口：

```dart
Future<void> setSource(String url, {Map<String,String>? headers, bool autoPlay = true});
```

### 4.2 播放编排逻辑散落在多个 ViewModel 和 View 里

`playlist_detail_viewmodel.dart:350-430`（playAll）、`:422-527`（playItem）手动「过滤 → 构造 `OnlinePlayable` → `setQueue` → `play`」；`local_music_viewmodel.dart` 里又有一份同样的流程。全项目有 **15 处** 手动构造 `PlayableAudio`，其中 **7 处直接在 View 层**（`home_page.dart` 4 处、`search_page.dart` 2 处、`explore_page.dart`、`playlist_detail_page.dart`、`audio_action_menu.dart`、`history_tab_view.dart`）。

**建议**：新增一个 `PlaybackCoordinator`（放 `services/`，不新建目录），对外只暴露：

```dart
Future<bool> playAll(List<PlayableAudio> items, {int startIndex = 0});
Future<bool> playOne(PlayableAudio item);
```

ViewModel 只负责「取数据 + 转成 PlayableAudio」，View 不再碰领域对象。这一改能同时削掉 `playlist_detail_viewmodel` 约 180 行。

### 4.3 约 1,663 行死代码无人引用

| 文件 | 行数 | 说明 |
|---|---|---|
| `core/network/dio_client.dart` | 280 | 与 `dio_provider.dart` 重复，二者都未被引用 |
| `core/utils/download_messages.dart` | 275 | 未被引用 |
| `core/network/dio_provider.dart` | 244 | 同上 |
| `core/errors/failures.dart` | 168 | dartz 时代遗留 |
| `models/dto/api_dto.dart` | 165 | 未被引用 |
| `core/utils/debounce_utils.dart` | 158 | 未被引用（下载页自己写了 debounce） |
| `services/download_service.dart` | 133 | 仅被测试引用，生产代码未用 |
| `core/utils/app_route_observer.dart` | 107 | 未被引用 |
| `core/constants/playback_status.dart` | 60 | 未被引用 |
| `core/config/app_config.dart` | 50 | 未被引用 |
| `data/database/database_export.dart` / `repositories_export.dart` | 9 + 14 | 空壳导出 |

清理时注意：`download_service_test.dart`（20 个用例）依赖 `download_service.dart`，删除服务时测试要一并处理。

### 4.4 三个超大文件，职责混杂

| 文件 | 行数 | 混杂的职责 |
|---|---|---|
| `data/repositories/download_repository.dart` | 1,060 | 队列调度 + DB 读写 + 网络下载 + 文件清理 + watchdog + 自动重试 |
| `presentation/views/library/playlist_detail_page.dart` | 1,167 | 列表渲染 + 拖拽排序 + 批量选择 + 弹窗 + 封面编辑 |
| `presentation/viewmodels/library/playlist_detail_viewmodel.dart` | 904 | 加载 + 播放 + 下载 + 批量 + 排序 + 撤销 |

**建议**（遵守「不新建目录、优先扩展已有文件」的约定）：同目录内拆分，例如 `download_repository.dart` + `download_queue_scheduler.dart` + `download_file_ops.dart`；页面拆出 `widgets/playlist_detail/` 下的 item / 排序层 / 批量操作栏。

### 4.5 分层泄漏

- `playlist_detail_viewmodel.dart:451` 直接 `ref.read(localMusicViewModelProvider)` —— ViewModel 依赖 ViewModel
- 同一文件直接访问 `AppDatabase.instance`（全项目 19 处直接访问，仅此 1 处在 presentation 层）
- `playback_viewmodel` 反向依赖 `history_viewmodel`（`:18` import）写播放历史

**建议**：VM 之间通过 Repository / 领域服务通信；播放历史写入下沉到 `HistoryRepository`，由播放服务在「播放开始/结束」时触发。

### 4.6 4 处空 catch 静默吞异常

`playlist_detail_viewmodel.dart:138`、`download_viewmodel.dart:162`、`:196`、`bilibili_downloader.dart:234`。

另全项目 **231 处** `catch (e)` 后仅 `AppLogger.error`，缺少错误分类与用户提示映射；`core/errors/exceptions.dart` 有异常体系但使用零散。建议统一为「Service 抛 `AppException` 子类 → ViewModel 映射为 `errorMessage` → UI 统一 SnackBar」。

---

## 五、P2：工程化

### 5.1 测试覆盖极不均衡

109 个用例，但分布是：`playback_viewmodel_test.dart` 58 个、`download_service_test` 20 个、`metadata_service_test` 14 个、`audio_player_service_test` 7 个、`queue_bottom_sheet_test` 10 个。

- 34 个 ViewModel 中只有 1 个有测试
- DAO / Repository **零测试**，而数据库已迭代到 v13，`_onUpgrade` 里有 13 个迁移分支（含建临时表 → 拷数据 → 重命名的破坏性迁移，`app_database.dart:413-508`）
- 一旦迁移写错，用户数据不可恢复

**建议优先补两类测试**：① 迁移测试（造 v1~v12 的库 → 升到 13 → 断言数据完整）；② Repository 层 CRUD/排序/事务测试。这两块性价比远高于继续堆 UI 测试。

### 5.2 没有 CI

`.github/` 下只有 `copilot-instructions.md`，无 workflow。当前 `flutter analyze` 是干净的，正好可以设为门禁：

```yaml
# .github/workflows/ci.yml
- flutter analyze --no-fatal-infos
- flutter test
```

再加一个 tag 触发的 `build apk --split-per-abi`，避免手工打包产生 83MB fat APK。

### 5.3 无国际化

UI 层 1,234 处中文字面量硬编码，无 `flutter_localizations` / `intl`。当前只面向中文用户，优先级低；若规划出海再引入 `l10n`（可与 4.4 的文件拆分一起做）。

### 5.4 版本号不一致

`pubspec.yaml:19` 是 `0.1.0+1`，`releases/` 里的产物叫 `v1.0`。建议统一语义化版本，并在 CI 中用 `--build-name/--build-number` 注入。

---

## 六、建议落地顺序

**第一批（1~2 天，风险低、收益直接）**
1. 删除 5 个零引用依赖 + 11 个死代码文件（约 1,600 行）
2. 11 处 `Image.network` → `ImageHelper.cachedNetworkImage`
3. `BilibiliApiService` 接入统一 Dio（超时 + 重试），合并 7 个独立 Dio 实例
4. 构建改 `--split-per-abi`，APK 从 83MB → ~40MB

**第二批（3~5 天，用户可感知）**
5. 播放位置拆独立 provider + 7 个组件改 `.select()`（消除高频重建）
6. Android 前台服务 + MediaSession（补齐后台播放/锁屏控制，同步修 README 或补实现）
7. 收敛 `AudioPlayerService` 的 6 个设源方法

**第三批（结构性，按需排期）**
8. 抽 `PlaybackCoordinator`，View 不再构造 `PlayableAudio`
9. 拆 `download_repository` / `playlist_detail_page` / `playlist_detail_viewmodel`
10. 补迁移测试 + Repository 测试，接入 CI 门禁
