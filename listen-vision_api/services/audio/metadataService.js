const db = require('../../config/database');
const bilibiliService = require('../bilibiliService');
const { logger } = require('../../utils/logger');

// 预编译语句
const stmt = {
  getMetadata: db.prepare('SELECT * FROM audio_metadata_cache WHERE bvid = ?'),
  insertMetadata: db.prepare(`
    INSERT OR REPLACE INTO audio_metadata_cache
    (bvid, title, artist, duration, cover_url, audio_url, cid, metadata, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
  `),
  updateAudioUrl: db.prepare(`
    UPDATE audio_metadata_cache SET audio_url = ?, updated_at = datetime('now') WHERE bvid = ?
  `),
  deleteMetadata: db.prepare('DELETE FROM audio_metadata_cache WHERE bvid = ?'),
  getAllMetadata: db.prepare('SELECT * FROM audio_metadata_cache ORDER BY created_at DESC LIMIT ? OFFSET ?'),
  getCacheStats: db.prepare(`
    SELECT COUNT(*) as total, MAX(updated_at) as last_update FROM audio_metadata_cache
  `),
};

/**
 * 解析缓存的元数据
 */
const parseCachedMetadata = (row) => {
  const result = {
    bvid: row.bvid,
    title: row.title,
    artist: row.artist,
    duration: row.duration,
    cover: row.cover_url,
    audioUrl: row.audio_url,
    cid: row.cid,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };

  if (row.metadata) {
    try {
      const extra = JSON.parse(row.metadata);
      result.desc = extra.desc;
      result.owner = extra.owner;
      result.pages = extra.pages;
    } catch (e) {
      logger.warn('解析元数据JSON失败 [%s]: %s', row.bvid, e.message);
    }
  }

  return result;
};

/**
 * 从B站获取并缓存元数据
 */
const fetchAndCacheMetadata = async (bvid) => {
  const videoInfo = await bilibiliService.getVideoInfo(bvid);

  const metadata = {
    bvid: videoInfo.bvid,
    title: videoInfo.title,
    artist: videoInfo.owner.name,
    duration: videoInfo.duration,
    cover: videoInfo.cover,
    cid: videoInfo.cid,
    desc: videoInfo.desc,
    owner: videoInfo.owner
  };

  stmt.insertMetadata.run(
    metadata.bvid,
    metadata.title,
    metadata.artist,
    metadata.duration,
    metadata.cover,
    null,
    metadata.cid,
    JSON.stringify(metadata)
  );

  return metadata;
};

/**
 * 获取音频元数据（优先从缓存）
 */
const getAudioMetadata = async (bvid, maxAge = 7 * 24 * 60 * 60 * 1000) => {
  const cached = stmt.getMetadata.get(bvid);

  if (cached) {
    const updatedAt = new Date(cached.updated_at);
    const age = Date.now() - updatedAt.getTime();

    if (age < maxAge) {
      return parseCachedMetadata(cached);
    }
  }

  return await fetchAndCacheMetadata(bvid);
};

/**
 * 批量获取音频元数据
 */
const getMultipleMetadata = async (bvids) => {
  const result = new Map();
  const toFetch = [];

  const batchSize = 10;
  for (let i = 0; i < bvids.length; i += batchSize) {
    const batch = bvids.slice(i, i + batchSize);
    const placeholders = batch.map(() => '?').join(',');
    const query = `SELECT * FROM audio_metadata_cache WHERE bvid IN (${placeholders})`;
    const cached = db.prepare(query).all(...batch);

    cached.forEach(row => {
      result.set(row.bvid, parseCachedMetadata(row));
    });
  }

  bvids.forEach(bvid => {
    if (!result.has(bvid)) {
      toFetch.push(bvid);
    }
  });

  if (toFetch.length > 0) {
    await Promise.all(toFetch.map(async (bvid) => {
      try {
        const metadata = await fetchAndCacheMetadata(bvid);
        result.set(bvid, metadata);
      } catch (error) {
        logger.error('获取 %s 元数据失败: %s', bvid, error.message);
      }
    }));
  }

  return result;
};

/**
 * 获取音频流URL
 */
const getAudioStreamUrl = async (bvid, userId = null) => {
  const metadata = await getAudioMetadata(bvid);
  const audioStream = await bilibiliService.getAudioStream(bvid, metadata.cid, userId);

  stmt.updateAudioUrl.run(audioStream.baseUrl, bvid);

  return {
    bvid: metadata.bvid,
    title: metadata.title,
    artist: metadata.artist,
    duration: metadata.duration,
    cover: metadata.cover,
    audioUrl: audioStream.baseUrl,
    mimeType: audioStream.mimeType,
    codecs: audioStream.codecs
  };
};

/**
 * 刷新元数据缓存
 */
const refreshMetadata = async (bvid) => {
  return await fetchAndCacheMetadata(bvid);
};

/**
 * 删除元数据缓存
 */
const deleteMetadata = (bvid) => {
  const info = stmt.deleteMetadata.run(bvid);
  return info.changes > 0;
};

/**
 * 获取所有缓存的元数据
 */
const getAllMetadata = (limit = 50, offset = 0) => {
  const rows = stmt.getAllMetadata.all(limit, offset);
  return rows.map(parseCachedMetadata);
};

/**
 * 获取缓存统计
 */
const getCacheStats = () => {
  const stats = stmt.getCacheStats.get();
  return {
    totalCached: stats.total || 0,
    lastUpdate: stats.last_update || null
  };
};

/**
 * 清理过期缓存
 */
const cleanExpiredCache = (maxAge = 30 * 24 * 60 * 60 * 1000) => {
  const expireTime = new Date(Date.now() - maxAge).toISOString();
  const info = db.prepare('DELETE FROM audio_metadata_cache WHERE updated_at < ?').run(expireTime);
  return info.changes;
};

module.exports = {
  getAudioMetadata,
  getMultipleMetadata,
  getAudioStreamUrl,
  refreshMetadata,
  deleteMetadata,
  getAllMetadata,
  getCacheStats,
  cleanExpiredCache
};
