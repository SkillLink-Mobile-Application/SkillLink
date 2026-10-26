
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import 'provider_profile_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.serviceName} Providers'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: loadProviders,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : providers.isEmpty
                  ? const Center(
                      child: Text('No providers found.'),
                    )
                  : RefreshIndicator(
                      onRefresh: loadProviders,
                      child: ListView.builder(
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person_rounded,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      phone,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
