
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/session.dart';
import 'customer/customer_home_screen.dart';
import 'provider/provider_dashboard_screen.dart';
import 'provider/provider_profile_edit_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final showCustomer = widget.availableRoles == null ||
        widget.availableRoles!.contains('CUSTOMER');

    final showProvider = widget.availableRoles == null ||
        widget.availableRoles!.contains('PROVIDER');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Role'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How do you want\nto use SkillLink?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how you want to use SkillLink.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 36),
            if (showCustomer)
              _roleCard(
                icon: Icons.person_rounded,
                color: AppColors.primary,
                title: 'Customer',
                subtitle: 'Find & book trusted services near you',
                onTap: () => selectRole('CUSTOMER'),
              ),
            if (showCustomer && showProvider)
              const SizedBox(height: 18),
            if (showProvider)
              _roleCard(
                icon: Icons.handyman_rounded,
                color: AppColors.secondary,
                title: 'Service Provider',
                subtitle: 'Offer your skills and grow your business',
                onTap: () => selectRole('PROVIDER'),
              ),
            if (isLoading) ...[
              const SizedBox(height: 25),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text('Please wait...'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roleCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
