
import 'dart:io';

import 'package:demo/constants/dimens.dart';
import 'package:demo/exceptions/api_exception.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ResetPasswordPage extends StatefulWidget {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reset Password',
          style: TextStyle(
            fontSize: Dimens.fontSizeLarge,
          ), 
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.home),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),

      drawer: const MyDrawer(),

      body: Padding(
        padding: const EdgeInsets.all(16.0), 
        child:Column(
          children: [
            _buildSendCodeForm(apiService),
            _buildResetPasswordForm(apiService),
            
          ],
        )
      ),
    );
  }

  Widget _buildSendCodeForm(ApiService apiService) {
    final _formKey = GlobalKey<FormState>();
    return Column(
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your username';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16.0),
        
        ElevatedButton(
          child: const Text(
            'Send reset code email',
            style: TextStyle(
              color: Colors.blue
            ),
          ),
          onPressed: () async{
            if (_formKey.currentState!.validate()) {
              try {
                await apiService.sendCode(_usernameController.text);
                showMySnackBar(context, 'Code sent to your email', Colors.green, 1000);
              } catch (e) {
                if (e is ApiException) {
                  showMySnackBar(context, e.message, Colors.red, 1000);
                }else if (e is SocketException) {
                  showMySnackBar(context, 'No internet connection', Colors.red, 1000);
                }
              }
            }
          },
        ),

        TextButton(
          child: const Text(
            'Bcak to login',
            style: TextStyle(
              color: Colors.blue
            ),
          ),
          onPressed: () => context.go('/login'),
        ),
      ]
    );
  }

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
                  labelText: 'Code',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the code sent to your email';
                  }
                  return null;
                },
              ),
               TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your new password';
                  }
                  return null;
                },
              ),
            ],
          )
        ),
        // const SizedBox(height: 16.0),
       
        const SizedBox(height: 16.0),
        ElevatedButton(
          child: const Text(
            'Reset Password',
            style: TextStyle(
              color: Colors.blue
            ),
          ),
          onPressed: () async{
            if (_formKey.currentState!.validate()) {
              try {
                await apiService.resetPassword(_usernameController.text, _codeController.text, _newPasswordController.text);
                showMySnackBar(context, 'Password reset successful', Colors.green, 1000);
              } catch (e) {
                if (e is ApiException) {
                  showMySnackBar(context, e.message, Colors.red, 1000);
                  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                } else if (e is SocketException) {
                  showMySnackBar(context, 'No internet connection', Colors.red, 1000);
                  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred, please try again later')));
                }
              }
            }
          },
        )
      ],
    );
  }

}