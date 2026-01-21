import 'dart:io';

import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/errors/exceptions.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/services/api_service.dart';
// P2: 组件已迁移到 presentation/widgets/
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 登录页面
///
/// 用户登录界面，支持用户名/密码登录
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 表单验证key
  final _formKey = GlobalKey<FormState>();

  // 用户名和密码输入控制器
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  /// 提交登录表单
  Future<void> _submit() async {
    // 验证表单
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final user = await apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.setUser(user);

      // 初始化歌单Provider
      final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
      try {
        await playlistProvider.initialize(user.token);
        await playlistProvider.loadFavorites(user.token);
      } catch (e) {
        // 歌单初始化失败不影响登录
        debugPrint('歌单初始化失败: $e');
      }

      if (mounted) {
        showMySnackBar(context, '登录成功！', Colors.green, 1000);
        context.go('/');
      }
    } catch (e) {
      if (e is ApiException) {
        String errorMessage = e.message;
        if (e.statusCode == 401) errorMessage = '用户名或密码无效';
        showMySnackBar(context, errorMessage, Colors.red, 1000);
      } else if (e is SocketException) {
        showMySnackBar(context, '连接被拒绝或网络错误', Colors.red, 1000);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '登录',
          style: TextStyle(
            fontSize: UIConstants.fontSizeLarge,
          ),
        ),
        actions: <Widget>[
          // 返回首页按钮
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: UIConstants.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),

      drawer: const MyDrawer(),

      body: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 用户名输入框
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入用户名';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 密码输入框
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                if (value.length < 6) {
                  return '密码长度至少为6位';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 登录按钮
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                      '登录',
                      style: TextStyle(fontSize: 18, color: Colors.blue),
                    ),
            ),

            // 注册按钮
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => context.go('/register'),
              child: const Text(
                '没有账号？去注册',
                style: TextStyle(fontSize: 18, color: Colors.blue),
              ),
            ),

            // 忘记密码按钮
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => context.go('/reset_password'),
              child: const Text(
                '忘记密码？',
                style: TextStyle(fontSize: 18, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
