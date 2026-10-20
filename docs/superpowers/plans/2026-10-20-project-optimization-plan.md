# ListenVision 项目优化实施方案

日期：2026-10-20

本方案针对当前工作区，包含已有未提交改动。保留 Flutter + Riverpod + media_kit + SQLite，按可独立验证的批次交付。实际完成范围见下方执行记录。

本次评审的验证基线：静态分析通过；现有测试 108 项通过、1 项失败，失败项为播放器平台错误分类。尚未进行真机后台播放验证、帧耗时和内存采样，因此不预估性能提升百分比。

执行记录（2026-10-20）：首轮 A + B 的数据库及异步正确性修改已落地，静态分析零问题，全量 138 项测试通过，比基线新增 29 项测试，并修复原有错误分类失败。保留了实施前已有的工作区改动。

- A：数据库版本统一至 14；新建字段和迁移字段一致；并发初始化共用 Future；迁移 SQL 失败会回滚且允许重试；隔离测试验证收藏、歌单顺序、下载和历史保留。
- A：在线可用性使用 true / false / unknown 三态；临时失败保留已有状态。批量检查按原始 BVID 请求、按 source_id 更新分 P；明确检查结果有缓存有效期。
- B：播放、准备、暂停、恢复、停止及跳转使用同一引擎命令通道，旧解析及旧设源不会恢复播放或写入历史；准备音源明确禁用自动播放。
- B：搜索和分页加入取消及过期结果检查；建议增加 300ms 防抖；分页防重复并去重；搜索页分 P 预检查也会取消旧请求。
- B：B站 API 通过统一 Dio 配置注入，连接/接收超时为 10/15 秒，总预算 30 秒（解析音源的两次请求共用预算），可重试的 GET 最多重试一次。删除了未引用的重复 DioProvider 实现。
- 测试：新增迁移、网络、搜索和播放器竞态回归；播放器错误分类兼容 WindowsAudioError；队列 Widget 测试改为注入内存歌单仓库，避免依赖真实 SQLite。
- 首轮交付时 C–F 尚未实施，后续执行情况见以下第二轮记录。

第二轮执行记录（2026-10-20）：C–F 的代码改造与本地验证已推进，Android 真机验收、性能采样和 GitHub 远程流水线执行仍待完成。

| 批次 | 实际交付 | 验证与边界 |
| --- | --- | --- |
| C | 播放进度与封面/控制区域分开监听；网络封面统一磁盘缓存与按像素比限制解码尺寸；歌单状态批量查询；排序下沉 Repository/DAO 事务 batch | 测试验证 100 次 position 更新不通知控制状态，播放状态改变仍通知；未进行真机帧耗时或首屏时间采样 |
| D | 移除下载管线中的旧后端续传入口，直连 CDN；校验 Range/ETag/长度；取消贯穿请求、流与转换；任务及实际文件路径原子提交；用户暂停在重启后保留 | 真实本地 HTTP 传输、200/206、ETag 变化、取消、进程超时、迟到回调、任务提交共 12 项测试通过 |
| D | FFmpeg 使用可终止进程、临时产物和成功后重命名；已有目标不直接复用；失败保留有效源文件；移动端只选择 M4A，Web 不访问原生平台信息 | 另用本机真实 FFmpeg/ffprobe 验证 M4A→MP3，音频、标题与附加封面保留；此冒烟测试在 .dart_tool 内，未加入要求安装 FFmpeg 的 CI 用例 |
| E | Android 前台媒体服务、MediaSession、音频焦点、耳机拔出暂停；Activity 与服务复用 Flutter 引擎；移除录音和图片媒体权限；文件权限移至下载操作 | Kotlin 已通过 Android release 构建；合并 APK 清单含 mediaPlayback 服务、对应权限及 WAKE_LOCK；锁屏、耳机、来电与厂商省电策略仍需真机验证 |
| F | 新增 Windows/Linux 检查与按 ABI 打包工作流；提交依赖锁文件；同步最低 SDK/json_annotation 约束；清理 6 个未使用的直接依赖及 8 个无引用源文件；更新 README/Copilot 指南 | 工作流 YAML 本地解析通过，未在 GitHub 执行；部分移除的直接依赖仍作为其他库的传递依赖保留；当前 release 沿用项目已有的开发签名，不自动发布 |

本地验证结果：

- `flutter analyze --no-pub`：零问题。
- `flutter test --no-pub`：155 项通过；相较首轮新增 17 项回归。
- `dart run build_runner build`：成功，生成结果已更新；CI 配置了生成结果一致性检查。
- `flutter build apk --release --split-per-abi --no-pub`：成功。三种 ABI 验证包位于 `C:/Projects/listen-vision-audio-app/frontend_flutter/build/app/outputs/flutter-apk/`，文件名为 `app-arm64-v8a-release.apk`、`app-armeabi-v7a-release.apk`、`app-x86_64-release.apk`，旁附 SHA256SUMS。
- 实测拆包大小约 30.01 / 26.57 / 32.40 MiB（arm64 / armeabi-v7a / x86_64）。历史通用 APK 约 82.72 MiB；两者代码版本和所含架构不同，不将差异全部归因于依赖清理。
- 测试与 Android 打包改为串行运行，避免同时改写平台插件注册文件。未使用的 integration_test 插件及其驱动依赖已移除，现有 Widget 测试仍保留。

Android 实现依据：[音频焦点规则](https://developer.android.com/media/optimize/audio-focus)、[MediaSession](https://developer.android.com/reference/android/media/session/MediaSession)、[后台播放与资源释放](https://developer.android.com/media/platform/mediaplayer/background)。代码接入和构建通过不替代这些场景的设备验收。

## 1. 实施顺序与范围

| 批次 | 优先级 | 交付内容 | 完成条件 |
| --- | --- | --- | --- |
| A | P0 | 数据库结构一致性、迁移测试 | 新装与 v13 升级后的结构一致，用户数据保留 |
| B | P1 | 播放/搜索竞态、请求超时与取消 | 最新操作决定最终结果，弱网请求可终止 |
| C | P1 | 播放器监听范围、封面缓存、歌单批量查询 | 进度更新不触发无关组件重建，消除逐首状态查询 |
| D | P1 | 下载取消与转换产物完整性 | 取消确实终止任务，残留文件不被当成成功产物 |
| E | P1 | Android 后台与系统媒体控制 | 真机通过后台、锁屏和音频中断场景 |
| F | P2 | CI、发布、文档与渐进式整理 | 自动检查通过，发布版本及能力说明一致 |

F 中的测试门禁与失败用例处理从 A 开始推进；不等全部优化完成后才建立回归检查。E 在 B 稳定后实施，避免同时改动播放控制权和请求调度。

## 2. 批次 A：先保证数据库正确

涉及文件：

- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/data/database/app_database.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/data/database/track_dao.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/models/cached_track.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/test/services/app_database_migration_test.dart`（拟新增文件，使用现有测试目录）

改动：

1. 将数据库版本统一至 14，新建 `tracks` 表加入 `online_status`、`last_online_check_at` 和相应索引。确保新建数据库与迁移数据库的字段、默认值及索引一致。
2. v13 → v14 迁移保留曲目、收藏、歌单顺序、历史和下载记录。通过列信息判断是否已存在字段，不再把所有 SQL 异常都当成“字段已存在”后吞掉。
3. 为数据库初始化缓存同一个 Future，确保多个调用方等待相同初始化结果；失败后允许重试。
4. 为迁移测试提供数据库路径或工厂注入，使用隔离的临时库，不能访问用户真实数据库。
5. 在线状态只在获得明确结果时变更。网络失败与临时性接口错误保留原状态，不触发永久失效或自动删除。具体平台业务码在实现时核对依据。
6. 核对 `source_id`、BVID、CID 的职责：分 P 曲目用自己的 source_id 定位数据库记录，原始 BVID/CID 用于访问接口，防止批量查询或状态更新漏掉分 P。

验收：新建库、已有 v13 库、重复打开、部分字段已存在、迁移失败回滚；升级前后的业务记录数量及关联保持一致；曲目插入、收藏切换与分 P 状态更新成功。后续再按历史版本结构补充跨版本升级夹具。

## 3. 批次 B：让最新操作决定最终状态

涉及文件：

- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/services/audio_player_service.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/presentation/viewmodels/discovery/search_viewmodel.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/presentation/views/discovery/search_page.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/services/bilibili_api_service.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/core/network/dio_client.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/core/network/dio_provider.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/data/repositories/repository_providers.dart`

播放控制：

1. 为播放/准备音源分配递增请求序号，切歌、停止和销毁时使旧请求失效。每个异步阶段完成后检查序号与生命周期。
2. 音源解析可以取消；底层播放器设源操作进入同一串行通道，执行前再次检查请求是否过期。不能仅在 UI 更新前检查，否则旧请求仍可能改变实际播放内容。
3. 过期请求不再更新状态、记录历史、启动保存计时器或显示错误；当前请求失败必须退出 loading。
4. 下一首、上一首、队列恢复共用同一入口，避免各自实现不同的竞态规则。

搜索控制：

1. 搜索建议增加约 300ms 防抖；输入过短或清空时取消请求并清空建议。
2. 搜索结果与搜索建议分别管理请求序号和 CancelToken。新关键词使旧搜索及分页结果失效，建议响应不能把结果页切回 idle 状态。
3. 分页增加请求中标记，阻止重复加载；按曲目标识去重；分页失败保留已有列表。

网络策略：

1. 在现有 `dio_client.dart` 内收敛客户端创建与配置，通过 Provider 注入各服务；核对引用后再移除重复入口。保留构造函数注入，方便使用假客户端测试。
2. API 和下载可使用不同实例，共用配置方式；不让下载继承短时 API 的完整超时策略，也不把 B站请求头或其他域名凭据全局附加到所有请求。
3. API 初始配置建议：连接超时 10 秒、接收空闲超时 15 秒、整次交互预算约 30 秒。作为可调参数，弱网测试后再定值；预算耗尽时实际取消请求。
4. 只对明确可重试的幂等 GET 做最多 1 次自动重试，加入退避和抖动。取消、业务错误与鉴权错误不自动重试；限流按响应策略处理。下载续传保留任务层重试规则，避免与通用拦截器叠加。
5. 将超时、取消、断网、业务失败映射为统一错误类型；用户主动取消不显示失败提示。

验收：用可控延迟模拟 A 请求慢、B 请求快，最终状态与实际音源均为 B；停止后旧请求不能恢复播放；旧搜索/分页/建议不能覆盖新结果；取消不被重试；超时后 loading 结束且用户可以重试。

## 4. 批次 C：降低重建、图片内存与数据库往返

涉及文件：

- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/presentation/widgets/controls_panel.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/presentation/widgets/audio_info.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/presentation/widgets/player/floating_player_bar.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/presentation/widgets/player/expanded_player_panel.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/presentation/widgets/player_action_bar.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/presentation/widgets/volume_slider.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/presentation/widgets/speed_button.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/core/utils/image_helper.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/data/database/track_dao.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/data/repositories/track_repository.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/presentation/viewmodels/library/playlist_detail_viewmodel.dart`

改动：

1. 先保留现有 PlaybackState，组件使用 `.select()` 只监听所需字段；将进度/时间与播放按钮拆成独立监听边界，避免父组件监听完整状态后仍重建全部子组件。
2. 采样后若全局进度状态仍有明显成本，再拆独立进度 Provider。第一步不同时改完整状态模型和所有消费端，也不靠盲目降低进度刷新率掩盖问题。
3. 网络封面统一使用 ImageHelper；缓存解码尺寸采用显示逻辑尺寸 × devicePixelRatio，并设置合理上限。Image.network 已有内存缓存，优化目标是补齐持久缓存与尺寸控制，不能承诺每次重建都减少一次网络请求。
4. 歌单曲目状态改成批量查询，返回以 source_id 为键的 Map；按 SQLite 参数上限分块。在线状态检测先做去重和有效期筛选，已知失效项允许手动重查或按策略复查；明确结果即使未改变状态，也更新检测时间。
5. 排序持久化下沉 Repository，使用事务或 batch；批量写入不逐条提交事务。只有大列表采样证明必要时再引入分页或进一步索引。

验收与度量：固定设备、profile 模式和同一份数据，分别采样改动前后。播放 30 秒时封面/标题/音量不因 position 单独变化而重建；使用 100、1000、5000 首歌单记录首屏时间和 SQL 查询数；反复滚动记录峰值内存与帧耗时。性能数字以采样结果为准。

## 5. 批次 D：保证下载与格式转换可取消、可恢复

涉及文件：

- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/data/repositories/download_repository.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/services/bilibili_downloader.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/services/resumable_download_service.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/services/ffmpeg_service.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/models/download_task.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/data/database/download_task_dao.dart`

改动：

1. 先梳理当前直连下载与历史后端续传调用链，只保留实际使用的执行路径；断点续传必须以当前 CDN 对 Range 的实际响应为依据，不能默认旧后端接口仍可用。
2. 同一个任务的取消信号贯穿获取音源、网络下载和转换；使用任务执行序号阻止取消前的旧回调将任务重新标为完成。并发任务不能共用单个“当前 token”。
3. 下载使用临时文件。续传校验 206、Content-Range、ETag/Last-Modified；服务端返回完整 200 响应时重新开始，不能追加到旧文件。未知总大小时显示不定进度。
4. 桌面转换用可管理的进程句柄，处理输出、退出码、取消和超时。转换临时文件保留正确扩展名或显式指定输出格式，成功校验后在目标目录内重命名。
5. 不因目标文件存在就直接认为转换成功。失败或取消保留有效源文件，清理当前任务临时产物；只有最终文件完成后才写 completed 和实际格式。
6. 移动端通过统一能力接口报告可用格式。未集成转换引擎前，界面只提供可用格式并说明原因；后续核对维护状态、平台支持、体积与许可后选择引擎。

验收：取消转换后进程退出且任务不会回到 completed；转换失败可重试；已有残缺输出不被复用；续传遇到 200 或 ETag 变化不产生拼接坏文件；多任务取消互不影响；下载记录指向的实际格式与文件一致。

## 6. 批次 E：补齐 Android 系统播放能力

涉及文件：

- `C:/Projects/listen-vision-audio-app/frontend_flutter/android/app/src/main/AndroidManifest.xml`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/main.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/services/audio_player_service.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/services/background_audio_service.dart`（拟新增文件）
- `C:/Projects/listen-vision-audio-app/frontend_flutter/pubspec.yaml`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/lib/core/utils/permission_helper.dart`

改动：

1. 保留 media_kit 为唯一播放引擎，增加系统媒体桥接服务。实施前根据项目 targetSdk、现有插件和官方文档核对桥接方案与前台服务声明，避免未经核对直接复制 manifest 配置。
2. 通知栏/锁屏播放、暂停、上一首、下一首和进度控制进入统一播放入口；引擎状态反向同步系统媒体状态，避免双向回调循环。
3. 统一音频焦点、耳机拔出与来电等中断策略；只有确实由中断暂停且满足恢复条件时才恢复，不覆盖用户主动暂停。
4. 把非启动必需的存储权限请求移至导入/选择目录场景，应用先显示首屏。按平台与功能核对必要权限，移除无使用依据的权限声明。

验收：目标 Android 版本真机切后台/锁屏连续播放 30 分钟；通知栏操作、耳机按键、拔出耳机、来电中断、系统回收后重开应用分别验证。Windows 播放链路需要回归。测试结果记录机型和系统版本，不以模拟器结果代替后台验收。

## 7. 批次 F：让优化结果可持续

涉及文件：

- `C:/Projects/listen-vision-audio-app/frontend_flutter/test/services/audio_player_service_test.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/test/viewmodels/player/playback_viewmodel_test.dart`
- `C:/Projects/listen-vision-audio-app/frontend_flutter/test/widgets/player/queue_bottom_sheet_test.dart`
- `C:/Projects/listen-vision-audio-app/.github/workflows/ci.yml`（规划位置；实施时需新增 workflows 目录）
- `C:/Projects/listen-vision-audio-app/frontend_flutter/pubspec.yaml`
- `C:/Projects/listen-vision-audio-app/README.md`
- `C:/Projects/listen-vision-audio-app/.github/copilot-instructions.md`

改动：

1. 先明确播放器是否仍兼容旧 WindowsAudioError，再修正错误分类或更新过时断言；不能只为变绿而删测试。Widget 测试注入假 Repository，避免真实数据库未初始化的错误被日志吞掉后仍通过。
2. 为 A/B/D 的数据、并发与文件完整性场景补有行为价值的测试。CI 执行依赖解析、代码生成一致性检查、静态分析和测试；生成器存在非确定性输出时先收敛，再设为阻断门禁。
3. 统一应用版本与产物名称；Android 发行按 ABI 构建，记录实际包体变化，不承诺固定压缩比例。签名与发布保持独立于普通 PR 检查。
4. README 和 Copilot 指南同步到纯前端架构、media_kit 和真实平台能力，删除过时后端/认证说明。
5. 网络层和调用链稳定后，再根据引用核对清理未使用依赖与遗留服务；检查测试、条件导入、平台代码与资源引用后删除。大文件只按已识别的职责拆分，不安排全量架构重写。

## 8. 交付与回退规则

- 每批独立提交，记录问题、改动和验收证据。实施时保留当前工作区已有改动，避免将未完成工作混入其他批次。
- A 批次涉及 schema 演进，不通过降数据库版本回退；开发验证前备份测试数据，发布后通过向前修复迁移解决问题。迁移备份的产品策略在实施时确定。
- B/C 优先保持现有调用接口，D 保留有效源文件，E 通过平台适配隔离 Windows 与 Android，便于定位回归。
- 所有批次完成基本检查后，只对新增改动或未解决风险补测；不以反复运行无关测试代替目标场景验收。
- 首个可交付范围为 A + B。它们稳定后再推进 C/D/E；包体和死代码清理放在功能正确性之后。
