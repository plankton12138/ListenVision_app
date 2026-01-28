import 'package:demo/core/base/base_page.dart';
import 'package:demo/core/constants/app_constants.dart';
import 'package:demo/core/di/service_factory.dart';
import 'package:demo/presentation/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 重置密码页面
///
/// 通过邮箱验证码重置用户密码
/// 使用 AsyncUIHandlerMixin 统一处理异步操作和错误
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with BasePageState, AsyncUIHandlerMixin {
  final _usernameController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

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
          child: const Text(
            '发送重置验证码邮件',
            style: TextStyle(color: Colors.blue),
          ),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await runAsync(
                operation: () async {
                  final authRepository = ServiceFactory.instance.authRepository;
                  final result = await authRepository.sendVerificationCode(
                    email: _usernameController.text,
                  );
                  result.fold(
                    (failure) {
                      throw Exception(failure.message ?? '发送验证码失败');
                    },
                    (_) {},
                  );
                },
                successMessage: '验证码已发送到您的邮箱',
              );
            }
          },
        ),

        TextButton(
          child: const Text(
            '返回登录',
            style: TextStyle(color: Colors.blue),
          ),
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
          child: const Text(
            '重置密码',
            style: TextStyle(color: Colors.blue),
          ),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await runAsync(
                operation: () async {
                  final authRepository = ServiceFactory.instance.authRepository;
                  final result = await authRepository.resetPassword(
                    email: _usernameController.text,
                    code: _codeController.text,
                    newPassword: _newPasswordController.text,
                  );
                  result.fold(
                    (failure) {
                      throw Exception(failure.message ?? '重置密码失败');
                    },
                    (_) {},
                  );
                },
                successMessage: '密码重置成功',
              );
            }
          },
        ),
      ],
    );
  }
}
