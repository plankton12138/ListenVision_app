"""音频元数据路由"""
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.services.audio_service import AudioService
from app.schemas.audio import (
    AudioMetadataCreate,
    AudioMetadataUpdate,
    AudioMetadataResponse
)
from app.schemas.common import ApiResponse
from app.models import User

router = APIRouter(prefix="/audio", tags=["音频元数据"])


@router.get("/metadata/{bvid}", response_model=ApiResponse[AudioMetadataResponse])
async def get_metadata(
    bvid: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """获取音频元数据"""
    service = AudioService(db)
    metadata = await service.get_metadata(current_user.id, bvid)
    if not metadata:
        return ApiResponse(success=False, message="未找到元数据")
    return ApiResponse(success=True, data=metadata)


@router.post("/metadata", response_model=ApiResponse[AudioMetadataResponse])
async def create_metadata(
    data: AudioMetadataCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """创建或更新音频元数据"""
    service = AudioService(db)
    metadata = await service.create_or_update(current_user.id, data)
    return ApiResponse(success=True, data=metadata, message="保存成功")


@router.patch("/metadata/{bvid}", response_model=ApiResponse[AudioMetadataResponse])
async def update_metadata(
    bvid: str,
    data: AudioMetadataUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """更新音频元数据"""
    service = AudioService(db)
    metadata = await service.update_metadata(current_user.id, bvid, data)
    if not metadata:
        return ApiResponse(success=False, message="未找到元数据")
    return ApiResponse(success=True, data=metadata, message="更新成功")


@router.delete("/metadata/{bvid}")
async def delete_metadata(
    bvid: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """删除音频元数据"""
    service = AudioService(db)
    await service.delete_metadata(current_user.id, bvid)
    return ApiResponse(success=True, message="删除成功")


@router.get("/metadata", response_model=ApiResponse[list[AudioMetadataResponse]])
async def list_metadata(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query(None, description="下载状态筛选"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """列出音频元数据"""
    service = AudioService(db)
    items = await service.list_by_user(current_user.id, status, page, page_size)
    return ApiResponse(success=True, data=items)