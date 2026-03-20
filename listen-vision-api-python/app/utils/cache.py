import time
from typing import Optional, Any, Dict
from functools import wraps


class MemoryCache:
    """简单的内存缓存"""

    def __init__(self):
        self._cache: Dict[str, Any] = {}
        self._expires: Dict[str, float] = {}

    def get(self, key: str) -> Optional[Any]:
        """获取缓存值"""
        if key in self._expires and time.time() > self._expires[key]:
            self.delete(key)
            return None
        return self._cache.get(key)

    def set(self, key: str, value: Any, ttl: int = 300) -> None:
        """设置缓存值"""
        self._cache[key] = value
        self._expires[key] = time.time() + ttl

    def delete(self, key: str) -> None:
        """删除缓存"""
        self._cache.pop(key, None)
        self._expires.pop(key, None)

    def clear(self) -> None:
        """清空缓存"""
        self._cache.clear()
        self._expires.clear()


cache = MemoryCache()


def cached(ttl: int = 300):
    """缓存装饰器"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # 生成缓存键
            cache_key = f"{func.__name__}:{str(args)}:{str(kwargs)}"

            # 尝试获取缓存
            cached_value = cache.get(cache_key)
            if cached_value is not None:
                return cached_value

            # 执行函数
            result = await func(*args, **kwargs)

            # 缓存结果
            cache.set(cache_key, result, ttl)

            return result
        return wrapper
    return decorator
