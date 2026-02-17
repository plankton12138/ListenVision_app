const playlistService = require('../services/playlistService');
const playHistoryService = require('../services/playHistoryService');
const { successResponse } = require('../utils/response');
const { catchAsync } = require('../middleware/errorHandler');

/**
 * 同步控制器
 *
 * 职责：
 * 1. 提供云端数据拉取接口
 * 2. 支持增量同步（带时间戳）
 * 3. 返回统一格式的响应
 */

// ==================== 收藏同步 ====================

/**
 * 获取云端收藏列表（带时间戳）
 *
 * 返回数据结构包含：
 * - items: 收藏列表
 * - timestamp: 最后更新时间
 * - count: 总数
 */
const getCloudFavorites = catchAsync(async (req, res) => {
  const userId = req.user.id;

  // 获取收藏列表
  const favorites = await playlistService.getFavorites(userId);

  // 为每个收藏项添加时间戳信息
  const itemsWithTimestamp = favorites.map(item => ({
    bvid: item.bvid,
    title: item.title,
    artist: item.artist,
    duration: item.duration,
    coverUrl: item.cover_url || item.coverUrl,
    addedAt: item.added_at || item.created_at,
    // 同步所需的元数据
    _sync: {
      localId: item.id,
      version: 1,
      lastModified: item.updated_at || item.added_at || item.created_at
    }
  }));

  // 获取最后更新时间
  const lastUpdate = favorites.length > 0
    ? favorites.reduce((latest, item) => {
        const itemTime = new Date(item.updated_at || item.added_at || item.created_at || 0);
        return itemTime > latest ? itemTime : latest;
      }, new Date(0))
    : new Date();

  return successResponse(res, {
    items: itemsWithTimestamp,
    timestamp: lastUpdate.toISOString(),
    count: favorites.length
  }, '获取云端收藏列表成功');
});

// ==================== 歌单同步 ====================

/**
 * 获取云端歌单列表（带时间戳）
 *
 * 返回数据结构包含：
 * - items: 歌单列表
 * - timestamp: 最后更新时间
 * - count: 总数
 */
const getCloudPlaylists = catchAsync(async (req, res) => {
  const userId = req.user.id;

  // 获取用户歌单
  const playlists = await playlistService.getUserPlaylists(userId);

  // 为每个歌单添加时间戳信息
  const itemsWithTimestamp = playlists.map(playlist => ({
    id: playlist.id.toString(),
    name: playlist.name,
    description: playlist.description,
    coverUrl: playlist.cover_url || playlist.coverUrl,
    itemCount: playlist.item_count || 0,
    createdAt: playlist.created_at,
    updatedAt: playlist.updated_at,
    // 同步所需的元数据
    _sync: {
      localId: playlist.id,
      version: 1,
      lastModified: playlist.updated_at || playlist.created_at
    }
  }));

  // 获取最后更新时间
  const lastUpdate = playlists.length > 0
    ? playlists.reduce((latest, playlist) => {
        const playlistTime = new Date(playlist.updated_at || playlist.created_at || 0);
        return playlistTime > latest ? playlistTime : latest;
      }, new Date(0))
    : new Date();

  return successResponse(res, {
    items: itemsWithTimestamp,
    timestamp: lastUpdate.toISOString(),
    count: playlists.length
  }, '获取云端歌单列表成功');
});

// ==================== 播放历史同步 ====================

/**
 * 获取云端播放历史（带时间戳）
 *
 * 返回数据结构包含：
 * - items: 播放历史列表
 * - timestamp: 最后更新时间
 * - count: 总数
 */
const getCloudHistory = catchAsync(async (req, res) => {
  const userId = req.user.id;

  // 获取所有播放历史（不分页）
  const history = playHistoryService.getAllHistory(userId);

  // 为每个历史项添加时间戳信息
  const itemsWithTimestamp = history.map(item => ({
    bvid: item.bvid,
    title: item.title,
    artist: item.artist,
    duration: item.duration,
    coverUrl: item.cover_url || item.coverUrl,
    progress: item.progress,
    playedAt: item.played_at,
    // 同步所需的元数据
    _sync: {
      localId: item.id,
      version: 1,
      lastModified: item.played_at
    }
  }));

  // 获取最后更新时间
  const lastUpdate = history.length > 0
    ? history.reduce((latest, item) => {
        const itemTime = new Date(item.played_at || 0);
        return itemTime > latest ? itemTime : latest;
      }, new Date(0))
    : new Date();

  return successResponse(res, {
    items: itemsWithTimestamp,
    timestamp: lastUpdate.toISOString(),
    count: history.length
  }, '获取云端播放历史成功');
});

// ==================== 增量变更同步 ====================

/**
 * 获取增量变更
 *
 * 根据传入的时间戳，返回该时间之后发生变更的数据
 * 用于高效的增量同步
 */
const getCloudChanges = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { since } = req.query;

  const sinceDate = since ? new Date(since) : new Date(0);

  // 收集所有变更
  const changes = [];

  // 1. 获取收藏变更
  const favorites = await playlistService.getFavorites(userId);
  const favoriteChanges = favorites
    .filter(item => {
      const itemTime = new Date(item.updated_at || item.added_at || item.created_at || 0);
      return itemTime > sinceDate;
    })
    .map(item => ({
      type: 'favorite',
      action: 'upsert',
      data: {
        bvid: item.bvid,
        title: item.title,
        artist: item.artist,
        duration: item.duration,
        coverUrl: item.cover_url || item.coverUrl,
        addedAt: item.added_at || item.created_at,
        _sync: {
          localId: item.id,
          version: 1,
          lastModified: item.updated_at || item.added_at || item.created_at
        }
      }
    }));
  changes.push(...favoriteChanges);

  // 2. 获取歌单变更
  const playlists = await playlistService.getUserPlaylists(userId);
  const playlistChanges = playlists
    .filter(playlist => {
      const playlistTime = new Date(playlist.updated_at || playlist.created_at || 0);
      return playlistTime > sinceDate;
    })
    .map(playlist => ({
      type: 'playlist',
      action: 'upsert',
      data: {
        id: playlist.id.toString(),
        name: playlist.name,
        description: playlist.description,
        coverUrl: playlist.cover_url || playlist.coverUrl,
        itemCount: playlist.item_count || 0,
        createdAt: playlist.created_at,
        updatedAt: playlist.updated_at,
        _sync: {
          localId: playlist.id,
          version: 1,
          lastModified: playlist.updated_at || playlist.created_at
        }
      }
    }));
  changes.push(...playlistChanges);

  // 3. 获取播放历史变更
  const history = playHistoryService.getAllHistory(userId);
  const historyChanges = history
    .filter(item => {
      const itemTime = new Date(item.played_at || 0);
      return itemTime > sinceDate;
    })
    .map(item => ({
      type: 'playHistory',
      action: 'upsert',
      data: {
        bvid: item.bvid,
        title: item.title,
        artist: item.artist,
        duration: item.duration,
        coverUrl: item.cover_url || item.coverUrl,
        progress: item.progress,
        playedAt: item.played_at,
        _sync: {
          localId: item.id,
          version: 1,
          lastModified: item.played_at
        }
      }
    }));
  changes.push(...historyChanges);

  return successResponse(res, {
    changes,
    timestamp: new Date().toISOString(),
    count: changes.length
  }, '获取增量变更成功');
});

// ==================== 同步状态 ====================

/**
 * 获取同步状态
 *
 * 返回当前用户的同步状态信息
 */
const getSyncStatus = catchAsync(async (req, res) => {
  const userId = req.user.id;

  // 获取各项数据的最后更新时间
  const favorites = await playlistService.getFavorites(userId);
  const playlists = await playlistService.getUserPlaylists(userId);
  const history = playHistoryService.getAllHistory(userId);

  // 计算最后更新时间
  const getLastUpdate = (items) => {
    if (!items || items.length === 0) return null;
    return items.reduce((latest, item) => {
      const itemTime = new Date(
        item.updated_at || item.added_at || item.created_at || item.played_at || 0
      );
      return itemTime > latest ? itemTime : latest;
    }, new Date(0)).toISOString();
  };

  return successResponse(res, {
    favorites: {
      count: favorites.length,
      lastUpdate: getLastUpdate(favorites)
    },
    playlists: {
      count: playlists.length,
      lastUpdate: getLastUpdate(playlists)
    },
    history: {
      count: history.length,
      lastUpdate: getLastUpdate(history)
    },
    syncVersion: 1,
    serverTime: new Date().toISOString()
  }, '获取同步状态成功');
});

module.exports = {
  getCloudFavorites,
  getCloudPlaylists,
  getCloudHistory,
  getCloudChanges,
  getSyncStatus
};
