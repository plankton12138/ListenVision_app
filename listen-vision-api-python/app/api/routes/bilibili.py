from typing import Optional, Tuple
from fastapi import APIRouter, Depends, Request, Response, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user, get_current_user_optional
from app.services.bilibili_service import BilibiliService
from app.services.bilibili_auth_service import BilibiliAuthService
from app.schemas.bilibili import (
    VideoInfo, AudioStreamsResponse, SubtitleResponse,
    SearchResponse, QRCodeResponse, QRCodeCheckResponse,
    BilibiliStatusResponse
)
from app.schemas.common import ApiResponse
from app.models import User
from bilibili_api import Credential

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
async def get_subtitles(
    bvid: str,
    current_user: Optional[User] = Depends(get_current_user_optional),
    db: AsyncSession = Depends(get_db)
):
    """获取字幕"""
    credential = None
    if current_user:
        auth_service = BilibiliAuthService(db)
        credential = await auth_service.get_credential(current_user.id)

    subtitles = await BilibiliService.get_subtitles(bvid, credential=credential)
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


# ==================== 代理功能 ====================

@router.get("/proxy/image")
async def proxy_image(url: str):
    """
    代理图片

    用于绕过跨域限制，代理B站图片资源
    """
    data, content_type = await BilibiliService.proxy_image(url)
    return Response(
        content=data,
        media_type=content_type,
        headers={"Cache-Control": "public, max-age=86400"}
    )


@router.get("/proxy/audio/{bvid}")
async def proxy_audio(
    bvid: str,
    request: Request,
    current_user: Optional[User] = Depends(get_current_user_optional),
    db: AsyncSession = Depends(get_db)
):
    """
    流式代理音频，支持 Range 请求

    用于播放B站音频，边下载边返回，显著降低启动延迟。
    支持游客模式（无需登录）。
    """
    from app.utils.logger import logger

    range_header = request.headers.get("range")
    logger.info(f"流式音频代理: bvid={bvid}, range={range_header}")

    # 获取用户 B站凭证（如果已登录且已绑定）
    credential = None
    if current_user:
        auth_service = BilibiliAuthService(db)
        credential = await auth_service.get_credential(current_user.id)

    try:
        # 获取流信息
        url, content_length, headers = await BilibiliService.get_audio_stream_info(bvid, credential)

        # 构建响应头
        response_headers = {
            "Content-Type": headers["content-type"],
            "Accept-Ranges": "bytes",
            "Cache-Control": "public, max-age=3600",
        }

        # 处理 Range 请求
        if range_header:
            # 解析 Range 头
            start, end = _parse_range_header(range_header, content_length)
            if start >= content_length:
                return Response(status_code=416, headers={"Content-Range": f"bytes */{content_length}"})

            # 构建子范围请求头
            range_request_header = f"bytes={start}-{end}"
            response_headers["Content-Range"] = f"bytes {start}-{end}/{content_length}"
            response_headers["Content-Length"] = str(end - start + 1)

            logger.info(f"流式代理范围: {range_request_header}")

            return StreamingResponse(
                BilibiliService.stream_audio_proxy(bvid, credential, range_request_header),
                status_code=206,
                headers=response_headers,
                media_type=headers["content-type"]
            )
        else:
            response_headers["Content-Length"] = str(content_length)

            return StreamingResponse(
                BilibiliService.stream_audio_proxy(bvid, credential),
                headers=response_headers,
                media_type=headers["content-type"]
            )

    except Exception as e:
        logger.error(f"流式音频代理失败: bvid={bvid}, error={e}")
        raise HTTPException(status_code=500, detail=f"音频代理失败: {str(e)}")


# ==================== UP主功能 ====================

@router.get("/uploader/{mid}")
async def get_uploader(mid: int):
    """
    获取UP主信息

    包括粉丝数、投稿数等基本信息
    """
    info = await BilibiliService.get_uploader_info(mid)
    return ApiResponse(success=True, data=info)


# ==================== 搜索功能 ====================

@router.get("/search/suggest")
async def get_search_suggestions(keyword: str):
    """
    获取搜索建议

    根据输入关键词返回搜索建议列表
    """
    keywords = await BilibiliService.get_search_suggestions(keyword)
    # 转换为前端期望的格式：[{ "value": "...", "name": "..." }]
    suggestions = [{"value": kw, "name": kw} for kw in keywords]
    return ApiResponse(success=True, data={"suggestions": suggestions})


@router.get("/search/recent")
async def get_recent_searches(
    current_user: User = Depends(get_current_user),
    limit: int = 10
):
    """
    获取最近搜索记录

    返回当前用户的搜索历史
    """
    history = await BilibiliService.get_search_history(current_user.id, limit)
    return ApiResponse(success=True, data={"keywords": history})


# ==================== Cookie 刷新 ====================

@router.post("/refresh-cookie")
async def refresh_cookie(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    手动刷新 B站 Cookie

    当Cookie即将过期时调用此接口刷新
    """
    from app.db.repositories.platform_account_repo import PlatformAccountRepository
    from app.models.platform_account import PlatformType

    platform_repo = PlatformAccountRepository(db)
    account = await platform_repo.get_by_user_and_platform(
        current_user.id, PlatformType.BILIBILI
    )

    if not account:
        return ApiResponse(success=False, message="未绑定B站账号")

    # 构建 Credential
    credential = Credential(
        sessdata=account.sessdata,
        bili_jct=account.bili_jct,
        dedeuserid=account.dedeuserid
    )

    # 刷新 Cookie
    new_cred = await BilibiliService.refresh_cookie(credential)

    # 更新数据库
    await platform_repo.update_bilibili_credentials(
        account_id=account.id,
        sessdata=new_cred["sessdata"],
        bili_jct=new_cred["bili_jct"],
        dedeuserid=new_cred["dedeuserid"]
    )

    return ApiResponse(success=True, message="Cookie 刷新成功")


# ==================== 辅助函数 ====================

def _parse_range_header(range_header: str, total_size: int) -> Tuple[int, int]:
    """
    解析 Range 请求头

    Args:
        range_header: Range 头值，如 "bytes=0-1023"
        total_size: 文件总大小

    Returns:
        元组 (start, end)
    """
    if not range_header.startswith("bytes="):
        return 0, total_size - 1

    range_spec = range_header[6:]  # 去掉 "bytes="
    if "-" not in range_spec:
        return 0, total_size - 1

    parts = range_spec.split("-")
    start = int(parts[0]) if parts[0] else 0
    end = int(parts[1]) if parts[1] else total_size - 1

    return start, min(end, total_size - 1)
