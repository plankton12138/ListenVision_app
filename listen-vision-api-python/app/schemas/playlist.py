from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel


class PlaylistItem(BaseModel):
    """歌单项"""
    bvid: str
    title: str
    artist: Optional[str]
    cover_url: Optional[str]
    duration: int
    added_at: datetime


class PlaylistBase(BaseModel):
    """歌单基础"""
    name: str
    description: Optional[str] = None
    cover_url: Optional[str] = None
    is_public: bool = False


class PlaylistCreate(PlaylistBase):
    """创建歌单"""
    pass


class PlaylistUpdate(BaseModel):
    """更新歌单"""
    name: Optional[str] = None
    description: Optional[str] = None
    cover_url: Optional[str] = None
    is_public: Optional[bool] = None


class PlaylistResponse(PlaylistBase):
    """歌单响应"""
    id: int
    user_id: int
    is_default: bool
    created_at: datetime
    updated_at: datetime
    item_count: int = 0

    class Config:
        from_attributes = True


class PlaylistDetailResponse(PlaylistResponse):
    """歌单详情响应"""
    items: List[PlaylistItem]


class PlaylistItemAddRequest(BaseModel):
    """添加歌单项请求"""
    bvid: str
    title: str
    artist: Optional[str] = None
    cover_url: Optional[str] = None
    duration: int = 0


class PlaylistItemRemoveRequest(BaseModel):
    """移除歌单项请求"""
    bvid: str
