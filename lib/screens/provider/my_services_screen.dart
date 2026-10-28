import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);
const Color _kDanger = Color(0xFFD92D20);
const Color _kSuccess = Color(0xFF1B7A3C);

//==================== My Services Screen ====================
class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() =>
      _MyServicesScreenState();
}

class _MyServicesScreenState
    extends State<MyServicesScreen> {
  List<dynamic> services = [];

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  InputDecoration _dialogFieldDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: _kTextSecondary,
        fontSize: 14.5,
      ),
      floatingLabelStyle: const TextStyle(
        color: _kBlack,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(
        color: _kTextSecondary,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: _kBlack, size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 14,
      ),
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
    );
  }

  ShapeBorder get _dialogShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      );

  // ============================================================
  // LOAD SERVICES
  // ============================================================

  Future<void> loadServices() async {
    final email = Session.email;

    if (email.isEmpty) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      return;
    }

    try {
      final result =
          await ApiService.getProviderServices(
        email: email,
      );

      if (!mounted) return;

      setState(() {
        services = result ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Load Services Error: $e');

      if (!mounted) return;

      setState(() {
        services = [];
        isLoading = false;
      });
    }
  }
  

  // ============================================================
  // SERVICE FORM DIALOG
  // ============================================================
Future<Map<String, dynamic>?> showServiceForm({
  Map<String, dynamic>? service,
}) async {
  final bool isEditing = service != null;

  final nameController = TextEditingController(
    text: isEditing
        ? service['name']?.toString() ?? ''
        : '',
  );

  final descriptionController = TextEditingController(
    text: isEditing
        ? service['description']?.toString() ?? ''
        : '',
  );

  final priceController = TextEditingController(
    text: isEditing
        ? service['price']?.toString() ?? ''
        : '',
  );

  String selectedCategory = isEditing
      ? service['category']?.toString() ?? 'Electrician'
      : 'Electrician';

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (
          dialogContext,
          setDialogState,
        ) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFAFAF7),
            surfaceTintColor: Colors.transparent,
            shape: _dialogShape,
            title: Row(
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
                Text(
                  isEditing
                      ? 'Edit Service'
                      : 'Add Service',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _kBlack,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),

            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),

                  // ==================== SERVICE NAME ====================

                  TextField(
                    controller: nameController,
                    cursorColor: _kBlack,
                    textInputAction: TextInputAction.next,
                    decoration: _dialogFieldDecoration(
                      label: 'Service Name',
                      hint: 'e.g. House Wiring',
                      icon: Icons.build_outlined,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // ==================== CATEGORY ====================

                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    decoration: _dialogFieldDecoration(
                      label: 'Category',
                      icon: Icons.category_outlined,
                    ),
                    items: const [
                      'Electrician',
                      'Plumber',
                      'Carpenter',
                      'Mason',
                      'Mechanic',
                      'AC Technician',
                      'Computer Technician',
                      'Phone Repair',
                      'Painter',
                    ].map(
                      (category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // ==================== DESCRIPTION ====================

                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    cursorColor: _kBlack,
                    textInputAction: TextInputAction.newline,
                    decoration: _dialogFieldDecoration(
                      label: 'Description',
                      hint: 'Describe your service',
                      icon: Icons.description_outlined,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // ==================== PRICE ====================

                  TextField(
                    controller: priceController,
                    cursorColor: _kBlack,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    decoration: _dialogFieldDecoration(
                      label: 'Price',
                      hint: 'Enter service price',
                      icon: Icons.payments_outlined,
                    ),
                  ),
                ],
              ),
            ),

            // ==================== ACTIONS ====================

            actions: [

              // ==================== CANCEL ====================

              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: _kBlack,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () async {
                  // Close keyboard
                  FocusManager.instance.primaryFocus?.unfocus();

                  // Give Android keyboard time to close
                  await Future.delayed(
                    const Duration(milliseconds: 300),
                  );

                  // Close dialog
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text(
                  'Cancel',
                ),
              ),

              // ==================== ADD / UPDATE ====================

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kYellow,
                  foregroundColor: _kBlack,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: () async {
                  final name =
                      nameController.text.trim();

                  final description =
                      descriptionController.text.trim();

                  final priceText =
                      priceController.text.trim();

                  // ==================== VALIDATION ====================

                  if (name.isEmpty ||
                      description.isEmpty ||
                      priceText.isEmpty) {
                    FocusManager.instance
                        .primaryFocus
                        ?.unfocus();

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please fill all fields.',
                        ),
                      ),
                    );

                    return;
                  }

                  final price =
                      double.tryParse(priceText);

                  if (price == null || price < 0) {
                    FocusManager.instance
                        .primaryFocus
                        ?.unfocus();

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a valid price.',
                        ),
                      ),
                    );

                    return;
                  }

                  // ==================== CLOSE KEYBOARD ====================

                  FocusManager.instance
                      .primaryFocus
                      ?.unfocus();

                  // Give Android keyboard time to close
                  await Future.delayed(
                    const Duration(milliseconds: 300),
                  );

                  // ==================== CLOSE DIALOG ====================

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop({
                      'name': name,
                      'category': selectedCategory,
                      'description': description,
                      'price': price,
                    });
                  }
                },
                child: Text(
                  isEditing
                      ? 'Update'
                      : 'Add Service',
                ),
              ),
            ],
          );
        },
      );
    },
  );

  // ==================== DISPOSE CONTROLLERS ====================

  nameController.dispose();
  descriptionController.dispose();
  priceController.dispose();

  return result;
}


  // ============================================================
  // ADD SERVICE
  // ============================================================

  Future<void> addService() async {
    final email = Session.email;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'User session not found. Please login again.',
          ),
        ),
      );

      return;
    }

    final data =
        await showServiceForm();

    if (data == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      isSaving = true;
    });

    final success =
        await ApiService.addService(
      email: email,
      name: data['name'],
      category: data['category'],
      description: data['description'],
      price: data['price'],
    );

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Service added successfully!',
          ),
          backgroundColor:
              _kSuccess,
        ),
      );

      await loadServices();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not add service.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // EDIT SERVICE
  // ============================================================
  Future<void> editService(
  Map<String, dynamic> service,
) async {
  final email = Session.email;

  if (email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'User session not found. Please login again.',
        ),
      ),
    );
    return;
  }

  final serviceId = int.tryParse(
    service['id'].toString(),
  );

  if (serviceId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid service ID.'),
      ),
    );
    return;
  }

  // Open edit form
  final data = await showServiceForm(
    service: service,
  );

  // User cancelled
  if (data == null) {
    return;
  }

  // Make sure screen is still active
  if (!mounted) {
    return;
  }

  debugPrint('EDIT: FORM CLOSED');
  debugPrint('EDIT: API CALL STARTED');

  setState(() {
    isSaving = true;
  });

  try {
    final success = await ApiService.updateService(
      id: serviceId,
      email: email,
      name: data['name'].toString(),
      category: data['category'].toString(),
      description: data['description'].toString(),
      price: (data['price'] as num).toDouble(),
    );

    debugPrint('EDIT: API CALL FINISHED - $success');

    if (!mounted) {
      return;
    }

    setState(() {
      isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Service updated successfully!',
          ),
          backgroundColor: _kSuccess,
        ),
      );

      await loadServices();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not update service.',
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('EDIT ERROR: $e');

    if (!mounted) {
      return;
    }

    setState(() {
      isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Update error: $e',
        ),
      ),
    );
  }
}
  
  // ============================================================
  // DELETE SERVICE
  // ============================================================

  Future<void> deleteService(
      Map<String, dynamic> service) async {

    final email = Session.email;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'User session not found. Please login again.',
          ),
        ),
      );

      return;
    }

    final serviceId =
        int.tryParse(
      service['id'].toString(),
    );

    if (serviceId == null) {
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: _dialogShape,
          title: const Text(
            'Delete Service',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _kBlack,
            ),
          ),
          content: Text(
            'Are you sure you want to delete '
            '"${service['name']}"?',
            style: const TextStyle(
              color: _kTextSecondary,
              height: 1.4,
            ),
          ),
          actions: [

            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: _kBlack,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kDanger,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    if (!mounted) return;

    setState(() {
      isSaving = true;
    });

    final success =
        await ApiService.deleteService(
      id: serviceId,
      email: email,
    );

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Service deleted successfully!',
          ),
          backgroundColor:
              _kSuccess,
        ),
      );

      await loadServices();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not delete service.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          _EmptyServicesIcon(),

          SizedBox(
            height: 16,
          ),

          Text(
            'No services added yet.',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w700,
              color: _kBlack,
            ),
          ),

          SizedBox(
            height: 6,
          ),

          Text(
            'Tap + Add Service to get started.',
            style: TextStyle(
              color: _kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    Map<String, dynamic> service,
  ) {
    final category =
        service['category']?.toString() ?? '';

    final description =
        service['description']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // ==================== SERVICE INFO ====================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kYellow,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.build_rounded,
                    color: _kBlack,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        service['name']
                                ?.toString() ??
                            '',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: -0.3,
                          color: _kBlack,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      if (category.isNotEmpty)
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _kBlack,
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: _kYellow,
                              fontWeight:
                                  FontWeight.w700,
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
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3C4),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Rs. ${service['price'] ?? 0}',
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
              const SizedBox(
                height: 14,
              ),

              // ==================== DESCRIPTION ====================

              Text(
                description,
                style: const TextStyle(
                  color: _kTextSecondary,
                  height: 1.45,
                  fontSize: 14,
                ),
              ),
            ],

            const SizedBox(
              height: 14,
            ),

            const Divider(
              height: 1,
              color: Color(0xFFEFEFEA),
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================== BUTTONS ====================

            Row(
              children: [

                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kBlack,
                      side: const BorderSide(
                        color: _kBlack,
                        width: 1.3,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed:
                        isSaving
                            ? null
                            : () {
                                editService(
                                  service,
                                );
                              },
                    icon:
                        const Icon(
                      Icons
                          .edit_outlined,
                      size: 18,
                    ),
                    label:
                        const Text(
                      'Edit',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kDanger,
                      side: const BorderSide(
                        color: _kDanger,
                        width: 1.3,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed:
                        isSaving
                            ? null
                            : () {
                                deleteService(
                                  service,
                                );
                              },
                    icon:
                        const Icon(
                      Icons
                          .delete_outline,
                      size: 18,
                    ),
                    label:
                        const Text(
                      'Delete',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            isSaving ? null : addService,
        backgroundColor: _kYellow,
        foregroundColor: _kBlack,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Service',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: isLoading

          ? const Center(
              child:
                  CircularProgressIndicator(
                color: _kBlack,
              ),
            )

          : services.isEmpty

              ? _buildEmptyState()

              : RefreshIndicator(
                  color: _kBlack,
                  backgroundColor: _kYellow,
                  onRefresh:
                      loadServices,

                  child:
                      ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      100,
                    ),

                    itemCount:
                        services.length,

                    itemBuilder:
                        (context, index) {

                      final service =
                          services[index];

                      return _buildServiceCard(
                        service,
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyServicesIcon extends StatelessWidget {
  const _EmptyServicesIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: _kYellow.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.build_circle_outlined,
        size: 44,
        color: _kBlack,
      ),
    );
  }
}