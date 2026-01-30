import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/domain/entities/user.dart';
import 'package:demo/core/network/dio_provider.dart';
import 'package:mocktail/mocktail.dart';

/// Mock DioProvider 用于模拟 updateToken 调用
class MockDioProvider extends Mock implements DioProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider', () {
    late AuthProvider authProvider;

    // 测试用用户数据
    final testUser = User(
      id: '123',
      username: 'testuser',
      email: 'test@example.com',
      token: 'test_jwt_token',
    );

    final testUserJson = jsonEncode({
      'id': '123',
      'username': 'testuser',
      'email': 'test@example.com',
      'token': 'test_jwt_token',
    });

    setUp(() {
      // 每次测试前清空 SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    group('初始化状态', () {
      test('初始状态应该是未登录', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        // 等待 _loadUser 完成
        await Future.delayed(const Duration(milliseconds: 100));

        expect(authProvider.user, isNull);
        expect(authProvider.isLoggedIn, false);
      });

      test('初始时 user getter 应该返回 null', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(authProvider.user, isNull);
      });

      test('初始时 isLoggedIn 应该返回 false', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(authProvider.isLoggedIn, false);
      });
    });

    group('setUser', () {
      test('setUser 应该保存用户信息到 SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));
        await authProvider.setUser(testUser);

        // 验证用户信息已保存
        final prefs = await SharedPreferences.getInstance();
        final savedUserData = prefs.getString('user_data');

        expect(savedUserData, isNotNull);
        expect(savedUserData, testUserJson);
      });

      test('setUser 应该更新 user 状态', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));
        await authProvider.setUser(testUser);

        expect(authProvider.user, isNotNull);
        expect(authProvider.user?.id, '123');
        expect(authProvider.user?.username, 'testuser');
        expect(authProvider.user?.email, 'test@example.com');
        expect(authProvider.user?.token, 'test_jwt_token');
      });

      test('setUser 后 isLoggedIn 应该返回 true', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));
        await authProvider.setUser(testUser);

        expect(authProvider.isLoggedIn, true);
      });

      test('setUser 应该保存 token 到单独的存储', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));
        await authProvider.setUser(testUser);

        final prefs = await SharedPreferences.getInstance();
        final savedToken = prefs.getString('auth_token');

        expect(savedToken, 'test_jwt_token');
      });

      test('setUser 应该调用 DioProvider.updateToken', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        // 验证 updateToken 被调用（通过检查 Dio 实例的 headers）
        final currentTokenBefore = DioProvider.instance.currentToken;
        expect(currentTokenBefore, isNull);

        await authProvider.setUser(testUser);

        final currentTokenAfter = DioProvider.instance.currentToken;
        expect(currentTokenAfter, 'test_jwt_token');
      });

      test('setUser 没有 token 时不应该调用 updateToken', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        final userWithoutToken = User(
          id: '456',
          username: 'notoken',
        );

        await authProvider.setUser(userWithoutToken);

        final currentToken = DioProvider.instance.currentToken;
        expect(currentToken, isNull);
      });

      test('setUser 应该触发 notifyListeners', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        var listenerCalled = false;
        authProvider.addListener(() {
          listenerCalled = true;
        });

        await authProvider.setUser(testUser);

        expect(listenerCalled, true);
      });

      test('setUser 应该正确序列化所有用户字段', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        final fullUser = User(
          id: '789',
          username: 'fulluser',
          email: 'full@example.com',
          avatarUrl: 'https://example.com/avatar.jpg',
          token: 'full_jwt_token',
        );

        await authProvider.setUser(fullUser);

        final prefs = await SharedPreferences.getInstance();
        final savedUserData = prefs.getString('user_data');
        final decodedJson = jsonDecode(savedUserData!);

        expect(decodedJson['id'], '789');
        expect(decodedJson['username'], 'fulluser');
        expect(decodedJson['email'], 'full@example.com');
        expect(decodedJson['token'], 'full_jwt_token');
      });
    });

    group('logout', () {
      test('logout 应该清除 user 状态', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));
        await authProvider.setUser(testUser);

        expect(authProvider.isLoggedIn, true);

        await authProvider.logout();

        expect(authProvider.user, isNull);
        expect(authProvider.isLoggedIn, false);
      });

      test('logout 应该清除 SharedPreferences 中的用户数据', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));
        await authProvider.setUser(testUser);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('user_data'), isNotNull);

        await authProvider.logout();

        expect(prefs.getString('user_data'), isNull);
      });

      test('logout 应该清除 token', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));
        await authProvider.setUser(testUser);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_token'), 'test_jwt_token');

        await authProvider.logout();

        expect(prefs.getString('auth_token'), isNull);
      });

      test('logout 应该调用 DioProvider.updateToken(null)', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));
        await authProvider.setUser(testUser);

        expect(DioProvider.instance.currentToken, 'test_jwt_token');

        await authProvider.logout();

        expect(DioProvider.instance.currentToken, isNull);
      });

      test('logout 应该触发 notifyListeners', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));
        await authProvider.setUser(testUser);

        var listenerCalled = false;
        authProvider.addListener(() {
          listenerCalled = true;
        });

        await authProvider.logout();

        expect(listenerCalled, true);
      });

      test('logout 在未登录状态调用应该是安全的', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(authProvider.isLoggedIn, false);

        // 未登录时调用 logout 不应该抛出异常
        await authProvider.logout();

        expect(authProvider.user, isNull);
        expect(authProvider.isLoggedIn, false);
      });
    });

    group('_loadUser', () {
      test('_loadUser 应该从 SharedPreferences 恢复用户数据', () async {
        SharedPreferences.setMockInitialValues({
          'user_data': testUserJson,
          'auth_token': 'test_jwt_token',
        });

        authProvider = AuthProvider();

        // 等待 _loadUser 完成
        await Future.delayed(const Duration(milliseconds: 100));

        expect(authProvider.user, isNotNull);
        expect(authProvider.user?.id, '123');
        expect(authProvider.user?.username, 'testuser');
        expect(authProvider.user?.email, 'test@example.com');
        expect(authProvider.user?.token, 'test_jwt_token');
      });

      test('_loadUser 恢复用户后 isLoggedIn 应该为 true', () async {
        SharedPreferences.setMockInitialValues({
          'user_data': testUserJson,
          'auth_token': 'test_jwt_token',
        });

        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(authProvider.isLoggedIn, true);
      });

      test('_loadUser 应该恢复 token 到 DioProvider', () async {
        SharedPreferences.setMockInitialValues({
          'user_data': testUserJson,
          'auth_token': 'test_jwt_token',
        });

        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(DioProvider.instance.currentToken, 'test_jwt_token');
      });

      test('_loadUser 没有存储数据时应该保持未登录状态', () async {
        SharedPreferences.setMockInitialValues({});

        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(authProvider.user, isNull);
        expect(authProvider.isLoggedIn, false);
      });

      test('_loadUser 应该兼容旧格式中 id 为 int 的情况', () async {
        final oldFormatJson = jsonEncode({
          'id': 123, // int 类型（旧格式）
          'username': 'olduser',
          'email': 'old@example.com',
          'token': 'old_jwt_token',
        });

        SharedPreferences.setMockInitialValues({
          'user_data': oldFormatJson,
          'auth_token': 'old_jwt_token',
        });

        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(authProvider.user, isNotNull);
        // User 实体要求 id 为 String，应该被转换
        expect(authProvider.user?.id, '123');
        expect(authProvider.user?.username, 'olduser');
      });

      test('_loadUser 恢复的用户没有 token 时不应该更新 Dio', () async {
        final userWithoutTokenJson = jsonEncode({
          'id': '456',
          'username': 'notoken',
          'email': 'notoken@example.com',
        });

        SharedPreferences.setMockInitialValues({
          'user_data': userWithoutTokenJson,
        });

        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        expect(authProvider.user, isNotNull);
        expect(DioProvider.instance.currentToken, isNull);
      });
    });

    group('完整流程测试', () {
      test('登录 -> 重启应用 -> 登出 完整流程', () async {
        // 1. 登录
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));
        await authProvider.setUser(testUser);

        expect(authProvider.isLoggedIn, true);
        expect(DioProvider.instance.currentToken, 'test_jwt_token');

        // 2. 模拟应用重启：重新创建 AuthProvider
        SharedPreferences.setMockInitialValues({
          'user_data': testUserJson,
          'auth_token': 'test_jwt_token',
        });

        final newAuthProvider = AuthProvider();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newAuthProvider.isLoggedIn, true);
        expect(DioProvider.instance.currentToken, 'test_jwt_token');

        // 3. 登出
        await newAuthProvider.logout();

        expect(newAuthProvider.isLoggedIn, false);
        expect(newAuthProvider.user, isNull);
        expect(DioProvider.instance.currentToken, isNull);

        // 4. 验证存储已清除
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('user_data'), isNull);
        expect(prefs.getString('auth_token'), isNull);
      });

      test('多次登录应该覆盖之前的用户数据', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        // 第一次登录
        final user1 = User(
          id: '111',
          username: 'user1',
          email: 'user1@example.com',
          token: 'token1',
        );

        await authProvider.setUser(user1);

        expect(authProvider.user?.id, '111');
        expect(DioProvider.instance.currentToken, 'token1');

        // 第二次登录
        final user2 = User(
          id: '222',
          username: 'user2',
          email: 'user2@example.com',
          token: 'token2',
        );

        await authProvider.setUser(user2);

        expect(authProvider.user?.id, '222');
        expect(DioProvider.instance.currentToken, 'token2');

        // 验证存储中只有第二次的用户数据
        final prefs = await SharedPreferences.getInstance();
        final savedUserData = prefs.getString('user_data');
        final decodedJson = jsonDecode(savedUserData!);

        expect(decodedJson['id'], '222');
        expect(decodedJson['username'], 'user2');
        expect(prefs.getString('auth_token'), 'token2');
      });

      test('切换用户后的状态应该正确', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        // 用户 A 登录
        final userA = User(
          id: 'aaa',
          username: 'userA',
          token: 'tokenA',
        );

        await authProvider.setUser(userA);
        expect(authProvider.user?.username, 'userA');
        expect(authProvider.isLoggedIn, true);

        // 用户 A 登出
        await authProvider.logout();
        expect(authProvider.isLoggedIn, false);

        // 用户 B 登录
        final userB = User(
          id: 'bbb',
          username: 'userB',
          token: 'tokenB',
        );

        await authProvider.setUser(userB);
        expect(authProvider.user?.username, 'userB');
        expect(authProvider.isLoggedIn, true);
        expect(DioProvider.instance.currentToken, 'tokenB');
      });
    });

    group('边界情况和异常处理', () {
      test('处理损坏的 JSON 数据', () async {
        SharedPreferences.setMockInitialValues({
          'user_data': 'invalid json{{{{',
        });

        authProvider = AuthProvider();

        // 等待 _loadUser 完成
        await Future.delayed(const Duration(milliseconds: 100));

        // 应该保持未登录状态，不抛出异常
        expect(authProvider.isLoggedIn, false);
        expect(authProvider.user, isNull);
      });

      test('处理缺少必需字段的 JSON', () async {
        final incompleteJson = jsonEncode({
          'username': 'incomplete',
          // 缺少 id 字段
        });

        SharedPreferences.setMockInitialValues({
          'user_data': incompleteJson,
        });

        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        // User.fromJson 可能会失败，AuthProvider 应该保持未登录状态
        expect(authProvider.isLoggedIn, false);
      });

      test('setUser 传入相同的用户应该正常工作', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        await authProvider.setUser(testUser);
        await authProvider.setUser(testUser); // 再次设置相同用户

        expect(authProvider.user, isNotNull);
        expect(authProvider.isLoggedIn, true);
      });

      test('连续调用 logout 应该是安全的', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));
        await authProvider.setUser(testUser);

        await authProvider.logout();
        await authProvider.logout();
        await authProvider.logout();

        expect(authProvider.isLoggedIn, false);
        expect(authProvider.user, isNull);
      });
    });

    group('状态通知测试', () {
      test('setUser 和 logout 都应该触发 notifyListeners', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        var callCount = 0;
        authProvider.addListener(() {
          callCount++;
        });

        // setUser 触发一次
        await authProvider.setUser(testUser);
        expect(callCount, 1);

        // logout 再触发一次
        await authProvider.logout();
        expect(callCount, 2);
      });

      test('多个监听器应该都能收到通知', () async {
        SharedPreferences.setMockInitialValues({});
        authProvider = AuthProvider();

        await Future.delayed(const Duration(milliseconds: 100));

        var listener1Called = false;
        var listener2Called = false;

        authProvider.addListener(() {
          listener1Called = true;
        });

        authProvider.addListener(() {
          listener2Called = true;
        });

        await authProvider.setUser(testUser);

        expect(listener1Called, true);
        expect(listener2Called, true);
      });
    });
  });
}
