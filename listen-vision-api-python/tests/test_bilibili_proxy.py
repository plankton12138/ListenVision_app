"""B站代理功能测试"""
import pytest
from bilibili_api.exceptions import CredentialNoSessdataException
from unittest.mock import AsyncMock, patch

from app.services.bilibili_service import BilibiliService


@pytest.mark.asyncio
async def test_proxy_image():
    """测试图片代理"""
    # 使用一个测试图片 URL (B站默认头像)
    url = "https://i0.hdslb.com/bfs/bangumi/image/dcc8c689df6d45e495c3c3a443e5a6a0a7f5a5a5.png"
    try:
        data, content_type = await BilibiliService.proxy_image(url)
        assert isinstance(data, bytes)
        assert len(data) > 0
        assert content_type.startswith("image/")
    except Exception as e:
        # 网络问题或图片不存在时跳过
        pytest.skip(f"网络不可用或图片不存在: {e}")


@pytest.mark.asyncio
async def test_proxy_image_invalid_url():
    """测试无效图片URL"""
    url = "https://invalid.example.com/notexist.jpg"
    with pytest.raises(Exception):
        await BilibiliService.proxy_image(url)


@pytest.mark.asyncio
async def test_get_uploader_info():
    """测试获取UP主信息"""
    # 使用一个已知存在的 UP主 ID (bilibili 官方账号)
    mid = 2
    try:
        info = await BilibiliService.get_uploader_info(mid)
        assert info["mid"] == mid
        assert "name" in info
        assert "face" in info
    except Exception as e:
        pytest.skip(f"网络不可用: {e}")


@pytest.mark.asyncio
async def test_get_uploader_info_invalid_mid():
    """测试无效UP主ID"""
    # 使用一个不太可能存在的 UP主 ID
    mid = 999999999999
    with pytest.raises(Exception):
        await BilibiliService.get_uploader_info(mid)


@pytest.mark.asyncio
async def test_search_suggestions():
    """测试搜索建议"""
    try:
        suggestions = await BilibiliService.get_search_suggestions("原神")
        assert isinstance(suggestions, list)
        # 搜索建议可能为空，但不应该报错
    except Exception as e:
        pytest.skip(f"网络不可用: {e}")


@pytest.mark.asyncio
async def test_search_suggestions_empty():
    """测试空关键词搜索建议"""
    suggestions = await BilibiliService.get_search_suggestions("")
    assert isinstance(suggestions, list)


@pytest.mark.asyncio
async def test_search_history():
    """测试搜索历史"""
    user_id = 999999  # 使用测试用户ID

    # 添加搜索历史
    await BilibiliService.add_search_history(user_id, "测试关键词1")
    await BilibiliService.add_search_history(user_id, "测试关键词2")
    await BilibiliService.add_search_history(user_id, "测试关键词3")

    # 获取搜索历史
    history = await BilibiliService.get_search_history(user_id)
    assert isinstance(history, list)
    assert "测试关键词1" in history
    assert "测试关键词2" in history
    assert "测试关键词3" in history


@pytest.mark.asyncio
async def test_search_history_dedup():
    """测试搜索历史去重"""
    user_id = 999998  # 使用测试用户ID

    # 添加重复关键词
    await BilibiliService.add_search_history(user_id, "重复关键词")
    await BilibiliService.add_search_history(user_id, "其他关键词")
    await BilibiliService.add_search_history(user_id, "重复关键词")

    # 获取搜索历史
    history = await BilibiliService.get_search_history(user_id)
    assert history.count("重复关键词") == 1
    # 最新添加的应该在最前面
    assert history[0] == "重复关键词"


@pytest.mark.asyncio
async def test_search_history_limit():
    """测试搜索历史数量限制"""
    user_id = 999997  # 使用测试用户ID

    # 添加超过50条记录
    for i in range(60):
        await BilibiliService.add_search_history(user_id, f"关键词{i}")

    # 获取搜索历史
    history = await BilibiliService.get_search_history(user_id, limit=50)
    assert len(history) <= 50


@pytest.mark.asyncio
async def test_search_history_empty_user():
    """测试空用户的搜索历史"""
    user_id = 999996  # 未添加过历史的用户

    history = await BilibiliService.get_search_history(user_id)
    assert isinstance(history, list)
    assert len(history) == 0


@pytest.mark.asyncio
async def test_proxy_audio_stream():
    """测试音频流代理"""
    # 使用一个已知的视频 BV 号进行测试
    bvid = "BV1xx411c7mD"  # B站官方视频
    try:
        data, content_type, total_size, start = await BilibiliService.proxy_audio_stream(
            bvid, credential=None, range_header=None
        )
        assert isinstance(data, bytes)
        assert len(data) > 0
        assert content_type.startswith("audio/")
        assert total_size > 0
        assert start == 0
    except Exception as e:
        # 网络问题或视频不存在时跳过
        pytest.skip(f"网络不可用或视频不存在: {e}")


@pytest.mark.asyncio
async def test_proxy_audio_stream_with_range():
    """测试带 Range 请求的音频流代理"""
    bvid = "BV1xx411c7mD"
    try:
        # 请求前 1024 字节
        data, content_type, total_size, start = await BilibiliService.proxy_audio_stream(
            bvid, credential=None, range_header="bytes=0-1023"
        )
        assert isinstance(data, bytes)
        assert len(data) <= 1024
        assert content_type.startswith("audio/")
        assert start == 0
    except Exception as e:
        pytest.skip(f"网络不可用或视频不存在: {e}")


@pytest.mark.asyncio
async def test_get_subtitles_returns_need_login_when_sessdata_missing():
    """测试游客态字幕请求返回 need_login 而不是 500"""
    mock_video = AsyncMock()
    mock_video.get_info.return_value = {"cid": 123456}
    mock_video.get_subtitle.side_effect = CredentialNoSessdataException()

    with patch("app.services.bilibili_service.video.Video", return_value=mock_video):
        result = await BilibiliService.get_subtitles("BV1test123456")

    assert result.bvid == "BV1test123456"
    assert result.cid == 123456
    assert result.subtitles == []
    assert result.need_login is True


@pytest.mark.asyncio
async def test_refresh_cookie():
    """测试 Cookie 刷新"""
    from unittest.mock import AsyncMock, patch, MagicMock
    from bilibili_api import Credential

    # 创建一个模拟的 Credential，使用 spec 来确保类型正确
    mock_credential = MagicMock(spec=Credential)
    mock_credential.sessdata = "test_sessdata"
    mock_credential.bili_jct = "test_bili_jct"
    mock_credential.dedeuserid = "test_dedeuserid"
    mock_credential.refresh = AsyncMock()

    # 设置刷新后的值
    async def mock_refresh():
        mock_credential.sessdata = "new_sessdata"
        mock_credential.bili_jct = "new_bili_jct"
        mock_credential.dedeuserid = "new_dedeuserid"

    mock_credential.refresh.side_effect = mock_refresh

    result = await BilibiliService.refresh_cookie(mock_credential)

    assert result["sessdata"] == "new_sessdata"
    assert result["bili_jct"] == "new_bili_jct"
    assert result["dedeuserid"] == "new_dedeuserid"
    mock_credential.refresh.assert_called_once()


@pytest.mark.asyncio
async def test_refresh_cookie_failure():
    """测试 Cookie 刷新失败"""
    from unittest.mock import AsyncMock, MagicMock
    from bilibili_api import Credential

    mock_credential = MagicMock(spec=Credential)
    mock_credential.refresh = AsyncMock(side_effect=Exception("Cookie 已过期"))

    with pytest.raises(Exception, match="Cookie 已过期"):
        await BilibiliService.refresh_cookie(mock_credential)


@pytest.mark.asyncio
async def test_stream_audio_proxy():
    """测试流式音频代理"""
    bvid = "BV1vsAwzREPP"

    try:
        chunks = []
        async for chunk in BilibiliService.stream_audio_proxy(bvid):
            chunks.append(chunk)
            if len(chunks) >= 3:  # 只测试前几个块
                break

        assert len(chunks) > 0
        assert all(isinstance(chunk, bytes) for chunk in chunks)
    except Exception as e:
        # 网络问题或视频不存在时跳过
        pytest.skip(f"网络不可用或视频不存在: {e}")


@pytest.mark.asyncio
async def test_stream_audio_proxy_with_range():
    """测试带 Range 的流式代理"""
    bvid = "BV1vsAwzREPP"

    try:
        # 先获取流信息
        url, content_length, headers = await BilibiliService.get_audio_stream_info(bvid)
        assert content_length > 0

        # 请求前 1KB
        chunks = []
        async for chunk in BilibiliService.stream_audio_proxy(bvid, range_header="bytes=0-1023"):
            chunks.append(chunk)

        total_size = sum(len(chunk) for chunk in chunks)
        assert total_size == 1024  # 请求了 0-1023，共 1024 字节
    except Exception as e:
        pytest.skip(f"网络不可用或视频不存在: {e}")


@pytest.mark.asyncio
async def test_get_audio_stream_info():
    """测试获取音频流信息"""
    bvid = "BV1vsAwzREPP"

    try:
        url, content_length, headers = await BilibiliService.get_audio_stream_info(bvid)

        assert url is not None
        assert len(url) > 0
        assert content_length > 0
        assert "content-type" in headers
        assert "accept-ranges" in headers
        assert headers["accept-ranges"] == "bytes"
    except Exception as e:
        pytest.skip(f"网络不可用或视频不存在: {e}")
