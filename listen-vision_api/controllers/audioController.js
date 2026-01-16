const audioService = require('../services/audioService');
const { successResponse } = require('../utils/response');

/**
 * 音频元数据控制器
 */

/**
 * 获取音频元数据
 */
const getAudioMetadata = async (req, res) => {
  try {
    const { bvid } = req.params;
    const { maxAge } = req.query;

    if (!bvid) {
      return res.status(400).json({
        success: false,
        error: '缺少 bvid 参数'
      });
    }

    const metadata = await audioService.getAudioMetadata(
      bvid,
      maxAge ? parseInt(maxAge) : undefined
    );

    successResponse(res, metadata);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 获取音频流URL
 */
const getAudioStreamUrl = async (req, res) => {
  try {
    const { bvid } = req.params;

    if (!bvid) {
      return res.status(400).json({
        success: false,
        error: '缺少 bvid 参数'
      });
    }

    const result = await audioService.getAudioStreamUrl(
      bvid,
      req.user?.id || null
    );

    successResponse(res, result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 批量获取音频元数据
 */
const getMultipleMetadata = async (req, res) => {
  try {
    const { bvids } = req.body;

    if (!Array.isArray(bvids) || bvids.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'bvids 参数必须是非空数组'
      });
    }

    // 限制一次最多获取50个
    const limitedBvids = bvids.slice(0, 50);

    const metadataMap = await audioService.getMultipleMetadata(limitedBvids);

    successResponse(res, {
      metadata: Array.from(metadataMap.entries()).map(([bvid, data]) => ({
        bvid,
        ...data
      }))
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 刷新元数据缓存
 */
const refreshMetadata = async (req, res) => {
  try {
    const { bvid } = req.params;

    if (!bvid) {
      return res.status(400).json({
        success: false,
        error: '缺少 bvid 参数'
      });
    }

    const metadata = await audioService.refreshMetadata(bvid);

    successResponse(res, metadata, '刷新成功');
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 删除元数据缓存
 */
const deleteMetadata = async (req, res) => {
  try {
    const { bvid } = req.params;

    if (!bvid) {
      return res.status(400).json({
        success: false,
        error: '缺少 bvid 参数'
      });
    }

    const success = audioService.deleteMetadata(bvid);

    if (!success) {
      return res.status(404).json({
        success: false,
        error: '元数据不存在'
      });
    }

    successResponse(res, { deleted: true }, '删除成功');
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 获取所有缓存元数据
 */
const getAllMetadata = async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;

    const metadata = audioService.getAllMetadata(
      parseInt(limit) || 50,
      parseInt(offset) || 0
    );

    successResponse(res, {
      metadata,
      limit: parseInt(limit) || 50,
      offset: parseInt(offset) || 0
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 获取搜索历史
 */
const getSearchHistory = async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;

    const history = audioService.getSearchHistory(
      req.user.id,
      parseInt(limit) || 20,
      parseInt(offset) || 0
    );

    successResponse(res, {
      history,
      limit: parseInt(limit) || 20,
      offset: parseInt(offset) || 0
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 获取最近搜索关键词
 */
const getRecentSearches = async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    const keywords = audioService.getRecentSearches(
      req.user.id,
      parseInt(limit) || 10
    );

    successResponse(res, {
      keywords
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 清空搜索历史
 */
const clearSearchHistory = async (req, res) => {
  try {
    audioService.clearSearchHistory(req.user.id);

    successResponse(res, { cleared: true }, '搜索历史已清空');
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 删除特定搜索关键词
 */
const deleteSearchKeyword = async (req, res) => {
  try {
    const { keyword } = req.params;

    if (!keyword) {
      return res.status(400).json({
        success: false,
        error: '缺少 keyword 参数'
      });
    }

    const success = audioService.deleteSearchKeyword(req.user.id, keyword);

    if (!success) {
      return res.status(404).json({
        success: false,
        error: '搜索记录不存在'
      });
    }

    successResponse(res, { deleted: true }, '删除成功');
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 获取缓存统计信息
 */
const getCacheStats = async (req, res) => {
  try {
    const stats = audioService.getCacheStats();

    successResponse(res, stats);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

/**
 * 清理过期缓存
 */
const cleanExpiredCache = async (req, res) => {
  try {
    const { maxAge } = req.query;

    const count = audioService.cleanExpiredCache(
      maxAge ? parseInt(maxAge) : undefined
    );

    successResponse(res, { cleaned: count }, `清理了 ${count} 条过期缓存`);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

module.exports = {
  // 元数据
  getAudioMetadata,
  getAudioStreamUrl,
  getMultipleMetadata,
  refreshMetadata,
  deleteMetadata,
  getAllMetadata,

  // 搜索历史
  getSearchHistory,
  getRecentSearches,
  clearSearchHistory,
  deleteSearchKeyword,

  // 统计
  getCacheStats,
  cleanExpiredCache
};
