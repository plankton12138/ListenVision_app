from typing import Optional, List, Tuple
import httpx
from bilibili_api import video, user, search, Credential
from bilibili_api.exceptions import ResponseCodeException, ArgsException

from app.utils.logger import logger
from app.utils.cache import cached
from app.utils.bilibili import BILIBILI_HEADERS, normalize_bilibili_url
from app.schemas.bilibili import (
    VideoInfo, VideoOwner, VideoStat,
    AudioStreamsResponse, AudioStream,
    SubtitleResponse, SubtitleInfo, SubtitleLine,
    SearchResponse, SearchResultItem
)


def _parse_duration(duration_str: str) -> int:
    """
    将 B站 duration 字符串转换为秒数

    Args:
        duration_str: 时长字符串，格式可能是 '分:秒' 或 '时:分:秒'

    Returns:
        总秒数

    Examples:
        '4:2' -> 242
        '37:42' -> 2262
        '1:30:45' -> 5445
    """
    try:
        parts = duration_str.split(':')
        if len(parts) == 2:
            # 分:秒 格式
            return int(parts[0]) * 60 + int(parts[1])
        elif len(parts) == 3:
            # 时:分:秒 格式
            return int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
        else:
            logger.warning(f"无法解析的 duration 格式: {duration_str}")
            return 0
    except (ValueError, AttributeError) as e:
        logger.error(f"解析 duration 失败: {duration_str}, 错误: {e}")
        return 0


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

            # 处理图片 URL（B站返回的可能缺少协议头）
            pic_url = normalize_bilibili_url(info["pic"])
            face_url = normalize_bilibili_url(info["owner"].get("face", ""))

            owner = VideoOwner(
                mid=info["owner"]["mid"],
                name=info["owner"]["name"],
                face=face_url
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
                pic=pic_url,
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

            # 获取分P列表，找到目标 cid 对应的 page_index
            pages = info.get("pages", [])
            page_index = 0  # 默认第一P

            if pages:
                for idx, page in enumerate(pages):
                    if page.get("cid") == cid:
                        page_index = idx
                        break

            # 获取音频流URL（使用 page_index 而非 cid）
            audio_url = await v.get_download_url(page_index)

            streams = []
            if "dash" in audio_url and "audio" in audio_url["dash"]:
                for audio in audio_url["dash"]["audio"]:
                    # baseUrl 和 base_url 都可能存在
                    audio_url_str = audio.get("baseUrl") or audio.get("base_url", "")
                    streams.append(AudioStream(
                        quality=audio.get("id", 0),
                        url=audio_url_str,
                        size=audio.get("size", 0),  # B站API可能不返回size
                        codecs=audio.get("codecs", "")
                    ))

            return AudioStreamsResponse(
                bvid=bvid,
                cid=cid,
                title=info["title"],
                streams=streams
            )
        except ArgsException as e:
            logger.error(f"视频分P错误 [{bvid}]: {e}")
            raise ValueError(f"视频 {bvid} 不存在或分P信息有误") from e
        except ResponseCodeException as e:
            logger.error(f"获取音频流失败 [{bvid}]: {e.code} - {e.msg}")
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

                async with httpx.AsyncClient() as client:
                    resp = await client.get(sub_url, headers=BILIBILI_HEADERS)
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

            videos = []
            for item in result.get("result", []):
                # 跳过非视频类型（如 ketang）
                if item.get("type") != "video":
                    continue
                # 跳过没有 bvid 的结果
                if not item.get("bvid"):
                    continue

                # 处理封面 URL（B站返回的 pic 可能缺少协议头）
                cover_url = normalize_bilibili_url(item.get("pic", ""))

                videos.append(SearchResultItem(
                    bvid=item["bvid"],
                    title=item["title"].replace("<em class=\"keyword\">", "").replace("</em>", ""),
                    author=item.get("author", ""),
                    cover=cover_url,
                    duration=_parse_duration(item.get("duration", "")),
                    description=item.get("description", ""),
                    view_count=item.get("play", 0),
                    pubdate=item.get("pubdate", 0)
                ))

            return SearchResponse(
                videos=videos,
                total=result.get("numResults", 0),
                page=page,
                pageSize=page_size
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
        # 处理无协议头的 URL（B站常见格式：//i2.hdslb.com/...）
        url = normalize_bilibili_url(url)

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url, headers=BILIBILI_HEADERS, follow_redirects=True)
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

        headers = BILIBILI_HEADERS.copy()
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
            # 使用 bilibili_api 的 get_suggest_keywords 方法
            result = await search.get_suggest_keywords(keyword)
            return result if result else []
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