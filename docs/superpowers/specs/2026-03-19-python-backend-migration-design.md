# Python 后端迁移设计文档

**日期**: 2026-03-19
**状态**: 待审批
**作者**: Claude (Brainstorming Session)

---

## 1. 背景与动机

### 1.1 当前问题

1. **字幕功能支持不足**: 当前 Node.js 后端手动实现 B站 API 调用，字幕获取逻辑复杂，调试困难
2. **B站 API 调用不稳定**: WBI 签名、Cookie 刷新等逻辑易出错，维护成本高
3. **功能扩展受限**: 想要扩展 B站功能（评论、弹幕、收藏夹等），当前实现扩展困难
4. **Debug 不方便**: 缺乏成熟的库封装，错误追踪困难

### 1.2 迁移目标

- 利用 Python `bilibili-api` 库（400+ API）简化 B站 API 集成
- 增强 B站功能支持（字幕、弹幕、评论、收藏夹等）
- 提升后端业务能力，承担更多业务逻辑
- 改善开发体验和代码可维护性

---

## 2. 技术方案

### 2.1 选定方案：Python FastAPI 完全重写

**技术栈**:
- **框架**: FastAPI（高性能异步框架）
- **B站 API**: bilibili-api-python 库
- **数据库**: SQLite + SQLAlchemy（保持兼容）
- **缓存**: Redis（可选）
- **测试**: pytest + pytest-asyncio

### 2.2 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter 前端                              │
│  (UI + Riverpod 状态管理 + 本地播放/下载)                     │
└─────────────────────────┬───────────────────────────────────┘
                          │ HTTP/REST
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 Python FastAPI 后端                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐│
│  │   认证层    │ │  路由层     │ │     业务服务层          ││
│  │ JWT + QR码  │ │  FastAPI    │ │ BilibiliService         ││
│  │             │ │  Routers    │ │ NeteaseService          ││
│  │             │ │             │ │ PlaylistService         ││
│  │             │ │             │ │ SyncService             ││
│  │             │ │             │ │ RecommendationService   ││
│  └─────────────┘ └─────────────┘ └─────────────────────────┘│
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐│
│  │  数据层     │ │  外部 API   │ │    缓存层               ││
│  │ SQLite      │ │ bilibili-api│ │ Redis (可选)            ││
│  │ SQLAlchemy  │ │ (Python库)  │ │                         ││
│  └─────────────┘ └─────────────┘ └─────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### 2.3 目录结构

```
listen-vision-api-python/
├── app/
│   ├── main.py                 # FastAPI 入口
│   ├── config.py               # 配置管理
│   ├── dependencies.py         # 依赖注入
│   │
│   ├── routers/                # 路由层
│   │   ├── auth.py             # 认证 (登录/注册/Token刷新)
│   │   ├── bilibili.py         # B站 API 代理
│   │   ├── netease.py          # 网易云 API 代理
│   │   ├── playlists.py        # 歌单管理
│   │   ├── sync.py             # 数据同步
│   │   └── recommendations.py  # 推荐服务
│   │
│   ├── services/               # 业务服务层
│   │   ├── auth_service.py
│   │   ├── bilibili_service.py  # 封装 bilibili-api 库
│   │   ├── netease_service.py
│   │   ├── playlist_service.py
│   │   ├── sync_service.py
│   │   └── recommendation_service.py
│   │
│   ├── models/                 # 数据模型
│   │   ├── user.py
│   │   ├── playlist.py
│   │   ├── track.py
│   │   └── sync.py
│   │
│   ├── schemas/                # Pydantic 请求/响应模型
│   │   ├── auth.py
│   │   ├── bilibili.py
│   │   └── playlist.py
│   │
│   ├── db/                     # 数据库
│   │   ├── database.py
│   │   └── repositories/
│   │
│   └── utils/                  # 工具函数
│       ├── logger.py
│       ├── security.py
│       └── cache.py
│
├── tests/                      # 测试
├── alembic/                    # 数据库迁移
├── requirements.txt
└── pyproject.toml
```

---

## 3. 核心功能设计

### 3.1 B站 QR 码登录

```python
from bilibili_api import login_v2, Credential

class BilibiliService:
    async def get_qrcode(self) -> dict:
        """获取 QR 码"""
        qr_login = login_v2.QrCodeLogin()
        await qr_login.generate_qrcode()

        return {
            "qrcode_key": qr_login._QrCodeLogin__qr_key,
            "qr_url": qr_login._QrCodeLogin__qr_link,
            "qr_image": qr_login.get_qrcode_picture()
        }

    async def check_qrcode(self, qr_key: str) -> dict:
        """检查登录状态"""
        event = await qr_login.check_state()

        if event == login_v2.QrCodeLoginEvents.DONE:
            credential = qr_login.get_credential()
            await self._save_credential(user_id, credential)
            return {"status": "success", "user_info": {...}}
        # ...
```

### 3.2 视频字幕获取

```python
from bilibili_api import video

class BilibiliService:
    async def get_subtitle(self, bvid: str, cid: int = None) -> dict:
        """获取视频字幕"""
        v = video.Video(bvid=bvid, credential=self.credential)

        if cid is None:
            info = await v.get_info()
            cid = info["cid"]

        # 一行获取字幕信息
        subtitle_info = await v.get_subtitle(cid=cid)

        # 下载字幕内容
        subtitles = []
        for sub in subtitle_info.get("subtitles", []):
            content = await self._download_subtitle(sub["subtitle_url"])
            subtitles.append({
                "lan": sub["lan"],
                "lan_doc": sub["lan_doc"],
                "lines": content["body"]
            })

        return {"bvid": bvid, "cid": cid, "subtitles": subtitles}
```

### 3.3 错误处理

```python
from bilibili_api.exceptions import (
    ApiException,
    NetworkException,
    ResponseCodeException,
    LoginError
)

class BilibiliErrorHandler:
    @staticmethod
    async def handle(func, *args, **kwargs):
        try:
            return await func(*args, **kwargs)

        except ResponseCodeException as e:
            if e.code == -101:
                raise UnauthorizedError("B站账号未登录或已过期")
            elif e.code == -403:
                raise ForbiddenError("访问被拒绝")
            elif e.code == -404:
                raise NotFoundError("资源不存在")

        except NetworkException as e:
            raise RetryableError(f"网络错误: {e}")

        except LoginError as e:
            raise AuthenticationError(f"登录失败: {e}")
```

---

## 4. 数据迁移策略

### 4.1 数据库 Schema 兼容性

Python 后端将**复用现有 SQLite 数据库**，通过 SQLAlchemy ORM 映射现有表结构：

| Node.js 表 | Python 模型 | 说明 |
|-----------|-------------|------|
| users | User | 用户基础信息 |
| bilibili_accounts | BilibiliAccount | B站绑定（含加密 Cookie） |
| playlists | Playlist | 歌单 |
| playlist_items | PlaylistItem | 歌单项 |
| play_history | PlayHistory | 播放历史 |
| sync_queue | SyncQueue | 同步队列 |

### 4.2 数据迁移脚本

```python
# scripts/migrate_data.py
"""
数据库迁移脚本
直接读取现有 Node.js SQLite 数据库，无需数据导出/导入
"""
import sqlite3
from pathlib import Path

def migrate_database(nodejs_db_path: str, python_db_path: str):
    """
    由于两个后端使用相同的数据库文件，无需迁移数据。
    只需确保 SQLAlchemy 模型与现有表结构一致。
    """
    # 验证表结构兼容性
    conn = sqlite3.connect(nodejs_db_path)
    cursor = conn.cursor()

    # 检查关键表是否存在
    tables = cursor.execute(
        "SELECT name FROM sqlite_master WHERE type='table'"
    ).fetchall()

    required_tables = ['users', 'bilibili_accounts', 'playlists']
    existing_tables = [t[0] for t in tables]

    for table in required_tables:
        if table not in existing_tables:
            raise MigrationError(f"缺失表: {table}")

    conn.close()
    print("✅ 数据库结构验证通过")

# 迁移策略：Python 后端直接使用现有数据库文件
# 配置: DATABASE_PATH=./listen-vision_api/data/database.db
```

### 4.3 Credential 存储与迁移

```python
# app/services/credential_service.py
"""
B站 Credential 存储服务
复用 Node.js 的加密机制
"""
from cryptography.fernet import Fernet
from bilibili_api import Credential

class CredentialService:
    def __init__(self, encryption_key: str):
        # 使用与 Node.js 相同的加密密钥
        self.cipher = Fernet(encryption_key)

    async def save_credential(
        self,
        user_id: int,
        credential: Credential
    ) -> None:
        """保存 B站 Credential 到数据库"""
        # 提取 Credential 字段
        cookie_str = self._build_cookie_string(credential)

        # 加密存储（与 Node.js 相同格式）
        encrypted = self.cipher.encrypt(cookie_str.encode())

        # 更新 bilibili_accounts 表
        await self.db.execute("""
            UPDATE bilibili_accounts
            SET cookie_encrypted = ?,
                updated_at = datetime('now')
            WHERE user_id = ?
        """, (encrypted, user_id))

    async def get_credential(self, user_id: int) -> Credential:
        """获取用户的 B站 Credential"""
        row = await self.db.fetch_one("""
            SELECT cookie_encrypted FROM bilibili_accounts
            WHERE user_id = ? AND is_active = 1
        """, user_id)

        if not row:
            return None

        # 解密并解析
        decrypted = self.cipher.decrypt(row[0]).decode()
        return self._parse_cookie_to_credential(decrypted)
```

### 4.4 前端切换机制

```yaml
# 前端配置 (frontend_flutter/lib/core/config/env_config.dart)
# 通过环境变量控制后端地址

class EnvConfig {
  // 开发环境
  static const String devApiBase = 'http://localhost:3000/api/v1';
  static const String devPythonApiBase = 'http://localhost:8000/api/v1';

  // 生产环境
  static const String prodApiBase = 'https://api.example.com/api/v1';

  // 当前使用的后端
  static String get apiBase {
    const backend = String.fromEnvironment('BACKEND', defaultValue: 'nodejs');
    switch (backend) {
      case 'python':
        return bool.fromEnvironment('PRODUCTION')
            ? prodApiBase
            : devPythonApiBase;
      default:
        return bool.fromEnvironment('PRODUCTION')
            ? prodApiBase
            : devApiBase;
    }
  }
}
```

**切换命令**:
```bash
# 使用 Node.js 后端
flutter run -d windows

# 使用 Python 后端
flutter run -d windows --dart-define=BACKEND=python
```

---

## 6. API 兼容性

后端 API 端点保持与现有 Node.js 一致，**前端无需修改**：

```
/api/v1/auth/*           → 认证相关
/api/v1/bilibili/*       → B站 API
/api/v1/netease/*        → 网易云 API
/api/v1/playlists/*      → 歌单管理
/api/v1/sync/*           → 数据同步
```

---

## 7. 功能增强

### 5.1 B站功能增强

| 功能 | 当前支持 | 迁移后支持 |
|------|---------|-----------|
| 视频信息 | ✅ | ✅ |
| 音频流 | ✅ | ✅ |
| 字幕 | ✅ (不稳定) | ✅ (完善) |
| QR码登录 | ✅ | ✅ (Web/TV) |
| 弹幕获取 | ❌ | ✅ |
| 评论 | ❌ | ✅ |
| 收藏夹 | ❌ | ✅ |
| 动态/专栏 | ❌ | ✅ |
| AI字幕生成 | ❌ | ✅ |

### 5.2 后端业务增强

**本次迁移范围**:
- 无新增业务功能，专注于迁移现有功能

**Phase 2（未来迭代）**:
- 播放历史分析
- 基于历史的个性化推荐
- 热门内容聚合
- 智能歌单生成

> 注：业务增强功能将在迁移稳定后单独规划，不在本次迁移范围内。

---

## 8. 测试策略

### 6.1 测试覆盖目标

| 模块 | 目标覆盖率 |
|------|-----------|
| bilibili_service.py | 90% |
| netease_service.py | 85% |
| auth_service.py | 90% |
| playlist_service.py | 80% |
| sync_service.py | 75% |

### 6.2 测试示例

```python
import pytest
from app.services.bilibili_service import BilibiliService

class TestBilibiliService:
    @pytest.mark.asyncio
    async def test_get_video_info(self):
        service = BilibiliService()
        info = await service.get_video_info("BV1uv411q7Mv")

        assert info["bvid"] == "BV1uv411q7Mv"
        assert "title" in info

    @pytest.mark.asyncio
    async def test_get_subtitle(self):
        service = BilibiliService()
        result = await service.get_subtitle("BV1uv411q7Mv")

        assert "subtitles" in result
```

---

## 10. 迁移计划（2-3 周）

### Week 1: 基础架构 + 认证

| 天数 | 任务 | 交付物 | 验收标准 |
|------|------|--------|----------|
| Day 1-2 | 项目初始化，FastAPI 骨架 | 可运行的空项目 | `curl /health` 返回 200 |
| Day 3-4 | 数据库迁移（SQLite → SQLAlchemy） | ORM 模型 + 迁移脚本 | 现有数据库可被 Python 读取 |
| Day 5-7 | 认证模块（JWT + B站 QR码登录） | auth.py 路由 + 测试 | 用户可登录/注册，B站 QR码可扫码绑定 |

### Week 2: B站/网易云 API

| 天数 | 任务 | 交付物 | 验收标准 |
|------|------|--------|----------|
| Day 8-10 | B站服务（视频、字幕、搜索） | bilibili_service.py + 测试 | 视频信息/字幕/搜索 API 可用 |
| Day 11-12 | 网易云服务 | netease_service.py + 测试 | 网易云搜索/歌单 API 可用 |
| Day 13-14 | 歌单管理 + 同步服务 | playlists.py + sync.py | 歌单 CRUD 和同步 API 可用 |

### Week 3: 测试 + 部署

| 天数 | 任务 | 交付物 | 验收标准 |
|------|------|--------|----------|
| Day 15-17 | 单元测试 + 集成测试 | 测试覆盖率报告 | 核心模块覆盖率 ≥ 80% |
| Day 18-19 | API 文档 + 部署配置 | Swagger 文档 + Dockerfile | `/docs` 可访问 API 文档 |
| Day 20-21 | 前端联调 + 问题修复 | 联调报告 | 前端可完整使用所有功能 |

### 验收标准总结

1. **功能完整性**: 所有现有 API 端点在 Python 后端可用
2. **数据兼容性**: 现有用户数据无需迁移即可使用
3. **前端兼容性**: 前端切换 `BACKEND=python` 后可正常使用
4. **测试覆盖**: 核心模块测试覆盖率 ≥ 80%
5. **文档完整**: Swagger API 文档完整可用

---

## 11. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| bilibili-api 库 API 变更 | 中 | 锁定版本 + 定期更新 |
| 功能遗漏 | 低 | 逐功能对比测试 |
| 性能差异 | 低 | FastAPI 异步 + 缓存 |
| 数据迁移错误 | 高 | 备份数据库 + 分步迁移 |

### 9.1 灰度过渡期

在迁移初期，建议两个后端并行运行：

```
Node.js 后端: localhost:3000 (稳定版)
Python 后端:  localhost:8000 (测试版)
```

**切换方式**:
1. 开发测试：前端通过 `--dart-define=BACKEND=python` 切换
2. 灰度发布：通过 Nginx 反向代理按比例分流
3. 全量切换：确认稳定后，Python 后端接管 100% 流量

### 9.2 Redis 使用策略

**场景**: 视频信息缓存、字幕缓存

**策略**:
- **有 Redis**: 缓存视频信息 1 小时，字幕 24 小时
- **无 Redis**: 使用内存缓存（`functools.lru_cache`），容量限制 1000 条

```python
# utils/cache.py
class CacheBackend:
    """缓存后端抽象，支持 Redis 和内存缓存"""

    @staticmethod
    def create(use_redis: bool = False, redis_url: str = None):
        if use_redis and redis_url:
            return RedisCache(redis_url)
        return MemoryCache(maxsize=1000)
```

---

## 12. 回滚方案

```bash
# 保留 Node.js 后端代码
# 出现问题时可快速切换

# 1. 停止 Python 服务
systemctl stop listen-vision-python

# 2. 启动 Node.js 服务
cd listen-vision_api && node index.js

# 3. 更新前端 API 地址
```

---

## 13. 参考资源

- [bilibili-api Python 库文档](https://nemo2011.github.io/bilibili-api/)
- [bilibili-api GitHub](https://github.com/Nemo2011/bilibili-api)
- [FastAPI 官方文档](https://fastapi.tiangolo.com/)
- 本地克隆: `references/bilibili-api-python/`

---

## 审批记录

| 日期 | 审批人 | 状态 | 备注 |
|------|--------|------|------|
| 2026-03-19 | 用户 | 待审批 | Brainstorming 生成 |