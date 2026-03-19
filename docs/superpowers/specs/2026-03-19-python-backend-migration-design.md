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

## 4. API 兼容性

后端 API 端点保持与现有 Node.js 一致，**前端无需修改**：

```
/api/v1/auth/*           → 认证相关
/api/v1/bilibili/*       → B站 API
/api/v1/netease/*        → 网易云 API
/api/v1/playlists/*      → 歌单管理
/api/v1/sync/*           → 数据同步
```

---

## 5. 功能增强

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

- 播放历史分析
- 基于历史的个性化推荐
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

## 7. 迁移计划（2-3 周）

### Week 1: 基础架构 + 认证

| 天数 | 任务 |
|------|------|
| Day 1-2 | 项目初始化，FastAPI 骨架 |
| Day 3-4 | 数据库迁移（SQLite → SQLAlchemy） |
| Day 5-7 | 认证模块（JWT + B站 QR码登录） |

### Week 2: B站/网易云 API

| 天数 | 任务 |
|------|------|
| Day 8-10 | B站服务（视频、字幕、搜索） |
| Day 11-12 | 网易云服务 |
| Day 13-14 | 歌单管理 + 同步服务 |

### Week 3: 测试 + 部署

| 天数 | 任务 |
|------|------|
| Day 15-17 | 单元测试 + 集成测试 |
| Day 18-19 | API 文档 + 部署配置 |
| Day 20-21 | 前端联调 + 问题修复 |

---

## 8. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| bilibili-api 库 API 变更 | 中 | 锁定版本 + 定期更新 |
| 功能遗漏 | 低 | 逐功能对比测试 |
| 性能差异 | 低 | FastAPI 异步 + 缓存 |
| 数据迁移错误 | 高 | 备份数据库 + 分步迁移 |

---

## 9. 回滚方案

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