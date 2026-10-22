import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/session.dart';
import '../../widgets/section_header.dart';

import '../customer/customer_home_screen.dart';
import '../customer/reviews_screen.dart';
import '../customer/notifications_screen.dart';
import 'provider_profile_edit_screen.dart';
import 'my_services_screen.dart';
import 'provider_requests_screen.dart';
import 'provider_bookings_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState
    extends State<ProviderDashboardScreen> {
  double averageRating = 0.0;
  int reviewCount = 0;
  bool isLoadingRating = true;

  int pendingRequests = 0;
  int completedRequests = 0;
  int totalCustomers = 0;
  bool isLoadingStats = true;

  int unreadNotificationCount = 0;
  bool isLoadingNotificationCount = true;

  @override
  void initState() {
    super.initState();
    loadProviderRating();
    loadDashboardStats();
    loadUnreadNotificationCount();
  }

  Future<void> loadUnreadNotificationCount() async {
    try {
      final count = await ApiService.getUnreadNotificationCount();

      if (!mounted) return;

      setState(() {
        unreadNotificationCount = count;
        isLoadingNotificationCount = false;
      });
    } catch (e) {
      debugPrint('UNREAD NOTIFICATION COUNT ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoadingNotificationCount = false;
      });
    }
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );

    if (!mounted) return;

    loadUnreadNotificationCount();
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

      double totalRating = 0.0;

      for (final review in result) {
        totalRating +=
            double.tryParse(review['rating']?.toString() ?? '0') ?? 0.0;
      }

      if (!mounted) return;

      setState(() {
        averageRating =
            result.isEmpty ? 0.0 : totalRating / result.length;
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
        final status =
            request['status']?.toString().toUpperCase() ?? '';

        if (status == 'PENDING') pending++;
        if (status == 'COMPLETED') completed++;

        final customer = request['customer'];

        if (customer != null) {
          final customerId = customer['id']?.toString();
          final customerEmail = customer['email']?.toString();

          if (customerId != null && customerId.isNotEmpty) {
            customerIds.add(customerId);
          } else if (customerEmail != null &&
              customerEmail.isNotEmpty) {
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
      });
    } catch (e) {
      debugPrint('DASHBOARD STATS ERROR: $e');

      if (!mounted) return;

      setState(() {
        pendingRequests = 0;
        completedRequests = 0;
        totalCustomers = 0;
        isLoadingStats = false;
      });
    }
  }

  Future<void> switchToCustomer(BuildContext context) async {
    final email = Session.email;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session not found. Please login again.'),
        ),
      );
      return;
    }

    if (Session.roles.contains('CUSTOMER')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CustomerHomeScreen(),
        ),
      );
      return;
    }

    final success = await ApiService.addRole(
      email: email,
      role: 'CUSTOMER',
    );

    if (!context.mounted) return;

    if (success) {
      Session.roles.add('CUSTOMER');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can now use SkillLink as a Customer!'),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CustomerHomeScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not switch to Customer.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: openNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (unreadNotificationCount > 0)
                  Positioned(
                    right: -7,
                    top: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadNotificationCount > 99
                            ? '99+'
                            : unreadNotificationCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Service Provider!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage your services and customer requests.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            _dashboardTile(
              context,
              icon: Icons.person_rounded,
              color: AppColors.primary,
              title: 'My Profile',
              subtitle: 'View and edit your provider profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ProviderProfileEditScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _dashboardTile(
              context,
              icon: Icons.build_rounded,
              color: AppColors.secondary,
              title: 'My Services',
              subtitle: 'Manage the services you provide',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyServicesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _dashboardTile(
              context,
              icon: Icons.assignment_rounded,
              color: AppColors.warning,
              title: 'Service Requests',
              subtitle: 'View customer service requests',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProviderRequestsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _dashboardTile(
              context,
              icon: Icons.calendar_month_rounded,
              color: AppColors.success,
              title: 'My Bookings',
              subtitle: 'View accepted and completed bookings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProviderBookingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _dashboardTile(
              context,
              icon: Icons.person_search_rounded,
              color: AppColors.primary,
              title: 'Switch to Customer',
              subtitle: 'Find and book services from other providers',
              onTap: () => switchToCustomer(context),
            ),
            const SizedBox(height: 28),

            const SectionHeader(title: 'Overview'),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.pending_actions_rounded,
                    title: 'Requests',
                    value: isLoadingStats ? '...' : pendingRequests.toString(),
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    icon: Icons.check_circle_rounded,
                    title: 'Completed',
                    value: isLoadingStats
                        ? '...'
                        : completedRequests.toString(),
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.star_rounded,
                    title: 'Rating',
                    value: isLoadingRating
                        ? '...'
                        : averageRating.toStringAsFixed(1),
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    icon: Icons.people_rounded,
                    title: 'Customers',
                    value: isLoadingStats
                        ? '...'
                        : totalCustomers.toString(),
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReviewsScreen(providerEmail: Session.email),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.rate_review_outlined,
                  size: 18,
                ),
                label: Text(
                  reviewCount > 0
                      ? 'View Reviews ($reviewCount)'
                      : 'View Reviews',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
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
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}