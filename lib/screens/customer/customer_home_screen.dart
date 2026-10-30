import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import 'become_provider_screen.dart';
import 'customer_bookings_screen.dart';
import 'customer_profile_screen.dart';
import 'notifications_screen.dart';
import 'provider_list_screen.dart';

// ============================================================
// DESIGN TOKENS (shared with bookings / requests screens)
// ============================================================

const Color _kYellow = Color(0xFFFFC400);
const Color _kYellowSoft = Color(0xFFFFF6D8);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kSurfaceMuted = Color(0xFFF3F3EE);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);

// ============================================================
// DATA
// ============================================================

class _Service {
  final String name;
  final String subtitle;
  final String category;
  final IconData icon;
  final double rating;

  const _Service(
    this.name,
    this.subtitle,
    this.category,
    this.icon,
    this.rating,
  );
}

const String _kAll = 'All';
const String _kPopular = 'Top rated';
const String _kHome = 'Home & vehicle';
const String _kTech = 'Tech & gadgets';
const String _kPersonal = 'Personal & events';

const List<String> _kCategories = [
  _kAll,
  _kPopular,
  _kHome,
  _kTech,
  _kPersonal,
];

const List<_Service> _kServices = [
  _Service('Electrician', 'Electrical work', _kHome, Icons.electrical_services_rounded, 4.9),
  _Service('Plumber', 'Pipes & taps', _kHome, Icons.plumbing_rounded, 4.8),
  _Service('Carpenter', 'Furniture & wood', _kHome, Icons.carpenter_rounded, 4.7),
  _Service('Mason', 'Building work', _kHome, Icons.foundation_rounded, 4.6),
  _Service('Mechanic', 'Vehicle repair', _kHome, Icons.car_repair_rounded, 4.8),
  _Service('AC Technician', 'Cooling & AC', _kHome, Icons.ac_unit_rounded, 4.9),
  _Service('Painter', 'Painting work', _kHome, Icons.format_paint_rounded, 4.7),
  _Service('Cleaner', 'Home cleaning', _kHome, Icons.cleaning_services_rounded, 4.9),
  _Service('Gardener', 'Garden care', _kHome, Icons.yard_rounded, 4.6),
  _Service('Locksmith', 'Locks & keys', _kHome, Icons.lock_rounded, 4.8),
  _Service('Roofer', 'Roof repairs', _kHome, Icons.roofing_rounded, 4.5),
  _Service('Pest Control', 'Pest treatment', _kHome, Icons.pest_control_rounded, 4.8),
  _Service('Vehicle Electrician', 'Vehicle electronics', _kHome, Icons.battery_charging_full_rounded, 4.8),
  _Service('Computer Technician', 'Computer repair', _kTech, Icons.computer_rounded, 4.9),
  _Service('Phone Repair', 'Mobile devices', _kTech, Icons.phone_android_rounded, 4.7),
  _Service('Washing Machine Repair', 'Appliance repair', _kTech, Icons.local_laundry_service_rounded, 4.7),
  _Service('Refrigerator Repair', 'Fridge repair', _kTech, Icons.kitchen_rounded, 4.7),
  _Service('CCTV Technician', 'Security systems', _kTech, Icons.videocam_rounded, 4.9),
  _Service('Solar Technician', 'Solar systems', _kTech, Icons.solar_power_rounded, 5.0),
  _Service('Hairdresser', 'Hair styling', _kPersonal, Icons.content_cut_rounded, 4.8),
  _Service('Tailor', 'Clothing alterations', _kPersonal, Icons.checkroom_rounded, 4.6),
  _Service('Makeup Artist', 'Beauty services', _kPersonal, Icons.face_retouching_natural_rounded, 4.9),
  _Service('Photographer', 'Photo & events', _kPersonal, Icons.camera_alt_rounded, 4.9),
  _Service('Tutor', 'Learning support', _kPersonal, Icons.school_rounded, 4.9),
];

// ============================================================
// SCREEN
// ============================================================

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int unreadNotificationCount = 0;
  String searchQuery = '';
  String selectedCategory = _kAll;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUnreadNotificationCount();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // DATA & NAVIGATION
  // ----------------------------------------------------------

  Future<void> loadUnreadNotificationCount() async {
    try {
      final count = await ApiService.getUnreadNotificationCount();
      if (!mounted) return;
      setState(() => unreadNotificationCount = count);
    } catch (_) {
      // The badge is optional; fail silently.
    }
  }

  // Opens a screen, then refreshes the badge when the user comes back.
  Future<void> _open(Widget screen) async {
    FocusScope.of(context).unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (mounted) await loadUnreadNotificationCount();
  }

  void openService(String serviceName) =>
      _open(ProviderListScreen(serviceName: serviceName));

  void clearSearch() {
    searchController.clear();
    setState(() => searchQuery = '');
  }

  void resetFilters() {
    searchController.clear();
    setState(() {
      searchQuery = '';
      selectedCategory = _kAll;
    });
  }

  List<_Service> get filteredServices {
    final query = searchQuery.trim().toLowerCase();

    return _kServices.where((service) {
      final matchesQuery = query.isEmpty ||
          service.name.toLowerCase().contains(query) ||
          service.subtitle.toLowerCase().contains(query) ||
          service.category.toLowerCase().contains(query);

      final matchesCategory = selectedCategory == _kAll ||
          (selectedCategory == _kPopular && service.rating >= 4.9) ||
          service.category == selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final services = filteredServices;
    final isSearching = searchQuery.trim().isNotEmpty;
    final showProviderPromo = !isSearching && selectedCategory == _kAll;

    return Scaffold(
      backgroundColor: _kBackground,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: RefreshIndicator(
          color: _kBlack,
          backgroundColor: _kYellow,
          edgeOffset: 120,
          onRefresh: loadUnreadNotificationCount,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildCategorySelector()),
              SliverToBoxAdapter(child: _buildSectionTitle(services.length)),
              if (services.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState())
              else
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
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildServiceCard(services[index]),
                      childCount: services.length,
                    ),
                  ),
                ),
              if (showProviderPromo)
                SliverToBoxAdapter(child: _buildProviderPromo()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ----------------------------------------------------------
  // HEADER (brand, notifications, headline, search)
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

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      textInputAction: TextInputAction.search,
      onChanged: (value) => setState(() => searchQuery = value),
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _kBlack,
      ),
      cursorColor: _kBlack,
      decoration: InputDecoration(
        hintText: 'Try "plumber" or "AC repair"',
        hintStyle: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
          color: _kTextSecondary,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: _kBlack, size: 22),
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kYellow, width: 2),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // CATEGORIES
  // ----------------------------------------------------------

  Widget _buildCategorySelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _kCategories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = _kCategories[index];
            final selected = selectedCategory == category;

            return ChoiceChip(
              label: Text(category),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => selectedCategory = category),
              selectedColor: _kYellow,
              backgroundColor: Colors.white,
              side: BorderSide(color: selected ? _kYellow : _kBorder),
              labelStyle: TextStyle(
                color: _kBlack,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(int count) {
    final isSearching = searchQuery.trim().isNotEmpty;

    final title = isSearching
        ? 'Results for "${searchQuery.trim()}"'
        : (selectedCategory == _kAll ? 'All services' : selectedCategory);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
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

  // ----------------------------------------------------------
  // SERVICE CARD (with smaller, lighter background watermark)
  // ----------------------------------------------------------

  Widget _buildServiceCard(_Service service) {
    return Semantics(
      button: true,
      label: '${service.name}, ${service.subtitle}',
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
                // Smaller, lighter background watermark icon in the corner
                Positioned(
                  right: -12,
                  top: -12,
                  child: Icon(
                    service.icon,
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
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _kBlack,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            service.icon,
                            size: 20,
                            color: _kYellow,
                          ),
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
                                    service.subtitle,
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
  // EMPTY STATE
  // ----------------------------------------------------------

  Widget _buildEmptyState() {
    final isSearching = searchQuery.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
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
                : 'No services in this category',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kBlack,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check the spelling or try a broader term like "repair".',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.4, color: _kTextSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: resetFilters,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kBlack,
              side: const BorderSide(color: _kBlack, width: 1.2),
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Show all services',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // PROVIDER PROMO
  // ----------------------------------------------------------

  Widget _buildProviderPromo() {
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
                onPressed: () => _open(const BecomeProviderScreen()),
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
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // BOTTOM NAV
  // ----------------------------------------------------------

  Widget _buildBottomNav() {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: _kBlack,
        indicatorColor: _kYellow,
        surfaceTintColor: Colors.transparent,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? _kBlack : const Color(0xFFB5B5B0),
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? _kYellow : const Color(0xFFB5B5B0),
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) _open(const CustomerBookingsScreen());
          if (index == 2) _open(const CustomerProfileScreen());
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