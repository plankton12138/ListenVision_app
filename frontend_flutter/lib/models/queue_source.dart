/// 队列来源类型
enum SourceType {
  /// 用户歌单
  userPlaylist,

  /// 收藏
  favorites,

  /// 播放历史
  history,

  /// 搜索结果
  search,

  /// 手动添加
  manual,
}

/// 队列来源
///
/// 用于记录当前播放队列的来源，方便用户追溯和跳转
class QueueSource {
  /// 来源ID（歌单ID、搜索关键词等）
  final String id;

  /// 来源名称（显示用）
  final String name;

  /// 封面URL（可选）
  final String? coverUrl;

  /// 来源类型
  final SourceType type;

  const QueueSource({
    required this.id,
    required this.name,
    this.coverUrl,
    required this.type,
  });

  /// 用户歌单
  factory QueueSource.userPlaylist(
    String id,
    String name, {
    String? coverUrl,
  }) {
    return QueueSource(
      id: id,
      name: name,
      coverUrl: coverUrl,
      type: SourceType.userPlaylist,
    );
  }

  /// 收藏
  factory QueueSource.favorites() {
    return const QueueSource(
      id: 'favorites',
      name: '我喜欢的音乐',
      type: SourceType.favorites,
    );
  }

  /// 播放历史
  factory QueueSource.history() {
    return const QueueSource(
      id: 'history',
      name: '播放历史',
      type: SourceType.history,
    );
  }

  /// 搜索结果
  factory QueueSource.search(String query) {
    return QueueSource(
      id: 'search_$query',
      name: '搜索: $query',
      type: SourceType.search,
    );
  }

  /// 手动添加
  factory QueueSource.manual() {
    return const QueueSource(
      id: 'manual',
      name: '手动添加',
      type: SourceType.manual,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coverUrl': coverUrl,
      'type': type.name,
    };
  }

  /// 从 JSON 创建
  factory QueueSource.fromJson(Map<String, dynamic> json) {
    return QueueSource(
      id: json['id'] as String,
      name: json['name'] as String,
      coverUrl: json['coverUrl'] as String?,
      type: SourceType.values.firstWhere(
        (e) => e.name == json['type'] as String?,
        orElse: () => SourceType.manual,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QueueSource && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'QueueSource(id: $id, name: $name, type: $type)';
  }
}
