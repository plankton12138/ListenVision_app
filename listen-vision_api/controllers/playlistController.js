const playlistService = require('../services/playlistService');
const { successResponse } = require('../utils/response');
const { catchAsync } = require('../middleware/errorHandler');

/**
 * 歌单控制器
 *
 * 职责：
 * 1. 接收 HTTP 请求，提取参数
 * 2. 调用 Service 层执行业务逻辑
 * 3. 返回统一格式的响应
 *
 * 注意：不包含业务验证逻辑，验证在 Service 层处理
 */

// ==================== 歌单管理 ====================

/**
 * 获取用户所有歌单
 */
const getUserPlaylists = catchAsync(async (req, res) => {
  const playlists = await playlistService.getUserPlaylists(req.user.id);
  return successResponse(res, playlists, '获取歌单列表成功');
});

/**
 * 获取歌单详情（包含items）
 */
const getPlaylistDetail = catchAsync(async (req, res) => {
  const { id } = req.params;
  const { sortType } = req.query;

  const detail = await playlistService.getPlaylistDetail(
    parseInt(id),
    req.user.id,
    sortType
  );

  return successResponse(res, detail, '获取歌单详情成功');
});

/**
 * 创建歌单
 */
const createPlaylist = catchAsync(async (req, res) => {
  const { name, description, coverUrl } = req.body;

  const playlist = await playlistService.createPlaylist(
    req.user.id,
    name,
    description,
    coverUrl
  );

  return successResponse(res, playlist, '创建歌单成功', 201);
});

/**
 * 更新歌单
 */
const updatePlaylist = catchAsync(async (req, res) => {
  const { id } = req.params;
  const updates = req.body;

  const playlist = await playlistService.updatePlaylist(
    parseInt(id),
    req.user.id,
    updates
  );

  return successResponse(res, playlist, '更新歌单成功');
});

/**
 * 删除歌单
 */
const deletePlaylist = catchAsync(async (req, res) => {
  const { id } = req.params;

  await playlistService.deletePlaylist(parseInt(id), req.user.id);

  return successResponse(res, { success: true }, '删除歌单成功');
});

// ==================== 歌单项管理 ====================

/**
 * 添加音频到歌单
 */
const addItem = catchAsync(async (req, res) => {
  const { id } = req.params;
  const itemData = req.body;

  const item = await playlistService.addItem(parseInt(id), itemData);

  return successResponse(res, item, '添加到歌单成功', 201);
});

/**
 * 从歌单移除音频
 */
const removeItem = catchAsync(async (req, res) => {
  const { id, bvid } = req.params;

  await playlistService.removeItem(parseInt(id), bvid);

  return successResponse(res, { success: true }, '从歌单移除成功');
});

/**
 * 调整歌单项顺序
 */
const reorderItems = catchAsync(async (req, res) => {
  const { id } = req.params;
  const { items } = req.body;

  await playlistService.reorderItems(parseInt(id), items);

  return successResponse(res, { success: true }, '调整顺序成功');
});

/**
 * 重新排序歌单项
 */
const sortItems = catchAsync(async (req, res) => {
  const { id } = req.params;
  const { sortType } = req.body;

  await playlistService.sortItems(parseInt(id), sortType, req.user.id);

  return successResponse(res, { success: true }, '排序成功');
});

// ==================== 收藏快捷方法 ====================

/**
 * 切换收藏状态
 */
const toggleFavorite = catchAsync(async (req, res) => {
  const itemData = req.body;

  const result = await playlistService.toggleFavorite(req.user.id, itemData);

  return successResponse(
    res,
    result,
    result.added ? '已添加到我喜欢' : '已从我喜欢移除'
  );
});

/**
 * 检查是否已收藏
 */
const checkFavorite = catchAsync(async (req, res) => {
  const { bvid } = req.params;

  const favorited = await playlistService.isFavorited(req.user.id, bvid);

  return successResponse(res, { favorited }, '检查收藏状态成功');
});

/**
 * 获取收藏列表（我喜欢）
 */
const getFavorites = catchAsync(async (req, res) => {
  const favorites = await playlistService.getFavorites(req.user.id);

  return successResponse(res, favorites, '获取收藏列表成功');
});

// ==================== 播放队列 ====================

/**
 * 保存当前播放队列
 */
const saveNowPlaying = catchAsync(async (req, res) => {
  const { items } = req.body;

  await playlistService.saveNowPlaying(req.user.id, items);

  return successResponse(res, { success: true }, '保存播放队列成功');
});

/**
 * 获取当前播放队列
 */
const getNowPlaying = catchAsync(async (req, res) => {
  const queue = await playlistService.getNowPlaying(req.user.id);

  return successResponse(res, queue, '获取播放队列成功');
});

/**
 * 增加歌单播放次数
 */
const incrementPlayCount = catchAsync(async (req, res) => {
  const { id } = req.params;

  await playlistService.incrementPlayCount(parseInt(id));

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
