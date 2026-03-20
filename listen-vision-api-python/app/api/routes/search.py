"""本地搜索路由"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.services.search_service import SearchService
from app.schemas.search import (
    SearchHistoryCreate,
    SearchHistoryResponse,
    LocalSearchResult
)
from app.schemas.common import ApiResponse
from app.models import User

router = APIRouter(prefix="/search", tags=["本地搜索"])


@router.get("/local", response_model=ApiResponse[list[LocalSearchResult]])
async def local_search(
    keyword: str = Query(..., min_length=1, description="搜索关键词"),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """本地全文搜索

    在用户下载的音频元数据中搜索，支持标题、艺术家、BV号匹配。
    """
    service = SearchService(db)
    results = await service.local_search(current_user.id, keyword, limit)
    return ApiResponse(success=True, data=results)


@router.get("/suggestions")
async def get_suggestions(
    prefix: str = Query(..., min_length=1, description="搜索前缀"),
    limit: int = Query(10, ge=1, le=20),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """获取搜索建议

    根据用户音频库中的标题和艺术家提供建议。
    """
    service = SearchService(db)
    suggestions = await service.get_suggestions(current_user.id, prefix, limit)
    return ApiResponse(success=True, data={"suggestions": suggestions})


@router.get("/history", response_model=ApiResponse[list[SearchHistoryResponse]])
async def get_search_history(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """获取搜索历史"""
    service = SearchService(db)
    items = await service.get_search_history(current_user.id, limit)
    return ApiResponse(success=True, data=items)


@router.post("/history")
async def add_search_history(
    data: SearchHistoryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """添加搜索历史"""
    service = SearchService(db)
    await service.add_search_history(current_user.id, data)
    return ApiResponse(success=True, message="添加成功")


@router.delete("/history/{history_id}")
async def delete_search_history(
    history_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """删除单条搜索历史"""
    service = SearchService(db)
    deleted = await service.delete_search_history(current_user.id, history_id)
    if not deleted:
        return ApiResponse(success=False, message="记录不存在")
    return ApiResponse(success=True, message="删除成功")


@router.delete("/history")
async def clear_search_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """清空搜索历史"""
    service = SearchService(db)
    count = await service.clear_search_history(current_user.id)
    return ApiResponse(success=True, message=f"已清空 {count} 条记录")