import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/section_header.dart';
import 'become_provider_screen.dart';
import 'provider_list_screen.dart';
import 'customer_bookings_screen.dart';
import 'customer_profile_screen.dart';
import 'notifications_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int unreadNotificationCount = 0;
  int currentNavIndex = 0;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String selectedCategory = 'All';

  // Yellow and Black theme custom color constants
  static const Color primaryYellow = Color(0xFFF59E0B);
  static const Color darkYellow = Color(0xFFD97706);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF9CA3AF);

  final List<String> categories = ['All', 'Popular', 'Home Repair', 'Tech & Gadgets', 'Beauty & Care'];

  final List<Map<String, dynamic>> services = [
    {
      'name': 'Electrician',
      'subtitle': 'Electrical work',
      'category': 'Home Repair',
      'icon': Icons.electrical_services_rounded,
      'rating': 4.9,
    },
    {
      'name': 'Plumber',
      'subtitle': 'Pipes & taps',
      'category': 'Home Repair',
      'icon': Icons.plumbing_rounded,
      'rating': 4.8,
    },
    {
      'name': 'Carpenter',
      'subtitle': 'Furniture & wood',
      'category': 'Home Repair',
      'icon': Icons.carpenter_rounded,
      'rating': 4.7,
    },
    {
      'name': 'Mason',
      'subtitle': 'Building work',
      'category': 'Home Repair',
      'icon': Icons.foundation_rounded,
      'rating': 4.6,
    },
    {
      'name': 'Mechanic',
      'subtitle': 'Vehicle repair',
      'category': 'Home Repair',
      'icon': Icons.car_repair_rounded,
      'rating': 4.8,
    },
    {
      'name': 'AC Technician',
      'subtitle': 'Cooling & AC',
      'category': 'Home Repair',
      'icon': Icons.ac_unit_rounded,
      'rating': 4.9,
    },
    {
      'name': 'Computer Technician',
      'subtitle': 'Computer repair',
      'category': 'Tech & Gadgets',
      'icon': Icons.computer_rounded,
      'rating': 4.9,
    },
    {
      'name': 'Phone Repair',
      'subtitle': 'Mobile devices',
      'category': 'Tech & Gadgets',
      'icon': Icons.phone_android_rounded,
      'rating': 4.7,
    },
    {
      'name': 'Painter',
      'subtitle': 'Painting work',
      'category': 'Home Repair',
      'icon': Icons.format_paint_rounded,
      'rating': 4.7,
    },
    {
      'name': 'Cleaner',
      'subtitle': 'Home cleaning',
      'category': 'Home Repair',
      'icon': Icons.cleaning_services_rounded,
      'rating': 4.9,
    },
    {
      'name': 'Gardener',
      'subtitle': 'Garden care',
      'category': 'Home Repair',
      'icon': Icons.yard_rounded,
      'rating': 4.6,
    },
    {
      'name': 'Locksmith',
      'subtitle': 'Locks & keys',
      'category': 'Home Repair',
      'icon': Icons.lock_rounded,
      'rating': 4.8,
    },
    {
      'name': 'Roofer',
      'subtitle': 'Roof repairs',
      'category': 'Home Repair',
      'icon': Icons.roofing_rounded,
      'rating': 4.5,
    },
    {
      'name': 'Pest Control',
      'subtitle': 'Pest treatment',
      'category': 'Home Repair',
      'icon': Icons.pest_control_rounded,
      'rating': 4.8,
    },
    {
      'name': 'Washing Machine Repair',
      'subtitle': 'Appliance repair',
      'category': 'Tech & Gadgets',
      'icon': Icons.local_laundry_service_rounded,
      'rating': 4.7,
    },
    {
      'name': 'Refrigerator Repair',
      'subtitle': 'Fridge repair',
      'category': 'Tech & Gadgets',
      'icon': Icons.kitchen_rounded,
      'rating': 4.7,
    },
    {
      'name': 'CCTV Technician',
      'subtitle': 'Security systems',
      'category': 'Tech & Gadgets',
      'icon': Icons.videocam_rounded,
      'rating': 4.9,
    },
    {
      'name': 'Solar Technician',
      'subtitle': 'Solar systems',
      'category': 'Tech & Gadgets',
      'icon': Icons.solar_power_rounded,
      'rating': 5.0,
    },
    {
      'name': 'Hairdresser',
      'subtitle': 'Hair styling',
      'category': 'Beauty & Care',
      'icon': Icons.content_cut_rounded,
      'rating': 4.8,
    },
    {
      'name': 'Tailor',
      'subtitle': 'Clothing alterations',
      'category': 'Beauty & Care',
      'icon': Icons.checkroom_rounded,
      'rating': 4.6,
    },
    {
      'name': 'Makeup Artist',
      'subtitle': 'Beauty services',
      'category': 'Beauty & Care',
      'icon': Icons.face_retouching_natural_rounded,
      'rating': 4.9,
    },
    {
      'name': 'Photographer',
      'subtitle': 'Photo & events',
      'category': 'Beauty & Care',
      'icon': Icons.camera_alt_rounded,
      'rating': 4.9,
    },
    {
      'name': 'Tutor',
      'subtitle': 'Learning support',
      'category': 'Beauty & Care',
      'icon': Icons.school_rounded,
      'rating': 4.9,
    },
    {
      'name': 'Vehicle Electrician',
      'subtitle': 'Vehicle electronics',
      'category': 'Home Repair',
      'icon': Icons.battery_charging_full_rounded,
      'rating': 4.8,
    },
  ];

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

  Future<void> loadUnreadNotificationCount() async {
    try {
      final count = await ApiService.getUnreadNotificationCount();
      if (!mounted) return;
      setState(() {
        unreadNotificationCount = count;
      });
    } catch (_) {}
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    if (mounted) {
      await loadUnreadNotificationCount();
    }
  }

  void openService(String serviceName) {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderListScreen(serviceName: serviceName),
      ),
    );
  }

  void clearSearch() {
    searchController.clear();
    setState(() {
      searchQuery = '';
    });
  }

  // ---------------------------------------------------------------------------
  // UI Widgets (Yellow & Black Theme)
  // ---------------------------------------------------------------------------

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: primaryYellow,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryYellow.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.handyman_rounded, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SkillLink',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: darkYellow),
                      const SizedBox(width: 3),
                      const Text(
                        'Sri Lanka',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: openNotifications,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: textDark,
                    size: 22,
                  ),
                ),
              ),
              if (unreadNotificationCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: primaryYellow,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      unreadNotificationCount > 99 ? '99+' : unreadNotificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSearchCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1E1E),
            Color(0xFF111111),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryYellow.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 24,
                decoration: BoxDecoration(
                  color: primaryYellow,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Find Trusted Experts',
                style: TextStyle(
                  color: primaryYellow,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'For Your Home & Office',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
              decoration: InputDecoration(
                hintText: 'Search any professional service...',
                hintStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: primaryYellow,
                  size: 22,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: clearSearch,
                        icon: const Icon(Icons.close_rounded, size: 18, color: textMuted),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(
                  color: isSelected ? primaryYellow : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryYellow.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? primaryYellow : textMuted,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryYellow.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.verified_user_rounded, color: primaryYellow, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you a skilled professional?',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Join SkillLink today and scale your business.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BecomeProviderScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryYellow,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // Uniform, Professional Service Card styled with consistent Yellow & Dark Theme accents
  Widget _buildServiceCard(Map<String, dynamic> service) {
    final icon = service['icon'] as IconData;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openService(service['name'] as String),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, size: 22, color: darkYellow),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_outward_rounded, size: 14, color: textDark),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  service['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  service['subtitle'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: primaryYellow.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 32, color: darkYellow),
            ),
            const SizedBox(height: 14),
            const Text(
              'No services found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try adjusting your search terms or category filter.',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: const Border(top: BorderSide(color: Color(0xFF222222), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.calendar_month_rounded, 'Bookings'),
              _buildNavItem(2, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentNavIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          currentNavIndex = index;
        });
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerBookingsScreen()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryYellow.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? primaryYellow : textMuted,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: primaryYellow,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();

    final filteredServices = services.where((service) {
      final name = service['name'].toString().toLowerCase();
      final subtitle = service['subtitle'].toString().toLowerCase();
      final category = service['category'].toString();

      final matchesQuery = name.contains(query) || subtitle.contains(query);
      final matchesCategory = selectedCategory == 'All' ||
          (selectedCategory == 'Popular' && double.parse(service['rating'].toString()) >= 4.9) ||
          category == selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              const SizedBox(height: 20),
              _buildHeroSearchCard(),
              const SizedBox(height: 26),
              _buildCategorySelector(),
              const SizedBox(height: 30),
              if (searchQuery.isEmpty && selectedCategory == 'All') ...[
                _buildPromoBanner(),
                const SizedBox(height: 30),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SectionHeader(
                          title: searchQuery.isEmpty ? 'Explore Services' : 'Search Results',
                        ),
                        Text(
                          '${filteredServices.length} available',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (filteredServices.isEmpty)
                      _buildEmptyState()
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredServices.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.15,
                        ),
                        itemBuilder: (context, index) {
                          return _buildServiceCard(filteredServices[index]);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}