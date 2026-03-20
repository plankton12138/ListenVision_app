"""播放历史 Schema"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel


class PlayHistoryCreate(BaseModel):
    """创建播放历史请求"""
    bvid: str
    title: Optional[str] = None
    artist: Optional[str] = None
    cover_url: Optional[str] = None
    duration: int = 0
    progress: int = 0


class PlayHistoryUpdate(BaseModel):
    """更新播放历史请求"""
    progress: Optional[int] = None


class PlayHistoryResponse(BaseModel):
    """播放历史响应"""
    id: int
    bvid: str
    title: Optional[str] = None
    artist: Optional[str] = None
    cover_url: Optional[str] = None
    duration: int = 0
    progress: int = 0
    play_count: int = 1
    last_played_at: datetime

    class Config:
        from_attributes = True


class PlayHistoryListResponse(BaseModel):
    """播放历史列表响应"""
    items: List[PlayHistoryResponse]
    total: int
    page: int
    page_size: int