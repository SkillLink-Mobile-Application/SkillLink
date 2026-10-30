import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';

import '../customer/customer_home_screen.dart';
import '../customer/reviews_screen.dart';
import '../customer/notifications_screen.dart';
import 'provider_profile_edit_screen.dart';
import 'my_services_screen.dart';
import 'provider_requests_screen.dart';
import 'provider_bookings_screen.dart';

// ============================================================
// DESIGN TOKENS (same as the customer home screen)
// ============================================================

const Color _kYellow = Color(0xFFFFC400);
const Color _kYellowSoft = Color(0xFFFFF6D8);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kSurfaceMuted = Color(0xFFF3F3EE);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);
const Color _kMutedOnDark = Color(0xFFB5B5B0);

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  // Rating
  double averageRating = 0.0;
  int reviewCount = 0;
  bool isLoadingRating = true;

  // Request stats
  int pendingRequests = 0;
  int completedRequests = 0;
  int totalCustomers = 0;
  bool isLoadingStats = true;
  bool statsFailed = false;

  // Notifications
  int unreadNotificationCount = 0;

  // Approval
  String approvalStatus = 'LOADING';
  bool isLoadingApproval = true;

  bool isSwitching = false;

  @override
  void initState() {
    super.initState();
    refreshAll();
  }

  // ----------------------------------------------------------
  // DATA
  // ----------------------------------------------------------

  Future<void> refreshAll() async {
    await Future.wait([
      loadProviderRating(),
      loadProviderApprovalStatus(),
      loadDashboardStats(),
      loadUnreadNotificationCount(),
    ]);
  }

  Future<void> loadProviderApprovalStatus() async {
    final email = Session.email;

    if (email.isEmpty) {
      if (!mounted) return;
      setState(() {
        approvalStatus = 'UNKNOWN';
        isLoadingApproval = false;
      });
      return;
    }

    try {
      final profile = await ApiService.getProviderProfile(email);

      if (!mounted) return;

      setState(() {
        approvalStatus =
            profile?['approvalStatus']?.toString().toUpperCase() ?? 'UNKNOWN';
        isLoadingApproval = false;
      });
    } catch (e) {
      debugPrint('PROVIDER APPROVAL STATUS ERROR: $e');

      if (!mounted) return;
      setState(() {
        approvalStatus = 'UNKNOWN';
        isLoadingApproval = false;
      });
    }
  }

  Future<void> loadUnreadNotificationCount() async {
    try {
      final count = await ApiService.getUnreadNotificationCount();
      if (!mounted) return;
      setState(() => unreadNotificationCount = count);
    } catch (e) {
      debugPrint('UNREAD NOTIFICATION COUNT ERROR: $e');
    }
  }

  Future<void> loadProviderRating() async {
    final email = Session.email;

    if (email.isEmpty) {
      if (!mounted) return;
      setState(() {
        averageRating = 0.0;
        reviewCount = 0;
        isLoadingRating = false;
      });
      return;
    }

    try {
      final result = await ApiService.getProviderReviews(email);

      double total = 0.0;
      for (final review in result) {
        total += double.tryParse(review['rating']?.toString() ?? '0') ?? 0.0;
      }

      if (!mounted) return;

      setState(() {
        averageRating = result.isEmpty ? 0.0 : total / result.length;
        reviewCount = result.length;
        isLoadingRating = false;
      });
    } catch (e) {
      debugPrint('DASHBOARD RATING ERROR: $e');

      if (!mounted) return;
      setState(() {
        averageRating = 0.0;
        reviewCount = 0;
        isLoadingRating = false;
      });
    }
  }

  Future<void> loadDashboardStats() async {
    final email = Session.email;

    if (email.isEmpty) {
      if (!mounted) return;
      setState(() {
        pendingRequests = 0;
        completedRequests = 0;
        totalCustomers = 0;
        isLoadingStats = false;
      });
      return;
    }

    try {
      final result = await ApiService.getProviderRequests(email: email);

      int pending = 0;
      int completed = 0;
      final Set<String> customerIds = {};

      for (final request in result) {
        final status = request['status']?.toString().toUpperCase() ?? '';

        if (status == 'PENDING') pending++;
        if (status == 'COMPLETED') completed++;

        final customer = request['customer'];

        if (customer != null) {
          final id = customer['id']?.toString();
          final customerEmail = customer['email']?.toString();

          if (id != null && id.isNotEmpty) {
            customerIds.add(id);
          } else if (customerEmail != null && customerEmail.isNotEmpty) {
            customerIds.add(customerEmail);
          }
        }
      }

      if (!mounted) return;

      setState(() {
        pendingRequests = pending;
        completedRequests = completed;
        totalCustomers = customerIds.length;
        isLoadingStats = false;
        statsFailed = false;
      });
    } catch (e) {
      debugPrint('DASHBOARD STATS ERROR: $e');

      if (!mounted) return;
      setState(() {
        isLoadingStats = false;
        statsFailed = true;
      });
    }
  }

  // ----------------------------------------------------------
  // NAVIGATION & ACTIONS
  // ----------------------------------------------------------

  Future<void> _open(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (mounted) refreshAll();
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: success ? const Color(0xFF1B7A3C) : _kBlack,
          content: Row(
            children: [
              Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: success ? Colors.white : _kYellow,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> switchToCustomer() async {
    if (isSwitching) return;

    final email = Session.email;

    if (email.isEmpty) {
      _showMessage('Session not found. Please log in again.');
      return;
    }

    if (Session.roles.contains('CUSTOMER')) {
      _open(const CustomerHomeScreen());
      return;
    }

    setState(() => isSwitching = true);

    try {
      final success = await ApiService.addRole(
        email: email,
        role: 'CUSTOMER',
      );

      if (!mounted) return;

      if (success) {
        Session.roles.add('CUSTOMER');
        _showMessage(
          'Customer mode is ready. You can now book services.',
          success: true,
        );
        _open(const CustomerHomeScreen());
      } else {
        _showMessage('Could not switch to customer mode. Please try again.');
      }
    } catch (e) {
      _showMessage('Something went wrong. Check your connection and retry.');
    } finally {
      if (mounted) setState(() => isSwitching = false);
    }
  }

  // ----------------------------------------------------------
  // HELPERS
  // ----------------------------------------------------------

  bool get _approved => approvalStatus == 'APPROVED';

  String _statValue(int value) {
    if (isLoadingStats) return '...';
    if (statsFailed) return '–';
    return '$value';
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: RefreshIndicator(
          color: _kBlack,
          backgroundColor: _kYellow,
          edgeOffset: 120,
          onRefresh: refreshAll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildApprovalBanner()),
              SliverToBoxAdapter(child: _sectionTitle('Manage')),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 146,
                  ),
                  delegate: SliverChildListDelegate([
                    _manageCard(
                      icon: Icons.assignment_rounded,
                      title: 'Requests',
                      subtitle: pendingRequests > 0
                          ? '$pendingRequests waiting'
                          : 'Customer requests',
                      badge: pendingRequests,
                      onTap: () => _open(const ProviderRequestsScreen()),
                    ),
                    _manageCard(
                      icon: Icons.calendar_month_rounded,
                      title: 'Bookings',
                      subtitle: 'Accepted & completed',
                      onTap: () => _open(const ProviderBookingsScreen()),
                    ),
                    _manageCard(
                      icon: Icons.build_rounded,
                      title: 'My services',
                      subtitle: 'Add or edit services',
                      onTap: () => _open(const MyServicesScreen()),
                    ),
                    _manageCard(
                      icon: Icons.person_rounded,
                      title: 'My profile',
                      subtitle: 'Details and photo',
                      onTap: () => _open(const ProviderProfileEditScreen()),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(child: _sectionTitle('Overview')),
              if (statsFailed)
                SliverToBoxAdapter(child: _buildStatsRetry()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 142,
                  ),
                  delegate: SliverChildListDelegate([
                    _statCard(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pending',
                      caption: 'Awaiting your reply',
                      value: _statValue(pendingRequests),
                      onTap: () => _open(const ProviderRequestsScreen()),
                    ),
                    _statCard(
                      icon: Icons.check_circle_rounded,
                      label: 'Completed',
                      caption: 'Finished jobs',
                      value: _statValue(completedRequests),
                      onTap: () => _open(const ProviderBookingsScreen()),
                    ),
                    _statCard(
                      icon: Icons.star_rounded,
                      label: 'Rating',
                      caption: reviewCount == 0
                          ? 'No reviews yet'
                          : (reviewCount == 1
                              ? '1 review'
                              : '$reviewCount reviews'),
                      value: isLoadingRating
                          ? '...'
                          : (reviewCount == 0
                              ? 'New'
                              : averageRating.toStringAsFixed(1)),
                      dark: true,
                      onTap: () =>
                          _open(ReviewsScreen(providerEmail: Session.email)),
                    ),
                    _statCard(
                      icon: Icons.people_rounded,
                      label: 'Customers',
                      caption: 'Unique customers',
                      value: _statValue(totalCustomers),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(child: _buildCustomerPromo()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // HEADER
  // ----------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: _kBlack,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _kYellow,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.handyman_rounded,
                      color: _kBlack,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SkillLink',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.4,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _buildStatusLine(),
                      ],
                    ),
                  ),
                  _buildNotificationButton(),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Welcome back,\nservice provider',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 18),
              _buildRequestsShortcut(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLine() {
    IconData icon;
    String text;

    if (isLoadingApproval) {
      icon = Icons.more_horiz_rounded;
      text = 'Checking status...';
    } else {
      switch (approvalStatus) {
        case 'APPROVED':
          icon = Icons.verified_rounded;
          text = 'Approved provider';
          break;
        case 'PENDING':
          icon = Icons.hourglass_top_rounded;
          text = 'Approval pending';
          break;
        case 'REJECTED':
          icon = Icons.cancel_rounded;
          text = 'Application rejected';
          break;
        default:
          icon = Icons.info_outline_rounded;
          text = 'Status unavailable';
      }
    }

    return Row(
      children: [
        Icon(icon, size: 13, color: _kYellow),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: _kMutedOnDark),
        ),
      ],
    );
  }

  Widget _buildNotificationButton() {
    final label =
        unreadNotificationCount > 99 ? '99+' : '$unreadNotificationCount';

    return Semantics(
      button: true,
      label: unreadNotificationCount > 0
          ? 'Notifications, $unreadNotificationCount unread'
          : 'Notifications',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _open(const NotificationsScreen()),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ),
          ),
          if (unreadNotificationCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kYellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBlack, width: 2),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _kBlack,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestsShortcut() {
    final hasPending = !isLoadingStats && !statsFailed && pendingRequests > 0;

    final String title;
    final String subtitle;

    if (isLoadingStats) {
      title = 'Checking requests...';
      subtitle = 'One moment';
    } else if (hasPending) {
      title = pendingRequests == 1
          ? '1 request is waiting'
          : '$pendingRequests requests are waiting';
      subtitle = _approved
          ? 'Tap to review and respond'
          : 'Tap to review. Approval is needed to accept';
    } else {
      title = 'No new requests';
      subtitle = 'You are all caught up';
    }

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(const ProviderRequestsScreen()),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: hasPending
                  ? Border.all(color: _kYellow, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasPending ? _kYellow : _kSurfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasPending
                        ? Icons.notifications_active_rounded
                        : Icons.check_rounded,
                    color: _kBlack,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _kBlack,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: _kYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
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

  // ----------------------------------------------------------
  // APPROVAL BANNER
  // ----------------------------------------------------------

  Widget _buildApprovalBanner() {
    if (isLoadingApproval || _approved) return const SizedBox.shrink();

    Color color;
    Color background;
    IconData icon;
    String title;
    String message;
    bool canRetry = false;

    switch (approvalStatus) {
      case 'PENDING':
        color = const Color(0xFF7A5A00);
        background = _kYellowSoft;
        icon = Icons.hourglass_top_rounded;
        title = 'Waiting for admin approval';
        message = 'You can set up your profile and services now. You can '
            'accept requests once you are approved.';
        break;

      case 'REJECTED':
        color = const Color(0xFFB3261E);
        background = const Color(0xFFFDEBEA);
        icon = Icons.cancel_rounded;
        title = 'Application rejected';
        message = 'Contact the administrator to find out why and what you '
            'can do next.';
        break;

      default:
        color = const Color(0xFF4B4B4B);
        background = const Color(0xFFEFEFEA);
        icon = Icons.cloud_off_rounded;
        title = 'Could not check approval status';
        message = 'Check your connection and try again.';
        canRetry = true;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(fontSize: 13, height: 1.4, color: color),
                  ),
                  if (canRetry) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() => isLoadingApproval = true);
                        loadProviderApprovalStatus();
                      },
                      child: Text(
                        'Try again',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: color,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SECTIONS
  // ----------------------------------------------------------

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: _kBlack,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildStatsRetry() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() => isLoadingStats = true);
          loadDashboardStats();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFEA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.cloud_off_rounded, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Could not load your stats. Tap to try again.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // MANAGE CARD (Subtler watermark icon, refined sizes)
  // ----------------------------------------------------------

  Widget _manageCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: badge > 0 ? _kYellow : _kBorder,
                width: badge > 0 ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Reduced size and opacity for the background watermark icon
                Positioned(
                  right: -12,
                  top: -12,
                  child: Icon(
                    icon,
                    size: 72,
                    color: _kYellow.withValues(alpha: 0.08),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _kBlack,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(icon, size: 20, color: _kYellow),
                            ),
                            if (badge > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _kYellow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  badge > 99 ? '99+' : '$badge',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: _kBlack,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: _kBlack,
                                      height: 1.2,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: _kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: _kYellow,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: _kBlack,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // STAT CARD
  // ----------------------------------------------------------

  Widget _statCard({
    required IconData icon,
    required String label,
    required String caption,
    required String value,
    VoidCallback? onTap,
    bool dark = false,
  }) {
    final Color mainText = dark ? Colors.white : _kBlack;
    final Color subText = dark ? _kMutedOnDark : _kTextSecondary;

    return Semantics(
      button: onTap != null,
      label: '$label, $value, $caption',
      child: Material(
        color: dark ? _kBlack : Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: dark ? _kBlack : _kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: dark ? _kYellow : _kBlack,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: dark ? _kBlack : _kYellow,
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 16,
                        color: subText,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1,
                    color: dark ? _kYellow : _kBlack,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: mainText,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: subText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SWITCH TO CUSTOMER
  // ----------------------------------------------------------

  Widget _buildCustomerPromo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kBlack,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _kYellow.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: _kYellow,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Need a service yourself?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Switch to customer mode to find and book other providers.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _kMutedOnDark,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isSwitching ? null : switchToCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kYellow,
                  foregroundColor: _kBlack,
                  disabledBackgroundColor: _kYellow.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isSwitching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kBlack,
                        ),
                      )
                    : const Text(
                        'Switch to customer mode',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}