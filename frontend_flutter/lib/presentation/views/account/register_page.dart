import 'dart:math';

import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_captcha/flutter_captcha.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 注册页面
///
/// 用户注册界面，包含表单验证和验证码功能
/// 使用 Riverpod 的 AuthViewModel 进行状态管理
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _captchaController = FlutterCaptchaController(
    random: Random.secure(),
  )..init();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _captchaController.randomizePositions = false;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  /// 提交注册表单到服务器
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_onCheck()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref.read(authViewModelProvider.notifier).register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注册成功！'), backgroundColor: Colors.green),
        );
        context.go('/');
      } else {
        final authState = ref.read(authViewModelProvider);
        String errorMsg = '注册失败，请稍后重试';
        authState.whenOrNull(
          error: (err, stack) {
            errorMsg = err.toString();
          },
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 检查验证码
  bool _onCheck() {
    if (_captchaController.checkSolution()) {
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('验证码不正确，请完成验证'), backgroundColor: Colors.orange),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '注册',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildForm(),
            _buildCaptcha(),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptcha() {
    return SizedBox(
      height: 300,
      width: 300,
      child: FlutterCaptcha(
        controller: _captchaController,
        crossLine: (color: Colors.white, width: 5),
        fit: BoxFit.cover,
        partsBuilder: (context, part) {
          return ColoredBox(
            color: Colors.red,
            child: part,
          );
        },
        draggingBuilder: (_, child) => Opacity(opacity: 0.5, child: child),
        child: Image.asset('assets/images/1.png'),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: '用户名'),
            validator: (value) {
              if (value == null || value.isEmpty) return '请输入用户名';
              if (value.length < 4) return '用户名长度至少为4位';
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: '密码'),
            validator: (value) {
              if (value == null || value.isEmpty) return '请输入密码';
              if (value.length < 6) return '密码长度至少为6位';
              return null;
            },
          ),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: '邮箱'),
            validator: (value) {
              if (value == null || value.isEmpty) return '请输入邮箱';
              if (!value.contains('@')) return '请输入有效的邮箱地址';
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('注册', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('已有账号？去登录', style: TextStyle(color: Colors.blue)),
          ),
          const Text('提交前请先完成验证码')
        ],
      ),
    );
  }
}
