# Design Spec: 删除后端，纯前端架构

**日期**: 2026-05-18
**分支**: `feature/backend-free-architecture`

## 目标

删除 Python 后端 (`listen-vision-api-python/`)，Flutter 前端直接调用 B站 REST API，所有数据存在本地 SQLite，无用户账户系统。

## 决策记录

| 决策 | 选择 | 原因 |
|------|------|------|
| B站集成 | 保留 QR 码登录，cookie 存本地 | 需要登录态获取高音质和完整字幕 |
| 数据持久化 | 纯本地 SQLite | 无多设备同步需求 |
| 网易云音乐 | 彻底删除 | 后端从未实现，仅有 stub |
| 音频格式转换 | 集成 flutter_ffmpeg | 支持 m4a→mp3 等格式 |
| 用户系统 | 完全删除 | 无注册/登录/JWT |

## 架构变更

### 删除（整个后端 + 前端适配层）

```
listen-vision-api-python/          # 整个目录删除
  app/
    main.py                        # FastAPI 入口
    api/deps.py                    # JWT 认证依赖
    api/routes/                    # 42 个 API 端点
    services/                      # 8 个 Service
    db/                            # SQLAlchemy + SQLite
    models/                        # 6 个 ORM 模型
```

**前端删除：**
- `data/api/backend_api_client.dart` — 所有后端调用
- `data/api/bilibili_api_client.dart` — 旧 B站 代理客户端，由新的 `BilibiliApiService` 替代
- `presentation/viewmodels/auth/*` — 注册/登录/密码重置/平台认证
- `presentation/views/auth/*` — 登录/注册页面
- 所有 `netease_*` 文件 — 网易云（后端未实现）
- `data/repositories/auth_repository.dart` — JWT 部分（保留 B站 cookie 状态读取）
- `core/network/dio_client.dart` — Token 刷新拦截器（删除）
- Sync 相关代码 — 所有 `sync*` 方法

### 新增

| 文件 | 来源 | 说明 |
|------|------|------|
| `services/bilibili_auth_service.dart` | 移植自 `bilibili_auth_service.py` | QR 码登录流程 |
| `services/bilibili_api_service.dart` | 移植自 `bilibili_service.py` | B站 REST API 直连 |
| `services/ffmpeg_service.dart` | 新建 | 封装 flutter_ffmpeg |

### 保留并适配

| 文件 | 变更 |
|------|------|
| `services/audio_player_service.dart` | 不变 |
| `services/bilibili_downloader.dart` | 已在直连 B站 CDN，不变 |
| `services/download_service.dart` | 删除 SSE 后端下载路径 |
| `data/database/app_database.dart` | V9 migration：删除 synced_at/server_id |
| `data/repositories/subtitle_repository.dart` | 改为直连 B站 subtitle API |
| `data/repositories/track_repository.dart` | 删除后端 fallback，改 B站 直连 |
| `data/repositories/playlist_repository.dart` | 删除服务端同步方法 |
| `data/repositories/history_repository.dart` | 纯本地 |
| `data/repositories/search_repository.dart` | 本地搜索保留（SQLite），B站直接搜索走新 Service |
| `data/repositories/download_repository.dart` | 删除 SSE 路径 |
| `core/network/dio_client.dart` | 删除 token 刷新逻辑 |

## B站 API 直连映射

所有请求携带 `Referer: https://www.bilibili.com/` 和标准 `User-Agent`。

| 功能 | B站 直接端点 |
|------|------------|
| 视频信息 | `api.bilibili.com/x/web-interface/view?bvid=` |
| 音频流 URL | `api.bilibili.com/x/player/playurl?bvid=&fnval=16` (解析 DASH) |
| 字幕列表+内容 | `api.bilibili.com/x/player/v2?bvid=` → `aisubtitle.hdslb.com` |
| 搜索 | `api.bilibili.com/x/web-interface/search/type?keyword=&search_type=video` |
| 搜索建议 | `s.search.bilibili.com/main/suggest?term=` |
| 推荐 | `api.bilibili.com/x/web-interface/index/top/feed/rcmd` |
| QR 码生成 | `passport.bilibili.com/x/passport-login/web/qrcode/generate` |
| QR 码轮询 | `passport.bilibili.com/x/passport-login/web/qrcode/poll` |
| Cookie 刷新 | B站 refresh API（本地触发） |
| 排行榜 | `api.bilibili.com/x/web-interface/ranking/v2` |
| 分区热门 | `api.bilibili.com/x/web-interface/popular/series/list` |
| 分区列表 | `api.bilibili.com/x/web-interface/archive/zone` |
| 上传者信息 | `api.bilibili.com/x/space/acc/info?mid=` |
| 音频下载 | B站 CDN 直连（已有） + ffmpeg 本地转换 |
| 封面图片 | B站 CDN 直连（无 CORS 限制） |

## 数据库 Schema 变更

V8 → V9 migration，使用表重建模式（与 V5/V6 一致）。

**tracks 表：** 删除 `synced_at` 列
**playlists 表：** 删除 `server_id`、`synced_at` 列
**其他表：** 不变

## App 启动流程

### 当前
```
App 启动 → 检查登录态 → 已登录/游客 → 主页面（功能受限）
```

### 新
```
App 启动 → 主页面（全部功能可用）
              └─ 设置页 → B站 QR 码登录（可选）
```

B站 登录态完全不影响 app 正常使用，仅影响：
- 字幕完整性（部分字幕需登录）
- 音频码率（登录可获取更高质量 DASH 流）

## 不保留的功能

- 邮箱注册/登录
- JWT token 管理
- 多设备云端同步
- 网易云音乐
- 图片/音频代理（移动端无 CORS）

## 风险

1. **B站 API 变更**：B站可能修改接口。通过集中封装的 `BilibiliApiService` 限制影响范围。
2. **反爬策略**：需维护标准 Headers。移动端请求通常不被拦截。
3. **包体积**：flutter_ffmpeg 增加约 30MB。
4. **cookie 过期**：B站 cookie 有时效，需定期刷新。在 `BilibiliAuthService` 中实现自动刷新。
