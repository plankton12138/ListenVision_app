"""播放历史路由"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.services.history_service import HistoryService
from app.schemas.history import (
    PlayHistoryCreate,
    PlayHistoryResponse,
    PlayHistoryListResponse
)
from app.schemas.common import ApiResponse
from app.models import User

router = APIRouter(prefix="/history", tags=["播放历史"])


@router.get("", response_model=ApiResponse[PlayHistoryListResponse])
async def get_history(
    page: int = 1,
    page_size: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """获取播放历史列表

    按最后播放时间倒序排列
    """
    service = HistoryService(db)
    result = await service.get_history(current_user.id, page, page_size)
    return ApiResponse(success=True, data=result)


@router.post("", response_model=ApiResponse[PlayHistoryResponse])
async def add_history(
    data: PlayHistoryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """添加播放历史

    如果已存在相同歌曲，则更新播放次数和时间
    """
    service = HistoryService(db)
    item = await service.add_history(current_user.id, data)
    return ApiResponse(success=True, data=item)


@router.delete("/{history_id}", response_model=ApiResponse)
async def delete_history(
    history_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """删除单条播放历史"""
    service = HistoryService(db)
    await service.delete_history(current_user.id, history_id)
    return ApiResponse(success=True, message="删除成功")


@router.delete("", response_model=ApiResponse)
async def clear_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """清空播放历史"""
    service = HistoryService(db)
    count = await service.clear_history(current_user.id)
    return ApiResponse(success=True, message=f"已清空 {count} 条记录")