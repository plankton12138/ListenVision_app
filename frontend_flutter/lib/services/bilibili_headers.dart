const Map<String, String> bilibiliHeaders = {
  'Referer': 'https://www.bilibili.com/',
  'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};

String normalizeBilibiliUrl(String url) {
  if (url.startsWith('//')) {
    return 'https:$url';
  }
  return url;
}

int parseBilibiliDuration(String? durationStr) {
  if (durationStr == null || durationStr.isEmpty) return 0;
  try {
    final parts = durationStr.split(':');
    if (parts.length == 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } else if (parts.length == 3) {
      return int.parse(parts[0]) * 3600 +
          int.parse(parts[1]) * 60 +
          int.parse(parts[2]);
    }
    return 0;
  } catch (_) {
    return 0;
  }
}
