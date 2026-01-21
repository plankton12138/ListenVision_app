import 'dart:io';
import 'dart:math';

import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/errors/exceptions.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/services/api_service.dart';
// P2: 组件已迁移到 presentation/widgets/
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:demo/core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_captcha/flutter_captcha.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 注册页面
///
/// 用户注册界面，包含表单验证和验证码功能
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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
    // 初始化时设置验证码不随机化位置
    _captchaController.randomizePositions = false;
  }

  /// 提交注册表单到服务器
  Future<void> _submit() async {
    // 验证表单
    if (!_formKey.currentState!.validate()) return;
    // 检查验证码是否正确
    if (!_onCheck(context)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final user = await apiService.register(
        _usernameController.text,
        _passwordController.text,
        _emailController.text,
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.setUser(user);

      if (mounted) {
        showMySnackBar(context, '注册成功！', Colors.green, 2000);
        context.go('/');
      }
    } catch (e) {
      // 停止加载状态
      setState(() => _isLoading = false);

      // 在 setState 外部显示 SnackBar
      if (!mounted) return;

      if (e is ApiException) {
        String errorMessage = e.message;
        if (e.statusCode == 409) {
          errorMessage = '用户名或邮箱已存在';
        }
        showMySnackBar(context, errorMessage, Colors.red, 3000);
      } else if (e is SocketException) {
        showMySnackBar(context, '连接被拒绝或网络错误，请检查后端是否启动', Colors.red, 3000);
      } else {
        // 通用错误处理（如 FormatException 等）
        showMySnackBar(context, '注册失败: $e', Colors.red, 3000);
      }
    } finally {
      // 确保加载状态被重置（如果 try 块成功）
      if (_isLoading && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 检查验证码
  bool _onCheck(BuildContext context) {
    if (_captchaController.checkSolution()) {
      return true;
    }

    showMySnackBar(context, '验证码不正确，请完成验证', Colors.red, 1000);
    return false;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '注册',
          style: TextStyle(
            fontSize: UIConstants.fontSizeLarge,
          ),
        ),
        actions: <Widget>[
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
                : const Text(
                    '注册',
                    style: TextStyle(color: Colors.blue),
                  ),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text(
              '已有账号？去登录',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          // 提示用户完成验证码
          const Text('提交前请先完成验证码')
        ],
      ),
    );
  }
}
