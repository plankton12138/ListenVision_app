/**
 * DTO (Data Transfer Object) 转换器
 *
 * 统一前后端数据格式，解决字段命名不一致问题
 *
 * 问题场景：
 * - 封面字段：cover / pic / coverUrl / cover_url
 * - 艺术家字段：author / artist / uname
 * - 发布时间：pubdate / published_at / publishedAt
 *
 * 使用方式：
 * const response = AudioResponseDTO.fromBilibili(data);
 */

class BaseDTO {
  /**
   * 统一字段名称映射
   */
  static normalizeField(data, mappings) {
    const result = { ...data };

    for (const [target, sources] of Object.entries(mappings)) {
      for (const source of sources) {
        if (result[source] !== undefined && result[target] === undefined) {
          result[target] = result[source];
          // 保留原始字段？可以选择删除
          // delete result[source];
          break;
        }
      }
    }

    return result;
  }

  /**
   * 转换为响应格式
   */
  static toResponse(data, message = '操作成功') {
    return {
      success: true,
      message,
      data,
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * 转换为错误格式
   */
  static toResponseError(error, statusCode = 400) {
    return {
      success: false,
      error: error.message || '操作失败',
      statusCode,
      timestamp: new Date().toISOString(),
    };
  }
}

/**
 * 音频响应 DTO
 * 统一音频相关的字段命名
 */
class AudioResponseDTO extends BaseDTO {
  /**
   * 从 B站数据转换
   */
  static fromBilibili(bilibiliData) {
    if (!bilibiliData) return null;

    // 字段映射
    const mappings = {
      cover: ['pic', 'coverUrl', 'cover_url', 'cover'],
      artist: ['author', 'uname', 'artist', 'singer'],
      title: ['title', 'name'],
      duration: ['duration', 'length'],
      publishedAt: ['pubdate', 'published_at', 'publishedAt', 'createTime'],
      bvid: ['bvid', 'id'],
    };

    const normalized = this.normalizeField(bilibiliData, mappings);

    // 构建标准响应格式
    return {
      id: normalized.bvid || normalized.id,
      bvid: normalized.bvid || normalized.id,
      title: normalized.title || '未知标题',
      artist: normalized.artist || '未知艺术家',
      cover: normalized.cover || '',
      duration: normalized.duration || 0,
      publishedAt: normalized.publishedAt
        ? new Date(normalized.publishedAt * 1000).toISOString()
        : null,
      // 原始数据（可选，用于调试）
      raw: normalized,
    };
  }

  /**
   * 从数据库记录转换
   */
  static fromDatabase(dbData) {
    if (!dbData) return null;

    return {
      id: dbData.bvid,
      bvid: dbData.bvid,
      title: dbData.title || '未知标题',
      artist: dbData.artist || '未知艺术家',
      cover: dbData.cover || '',
      duration: dbData.duration || 0,
      publishedAt: dbData.created_at || null,
    };
  }

  /**
   * 批量转换
   */
  static fromBilibiliList(list) {
    if (!Array.isArray(list)) return [];
    return list.map(item => this.fromBilibili(item)).filter(Boolean);
  }

  /**
   * 转换为前端期望格式（用于搜索结果）
   */
  static toSearchResult(audioData) {
    const normalized = this.fromBilibili(audioData);
    if (!normalized) return null;

    return {
      ...normalized,
      type: 'audio',
      source: 'bilibili',
      canPlay: true,
      canDownload: true,
    };
  }
}

/**
 * 歌单响应 DTO
 */
class PlaylistResponseDTO extends BaseDTO {
  static fromDatabase(playlistData, items = []) {
    if (!playlistData) return null;

    return {
      id: playlistData.id,
      name: playlistData.name || playlistData.title || '未命名歌单',
      description: playlistData.description || '',
      cover: playlistData.cover || '',
      itemCount: items.length || playlistData.item_count || 0,
      isSystem: playlistData.is_system || false,
      createdAt: playlistData.created_at || null,
      updatedAt: playlistData.updated_at || null,
      items: items.map(item => AudioResponseDTO.fromBilibili(item)),
    };
  }

  static fromList(playlistsData, includeItems = false) {
    if (!Array.isArray(playlistsData)) return [];
    return playlistsData.map(playlist =>
      this.fromDatabase(playlist, includeItems ? playlist.items : [])
    );
  }
}

/**
 * 用户响应 DTO
 */
class UserResponseDTO extends BaseDTO {
  static fromDatabase(userData) {
    if (!userData) return null;

    return {
      id: userData.id,
      username: userData.username,
      email: userData.email,
      avatar: userData.avatar || null,
      createdAt: userData.created_at || null,
      // 不返回敏感信息（密码哈希等）
    };
  }
}

/**
 * 播放历史响应 DTO
 */
class PlayHistoryResponseDTO extends BaseDTO {
  static fromDatabase(historyData) {
    if (!historyData) return null;

    return {
      id: historyData.id,
      title: historyData.title || '未知标题',
      artist: historyData.artist || '未知艺术家',
      cover: historyData.cover_url || '',
      progress: historyData.progress || 0,
      duration: historyData.duration || 0,
      playedAt: historyData.played_at || null,
      bvid: historyData.bvid || null,
      localPath: historyData.local_path || null,
    };
  }

  static fromList(historyList) {
    if (!Array.isArray(historyList)) return [];
    return historyList.map(item => this.fromDatabase(item));
  }
}

/**
 * 推荐内容响应 DTO
 */
class RecommendationResponseDTO extends BaseDTO {
  static fromBilibiliPlaylist(playlistData) {
    if (!playlistData) return null;

    return {
      id: playlistData.id,
      title: playlistData.title,
      cover: playlistData.cover || playlistData.pic || '',
      description: playlistData.description || '',
      itemCount: playlistData.item_count || playlistData.media_count || 0,
      playCount: playlistData.play_count || 0,
      type: 'playlist',
      source: 'bilibili',
    };
  }

  static fromList(list) {
    if (!Array.isArray(list)) return [];
    return list.map(item => this.fromBilibiliPlaylist(item));
  }
}

/**
 * 分页响应 DTO
 */
class PaginatedResponseDTO extends BaseDTO {
  static create({ items, total, page, pageSize, message = '获取成功' }) {
    return {
      success: true,
      message,
      data: items,
      pagination: {
        total,
        page,
        pageSize,
        totalPages: Math.ceil(total / pageSize),
        hasMore: page * pageSize < total,
      },
      timestamp: new Date().toISOString(),
    };
  }
}

/**
 * 搜索建议响应 DTO
 */
class SearchSuggestionDTO extends BaseDTO {
  static fromKeywords(keywords) {
    if (!Array.isArray(keywords)) return [];

    return keywords.map(keyword => ({
      keyword,
      type: 'suggestion',
    }));
  }
}

module.exports = {
  BaseDTO,
  AudioResponseDTO,
  PlaylistResponseDTO,
  UserResponseDTO,
  PlayHistoryResponseDTO,
  RecommendationResponseDTO,
  PaginatedResponseDTO,
  SearchSuggestionDTO,
};
