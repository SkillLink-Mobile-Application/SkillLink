import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/session.dart';
import 'choose_role_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool isLoading = false;

  Future<void> login() async {
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => isLoading = true);

    try {
      debugPrint('LOGIN: Starting API request');

      // The timeout must also be configured inside ApiService
      // if loginUser itself can wait indefinitely.
      final loginData = await ApiService.loginUser(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 20));

      debugPrint(
        'LOGIN: API request completed. '
        'Success: ${loginData != null}',
      );

      if (!mounted) return;

      if (loginData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Login failed. Check your credentials and connection.',
            ),
          ),
        );
        return;
      }

      final token = loginData['token']?.toString();
      final rawRoles = loginData['roles'];

      if (token == null ||
          token.isEmpty ||
          rawRoles is! List ||
          rawRoles.isEmpty) {
        debugPrint('LOGIN: Invalid response format');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid login response. Please try again.',
            ),
          ),
        );
        return;
      }

      final roles = rawRoles
          .map((role) => role.toString())
          .toList();

      // Save the session.
      Session.email = email;
      Session.roles = roles;
      Session.token = token;

      debugPrint('LOGIN: Session saved for $email');
      debugPrint('LOGIN: Roles received: $roles');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customerEmail', email);

      debugPrint('LOGIN: Local preferences saved');

      // Navigate after successful authentication.
      // FCM token registration is attempted separately so it
      // cannot keep the user stuck on the login screen.
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChooseRoleScreen(
            name: '',
            email: email,
            password: '',
            phone: '',
            availableRoles: roles,
            isLoginFlow: true,
          ),
        ),
      );

      // Register the device token without blocking navigation.
      _registerFcmToken();
    } on Exception catch (e, stackTrace) {
      debugPrint('LOGIN ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      final message = e.toString().contains('TimeoutException')
          ? 'Login timed out. Check your connection and server.'
          : 'Unable to log in. Please check your connection and try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      debugPrint('FCM: Getting device token');

      final fcmToken =
          await FirebaseMessaging.instance.getToken().timeout(
                const Duration(seconds: 10),
              );

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('FCM: Token unavailable');
        return;
      }

      debugPrint('FCM: Token obtained; length=${fcmToken.length}');

      final saved = await ApiService.saveFcmToken(fcmToken)
          .timeout(const Duration(seconds: 10));

      debugPrint('FCM: Token saved successfully=$saved');
    } catch (e) {
      debugPrint('FCM REGISTRATION ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Login to continue using SkillLink',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              onSubmitted: (_) {
                if (!isLoading) login();
              },
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : login,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 17),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RegisterScreen(),
                          ),
                        );
                      },
                child: const Text(
                  "Don't have an account? Register",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}