from app.api.routes.auth import router as auth_router
from app.api.routes.bilibili import router as bilibili_router
from app.api.routes.playlist import router as playlist_router
from app.api.routes.recommendations import router as recommendations_router

__all__ = ["auth_router", "bilibili_router", "playlist_router", "recommendations_router"]