from typing import Optional
import httpx
from fastapi import APIRouter, Depends, Request, Response, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user, get_current_user_optional
from app.services.bilibili_service import BilibiliService
from app.services.bilibili_auth_service import BilibiliAuthService
from app.utils.bilibili import BILIBILI_HEADERS
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


@router.get("/download/{bvid}")
async def download_audio(
    bvid: str,
    format: str = "m4a",
    current_user: Optional[User] = Depends(get_current_user_optional),
    db: AsyncSession = Depends(get_db)
):
    """
    下载音频文件（支持格式选择）

    获取 B站音频流并返回为文件下载。
    当前支持 m4a（原始 AAC），MP3 转换需要服务器安装 ffmpeg。
    """
    from app.utils.logger import logger

    logger.info(f"下载音频: bvid={bvid}, format={format}")

    credential = None
    if current_user:
        auth_service = BilibiliAuthService(db)
        credential = await auth_service.get_credential(current_user.id)

    try:
        streams = await BilibiliService.get_audio_streams(bvid, credential)
        if not streams.streams:
            raise ValueError("无可用音频流")

        # 按 quality 降序，选最高音质
        sorted_streams = sorted(streams.streams, key=lambda s: s.quality, reverse=True)
        stream = sorted_streams[0]
        url = stream.url

        async def file_stream():
            async with httpx.AsyncClient(timeout=60.0) as client:
                async with client.stream("GET", url, headers=BILIBILI_HEADERS, follow_redirects=True) as response:
                    response.raise_for_status()
                    async for chunk in response.aiter_bytes(chunk_size=65536):
                        yield chunk

        filename = f"{bvid}.{format}"
        return StreamingResponse(
            file_stream(),
            media_type="audio/mp4",
            headers={
                "Content-Disposition": f'attachment; filename="{filename}"',
                "Cache-Control": "no-cache",
            }
        )

    except ValueError as e:
        logger.warning(f"下载失败: bvid={bvid}, error={e}")
        raise HTTPException(status_code=400, detail=str(e))
    except httpx.TimeoutException:
        logger.error(f"B站API超时: bvid={bvid}")
        raise HTTPException(status_code=504, detail="B站服务超时")
    except httpx.HTTPStatusError as e:
        logger.error(f"B站API错误: bvid={bvid}, status={e.response.status_code}")
        raise HTTPException(status_code=502, detail="B站服务错误")
    except Exception as e:
        logger.error(f"下载音频失败: bvid={bvid}, error={e}")
        raise HTTPException(status_code=500, detail=f"下载失败: {str(e)}")


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
        # 获取流信息（不使用 HEAD 请求的 content-length，因为它可能不准确）
        streams = await BilibiliService.get_audio_streams(bvid, credential)
        if not streams.streams:
            raise ValueError("无可用音频流")

        stream = streams.streams[0]
        url = stream.url

        # 构建请求头
        request_headers = BILIBILI_HEADERS.copy()
        if range_header:
            request_headers["Range"] = range_header

        # 直接流式代理，透传 B站 CDN 的响应
        # 不设置 Content-Length，让 StreamingResponse 自动处理
        async def stream_with_headers():
            async with httpx.AsyncClient(timeout=60.0) as client:
                async with client.stream("GET", url, headers=request_headers, follow_redirects=True) as response:
                    response.raise_for_status()
                    async for chunk in response.aiter_bytes(chunk_size=65536):
                        yield chunk

        # 构建响应头
        response_headers = {
            "Accept-Ranges": "bytes",
            "Cache-Control": "public, max-age=3600",
        }

        # 直接返回流式响应，不设置 Content-Length
        # B站 CDN 会正确处理 Range 请求
        return StreamingResponse(
            stream_with_headers(),
            headers=response_headers,
            media_type="audio/mp4"
        )

    except ValueError as e:
        logger.warning(f"无效请求: bvid={bvid}, error={e}")
        raise HTTPException(status_code=400, detail=str(e))
    except httpx.TimeoutException:
        logger.error(f"B站API超时: bvid={bvid}")
        raise HTTPException(status_code=504, detail="B站服务超时")
    except httpx.HTTPStatusError as e:
        logger.error(f"B站API错误: bvid={bvid}, status={e.response.status_code}")
        raise HTTPException(status_code=502, detail="B站服务错误")
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
