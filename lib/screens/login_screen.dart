import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/api_service.dart';
import '../utils/session.dart';
import 'choose_role_screen.dart';
import 'register_screen.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBlackLight = Color(0xFF1E1E1E);
const Color _kBackground = Color(0xFFFAFAF7);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);

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

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: _kTextSecondary,
        fontSize: 14.5,
      ),
      floatingLabelStyle: const TextStyle(
        color: _kBlack,
        fontWeight: FontWeight.w700,
      ),
      prefixIcon: Icon(icon, color: _kBlack, size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kYellow, width: 2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kBlackLight, _kBlack],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kYellow.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -70,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kYellow.withValues(alpha: 0.07),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      tooltip: 'Back',
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kYellow,
                      boxShadow: [
                        BoxShadow(
                          color: _kYellow.withValues(alpha: 0.40),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 38,
                      color: _kBlack,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login to continue using SkillLink',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: const BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            cursorColor: _kBlack,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _kBlack,
            ),
            decoration: _fieldDecoration(
              label: 'Email',
              icon: Icons.email_outlined,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: passwordController,
            obscureText: true,
            cursorColor: _kBlack,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _kBlack,
            ),
            decoration: _fieldDecoration(
              label: 'Password',
              icon: Icons.lock_outline,
            ),
            onSubmitted: (_) {
              if (!isLoading) login();
            },
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kYellow,
                foregroundColor: _kBlack,
                disabledBackgroundColor: _kYellow.withValues(alpha: 0.65),
                disabledForegroundColor: _kBlack,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onPressed: isLoading ? null : login,
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: _kBlack,
                      ),
                    )
                  : const Text(
                      'Login',
                      style: TextStyle(fontSize: 17),
                    ),
            ),
          ),

          const SizedBox(height: 18),

          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: _kBlack,
              ),
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
              child: const Text.rich(
                TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: 'Register',
                      style: TextStyle(
                        color: _kBlack,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: _kYellow,
                        decorationThickness: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBlack,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(child: _buildForm()),
                    ],
                  ),
                ),
              ),
            );
          },
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