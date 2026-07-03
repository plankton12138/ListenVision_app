import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/utils/app_logger.dart';
import 'bilibili_headers.dart';

enum BilibiliQRStatus { pending, scanned, expired, success, error }

class BilibiliAccount {
  final String sessdata;
  final String biliJct;
  final String dedeuserid;
  final String? username;
  final String? avatarUrl;

  BilibiliAccount({
    required this.sessdata,
    required this.biliJct,
    required this.dedeuserid,
    this.username,
    this.avatarUrl,
  });
}

class BilibiliAuthService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  BilibiliAuthService({Dio? dio, FlutterSecureStorage? secureStorage})
      : _dio = dio ?? Dio(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _passportUrl = 'https://passport.bilibili.com';

  Future<Map<String, String>> generateQRCode() async {
    final response = await _dio.get(
      '$_passportUrl/x/passport-login/web/qrcode/generate',
      options: Options(headers: bilibiliHeaders),
    );
    final data = response.data['data'];
    if (data == null) throw Exception('生成QR码失败');
    return {
      'qrcode_key': data['qrcode_key']?.toString() ?? '',
      'qr_url': data['url']?.toString() ?? '',
    };
  }

  Future<(BilibiliQRStatus, BilibiliAccount?)> checkQRCode(
    String qrcodeKey,
  ) async {
    try {
      final response = await _dio.get(
        '$_passportUrl/x/passport-login/web/qrcode/poll',
        queryParameters: {'qrcode_key': qrcodeKey},
        options: Options(headers: bilibiliHeaders),
      );
      final data = response.data['data'];
      final code = data?['code'] ?? -1;

      switch (code) {
        case 0:
          final cookies = _extractCookies(response);
          if (cookies['sessdata'] == null) {
            return (BilibiliQRStatus.error, null);
          }
          final account = BilibiliAccount(
            sessdata: cookies['sessdata']!,
            biliJct: cookies['bili_jct'] ?? '',
            dedeuserid: cookies['dedeuserid'] ?? '',
          );
          final userInfo = await _fetchUserInfo(cookies);
          final fullAccount = BilibiliAccount(
            sessdata: account.sessdata,
            biliJct: account.biliJct,
            dedeuserid: account.dedeuserid,
            username: userInfo['name'],
            avatarUrl: userInfo['face'],
          );
          await _saveAccount(fullAccount);
          return (BilibiliQRStatus.success, fullAccount);

        case 86090:
          return (BilibiliQRStatus.scanned, null);

        case 86038:
          return (BilibiliQRStatus.expired, null);

        default:
          return (BilibiliQRStatus.pending, null);
      }
    } catch (e) {
      AppLogger.error('BilibiliAuthService', '检查QR码状态失败: $e');
      return (BilibiliQRStatus.error, null);
    }
  }

  Future<BilibiliAccount?> getStoredAccount() async {
    final sessdata = await _secureStorage.read(key: 'bilibili_sessdata');
    if (sessdata == null || sessdata.isEmpty) return null;
    final biliJct = await _secureStorage.read(key: 'bilibili_jct') ?? '';
    final dedeuserid =
        await _secureStorage.read(key: 'bilibili_dedeuserid') ?? '';
    final username = await _secureStorage.read(key: 'bilibili_username');
    final avatarUrl = await _secureStorage.read(key: 'bilibili_avatar');
    return BilibiliAccount(
      sessdata: sessdata,
      biliJct: biliJct,
      dedeuserid: dedeuserid,
      username: username,
      avatarUrl: avatarUrl,
    );
  }

  Future<void> unbind() async {
    await _secureStorage.delete(key: 'bilibili_sessdata');
    await _secureStorage.delete(key: 'bilibili_jct');
    await _secureStorage.delete(key: 'bilibili_dedeuserid');
    await _secureStorage.delete(key: 'bilibili_username');
    await _secureStorage.delete(key: 'bilibili_avatar');
  }

  Future<bool> isBound() async {
    final account = await getStoredAccount();
    return account != null;
  }

  Future<Map<String, String>?> getStoredCookies() async {
    final account = await getStoredAccount();
    if (account == null) return null;
    return {
      'sessdata': account.sessdata,
      'bili_jct': account.biliJct,
      'dedeuserid': account.dedeuserid,
    };
  }

  Future<void> _saveAccount(BilibiliAccount account) async {
    await _secureStorage.write(
        key: 'bilibili_sessdata', value: account.sessdata);
    await _secureStorage.write(key: 'bilibili_jct', value: account.biliJct);
    await _secureStorage.write(
        key: 'bilibili_dedeuserid', value: account.dedeuserid);
    if (account.username != null) {
      await _secureStorage.write(
          key: 'bilibili_username', value: account.username);
    }
    if (account.avatarUrl != null) {
      await _secureStorage.write(
          key: 'bilibili_avatar', value: account.avatarUrl);
    }
  }

  Map<String, String> _extractCookies(Response response) {
    final result = <String, String>{};
    final setCookie = response.headers['set-cookie'] ?? [];
    for (final header in setCookie) {
      for (final part in header.split(';')) {
        final trimmed = part.trim();
        final eqIdx = trimmed.indexOf('=');
        if (eqIdx == -1) continue;
        final key = trimmed.substring(0, eqIdx);
        final value = trimmed.substring(eqIdx + 1);
        if (key == 'SESSDATA') result['sessdata'] = value;
        if (key == 'bili_jct') result['bili_jct'] = value;
        if (key == 'DedeUserID') result['dedeuserid'] = value;
      }
    }
    return result;
  }

  Future<Map<String, String>> _fetchUserInfo(
      Map<String, String> cookies) async {
    try {
      final cookieStr = cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
      final response = await _dio.get(
        'https://api.bilibili.com/x/web-interface/nav',
        options: Options(headers: {
          ...bilibiliHeaders,
          'Cookie': cookieStr,
        }),
      );
      final data = response.data['data'];
      return {
        'name': data?['uname']?.toString() ?? '',
        'face': data?['face']?.toString() ?? '',
      };
    } catch (_) {
      return {'name': '', 'face': ''};
    }
  }
}
