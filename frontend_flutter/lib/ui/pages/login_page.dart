import 'dart:io';

import 'package:demo/constants/dimens.dart';
import 'package:demo/exceptions/api_exception.dart';
import 'package:demo/providers/auth_provider.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  // formkey to validate form
  final _formKey = GlobalKey<FormState>();

  // text controllers for username and password
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  // String? _errorMessage;

  Future<void> _submit() async {    
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      // _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final user = await apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.setUser(user);

      if(mounted) {
        showMySnackBar(context, 'Login successful!', Colors.green, 1000);
        context.go('/');
      }
    } catch (e) {
      if (e is ApiException) {
        String errormessage = e.message;
        if(e.statusCode == 401) errormessage = 'Invalid username or password';
        showMySnackBar(context, errormessage, Colors.red, 1000);

      } else if (e is SocketException) {
        showMySnackBar(context, 'Connection refused or Network error', Colors.red, 1000);
      }
    } finally {
      if(mounted) {
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
          'Login',
          style: TextStyle(
            fontSize: Dimens.fontSizeLarge,            
          ),
        ),
        actions: <Widget>[
          // Home Button
          IconButton(
            icon: Icon(Icons.home),
            iconSize: Dimens.iconMedium,
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
            // Username Text Field
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your username';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password Text Field
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters long';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                    'Login', 
                    style: TextStyle(fontSize: 18, color: Colors.blue),
                  ),
            ),

            // Register Button
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => context.go('/register'),
              child: const Text(
                'Without account, go to register',
                style: TextStyle(fontSize: 18, color: Colors.blue),
              ),
            ),

            // Forgot Password Button
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => context.go('/reset_password'),
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 18, color: Colors.blue),
              )
            ),
          ],
        ),
      ),
    );
  }
}