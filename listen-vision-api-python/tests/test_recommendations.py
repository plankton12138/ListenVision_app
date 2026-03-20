"""推荐功能测试"""
import pytest

from app.services.recommendation_service import RecommendationService


class TestRecommendationService:
    """推荐服务测试"""

    @pytest.mark.asyncio
    async def test_get_hot_playlists(self):
        """测试获取热门歌单"""
        playlists = await RecommendationService.get_hot_playlists(limit=5)
        assert isinstance(playlists, list)
        assert len(playlists) <= 5

        # 检查返回的数据结构
        for playlist in playlists:
            assert hasattr(playlist, "id")
            assert hasattr(playlist, "name")
            assert isinstance(playlist.id, int)
            assert isinstance(playlist.name, str)

    @pytest.mark.asyncio
    async def test_get_rank_music(self):
        """测试获取音乐榜单"""
        items = await RecommendationService.get_rank("music")
        assert isinstance(items, list)

        # 检查返回的数据结构
        for item in items:
            assert hasattr(item, "bvid")
            assert hasattr(item, "title")
            assert hasattr(item, "author")

    @pytest.mark.asyncio
    async def test_get_rank_hot(self):
        """测试获取热门榜单"""
        items = await RecommendationService.get_rank("hot")
        assert isinstance(items, list)

    @pytest.mark.asyncio
    async def test_get_rank_all(self):
        """测试获取全站榜单"""
        items = await RecommendationService.get_rank("all")
        assert isinstance(items, list)

    def test_get_categories(self):
        """测试获取分区列表"""
        categories = RecommendationService.get_categories()
        assert isinstance(categories, list)
        assert len(categories) > 0

        # 检查返回的数据结构
        for category in categories:
            assert hasattr(category, "tid")
            assert hasattr(category, "name")
            assert isinstance(category.tid, int)
            assert isinstance(category.name, str)

    @pytest.mark.asyncio
    async def test_get_personalized(self):
        """测试获取个性化推荐"""
        items = await RecommendationService.get_personalized(limit=10)
        assert isinstance(items, list)
        assert len(items) <= 10

        # 检查返回的数据结构
        for item in items:
            assert hasattr(item, "bvid")
            assert hasattr(item, "title")

    @pytest.mark.asyncio
    async def test_get_category_top10(self):
        """测试获取分区排行榜前十"""
        # 音乐分区 tid = 3
        items = await RecommendationService.get_category_top10(3)
        assert isinstance(items, list)
        assert len(items) <= 10

    @pytest.mark.asyncio
    async def test_get_category_new_videos(self):
        """测试获取分区最新视频"""
        # 音乐分区 tid = 3
        items = await RecommendationService.get_category_new_videos(3, page=1, page_size=10)
        assert isinstance(items, list)
        assert len(items) <= 10

    @pytest.mark.asyncio
    async def test_get_music_rank(self):
        """测试获取音乐榜"""
        items = await RecommendationService.get_music_rank()
        assert isinstance(items, list)

    @pytest.mark.asyncio
    async def test_get_music_weekly(self):
        """测试获取音乐周榜"""
        items = await RecommendationService.get_music_weekly()
        assert isinstance(items, list)


class TestRecommendationServiceEdgeCases:
    """推荐服务边缘情况测试"""

    @pytest.mark.asyncio
    async def test_get_rank_invalid_type(self):
        """测试获取无效榜单类型"""
        # 无效类型应该返回空列表或默认榜单
        items = await RecommendationService.get_rank("invalid_type")
        assert isinstance(items, list)

    @pytest.mark.asyncio
    async def test_get_category_top10_invalid_tid(self):
        """测试获取无效分区ID的排行榜"""
        items = await RecommendationService.get_category_top10(999999)
        assert isinstance(items, list)
        # 无效分区应该返回空列表

    @pytest.mark.asyncio
    async def test_get_category_new_videos_invalid_tid(self):
        """测试获取无效分区ID的最新视频"""
        items = await RecommendationService.get_category_new_videos(999999, page=1, page_size=10)
        assert isinstance(items, list)
        # 无效分区应该返回空列表