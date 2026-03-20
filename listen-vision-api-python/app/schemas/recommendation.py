"""推荐相关 Schema"""
from pydantic import BaseModel
from typing import List, Optional


class HotPlaylist(BaseModel):
    """热门歌单"""
    id: int
    name: str
    cover_url: Optional[str] = None
    play_count: int = 0
    description: Optional[str] = None


class RankItem(BaseModel):
    """榜单项"""
    bvid: str
    title: str
    cover_url: Optional[str] = None
    view_count: int = 0
    author: str


class CategoryInfo(BaseModel):
    """分区信息"""
    tid: int
    name: str
    parent_tid: Optional[int] = None


class RecommendationsResponse(BaseModel):
    """推荐响应"""
    items: List[RankItem]
    total: int


class HotPlaylistsResponse(BaseModel):
    """热门歌单响应"""
    items: List[HotPlaylist]


class CategoriesResponse(BaseModel):
    """分区列表响应"""
    items: List[CategoryInfo]