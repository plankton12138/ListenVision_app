import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/presentation/providers.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 重置密码页面
///
/// 通过邮箱验证码重置用户密码
/// 使用 Riverpod 的 AuthViewModel 进行状态管理
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _usernameController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '重置密码',
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
          children: [
            _buildSendCodeForm(),
            _buildResetPasswordForm(),
          ],
        ),
      ),
    );
  }

  /// 构建发送验证码表单
  Widget _buildSendCodeForm() {
    final _formKey = GlobalKey<FormState>();
    return Column(
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入用户名';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16.0),

        ElevatedButton(
          onPressed: _isLoading ? null : () => _sendCode(_formKey),
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('发送重置验证码邮件', style: TextStyle(color: Colors.blue)),
        ),

        TextButton(
          child: const Text('返回登录', style: TextStyle(color: Colors.blue)),
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  /// 构建重置密码表单
  Widget _buildResetPasswordForm() {
    final _formKey = GlobalKey<FormState>();
    return Column(
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: '验证码',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入发送到您邮箱的验证码';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: '新密码',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入新密码';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _resetPassword(_formKey),
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('重置密码', style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }

  Future<void> _sendCode(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref.read(authViewModelProvider).sendVerificationCode(
        _usernameController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '验证码已发送到您的邮箱' : '发送验证码失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref.read(authViewModelProvider).resetPassword(
        email: _usernameController.text,
        code: _codeController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '密码重置成功' : '重置密码失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
