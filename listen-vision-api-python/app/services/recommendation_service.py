"""推荐服务"""
from typing import List, Optional
from bilibili_api import rank, homepage, video_zone
from bilibili_api.exceptions import ResponseCodeException

from app.schemas.recommendation import HotPlaylist, RankItem, CategoryInfo
from app.utils.logger import logger
from app.utils.cache import cached


class RecommendationService:
    """推荐服务"""

    @staticmethod
    @cached(ttl=300)
    async def get_hot_playlists(limit: int = 10) -> List[HotPlaylist]:
        """获取热门歌单（基于首页推荐视频）"""
        try:
            result = await homepage.get_videos()
            items = result.get("item", [])[:limit]

            playlists = []
            for i, item in enumerate(items):
                # 从推荐视频构建热门歌单
                title = item.get("title", "热门推荐")
                # 移除 HTML 标签
                if isinstance(title, str):
                    title = title.replace("<em class=\"keyword\">", "").replace("</em>", "")

                playlists.append(HotPlaylist(
                    id=i + 1,
                    name=title,
                    cover_url=item.get("pic"),
                    play_count=item.get("play", 0) or item.get("stat", {}).get("view", 0),
                    description=item.get("desc", "")
                ))
            return playlists
        except ResponseCodeException as e:
            logger.error(f"获取热门歌单失败: {e.code} - {e.msg}")
            return []
        except Exception as e:
            logger.error(f"获取热门歌单失败: {e}")
            return []

    @staticmethod
    @cached(ttl=300)
    async def get_rank(rank_type: str = "music") -> List[RankItem]:
        """获取榜单

        Args:
            rank_type: 榜单类型，支持 music/hot/all
        """
        try:
            type_map = {
                "music": rank.RankType.Music,
                "hot": rank.RankType.Original,
                "all": rank.RankType.All,
                "dance": rank.RankType.Dance,
                "game": rank.RankType.Game,
                "knowledge": rank.RankType.Knowledge,
                "technology": rank.RankType.Technology,
                "life": rank.RankType.Life,
                "food": rank.RankType.Food,
                "animal": rank.RankType.Animal,
                "ent": rank.RankType.Ent,
            }

            rank_type_enum = type_map.get(rank_type, rank.RankType.Music)
            result = await rank.get_rank(type_=rank_type_enum)

            items = []
            for item in result.get("list", [])[:20]:
                items.append(RankItem(
                    bvid=item.get("bvid", ""),
                    title=item.get("title", ""),
                    cover_url=item.get("pic"),
                    view_count=item.get("play", 0) or item.get("stat", {}).get("view", 0),
                    author=item.get("owner", {}).get("name", "") or item.get("author", "")
                ))
            return items
        except ResponseCodeException as e:
            logger.error(f"获取榜单失败: {e.code} - {e.msg}")
            return []
        except Exception as e:
            logger.error(f"获取榜单失败: {e}")
            return []

    @staticmethod
    def get_categories() -> List[CategoryInfo]:
        """获取分区列表"""
        try:
            zones = video_zone.get_zone_list()
            categories = []

            for zone in zones:
                # 只返回主分区
                if "father" not in zone:
                    tid = zone.get("tid")
                    if tid is not None:
                        categories.append(CategoryInfo(
                            tid=tid,
                            name=zone.get("name", ""),
                            parent_tid=None
                        ))

            return categories
        except Exception as e:
            logger.error(f"获取分区列表失败: {e}")
            # 返回默认分区列表
            return [
                CategoryInfo(tid=1, name="首页"),
                CategoryInfo(tid=13, name="番剧"),
                CategoryInfo(tid=167, name="国创"),
                CategoryInfo(tid=3, name="音乐"),
                CategoryInfo(tid=129, name="舞蹈"),
                CategoryInfo(tid=4, name="游戏"),
                CategoryInfo(tid=36, name="科技"),
                CategoryInfo(tid=188, name="数码"),
                CategoryInfo(tid=234, name="汽车"),
                CategoryInfo(tid=223, name="美食"),
                CategoryInfo(tid=160, name="生活"),
                CategoryInfo(tid=211, name="动物圈"),
                CategoryInfo(tid=119, name="时尚"),
                CategoryInfo(tid=155, name="娱乐"),
                CategoryInfo(tid=202, name="影视"),
            ]

    @staticmethod
    @cached(ttl=300)
    async def get_personalized(limit: int = 10) -> List[RankItem]:
        """获取个性化推荐（基于首页推荐）"""
        try:
            result = await homepage.get_videos()
            items = result.get("item", [])[:limit]

            recommendations = []
            for item in items:
                title = item.get("title", "")
                # 移除 HTML 标签
                if isinstance(title, str):
                    title = title.replace("<em class=\"keyword\">", "").replace("</em>", "")

                recommendations.append(RankItem(
                    bvid=item.get("bvid", ""),
                    title=title,
                    cover_url=item.get("pic"),
                    view_count=item.get("play", 0) or item.get("stat", {}).get("view", 0),
                    author=item.get("owner", {}).get("name", "")
                ))
            return recommendations
        except ResponseCodeException as e:
            logger.error(f"获取个性化推荐失败: {e.code} - {e.msg}")
            return []
        except Exception as e:
            logger.error(f"获取个性化推荐失败: {e}")
            return []

    @staticmethod
    @cached(ttl=300)
    async def get_category_top10(tid: int) -> List[RankItem]:
        """获取分区排行榜前十"""
        try:
            result = await video_zone.get_zone_top10(tid, day=7)

            items = []
            for item in result.get("list", [])[:10]:
                items.append(RankItem(
                    bvid=item.get("bvid", ""),
                    title=item.get("title", ""),
                    cover_url=item.get("pic"),
                    view_count=item.get("play", 0) or item.get("stat", {}).get("view", 0),
                    author=item.get("owner", {}).get("name", "") or item.get("author", "")
                ))
            return items
        except ResponseCodeException as e:
            logger.error(f"获取分区排行榜失败: {e.code} - {e.msg}")
            return []
        except Exception as e:
            logger.error(f"获取分区排行榜失败: {e}")
            return []

    @staticmethod
    @cached(ttl=300)
    async def get_category_new_videos(tid: int, page: int = 1, page_size: int = 20) -> List[RankItem]:
        """获取分区最新视频"""
        try:
            result = await video_zone.get_zone_new_videos(tid, page, page_size)

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
        except ResponseCodeException as e:
            logger.error(f"获取分区最新视频失败: {e.code} - {e.msg}")
            return []
        except Exception as e:
            logger.error(f"获取分区最新视频失败: {e}")
            return []

    @staticmethod
    @cached(ttl=300)
    async def get_music_rank() -> List[RankItem]:
        """获取音乐榜"""
        return await RecommendationService.get_rank("music")

    @staticmethod
    @cached(ttl=300)
    async def get_music_weekly() -> List[RankItem]:
        """获取音乐周榜"""
        try:
            result = await rank.get_music_rank_weekly_musics(week=1)
            items = []

            for item in result.get("data", {}).get("list", [])[:20]:
                items.append(RankItem(
                    bvid="",  # 音乐榜可能没有 bvid
                    title=item.get("title", ""),
                    cover_url=item.get("cover"),
                    view_count=item.get("play_count", 0),
                    author=item.get("author", "") or item.get("uname", "")
                ))
            return items
        except Exception as e:
            logger.error(f"获取音乐周榜失败: {e}")
            return []