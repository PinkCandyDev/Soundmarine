import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/liked_service.dart';
import '../widgets/common/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('server_url');
    if (url != null) _serverController.text = url;
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', _serverController.text);
      await prefs.setString('username', _usernameController.text);
      ApiService.baseUrl = _serverController.text;

      final token = await ApiService.login(
        _usernameController.text,
        _passwordController.text,
      );
      ApiService.token = token;
      await prefs.setString('token', token);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
      await LikedService.instance.load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Soundmarine',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            AppTextField(
              controller: _serverController,
              label: 'Server URL',
              hintText: 'http://192.168.50.81:3230',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _usernameController,
              label: 'Username',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              label: 'Password',
              obscureText: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}