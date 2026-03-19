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

### 1.3 项目性质

**这是一个开发中的项目，无需考虑：**
- 数据迁移（无现有用户数据）
- 灰度过渡期
- 向后兼容性

**可以直接：**
- 完全重写后端
- 更新前端 API 配置
- 使用全新的数据库 Schema

---

## 2. 技术方案

### 2.1 技术栈

| 组件 | 选择 | 说明 |
|------|------|------|
| 框架 | FastAPI | 高性能异步框架，自动 API 文档 |
| B站 API | bilibili-api-python | 400+ API，活跃维护 |
| 数据库 | SQLite + SQLAlchemy | 简单部署，ORM 支持 |
| 认证 | JWT + OAuth2 | FastAPI 内置支持 |
| 测试 | pytest + pytest-asyncio | 异步测试支持 |
| 缓存 | 内存缓存 | 简单场景无需 Redis |

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
│  └─────────────┘ └─────────────┘ └─────────────────────────┘│
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐                            │
│  │  数据层     │ │  外部 API   │                            │
│  │ SQLite      │ │ bilibili-api│                            │
│  │ SQLAlchemy  │ │ (Python库)  │                            │
│  └─────────────┘ └─────────────┘                            │
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
│   │   └── sync.py             # 数据同步
│   │
│   ├── services/               # 业务服务层
│   │   ├── auth_service.py
│   │   ├── bilibili_service.py  # 封装 bilibili-api 库
│   │   ├── netease_service.py
│   │   ├── playlist_service.py
│   │   └── sync_service.py
│   │
│   ├── models/                 # SQLAlchemy 数据模型
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── playlist.py
│   │   └── platform_account.py
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
# app/services/bilibili_service.py
from bilibili_api import login_v2, Credential
from app.db.repositories.platform_account_repo import PlatformAccountRepo

class BilibiliService:
    def __init__(self, db: Session):
        self.db = db
        self.account_repo = PlatformAccountRepo(db)
        # 存储 QR 登录会话（生产环境可用 Redis）
        self._qr_sessions: dict[str, login_v2.QrCodeLogin] = {}

    async def get_qrcode(self) -> dict:
        """获取 QR 码"""
        qr_login = login_v2.QrCodeLogin()
        await qr_login.generate_qrcode()

        # 存储会话
        qr_key = qr_login._QrCodeLogin__qr_key
        self._qr_sessions[qr_key] = qr_login

        return {
            "qrcode_key": qr_key,
            "qr_url": qr_login._QrCodeLogin__qr_link,
        }

    async def check_qrcode(self, user_id: int, qr_key: str) -> dict:
        """检查登录状态"""
        qr_login = self._qr_sessions.get(qr_key)
        if not qr_login:
            return {"status": "expired", "message": "QR码已过期"}

        event = await qr_login.check_state()

        if event == login_v2.QrCodeLoginEvents.DONE:
            credential = qr_login.get_credential()

            # 保存到数据库
            await self.account_repo.save_bilibili_account(
                user_id=user_id,
                sessdata=credential.sessdata,
                bili_jct=credential.bili_jct,
                dedeuserid=credential.dedeuserid,
            )

            # 清理会话
            del self._qr_sessions[qr_key]

            return {"status": "success"}

        elif event == login_v2.QrCodeLoginEvents.TIMEOUT:
            del self._qr_sessions[qr_key]
            return {"status": "expired"}

        elif event == login_v2.QrCodeLoginEvents.CONF:
            return {"status": "scanned"}

        else:  # SCAN
            return {"status": "pending"}
```

### 3.2 视频字幕获取

```python
# app/services/bilibili_service.py
from bilibili_api import video

class BilibiliService:
    async def get_subtitle(self, bvid: str, cid: int = None) -> dict:
        """获取视频字幕"""
        # 获取用户 Credential（可选）
        credential = await self._get_user_credential()

        v = video.Video(bvid=bvid, credential=credential)

        if cid is None:
            info = await v.get_info()
            cid = info["cid"]

        # 获取字幕信息
        subtitle_info = await v.get_subtitle(cid=cid)

        if not subtitle_info or not subtitle_info.get("subtitles"):
            return {"bvid": bvid, "cid": cid, "subtitles": []}

        # 下载字幕内容
        subtitles = []
        for sub in subtitle_info["subtitles"]:
            content = await self._fetch_subtitle_content(sub["subtitle_url"])
            subtitles.append({
                "lan": sub["lan"],
                "lan_doc": sub["lan_doc"],
                "lines": content.get("body", [])
            })

        return {"bvid": bvid, "cid": cid, "subtitles": subtitles}
```

### 3.3 错误处理

```python
# app/utils/error_handler.py
from bilibili_api.exceptions import (
    ResponseCodeException,
    NetworkException,
    LoginError
)
from fastapi import HTTPException

class BilibiliErrorHandler:
    ERROR_MAP = {
        -101: (401, "B站账号未登录或已过期"),
        -403: (403, "访问被拒绝"),
        -404: (404, "资源不存在"),
        -400: (400, "请求参数错误"),
    }

    @staticmethod
    async def handle(func, *args, **kwargs):
        try:
            return await func(*args, **kwargs)

        except ResponseCodeException as e:
            status_code, message = BilibiliErrorHandler.ERROR_MAP.get(
                e.code, (500, f"B站API错误: {e.code}")
            )
            raise HTTPException(status_code=status_code, detail=message)

        except NetworkException as e:
            raise HTTPException(status_code=503, detail=f"网络错误: {e}")

        except LoginError as e:
            raise HTTPException(status_code=401, detail=f"登录失败: {e}")
```

---

## 4. API 端点设计

保持与现有 Node.js API 兼容，便于前端快速切换：

### 4.1 认证 API

```
POST /api/v1/auth/register     # 注册
POST /api/v1/auth/login        # 登录
POST /api/v1/auth/refresh      # 刷新 Token
GET  /api/v1/auth/me           # 获取当前用户
```

### 4.2 B站 API

```
POST /api/v1/bilibili/qrcode           # 获取 QR 码
POST /api/v1/bilibili/qrcode/check     # 检查登录状态
GET  /api/v1/bilibili/status           # 获取绑定状态
DELETE /api/v1/bilibili/unbind         # 解绑账号
GET  /api/v1/bilibili/video/{bvid}     # 获取视频信息
GET  /api/v1/bilibili/audio/{bvid}     # 获取音频流
GET  /api/v1/bilibili/subtitle/{bvid}  # 获取字幕
GET  /api/v1/bilibili/search           # 搜索视频
GET  /api/v1/bilibili/recommend        # 获取推荐
```

### 4.3 网易云 API

```
POST /api/v1/netease/qrcode            # 获取 QR 码
POST /api/v1/netease/qrcode/check      # 检查登录状态
GET  /api/v1/netease/search            # 搜索
GET  /api/v1/netease/playlist/{id}     # 获取歌单详情
```

### 4.4 歌单 API

```
GET    /api/v1/playlists               # 获取歌单列表
POST   /api/v1/playlists               # 创建歌单
GET    /api/v1/playlists/{id}          # 获取歌单详情
PUT    /api/v1/playlists/{id}          # 更新歌单
DELETE /api/v1/playlists/{id}          # 删除歌单
POST   /api/v1/playlists/{id}/items    # 添加歌单项
DELETE /api/v1/playlists/{id}/items/{bvid}  # 删除歌单项
```

---

## 5. 功能增强

### 5.1 本次迁移支持的新功能

| 功能 | Node.js 支持 | Python 支持 |
|------|-------------|-------------|
| 视频信息 | ✅ | ✅ |
| 音频流 | ✅ | ✅ |
| 字幕 | ✅ (不稳定) | ✅ (完善) |
| QR码登录 | ✅ | ✅ (Web/TV) |
| 弹幕获取 | ❌ | ✅ |
| 评论 | ❌ | ✅ |
| 收藏夹 | ❌ | ✅ |

### 5.2 Phase 2 功能（后续迭代）

- 播放历史分析
- 个性化推荐
- 热门内容聚合
- 智能歌单生成

---

## 6. 测试策略

### 6.1 测试覆盖目标

| 模块 | 目标覆盖率 |
|------|-----------|
| bilibili_service.py | 90% |
| netease_service.py | 85% |
| auth_service.py | 90% |
| playlist_service.py | 80% |

### 6.2 测试示例

```python
# tests/services/test_bilibili_service.py
import pytest
from unittest.mock import AsyncMock, patch
from app.services.bilibili_service import BilibiliService

class TestBilibiliService:
    @pytest.fixture
    def service(self, db_session):
        return BilibiliService(db_session)

    @pytest.mark.asyncio
    async def test_get_video_info(self, service):
        info = await service.get_video_info("BV1uv411q7Mv")

        assert info["bvid"] == "BV1uv411q7Mv"
        assert "title" in info
        assert "owner" in info

    @pytest.mark.asyncio
    async def test_get_subtitle(self, service):
        result = await service.get_subtitle("BV1uv411q7Mv")

        assert "subtitles" in result
        if result["subtitles"]:
            sub = result["subtitles"][0]
            assert "lan" in sub
            assert "lines" in sub
```

---

## 7. 迁移计划（2-3 周）

### Week 1: 基础架构 + 认证

| 天数 | 任务 | 交付物 | 验收标准 |
|------|------|--------|----------|
| Day 1-2 | 项目初始化，FastAPI 骨架 | 可运行的空项目 | `curl /health` 返回 200 |
| Day 3-4 | 数据库模型 + SQLAlchemy | ORM 模型 | 数据库表创建成功 |
| Day 5-7 | 认证模块 | auth.py 路由 + 测试 | 用户可登录/注册 |

### Week 2: B站/网易云 API

| 天数 | 任务 | 交付物 | 验收标准 |
|------|------|--------|----------|
| Day 8-10 | B站服务 | bilibili_service.py + 测试 | 视频/字幕/搜索 API 可用 |
| Day 11-12 | 网易云服务 | netease_service.py + 测试 | 搜索/歌单 API 可用 |
| Day 13-14 | 歌单管理 + 同步 | playlists.py + sync.py | 歌单 CRUD 可用 |

### Week 3: 测试 + 部署

| 天数 | 任务 | 交付物 | 验收标准 |
|------|------|--------|----------|
| Day 15-17 | 单元测试 + 集成测试 | 测试覆盖率报告 | 核心模块覆盖率 ≥ 80% |
| Day 18-19 | API 文档 + 部署配置 | Swagger 文档 | `/docs` 可访问 |
| Day 20-21 | 前端联调 + 问题修复 | 联调报告 | 前端可完整使用 |

### 验收标准总结

1. **功能完整性**: 所有 API 端点可用
2. **测试覆盖**: 核心模块覆盖率 ≥ 80%
3. **文档完整**: Swagger API 文档完整
4. **前端可用**: Flutter 前端可正常使用所有功能

---

## 8. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| bilibili-api 库 API 变更 | 中 | 锁定版本 + 定期更新 |
| 功能遗漏 | 低 | 逐功能对比测试 |
| 性能差异 | 低 | FastAPI 异步 + 内存缓存 |

---

## 9. 前端改动

由于无需兼容性，前端只需修改 API 基础地址：

```dart
// frontend_flutter/lib/core/network/dio_client.dart
class DioClient {
  // 原地址
  // static const String baseUrl = 'http://localhost:3000/api/v1';

  // 新地址
  static const String baseUrl = 'http://localhost:8000/api/v1';
}
```

---

## 10. 参考资源

- [bilibili-api Python 库文档](https://nemo2011.github.io/bilibili-api/)
- [bilibili-api GitHub](https://github.com/Nemo2011/bilibili-api)
- [FastAPI 官方文档](https://fastapi.tiangolo.com/)
- 本地克隆: `references/bilibili-api-python/`

---

## 审批记录

| 日期 | 审批人 | 状态 | 备注 |
|------|--------|------|------|
| 2026-03-19 | 用户 | 待审批 | Brainstorming 生成 |