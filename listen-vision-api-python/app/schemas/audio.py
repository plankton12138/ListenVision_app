"""音频元数据 Schema"""
from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class AudioMetadataCreate(BaseModel):
    """创建音频元数据请求"""
    bvid: str
    title: Optional[str] = None
    artist: Optional[str] = None
    cover_url: Optional[str] = None
    duration: int = 0
    local_path: Optional[str] = None
    file_size: int = 0


class AudioMetadataUpdate(BaseModel):
    """更新音频元数据请求"""
    title: Optional[str] = None
    artist: Optional[str] = None
    cover_url: Optional[str] = None
    duration: Optional[int] = None
    local_path: Optional[str] = None
    file_size: Optional[int] = None
    play_progress: Optional[int] = None
    download_status: Optional[str] = None


class AudioMetadataResponse(BaseModel):
    """音频元数据响应"""
    id: int
    bvid: str
    title: Optional[str] = None
    artist: Optional[str] = None
    cover_url: Optional[str] = None
    duration: int = 0
    local_path: Optional[str] = None
    file_size: int = 0
    play_progress: int = 0
    download_status: str = "pending"
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True