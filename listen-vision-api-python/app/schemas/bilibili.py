from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field


class VideoOwner(BaseModel):
    """视频作者"""
    mid: int
    name: str
    face: Optional[str] = None


class VideoStat(BaseModel):
    """视频统计数据"""
    view: int
    like: int
    coin: int
    favorite: int
    share: int
    reply: int
    danmaku: int


class VideoInfo(BaseModel):
    """视频信息"""
    bvid: str
    aid: int
    cid: int
    title: str
    desc: str
    owner: VideoOwner
    duration: int
    pic: str
    pubdate: datetime
    stat: VideoStat


class AudioStream(BaseModel):
    """音频流"""
    quality: int
    url: str
    size: int
    codecs: str


class AudioStreamsResponse(BaseModel):
    """音频流响应"""
    bvid: str
    cid: int
    title: str
    streams: List[AudioStream]


class SubtitleLine(BaseModel):
    """字幕行"""
    from_time: float = Field(..., alias="from")
    to_time: float = Field(..., alias="to")
    content: str

    class Config:
        populate_by_name = True


class SubtitleInfo(BaseModel):
    """字幕信息"""
    lan: str
    lan_doc: str
    lines: List[SubtitleLine]


class SubtitleResponse(BaseModel):
    """字幕响应"""
    bvid: str
    cid: int
    subtitles: List[SubtitleInfo]


class SearchResultItem(BaseModel):
    """搜索结果项"""
    bvid: str
    title: str
    description: str
    owner: VideoOwner
    duration: int
    cover_url: str
    view_count: int
    pubdate: datetime


class SearchResponse(BaseModel):
    """搜索响应"""
    items: List[SearchResultItem]
    total: int
    page: int
    page_size: int


class RecommendationItem(BaseModel):
    """推荐项"""
    bvid: str
    title: str
    owner: VideoOwner
    duration: int
    cover_url: str
    stat: VideoStat


class QRCodeResponse(BaseModel):
    """QR码响应"""
    qrcode_key: str
    qr_url: str
    expires_in: int = 300


class QRCodeCheckResponse(BaseModel):
    """QR码检查响应"""
    status: str  # pending, scanned, expired, success
    message: Optional[str] = None


class BilibiliStatusResponse(BaseModel):
    """B站绑定状态响应"""
    is_bound: bool
    username: Optional[str] = None
    avatar_url: Optional[str] = None
