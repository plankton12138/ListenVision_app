"""搜索相关 Schema"""
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


class SearchHistoryCreate(BaseModel):
    """创建搜索历史请求"""
    keyword: str


class SearchHistoryResponse(BaseModel):
    """搜索历史响应"""
    id: int
    keyword: str
    searched_at: datetime

    class Config:
        from_attributes = True


class LocalSearchResult(BaseModel):
    """本地搜索结果"""
    bvid: str
    title: str
    artist: Optional[str] = None
    cover_url: Optional[str] = None
    duration: int = 0
    match_type: str  # title, artist, bvid


class SearchSuggestion(BaseModel):
    """搜索建议"""
    text: str
    type: str  # title, artist