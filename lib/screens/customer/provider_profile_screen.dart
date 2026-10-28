import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';
import 'request_service_screen.dart';
import 'reviews_screen.dart';
import 'chat_screen.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);

//==================== Provider Profile Screen ====================

class ProviderProfileScreen extends StatefulWidget {
  final String name;
  final String location;
  final String experience;
  final String rating;
  final String serviceName;
  final String description;
  final String email;

  const ProviderProfileScreen({
    super.key,
    required this.name,
    required this.location,
    required this.experience,
    required this.rating,
    required this.serviceName,
    required this.description,
    required this.email,
  });

  @override
  State<ProviderProfileScreen> createState() =>
      _ProviderProfileScreenState();
}

class _ProviderProfileScreenState
    extends State<ProviderProfileScreen> {
  List<dynamic> services = [];
  List<dynamic> reviews = [];

  bool isLoadingServices = true;
  bool isLoadingReviews = true;

  double averageRating = 0.0;

  @override
  void initState() {
    super.initState();

    loadProviderServices();
    loadProviderReviews();
  }

  // ==================== LOAD SERVICES ====================

  Future<void> loadProviderServices() async {
    try {
      final result = await ApiService.getProviderServices(
        email: widget.email,
      );

      if (!mounted) return;

      setState(() {
        services = result ?? [];
        isLoadingServices = false;
      });
    } catch (e) {
      debugPrint('SERVICES ERROR: $e');

      if (!mounted) return;

      setState(() {
        services = [];
        isLoadingServices = false;
      });
    }
  }

  // ==================== LOAD REVIEWS ====================

  Future<void> loadProviderReviews() async {
    debugPrint('================================');
    debugPrint('LOADING REVIEWS');
    debugPrint('EMAIL: ${widget.email}');
    debugPrint('================================');

    try {
      final result =
          await ApiService.getProviderReviews(widget.email);

      debugPrint('REVIEWS API RESULT: $result');
      debugPrint('NUMBER OF REVIEWS: ${result.length}');

      double totalRating = 0.0;

      for (final review in result) {
        debugPrint('REVIEW: $review');

        final ratingValue =
            double.tryParse(
                  review['rating']?.toString() ?? '0',
                ) ??
                0.0;

        debugPrint('RATING VALUE: $ratingValue');

        totalRating += ratingValue;
      }

      double calculatedAverage = 0.0;

      if (result.isNotEmpty) {
        calculatedAverage =
            totalRating / result.length;
      }

      debugPrint('TOTAL RATING: $totalRating');
      debugPrint(
        'AVERAGE RATING: $calculatedAverage',
      );

      if (!mounted) return;

      setState(() {
        reviews = result;
        averageRating = calculatedAverage;
        isLoadingReviews = false;
      });

      debugPrint(
        'FINAL AVERAGE RATING: $averageRating',
      );
    } catch (e) {
      debugPrint('================================');
      debugPrint('REVIEWS ERROR');
      debugPrint('$e');
      debugPrint('================================');

      if (!mounted) return;

      setState(() {
        reviews = [];
        averageRating = 0.0;
        isLoadingReviews = false;
      });
    }
  }

  // ==================== UI HELPERS ====================

  Widget _buildServiceCard(dynamic service) {
    final serviceName =
        service['name']?.toString() ??
            'Service';

    final category =
        service['category']?.toString() ??
            '';

    final description =
        service['description']
                ?.toString() ??
            '';

    final price =
        service['price']?.toString() ??
            '0';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  serviceName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: _kBlack,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _kYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Rs. $price',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _kBlack,
                  ),
                ),
              ),
            ],
          ),

          if (category.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              category,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kBlack,
              ),
            ),
          ],

          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: _kTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

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
          'Provider Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ==================== PROFILE ICON ====================

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
              child: const CircleAvatar(
                radius: 55,
                backgroundColor: Color(0xFFFFF3C4),
                child: Icon(
                  Icons.person_rounded,
                  size: 58,
                  color: _kBlack,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================== NAME ====================

            Text(
              widget.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: _kBlack,
              ),
            ),

            const SizedBox(height: 8),

            // ==================== SERVICE CATEGORY ====================

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _kBlack,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                widget.serviceName,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _kYellow,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ==================== RATING ====================

            if (isLoadingReviews)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _kBlack,
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: _kYellow,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          averageRating > 0
                              ? averageRating
                                  .toStringAsFixed(1)
                              : 'No ratings',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _kBlack,
                          ),
                        ),
                        if (reviews.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(${reviews.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              color: _kTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ==================== VIEW REVIEWS ====================

                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: _kBlack,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReviewsScreen(
                            providerEmail:
                                widget.email,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.rate_review_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      'View Reviews',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: _kYellow,
                        decorationThickness: 2.5,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // ==================== LOCATION ====================

            _InfoTile(
              icon: Icons.location_on_rounded,
              title: 'Location',
              subtitle: widget.location,
            ),

            // ==================== EXPERIENCE ====================

            _InfoTile(
              icon: Icons.work_rounded,
              title: 'Experience',
              subtitle: widget.experience,
            ),

            // ==================== DESCRIPTION ====================

            _InfoTile(
              icon: Icons.description_rounded,
              title: 'About',
              subtitle: widget.description,
            ),

            const SizedBox(height: 20),

            // ==================== SERVICES ====================

            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _kYellow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Services Offered',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: _kBlack,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            if (isLoadingServices)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: _kBlack,
                ),
              )
            else if (services.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No services available.',
                  style: TextStyle(
                    color: _kTextSecondary,
                  ),
                ),
              )
            else
              Column(
                children:
                    services.map((service) {
                  return _buildServiceCard(service);
                }).toList(),
              ),

            const SizedBox(height: 12),

            // ==================== VERIFIED ====================

            const _InfoTile(
              icon: Icons.verified_rounded,
              title: 'Verified Provider',
              subtitle:
                  'Identity verification will be available later.',
              dark: true,
            ),

            const SizedBox(height: 12),

            // ==================== CHAT WITH PROVIDER ====================

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kBlack,
                  side: const BorderSide(
                    color: _kBlack,
                    width: 1.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        otherUserEmail: widget.email,
                        otherUserName: widget.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                ),
                label: const Text(
                  'Chat with Provider',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),


            // ==================== REQUEST SERVICE ====================

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RequestServiceScreen(
                        providerName: widget.name,
                        serviceName:
                            widget.serviceName,
                        customerEmail:
                            Session.email,
                        providerEmail:
                            widget.email,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Request Service',
                  style: TextStyle(
                    fontSize: 17,
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

// ==================== Info Tile ====================

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool dark;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.dark = false,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: dark ? _kBlack : _kYellow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 23,
              color: dark ? _kYellow : _kBlack,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
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
                      fontSize: 14.5,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: _kBlack,
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
}