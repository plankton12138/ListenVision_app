import pytest
import uuid
from app.db.repositories.playlist_repo import PlaylistRepository
from app.db.repositories.user_repo import UserRepository
from app.db.database import AsyncSessionLocal, init_db


def _unique_email(prefix: str = "playlist") -> str:
    """生成唯一邮箱，确保测试可重复运行"""
    return f"{prefix}_{uuid.uuid4().hex[:8]}@example.com"


@pytest.mark.asyncio
async def test_create_playlist():
    """测试创建歌单"""
    await init_db()

    async with AsyncSessionLocal() as session:
        user_repo = UserRepository(session)
        user = await user_repo.create(email=_unique_email(), hashed_password="pass")

        repo = PlaylistRepository(session)
        playlist = await repo.create(
            user_id=user.id,
            name="My Playlist",
            description="Test playlist"
        )

        assert playlist.name == "My Playlist"
        assert playlist.description == "Test playlist"
        assert playlist.user_id == user.id


@pytest.mark.asyncio
async def test_add_and_get_items():
    """测试添加和获取歌单项"""
    async with AsyncSessionLocal() as session:
        user_repo = UserRepository(session)
        user = await user_repo.create(email=_unique_email("items"), hashed_password="pass")

        repo = PlaylistRepository(session)
        playlist = await repo.create(user_id=user.id, name="Test")

        # 添加歌曲
        success = await repo.add_item(
            playlist_id=playlist.id,
            bvid="BV1xx411c7mD",
            title="Test Song",
            artist="Test Artist"
        )
        assert success is True

        # 获取歌曲
        items = await repo.get_items(playlist.id)
        assert len(items) == 1
        assert items[0]["bvid"] == "BV1xx411c7mD"
        assert items[0]["title"] == "Test Song"


@pytest.mark.asyncio
async def test_remove_item():
    """测试移除歌单项"""
    async with AsyncSessionLocal() as session:
        user_repo = UserRepository(session)
        user = await user_repo.create(email=_unique_email("remove"), hashed_password="pass")

        repo = PlaylistRepository(session)
        playlist = await repo.create(user_id=user.id, name="Test")

        await repo.add_item(playlist.id, "BV1xx411c7mD", "Song")

        success = await repo.remove_item(playlist.id, "BV1xx411c7mD")
        assert success is True

        items = await repo.get_items(playlist.id)
        assert len(items) == 0


@pytest.mark.asyncio
async def test_delete_playlist():
    """测试删除歌单"""
    async with AsyncSessionLocal() as session:
        user_repo = UserRepository(session)
        user = await user_repo.create(email=_unique_email("del"), hashed_password="pass")

        repo = PlaylistRepository(session)
        playlist = await repo.create(user_id=user.id, name="To Delete")

        success = await repo.delete(playlist.id)
        assert success is True

        deleted = await repo.get_by_id(playlist.id)
        assert deleted is None
