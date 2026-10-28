import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import 'provider_profile_screen.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);
const Color _kDanger = Color(0xFFD92D20);

//==================== Provider List Screen ====================

class ProviderListScreen extends StatefulWidget {
  final String serviceName;

  const ProviderListScreen({
    super.key,
    required this.serviceName,
  });

  @override
  State<ProviderListScreen> createState() =>
      _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  List<Map<String, dynamic>> providers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadProviders();
  }

  Future<void> loadProviders() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final services = await ApiService.getServicesByCategory(
        widget.serviceName,
      );

      final List<Map<String, dynamic>> providerList = [];

      for (final service in services) {
        if (service is! Map) continue;

        final provider = service['provider'];

        if (provider is! Map) continue;

        final providerMap = Map<String, dynamic>.from(provider);
        final providerId = providerMap['id'];

        if (providerId == null) continue;

        final alreadyAdded = providerList.any(
          (item) => item['id'] == providerId,
        );

        if (!alreadyAdded) {
          providerList.add(providerMap);
        }
      }

      if (!mounted) return;

      setState(() {
        providers = providerList;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Load Providers Error: $e');

      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to load providers. Please try again.';
        isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: _kDanger.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: _kDanger,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kBlack,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kYellow,
                foregroundColor: _kBlack,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: loadProviders,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _kYellow.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_rounded,
              size: 44,
              color: _kBlack,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No providers found.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kTextSecondary,
            ),
          ),
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
        title: Text(
          '${widget.serviceName} Providers',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
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
          : errorMessage != null
              ? _buildErrorState()
              : providers.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: _kBlack,
                      backgroundColor: _kYellow,
                      onRefresh: loadProviders,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: providers.length,
                        itemBuilder: (context, index) {
                          final provider = providers[index];

                          return _providerCard(
                            context,
                            provider: provider,
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _providerCard(
    BuildContext context, {
    required Map<String, dynamic> provider,
  }) {
    final name =
        provider['name']?.toString() ?? 'Unknown Provider';

    final phone =
        provider['phone']?.toString() ?? 'No phone number';

    final email =
        provider['email']?.toString() ?? 'No email';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          splashColor: _kYellow.withValues(alpha: 0.15),
          highlightColor: _kYellow.withValues(alpha: 0.08),
          onTap: () async {
            if (email == 'No email' || email.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Provider email is unavailable.'),
                ),
              );
              return;
            }

            final profile =
                await ApiService.getProviderProfile(email);

            if (!context.mounted) return;

            if (profile == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Provider profile not found.'),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProviderProfileScreen(
                  name: name,
                  location: profile['location']?.toString() ??
                      'Location not available',
                  experience:
                      '${profile['experience']?.toString() ?? 'N/A'} years experience',
                  rating: 'New',
                  serviceName: widget.serviceName,
                  description:
                      profile['description']?.toString() ??
                          'No description available',
                  email: email,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _kYellow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kYellow.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 30,
                    color: _kBlack,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.3,
                          color: _kBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_rounded,
                            size: 14,
                            color: _kBlack,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _kTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_rounded,
                            size: 14,
                            color: _kBlack,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _kTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _kBlack,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: _kYellow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}