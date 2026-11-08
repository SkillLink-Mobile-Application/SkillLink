
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

// ==================== Colors ====================

const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBlackLight = Color(0xFF1E1E1E);
const Color _kBackground = Color(0xFFFAFAF7);
const Color _kTextSecondary = Color(0xFF6B6B6B);

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // ==================== Contact Actions ====================

  Future<void> _openContact(
    BuildContext context,
    Uri uri,
  ) async {
    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open this application.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroHeight =
                (constraints.maxHeight * 0.40).clamp(250.0, 320.0);

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    // ==================== HERO SECTION ====================

                    Container(
                      width: double.infinity,
                      height: heroHeight,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _kBlackLight,
                            _kBlack,
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -55,
                              top: -55,
                              child: Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _kYellow.withValues(alpha: 0.10),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -45,
                              bottom: -55,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _kYellow.withValues(alpha: 0.07),
                                ),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 82,
                                      height: 82,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _kYellow,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _kYellow.withValues(
                                              alpha: 0.30,
                                            ),
                                            blurRadius: 24,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.handyman_rounded,
                                        color: _kBlack,
                                        size: 42,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          'Skill',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          'Link',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: _kYellow,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Connect with Trusted\nLocal Service Providers',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ==================== MAIN CONTENT ====================

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        22,
                        24,
                        22,
                        20,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Professional Help,\nJust a Tap Away',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: _kBlack,
                              height: 1.25,
                              letterSpacing: -0.4,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _kYellow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Book verified electricians, plumbers, painters '
                            'and more — all in one trusted platform.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _kTextSecondary,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ==================== STATISTICS ====================

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: _kBlack,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: const [
                                Expanded(
                                  child: _WelcomeStat(
                                    value: '500+',
                                    label: 'Professionals',
                                  ),
                                ),
                                _WelcomeStatDivider(),
                                Expanded(
                                  child: _WelcomeStat(
                                    value: '4.8★',
                                    label: 'Avg. Rating',
                                  ),
                                ),
                                _WelcomeStatDivider(),
                                Expanded(
                                  child: _WelcomeStat(
                                    value: '10k+',
                                    label: 'Bookings',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ==================== GET STARTED ====================

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kYellow,
                                foregroundColor: _kBlack,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 19,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Trusted by 500+ verified professionals',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: _kTextSecondary,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ==================== CONTACT DETAILS ====================

                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _openContact(
                                  context,
                                  Uri(
                                    scheme: 'mailto',
                                    path: 'skilllink.supportteam@gmail.com',
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 5,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 15,
                                        color: _kBlackLight,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'skilllink.supportteam@gmail.com',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _kBlackLight,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _openContact(
                                  context,
                                  Uri(
                                    scheme: 'tel',
                                    path: '0702305523',
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 5,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 15,
                                        color: _kBlackLight,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        '0702305523',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _kBlackLight,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          const _DeveloperCredit(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==================== STATISTICS ITEM ====================

class _WelcomeStat extends StatelessWidget {
  final String value;
  final String label;

  const _WelcomeStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _kYellow,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ==================== STATISTICS DIVIDER ====================

class _WelcomeStatDivider extends StatelessWidget {
  const _WelcomeStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 27,
      color: Colors.white.withValues(alpha: 0.16),
    );
  }
}

// ==================== DEVELOPER CREDIT ====================

class _DeveloperCredit extends StatelessWidget {
  const _DeveloperCredit();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _kYellow,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Developed by ',
          style: TextStyle(
            fontSize: 11,
            color: _kTextSecondary,
          ),
        ),
        const Text(
          'Charuni Liyanage',
          style: TextStyle(
            fontSize: 11,
            color: _kBlack,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
