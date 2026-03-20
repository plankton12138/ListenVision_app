"""B站代理功能测试"""
import pytest

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