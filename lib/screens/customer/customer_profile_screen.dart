import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../utils/session.dart';
import 'customer_edit_profile_screen.dart';
import 'become_provider_screen.dart';
import '../change_password_screen.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);
const Color _kDanger = Color(0xFFD92D20);

// ==================== Customer Profile Screen ====================

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState
    extends State<CustomerProfileScreen> {
  bool isLoading = true;

  String name = '';
  String email = '';
  String phone = '';
  String profileImage = '';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ================= LOAD PROFILE =================

  Future<void> loadProfile() async {
    if (Session.email.isEmpty) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
      return;
    }

    final profile = await ApiService.getUserProfile(
      email: Session.email,
    );

    debugPrint('CUSTOMER PROFILE EMAIL: ${Session.email}');
    debugPrint('CUSTOMER PROFILE DATA: $profile');

    if (!mounted) return;

    if (profile != null) {
      setState(() {
        name = profile['name'] ?? '';
        email = profile['email'] ?? Session.email;
        phone = profile['phone'] ?? '';
        profileImage = profile['profileImage'] ?? '';
        isLoading = false;
      });

      debugPrint('CUSTOMER PROFILE IMAGE: $profileImage');
    } else {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load profile'),
        ),
      );
    }
  }

  // ================= PROFILE IMAGE URL =================

  String get profileImageUrl {
    if (profileImage.isEmpty) {
      return '';
    }

    if (profileImage.startsWith('http')) {
      return profileImage;
    }

    return '${ApiService.baseUrl}$profileImage';
  }

  // ================= UI HELPERS =================

  ButtonStyle _outlinedStyle({
    Color color = _kBlack,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color, width: 1.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBlack,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _kBlack,
              ),
            )
          : RefreshIndicator(
              color: _kBlack,
              backgroundColor: _kYellow,
              onRefresh: loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ================= PROFILE PHOTO =================

                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _kYellow,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _kYellow.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFFFFF3C4),
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        onBackgroundImageError:
                            profileImageUrl.isNotEmpty
                                ? (_, _) {
                                    debugPrint(
                                      'Failed to load customer profile image',
                                    );
                                  }
                                : null,
                        child: profileImageUrl.isEmpty
                            ? const Icon(
                                Icons.person_rounded,
                                size: 58,
                                color: _kBlack,
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ================= NAME =================

                    Text(
                      name.isEmpty ? 'Customer' : name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _kBlack,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 4),

                    // ================= EMAIL =================

                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _kTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 28),

                    // ================= FULL NAME =================

                    _ProfileInfoTile(
                      icon: Icons.person_rounded,
                      title: 'Full Name',
                      subtitle:
                          name.isEmpty ? 'Not added' : name,
                    ),

                    const SizedBox(height: 12),

                    // ================= EMAIL =================

                    _ProfileInfoTile(
                      icon: Icons.email_rounded,
                      title: 'Email',
                      subtitle: email,
                    ),

                    const SizedBox(height: 12),

                    // ================= PHONE =================

                    _ProfileInfoTile(
                      icon: Icons.phone_rounded,
                      title: 'Phone Number',
                      subtitle:
                          phone.isEmpty ? 'Not added' : phone,
                    ),

                    const SizedBox(height: 24),

                    // ================= EDIT PROFILE =================

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kYellow,
                          foregroundColor: _kBlack,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed: () async {
                          final updated =
                              await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CustomerEditProfileScreen(
                                name: name,
                                email: email,
                                phone: phone,
                              ),
                            ),
                          );

                          if (updated == true && mounted) {
                            await loadProfile();
                          }
                        },
                        icon: const Icon(
                          Icons.edit_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ================= BECOME PROVIDER =================

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlack,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BecomeProviderScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.handyman_rounded,
                          color: _kYellow,
                        ),
                        label: const Text(
                          'Become a Service Provider',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ================= CHANGE PASSWORD =================//

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        style: _outlinedStyle(),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePasswordScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.lock_reset_rounded),
                        label: const Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ================= LOGOUT =================

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        style: _outlinedStyle(color: _kDanger),
                        onPressed: () {
                          Session.email = '';
                          Session.roles = [];

                          Navigator.popUntil(
                            context,
                            (route) => route.isFirst,
                          );
                        },
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Logout',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

// ================= PROFILE INFO TILE =================

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _kYellow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: _kBlack,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _kTextSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kBlack,
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