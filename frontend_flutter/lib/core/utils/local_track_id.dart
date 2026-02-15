/// 本地音频统一业务 ID
///
/// 规则：local_{hash(normalizedPath)}
/// - normalizedPath：统一分隔符为 "\\"，并转小写（Windows 路径大小写不敏感）
String localIdFromPath(String filePath) {
  final normalized = filePath.replaceAll('/', '\\').toLowerCase();
  return 'local_${normalized.hashCode}';
}
