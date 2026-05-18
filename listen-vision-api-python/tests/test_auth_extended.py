"""扩展认证功能测试"""
import pytest
import uuid
from app.services.auth_service import AuthService
from app.schemas.auth import UserCreate
from app.db.database import AsyncSessionLocal, engine, Base
from app.models import User, PlatformAccount, Playlist


@pytest.fixture(autouse=True)
async def setup_db():
    """每个测试前重置数据库"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield


@pytest.mark.asyncio
async def test_send_verification_code():
    """测试发送验证码"""
    async with AsyncSessionLocal() as session:
        service = AuthService(session)
        email = f"verify_{uuid.uuid4().hex[:8]}@example.com"

        # 发送注册验证码
        code = await service.send_verification_code(email, "register")

        # 开发环境应该返回验证码
        assert code is not None
        assert len(code) == 6
        assert code.isdigit()

        # 验证验证码已存储
        key = f"register:{email.lower()}"
        assert key in AuthService._verification_codes


@pytest.mark.asyncio
async def test_send_verification_code_duplicate_email():
    """测试已注册邮箱发送验证码失败"""
    async with AsyncSessionLocal() as session:
        service = AuthService(session)
        email = f"dup_{uuid.uuid4().hex[:8]}@example.com"

        # 先注册用户
        await service.register(UserCreate(
            email=email,
            password="password123"
        ))

        # 尝试发送注册验证码
        with pytest.raises(Exception) as exc_info:
            await service.send_verification_code(email, "register")
        assert "邮箱已被注册" in str(exc_info.value)


@pytest.mark.asyncio
async def test_verify_email_and_register():
    """测试验证邮箱并注册"""
    async with AsyncSessionLocal() as session:
        service = AuthService(session)
        email = f"new_{uuid.uuid4().hex[:8]}@example.com"

        # 发送验证码
        code = await service.send_verification_code(email, "register")

        # 验证邮箱并注册
        user = await service.verify_email_and_register(
            email=email,
            code=code,
            password="newpassword123",
            username="newuser"
        )

        assert user.email == email
        assert user.username == "newuser"


@pytest.mark.asyncio
async def test_verify_email_invalid_code():
    """测试无效验证码"""
    async with AsyncSessionLocal() as session:
        service = AuthService(session)
        email = f"invalid_{uuid.uuid4().hex[:8]}@example.com"

        # 发送验证码
        await service.send_verification_code(email, "register")

        # 使用错误的验证码
        with pytest.raises(Exception) as exc_info:
            await service.verify_email_and_register(
                email=email,
                code="000000",  # 错误的验证码
                password="password123"
            )
        assert "验证码无效或已过期" in str(exc_info.value)


@pytest.mark.asyncio
async def test_reset_password():
    """测试重置密码"""
    async with AsyncSessionLocal() as session:
        service = AuthService(session)
        email = f"reset_{uuid.uuid4().hex[:8]}@example.com"

        # 先注册用户
        await service.register(UserCreate(
            email=email,
            password="oldpassword"
        ))

        # 发送重置密码验证码
        code = await service.send_verification_code(email, "reset_password")

        # 重置密码
        await service.reset_password(
            email=email,
            code=code,
            new_password="newpassword123"
        )

        # 使用新密码登录
        token = await service.login(email, "newpassword123")
        assert token.access_token is not None


@pytest.mark.asyncio
async def test_reset_password_invalid_code():
    """测试重置密码无效验证码"""
    async with AsyncSessionLocal() as session:
        service = AuthService(session)
        email = f"reset_invalid_{uuid.uuid4().hex[:8]}@example.com"

        # 先注册用户
        await service.register(UserCreate(
            email=email,
            password="password123"
        ))

        # 发送验证码
        await service.send_verification_code(email, "reset_password")

        # 使用错误的验证码
        with pytest.raises(Exception) as exc_info:
            await service.reset_password(
                email=email,
                code="000000",
                new_password="newpassword"
            )
        assert "验证码无效或已过期" in str(exc_info.value)


@pytest.mark.asyncio
async def test_delete_account():
    """测试删除账号"""
    async with AsyncSessionLocal() as session:
        service = AuthService(session)
        email = f"delete_{uuid.uuid4().hex[:8]}@example.com"

        # 注册用户
        user = await service.register(UserCreate(
            email=email,
            password="password123"
        ))

        # 删除账号
        result = await service.delete_account(user.id)
        assert result is True

        # 尝试登录应该失败
        with pytest.raises(Exception) as exc_info:
            await service.login(email, "password123")
        assert "用户不存在" in str(exc_info.value)


@pytest.mark.asyncio
async def test_delete_nonexistent_account():
    """测试删除不存在的账号"""
    async with AsyncSessionLocal() as session:
        service = AuthService(session)

        with pytest.raises(Exception) as exc_info:
            await service.delete_account(99999)
        assert "用户不存在" in str(exc_info.value)


@pytest.mark.asyncio
async def test_send_reset_code_to_nonexistent_email():
    """测试向未注册邮箱发送重置密码验证码"""
    async with AsyncSessionLocal() as session:
        service = AuthService(session)
        email = f"nonexistent_{uuid.uuid4().hex[:8]}@example.com"

        with pytest.raises(Exception) as exc_info:
            await service.send_verification_code(email, "reset_password")
        assert "邮箱未注册" in str(exc_info.value)