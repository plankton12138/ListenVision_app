/**
 * 音乐区爬虫服务（Phase 2B）
 *
 * 功能：爬取 bilibili.com/c/music 页面获取用户绑定的B站账户的个性化推荐内容
 *
 * 技术选型：
 * - axios + cheerio（轻量级HTML解析）
 * - 优势：无需浏览器，性能高
 * - 劣势：只能解析静态HTML
 *
 * @module musicCrawlerService
 */

const axios = require('axios');
const cheerio = require('cheerio');
const { getCookie } = require('./bilibiliService');

// ==================== 配置常量 ====================

const USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
const REFERER = 'https://www.bilibili.com';
const BASE_URL = 'https://www.bilibili.com/c/music';
const REQUEST_TIMEOUT = 10000; // 10秒超时

// ==================== 工具函数 ====================

/**
 * 解析播放量（如 "10.5万" -> 10500）
 *
 * @param {string} text - 播放量文本
 * @returns {number} 解析后的数字
 */
const parseCount = (text) => {
  if (!text) return 0;

  // 移除所有空白字符
  const cleaned = text.replace(/\s/g, '');

  // 处理 "万" 单位 (如 10.5万 -> 10500)
  const matchWan = cleaned.match(/([\d.]+)万/);
  if (matchWan) {
    return Math.floor(parseFloat(matchWan[1]) * 10000);
  }

  // 处理 "千" 单位 (如 1.2千 -> 1200)
  const matchQian = cleaned.match(/([\d.]+)千/);
  if (matchQian) {
    return Math.floor(parseFloat(matchQian[1]) * 1000);
  }

  // 纯数字
  const matchNum = cleaned.match(/\d+/);
  if (matchNum) {
    return parseInt(matchNum[0], 10);
  }

  return 0;
};

/**
 * 从 URL 中提取 BVID
 *
 * @param {string} url - 视频 URL
 * @returns {string|null} BVID
 */
const extractBvid = (url) => {
  if (!url) return null;

  // 尝试匹配 BV 开头的ID
  const match = url.match(/(BV[a-zA-Z0-9]{10})/);
  return match ? match[1] : null;
};

// ==================== 核心爬虫方法 ====================

/**
 * 爬取B站音乐区页面
 *
 * @param {number} userId - 用户ID（用于获取Cookie）
 * @param {number} page - 页码
 * @param {number} pageSize - 每页数量
 * @returns {Object} 爬取结果
 */
const crawlMusicPage = async (userId, page = 1, pageSize = 20) => {
  try {
    // 获取用户绑定的B站 Cookie
    const cookie = getCookie(userId);

    if (!cookie) {
      throw new Error('请先绑定B站账号');
    }

    const url = `${BASE_URL}?pn=${page}`;

    console.log(`[MusicCrawler] Crawling: ${url}`);

    const response = await axios.get(url, {
      headers: {
        'User-Agent': USER_AGENT,
        'Cookie': cookie,
        'Referer': REFERER,
      },
      timeout: REQUEST_TIMEOUT,
    });

    if (response.status !== 200) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const $ = cheerio.load(response.data);
    const items = [];

    // B站音乐区页面结构（可能需要根据实际页面调整）
    // 尝试多种可能的选择器
    const selectors = [
      '.bili-video-card', // 新版卡片样式
      '.video-card',       // 旧版卡片样式
      '.rcmd-item',        // 推荐项样式
    ];

    let matchedSelector = null;
    for (const selector of selectors) {
      if ($(selector).length > 0) {
        matchedSelector = selector;
        break;
      }
    }

    if (!matchedSelector) {
      console.warn('[MusicCrawler] No matching selector found, page structure may have changed');
      return {
        success: true,
        data: [],
        page: page,
        hasMore: false,
        message: '未找到视频卡片，页面结构可能已变化'
      };
    }

    $(matchedSelector).each((index, element) => {
      if (items.length >= pageSize) return false; // 跳出循环

      const $el = $(element);

      // 提取标题
      const titleEl = $el.find('.bili-video-card__info--tit, .title a, a[title]');
      const title = titleEl.attr('title') || titleEl.text().trim();

      // 提取链接和 BVID
      const href = $el.find('a').first().attr('href') || '';
      const bvid = extractBvid(href);

      // 提取封面
      const cover = $el.find('img').attr('data-src') ||
                    $el.find('img').attr('src') ||
                    $el.find('img').attr('data-lazy-src');

      // 提取作者
      const author = $el.find('.bili-video-card__info--author, .author, .up-name').text().trim();

      // 提取播放量
      const playCountEl = $el.find('.bili-video-card__stats--item, .play-count, .stats-view');
      const playCountText = playCountEl.first().text();
      const playCount = parseCount(playCountText);

      // 提取时长
      const duration = $el.find('.bili-video-card__stats__duration, .duration').text().trim();

      // 提取视频链接
      const arcurl = href.startsWith('http') ? href : (`https:${href}`.replace('//', '/'));

      if (bvid && title) {
        items.push({
          bvid,
          title: title.replace(/<[^>]*>/g, ''), // 清理可能的HTML标签
          cover: cover ? (cover.startsWith('//') ? `https:${cover}` : cover) : null,
          author: author || 'Unknown',
          playCount,
          duration,
          arcurl,
        });
      }
    });

    console.log(`[MusicCrawler] Found ${items.length} items`);

    return {
      success: true,
      data: items,
      page: page,
      hasMore: items.length === pageSize,
    };
  } catch (error) {
    console.error('[MusicCrawler] Error:', error.message);

    // 网络错误时返回失败状态
    if (error.code === 'ECONNABORTED') {
      throw new Error('爬取超时，请检查网络连接');
    }

    if (error.response) {
      throw new Error(`B站返回错误: HTTP ${error.response.status}`);
    }

    throw new Error(`爬取音乐区失败: ${error.message}`);
  }
};

/**
 * 爬取B站音乐区页面（带降级方案）
 *
 * 如果爬取失败，回退到热门歌单API
 *
 * @param {number} userId - 用户ID
 * @param {number} page - 页码
 * @param {number} pageSize - 每页数量
 * @returns {Object} 爬取结果
 */
const crawlMusicPageWithFallback = async (userId, page = 1, pageSize = 20) => {
  try {
    return await crawlMusicPage(userId, page, pageSize);
  } catch (error) {
    console.warn('[MusicCrawler] Crawling failed, using fallback:', error.message);

    // 降级方案：返回空结果，调用方可以决定是否使用热门歌单
    return {
      success: false,
      data: [],
      page: page,
      hasMore: false,
      error: error.message,
      fallback: true,
    };
  }
};

module.exports = {
  // 核心方法
  crawlMusicPage,
  crawlMusicPageWithFallback,
  // 工具函数
  parseCount,
  extractBvid,
};
