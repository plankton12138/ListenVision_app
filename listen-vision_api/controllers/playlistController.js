const playlistService = require('../services/playlistService');
const { successResponse } = require('../utils/response');
const { AppError, catchAsync } = require('../middleware/errorHandler');

/**
 * 歌单控制器
 * 处理歌单、收藏、播放队列相关请求
 */

// ==================== 歌单管理 ====================

/**
 * 获取用户所有歌单
 */
const getUserPlaylists = catchAsync(async (req, res) => {
  const userId = req.user.id;

  const playlists = playlistService.getUserPlaylists(userId);

  return successResponse(res, playlists, '获取歌单列表成功');
});

/**
 * 获取歌单详情（包含items）
 */
const getPlaylistDetail = catchAsync(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { sortType } = req.query; // 从查询参数获取排序类型

  const detail = playlistService.getPlaylistDetail(parseInt(id), userId, sortType);

  return successResponse(res, detail, '获取歌单详情成功');
});

/**
 * 创建歌单
 */
const createPlaylist = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { name, description, coverUrl } = req.body;

  if (!name || name.trim() === '') {
    throw new AppError('歌单名称不能为空', 400);
  }

  const playlist = playlistService.createPlaylist(userId, name, description, coverUrl);

  return successResponse(res, playlist, '创建歌单成功', 201);
});

/**
 * 更新歌单
 */
const updatePlaylist = catchAsync(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { name, description, coverUrl, isPublic } = req.body;

  const updates = { name, description, coverUrl, isPublic };
  const playlist = playlistService.updatePlaylist(parseInt(id), userId, updates);

  return successResponse(res, playlist, '更新歌单成功');
});

/**
 * 删除歌单
 */
const deletePlaylist = catchAsync(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  playlistService.deletePlaylist(parseInt(id), userId);

  return successResponse(res, { success: true }, '删除歌单成功');
});

// ==================== 歌单项管理 ====================

/**
 * 添加音频到歌单
 */
const addItem = catchAsync(async (req, res) => {
  const { id } = req.params;
  const { bvid, title, artist, duration, coverUrl, localPath } = req.body;

  if (!bvid) {
    throw new AppError('BVID不能为空', 400);
  }

  const metadata = { title, artist, duration, coverUrl, localPath };
  const item = playlistService.addItem(parseInt(id), bvid, metadata);

  return successResponse(res, item, '添加到歌单成功', 201);
});

/**
 * 从歌单移除音频
 */
const removeItem = catchAsync(async (req, res) => {
  const { id, bvid } = req.params;

  playlistService.removeItem(parseInt(id), bvid);

  return successResponse(res, { success: true }, '从歌单移除成功');
});

/**
 * 调整歌单项顺序
 */
const reorderItems = catchAsync(async (req, res) => {
  const { id } = req.params;
  const { items } = req.body;

  if (!Array.isArray(items)) {
    throw new AppError('items必须是数组', 400);
  }

  playlistService.reorderItems(parseInt(id), items);

  return successResponse(res, { success: true }, '调整顺序成功');
});

/**
 * 重新排序歌单项
 */
const sortItems = catchAsync(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { sortType } = req.body;

  // 验证sortType参数
  const validSortTypes = [
    'added_at_desc', 'added_at_asc',
    'title_asc', 'title_desc',
    'artist_asc', 'artist_desc',
    'position_asc'
  ];

  if (!sortType || !validSortTypes.includes(sortType)) {
    throw new AppError('无效的排序类型', 400);
  }

  playlistService.sortItems(parseInt(id), sortType, userId);

  return successResponse(res, { success: true }, '排序成功');
});

// ==================== 收藏快捷方法 ====================

/**
 * 切换收藏状态
 */
const toggleFavorite = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { bvid, title, artist, duration, coverUrl, localPath } = req.body;

  if (!bvid) {
    throw new AppError('BVID不能为空', 400);
  }

  const metadata = { title, artist, duration, coverUrl, localPath };
  const result = playlistService.toggleFavorite(userId, bvid, metadata);

  return successResponse(res, result, result.added ? '已添加到我喜欢' : '已从我喜欢移除');
});

/**
 * 检查是否已收藏
 */
const checkFavorite = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { bvid } = req.params;

  const favorited = playlistService.isFavorited(userId, bvid);

  return successResponse(res, { favorited }, '检查收藏状态成功');
});

/**
 * 获取收藏列表（我喜欢）
 */
const getFavorites = catchAsync(async (req, res) => {
  const userId = req.user.id;

  const favorites = playlistService.getFavorites(userId);

  return successResponse(res, favorites, '获取收藏列表成功');
});

// ==================== 播放队列 ====================

/**
 * 保存当前播放队列
 */
const saveNowPlaying = catchAsync(async (req, res) => {
  const userId = req.user.id;
  const { items } = req.body;

  if (!Array.isArray(items)) {
    throw new AppError('items必须是数组', 400);
  }

  playlistService.saveNowPlaying(userId, items);

  return successResponse(res, { success: true }, '保存播放队列成功');
});

/**
 * 获取当前播放队列
 */
const getNowPlaying = catchAsync(async (req, res) => {
  const userId = req.user.id;

  const queue = playlistService.getNowPlaying(userId);

  return successResponse(res, queue, '获取播放队列成功');
});

/**
 * 增加歌单播放次数
 */
const incrementPlayCount = catchAsync(async (req, res) => {
  const { id } = req.params;

  playlistService.incrementPlayCount(parseInt(id));

  return successResponse(res, { success: true }, '记录播放成功');
});

module.exports = {
  // 歌单管理
  getUserPlaylists,
  getPlaylistDetail,
  createPlaylist,
  updatePlaylist,
  deletePlaylist,
  // 歌单项管理
  addItem,
  removeItem,
  reorderItems,
  sortItems,
  // 收藏快捷方法
  toggleFavorite,
  checkFavorite,
  getFavorites,
  // 播放队列
  saveNowPlaying,
  getNowPlaying,
  incrementPlayCount
};
