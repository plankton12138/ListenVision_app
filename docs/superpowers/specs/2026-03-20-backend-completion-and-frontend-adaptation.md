# Python 后端补齐与前端适配设计文档

**日期**: 2026-03-20
**状态**: 待审批
**作者**: Claude (Brainstorming Session)

---

## 1. 背景与目标

### 1.1 当前状态

- Python 后端基础架构已完成（认证、B站核心功能、歌单）
- Node.js 后端功能更完整，但即将弃用
- 前端 Flutter 代码针对 Node.js 后端编写

### 1.2 目标

1. **完全迁移** - 弃用 Node.js 后端，前端全部切换到 Python 后端
2. **功能补齐** - Python 后端补齐所有必要功能（网易云除外）
3. **前端适配** - 修改前端代码以适配新后端

### 1.3 不在范围内

- 网易云音乐功能（保持待办状态）
- 数据迁移（开发项目，无生产数据）
- 灰度过渡期

---

## 2. 功能需求清单

### 2.1 P0 - 用户相关功能（最高优先级）

| 功能 | 端点 | 描述 |
|------|------|------|
| 邮箱验证注册 | `POST /auth/register` → `POST /auth/verify-email` | 注册时发送验证码，验证后创建账号 |
| 密码重置 | `POST /auth/send-code`, `POST /auth/reset-pwd` | 发送重置验证码，验证后重置密码 |
| 账号注销 | `DELETE /auth/account` | 永久删除用户账号及关联数据 |

### 2.2 P1 - B站功能

#### 已实现（需验证）

| 功能 | 端点 | 状态 |
|------|------|------|
| QR码登录 | `POST /bilibili/qrcode`, `GET /bilibili/qrcode/check` | ✅ 已实现 |
| 绑定状态 | `GET /bilibili/status` | ✅ 已实现 |
| 解绑账号 | `DELETE /bilibili/unbind` | ✅ 已实现 |
| 视频信息 | `GET /bilibili/video/{bvid}` | ✅ 已实现 |
| 音频流 | `GET /bilibili/audio/{bvid}` | ✅ 已实现 |
| 字幕获取 | `GET /bilibili/subtitle/{bvid}` | ✅ 已实现 |
| 视频搜索 | `GET /bilibili/search` | ✅ 已实现 |
| 推荐视频 | `GET /bilibili/recommend` | ✅ 基础实现 |

#### 待实现

| 功能 | 端点 | 描述 |
|------|------|------|
| 图片代理 | `GET /bilibili/proxy/image` | 代理B站图片，解决跨域问题 |
| 音频代理 | `GET /bilibili/proxy/audio/{bvid}` | 代理音频流，支持Range请求 |
| UP主信息 | `GET /bilibili/uploader/{mid}` | 获取UP主详细信息 |
| 搜索建议 | `GET /bilibili/search/suggest` | 搜索关键词自动完成 |
| 搜索历史 | `GET /bilibili/search/recent` | 最近搜索记录 |
| Cookie刷新 | `POST /bilibili/refresh-cookie` | 手动刷新B站Cookie |

### 2.3 P1 - 推荐功能

| 功能 | 端点 | 描述 |
|------|------|------|
| 热门歌单 | `GET /recommendations/hot-playlists` | 热门歌单推荐 |
| 热歌榜单 | `GET /recommendations/rank` | 各类榜单 |
| 个性化推荐 | `GET /recommendations/personalized` | 基于历史的推荐 |
| 分区推荐 | `GET /recommendations/category/{tid}` | 特定分区推荐 |
| 音乐区推荐 | `GET /recommendations/music` | 音乐区精选 |
| 分区列表 | `GET /recommendations/categories` | 可用分区列表 |

### 2.4 P2 - 其他功能

| 功能 | 端点 | 描述 |
|------|------|------|
| 音频元数据管理 | `GET/POST/DELETE /audio/metadata/*` | 管理已下载音频的元数据 |
| 播放历史 | `GET/POST/DELETE /history` | 播放历史 CRUD |
| 本地搜索 | `GET /search/local`, `/search/suggestions` | 本地元数据全文搜索（FTS5） |
| 搜索历史 | `GET/POST/DELETE /search/history` | 用户搜索历史管理 |

### 2.5 不实现的功能

| 功能 | 原因 |
|------|------|
| 同步功能 | 实现复杂，暂不保留 |
| 网易云音乐 | 原本就是待办状态 |

---

## 3. 后端实施方案

### 3.1 目录结构扩展

```
listen-vision-api-python/app/
├── api/routes/
│   ├── auth.py          # 扩展：邮箱验证、密码重置、账号注销
│   ├── bilibili.py      # 扩展：代理、UP主、搜索建议
│   ├── playlist.py      # 已完成
│   ├── recommendations.py # 新增：推荐功能
│   ├── audio.py         # 新增：音频元数据管理
│   ├── history.py       # 新增：播放历史
│   └── search.py        # 新增：本地搜索
│
├── services/
│   ├── auth_service.py      # 扩展：邮箱验证、密码重置
│   ├── bilibili_service.py  # 扩展：代理、UP主、搜索建议
│   ├── recommendation_service.py # 新增：推荐服务
│   ├── audio_service.py     # 新增：元数据管理
│   ├── history_service.py   # 新增：播放历史
│   └── search_service.py    # 新增：本地搜索
│
├── models/
│   ├── audio_metadata.py    # 新增：音频元数据模型
│   ├── play_history.py      # 新增：播放历史模型
│   └── search_history.py    # 新增：搜索历史模型
│
└── schemas/
    ├── audio.py         # 新增
    ├── history.py       # 新增
    └── search.py        # 新增
```

### 3.2 数据模型设计

#### 音频元数据 (audio_metadata)

```python
class AudioMetadata(Base):
    __tablename__ = "audio_metadata"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    bvid = Column(String(20), index=True)
    title = Column(String(200))
    artist = Column(String(100))
    cover_url = Column(String(500))
    duration = Column(Integer)
    local_path = Column(String(500))  # 本地文件路径
    file_size = Column(Integer)
    play_progress = Column(Integer, default=0)  # 播放进度（秒）
    download_status = Column(Enum('pending', 'downloading', 'completed', 'failed'))
    created_at = Column(DateTime)
    updated_at = Column(DateTime)
```

#### 播放历史 (play_history)

```python
class PlayHistory(Base):
    __tablename__ = "play_history"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    bvid = Column(String(20), index=True)
    title = Column(String(200))
    artist = Column(String(100))
    cover_url = Column(String(500))
    duration = Column(Integer)
    progress = Column(Integer, default=0)  # 播放进度（秒）
    play_count = Column(Integer, default=1)
    last_played_at = Column(DateTime)
    created_at = Column(DateTime)
```

#### 搜索历史 (search_history)

```python
class SearchHistory(Base):
    __tablename__ = "search_history"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    keyword = Column(String(100))
    searched_at = Column(DateTime)
```

### 3.3 API 响应格式

统一使用 snake_case 字段名。

#### 成功响应

```json
{
  "success": true,
  "message": "操作成功",
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "expires_in": 3600
  }
}
```

#### 错误响应

```json
{
  "success": false,
  "message": "错误描述",
  "error": {
    "code": "ERROR_CODE",
    "details": "详细错误信息"
  }
}
```

#### 分页响应

```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total": 100,
      "total_pages": 5
    }
  }
}
```

---

## 4. 前端适配方案

### 4.1 需要修改的文件

#### API 配置

| 文件 | 修改内容 |
|------|----------|
| `lib/core/network/dio_client.dart` | 基础地址改为 Python 后端端口 |
| `lib/core/network/endpoints.dart` | 检查端点路径是否一致 |

#### 数据解析

| 文件 | 修改内容 |
|------|----------|
| `lib/data/repositories/auth_repository.dart` | 响应字段改为 snake_case |
| `lib/data/repositories/playlist_repository.dart` | 响应字段改为 snake_case |
| `lib/data/repositories/bilibili_repository.dart` | 响应字段改为 snake_case |
| `lib/models/dto/api_dto.dart` | DTO 类字段改为 snake_case |

#### 需要移除的代码

| 文件/目录 | 操作 |
|----------|------|
| `lib/data/sync/sync_worker_provider.dart` | 删除 |
| `lib/data/sync/sync_strategy.dart` | 删除 |
| `lib/data/sync/sync_worker.dart` | 删除 |
| `lib/data/sync/sync_configuration_provider.dart` | 删除 |
| `lib/data/sync/bidirectional_sync_worker.dart` | 删除 |
| `lib/data/sync/conflict_resolver.dart` | 删除 |
| `lib/data/sync/sync_worker_provider.g.dart` | 删除（生成文件） |
| `lib/data/sync/download_integrity_provider.dart` | 删除 |
| `lib/data/sync/download_integrity_provider.g.dart` | 删除（生成文件） |
| `lib/data/database/sync_queue_dao.dart` | 删除 |
| `lib/models/sync_queue.dart` | 删除 |
| `lib/presentation/widgets/common/sync_status_indicator.dart` | 删除 |
| 网易云相关代码 | 保留占位或删除实现 |

#### 需要修改的文件（移除同步引用）

| 文件 | 需移除的导入/代码 |
|------|------------------|
| `lib/app.dart` | `import 'data/sync/download_integrity_provider.dart'`，改用 `services/download_integrity_service.dart` |
| `lib/data/repositories/history_repository.dart` | `sync_queue.dart`, `sync_queue_dao.dart` 导入及相关同步逻辑 |
| `lib/data/repositories/playlist_repository.dart` | `sync_queue.dart`, `sync_queue_dao.dart` 导入及相关同步逻辑 |
| `lib/data/repositories/track_repository.dart` | `sync_queue.dart`, `sync_queue_dao.dart` 导入及相关同步逻辑 |
| `lib/presentation/views/system/settings_page.dart` | `sync_status_indicator.dart` 导入及组件使用 |
| `lib/presentation/viewmodels/auth/auth_viewmodel.dart` | `sync_worker_provider.dart` 导入及启动同步逻辑 |

#### 保留的本地功能

以下文件属于**本地优先架构**，与网络同步无关，应保留：

| 文件 | 用途 |
|------|------|
| `lib/services/download_integrity_service.dart` | 本地文件完整性验证（启动扫描+定期轮询+播放前验证） |

**注意**：`app.dart` 需要修改为直接使用 `DownloadIntegrityService` 而非 Provider。

### 4.2 字段名映射表

#### 认证响应

| Node.js (旧) | Python (新) |
|--------------|-------------|
| `token` | `access_token` |
| `refreshToken` | `refresh_token` |
| `expiresIn` | `expires_in` |
| `user.id` | `user.id` |
| `user.username` | `user.username` |
| `user.email` | `user.email` |

#### B站视频响应

| Node.js (旧) | Python (新) |
|--------------|-------------|
| `owner.mid` | `owner.mid` |
| `owner.name` | `owner.name` |
| `stat.view` | `stat.view` |
| `pubdate` | `pubdate` |

#### 歌单响应

| Node.js (旧) | Python (新) |
|--------------|-------------|
| `userId` | `user_id` |
| `isDefault` | `is_default` |
| `isPublic` | `is_public` |
| `createdAt` | `created_at` |
| `updatedAt` | `updated_at` |
| `itemCount` | `item_count` |

#### 播放历史响应

| Node.js (旧) | Python (新) |
|--------------|-------------|
| `playCount` | `play_count` |
| `lastPlayedAt` | `last_played_at` |

#### 音频元数据响应

| Node.js (旧) | Python (新) |
|--------------|-------------|
| `localPath` | `local_path` |
| `fileSize` | `file_size` |
| `playProgress` | `play_progress` |
| `downloadStatus` | `download_status` |

### 4.3 前端修改清单生成方式

审查以下目录中的所有文件：
1. `lib/data/repositories/` - 所有 Repository 类
2. `lib/models/dto/` - 所有 DTO 类
3. `lib/presentation/viewmodels/` - 所有 ViewModel 类

对每个文件检查：
- API 调用端点是否正确
- 响应字段解析是否使用 snake_case
- 是否有同步/网易云相关代码需要移除

---

## 5. 实施计划

### 阶段 1：后端补齐 + 前端审查并行（预计 4-5 天）

| 任务 | 后端工作 | 前端工作 |
|------|----------|----------|
| Day 1 | P0 用户功能：邮箱验证注册、密码重置、账号注销 | 审查 auth 相关代码 |
| Day 2 | P1 B站代理：图片代理、音频代理 | 审查 bilibili 相关代码 |
| Day 3 | P1 B站扩展：UP主、搜索建议、Cookie刷新 | 审查 playlist 相关代码 |
| Day 4 | P1 推荐功能：热门歌单、榜单、分区推荐 | 审查 history/search 相关代码 |
| Day 5 | P2 音频元数据、播放历史、本地搜索 | 生成完整修改清单 |

### 阶段 2：前端集中修改（预计 1-2 天）

| 任务 | 内容 |
|------|------|
| 修改 API 配置 | 基础地址、端点路径 |
| 修改响应解析 | snake_case 字段名 |
| 移除同步代码 | 删除 sync 目录及相关引用 |
| 移除网易云代码 | 保留占位或删除实现 |

### 阶段 3：联调测试（预计 1 天）

| 任务 | 内容 |
|------|------|
| 功能测试 | 所有 API 端点端到端测试 |
| 回归测试 | 确保无遗漏问题 |

---

## 6. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| API 响应格式差异 | 前端解析失败 | 统一使用 snake_case，逐一检查 |
| 遗漏端点 | 功能缺失 | 对比 Node.js 路由文件，逐个验证 |
| 同步功能移除影响 | 用户数据丢失风险 | 项目处于开发阶段，无生产数据 |
| Token 刷新机制差异 | 认证失败 | 后端实现与 Node.js 一致的 `/auth/refresh` 接口 |
| 限流策略缺失 | 服务不稳定 | 后端添加 FastAPI 限流中间件 |
| B站 Cookie 过期 | 功能异常 | 实现自动刷新机制，提供手动刷新接口 |

---

## 7. 验收标准

### 后端

- [ ] 所有 P0/P1/P2 功能端点可用
- [ ] 后端测试覆盖率 ≥ 80%
- [ ] API 文档完整（Swagger）

### 前端

- [ ] 所有 API 调用正常工作
- [ ] 无同步相关代码残留
- [ ] 无编译错误/警告

### 核心功能测试清单

| 功能 | 测试项 |
|------|--------|
| 登录注册 | 邮箱验证注册、登录、Token刷新、密码重置 |
| B站功能 | QR码绑定、视频搜索、音频播放、字幕获取 |
| 歌单管理 | 创建、删除、添加/移除歌曲 |
| 播放历史 | 记录、查询、删除 |
| 本地搜索 | 元数据搜索、搜索建议 |

---

## 审批记录

| 日期 | 审批人 | 状态 | 备注 |
|------|--------|------|------|
| 2026-03-20 | - | 待审批 | - |