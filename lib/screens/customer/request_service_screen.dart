import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);
const Color _kDanger = Color(0xFFD92D20);
const Color _kSuccess = Color(0xFF1B7A3C);

//==================== Request Service Screen ====================
class RequestServiceScreen extends StatefulWidget {
  final String providerName;
  final String serviceName;
  final String customerEmail;
  final String providerEmail;

  const RequestServiceScreen({
    super.key,
    required this.providerName,
    required this.serviceName,
    required this.customerEmail,
    required this.providerEmail,
  });

  @override
  State<RequestServiceScreen> createState() =>
      _RequestServiceScreenState();
}

class _RequestServiceScreenState
    extends State<RequestServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController addressController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // Yellow & black theme for the date / time pickers
  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: _kYellow,
          onPrimary: _kBlack,
          surface: Colors.white,
          onSurface: _kBlack,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _kBlack,
          ),
        ),
      ),
      child: child!,
    );
  }

  Future<void> selectDate() async {
    final DateTime? pickedDate =
        await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: _pickerTheme,
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> selectTime() async {
    final TimeOfDay? pickedTime =
        await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: _pickerTheme,
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  Future<void> submitRequest() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  if (selectedDate == null ||
      selectedTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please select date and time.',
        ),
      ),
    );
    return;
  }

  final requestedDate =
      '${selectedDate!.year}-'
      '${selectedDate!.month.toString().padLeft(2, '0')}-'
      '${selectedDate!.day.toString().padLeft(2, '0')}';

  final requestedTime =
      '${selectedTime!.hour.toString().padLeft(2, '0')}:'
      '${selectedTime!.minute.toString().padLeft(2, '0')}';

  final services =
      await ApiService.getProviderServices(
    email: widget.providerEmail,
  );

  if (services == null || services.isEmpty) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No services found for this provider.',
        ),
      ),
    );

    return;
  }

  final matchingServices = services.where((service) {
    return service['category']?.toString() ==
        widget.serviceName;
  }).toList();

  if (matchingServices.isEmpty) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Selected service is not available.',
        ),
      ),
    );

    return;
  }

  final serviceId =
      int.tryParse(
        matchingServices.first['id'].toString(),
      );

  if (serviceId == null) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Invalid service.',
        ),
      ),
    );

    return;
  }

  final result =
      await ApiService.createServiceRequest(
    customerEmail: widget.customerEmail,
    providerEmail: widget.providerEmail,
    serviceId: serviceId,
    requestedDate: requestedDate,
    requestedTime: requestedTime,
    address: addressController.text.trim(),
    description:
        descriptionController.text.trim(),
  );

  if (!mounted) return;

  if (result != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Service request submitted successfully!',
        ),
        backgroundColor: _kSuccess,
      ),
    );

    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Failed to submit service request.',
        ),
      ),
    );
  }
}

  // ==================== UI HELPERS ====================

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _kTextSecondary,
        fontSize: 14.5,
      ),
      prefixIcon: Icon(icon, color: _kBlack, size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 17,
        horizontal: 16,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kDanger, width: 2),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _kBlack,
      ),
    );
  }

  Widget _pickerButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String text,
    required bool hasValue,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _kBlack,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: BorderSide(
            color: hasValue ? _kYellow : _kBorder,
            width: hasValue ? 1.8 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: _kBlack),
        label: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
            color: hasValue ? _kBlack : _kTextSecondary,
          ),
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
          'Request Service',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ),

      body: SingleChildScrollView(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // ==================== SERVICE DETAILS ====================

              Row(
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
                    'Service Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: _kBlack,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ==================== PROVIDER ====================

              _InfoTile(
                icon: Icons.person_rounded,
                title: 'Provider',
                subtitle: widget.providerName,
              ),

              // ==================== SERVICE ====================

              _InfoTile(
                icon: Icons.build_rounded,
                title: 'Service',
                subtitle: widget.serviceName,
              ),

              const SizedBox(height: 12),

              // ==================== DATE & TIME ====================

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _label('Select Date'),
                        const SizedBox(height: 8),
                        _pickerButton(
                          onPressed: selectDate,
                          icon: Icons.calendar_today_rounded,
                          hasValue: selectedDate != null,
                          text: selectedDate == null
                              ? 'Choose Date'
                              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _label('Select Time'),
                        const SizedBox(height: 8),
                        _pickerButton(
                          onPressed: selectTime,
                          icon: Icons.access_time_rounded,
                          hasValue: selectedTime != null,
                          text: selectedTime == null
                              ? 'Choose Time'
                              : selectedTime!.format(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==================== ADDRESS ====================

              _label('Service Address'),

              const SizedBox(height: 8),

              TextFormField(
                controller: addressController,
                maxLines: 2,
                cursorColor: _kBlack,
                style: const TextStyle(
                  fontSize: 15,
                  color: _kBlack,
                ),

                decoration: _fieldDecoration(
                  hint: 'Enter your service address',
                  icon: Icons.location_on_outlined,
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter your address';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ==================== PROBLEM ====================

              _label('Describe Your Problem'),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                    descriptionController,

                maxLines: 4,
                cursorColor: _kBlack,
                style: const TextStyle(
                  fontSize: 15,
                  color: _kBlack,
                ),

                decoration: _fieldDecoration(
                  hint: 'Describe what service you need...',
                  icon: Icons.description_outlined,
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please describe your problem';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              // ==================== SUBMIT ====================

              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton.icon(
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
                  onPressed: submitRequest,

                  icon: const Icon(
                    Icons.send_rounded,
                    size: 18,
                  ),

                  label: const Text(
                    'Submit Request',
                    style: TextStyle(
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}

// ==================== Info Tile ====================

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _kYellow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 23, color: _kBlack),
          ),
          const SizedBox(width: 14),
          Expanded(
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}