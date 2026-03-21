"""B站相关工具函数和常量"""

# B站 CDN 请求头（用于绕过防盗链）
BILIBILI_HEADERS = {
    "Referer": "https://www.bilibili.com/",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}


def normalize_bilibili_url(url: str) -> str:
    """
    处理 B站 URL 协议头缺失问题

    B站返回的 URL 可能以 // 开头（如 //i2.hdslb.com/...），
    需要补全 https: 协议头才能正常访问。

    Args:
        url: 原始 URL

    Returns:
        完整的 URL（带 https: 协议头）
    """
    if url and url.startswith("//"):
        return f"https:{url}"
    return url