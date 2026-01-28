import 'package:demo/core/base/base_page.dart';
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/di/service_factory.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 登录页面
///
/// 用户登录界面，支持用户名/密码登录
/// 使用 AsyncUIHandlerMixin 统一处理异步操作和错误
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with BasePageState, AsyncUIHandlerMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  /// 提交登录表单
  ///
  /// 使用 AsyncUIHandlerMixin 的 runAsyncWithState 方法
  /// 自动管理加载状态和错误处理
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await runAsyncWithState(
      operation: () async {
        final authRepository = ServiceFactory.instance.authRepository;
        final result = await authRepository.login(
          email: _usernameController.text,
          password: _passwordController.text,
        );

        result.fold(
          (failure) {
            throw Exception(failure.message ?? '登录失败');
          },
          (user) async {
            if (!mounted) return;
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);

            await authProvider.setUser(user);

            final token = user.token ?? '';
            try {
              if (token.isNotEmpty) {
                await playlistProvider.initialize(token);
                await playlistProvider.loadFavorites(token);
              }
            } catch (e) {
              AppLogger.error('LoginPage', '歌单初始化失败: $e');
            }

            if (mounted) {
              context.go('/');
            }
          },
        );
      },
      isLoadingSetter: (loading) => safeSetState(() {
        _isLoading = loading;
      }),
      successMessage: '登录成功！',
    );
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
          style: TextStyle(fontSize: UIConstants.fontSizeLarge),
        ),
        actions: [
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('登录', style: TextStyle(fontSize: 18, color: Colors.blue)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => context.go('/register'),
              child: const Text('没有账号？去注册', style: TextStyle(fontSize: 18, color: Colors.blue)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => context.go('/reset_password'),
              child: const Text('忘记密码？', style: TextStyle(fontSize: 18, color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}
