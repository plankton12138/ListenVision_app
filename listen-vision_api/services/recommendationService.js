const db = require('../config/database');
const { searchBilibili, getWbiKey, signWbi, getCookie } = require('./bilibiliService');

/**
 * B站推荐内容服务（Phase 3.2 扩展）
 *
 * 功能：
 * 1. 热门歌单（B站音乐服务）
 * 2. 热歌榜单（B站音乐服务）
 * 3. 个性化推荐（基于搜索历史 + 用户行为）
 * 4. 分区推荐（音乐区、翻唱、演奏等）
 *
 * Phase 3.2 新增：
 * - 记录用户行为日志（播放、收藏、跳过、分享）
 * - 基于用户行为的协同过滤推荐
 * - 内容相似度推荐
 *
 * API参考: bilibili-API-collect/docs/audio/music_list.md
 */

// ==================== 预编译语句 ====================

const stmt = {
  // 获取用户搜索历史（用于个性化推荐）
  getRecentSearches: db.prepare(`
    SELECT DISTINCT keyword, result_count
    FROM search_history
    WHERE user_id = ? AND result_count > 0
    ORDER BY created_at DESC
    LIMIT 10
  `),

  // 获取用户播放历史（用于个性化推荐）
  getRecentPlays: db.prepare(`
    SELECT DISTINCT bvid, title, artist
    FROM play_history
    WHERE user_id = ?
    ORDER BY played_at DESC
    LIMIT 10
  `),

  // Phase 3.2: 记录用户行为
  logUserBehavior: db.prepare(`
    INSERT INTO user_behavior_logs (user_id, bvid, action, timestamp)
    VALUES (?, ?, ?, datetime('now'))
  `),

  // Phase 3.2: 获取用户偏好（基于行为日志）
  getUserPreferences: db.prepare(`
    SELECT
      action,
      COUNT(DISTINCT bvid) as count
    FROM user_behavior_logs
    WHERE user_id = ? AND timestamp > datetime('now', '-30 days')
    GROUP BY action
  `),

  // Phase 3.2: 获取相似用户喜欢的视频（协同过滤基础）
  getSimilarUsersLikedVideos: db.prepare(`
    SELECT DISTINCT l.bvid
    FROM user_behavior_logs l
    WHERE l.user_id IN (
      SELECT DISTINCT user_id
      FROM user_behavior_logs
      WHERE bvid IN (SELECT bvid FROM user_behavior_logs WHERE user_id = ? AND action = 'like')
      AND action = 'like'
    )
    AND l.action = 'like'
    AND l.timestamp > datetime('now', '-30 days')
    LIMIT 20
  `),
};

// ==================== HTTP请求工具 ====================

/**
 * 通用HTTP请求函数（复用bilibiliService）
 */
const httpGet = async (url, headers = {}) => {
  const response = await fetch(url, {
    method: 'GET',
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://www.bilibili.com/',
      ...headers
    }
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }

  return response.json();
};

// ==================== B站音乐服务推荐 ====================

/**
 * 获取热门歌单
 *
 * API: GET https://www.bilibili.com/audio/music-service-c/web/menu/hit?pn={page}&ps={pageSize}
 *
 * @param {number} page - 页码
 * @param {number} pageSize - 每页数量
 * @returns {Object} 热门歌单列表
 */
const getHotPlaylists = async (page = 1, pageSize = 10) => {
  try {
    const url = `https://www.bilibili.com/audio/music-service-c/web/menu/hit?pn=${page}&ps=${pageSize}`;
    const data = await httpGet(url);

    if (data.code !== 0) {
      throw new Error(data.message || '获取热门歌单失败');
    }

    const playlists = (data.data?.data || []).map(p => ({
      menuId: p.menuId,
      uid: p.uid,
      uname: p.uname,
      title: p.title,
      cover: p.cover,
      intro: p.intro,
      type: p.type,
      songCount: p.snum,
      statistic: {
        play: p.statistic?.play || 0,
        collect: p.statistic?.collect || 0,
        comment: p.statistic?.comment || 0,
        share: p.statistic?.share || 0
      },
      // 部分歌单包含预览音频
      previews: (p.audios || []).map(a => ({
        id: a.id,
        title: a.title,
        duration: a.duration
      }))
    }));

    return {
      playlists,
      page: data.data?.curPage || page,
      pageSize: data.data?.pageSize || pageSize,
      total: data.data?.totalSize || 0
    };
  } catch (error) {
    throw new Error(`获取热门歌单失败: ${error.message}`);
  }
};

/**
 * 获取热歌榜单
 *
 * API: GET https://www.bilibili.com/audio/music-service-c/web/menu/rank?pn={page}&ps={pageSize}
 *
 * @param {number} page - 页码
 * @param {number} pageSize - 每页数量
 * @returns {Object} 热歌榜单列表
 */
const getHotRank = async (page = 1, pageSize = 10) => {
  try {
    const url = `https://www.bilibili.com/audio/music-service-c/web/menu/rank?pn=${page}&ps=${pageSize}`;
    const data = await httpGet(url);

    if (data.code !== 0) {
      throw new Error(data.message || '获取热歌榜单失败');
    }

    const playlists = (data.data?.data || []).map(p => ({
      menuId: p.menuId,
      uid: p.uid,
      uname: p.uname,
      title: p.title,
      cover: p.cover,
      intro: p.intro,
      type: p.type,
      songCount: p.snum,
      statistic: {
        play: p.statistic?.play || 0,
        collect: p.statistic?.collect || 0,
        comment: p.statistic?.comment || 0,
        share: p.statistic?.share || 0
      },
      // 榜单通常包含预览音频
      previews: (p.audios || []).map(a => ({
        id: a.id,
        title: a.title,
        duration: a.duration
      }))
    }));

    return {
      playlists,
      page: data.data?.curPage || page,
      pageSize: data.data?.pageSize || pageSize,
      total: data.data?.totalSize || 0
    };
  } catch (error) {
    throw new Error(`获取热歌榜单失败: ${error.message}`);
  }
};

// ==================== 个性化推荐 ====================

/**
 * 获取个性化推荐
 * 基于用户的搜索历史和播放历史，推荐相关内容
 *
 * @param {number} userId - 用户ID
 * @param {number} limit - 推荐数量限制
 * @returns {Object} 个性化推荐结果
 */
const getPersonalized = async (userId, limit = 20) => {
  try {
    // 获取用户最近搜索的关键词
    const searchHistory = stmt.getRecentSearches.all(userId);

    // 获取用户最近播放的视频
    const playHistory = stmt.getRecentPlays.all(userId);

    // 如果没有历史数据，返回热门推荐
    if (searchHistory.length === 0 && playHistory.length === 0) {
      // 返回热门歌单的前几个
      const hotPlaylists = await getHotPlaylists(1, 3);
      return {
        source: 'hot',
        playlists: hotPlaylists.playlists.slice(0, 2),
        videos: []
      };
    }

    // 基于搜索关键词进行推荐搜索
    const keywords = searchHistory.map(h => h.keyword).slice(0, 3);
    const recommendations = [];

    for (const keyword of keywords) {
      try {
        const result = await searchBilibili(keyword, 1, 5, null);
        recommendations.push(...result.videos.slice(0, 3));
      } catch (e) {
        // 忽略单个搜索失败
        console.error(`个性化搜索失败: ${keyword}`, e.message);
      }
      if (recommendations.length >= limit) break;
    }

    return {
      source: 'personalized',
      keywords,
      videos: recommendations.slice(0, limit)
    };
  } catch (error) {
    throw new Error(`获取个性化推荐失败: ${error.message}`);
  }
};

// ==================== 分区推荐 ====================

/**
 * 分区ID常量
 */
const CATEGORY_TIDS = {
  MUSIC: 3,            // 音乐区
  ORIGINAL_MUSIC: 28,  // 原创音乐
  COVER: 31,           // 翻唱
  INSTRUMENTAL: 59,    // 演奏
  VOCALOID: 30,        // VOCALOID
  DANCE: 129,          // 舞蹈
  MV: 193              // MV
};

/**
 * 获取分区推荐
 *
 * API: GET https://api.bilibili.com/x/web-interface/wbi/search/type
 *
 * @param {number} tid - 分区ID
 * @param {number} page - 页码
 * @param {number} pageSize - 每页数量
 * @param {number} userId - 用户ID（可选，用于获取Cookie）
 * @returns {Object} 分区推荐结果
 */
const getByCategory = async (tid, page = 1, pageSize = 20, userId = null) => {
  try {
    // 获取WBI签名（传入userId以使用Cookie）
    const wbiKey = await getWbiKey(userId);
    console.log(`[getByCategory] WBI Key:`, wbiKey);

    // 如果没有WBI key，返回空结果
    if (!wbiKey.imgKey || !wbiKey.subKey) {
      console.warn('[getByCategory] No valid WBI key, returning empty result');
      return { tid, videos: [], page, pageSize, total: 0 };
    }

    const params = {
      search_type: 'video',
      tid,
      pn: page,
      page_size: pageSize
    };
    const signedParams = signWbi(params, wbiKey);

    const url = `https://api.bilibili.com/x/web-interface/wbi/search/type?${new URLSearchParams(signedParams).toString()}`;
    console.log(`[getByCategory] URL: ${url}`);

    // 构建请求头（如果有Cookie）
    const headers = {};
    if (userId) {
      const { getCookie } = require('./bilibiliService');
      const cookie = getCookie(userId);
      if (cookie) {
        headers['Cookie'] = cookie;
      }
    }

    let data;
    try {
      data = await httpGet(url, headers);
    } catch (httpError) {
      console.error(`[getByCategory] HTTP Error: ${httpError.message}`);
      throw new Error(`请求错误: ${httpError.message}`);
    }

    console.log(`[getByCategory] Response code: ${data.code}`);

    if (data.code !== 0) {
      throw new Error(data.message || '获取分区推荐失败');
    }

    const results = data.data?.result || [];
    const videos = results
      .filter(r => r.type === 'video')
      .map(r => ({
        bvid: r.bvid,
        title: cleanHtml(r.title),
        description: cleanHtml(r.description),
        cover: r.pic.startsWith('//') ? 'https:' + r.pic : r.pic,
        duration: r.duration,
        author: r.author,
        play: r.play,
        arcurl: r.arcurl
      }));

    return {
      tid,
      videos,
      page,
      pageSize,
      total: data.data?.numResults || videos.length
    };
  } catch (error) {
    console.error(`[getByCategory] Error: ${error.message}`);
    throw new Error(`获取分区推荐失败: ${error.message}`);
  }
};

/**
 * 获取音乐区推荐（综合）
 *
 * @param {number} limit - 数量限制
 * @param {number} userId - 用户ID（可选，用于获取Cookie）
 * @returns {Object} 音乐区推荐
 */
const getMusicRecommendation = async (limit = 20, userId = null) => {
  try {
    // 组合多个音乐分区的内容
    const categories = [
      { tid: CATEGORY_TIDS.MUSIC, name: '音乐' },
      { tid: CATEGORY_TIDS.ORIGINAL_MUSIC, name: '原创音乐' },
      { tid: CATEGORY_TIDS.COVER, name: '翻唱' }
    ];

    const results = [];
    for (const cat of categories) {
      try {
        const result = await getByCategory(cat.tid, 1, Math.ceil(limit / categories.length), userId);
        results.push({
          category: cat.name,
          tid: cat.tid,
          videos: result.videos
        });
      } catch (e) {
        console.error(`获取${cat.name}推荐失败:`, e.message);
      }
    }

    return results;
  } catch (error) {
    throw new Error(`获取音乐区推荐失败: ${error.message}`);
  }
};

// ==================== 工具函数 ====================

/**
 * 清理HTML标签
 */
const cleanHtml = (text) => {
  if (!text) return '';
  return text.replace(/<[^>]*>/g, '').replace(/&quot;/g, '"').replace(/&amp;/g, '&');
};

/**
 * 格式化视频时长（秒数转 MM:SS 或 HH:MM:SS）
 */
const formatDuration = (seconds) => {
  if (!seconds) return '';
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;

  if (h > 0) {
    return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }
  return `${m}:${s.toString().padStart(2, '0')}`;
};

/**
 * 从 URL 中提取 BVID
 * 支持格式：
 * - BV1xx411c7mD (纯BVID)
 * - https://www.bilibili.com/video/BV1xx411c7mD
 * - https://b23.tv/BV1xx411c7mD
 *
 * @param {string} url - URL 或 BVID
 * @returns {string} BVID 或原字符串（如果不是B站链接）
 */
const extractBvid = (url) => {
  if (!url) return url;

  // 如果已经是BVID格式，直接返回
  if (url.startsWith('BV')) {
    return url;
  }

  // 尝试从 URL 中提取 BVID
  const bvidMatch = url.match(/(BV[a-zA-Z0-9]{10})/);
  return bvidMatch ? bvidMatch[1] : url;
};

/**
 * Phase 3.2: 记录用户行为
 *
 * @param {number} userId - 用户ID
 * @param {string} bvid - 视频 ID
 * @param {string} action - 行为类型 (play, like, skip, share)
 */
const logBehavior = (userId, bvid, action) => {
  try {
    stmt.logUserBehavior.run(userId, bvid, action);
    console.log(`[Behavior Log] User ${userId}: ${action} - ${bvid}`);
  } catch (error) {
    console.error('[Behavior Log] Failed:', error);
  }
};

/**
 * Phase 3.2: 基于用户行为的协同过滤推荐
 *
 * 算法：
 * 1. 查找相似用户喜欢的视频
 * 2. 基于用户最近播放的视频推荐
 * 3. 结合热门度（搜索统计）
 *
 * @param {number} userId - 用户ID
 * @param {number} limit - 推荐数量限制
 * @returns {Array} 推荐结果
 */
const getBehaviorBasedRecommendations = async (userId, limit = 20) => {
  try {
    // 获取相似用户喜欢的视频（协同过滤）
    const similarLikes = stmt.getSimilarUsersLikedVideos.all(userId);

    // 获取用户最近播放的视频
    const recentPlays = stmt.getRecentPlays.all(userId).map(p => p.bvid);

    // 合并并去重
    const candidates = [...new Set([...similarLikes, ...recentPlays])];

    // 从 audio_metadata_cache 获取详细信息
    const recommendations = [];
    for (const bvid of candidates) {
      if (recommendations.length >= limit) break;

      const metadata = db.prepare('SELECT bvid, title, artist, duration, cover_url FROM audio_metadata_cache WHERE bvid = ?').get(bvid);
      if (metadata) {
        recommendations.push(metadata);
      }
    }

    return recommendations;
  } catch (error) {
    console.error('[Behavior Recommendation] Failed:', error);
    throw new Error(`获取行为推荐失败: ${error.message}`);
  }
};

/**
 * Phase 3.2: 混合推荐（热门 + 个性化）
 *
 * 结合用户行为、播放历史和热门内容的综合推荐
 *
 * @param {number} userId - 用户ID
 * @param {number} limit - 推荐数量限制
 * @returns {Object} 推荐结果（包含来源标识）
 */
const getHybridRecommendations = async (userId, limit = 20) => {
  try {
    // 获取用户偏好
    const preferences = stmt.getUserPreferences.all(userId);

    // 统计各类行为次数
    const behaviorCounts = {};
    preferences.forEach(p => {
      behaviorCounts[p.action] = p.count;
    });

    // 1. 基于用户行为推荐 (60%)
    const behaviorRecs = await getBehaviorBasedRecommendations(userId, Math.ceil(limit * 0.6));

    // 2. 基于热门推荐 (40%)
    let hotRecs = [];
    if (behaviorRecs.length < limit) {
      const remaining = limit - behaviorRecs.length;
      const hotPlaylists = await getHotPlaylists(1, Math.ceil(remaining * 0.5));
      const hotRank = await getHotRank(1, Math.ceil(remaining * 0.5));
      const sliceLimit = Math.ceil(remaining * 0.25);

      const playlistItems = (hotPlaylists.playlists || [])
        .flatMap(p => p.previews || [])
        .slice(0, sliceLimit);

      const rankItems = (hotRank.playlists || [])
        .flatMap(p => p.previews || [])
        .slice(0, sliceLimit);

      hotRecs = [...playlistItems, ...rankItems];
    }

    // 3. 去重并添加来源标识
    const allRecs = [...behaviorRecs, ...hotRecs];
    const seen = new Set();
    const finalRecs = [];

    for (const rec of allRecs) {
      if (seen.has(rec.bvid)) continue;
      seen.add(rec.bvid);

      // 标记推荐来源
      let source = 'hot';
      if (behaviorRecs.some(b => b.bvid === rec.bvid)) {
        source = 'behavior';
      }

      finalRecs.push({ ...rec, source });
      if (finalRecs.length >= limit) break;
    }

    return {
      recommendations: finalRecs,
      behaviorStats: behaviorCounts
    };
  } catch (error) {
    console.error('[Hybrid Recommendation] Failed:', error);
    throw new Error(`获取混合推荐失败: ${error.message}`);
  }
};

module.exports = {
  // 常量
  CATEGORY_TIDS,
  // B站音乐服务
  getHotPlaylists,
  getHotRank,
  getPersonalized,
  getByCategory,
  getMusicRecommendation,
  // Phase 3.2: 用户行为推荐
  logBehavior,
  getBehaviorBasedRecommendations,
  getHybridRecommendations,
  // Phase 2B: 音乐区推荐（使用分区最新视频API）
  // API: https://api.bilibili.com/x/web-interface/dynamic/region?rid=3&pn=1&ps=20
  // rid=3 是音乐区tid，无需WBI签名
  getMusicZoneRecommendations: async (userId, page = 1, pageSize = 20) => {
    try {
      // 构建请求头（使用用户Cookie提升稳定性）
      const headers = {};
      if (userId) {
        const cookie = getCookie(userId);
        if (cookie) {
          headers['Cookie'] = cookie;
        }
      }

      const url = `https://api.bilibili.com/x/web-interface/dynamic/region?rid=3&pn=${page}&ps=${pageSize}`;
      console.log('[MusicZone] URL:', url);

      const data = await httpGet(url, headers);
      console.log('[MusicZone] Response code:', data.code);

      if (data.code !== 0) {
        throw new Error(data.message || '获取音乐区推荐失败');
      }

      // 转换数据格式以兼容前端
      const archives = data.data?.archives || [];
      const videos = archives.map(item => ({
        bvid: item.bvid,
        title: cleanHtml(item.title),
        description: cleanHtml(item.desc || ''),
        cover: item.pic.startsWith('//') ? `https:${item.pic}` : item.pic,
        duration: formatDuration(item.duration),
        author: item.owner?.name || 'Unknown',
        playCount: item.stat?.view || 0,  // 前端使用 playCount 字段
        arcurl: `https://www.bilibili.com/video/${item.bvid}`
      }));

      console.log('[MusicZone] Found', videos.length, 'videos');

      return {
        data: videos,
        page: page,
        hasMore: videos.length === pageSize,
        fallback: false,
        source: 'region_api'
      };
    } catch (error) {
      console.error('[MusicZone] API error:', error.message);
      // 返回降级状态
      return {
        data: [],
        page: page,
        hasMore: false,
        fallback: true,
        error: error.message
      };
    }
  },
  // 工具函数
  extractBvid
};
