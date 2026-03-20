"""推荐功能路由"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.recommendation_service import RecommendationService
from app.schemas.common import ApiResponse
from app.schemas.recommendation import (
    HotPlaylistsResponse, RecommendationsResponse, CategoriesResponse
)
from app.api.deps import get_db, get_current_user
from app.models import User

router = APIRouter(prefix="/recommendations", tags=["推荐"])


@router.get("/hot-playlists", response_model=ApiResponse[HotPlaylistsResponse])
async def get_hot_playlists(limit: int = Query(default=10, ge=1, le=50)):
    """获取热门歌单"""
    playlists = await RecommendationService.get_hot_playlists(limit)
    return ApiResponse(
        success=True,
        data=HotPlaylistsResponse(items=playlists, total=len(playlists))
    )


@router.get("/rank", response_model=ApiResponse[RecommendationsResponse])
async def get_rank(
    rank_type: str = Query(default="music", description="榜单类型: music/hot/all/dance/game 等")
):
    """获取榜单"""
    items = await RecommendationService.get_rank(rank_type)
    return ApiResponse(
        success=True,
        data=RecommendationsResponse(items=items, total=len(items))
    )


@router.get("/categories", response_model=ApiResponse[CategoriesResponse])
async def get_categories():
    """获取分区列表"""
    categories = RecommendationService.get_categories()
    return ApiResponse(
        success=True,
        data=CategoriesResponse(items=categories, total=len(categories))
    )


@router.get("/personalized", response_model=ApiResponse[RecommendationsResponse])
async def get_personalized(
    limit: int = Query(default=10, ge=1, le=50),
    current_user: User = Depends(get_current_user)
):
    """获取个性化推荐（需要登录）"""
    items = await RecommendationService.get_personalized(limit)
    return ApiResponse(
        success=True,
        data=RecommendationsResponse(items=items, total=len(items))
    )


@router.get("/category/{tid}/top", response_model=ApiResponse[RecommendationsResponse])
async def get_category_top(tid: int):
    """获取分区排行榜前十"""
    items = await RecommendationService.get_category_top10(tid)
    return ApiResponse(
        success=True,
        data=RecommendationsResponse(items=items, total=len(items))
    )


@router.get("/category/{tid}/new", response_model=ApiResponse[RecommendationsResponse])
async def get_category_new_videos(
    tid: int,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=50)
):
    """获取分区最新视频"""
    items = await RecommendationService.get_category_new_videos(tid, page, page_size)
    return ApiResponse(
        success=True,
        data=RecommendationsResponse(items=items, total=len(items))
    )


@router.get("/music", response_model=ApiResponse[RecommendationsResponse])
async def get_music_rank():
    """获取音乐榜"""
    items = await RecommendationService.get_music_rank()
    return ApiResponse(
        success=True,
        data=RecommendationsResponse(items=items, total=len(items))
    )


@router.get("/music/weekly", response_model=ApiResponse[RecommendationsResponse])
async def get_music_weekly():
    """获取音乐周榜"""
    items = await RecommendationService.get_music_weekly()
    return ApiResponse(
        success=True,
        data=RecommendationsResponse(items=items, total=len(items))
    )