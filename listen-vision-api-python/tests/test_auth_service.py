import pytest
import uuid
from app.services.auth_service import AuthService
from app.schemas.auth import UserCreate
from app.db.database import AsyncSessionLocal, init_db, engine, Base
from app.models import User, PlatformAccount, Playlist


@pytest.fixture(autouse=True)
async def setup_db():
    """每个测试前重置数据库"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield


@pytest.mark.asyncio
async def test_user_registration():
    """测试用户注册"""
    async with AsyncSessionLocal() as session:
        service = AuthService(session)
        email = f"user_{uuid.uuid4().hex[:8]}@example.com"
        user_data = UserCreate(
            email=email,
            password="password123",
            username="newuser"
        )

        user = await service.register(user_data)
        assert user.email == email
        assert user.username == "newuser"


@pytest.mark.asyncio
async def test_duplicate_registration():
    """测试重复注册"""
    async with AsyncSessionLocal() as session:
        service = AuthService(session)
        email = f"dup_{uuid.uuid4().hex[:8]}@example.com"
        user_data = UserCreate(
            email=email,
            password="password123"
        )

        await service.register(user_data)

        with pytest.raises(Exception) as exc_info:
            await service.register(user_data)
        assert "邮箱已被注册" in str(exc_info.value)


@pytest.mark.asyncio
async def test_login():
    """测试登录"""
    async with AsyncSessionLocal() as session:
        service = AuthService(session)
        email = f"login_{uuid.uuid4().hex[:8]}@example.com"

        # 注册用户
        await service.register(UserCreate(
            email=email,
            password="password123"
        ))

        # 登录
        token = await service.login(email, "password123")
        assert token.access_token is not None
        assert token.refresh_token is not None


@pytest.mark.asyncio
async def test_wrong_password():
    """测试错误密码"""
    async with AsyncSessionLocal() as session:
        service = AuthService(session)
        email = f"wrong_{uuid.uuid4().hex[:8]}@example.com"

        await service.register(UserCreate(
            email=email,
            password="password123"
        ))

        with pytest.raises(Exception) as exc_info:
            await service.login(email, "wrongpassword")
        assert "邮箱或密码错误" in str(exc_info.value)