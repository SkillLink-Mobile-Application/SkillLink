
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import 'become_provider_screen.dart';
import 'customer_bookings_screen.dart';
import 'customer_profile_screen.dart';
import 'notifications_screen.dart';
import 'provider_list_screen.dart';

// ============================================================
// DESIGN TOKENS
// ============================================================

const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);

// ============================================================
// DYNAMIC SERVICE MODEL
// ============================================================

class _Service {
  final String name;
  final String description;
  final String? icon;
  final String? imageUrl;

  const _Service({
    required this.name,
    required this.description,
    this.icon,
    this.imageUrl,
  });

  bool get hasImage =>
      imageUrl != null && imageUrl!.trim().isNotEmpty;

  bool get hasIcon =>
      icon != null && icon!.trim().isNotEmpty;
}

// ============================================================
// SCREEN
// ============================================================

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() =>
      _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int unreadNotificationCount = 0;

  String searchQuery = '';

  List<_Service> services = [];

  bool isLoadingCategories = true;
  String? categoryLoadError;

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadUnreadNotificationCount();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD CATEGORIES FROM DATABASE
  // ==========================================================

  Future<void> loadCategories() async {
    if (mounted && services.isEmpty) {
      setState(() {
        isLoadingCategories = true;
        categoryLoadError = null;
      });
    }

    try {
      final data = await ApiService.getCategories();

      final loadedServices = data
          .whereType<Map>()
          .map((item) {
        final name = (item['name'] ?? '').toString().trim();

        if (name.isEmpty) return null;

        final description =
            (item['description'] ?? '').toString().trim();

        final icon = (item['icon'] ?? '').toString().trim();

        final imageUrl =
            (item['imageUrl'] ?? '').toString().trim();

        return _Service(
          name: name,
          description: description,
          icon: icon.isEmpty ? null : icon,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
        );
      })
          .whereType<_Service>()
          .toList();

      if (!mounted) return;

      setState(() {
        services = loadedServices;
        isLoadingCategories = false;

        categoryLoadError = loadedServices.isEmpty
            ? 'No active service categories are available right now.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingCategories = false;
        categoryLoadError =
            'Could not load service categories. Please try again.';
      });
    }
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<void> _refreshDashboard() async {
    await Future.wait([
      loadCategories(),
      loadUnreadNotificationCount(),
    ]);
  }

  Future<void> loadUnreadNotificationCount() async {
    try {
      final count =
          await ApiService.getUnreadNotificationCount();

      if (!mounted) return;

      setState(() {
        unreadNotificationCount = count;
      });
    } catch (_) {
      // Notification badge is optional.
    }
  }

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  Future<void> _open(Widget screen) async {
    FocusScope.of(context).unfocus();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (mounted) {
      await loadUnreadNotificationCount();
    }
  }

  void openService(String serviceName) {
    _open(ProviderListScreen(serviceName: serviceName));
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  void clearSearch() {
    searchController.clear();

    setState(() {
      searchQuery = '';
    });
  }

  List<_Service> get filteredServices {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return services;

    return services.where((service) {
      return service.name.toLowerCase().contains(query) ||
          service.description.toLowerCase().contains(query);
    }).toList();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final displayedServices = filteredServices;

    final isSearching = searchQuery.trim().isNotEmpty;

    final showProviderPromo = !isSearching;

    return Scaffold(
      backgroundColor: _kBackground,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: RefreshIndicator(
          color: _kBlack,
          backgroundColor: _kYellow,
          edgeOffset: 120,
          onRefresh: _refreshDashboard,
          child: CustomScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),

              SliverToBoxAdapter(
                child: _buildSectionTitle(displayedServices.length),
              ),

              if (isLoadingCategories && services.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _kBlack,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                )
              else if (categoryLoadError != null &&
                  services.isEmpty)
                SliverToBoxAdapter(
                  child: _buildCategoryError(),
                )
              else if (displayedServices.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 146,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildServiceCard(
                          displayedServices[index],
                        );
                      },
                      childCount: displayedServices.length,
                    ),
                  ),
                ),

              if (showProviderPromo)
                SliverToBoxAdapter(
                  child: _buildProviderPromo(),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

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
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            22,
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

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SkillLink',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.4,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: _kYellow,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Sri Lanka',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB5B5B0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  _buildNotificationButton(),
                ],
              ),

              const SizedBox(height: 22),

              const Text(
                'Who do you need\ntoday?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),

              const SizedBox(height: 18),

              _buildSearchField(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // NOTIFICATIONS
  // ==========================================================

  Widget _buildNotificationButton() {
    final label = unreadNotificationCount > 99
        ? '99+'
        : unreadNotificationCount.toString();

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kYellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _kBlack,
                    width: 2,
                  ),
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

  // ==========================================================
  // SEARCH FIELD
  // ==========================================================

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      textInputAction: TextInputAction.search,
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
      onSubmitted: (_) {
        FocusScope.of(context).unfocus();
      },
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _kBlack,
      ),
      cursorColor: _kBlack,
      decoration: InputDecoration(
        hintText: 'Search services...',
        hintStyle: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
          color: _kTextSecondary,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _kBlack,
          size: 22,
        ),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: clearSearch,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: _kTextSecondary,
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _kYellow,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _buildSectionTitle(int count) {
    final isSearching = searchQuery.trim().isNotEmpty;

    final title = isSearching
        ? 'Results for "${searchQuery.trim()}"'
        : 'All services';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _kBlack,
                letterSpacing: -0.3,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Text(
            count == 1 ? '1 service' : '$count services',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SERVICE IMAGE / ICON
  // ==========================================================

  Widget _buildServiceVisual(_Service service) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _kBlack,
        borderRadius: BorderRadius.circular(13),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: service.hasImage
            ? Image.network(
                service.imageUrl!,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackIcon(service);
                },
              )
            : _buildFallbackIcon(service),
      ),
    );
  }

  Widget _buildFallbackIcon(_Service service) {
    if (service.hasIcon) {
      return Center(
        child: Text(
          service.icon!,
          style: const TextStyle(fontSize: 22),
        ),
      );
    }

    return const Icon(
      Icons.handyman_rounded,
      size: 20,
      color: _kYellow,
    );
  }

  // ==========================================================
  // SERVICE CARD
  // ==========================================================

  Widget _buildServiceCard(_Service service) {
    return Semantics(
      button: true,
      label: '${service.name}, ${service.description}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openService(service.name),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _kBorder),
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
                if (!service.hasImage)
                  Positioned(
                    right: -12,
                    top: -12,
                    child: Icon(
                      Icons.handyman_rounded,
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
                        _buildServiceVisual(service),

                        const Spacer(),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name,
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
                                    service.description.isNotEmpty
                                        ? service.description
                                        : 'Professional services',
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

  // ==========================================================
  // CATEGORY ERROR
  // ==========================================================

  Widget _buildCategoryError() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 42,
        horizontal: 28,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: _kTextSecondary,
          ),

          const SizedBox(height: 12),

          Text(
            categoryLoadError ??
                'Could not load service categories.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: _kTextSecondary,
            ),
          ),

          const SizedBox(height: 14),

          ElevatedButton.icon(
            onPressed: loadCategories,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kYellow,
              foregroundColor: _kBlack,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState() {
    final isSearching = searchQuery.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 32,
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: _kYellow.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 38,
              color: _kBlack,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            isSearching
                ? 'No services match "${searchQuery.trim()}"'
                : 'No services available',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kBlack,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Try another search or check back later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: _kTextSecondary,
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton(
            onPressed: clearSearch,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kBlack,
              side: const BorderSide(
                color: _kBlack,
                width: 1.2,
              ),
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Show all services',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PROVIDER PROMO
  // ==========================================================

  Widget _buildProviderPromo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        22,
        16,
        0,
      ),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kYellow.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: _kYellow,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 14),

                const Expanded(
                  child: Text(
                    'Do you offer a skilled service?',
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
              'List your service on SkillLink and get booking requests from '
              'customers near you.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFFB5B5B0),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () =>
                    _open(const BecomeProviderScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kYellow,
                  foregroundColor: _kBlack,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Become a provider',
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

  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  Widget _buildBottomNav() {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: _kBlack,
        indicatorColor: _kYellow,
        surfaceTintColor: Colors.transparent,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected =
              states.contains(WidgetState.selected);

          return IconThemeData(
            color: selected
                ? _kBlack
                : const Color(0xFFB5B5B0),
            size: 24,
          );
        }),
        labelTextStyle:
            WidgetStateProperty.resolveWith((states) {
          final selected =
              states.contains(WidgetState.selected);

          return TextStyle(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? _kYellow
                : const Color(0xFFB5B5B0),
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            _open(const CustomerBookingsScreen());
          }

          if (index == 2) {
            _open(const CustomerProfileScreen());
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
