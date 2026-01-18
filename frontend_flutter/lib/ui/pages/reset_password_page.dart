import 'dart:io';

import 'package:demo/constants/dimens.dart';
import 'package:demo/exceptions/api_exception.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 重置密码页面
///
/// 通过邮箱验证码重置用户密码
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
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
    final apiService = Provider.of<ApiService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '重置密码',
          style: TextStyle(
            fontSize: Dimens.fontSizeLarge,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),

      drawer: const MyDrawer(),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSendCodeForm(apiService),
            _buildResetPasswordForm(apiService),
          ],
        ),
      ),
    );
  }

  /// 构建发送验证码表单
  Widget _buildSendCodeForm(ApiService apiService) {
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
              try {
                await apiService.sendCode(_usernameController.text);
                showMySnackBar(context, '验证码已发送到您的邮箱', Colors.green, 1000);
              } catch (e) {
                if (e is ApiException) {
                  showMySnackBar(context, e.message, Colors.red, 1000);
                } else if (e is SocketException) {
                  showMySnackBar(context, '无网络连接', Colors.red, 1000);
                }
              }
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
  Widget _buildResetPasswordForm(ApiService apiService) {
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
              try {
                await apiService.resetPassword(
                  _usernameController.text,
                  _codeController.text,
                  _newPasswordController.text,
                );
                showMySnackBar(context, '密码重置成功', Colors.green, 1000);
              } catch (e) {
                if (e is ApiException) {
                  showMySnackBar(context, e.message, Colors.red, 1000);
                } else if (e is SocketException) {
                  showMySnackBar(context, '无网络连接', Colors.red, 1000);
                }
              }
            }
          },
        ),
      ],
    );
  }
}
