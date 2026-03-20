import pytest
from app.models.platform_account import PlatformAccount, PlatformType
from app.db.repositories.platform_account_repo import PlatformAccountRepository
from app.db.repositories.user_repo import UserRepository
from app.db.database import AsyncSessionLocal, init_db


@pytest.mark.asyncio
async def test_create_bilibili_account():
    """测试创建B站账号绑定"""
    await init_db()

    async with AsyncSessionLocal() as session:
        # 创建用户
        user_repo = UserRepository(session)
        user = await user_repo.create(email="bili@example.com", hashed_password="pass")

        # 创建B站绑定
        repo = PlatformAccountRepository(session)
        account = await repo.create_bilibili(
            user_id=user.id,
            sessdata="test_sessdata",
            bili_jct="test_bili_jct",
            dedeuserid="12345",
            platform_username="TestUser"
        )

        assert account.platform_type == PlatformType.BILIBILI
        assert account.sessdata == "test_sessdata"
        assert account.dedeuserid == "12345"


@pytest.mark.asyncio
async def test_get_bilibili_account():
    """测试获取B站账号"""
    async with AsyncSessionLocal() as session:
        user_repo = UserRepository(session)
        user = await user_repo.create(email="get@example.com", hashed_password="pass")

        repo = PlatformAccountRepository(session)
        await repo.create_bilibili(
            user_id=user.id,
            sessdata="sess",
            bili_jct="jct",
            dedeuserid="12345"
        )

        account = await repo.get_by_user_and_platform(user.id, PlatformType.BILIBILI)
        assert account is not None
        assert account.dedeuserid == "12345"


@pytest.mark.asyncio
async def test_delete_bilibili_account():
    """测试删除B站账号绑定"""
    async with AsyncSessionLocal() as session:
        user_repo = UserRepository(session)
        user = await user_repo.create(email="del@example.com", hashed_password="pass")

        repo = PlatformAccountRepository(session)
        await repo.create_bilibili(
            user_id=user.id,
            sessdata="sess",
            bili_jct="jct",
            dedeuserid="12345"
        )

        # 删除
        await repo.delete_by_platform(user.id, PlatformType.BILIBILI)

        # 验证已删除
        account = await repo.get_by_user_and_platform(user.id, PlatformType.BILIBILI)
        assert account is None
