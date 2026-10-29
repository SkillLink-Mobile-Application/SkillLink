import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';
import 'my_availability_screen.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kYellowSoft = Color(0xFFFFF3C4);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);
const Color _kDanger = Color(0xFFD92D20);
const Color _kSuccess = Color(0xFF1B7A3C);

const List<String> _kCategories = [
  'Electrician',
  'Plumber',
  'Carpenter',
  'Mason',
  'Mechanic',
  'AC Technician',
  'Computer Technician',
  'Phone Repair',
  'Painter',
];

IconData _categoryIcon(String category) {
  switch (category) {
    case 'Electrician':
      return Icons.electrical_services_rounded;
    case 'Plumber':
      return Icons.plumbing_rounded;
    case 'Carpenter':
      return Icons.carpenter_rounded;
    case 'Mason':
      return Icons.foundation_rounded;
    case 'Mechanic':
      return Icons.car_repair_rounded;
    case 'AC Technician':
      return Icons.ac_unit_rounded;
    case 'Computer Technician':
      return Icons.computer_rounded;
    case 'Phone Repair':
      return Icons.phone_android_rounded;
    case 'Painter':
      return Icons.format_paint_rounded;
    default:
      return Icons.build_rounded;
  }
}

String _formatPrice(dynamic value) {
  final number = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (number == null) return 'Rs. 0';
  final isWhole = number == number.roundToDouble();
  final text = isWhole ? number.toInt().toString() : number.toStringAsFixed(2);
  final parts = text.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return 'Rs. ${parts.length > 1 ? '$whole.${parts[1]}' : whole}';
}

//==================== My Services Screen ====================
class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  List<Map<String, dynamic>> services = [];

  bool isLoading = true;
  bool isSaving = false;
  bool hasError = false;

  String searchQuery = '';
  String? selectedCategory; // null = all

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _toast(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(text),
          backgroundColor: isError ? _kDanger : _kSuccess,
        ),
      );
  }

  List<Map<String, dynamic>> get _filteredServices {
    final query = searchQuery.trim().toLowerCase();
    return services.where((service) {
      final category = service['category']?.toString() ?? '';
      if (selectedCategory != null && category != selectedCategory) {
        return false;
      }
      if (query.isEmpty) return true;
      final name = service['name']?.toString().toLowerCase() ?? '';
      final description = service['description']?.toString().toLowerCase() ?? '';
      return name.contains(query) ||
          description.contains(query) ||
          category.toLowerCase().contains(query);
    }).toList();
  }

  List<String> get _usedCategories {
    final set = <String>{};
    for (final service in services) {
      final category = service['category']?.toString() ?? '';
      if (category.isNotEmpty) set.add(category);
    }
    return set.toList()..sort();
  }

  // ============================================================
  // LOAD SERVICES
  // ============================================================

  Future<void> loadServices() async {
    final email = Session.email;

    if (email.isEmpty) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
      });
      return;
    }

    try {
      final result = await ApiService.getProviderServices(email: email);

      if (!mounted) return;

      setState(() {
        services = (result ?? [])
            .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map),
            )
            .toList();
        isLoading = false;
        hasError = false;
        // Reset filter if the chosen category no longer exists
        if (selectedCategory != null &&
            !_usedCategories.contains(selectedCategory)) {
          selectedCategory = null;
        }
      });
    } catch (e) {
      debugPrint('Load Services Error: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  // ============================================================
  // SERVICE FORM (bottom sheet)
  // ============================================================

  Future<Map<String, dynamic>?> showServiceForm({
    Map<String, dynamic>? service,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFAFAF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ServiceFormSheet(service: service),
    );
  }

  // ============================================================
  // ADD SERVICE
  // ============================================================

  Future<void> addService() async {
    final email = Session.email;

    if (email.isEmpty) {
      _toast('User session not found. Please login again.', isError: true);
      return;
    }

    final data = await showServiceForm();
    if (data == null || !mounted) return;

    setState(() => isSaving = true);

    bool success = false;
    try {
      success = await ApiService.addService(
        email: email,
        name: data['name'],
        category: data['category'],
        description: data['description'],
        price: data['price'],
      );
    } catch (e) {
      debugPrint('Add Service Error: $e');
    }

    if (!mounted) return;
    setState(() => isSaving = false);

    if (success) {
      _toast('Service added successfully!');
      await loadServices();
    } else {
      _toast('Could not add service.', isError: true);
    }
  }

  // ============================================================
  // EDIT SERVICE
  // ============================================================

  Future<void> editService(Map<String, dynamic> service) async {
    final email = Session.email;

    if (email.isEmpty) {
      _toast('User session not found. Please login again.', isError: true);
      return;
    }

    final serviceId = int.tryParse(service['id'].toString());
    if (serviceId == null) {
      _toast('Invalid service ID.', isError: true);
      return;
    }

    final data = await showServiceForm(service: service);
    if (data == null || !mounted) return;

    setState(() => isSaving = true);

    try {
      final success = await ApiService.updateService(
        id: serviceId,
        email: email,
        name: data['name'].toString(),
        category: data['category'].toString(),
        description: data['description'].toString(),
        price: (data['price'] as num).toDouble(),
      );

      if (!mounted) return;
      setState(() => isSaving = false);

      if (success) {
        _toast('Service updated successfully!');
        await loadServices();
      } else {
        _toast('Could not update service.', isError: true);
      }
    } catch (e) {
      debugPrint('EDIT ERROR: $e');
      if (!mounted) return;
      setState(() => isSaving = false);
      _toast('Update error: $e', isError: true);
    }
  }

  // ============================================================
  // DELETE SERVICE
  // ============================================================

  Future<void> deleteService(Map<String, dynamic> service) async {
    final email = Session.email;

    if (email.isEmpty) {
      _toast('User session not found. Please login again.', isError: true);
      return;
    }

    final serviceId = int.tryParse(service['id'].toString());
    if (serviceId == null) {
      _toast('Invalid service ID.', isError: true);
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kDanger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: _kDanger, size: 28),
          ),
          title: const Text(
            'Delete service?',
            style: TextStyle(fontWeight: FontWeight.w800, color: _kBlack),
          ),
          content: Text(
            '"${service['name']}" will be removed from your profile. '
            'This cannot be undone.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kTextSecondary, height: 1.4),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: _kBlack,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kDanger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    setState(() => isSaving = true);

    bool success = false;
    try {
      success = await ApiService.deleteService(id: serviceId, email: email);
    } catch (e) {
      debugPrint('Delete Service Error: $e');
    }

    if (!mounted) return;
    setState(() => isSaving = false);

    if (success) {
      _toast('Service deleted successfully!');
      await loadServices();
    } else {
      _toast('Could not delete service.', isError: true);
    }
  }

  // ============================================================
  // UI PIECES
  // ============================================================

  Widget _buildSummary() {
    final categories = _usedCategories.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kBlack,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kYellow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.handyman_rounded, color: _kBlack),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${services.length} ${services.length == 1 ? 'service' : 'services'} listed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  categories == 0
                      ? 'Add your first service to get bookings'
                      : 'Across $categories ${categories == 1 ? 'category' : 'categories'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      cursorColor: _kBlack,
      textInputAction: TextInputAction.search,
      onChanged: (value) => setState(() => searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search your services',
        hintStyle: const TextStyle(color: _kTextSecondary, fontSize: 14.5),
        prefixIcon: const Icon(Icons.search_rounded, color: _kBlack),
        suffixIcon: searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, color: _kTextSecondary),
                onPressed: () {
                  _searchController.clear();
                  setState(() => searchQuery = '');
                },
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kYellow, width: 2),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = _usedCategories;
    if (categories.length < 2) return const SizedBox.shrink();

    Widget chip(String label, bool selected, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          backgroundColor: Colors.white,
          selectedColor: _kBlack,
          side: BorderSide(color: selected ? _kBlack : _kBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: TextStyle(
            color: selected ? _kYellow : _kBlack,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            chip('All', selectedCategory == null,
                () => setState(() => selectedCategory = null)),
            for (final category in categories)
              chip(category, selectedCategory == category,
                  () => setState(() => selectedCategory = category)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _kYellow.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: _kBlack),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _kBlack,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kTextSecondary, height: 1.4),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kYellow,
                foregroundColor: _kBlack,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final category = service['category']?.toString() ?? '';
    final description = service['description']?.toString() ?? '';

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kYellow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_categoryIcon(category), color: _kBlack),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: _kBlack,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kBlack,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: _kYellow,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kYellowSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatPrice(service['price']),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _kBlack,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kTextSecondary,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFEFEFEA)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kBlack,
                      side: const BorderSide(color: _kBlack, width: 1.3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: isSaving ? null : () => editService(service),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kDanger,
                      side: const BorderSide(color: _kDanger, width: 1.3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: isSaving ? null : () => deleteService(service),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _kBlack),
      );
    }

    final filtered = _filteredServices;

    return RefreshIndicator(
      color: _kBlack,
      backgroundColor: _kYellow,
      onRefresh: loadServices,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          if (hasError && services.isEmpty)
            _buildMessageState(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load services',
              subtitle: Session.email.isEmpty
                  ? 'User session not found. Please login again.'
                  : 'Check your connection and try again.',
              actionLabel: Session.email.isEmpty ? null : 'Retry',
              onAction: () {
                setState(() => isLoading = true);
                loadServices();
              },
            )
          else if (services.isEmpty)
            _buildMessageState(
              icon: Icons.build_circle_outlined,
              title: 'No services added yet.',
              subtitle:
                  'Add what you offer, your price and a short description so customers can book you.',
              actionLabel: 'Add Service',
              onAction: addService,
            )
          else ...[
            _buildSummary(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            _buildCategoryChips(),
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              _buildMessageState(
                icon: Icons.search_off_rounded,
                title: 'No matching services',
                subtitle: 'Try a different search or category.',
                actionLabel: 'Clear filters',
                onAction: () {
                  _searchController.clear();
                  setState(() {
                    searchQuery = '';
                    selectedCategory = null;
                  });
                },
              )
            else
              for (final service in filtered) _buildServiceCard(service),
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
          'My Services',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'My Availability',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MyAvailabilityScreen(),
                ),
              );
            },
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          const SizedBox(width: 8),
        ],
        bottom: isSaving
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: _kYellow,
                  backgroundColor: Colors.transparent,
                ),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSaving ? null : addService,
        backgroundColor: isSaving ? _kBorder : _kYellow,
        foregroundColor: _kBlack,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Service',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _buildBody(),
    );
  }
}

// ============================================================
// SERVICE FORM SHEET
// Owns its own controllers so they are disposed safely.
// ============================================================
class _ServiceFormSheet extends StatefulWidget {
  final Map<String, dynamic>? service;

  const _ServiceFormSheet({this.service});

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late String _category;
  late final List<String> _categoryOptions;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;

    _nameController = TextEditingController(text: s?['name']?.toString() ?? '');
    _descriptionController =
        TextEditingController(text: s?['description']?.toString() ?? '');

    String priceText = '';
    final rawPrice = s?['price'];
    if (rawPrice != null) {
      final number = rawPrice is num ? rawPrice : num.tryParse('$rawPrice');
      if (number != null) {
        priceText = number == number.roundToDouble()
            ? number.toInt().toString()
            : number.toString();
      }
    }
    _priceController = TextEditingController(text: priceText);

    _category = s?['category']?.toString() ?? _kCategories.first;
    _categoryOptions = [..._kCategories];
    if (!_categoryOptions.contains(_category)) {
      _categoryOptions.add(_category);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 14.5),
      floatingLabelStyle:
          const TextStyle(color: _kBlack, fontWeight: FontWeight.w700),
      hintStyle: const TextStyle(color: _kTextSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: _kBlack, size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      border: border(_kBorder),
      enabledBorder: border(_kBorder),
      focusedBorder: border(_kYellow, 2),
      errorBorder: border(_kDanger),
      focusedErrorBorder: border(_kDanger, 2),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'category': _category,
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _kYellow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isEditing ? 'Edit Service' : 'Add Service',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _kBlack,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                cursorColor: _kBlack,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  label: 'Service Name',
                  hint: 'e.g. House Wiring',
                  icon: Icons.build_outlined,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Please enter a service name';
                  if (text.length < 3) return 'Name is too short';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                decoration: _decoration(
                  label: 'Category',
                  icon: Icons.category_outlined,
                ),
                items: _categoryOptions
                    .map((c) => DropdownMenuItem<String>(
                          value: c,
                          child: Row(
                            children: [
                              Icon(_categoryIcon(c), size: 18, color: _kBlack),
                              const SizedBox(width: 10),
                              Text(c),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 300,
                cursorColor: _kBlack,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                decoration: _decoration(
                  label: 'Description',
                  hint: 'Describe what is included in your service',
                  icon: Icons.description_outlined,
                ),
                validator: (value) {
                  if ((value?.trim() ?? '').isEmpty) {
                    return 'Please add a short description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                cursorColor: _kBlack,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: _decoration(
                  label: 'Price (Rs.)',
                  hint: 'Enter service price',
                  icon: Icons.payments_outlined,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Please enter a price';
                  final price = double.tryParse(text);
                  if (price == null || price < 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kBlack,
                        side: const BorderSide(color: _kBorder, width: 1.3),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle:
                            const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kYellow,
                        foregroundColor: _kBlack,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle:
                            const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      child: Text(_isEditing ? 'Update' : 'Add Service'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}