from typing import Optional, List, Tuple
import httpx
from bilibili_api import video, user, search, Credential
from bilibili_api.exceptions import ResponseCodeException

from app.utils.logger import logger
from app.utils.cache import cached
from app.schemas.bilibili import (
    VideoInfo, VideoOwner, VideoStat,
    AudioStreamsResponse, AudioStream,
    SubtitleResponse, SubtitleInfo, SubtitleLine,
    SearchResponse, SearchResultItem
)


# 搜索历史缓存（生产环境应使用 Redis）
_search_history: dict[int, list[str]] = {}


class BilibiliService:
    """B站服务"""

    @staticmethod
    @cached(ttl=300)
    async def get_video_info(bvid: str) -> VideoInfo:
        """获取视频信息"""
        try:
            v = video.Video(bvid=bvid)
            info = await v.get_info()

            owner = VideoOwner(
                mid=info["owner"]["mid"],
                name=info["owner"]["name"],
                face=info["owner"].get("face")
            )

            stat = VideoStat(
                view=info["stat"]["view"],
                like=info["stat"]["like"],
                coin=info["stat"]["coin"],
                favorite=info["stat"]["favorite"],
                share=info["stat"]["share"],
                reply=info["stat"]["reply"],
                danmaku=info["stat"]["danmaku"]
            )

            return VideoInfo(
                bvid=info["bvid"],
                aid=info["aid"],
                cid=info["cid"],
                title=info["title"],
                desc=info["desc"],
                owner=owner,
                duration=info["duration"],
                pic=info["pic"],
                pubdate=info["pubdate"],
                stat=stat
            )
        except ResponseCodeException as e:
            logger.error(f"B站API错误: {e.code} - {e.msg}")
            raise

    @staticmethod
    async def get_audio_streams(bvid: str, credential=None) -> AudioStreamsResponse:
        """获取音频流"""
        try:
            v = video.Video(bvid=bvid, credential=credential)
            info = await v.get_info()
            cid = info["cid"]

            # 获取音频流URL
            audio_url = await v.get_download_url(cid)

            streams = []
            if "dash" in audio_url and "audio" in audio_url["dash"]:
                for audio in audio_url["dash"]["audio"]:
                    streams.append(AudioStream(
                        quality=audio["id"],
                        url=audio["baseUrl"],
                        size=audio["size"],
                        codecs=audio["codecs"]
                    ))

            return AudioStreamsResponse(
                bvid=bvid,
                cid=cid,
                title=info["title"],
                streams=streams
            )
        except ResponseCodeException as e:
            logger.error(f"获取音频流失败: {e.code} - {e.msg}")
            raise

    @staticmethod
    async def get_subtitles(bvid: str, credential=None) -> SubtitleResponse:
        """获取字幕"""
        try:
            v = video.Video(bvid=bvid, credential=credential)
            info = await v.get_info()
            cid = info["cid"]

            # 获取字幕列表
            subtitle_info = await v.get_subtitle(cid)

            subtitles = []
            for sub in subtitle_info.get("subtitles", []):
                # 获取字幕内容
                sub_url = sub["subtitle_url"]
                if sub_url.startswith("//"):
                    sub_url = f"https:{sub_url}"

                import httpx
                async with httpx.AsyncClient() as client:
                    resp = await client.get(sub_url)
                    sub_data = resp.json()

                lines = [
                    SubtitleLine(
                        from_time=line["from"],
                        to_time=line["to"],
                        content=line["content"]
                    )
                    for line in sub_data.get("body", [])
                ]

                subtitles.append(SubtitleInfo(
                    lan=sub["lan"],
                    lan_doc=sub["lan_doc"],
                    lines=lines
                ))

            return SubtitleResponse(
                bvid=bvid,
                cid=cid,
                subtitles=subtitles
            )
        except ResponseCodeException as e:
            logger.error(f"获取字幕失败: {e.code} - {e.msg}")
            raise

    @staticmethod
    @cached(ttl=60)
    async def search_videos(
        keyword: str,
        page: int = 1,
        page_size: int = 20
    ) -> SearchResponse:
        """搜索视频"""
        try:
            result = await search.search_by_type(
                keyword,
                search_type=search.SearchObjectType.VIDEO,
                page=page,
                page_size=page_size
            )

            items = []
            for item in result.get("result", []):
                owner = VideoOwner(
                    mid=item["mid"],
                    name=item["author"],
                    face=None
                )
                items.append(SearchResultItem(
                    bvid=item["bvid"],
                    title=item["title"].replace("<em class=\"keyword\">", "").replace("</em>", ""),
                    description=item.get("description", ""),
                    owner=owner,
                    duration=item["duration"],
                    cover_url=item["pic"],
                    view_count=item["play"],
                    pubdate=item["pubdate"]
                ))

            return SearchResponse(
                items=items,
                total=result.get("numResults", 0),
                page=page,
                page_size=page_size
            )
        except ResponseCodeException as e:
            logger.error(f"搜索失败: {e.code} - {e.msg}")
            raise

    @staticmethod
    @cached(ttl=300)
    async def get_recommendations(page: int = 1) -> List[dict]:
        """获取推荐视频"""
        try:
            result = await video.get_recommendvideos()
            return result.get("item", [])
        except ResponseCodeException as e:
            logger.error(f"获取推荐失败: {e.code} - {e.msg}")
            raise

    # ==================== 代理功能 ====================

    @staticmethod
    async def proxy_image(url: str) -> Tuple[bytes, str]:
        """
        代理图片，返回 (图片数据, content_type)

        Args:
            url: 图片URL

        Returns:
            元组 (图片二进制数据, content_type)
        """
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url, follow_redirects=True)
            response.raise_for_status()
            content_type = response.headers.get("content-type", "image/jpeg")
            return response.content, content_type

    @staticmethod
    async def proxy_audio_stream(
        bvid: str,
        credential: Optional[Credential] = None,
        range_header: Optional[str] = None
    ) -> Tuple[bytes, str, int, int]:
        """
        代理音频流，返回 (数据, content_type, 总大小, 当前位置)

        Args:
            bvid: 视频BV号
            credential: B站认证凭证（可选）
            range_header: Range请求头（可选）

        Returns:
            元组 (音频数据, content_type, 总大小, 起始位置)
        """
        streams = await BilibiliService.get_audio_streams(bvid, credential)
        if not streams.streams:
            raise ValueError("无可用音频流")

        # 选择最高质量
        stream = streams.streams[0]
        url = stream.url

        headers = {}
        if range_header:
            headers["Range"] = range_header

        async with httpx.AsyncClient(timeout=60.0) as client:
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
                    range_parts = parts[0].replace("bytes ", "").split("-")
                    if len(range_parts) >= 1:
                        start = int(range_parts[0])

            return response.content, content_type, total_size, start

    # ==================== UP主功能 ====================

    @staticmethod
    @cached(ttl=300)
    async def get_uploader_info(mid: int) -> dict:
        """
        获取UP主信息

        Args:
            mid: UP主ID

        Returns:
            UP主信息字典
        """
        try:
            u = user.User(uid=mid)
            info = await u.get_user_info()
            return {
                "mid": info.get("mid", mid),
                "name": info.get("name", ""),
                "face": info.get("face", ""),
                "sign": info.get("sign", ""),
                "level": info.get("level", 0),
                "fans": info.get("follower", 0),
                "videos": info.get("video_count", 0)
            }
        except ResponseCodeException as e:
            logger.error(f"获取UP主信息失败: {e.code} - {e.msg}")
            raise

    # ==================== 搜索功能 ====================

    @staticmethod
    @cached(ttl=60)
    async def get_search_suggestions(keyword: str) -> List[str]:
        """
        获取搜索建议

        Args:
            keyword: 搜索关键词

        Returns:
            搜索建议列表
        """
        try:
            result = await search.get_suggestions(keyword)
            return [item["value"] for item in result.get("tag", [])]
        except Exception as e:
            logger.error(f"获取搜索建议失败: {e}")
            return []

    @staticmethod
    async def get_search_history(user_id: int, limit: int = 10) -> List[str]:
        """
        获取搜索历史

        Args:
            user_id: 用户ID
            limit: 返回数量限制

        Returns:
            搜索历史列表
        """
        return _search_history.get(user_id, [])[:limit]

    @staticmethod
    async def add_search_history(user_id: int, keyword: str) -> None:
        """
        添加搜索历史

        Args:
            user_id: 用户ID
            keyword: 搜索关键词
        """
        if user_id not in _search_history:
            _search_history[user_id] = []
        history = _search_history[user_id]
        # 去重：移除已存在的相同关键词
        if keyword in history:
            history.remove(keyword)
        # 添加到开头
        history.insert(0, keyword)
        # 限制数量为50条
        _search_history[user_id] = history[:50]

    # ==================== Cookie 刷新 ====================

    @staticmethod
    async def refresh_cookie(credential: Credential) -> dict:
        """
        刷新 B站 Cookie

        Args:
            credential: 当前的认证凭证

        Returns:
            新的凭证信息字典
        """
        try:
            # 使用 Credential 的 refresh 方法刷新
            await credential.refresh()
            return {
                "sessdata": credential.sessdata,
                "bili_jct": credential.bili_jct,
                "dedeuserid": credential.dedeuserid
            }
        except Exception as e:
            logger.error(f"刷新 Cookie 失败: {e}")
            raise