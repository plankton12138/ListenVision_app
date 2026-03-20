"""播放历史测试"""
import pytest
from app.db.repositories.history_repo import HistoryRepository
from app.db.repositories.user_repo import UserRepository
from app.db.database import AsyncSessionLocal, init_db


@pytest.mark.asyncio
async def test_create_history():
    """测试创建播放历史"""
    await init_db()

    async with AsyncSessionLocal() as session:
        user_repo = UserRepository(session)
        user = await user_repo.create(email="history@example.com", hashed_password="pass")

        repo = HistoryRepository(session)
        history = await repo.create(
            user_id=user.id,
            bvid="BV1xx411c7mD",
            title="Test Song",
            artist="Test Artist",
            duration=180
        )

        assert history.bvid == "BV1xx411c7mD"
        assert history.title == "Test Song"
        assert history.artist == "Test Artist"
        assert history.duration == 180
        assert history.play_count == 1


@pytest.mark.asyncio
async def test_get_by_user_and_bvid():
    """测试根据用户和BVID获取历史"""
    async with AsyncSessionLocal() as session:
        user_repo = UserRepository(session)
        user = await user_repo.create(email="history_bvid@example.com", hashed_password="pass")

        repo = HistoryRepository(session)
        await repo.create(
            user_id=user.id,
            bvid="BV1xx411c7mD",
            title="Test Song"
        )

        found = await repo.get_by_user_and_bvid(user.id, "BV1xx411c7mD")
        assert found is not None
        assert found.title == "Test Song"

        not_found = await repo.get_by_user_and_bvid(user.id, "BV1notfound")
        assert not_found is None


@pytest.mark.asyncio
async def test_update_play_info():
    """测试更新播放信息"""
    async with AsyncSessionLocal() as session:
        user_repo = UserRepository(session)
        user = await user_repo.create(email="history_update@example.com", hashed_password="pass")

        repo = HistoryRepository(session)
        history = await repo.create(
            user_id=user.id,
            bvid="BV1xx411c7mD",
            title="Test Song",
            progress=30
        )

        # 更新播放信息
        updated = await repo.update_play_info(history.id, progress=60)
        assert updated.play_count == 2
        assert updated.progress == 60


@pytest.mark.asyncio
async def test_get_by_user_paginated():
    """测试分页获取用户历史"""
    async with AsyncSessionLocal() as session:
        user_repo = UserRepository(session)
        user = await user_repo.create(email="history_page@example.com", hashed_password="pass")

        repo = HistoryRepository(session)
        # 创建多条记录
        for i in range(5):
            await repo.create(
                user_id=user.id,
                bvid=f"BV{i:010d}",
                title=f"Song {i}"
            )

        items, total = await repo.get_by_user(user.id, page=1, page_size=3)
        assert len(items) == 3
        assert total == 5

        items2, _ = await repo.get_by_user(user.id, page=2, page_size=3)
        assert len(items2) == 2


@pytest.mark.asyncio
async def test_delete_history():
    """测试删除播放历史"""
    async with AsyncSessionLocal() as session:
        user_repo = UserRepository(session)
        user = await user_repo.create(email="history_del@example.com", hashed_password="pass")

        repo = HistoryRepository(session)
        history = await repo.create(
            user_id=user.id,
            bvid="BV1xx411c7mD",
            title="Test Song"
        )

        success = await repo.delete(history.id)
        assert success is True

        deleted = await repo.get_by_id(history.id)
        assert deleted is None


@pytest.mark.asyncio
async def test_delete_by_user():
    """测试清空用户历史"""
    async with AsyncSessionLocal() as session:
        user_repo = UserRepository(session)
        user = await user_repo.create(email="history_clear@example.com", hashed_password="pass")

        repo = HistoryRepository(session)
        # 创建多条记录
        for i in range(3):
            await repo.create(
                user_id=user.id,
                bvid=f"BV{i:010d}",
                title=f"Song {i}"
            )

        count = await repo.delete_by_user(user.id)
        assert count == 3

        items, total = await repo.get_by_user(user.id)
        assert total == 0