import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../utils/session.dart';
import 'customer/customer_home_screen.dart';
import 'provider/provider_dashboard_screen.dart';
import 'provider/provider_profile_edit_screen.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBlackLight = Color(0xFF1E1E1E);
const Color _kBackground = Color(0xFFFAFAF7);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);

class ChooseRoleScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String phone;
  final List<String>? availableRoles;
  final bool isLoginFlow;

  const ChooseRoleScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.availableRoles,
    this.isLoginFlow = false,
  });

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  bool isLoading = false;

  Future<void> selectRole(String role) async {
    if (isLoading) return;

    // Keep the existing login flow unchanged.
    if (widget.isLoginFlow) {
      if (role == 'CUSTOMER') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomerHomeScreen(),
          ),
        );
      } else if (role == 'PROVIDER') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProviderDashboardScreen(),
          ),
        );
      }
      return;
    }

    setState(() => isLoading = true);

    final success = await ApiService.registerUser(
      name: widget.name,
      email: widget.email,
      password: widget.password,
      phone: widget.phone,
      role: role,
    );

    if (!mounted) return;

    if (!success) {
      setState(() => isLoading = false);
      _showMessage('Registration failed. Please try again.');
      return;
    }

    // Save the signed-in user's session.
    Session.email = widget.email;
    Session.roles = [role];

    if (role == 'CUSTOMER') {
      setState(() => isLoading = false);

      // Customer registration flow remains unchanged.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomerHomeScreen(),
        ),
        (route) => false,
      );
      return;
    }

    if (role == 'PROVIDER') {
      setState(() => isLoading = false);

      // Navigate directly to the provider profile page.
      // No popup and no "Complete Later" option.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const ProviderProfileEditScreen(),
        ),
        (route) => false,
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

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
                      onPressed: isLoading
                          ? null
                          : () => Navigator.maybePop(context),
                      tooltip: 'Back',
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                      Icons.handyman_rounded,
                      size: 36,
                      color: _kBlack,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'How do you want\nto use SkillLink?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.8,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to use SkillLink.',
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

  @override
  Widget build(BuildContext context) {
    final showCustomer = widget.availableRoles == null ||
        widget.availableRoles!.contains('CUSTOMER');

    final showProvider = widget.availableRoles == null ||
        widget.availableRoles!.contains('PROVIDER');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBlack,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(
                            24,
                            32,
                            24,
                            28,
                          ),
                          decoration: const BoxDecoration(
                            color: _kBackground,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              if (showCustomer)
                                _roleCard(
                                  icon: Icons.person_rounded,
                                  title: 'Customer',
                                  subtitle:
                                      'Find & book trusted services near you',
                                  onTap: () =>
                                      selectRole('CUSTOMER'),
                                ),
                              if (showCustomer && showProvider)
                                const SizedBox(height: 18),
                              if (showProvider)
                                _roleCard(
                                  icon: Icons.handyman_rounded,
                                  title: 'Service Provider',
                                  subtitle:
                                      'Offer your skills and grow your business',
                                  dark: true,
                                  onTap: () =>
                                      selectRole('PROVIDER'),
                                ),
                              if (isLoading) ...[
                                const SizedBox(height: 28),
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: _kBlack,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Center(
                                  child: Text(
                                    'Please wait...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _kTextSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
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

  Widget _roleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool dark = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? _kBlack : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dark ? _kBlack : _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.18 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          splashColor: _kYellow.withValues(alpha: 0.18),
          highlightColor: _kYellow.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _kYellow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: _kBlack,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: dark ? Colors.white : _kBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: dark
                              ? Colors.white.withValues(alpha: 0.7)
                              : _kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: dark ? _kYellow : const Color(0xFFF3F3EE),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: _kBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}