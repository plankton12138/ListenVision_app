from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.api.deps import get_db, get_current_user
from app.services.playlist_service import PlaylistService
from app.schemas.playlist import (
    PlaylistCreate, PlaylistUpdate, PlaylistResponse,
    PlaylistDetailResponse, PlaylistItemAddRequest, PlaylistItemRemoveRequest
)
from app.schemas.common import ApiResponse
from app.models import User

router = APIRouter(prefix="/playlists", tags=["歌单"])


@router.post("", response_model=ApiResponse[PlaylistResponse])
async def create_playlist(
    data: PlaylistCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """创建歌单"""
    service = PlaylistService(db)
    playlist = await service.create_playlist(current_user.id, data)
    return ApiResponse(success=True, message="创建成功", data=playlist)


@router.get("", response_model=ApiResponse[List[PlaylistResponse]])
async def get_playlists(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """获取用户歌单列表"""
    service = PlaylistService(db)
    playlists = await service.get_user_playlists(current_user.id)
    return ApiResponse(success=True, data=playlists)


@router.get("/{playlist_id}", response_model=ApiResponse[PlaylistDetailResponse])
async def get_playlist(
    playlist_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """获取歌单详情"""
    service = PlaylistService(db)
    playlist = await service.get_playlist_detail(playlist_id, current_user.id)
    return ApiResponse(success=True, data=playlist)


@router.put("/{playlist_id}", response_model=ApiResponse[PlaylistResponse])
async def update_playlist(
    playlist_id: int,
    data: PlaylistUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """更新歌单"""
    service = PlaylistService(db)
    playlist = await service.update_playlist(playlist_id, current_user.id, data)
    return ApiResponse(success=True, message="更新成功", data=playlist)


@router.delete("/{playlist_id}", response_model=ApiResponse)
async def delete_playlist(
    playlist_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """删除歌单"""
    service = PlaylistService(db)
    await service.delete_playlist(playlist_id, current_user.id)
    return ApiResponse(success=True, message="删除成功")


@router.post("/{playlist_id}/items", response_model=ApiResponse)
async def add_playlist_item(
    playlist_id: int,
    data: PlaylistItemAddRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """添加歌单项"""
    service = PlaylistService(db)
    await service.add_item(playlist_id, current_user.id, data)
    return ApiResponse(success=True, message="添加成功")


@router.delete("/{playlist_id}/items/{bvid}", response_model=ApiResponse)
async def remove_playlist_item(
    playlist_id: int,
    bvid: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """移除歌单项"""
    service = PlaylistService(db)
    await service.remove_item(playlist_id, current_user.id, bvid)
    return ApiResponse(success=True, message="移除成功")