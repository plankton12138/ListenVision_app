from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.services.bilibili_service import BilibiliService
from app.services.bilibili_auth_service import BilibiliAuthService
from app.schemas.bilibili import (
    VideoInfo, AudioStreamsResponse, SubtitleResponse,
    SearchResponse, QRCodeResponse, QRCodeCheckResponse,
    BilibiliStatusResponse
)
from app.schemas.common import ApiResponse
from app.models import User

router = APIRouter(prefix="/bilibili", tags=["B站"])


@router.get("/status", response_model=ApiResponse[BilibiliStatusResponse])
async def get_bilibili_status(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """获取B站绑定状态"""
    service = BilibiliAuthService(db)
    status = await service.get_bilibili_status(current_user.id)
    return ApiResponse(success=True, data=status)


@router.post("/qrcode", response_model=ApiResponse[QRCodeResponse])
async def generate_qrcode():
    """生成登录二维码"""
    service = BilibiliAuthService()
    qrcode = await service.generate_qrcode()
    return ApiResponse(success=True, data=qrcode)


@router.get("/qrcode/check", response_model=ApiResponse[QRCodeCheckResponse])
async def check_qrcode(
    qrcode_key: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """检查二维码扫描状态"""
    service = BilibiliAuthService()
    result, credential = await service.check_qrcode(qrcode_key)

    # 如果登录成功，绑定账号
    if result.status == "success" and credential:
        bind_service = BilibiliAuthService(db)
        await bind_service.bind_bilibili_account(
            user_id=current_user.id,
            sessdata=credential.sessdata,
            bili_jct=credential.bili_jct,
            dedeuserid=credential.dedeuserid
        )

    return ApiResponse(success=True, data=result)


@router.delete("/unbind", response_model=ApiResponse)
async def unbind_bilibili(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """解绑B站账号"""
    service = BilibiliAuthService(db)
    await service.unbind_bilibili_account(current_user.id)
    return ApiResponse(success=True, message="解绑成功")


@router.get("/video/{bvid}", response_model=ApiResponse[VideoInfo])
async def get_video_info(bvid: str):
    """获取视频信息"""
    info = await BilibiliService.get_video_info(bvid)
    return ApiResponse(success=True, data=info)


@router.get("/video/{bvid}/audio", response_model=ApiResponse[AudioStreamsResponse])
async def get_audio_streams(bvid: str):
    """获取音频流"""
    streams = await BilibiliService.get_audio_streams(bvid)
    return ApiResponse(success=True, data=streams)


@router.get("/video/{bvid}/subtitle", response_model=ApiResponse[SubtitleResponse])
async def get_subtitles(bvid: str):
    """获取字幕"""
    subtitles = await BilibiliService.get_subtitles(bvid)
    return ApiResponse(success=True, data=subtitles)


@router.get("/search", response_model=ApiResponse[SearchResponse])
async def search_videos(
    keyword: str,
    page: int = 1,
    page_size: int = 20
):
    """搜索视频"""
    result = await BilibiliService.search_videos(keyword, page, page_size)
    return ApiResponse(success=True, data=result)


@router.get("/recommend")
async def get_recommendations(page: int = 1):
    """获取推荐视频"""
    result = await BilibiliService.get_recommendations(page)
    return ApiResponse(success=True, data=result)