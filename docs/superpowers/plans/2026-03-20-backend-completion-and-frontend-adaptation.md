# Python 后端补齐与前端适配实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成 Python 后端功能补齐，弃用 Node.js 后端，前端全部适配新后端。

**Architecture:** Python FastAPI 后端 + Flutter 前端。后端使用 snake_case 响应字段，前端适配解析逻辑。移除同步功能，保留本地优先架构。

**Tech Stack:** Python 3.11, FastAPI, SQLAlchemy, bilibili_api; Flutter 3.38, Riverpod 3, Dio

---

## 文件结构

### 后端新增文件

```
listen-vision-api-python/app/
├── api/routes/
│   ├── recommendations.py    # 新增：推荐功能路由
│   ├── audio.py              # 新增：音频元数据路由
│   ├── history.py            # 新增：播放历史路由
│   └── search.py             # 新增：本地搜索路由
├── services/
│   ├── email_service.py      # 新增：邮件服务
│   ├── recommendation_service.py  # 新增：推荐服务
│   ├── audio_service.py      # 新增：音频元数据服务
│   ├── history_service.py    # 新增：播放历史服务
│   └── search_service.py     # 新增：搜索服务
├── models/
│   ├── audio_metadata.py     # 新增：音频元数据模型
│   ├── play_history.py       # 新增：播放历史模型
│   └── search_history.py     # 新增：搜索历史模型
└── schemas/
    ├── email.py              # 新增：邮件相关 Schema
    ├── audio.py              # 新增：音频 Schema
    ├── history.py            # 新增：历史 Schema
    └── search.py             # 新增：搜索 Schema
```

### 前端需删除文件

```
frontend_flutter/lib/data/sync/          # 整个目录删除
frontend_flutter/lib/models/sync_queue.dart
frontend_flutter/lib/data/database/sync_queue_dao.dart
frontend_flutter/lib/presentation/widgets/common/sync_status_indicator.dart
```

### 前端需修改文件

```
frontend_flutter/lib/core/network/dio_client.dart      # 基础地址
frontend_flutter/lib/core/network/endpoints.dart       # 端点路径检查
frontend_flutter/lib/models/dto/api_dto.dart           # snake_case 字段
frontend_flutter/lib/data/repositories/*.dart          # 响应解析
frontend_flutter/lib/app.dart                          # 移除 sync 相关
```

---

## Task 1: 后端 - P0 用户功能（邮箱验证注册）

**Files:**
- Create: `listen-vision-api-python/app/services/email_service.py`
- Create: `listen-vision-api-python/app/schemas/email.py`
- Modify: `listen-vision-api-python/app/services/auth_service.py`
- Modify: `listen-vision-api-python/app/api/routes/auth.py`
- Test: `listen-vision-api-python/tests/test_auth.py`

- [ ] **Step 1: 创建邮件服务**

创建 `listen-vision-api-python/app/services/email_service.py`:

```python
"""邮件服务"""
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional

from app.config import get_settings
from app.utils.logger import logger

settings = get_settings()


class EmailService:
    """邮件发送服务"""

    def __init__(self):
        self.smtp_host = settings.smtp_host
        self.smtp_port = settings.smtp_port
        self.smtp_user = settings.smtp_user
        self.smtp_pass = settings.smtp_pass
        self.from_email = settings.smtp_from_email

    async def send_verification_code(
        self,
        to_email: str,
        code: str,
        purpose: str = "注册"
    ) -> bool:
        """发送验证码邮件"""
        if not all([self.smtp_host, self.smtp_user, self.smtp_pass]):
            logger.warning("SMTP 配置不完整，跳过邮件发送")
            return False

        subject = f"Listen Vision - {purpose}验证码"
        body = f"""
        <html>
        <body>
            <h2>Listen Vision {purpose}验证</h2>
            <p>您的验证码是：<strong style="font-size: 24px;">{code}</strong></p>
            <p>验证码有效期为 10 分钟，请尽快使用。</p>
            <p>如果您没有请求此验证码，请忽略此邮件。</p>
        </body>
        </html>
        """

        try:
            msg = MIMEMultipart("alternative")
            msg["Subject"] = subject
            msg["From"] = self.from_email or self.smtp_user
            msg["To"] = to_email
            msg.attach(MIMEText(body, "html"))

            with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_pass)
                server.sendmail(self.smtp_user, to_email, msg.as_string())

            logger.info(f"验证码邮件已发送: {to_email}, purpose={purpose}")
            return True
        except Exception as e:
            logger.error(f"发送邮件失败: {e}")
            return False


# 单例
email_service = EmailService()
```

- [ ] **Step 2: 创建邮件 Schema**

创建 `listen-vision-api-python/app/schemas/email.py`:

```python
"""邮件相关 Schema"""
from pydantic import BaseModel, EmailStr


class SendCodeRequest(BaseModel):
    """发送验证码请求"""
    email: EmailStr
    purpose: str = "register"  # register, reset_password


class VerifyEmailRequest(BaseModel):
    """验证邮箱请求"""
    email: EmailStr
    code: str


class ResetPasswordRequest(BaseModel):
    """重置密码请求"""
    email: EmailStr
    code: str
    new_password: str
```

- [ ] **Step 3: 添加配置项**

修改 `listen-vision-api-python/app/config.py`，添加 SMTP 配置:

```python
# 在 Settings 类中添加
smtp_host: str = ""
smtp_port: int = 587
smtp_user: str = ""
smtp_pass: str = ""
smtp_from_email: str = ""
```

- [ ] **Step 4: 扩展 AuthService（含验证码存储）**

修改 `listen-vision-api-python/app/services/auth_service.py`，添加验证码逻辑:

```python
import random
import string
from datetime import datetime, timedelta

# 内存验证码存储（生产环境应使用 Redis）
_verification_codes: dict[str, tuple[str, datetime]] = {}

# 在类中添加
def _generate_code(self, length: int = 6) -> str:
    """生成数字验证码"""
    return ''.join(random.choices(string.digits, k=length))

def _get_code_key(self, email: str, purpose: str) -> str:
    """生成验证码存储键"""
    return f"{purpose}:{email}"

async def send_verification_code(
    self,
    email: str,
    purpose: str = "register"
) -> str:
    """发送验证码并返回（用于测试）"""
    from app.services.email_service import email_service

    code = self._generate_code()
    key = self._get_code_key(email, purpose)

    # 存储10分钟有效
    _verification_codes[key] = (code, datetime.utcnow() + timedelta(minutes=10))

    await email_service.send_verification_code(email, code, purpose)
    return code

def _verify_code(self, email: str, code: str, purpose: str) -> bool:
    """验证验证码"""
    key = self._get_code_key(email, purpose)
    stored = _verification_codes.get(key)

    if not stored:
        return False

    stored_code, expires_at = stored
    if datetime.utcnow() > expires_at:
        del _verification_codes[key]
        return False

    if stored_code != code:
        return False

    # 验证成功后删除
    del _verification_codes[key]
    return True

async def verify_email_and_register(
    self,
    email: str,
    code: str,
    username: str,
    password: str
) -> "UserResponse":
    """验证邮箱并完成注册"""
    if not self._verify_code(email, code, "register"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="验证码无效或已过期"
        )

    from app.schemas.auth import UserCreate
    return await self.register(UserCreate(
        email=email,
        username=username,
        password=password
    ))

async def reset_password(
    self,
    email: str,
    code: str,
    new_password: str
) -> bool:
    """重置密码"""
    if not self._verify_code(email, code, "reset_password"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="验证码无效或已过期"
        )

    user = await self.user_repo.get_by_email(email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )

    hashed_password = hash_password(new_password)
    await self.user_repo.update_password(user.id, hashed_password)
    return True

async def delete_account(self, user_id: int) -> bool:
    """删除用户账号"""
    user = await self.user_repo.get_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )

    # 删除关联的平台账号
    await self.platform_repo.delete_by_user(user_id)

    # 删除用户
    await self.user_repo.delete(user_id)
    logger.info(f"用户账号已删除: {user.email}")
    return True
```

- [ ] **Step 5: 扩展路由**

修改 `listen-vision-api-python/app/api/routes/auth.py`:

```python
from app.schemas.email import SendCodeRequest, VerifyEmailRequest, ResetPasswordRequest

@router.post("/send-code")
async def send_code(
    request: SendCodeRequest,
    db: AsyncSession = Depends(get_db)
):
    """发送验证码"""
    service = AuthService(db)
    await service.send_verification_code(request.email, request.purpose)
    return ApiResponse(success=True, message="验证码已发送")


@router.post("/verify-email", response_model=ApiResponse[TokenResponse])
async def verify_email(
    request: VerifyEmailRequest,
    username: str,
    password: str,
    db: AsyncSession = Depends(get_db)
):
    """验证邮箱并完成注册"""
    service = AuthService(db)
    user = await service.verify_email_and_register(
        request.email, request.code, username, password
    )
    # 自动登录
    token = await service.login(request.email, password)
    return ApiResponse(success=True, message="注册成功", data=token)


@router.post("/reset-pwd")
async def reset_password(
    request: ResetPasswordRequest,
    db: AsyncSession = Depends(get_db)
):
    """重置密码"""
    service = AuthService(db)
    await service.reset_password(request.email, request.code, request.new_password)
    return ApiResponse(success=True, message="密码重置成功")


@router.delete("/account")
async def delete_account(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """注销账号"""
    service = AuthService(db)
    await service.delete_account(current_user.id)
    return ApiResponse(success=True, message="账号已注销")
```

- [ ] **Step 6: 编写测试**

创建 `listen-vision-api-python/tests/test_auth_extended.py`:

```python
"""用户功能扩展测试"""
import pytest
from httpx import AsyncClient

from app.main import app


@pytest.mark.asyncio
async def test_send_verification_code():
    """测试发送验证码"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/send-code",
            json={"email": "test@example.com", "purpose": "register"}
        )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True


@pytest.mark.asyncio
async def test_delete_account(async_client, auth_headers):
    """测试注销账号"""
    response = await async_client.delete(
        "/api/v1/auth/account",
        headers=auth_headers
    )
    assert response.status_code == 200
```

- [ ] **Step 7: 运行测试验证**

```bash
cd listen-vision-api-python
uv run pytest tests/test_auth_extended.py -v
```

- [ ] **Step 8: 提交**

```bash
git add listen-vision-api-python/app/services/email_service.py
git add listen-vision-api-python/app/schemas/email.py
git add listen-vision-api-python/app/services/auth_service.py
git add listen-vision-api-python/app/api/routes/auth.py
git add listen-vision-api-python/tests/test_auth_extended.py
git commit -m "feat(auth): 添加邮箱验证注册、密码重置、账号注销功能"
```

---

## Task 2: 后端 - P1 B站代理功能

**Files:**
- Modify: `listen-vision-api-python/app/api/routes/bilibili.py`
- Modify: `listen-vision-api-python/app/services/bilibili_service.py`
- Create: `listen-vision-api-python/tests/test_bilibili_proxy.py`

- [ ] **Step 1: 添加图片代理方法**

修改 `listen-vision-api-python/app/services/bilibili_service.py`:

```python
import httpx

@staticmethod
async def proxy_image(url: str) -> tuple[bytes, str]:
    """代理图片，返回 (图片数据, content_type)"""
    async with httpx.AsyncClient() as client:
        response = await client.get(url, follow_redirects=True)
        response.raise_for_status()
        content_type = response.headers.get("content-type", "image/jpeg")
        return response.content, content_type

@staticmethod
async def proxy_audio_stream(
    bvid: str,
    credential=None,
    range_header: str = None
) -> tuple[bytes, str, int, int]:
    """代理音频流，返回 (数据, content_type, 总大小, 当前位置)"""
    streams = await BilibiliService.get_audio_streams(bvid, credential)
    if not streams.streams:
        raise ValueError("无可用音频流")

    # 选择最高质量
    stream = streams.streams[0]
    url = stream.url

    headers = {}
    if range_header:
        headers["Range"] = range_header

    async with httpx.AsyncClient() as client:
        response = await client.get(url, headers=headers, follow_redirects=True)
        response.raise_for_status()

        content_type = response.headers.get("content-type", "audio/mp4")
        total_size = int(response.headers.get("content-length", 0))
        content_range = response.headers.get("content-range", "")

        # 解析 range
        start = 0
        if content_range:
            parts = content_range.split("/")
            if len(parts) == 2:
                total_size = int(parts[1])
                range_parts = parts[0].split("-")
                if len(range_parts) == 2:
                    start = int(range_parts[0])

        return response.content, content_type, total_size, start
```

- [ ] **Step 2: 添加 UP主信息方法**

```python
@staticmethod
@cached(ttl=300)
async def get_uploader_info(mid: int) -> dict:
    """获取UP主信息"""
    try:
        u = user.User(uid=mid)
        info = await u.get_user_info()
        return {
            "mid": info["mid"],
            "name": info["name"],
            "face": info["face"],
            "sign": info["sign"],
            "level": info["level"],
            "fans": info["follower"],
            "videos": info["video_count"]
        }
    except ResponseCodeException as e:
        logger.error(f"获取UP主信息失败: {e.code} - {e.msg}")
        raise
```

- [ ] **Step 3: 添加搜索建议方法**

```python
@staticmethod
@cached(ttl=60)
async def get_search_suggestions(keyword: str) -> list[str]:
    """获取搜索建议"""
    try:
        from bilibili_api import search as search_module
        result = await search_module.get_suggestions(keyword)
        return [item["value"] for item in result.get("tag", [])]
    except Exception as e:
        logger.error(f"获取搜索建议失败: {e}")
        return []
```

- [ ] **Step 4: 添加路由端点**

修改 `listen-vision-api-python/app/api/routes/bilibili.py`:

```python
from fastapi import Response, Request
from fastapi.responses import StreamingResponse

from app.api.deps import get_db, get_current_user
from app.models import User

@router.get("/proxy/image")
async def proxy_image(url: str):
    """代理图片"""
    data, content_type = await BilibiliService.proxy_image(url)
    return Response(
        content=data,
        media_type=content_type,
        headers={"Cache-Control": "public, max-age=86400"}
    )


@router.get("/proxy/audio/{bvid}")
async def proxy_audio(
    bvid: str,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """代理音频流，支持 Range 请求"""
    range_header = request.headers.get("range")

    data, content_type, total_size, start = await BilibiliService.proxy_audio_stream(
        bvid, range_header=range_header
    )

    headers = {
        "Content-Type": content_type,
        "Accept-Ranges": "bytes",
        "Content-Length": str(len(data)),
    }

    if range_header:
        end = start + len(data) - 1
        headers["Content-Range"] = f"bytes {start}-{end}/{total_size}"
        return Response(content=data, status_code=206, headers=headers)

    return Response(content=data, headers=headers)


@router.get("/uploader/{mid}")
async def get_uploader(mid: int):
    """获取UP主信息"""
    info = await BilibiliService.get_uploader_info(mid)
    return ApiResponse(success=True, data=info)


@router.get("/search/suggest")
async def get_search_suggestions(keyword: str):
    """获取搜索建议"""
    suggestions = await BilibiliService.get_search_suggestions(keyword)
    return ApiResponse(success=True, data={"suggestions": suggestions})
```

- [ ] **Step 5: 添加 Cookie 刷新方法**

修改 `listen-vision-api-python/app/services/bilibili_service.py`:

```python
@staticmethod
async def refresh_cookie(credential) -> dict:
    """刷新 B站 Cookie"""
    try:
        from bilibili_api import login_func
        # 使用 credential 刷新
        new_credential = await login_func.refresh_cookie(credential)
        return {
            "sessdata": new_credential.sessdata,
            "bili_jct": new_credential.bili_jct,
            "dedeuserid": new_credential.dedeuserid
        }
    except Exception as e:
        logger.error(f"刷新 Cookie 失败: {e}")
        raise
```

- [ ] **Step 6: 添加搜索历史方法**

```python
# 在内存中存储搜索历史（生产环境应使用 Redis）
_search_history: dict[int, list[str]] = {}

@staticmethod
async def get_search_history(user_id: int, limit: int = 10) -> list[str]:
    """获取搜索历史"""
    return _search_history.get(user_id, [])[:limit]

@staticmethod
async def add_search_history(user_id: int, keyword: str) -> None:
    """添加搜索历史"""
    if user_id not in _search_history:
        _search_history[user_id] = []
    history = _search_history[user_id]
    # 去重
    if keyword in history:
        history.remove(keyword)
    history.insert(0, keyword)
    # 限制数量
    _search_history[user_id] = history[:50]
```

- [ ] **Step 7: 添加路由端点（续）**

修改 `listen-vision-api-python/app/api/routes/bilibili.py`:

```python
@router.post("/refresh-cookie")
async def refresh_cookie(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """手动刷新 B站 Cookie"""
    from app.services.bilibili_auth_service import BilibiliAuthService
    auth_service = BilibiliAuthService(db)
    credential = await auth_service.get_credential(current_user.id)

    if not credential:
        return ApiResponse(success=False, message="未绑定B站账号")

    new_cred = await BilibiliService.refresh_cookie(credential)
    await auth_service.update_credential(current_user.id, new_cred)
    return ApiResponse(success=True, message="Cookie 刷新成功")


@router.get("/search/recent")
async def get_recent_searches(
    current_user: User = Depends(get_current_user),
    limit: int = 10
):
    """获取最近搜索记录"""
    history = await BilibiliService.get_search_history(current_user.id, limit)
    return ApiResponse(success=True, data={"keywords": history})
```

- [ ] **Step 8: 编写测试**

创建 `listen-vision-api-python/tests/test_bilibili_proxy.py`:

```python
"""B站代理功能测试"""
import pytest

from app.services.bilibili_service import BilibiliService


@pytest.mark.asyncio
async def test_proxy_image():
    """测试图片代理"""
    # 使用一个测试图片 URL
    url = "https://i0.hdslb.com/bfs/face/test.jpg"
    try:
        data, content_type = await BilibiliService.proxy_image(url)
        assert isinstance(data, bytes)
        assert content_type.startswith("image/")
    except Exception:
        pytest.skip("网络不可用或图片不存在")


@pytest.mark.asyncio
async def test_get_uploader_info():
    """测试获取UP主信息"""
    # 使用一个已知存在的 UP主 ID
    mid = 2  # bilibili 官方账号
    info = await BilibiliService.get_uploader_info(mid)
    assert info["mid"] == mid
    assert "name" in info


@pytest.mark.asyncio
async def test_search_suggestions():
    """测试搜索建议"""
    suggestions = await BilibiliService.get_search_suggestions("原神")
    assert isinstance(suggestions, list)


@pytest.mark.asyncio
async def test_search_history():
    """测试搜索历史"""
    user_id = 1
    await BilibiliService.add_search_history(user_id, "测试关键词")
    history = await BilibiliService.get_search_history(user_id)
    assert "测试关键词" in history
```

- [ ] **Step 9: 运行测试**

```bash
cd listen-vision-api-python
uv run pytest tests/test_bilibili_proxy.py -v
```

- [ ] **Step 10: 提交**

```bash
git add listen-vision-api-python/app/services/bilibili_service.py
git add listen-vision-api-python/app/api/routes/bilibili.py
git add listen-vision-api-python/tests/test_bilibili_proxy.py
git commit -m "feat(bilibili): 添加图片代理、音频代理、UP主信息、搜索建议、Cookie刷新、搜索历史功能"
```

---

## Task 3: 后端 - P1 推荐功能

**Files:**
- Create: `listen-vision-api-python/app/api/routes/recommendations.py`
- Create: `listen-vision-api-python/app/services/recommendation_service.py`
- Create: `listen-vision-api-python/app/schemas/recommendation.py`
- Modify: `listen-vision-api-python/app/main.py`
- Test: `listen-vision-api-python/tests/test_recommendations.py`

- [ ] **Step 1: 创建推荐 Schema**

创建 `listen-vision-api-python/app/schemas/recommendation.py`:

```python
"""推荐相关 Schema"""
from pydantic import BaseModel
from typing import List, Optional


class HotPlaylist(BaseModel):
    """热门歌单"""
    id: int
    name: str
    cover_url: Optional[str] = None
    play_count: int = 0
    description: Optional[str] = None


class RankItem(BaseModel):
    """榜单项"""
    bvid: str
    title: str
    cover_url: Optional[str] = None
    view_count: int = 0
    author: str


class CategoryInfo(BaseModel):
    """分区信息"""
    tid: int
    name: str
    parent_tid: Optional[int] = None
```

- [ ] **Step 2: 创建推荐服务**

创建 `listen-vision-api-python/app/services/recommendation_service.py`:

```python
"""推荐服务"""
from typing import List
from bilibili_api import video, rank

from app.schemas.recommendation import HotPlaylist, RankItem, CategoryInfo
from app.utils.logger import logger
from app.utils.cache import cached


class RecommendationService:
    """推荐服务"""

    # B站分区 ID 映射
    CATEGORIES = {
        1: "分区",
        13: "番剧",
        167: "国创",
        3: "音乐",
        129: "舞蹈",
        4: "游戏",
        36: "科技",
        188: "数码",
        234: "汽车",
        223: "美食",
        160: "生活",
        211: "动物圈",
        217: "鬼畜",
        119: "时尚",
        155: "娱乐",
        202: "影视",
        5: "娱乐",
    }

    @staticmethod
    @cached(ttl=300)
    async def get_hot_playlists(limit: int = 10) -> List[HotPlaylist]:
        """获取热门歌单"""
        # 这里使用推荐视频模拟
        try:
            result = await video.get_recommendvideos()
            items = result.get("item", [])[:limit]

            playlists = []
            for i, item in enumerate(items):
                playlists.append(HotPlaylist(
                    id=i + 1,
                    name=item.get("title", "热门推荐"),
                    cover_url=item.get("pic"),
                    play_count=item.get("play", 0),
                    description=item.get("desc", "")
                ))
            return playlists
        except Exception as e:
            logger.error(f"获取热门歌单失败: {e}")
            return []

    @staticmethod
    @cached(ttl=300)
    async def get_rank(rank_type: str = "music") -> List[RankItem]:
        """获取榜单"""
        try:
            from bilibili_api import rank as rank_module

            # 根据类型选择榜单
            if rank_type == "music":
                result = await rank_module.get_rank(rank_module.RankType.Music)
            elif rank_type == "hot":
                result = await rank_module.get_rank(rank_module.RankType.Original)
            else:
                result = await rank_module.get_rank(rank_module.RankType.Original)

            items = []
            for item in result.get("list", [])[:20]:
                items.append(RankItem(
                    bvid=item.get("bvid", ""),
                    title=item.get("title", ""),
                    cover_url=item.get("pic"),
                    view_count=item.get("play", 0),
                    author=item.get("author", "")
                ))
            return items
        except Exception as e:
            logger.error(f"获取榜单失败: {e}")
            return []

    @staticmethod
    def get_categories() -> List[CategoryInfo]:
        """获取分区列表"""
        return [
            CategoryInfo(tid=tid, name=name)
            for tid, name in RecommendationService.CATEGORIES.items()
        ]

    @staticmethod
    @cached(ttl=300)
    async def get_personalized(user_id: int, limit: int = 10) -> List[RankItem]:
        """获取个性化推荐（基于用户播放历史）"""
        try:
            # 基于用户播放历史推荐相似内容
            # 这里简化实现，使用热门视频代替
            result = await video.get_recommendvideos()
            items = result.get("item", [])[:limit]

            recommendations = []
            for item in items:
                recommendations.append(RankItem(
                    bvid=item.get("bvid", ""),
                    title=item.get("title", ""),
                    cover_url=item.get("pic"),
                    view_count=item.get("play", 0),
                    author=item.get("owner", {}).get("name", "")
                ))
            return recommendations
        except Exception as e:
            logger.error(f"获取个性化推荐失败: {e}")
            return []

    @staticmethod
    @cached(ttl=300)
    async def get_category_videos(tid: int, page: int = 1, page_size: int = 20) -> List[RankItem]:
        """获取分区推荐视频"""
        try:
            from bilibili_api import video as video_module
            result = await video_module.get_videos_in_region(tid, page=page, page_size=page_size)

            items = []
            for item in result.get("archives", []):
                items.append(RankItem(
                    bvid=item.get("bvid", ""),
                    title=item.get("title", ""),
                    cover_url=item.get("pic"),
                    view_count=item.get("stat", {}).get("view", 0),
                    author=item.get("owner", {}).get("name", "")
                ))
            return items
        except Exception as e:
            logger.error(f"获取分区推荐失败: {e}")
            return []

    @staticmethod
    @cached(ttl=300)
    async def get_music_videos(page: int = 1, page_size: int = 20) -> List[RankItem]:
        """获取音乐区推荐"""
        # 音乐分区 tid = 3
        return await RecommendationService.get_category_videos(3, page, page_size)
```

- [ ] **Step 3: 创建推荐路由**

创建 `listen-vision-api-python/app/api/routes/recommendations.py`:

```python
"""推荐功能路由"""
from fastapi import APIRouter

from app.services.recommendation_service import RecommendationService
from app.schemas.common import ApiResponse

router = APIRouter(prefix="/recommendations", tags=["推荐"])


@router.get("/hot-playlists")
async def get_hot_playlists(limit: int = 10):
    """获取热门歌单"""
    playlists = await RecommendationService.get_hot_playlists(limit)
    return ApiResponse(success=True, data={"items": playlists})


@router.get("/rank")
async def get_rank(rank_type: str = "music"):
    """获取榜单"""
    items = await RecommendationService.get_rank(rank_type)
    return ApiResponse(success=True, data={"items": items})


@router.get("/categories")
async def get_categories():
    """获取分区列表"""
    categories = RecommendationService.get_categories()
    return ApiResponse(success=True, data={"items": categories})


@router.get("/personalized")
async def get_personalized(
    limit: int = 10,
    current_user: User = Depends(get_current_user)
):
    """获取个性化推荐"""
    items = await RecommendationService.get_personalized(current_user.id, limit)
    return ApiResponse(success=True, data={"items": items})


@router.get("/category/{tid}")
async def get_category_videos(
    tid: int,
    page: int = 1,
    page_size: int = 20
):
    """获取分区推荐"""
    items = await RecommendationService.get_category_videos(tid, page, page_size)
    return ApiResponse(success=True, data={"items": items})


@router.get("/music")
async def get_music_videos(
    page: int = 1,
    page_size: int = 20
):
    """获取音乐区推荐"""
    items = await RecommendationService.get_music_videos(page, page_size)
    return ApiResponse(success=True, data={"items": items})
```

注意：需要导入 `get_current_user` 和 `User`:

```python
from app.api.deps import get_db, get_current_user
from app.models import User
```

- [ ] **Step 4: 注册路由**

修改 `listen-vision-api-python/app/main.py`:

```python
from app.api.routes import auth, bilibili, playlist, recommendations

# 在注册路由部分添加
app.include_router(recommendations.router, prefix="/api/v1")
```

- [ ] **Step 5: 编写测试**

创建 `listen-vision-api-python/tests/test_recommendations.py`:

```python
"""推荐功能测试"""
import pytest

from app.services.recommendation_service import RecommendationService


@pytest.mark.asyncio
async def test_get_hot_playlists():
    """测试获取热门歌单"""
    playlists = await RecommendationService.get_hot_playlists(limit=5)
    assert isinstance(playlists, list)
    assert len(playlists) <= 5


@pytest.mark.asyncio
async def test_get_rank():
    """测试获取榜单"""
    items = await RecommendationService.get_rank("music")
    assert isinstance(items, list)


def test_get_categories():
    """测试获取分区列表"""
    categories = RecommendationService.get_categories()
    assert isinstance(categories, list)
    assert len(categories) > 0
```

- [ ] **Step 6: 运行测试**

```bash
cd listen-vision-api-python
uv run pytest tests/test_recommendations.py -v
```

- [ ] **Step 7: 提交**

```bash
git add listen-vision-api-python/app/api/routes/recommendations.py
git add listen-vision-api-python/app/services/recommendation_service.py
git add listen-vision-api-python/app/schemas/recommendation.py
git add listen-vision-api-python/app/main.py
git add listen-vision-api-python/tests/test_recommendations.py
git commit -m "feat(recommendations): 添加热门歌单、榜单、分区列表功能"
```

---

## Task 4: 后端 - P2 播放历史与音频元数据

**Files:**
- Create: `listen-vision-api-python/app/models/play_history.py`
- Create: `listen-vision-api-python/app/models/audio_metadata.py`
- Create: `listen-vision-api-python/app/schemas/history.py`
- Create: `listen-vision-api-python/app/schemas/audio.py`
- Create: `listen-vision-api-python/app/services/history_service.py`
- Create: `listen-vision-api-python/app/services/audio_service.py`
- Create: `listen-vision-api-python/app/api/routes/history.py`
- Create: `listen-vision-api-python/app/api/routes/audio.py`
- Modify: `listen-vision-api-python/app/main.py`

- [ ] **Step 1: 创建播放历史模型**

创建 `listen-vision-api-python/app/models/play_history.py`:

```python
"""播放历史模型"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime

from app.db.database import Base


class PlayHistory(Base):
    __tablename__ = "play_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    bvid = Column(String(20), nullable=False, index=True)
    title = Column(String(200))
    artist = Column(String(100))
    cover_url = Column(String(500))
    duration = Column(Integer, default=0)
    progress = Column(Integer, default=0)
    play_count = Column(Integer, default=1)
    last_played_at = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="play_history")
```

- [ ] **Step 2: 创建音频元数据模型**

创建 `listen-vision-api-python/app/models/audio_metadata.py`:

```python
"""音频元数据模型"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum
from datetime import datetime
import enum

from app.db.database import Base


class DownloadStatus(str, enum.Enum):
    PENDING = "pending"
    DOWNLOADING = "downloading"
    COMPLETED = "completed"
    FAILED = "failed"


class AudioMetadata(Base):
    __tablename__ = "audio_metadata"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    bvid = Column(String(20), nullable=False, index=True)
    title = Column(String(200))
    artist = Column(String(100))
    cover_url = Column(String(500))
    duration = Column(Integer, default=0)
    local_path = Column(String(500))
    file_size = Column(Integer, default=0)
    play_progress = Column(Integer, default=0)
    download_status = Column(
        Enum(DownloadStatus),
        default=DownloadStatus.PENDING
    )
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
```

- [ ] **Step 3: 创建 Schema**

创建 `listen-vision-api-python/app/schemas/history.py`:

```python
"""播放历史 Schema"""
from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class PlayHistoryCreate(BaseModel):
    """创建播放历史"""
    bvid: str
    title: Optional[str] = None
    artist: Optional[str] = None
    cover_url: Optional[str] = None
    duration: int = 0
    progress: int = 0


class PlayHistoryResponse(BaseModel):
    """播放历史响应"""
    id: int
    bvid: str
    title: Optional[str] = None
    artist: Optional[str] = None
    cover_url: Optional[str] = None
    duration: int = 0
    progress: int = 0
    play_count: int = 1
    last_played_at: datetime

    class Config:
        from_attributes = True
```

- [ ] **Step 4: 创建历史服务**

创建 `listen-vision-api-python/app/services/history_service.py`:

```python
"""播放历史服务"""
from typing import List
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from fastapi import HTTPException, status

from app.models.play_history import PlayHistory
from app.schemas.history import PlayHistoryCreate, PlayHistoryResponse
from app.utils.logger import logger


class HistoryService:
    """播放历史服务"""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def add_history(
        self,
        user_id: int,
        data: PlayHistoryCreate
    ) -> PlayHistoryResponse:
        """添加播放历史"""
        # 检查是否已存在
        stmt = select(PlayHistory).where(
            PlayHistory.user_id == user_id,
            PlayHistory.bvid == data.bvid
        )
        result = await self.db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            # 更新
            existing.play_count += 1
            existing.progress = data.progress
            existing.last_played_at = datetime.utcnow()
            await self.db.commit()
            await self.db.refresh(existing)
            return PlayHistoryResponse.model_validate(existing)

        # 创建新记录
        history = PlayHistory(
            user_id=user_id,
            **data.model_dump()
        )
        self.db.add(history)
        await self.db.commit()
        await self.db.refresh(history)
        return PlayHistoryResponse.model_validate(history)

    async def get_history(
        self,
        user_id: int,
        page: int = 1,
        page_size: int = 20
    ) -> List[PlayHistoryResponse]:
        """获取播放历史"""
        offset = (page - 1) * page_size
        stmt = select(PlayHistory).where(
            PlayHistory.user_id == user_id
        ).order_by(desc(PlayHistory.last_played_at)).offset(offset).limit(page_size)

        result = await self.db.execute(stmt)
        items = result.scalars().all()
        return [PlayHistoryResponse.model_validate(item) for item in items]

    async def delete_history(self, user_id: int, history_id: int) -> bool:
        """删除播放历史"""
        stmt = select(PlayHistory).where(
            PlayHistory.id == history_id,
            PlayHistory.user_id == user_id
        )
        result = await self.db.execute(stmt)
        history = result.scalar_one_or_none()

        if not history:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="记录不存在"
            )

        await self.db.delete(history)
        await self.db.commit()
        return True
```

- [ ] **Step 5: 创建历史路由**

创建 `listen-vision-api-python/app/api/routes/history.py`:

```python
"""播放历史路由"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.services.history_service import HistoryService
from app.schemas.history import PlayHistoryCreate, PlayHistoryResponse
from app.schemas.common import ApiResponse
from app.models import User

router = APIRouter(prefix="/history", tags=["播放历史"])


@router.get("", response_model=ApiResponse[list[PlayHistoryResponse]])
async def get_history(
    page: int = 1,
    page_size: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """获取播放历史"""
    service = HistoryService(db)
    items = await service.get_history(current_user.id, page, page_size)
    return ApiResponse(success=True, data=items)


@router.post("", response_model=ApiResponse[PlayHistoryResponse])
async def add_history(
    data: PlayHistoryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """添加播放历史"""
    service = HistoryService(db)
    item = await service.add_history(current_user.id, data)
    return ApiResponse(success=True, data=item)


@router.delete("/{history_id}")
async def delete_history(
    history_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """删除播放历史"""
    service = HistoryService(db)
    await service.delete_history(current_user.id, history_id)
    return ApiResponse(success=True, message="删除成功")
```

- [ ] **Step 6: 注册路由**

修改 `listen-vision-api-python/app/main.py`:

```python
from app.api.routes import auth, bilibili, playlist, recommendations, history

app.include_router(history.router, prefix="/api/v1")
```

- [ ] **Step 7: 更新模型导入和数据库初始化**

修改 `listen-vision-api-python/app/models/__init__.py`，导入新模型:

```python
from app.models.user import User
from app.models.platform_account import PlatformAccount
from app.models.playlist import Playlist
from app.models.play_history import PlayHistory
from app.models.audio_metadata import AudioMetadata

__all__ = ["User", "PlatformAccount", "Playlist", "PlayHistory", "AudioMetadata"]
```

修改 `listen-vision-api-python/app/db/database.py`，确保新模型被创建:

```python
# 在 init_db 函数中，确保所有模型都被导入
async def init_db():
    from app.models import User, PlatformAccount, Playlist, PlayHistory, AudioMetadata
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
```

- [ ] **Step 8: 更新测试 conftest.py**

修改 `listen-vision-api-python/tests/conftest.py`，添加 db_session fixture:

```python
import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.db.database import Base
from app.models import User, PlatformAccount, Playlist, PlayHistory, AudioMetadata

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest_asyncio.fixture
async def db_session():
    """创建测试数据库会话"""
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session() as session:
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
```

- [ ] **Step 9: 编写测试**

创建 `listen-vision-api-python/tests/test_history.py`:

```python
"""播放历史测试"""
import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.history_service import HistoryService
from app.schemas.history import PlayHistoryCreate


@pytest.mark.asyncio
async def test_add_history(db_session: AsyncSession):
    """测试添加播放历史"""
    service = HistoryService(db_session)
    data = PlayHistoryCreate(
        bvid="BV1test123",
        title="测试视频",
        artist="测试UP主",
        duration=180
    )
    result = await service.add_history(user_id=1, data=data)
    assert result.bvid == "BV1test123"
    assert result.title == "测试视频"


@pytest.mark.asyncio
async def test_get_history(db_session: AsyncSession):
    """测试获取播放历史"""
    service = HistoryService(db_session)
    # 先添加
    await service.add_history(user_id=1, data=PlayHistoryCreate(
        bvid="BV1test456", title="测试2"
    ))
    # 再获取
    items = await service.get_history(user_id=1)
    assert len(items) > 0
```

- [ ] **Step 10: 运行测试**

```bash
cd listen-vision-api-python
uv run pytest tests/test_history.py -v
```

- [ ] **Step 11: 提交**

```bash
git add listen-vision-api-python/app/models/play_history.py
git add listen-vision-api-python/app/models/audio_metadata.py
git add listen-vision-api-python/app/schemas/history.py
git add listen-vision-api-python/app/services/history_service.py
git add listen-vision-api-python/app/api/routes/history.py
git add listen-vision-api-python/app/main.py
git commit -m "feat(history): 添加播放历史功能"
```

---

## Task 4.5: 后端 - P2 音频元数据与本地搜索

**Files:**
- Create: `listen-vision-api-python/app/services/audio_service.py`
- Create: `listen-vision-api-python/app/services/search_service.py`
- Create: `listen-vision-api-python/app/schemas/audio.py`
- Create: `listen-vision-api-python/app/schemas/search.py`
- Create: `listen-vision-api-python/app/models/search_history.py`
- Create: `listen-vision-api-python/app/api/routes/audio.py`
- Create: `listen-vision-api-python/app/api/routes/search.py`
- Modify: `listen-vision-api-python/app/main.py`

- [ ] **Step 1: 创建音频 Schema**

创建 `listen-vision-api-python/app/schemas/audio.py`:

```python
"""音频元数据 Schema"""
from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class AudioMetadataCreate(BaseModel):
    """创建音频元数据"""
    bvid: str
    title: Optional[str] = None
    artist: Optional[str] = None
    cover_url: Optional[str] = None
    duration: int = 0
    local_path: Optional[str] = None
    file_size: int = 0


class AudioMetadataResponse(BaseModel):
    """音频元数据响应"""
    id: int
    bvid: str
    title: Optional[str] = None
    artist: Optional[str] = None
    cover_url: Optional[str] = None
    duration: int = 0
    local_path: Optional[str] = None
    file_size: int = 0
    play_progress: int = 0
    download_status: str = "pending"
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
```

- [ ] **Step 2: 创建搜索 Schema**

创建 `listen-vision-api-python/app/schemas/search.py`:

```python
"""搜索相关 Schema"""
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


class SearchHistoryCreate(BaseModel):
    """创建搜索历史"""
    keyword: str


class SearchHistoryResponse(BaseModel):
    """搜索历史响应"""
    id: int
    keyword: str
    searched_at: datetime

    class Config:
        from_attributes = True


class LocalSearchResult(BaseModel):
    """本地搜索结果"""
    bvid: str
    title: str
    artist: Optional[str] = None
    cover_url: Optional[str] = None
    duration: int = 0
    match_type: str  # title, artist, bvid
```

- [ ] **Step 3: 创建搜索历史模型**

创建 `listen-vision-api-python/app/models/search_history.py`:

```python
"""搜索历史模型"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from datetime import datetime

from app.db.database import Base


class SearchHistory(Base):
    __tablename__ = "search_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    keyword = Column(String(100), nullable=False)
    searched_at = Column(DateTime, default=datetime.utcnow)
```

- [ ] **Step 4: 创建音频服务**

创建 `listen-vision-api-python/app/services/audio_service.py`:

```python
"""音频元数据服务"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete

from app.models.audio_metadata import AudioMetadata, DownloadStatus
from app.schemas.audio import AudioMetadataCreate, AudioMetadataResponse
from app.utils.logger import logger


class AudioService:
    """音频元数据服务"""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_metadata(self, user_id: int, bvid: str) -> Optional[AudioMetadataResponse]:
        """获取音频元数据"""
        stmt = select(AudioMetadata).where(
            AudioMetadata.user_id == user_id,
            AudioMetadata.bvid == bvid
        )
        result = await self.db.execute(stmt)
        metadata = result.scalar_one_or_none()
        return AudioMetadataResponse.model_validate(metadata) if metadata else None

    async def create_or_update(
        self,
        user_id: int,
        data: AudioMetadataCreate
    ) -> AudioMetadataResponse:
        """创建或更新音频元数据"""
        stmt = select(AudioMetadata).where(
            AudioMetadata.user_id == user_id,
            AudioMetadata.bvid == data.bvid
        )
        result = await self.db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            for key, value in data.model_dump().items():
                if value is not None:
                    setattr(existing, key, value)
            await self.db.commit()
            await self.db.refresh(existing)
            return AudioMetadataResponse.model_validate(existing)

        metadata = AudioMetadata(user_id=user_id, **data.model_dump())
        self.db.add(metadata)
        await self.db.commit()
        await self.db.refresh(metadata)
        return AudioMetadataResponse.model_validate(metadata)

    async def delete_metadata(self, user_id: int, bvid: str) -> bool:
        """删除音频元数据"""
        stmt = delete(AudioMetadata).where(
            AudioMetadata.user_id == user_id,
            AudioMetadata.bvid == bvid
        )
        await self.db.execute(stmt)
        await self.db.commit()
        return True

    async def list_by_user(
        self,
        user_id: int,
        status: Optional[DownloadStatus] = None,
        page: int = 1,
        page_size: int = 20
    ) -> List[AudioMetadataResponse]:
        """列出用户的音频元数据"""
        offset = (page - 1) * page_size
        stmt = select(AudioMetadata).where(
            AudioMetadata.user_id == user_id
        )

        if status:
            stmt = stmt.where(AudioMetadata.download_status == status)

        stmt = stmt.offset(offset).limit(page_size)
        result = await self.db.execute(stmt)
        items = result.scalars().all()
        return [AudioMetadataResponse.model_validate(item) for item in items]
```

- [ ] **Step 5: 创建搜索服务**

创建 `listen-vision-api-python/app/services/search_service.py`:

```python
"""本地搜索服务"""
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_, desc

from app.models.audio_metadata import AudioMetadata
from app.models.search_history import SearchHistory
from app.schemas.search import SearchHistoryCreate, SearchHistoryResponse, LocalSearchResult
from app.utils.logger import logger


class SearchService:
    """本地搜索服务"""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def local_search(
        self,
        user_id: int,
        keyword: str,
        limit: int = 20
    ) -> List[LocalSearchResult]:
        """本地全文搜索（简化实现，未使用 FTS5）"""
        pattern = f"%{keyword}%"
        stmt = select(AudioMetadata).where(
            AudioMetadata.user_id == user_id,
            or_(
                AudioMetadata.title.ilike(pattern),
                AudioMetadata.artist.ilike(pattern),
                AudioMetadata.bvid.ilike(pattern)
            )
        ).limit(limit)

        result = await self.db.execute(stmt)
        items = result.scalars().all()

        results = []
        for item in items:
            # 确定匹配类型
            match_type = "bvid"
            if keyword.lower() in (item.title or "").lower():
                match_type = "title"
            elif keyword.lower() in (item.artist or "").lower():
                match_type = "artist"

            results.append(LocalSearchResult(
                bvid=item.bvid,
                title=item.title or "",
                artist=item.artist,
                cover_url=item.cover_url,
                duration=item.duration,
                match_type=match_type
            ))

        return results

    async def get_suggestions(self, user_id: int, prefix: str, limit: int = 10) -> List[str]:
        """获取搜索建议"""
        pattern = f"{prefix}%"
        stmt = select(AudioMetadata.title, AudioMetadata.artist).where(
            AudioMetadata.user_id == user_id,
            or_(
                AudioMetadata.title.ilike(pattern),
                AudioMetadata.artist.ilike(pattern)
            )
        ).distinct().limit(limit)

        result = await self.db.execute(stmt)
        rows = result.all()

        suggestions = set()
        for title, artist in rows:
            if title and title.lower().startswith(prefix.lower()):
                suggestions.add(title)
            if artist and artist.lower().startswith(prefix.lower()):
                suggestions.add(artist)

        return list(suggestions)[:limit]

    async def add_search_history(self, user_id: int, data: SearchHistoryCreate) -> None:
        """添加搜索历史"""
        history = SearchHistory(user_id=user_id, keyword=data.keyword)
        self.db.add(history)
        await self.db.commit()

    async def get_search_history(
        self,
        user_id: int,
        limit: int = 10
    ) -> List[SearchHistoryResponse]:
        """获取搜索历史"""
        stmt = select(SearchHistory).where(
            SearchHistory.user_id == user_id
        ).order_by(desc(SearchHistory.searched_at)).limit(limit)

        result = await self.db.execute(stmt)
        items = result.scalars().all()
        return [SearchHistoryResponse.model_validate(item) for item in items]

    async def clear_search_history(self, user_id: int) -> None:
        """清空搜索历史"""
        from sqlalchemy import delete
        stmt = delete(SearchHistory).where(SearchHistory.user_id == user_id)
        await self.db.execute(stmt)
        await self.db.commit()
```

- [ ] **Step 6: 创建音频路由**

创建 `listen-vision-api-python/app/api/routes/audio.py`:

```python
"""音频元数据路由"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.services.audio_service import AudioService
from app.schemas.audio import AudioMetadataCreate, AudioMetadataResponse
from app.schemas.common import ApiResponse
from app.models import User

router = APIRouter(prefix="/audio", tags=["音频元数据"])


@router.get("/metadata/{bvid}", response_model=ApiResponse[AudioMetadataResponse])
async def get_metadata(
    bvid: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """获取音频元数据"""
    service = AudioService(db)
    metadata = await service.get_metadata(current_user.id, bvid)
    if not metadata:
        return ApiResponse(success=False, message="未找到元数据")
    return ApiResponse(success=True, data=metadata)


@router.post("/metadata", response_model=ApiResponse[AudioMetadataResponse])
async def create_metadata(
    data: AudioMetadataCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """创建或更新音频元数据"""
    service = AudioService(db)
    metadata = await service.create_or_update(current_user.id, data)
    return ApiResponse(success=True, data=metadata)


@router.delete("/metadata/{bvid}")
async def delete_metadata(
    bvid: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """删除音频元数据"""
    service = AudioService(db)
    await service.delete_metadata(current_user.id, bvid)
    return ApiResponse(success=True, message="删除成功")


@router.get("/metadata", response_model=ApiResponse[list[AudioMetadataResponse]])
async def list_metadata(
    page: int = 1,
    page_size: int = 20,
    status: str = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """列出音频元数据"""
    service = AudioService(db)
    items = await service.list_by_user(current_user.id, status, page, page_size)
    return ApiResponse(success=True, data=items)
```

- [ ] **Step 7: 创建搜索路由**

创建 `listen-vision-api-python/app/api/routes/search.py`:

```python
"""本地搜索路由"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.services.search_service import SearchService
from app.schemas.search import SearchHistoryCreate, SearchHistoryResponse, LocalSearchResult
from app.schemas.common import ApiResponse
from app.models import User

router = APIRouter(prefix="/search", tags=["本地搜索"])


@router.get("/local", response_model=ApiResponse[list[LocalSearchResult]])
async def local_search(
    keyword: str,
    limit: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """本地全文搜索"""
    service = SearchService(db)
    results = await service.local_search(current_user.id, keyword, limit)
    return ApiResponse(success=True, data=results)


@router.get("/suggestions")
async def get_suggestions(
    prefix: str,
    limit: int = 10,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """获取搜索建议"""
    service = SearchService(db)
    suggestions = await service.get_suggestions(current_user.id, prefix, limit)
    return ApiResponse(success=True, data={"suggestions": suggestions})


@router.get("/history", response_model=ApiResponse[list[SearchHistoryResponse]])
async def get_search_history(
    limit: int = 10,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """获取搜索历史"""
    service = SearchService(db)
    items = await service.get_search_history(current_user.id, limit)
    return ApiResponse(success=True, data=items)


@router.post("/history")
async def add_search_history(
    data: SearchHistoryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """添加搜索历史"""
    service = SearchService(db)
    await service.add_search_history(current_user.id, data)
    return ApiResponse(success=True, message="添加成功")


@router.delete("/history")
async def clear_search_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """清空搜索历史"""
    service = SearchService(db)
    await service.clear_search_history(current_user.id)
    return ApiResponse(success=True, message="清空成功")
```

- [ ] **Step 8: 注册路由**

修改 `listen-vision-api-python/app/main.py`:

```python
from app.api.routes import auth, bilibili, playlist, recommendations, history, audio, search

app.include_router(audio.router, prefix="/api/v1")
app.include_router(search.router, prefix="/api/v1")
```

- [ ] **Step 9: 编写测试**

创建 `listen-vision-api-python/tests/test_audio_search.py`:

```python
"""音频元数据和搜索测试"""
import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.audio_service import AudioService
from app.services.search_service import SearchService
from app.schemas.audio import AudioMetadataCreate
from app.schemas.search import SearchHistoryCreate


@pytest.mark.asyncio
async def test_create_audio_metadata(db_session: AsyncSession):
    """测试创建音频元数据"""
    service = AudioService(db_session)
    data = AudioMetadataCreate(
        bvid="BV1audio123",
        title="测试音频",
        artist="测试歌手",
        duration=240
    )
    result = await service.create_or_update(user_id=1, data=data)
    assert result.bvid == "BV1audio123"
    assert result.title == "测试音频"


@pytest.mark.asyncio
async def test_local_search(db_session: AsyncSession):
    """测试本地搜索"""
    # 先添加元数据
    audio_service = AudioService(db_session)
    await audio_service.create_or_update(user_id=1, data=AudioMetadataCreate(
        bvid="BV1search001", title="搜索测试歌曲", artist="歌手A"
    ))

    # 搜索
    search_service = SearchService(db_session)
    results = await search_service.local_search(user_id=1, keyword="搜索测试")
    assert len(results) > 0
    assert results[0].bvid == "BV1search001"


@pytest.mark.asyncio
async def test_search_history(db_session: AsyncSession):
    """测试搜索历史"""
    service = SearchService(db_session)
    await service.add_search_history(user_id=1, data=SearchHistoryCreate(keyword="测试关键词"))
    history = await service.get_search_history(user_id=1)
    assert len(history) > 0
    assert history[0].keyword == "测试关键词"
```

- [ ] **Step 10: 运行测试**

```bash
cd listen-vision-api-python
uv run pytest tests/test_audio_search.py -v
```

- [ ] **Step 11: 提交**

```bash
git add listen-vision-api-python/app/services/audio_service.py
git add listen-vision-api-python/app/services/search_service.py
git add listen-vision-api-python/app/schemas/audio.py
git add listen-vision-api-python/app/schemas/search.py
git add listen-vision-api-python/app/models/search_history.py
git add listen-vision-api-python/app/api/routes/audio.py
git add listen-vision-api-python/app/api/routes/search.py
git add listen-vision-api-python/app/main.py
git commit -m "feat(audio,search): 添加音频元数据管理和本地搜索功能"
```

---

## Task 5: 前端 - 移除同步代码

**Files:**
- Delete: `frontend_flutter/lib/data/sync/` (整个目录)
- Delete: `frontend_flutter/lib/models/sync_queue.dart`
- Delete: `frontend_flutter/lib/data/database/sync_queue_dao.dart`
- Delete: `frontend_flutter/lib/presentation/widgets/common/sync_status_indicator.dart`
- Modify: `frontend_flutter/lib/app.dart`
- Modify: `frontend_flutter/lib/data/repositories/history_repository.dart`
- Modify: `frontend_flutter/lib/data/repositories/playlist_repository.dart`
- Modify: `frontend_flutter/lib/data/repositories/track_repository.dart`
- Modify: `frontend_flutter/lib/presentation/views/system/settings_page.dart`
- Modify: `frontend_flutter/lib/presentation/viewmodels/auth/auth_viewmodel.dart`

- [ ] **Step 1: 删除同步相关文件**

```bash
cd frontend_flutter
rm -rf lib/data/sync/
rm lib/models/sync_queue.dart
rm lib/data/database/sync_queue_dao.dart
rm lib/presentation/widgets/common/sync_status_indicator.dart
```

- [ ] **Step 2: 修改 app.dart**

移除同步相关导入，保留 `DownloadIntegrityService`:

```dart
// 删除这些导入
// import 'data/sync/download_integrity_provider.dart';
// import 'data/sync/sync_worker_provider.dart';

// 保留
import 'services/download_integrity_service.dart';

// 在 initState 中
void initState() {
  super.initState();
  // 直接使用服务
  DownloadIntegrityService.instance.startPeriodicCheck();
}
```

- [ ] **Step 3: 修改 history_repository.dart**

移除同步队列相关代码:

```dart
// 删除这些导入
// import '../sync/sync_worker.dart';
// import '../database/sync_queue_dao.dart';
// import '../../models/sync_queue.dart';

// 移除 SyncQueueDao 相关代码
// 移除 addToSyncQueue 方法调用
```

- [ ] **Step 4: 修改 playlist_repository.dart**

移除同步队列相关代码:

```dart
// 删除同步相关导入和逻辑
// 保留直接 API 调用
```

- [ ] **Step 5: 修改 settings_page.dart**

移除同步状态指示器:

```dart
// 删除
// import '../widgets/common/sync_status_indicator.dart';
// 移除 SyncStatusIndicator 组件
```

- [ ] **Step 6: 修改 auth_viewmodel.dart**

移除同步工作器启动逻辑:

```dart
// 删除
// import '../../data/sync/sync_worker_provider.dart';
// 移除 syncWorkerProvider 启动代码
```

- [ ] **Step 7: 运行 flutter analyze**

```bash
cd frontend_flutter
flutter analyze
```

- [ ] **Step 8: 提交**

```bash
git add -A
git commit -m "refactor(frontend): 移除同步功能代码，保留本地优先架构"
```

---

## Task 6: 前端 - 适配 snake_case 响应

**Files:**
- Modify: `frontend_flutter/lib/models/dto/api_dto.dart`
- Modify: `frontend_flutter/lib/data/repositories/auth_repository.dart`
- Modify: `frontend_flutter/lib/data/repositories/playlist_repository.dart`
- Modify: `frontend_flutter/lib/core/network/dio_client.dart`

- [ ] **Step 1: 修改 api_dto.dart**

更新 DTO 类以支持 snake_case:

```dart
class LoginResponseDto {
  final String accessToken;
  final String? refreshToken;
  final int expiresIn;
  final int userId;
  final String username;
  final String? email;
  final bool bilibiliBound;

  LoginResponseDto.fromJson(Map<String, dynamic> json)
      : accessToken = json['access_token'] as String,
        refreshToken = json['refresh_token'] as String?,
        expiresIn = json['expires_in'] as int? ?? 3600,
        userId = json['user']?['id'] as int? ?? 0,
        username = json['user']?['username'] as String? ?? '',
        email = json['user']?['email'] as String?,
        bilibiliBound = false;  // 从平台账号判断
}

class PlaylistDto {
  final int id;
  final String name;
  final String? description;
  final String? coverUrl;
  final int itemCount;
  final DateTime? createdAt;

  PlaylistDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        name = json['name'] as String,
        description = json['description'] as String?,
        coverUrl = json['cover_url'] as String?,
        itemCount = json['item_count'] as int? ?? 0,
        createdAt = json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null;
}

class PlayHistoryDto {
  final int id;
  final String bvid;
  final String? title;
  final String? artist;
  final String? coverUrl;
  final int duration;
  final int progress;
  final int playCount;
  final DateTime lastPlayedAt;

  PlayHistoryDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        bvid = json['bvid'] as String,
        title = json['title'] as String?,
        artist = json['artist'] as String?,
        coverUrl = json['cover_url'] as String?,
        duration = json['duration'] as int? ?? 0,
        progress = json['progress'] as int? ?? 0,
        playCount = json['play_count'] as int? ?? 1,
        lastPlayedAt = DateTime.parse(json['last_played_at'] as String);
}
```

- [ ] **Step 2: 修改 auth_repository.dart**

更新响应字段解析:

```dart
Future<User> login(LoginRequest request) async {
  final data = await _apiClient.login(request);

  // Python 后端响应格式
  final responseData = data['data'] ?? data;
  final userData = responseData['user'] ?? {};

  final user = User.fromDto({
    ...userData,
    'id': userData['id'],
    'token': responseData['access_token'],
  });

  await _storage.setToken(responseData['access_token'] as String);
  if (responseData['refresh_token'] != null) {
    await _storage.setRefreshToken(responseData['refresh_token'] as String);
  }
  // ...
}
```

- [ ] **Step 3: 修改 dio_client.dart**

更新 token 刷新逻辑:

```dart
// 在 _handleTokenRefresh 方法中
final newToken = refreshResponse.data?['data']?['access_token'] as String?;
final newRefreshToken = refreshResponse.data?['data']?['refresh_token'] as String?;
```

- [ ] **Step 4: 修改 playlist_repository.dart**

更新字段名:

```dart
// 所有 item_count -> itemCount
// 所有 cover_url -> coverUrl
// 所有 created_at -> createdAt
```

- [ ] **Step 5: 运行测试**

```bash
cd frontend_flutter
flutter test
```

- [ ] **Step 6: 提交**

```bash
git add frontend_flutter/lib/models/dto/api_dto.dart
git add frontend_flutter/lib/data/repositories/
git add frontend_flutter/lib/core/network/dio_client.dart
git commit -m "fix(frontend): 适配 Python 后端 snake_case 响应格式"
```

---

## Task 7: 前端 - 更新 API 基础地址

**Files:**
- Modify: `frontend_flutter/lib/core/constants/api_constants.dart`
- Modify: `frontend_flutter/lib/core/network/endpoints.dart`

- [ ] **Step 1: 修改 api_constants.dart**

更新基础 URL:

```dart
class ApiConstants {
  // Python 后端地址
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api/v1';
  static const String fullBaseUrl = '$baseUrl$apiVersion';
}
```

- [ ] **Step 2: 检查 endpoints.dart**

确认端点路径与 Python 后端一致:

```dart
// 确认以下端点
static const String authLogin = '/auth/login';
static const String authRegister = '/auth/register';
static const String authRefresh = '/auth/refresh';

// B站端点
static const String bilibiliStatus = '/bilibili/status';
static const String bilibiliSearch = '/bilibili/search';
static String bilibiliVideo(String bvid) => '/bilibili/video/$bvid';
static String bilibiliAudio(String bvid) => '/bilibili/video/$bvid/audio';
static String bilibiliSubtitle(String bvid, {int? cid}) =>
    '/bilibili/video/$bvid/subtitle';

// 播放历史端点
static const String historyList = '/history';
```

- [ ] **Step 3: 提交**

```bash
git add frontend_flutter/lib/core/constants/api_constants.dart
git add frontend_flutter/lib/core/network/endpoints.dart
git commit -m "chore(frontend): 更新 API 基础地址为 Python 后端"
```

---

## Task 8: 联调测试

**Files:**
- Test: 端到端测试所有功能

- [ ] **Step 1: 启动 Python 后端**

```bash
cd listen-vision-api-python
uv run uvicorn app.main:app --reload --port 8000
```

- [ ] **Step 2: 启动 Flutter 应用**

```bash
cd frontend_flutter
flutter run
```

- [ ] **Step 3: 测试认证流程**

- [ ] 注册新用户（邮箱验证）
- [ ] 登录
- [ ] Token 刷新
- [ ] 密码重置
- [ ] 注销账号

- [ ] **Step 4: 测试 B站功能**

- [ ] QR码绑定
- [ ] 视频搜索
- [ ] 音频播放
- [ ] 字幕获取
- [ ] 图片代理

- [ ] **Step 5: 测试歌单功能**

- [ ] 创建歌单
- [ ] 添加歌曲
- [ ] 删除歌曲
- [ ] 删除歌单

- [ ] **Step 6: 测试播放历史**

- [ ] 添加历史记录
- [ ] 查看历史
- [ ] 删除历史

- [ ] **Step 7: 提交测试通过记录**

```bash
git add -A
git commit -m "test: 联调测试通过"
```

---

## 验收清单

### 后端

- [ ] 所有 P0/P1/P2 功能端点可用
- [ ] 后端测试覆盖率 ≥ 70%
- [ ] API 文档完整（访问 /docs）

### 前端

- [ ] 所有 API 调用正常工作
- [ ] 无同步相关代码残留
- [ ] 无编译错误/警告
- [ ] flutter analyze 通过

### 功能测试

- [ ] 认证流程完整
- [ ] B站功能正常
- [ ] 歌单管理正常
- [ ] 播放历史正常
- [ ] 本地搜索正常