import pytest
from app.models.user import User
from app.db.repositories.user_repo import UserRepository
from app.db.database import init_db, AsyncSessionLocal


@pytest.mark.asyncio
async def test_user_creation():
    """测试用户创建"""
    await init_db()

    async with AsyncSessionLocal() as session:
        repo = UserRepository(session)
        user = await repo.create(
            email="test@example.com",
            hashed_password="hashed_password",
            username="testuser"
        )

        assert user.id is not None
        assert user.email == "test@example.com"
        assert user.username == "testuser"
        assert user.is_active is True


@pytest.mark.asyncio
async def test_get_user_by_email():
    """测试通过邮箱获取用户"""
    async with AsyncSessionLocal() as session:
        repo = UserRepository(session)

        # 创建用户
        await repo.create(
            email="find@example.com",
            hashed_password="hashed_password"
        )

        # 查找用户
        user = await repo.get_by_email("find@example.com")
        assert user is not None
        assert user.email == "find@example.com"


@pytest.mark.asyncio
async def test_user_exists_by_email():
    """测试检查邮箱存在性"""
    async with AsyncSessionLocal() as session:
        repo = UserRepository(session)

        await repo.create(email="exists@example.com", hashed_password="pass")

        exists = await repo.exists_by_email("exists@example.com")
        not_exists = await repo.exists_by_email("notexists@example.com")

        assert exists is True
        assert not_exists is False
