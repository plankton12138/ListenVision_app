
/// 推荐内容模型
class RecommendationItem {
  final String? bvid;
  final String? title;
  final String? description;
  final String? cover;
  final String? duration;
  final String? author;
  final int? play;
  final String? arcurl;

  RecommendationItem({
    this.bvid,
    this.title,
    this.description,
    this.cover,
    this.duration,
    this.author,
    this.play,
    this.arcurl,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      bvid: json['bvid'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      cover: json['cover'] as String? ?? json['pic'] as String?,
      // 兼容 int（秒数）和 String（格式化时长）两种格式
      duration: json['duration']?.toString(),
      author: json['author'] as String? ?? json['uname'] as String?,
      play: json['play'] is int ? json['play'] as int? : int.tryParse(json['play']?.toString() ?? ''),
      arcurl: json['arcurl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bvid': bvid,
      'title': title,
      'description': description,
      'cover': cover,
      'duration': duration,
      'author': author,
      'play': play,
      'arcurl': arcurl,
    };
  }

  /// 格式化时长显示
  /// 如果 duration 是秒数（如 "180"），转换为 "03:00" 格式
  /// 如果已经是格式化字符串（如 "03:00"），直接返回
  String get formattedDuration {
    if (duration == null || duration!.isEmpty) return '--:--';

    // 尝试解析为整数（秒数）
    final seconds = int.tryParse(duration!);
    if (seconds != null) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    // 已经是格式化字符串，直接返回
    return duration!;
  }
}

/// B站热门歌单/榜单模型
class BiliPlaylist {
  final int menuId;
  final int? uid;
  final String? uname;
  final String title;
  final String? cover;
  final String? intro;
  final int? type;
  final int songCount;
  final BiliPlaylistStatistic statistic;
  final List<BiliAudioPreview>? previews;

  BiliPlaylist({
    required this.menuId,
    this.uid,
    this.uname,
    required this.title,
    this.cover,
    this.intro,
    this.type,
    required this.songCount,
    required this.statistic,
    this.previews,
  });

  factory BiliPlaylist.fromJson(Map<String, dynamic> json) {
    final previewsJson = json['previews'] as List?;
    return BiliPlaylist(
      menuId: json['menuId'] as int,
      uid: json['uid'] as int?,
      uname: json['uname'] as String?,
      title: json['title'] as String,
      cover: json['cover'] as String?,
      intro: json['intro'] as String?,
      type: json['type'] as int?,
      songCount: json['songCount'] as int? ?? json['snum'] as int? ?? 0,
      statistic: BiliPlaylistStatistic.fromJson(json['statistic'] as Map<String, dynamic>? ?? {}),
      previews: previewsJson?.map((p) => BiliAudioPreview.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuId': menuId,
      'uid': uid,
      'uname': uname,
      'title': title,
      'cover': cover,
      'intro': intro,
      'type': type,
      'songCount': songCount,
      'statistic': statistic.toJson(),
      if (previews != null) 'previews': previews?.map((p) => p.toJson()).toList(),
    };
  }

  /// 格式化播放次数
  String get formattedPlayCount {
    if (statistic.play < 1000) return statistic.play.toString();
    if (statistic.play < 10000) return '${(statistic.play / 1000).toStringAsFixed(1)}k';
    if (statistic.play < 100000000) return '${(statistic.play / 10000).toStringAsFixed(1)}w';
    return '${(statistic.play / 100000000).toStringAsFixed(1)}亿';
  }
}

/// B站歌单统计信息
class BiliPlaylistStatistic {
  final int play;
  final int collect;
  final int comment;
  final int share;

  BiliPlaylistStatistic({
    this.play = 0,
    this.collect = 0,
    this.comment = 0,
    this.share = 0,
  });

  factory BiliPlaylistStatistic.fromJson(Map<String, dynamic> json) {
    return BiliPlaylistStatistic(
      play: json['play'] as int? ?? 0,
      collect: json['collect'] as int? ?? 0,
      comment: json['comment'] as int? ?? 0,
      share: json['share'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'play': play,
      'collect': collect,
      'comment': comment,
      'share': share,
    };
  }
}

/// B站音频预览（榜单中的歌曲预览）
class BiliAudioPreview {
  final int id;
  final String title;
  final int? duration;

  BiliAudioPreview({
    required this.id,
    required this.title,
    this.duration,
  });

  factory BiliAudioPreview.fromJson(Map<String, dynamic> json) {
    return BiliAudioPreview(
      id: json['id'] as int,
      title: json['title'] as String,
      duration: json['duration'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
    };
  }

  /// 格式化时长
  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 热门歌单/榜单响应
class BiliPlaylistsResponse {
  final List<BiliPlaylist> playlists;
  final int page;
  final int pageSize;
  final int total;

  BiliPlaylistsResponse({
    required this.playlists,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory BiliPlaylistsResponse.fromJson(Map<String, dynamic> json) {
    final playlistsJson = json['playlists'] as List?;
    return BiliPlaylistsResponse(
      playlists: playlistsJson?.map((p) => BiliPlaylist.fromJson(p as Map<String, dynamic>)).toList() ?? [],
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playlists': playlists.map((p) => p.toJson()).toList(),
      'page': page,
      'pageSize': pageSize,
      'total': total,
    };
  }
}

/// 个性化推荐响应
class PersonalizedResponse {
  final String source; // 'hot' 或 'personalized'
  final List<String>? keywords;
  final List<RecommendationItem>? videos;
  final List<BiliPlaylist>? playlists;

  PersonalizedResponse({
    required this.source,
    this.keywords,
    this.videos,
    this.playlists,
  });

  factory PersonalizedResponse.fromJson(Map<String, dynamic> json) {
    final videosJson = json['videos'] as List?;
    final playlistsJson = json['playlists'] as List?;
    final keywordsJson = json['keywords'] as List?;

    return PersonalizedResponse(
      source: json['source'] as String? ?? 'unknown',
      keywords: keywordsJson?.map((k) => k.toString()).toList(),
      videos: videosJson?.map((v) => RecommendationItem.fromJson(v as Map<String, dynamic>)).toList(),
      playlists: playlistsJson?.map((p) => BiliPlaylist.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      if (keywords != null) 'keywords': keywords,
      if (videos != null) 'videos': videos?.map((v) => v.toJson()).toList(),
      if (playlists != null) 'playlists': playlists?.map((p) => p.toJson()).toList(),
    };
  }
}

/// 分区推荐响应
class CategoryRecommendationResponse {
  final int tid;
  final List<RecommendationItem> videos;
  final int page;
  final int pageSize;
  final int total;

  CategoryRecommendationResponse({
    required this.tid,
    required this.videos,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory CategoryRecommendationResponse.fromJson(Map<String, dynamic> json) {
    final videosJson = json['videos'] as List?;
    return CategoryRecommendationResponse(
      tid: json['tid'] as int,
      videos: videosJson?.map((v) => RecommendationItem.fromJson(v as Map<String, dynamic>)).toList() ?? [],
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tid': tid,
      'videos': videos.map((v) => v.toJson()).toList(),
      'page': page,
      'pageSize': pageSize,
      'total': total,
    };
  }
}

/// 音乐区综合推荐响应
class MusicRecommendationResponse {
  final List<CategoryRecommendation> categories;

  MusicRecommendationResponse({
    required this.categories,
  });

  factory MusicRecommendationResponse.fromJson(List<dynamic> json) {
    return MusicRecommendationResponse(
      categories: json.map((c) => CategoryRecommendation.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((c) => c.toJson()).toList(),
    };
  }
}

/// 单个分类的推荐
class CategoryRecommendation {
  final String category;
  final int tid;
  final List<RecommendationItem> videos;

  CategoryRecommendation({
    required this.category,
    required this.tid,
    required this.videos,
  });

  factory CategoryRecommendation.fromJson(Map<String, dynamic> json) {
    final videosJson = json['videos'] as List?;
    return CategoryRecommendation(
      category: json['category'] as String,
      tid: json['tid'] as int,
      videos: videosJson?.map((v) => RecommendationItem.fromJson(v as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'tid': tid,
      'videos': videos.map((v) => v.toJson()).toList(),
    };
  }
}
