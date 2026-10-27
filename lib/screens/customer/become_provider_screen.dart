import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';

import '../provider/provider_dashboard_screen.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBlackLight = Color(0xFF1E1E1E);
const Color _kBackground = Color(0xFFFAFAF7);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);

//==================== Become Provider Screen ====================

class BecomeProviderScreen extends StatefulWidget {
  const BecomeProviderScreen({super.key});

  @override
  State<BecomeProviderScreen> createState() =>
      _BecomeProviderScreenState();
}

class _BecomeProviderScreenState
    extends State<BecomeProviderScreen> {

  bool isLoading = false;

  // ==================== Become Provider ====================

  Future<void> becomeProvider() async {
    final email = Session.email;

    // Check login session
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User session not found. Please login again.',
          ),
        ),
      );
      return;
    }

    // Already a provider
    if (Session.roles.contains('PROVIDER')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const ProviderDashboardScreen(),
        ),
      );

      return;
    }

    // Start loading
    setState(() {
      isLoading = true;
    });

    // Call backend API
    final success = await ApiService.addRole(
      email: email,
      role: 'PROVIDER',
    );

    if (!mounted) return;

    // Stop loading
    setState(() {
      isLoading = false;
    });

    // ==================== Success ====================

    if (success) {
      // Add provider role to current session
      Session.roles.add('PROVIDER');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are now a Service Provider!',
          ),
        ),
      );

      // Go to Provider Dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const ProviderDashboardScreen(),
        ),
      );
    }

    // ==================== Failed ====================

    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not become a Service Provider.',
          ),
        ),
      );
    }
  }

  // ==================== UI ====================

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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
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

                  // ==================== Icon ====================
                  Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kYellow,
                        boxShadow: [
                          BoxShadow(
                            color: _kYellow.withValues(alpha: 0.40),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.handyman_rounded,
                        size: 46,
                        color: _kBlack,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ==================== Title ====================
                  const SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Start Offering Your Skills',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.7,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ==================== Description ====================
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Become a SkillLink service provider and connect with customers who need your skills.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
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

  Widget _buildBody() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
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
          // ==================== Info 1 ====================
          const _BenefitTile(
            icon: Icons.people_alt_rounded,
            title: 'Reach Customers',
            subtitle: 'Connect with people looking for your services.',
          ),

          // ==================== Info 2 ====================
          const _BenefitTile(
            icon: Icons.work_rounded,
            title: 'Show Your Skills',
            subtitle:
                'Create your provider profile and list your services.',
          ),

          // ==================== Info 3 ====================
          const _BenefitTile(
            icon: Icons.trending_up_rounded,
            title: 'Grow Your Business',
            subtitle: 'Receive service requests through SkillLink.',
          ),

          const SizedBox(height: 14),

          // ==================== Button ====================
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
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
              onPressed: isLoading ? null : becomeProvider,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: _kBlack,
                      ),
                    )
                  : const Icon(
                      Icons.handyman_rounded,
                    ),
              label: Text(
                isLoading
                    ? 'Becoming a Provider...'
                    : 'Become a Service Provider',
                style: const TextStyle(
                  fontSize: 16,
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(child: _buildBody()),
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
}

// ==================== Benefit Tile ====================

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _kYellow,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 25, color: _kBlack),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kBlack,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: _kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}