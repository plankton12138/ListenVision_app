from bilibili_api.exceptions import (
    ResponseCodeException,
    NetworkException,
    LoginError
)
from fastapi import HTTPException


class BilibiliErrorHandler:
    ERROR_MAP = {
        -101: (401, "B站账号未登录或已过期"),
        -403: (403, "访问被拒绝"),
        -404: (404, "资源不存在"),
        -400: (400, "请求参数错误"),
    }

    @staticmethod
    async def handle(func, *args, **kwargs):
        try:
            return await func(*args, **kwargs)

        except ResponseCodeException as e:
            status_code, message = BilibiliErrorHandler.ERROR_MAP.get(
                e.code, (500, f"B站API错误: {e.code}")
            )
            raise HTTPException(status_code=status_code, detail=message)

        except NetworkException as e:
            raise HTTPException(status_code=503, detail=f"网络错误: {e}")

        except LoginError as e:
            raise HTTPException(status_code=401, detail=f"登录失败: {e}")
