import 'dart:io';
import 'dart:math';

import 'package:demo/constants/dimens.dart';
import 'package:demo/exceptions/api_exception.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_captcha/flutter_captcha.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
    final _Captchacontroller = FlutterCaptchaController(
    random: Random.secure(),
  )..init();

  bool _isLoading = false;
  String? _errorMessage;

  // submit form data to server
  Future<void> _submit() async {

    // validate form
    if (!_formKey.currentState!.validate()) return;
    // check if captcha is correct
    if (!_onCheck(context)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
        showMySnackBar(context, 'Registered successfully!', Colors.green, 1000);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Registered successfully!')),
        // );
        context.go('/');
      }
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          // print(e.statusCode);
          String errormessage = e.message;
          if (e.statusCode == 409) errormessage = 'Username or Email already exists';
          showMySnackBar(context, errormessage, Colors.red, 1000);
        }
        else if (e is SocketException) {
          showMySnackBar(context, 'Connection refused or Network error', Colors.red, 1000);
        } 
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // check captcha
  bool _onCheck(BuildContext context) {
    if (_Captchacontroller.checkSolution()) {
      return true;
    }

    showMySnackBar(context, 'Captcha is not correct, please complete it', Colors.red, 1000);
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
          'Register',
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildForm(),
            _buildCaptcha(),
          ]
        ),
      ),
    );
  }

  Widget _buildCaptcha() {
    setState(() {
      // not to randomize positions on each build
      _Captchacontroller.randomizePositions = false;
    });
    return SizedBox(
      height: 300,
      width: 300,
      child: FlutterCaptcha(
        controller: _Captchacontroller,
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
            decoration: const InputDecoration(labelText: 'username'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a username';
              if (value.length < 4) return 'Username must be at least 4 characters long';
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'password'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a password';
              if (value.length < 6) return 'Password must be at least 6 characters long';
              return null;
            },
          ),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'email'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter an email';
              if (!value.contains('@')) return 'Please enter a valid email address';
              return null;
            },
          ),
          if (_errorMessage == 'HTTP refused: 409')
            Text('username already exists', style: TextStyle(color: Colors.red)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text(
                  'Register',
                  style: TextStyle(color: Colors.blue),
                  ),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text(
              'Already have an account? Login',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          // alert user if captcha is not correct
          Text('Please solve the captcha before submitting')
        ],
      ),
    );
  }
}