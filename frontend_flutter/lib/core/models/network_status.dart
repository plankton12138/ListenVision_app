/// 网络连接类型
enum NetworkConnectionType {
  none, // 无网络
  wifi, // WiFi
  mobile, // 移动数据
  ethernet, // 以太网
  bluetooth, // 蓝牙
  vpn, // VPN
  other, // 其他
}

/// 网络状态
class NetworkStatus {
  final bool isConnected;
  final NetworkConnectionType connectionType;
  final DateTime lastUpdated;

  const NetworkStatus({
    required this.isConnected,
    required this.connectionType,
    required this.lastUpdated,
  });

  /// 是否为 WiFi 连接
  bool get isWifi => connectionType == NetworkConnectionType.wifi;

  /// 是否为移动数据连接
  bool get isMobile => connectionType == NetworkConnectionType.mobile;

  /// 获取连接类型描述
  String get connectionDescription {
    switch (connectionType) {
      case NetworkConnectionType.none:
        return '无网络';
      case NetworkConnectionType.wifi:
        return 'WiFi';
      case NetworkConnectionType.mobile:
        return '移动数据';
      case NetworkConnectionType.ethernet:
        return '以太网';
      case NetworkConnectionType.bluetooth:
        return '蓝牙';
      case NetworkConnectionType.vpn:
        return 'VPN';
      case NetworkConnectionType.other:
        return '其他网络';
    }
  }

  /// 创建未连接状态
  static NetworkStatus disconnected() {
    return NetworkStatus(
      isConnected: false,
      connectionType: NetworkConnectionType.none,
      lastUpdated: DateTime.now(),
    );
  }

  /// 创建连接状态
  static NetworkStatus connected(NetworkConnectionType type) {
    return NetworkStatus(
      isConnected: true,
      connectionType: type,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkStatus &&
        other.isConnected == isConnected &&
        other.connectionType == connectionType;
  }

  @override
  int get hashCode => Object.hash(isConnected, connectionType);

  @override
  String toString() {
    return 'NetworkStatus(isConnected: $isConnected, connectionType: $connectionType)';
  }
}
