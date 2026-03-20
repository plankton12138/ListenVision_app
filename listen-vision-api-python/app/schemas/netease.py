from typing import Optional, List
from pydantic import BaseModel


class SongInfo(BaseModel):
    """歌曲信息"""
    id: str
    name: str
    artists: List[str]
    album: str
    duration: int
    cover_url: Optional[str]


class PlaylistInfo(BaseModel):
    """歌单信息"""
    id: str
    name: str
    description: str
    cover_url: Optional[str]
    creator: str
    song_count: int
    songs: List[SongInfo]


class NeteaseSearchResponse(BaseModel):
    """网易云搜索响应"""
    songs: List[SongInfo]
    total: int
    page: int
    page_size: int


class NeteaseQRCodeResponse(BaseModel):
    """网易云QR码响应"""
    qrcode_key: str
    qr_url: str
    expires_in: int = 300


class NeteaseQRCodeCheckResponse(BaseModel):
    """网易云QR码检查响应"""
    status: str
    message: Optional[str] = None
