"""音频元数据和本地搜索测试"""
import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import select

from app.db.database import Base
from app.models import User, AudioMetadata, SearchHistory, DownloadStatus
from app.services.audio_service import AudioService
from app.services.search_service import SearchService
from app.schemas.audio import AudioMetadataCreate, AudioMetadataUpdate
from app.schemas.search import SearchHistoryCreate

# 使用内存数据库测试
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest_asyncio.fixture
async def db_engine():
    """创建测试数据库引擎"""
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db_session(db_engine):
    """创建测试数据库会话"""
    async_session = async_sessionmaker(
        db_engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    async with async_session() as session:
        yield session


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession):
    """创建测试用户"""
    user = User(
        id=1,
        email="test@example.com",
        hashed_password="hashed_password",
        username="testuser"
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


class TestAudioService:
    """音频元数据服务测试"""

    @pytest.mark.asyncio
    async def test_create_audio_metadata(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试创建音频元数据"""
        service = AudioService(db_session)
        data = AudioMetadataCreate(
            bvid="BV1audio123",
            title="测试音频",
            artist="测试歌手",
            duration=240
        )
        result = await service.create_or_update(test_user.id, data)

        assert result.bvid == "BV1audio123"
        assert result.title == "测试音频"
        assert result.artist == "测试歌手"
        assert result.duration == 240
        assert result.download_status == "pending"

    @pytest.mark.asyncio
    async def test_update_audio_metadata(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试更新音频元数据"""
        service = AudioService(db_session)

        # 创建
        await service.create_or_update(test_user.id, AudioMetadataCreate(
            bvid="BV1update001",
            title="原标题"
        ))

        # 更新
        result = await service.update_metadata(
            test_user.id,
            "BV1update001",
            AudioMetadataUpdate(
                title="新标题",
                artist="新歌手"
            )
        )

        assert result is not None
        assert result.title == "新标题"
        assert result.artist == "新歌手"

    @pytest.mark.asyncio
    async def test_update_download_status(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试更新下载状态"""
        service = AudioService(db_session)

        # 创建
        await service.create_or_update(test_user.id, AudioMetadataCreate(
            bvid="BV1status001",
            title="状态测试"
        ))

        # 更新状态
        result = await service.update_metadata(
            test_user.id,
            "BV1status001",
            AudioMetadataUpdate(download_status="completed")
        )

        assert result is not None
        assert result.download_status == "completed"

    @pytest.mark.asyncio
    async def test_get_metadata(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试获取音频元数据"""
        service = AudioService(db_session)

        # 创建
        await service.create_or_update(test_user.id, AudioMetadataCreate(
            bvid="BV1get001",
            title="获取测试"
        ))

        # 获取
        result = await service.get_metadata(test_user.id, "BV1get001")

        assert result is not None
        assert result.bvid == "BV1get001"

    @pytest.mark.asyncio
    async def test_get_metadata_not_found(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试获取不存在的元数据"""
        service = AudioService(db_session)
        result = await service.get_metadata(test_user.id, "BV1notfound")
        assert result is None

    @pytest.mark.asyncio
    async def test_delete_metadata(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试删除音频元数据"""
        service = AudioService(db_session)

        # 创建
        await service.create_or_update(test_user.id, AudioMetadataCreate(
            bvid="BV1delete001",
            title="删除测试"
        ))

        # 删除
        await service.delete_metadata(test_user.id, "BV1delete001")

        # 验证已删除
        result = await service.get_metadata(test_user.id, "BV1delete001")
        assert result is None

    @pytest.mark.asyncio
    async def test_list_by_user(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试列出用户音频元数据"""
        service = AudioService(db_session)

        # 创建多个
        for i in range(3):
            await service.create_or_update(test_user.id, AudioMetadataCreate(
                bvid=f"BV1list{i:03d}",
                title=f"列表测试{i}"
            ))

        # 列出
        items = await service.list_by_user(test_user.id)

        assert len(items) == 3

    @pytest.mark.asyncio
    async def test_list_by_status(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试按状态筛选"""
        service = AudioService(db_session)

        # 创建不同状态
        await service.create_or_update(test_user.id, AudioMetadataCreate(
            bvid="BV1pending001",
            title="待下载"
        ))
        await service.create_or_update(test_user.id, AudioMetadataCreate(
            bvid="BV1completed001",
            title="已完成"
        ))
        await service.update_metadata(
            test_user.id,
            "BV1completed001",
            AudioMetadataUpdate(download_status="completed")
        )

        # 筛选已完成
        items = await service.list_by_user(test_user.id, status="completed")
        assert len(items) == 1
        assert items[0].bvid == "BV1completed001"


class TestSearchService:
    """本地搜索服务测试"""

    @pytest.mark.asyncio
    async def test_local_search_by_title(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试按标题搜索"""
        # 添加音频元数据
        audio_service = AudioService(db_session)
        await audio_service.create_or_update(test_user.id, AudioMetadataCreate(
            bvid="BV1search001",
            title="搜索测试歌曲",
            artist="歌手A"
        ))

        # 搜索
        search_service = SearchService(db_session)
        results = await search_service.local_search(test_user.id, "搜索测试")

        assert len(results) == 1
        assert results[0].bvid == "BV1search001"
        assert results[0].match_type == "title"

    @pytest.mark.asyncio
    async def test_local_search_by_artist(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试按艺术家搜索"""
        audio_service = AudioService(db_session)
        await audio_service.create_or_update(test_user.id, AudioMetadataCreate(
            bvid="BV1artist001",
            title="歌曲标题",
            artist="测试艺术家"
        ))

        search_service = SearchService(db_session)
        results = await search_service.local_search(test_user.id, "测试艺术")

        assert len(results) == 1
        assert results[0].match_type == "artist"

    @pytest.mark.asyncio
    async def test_local_search_by_bvid(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试按 BV 号搜索"""
        audio_service = AudioService(db_session)
        await audio_service.create_or_update(test_user.id, AudioMetadataCreate(
            bvid="BV1bvidtest01",
            title="BV号测试"
        ))

        search_service = SearchService(db_session)
        results = await search_service.local_search(test_user.id, "BV1bvidtest")

        assert len(results) == 1
        assert results[0].match_type == "bvid"

    @pytest.mark.asyncio
    async def test_local_search_no_results(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试无结果搜索"""
        search_service = SearchService(db_session)
        results = await search_service.local_search(test_user.id, "不存在的内容")
        assert len(results) == 0

    @pytest.mark.asyncio
    async def test_get_suggestions(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试获取搜索建议"""
        audio_service = AudioService(db_session)
        await audio_service.create_or_update(test_user.id, AudioMetadataCreate(
            bvid="BV1suggest001",
            title="建议测试标题",
            artist="建议测试歌手"
        ))

        search_service = SearchService(db_session)
        suggestions = await search_service.get_suggestions(test_user.id, "建议测试")

        assert len(suggestions) > 0

    @pytest.mark.asyncio
    async def test_search_history(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试搜索历史"""
        search_service = SearchService(db_session)

        # 添加历史
        await search_service.add_search_history(test_user.id, SearchHistoryCreate(keyword="测试关键词1"))
        await search_service.add_search_history(test_user.id, SearchHistoryCreate(keyword="测试关键词2"))

        # 获取历史
        history = await search_service.get_search_history(test_user.id)

        assert len(history) == 2
        assert history[0].keyword == "测试关键词2"  # 最新在前

    @pytest.mark.asyncio
    async def test_clear_search_history(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试清空搜索历史"""
        search_service = SearchService(db_session)

        # 添加历史
        await search_service.add_search_history(test_user.id, SearchHistoryCreate(keyword="关键词"))

        # 清空
        count = await search_service.clear_search_history(test_user.id)

        assert count >= 1

        # 验证已清空
        history = await search_service.get_search_history(test_user.id)
        assert len(history) == 0

    @pytest.mark.asyncio
    async def test_delete_single_search_history(
        self,
        db_session: AsyncSession,
        test_user: User
    ):
        """测试删除单条搜索历史"""
        search_service = SearchService(db_session)

        # 添加历史
        await search_service.add_search_history(test_user.id, SearchHistoryCreate(keyword="关键词"))

        # 获取历史
        history = await search_service.get_search_history(test_user.id)
        assert len(history) == 1

        # 删除
        deleted = await search_service.delete_search_history(test_user.id, history[0].id)
        assert deleted is True

        # 验证已删除
        history = await search_service.get_search_history(test_user.id)
        assert len(history) == 0