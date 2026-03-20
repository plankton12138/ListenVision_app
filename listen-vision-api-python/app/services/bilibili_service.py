from typing import Optional, List
from bilibili_api import video, user, search
from bilibili_api.exceptions import ResponseCodeException

from app.utils.logger import logger
from app.utils.cache import cached
from app.schemas.bilibili import (
    VideoInfo, VideoOwner, VideoStat,
    AudioStreamsResponse, AudioStream,
    SubtitleResponse, SubtitleInfo, SubtitleLine,
    SearchResponse, SearchResultItem
)


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