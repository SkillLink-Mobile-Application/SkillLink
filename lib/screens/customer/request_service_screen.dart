import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);
const Color _kDanger = Color(0xFFD92D20);
const Color _kSuccess = Color(0xFF1B7A3C);

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
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();

  List<Map<String, dynamic>> availabilitySlots = [];

  bool isLoadingAvailability = true;
  bool isSubmitting = false;
  String? availabilityError;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      isLoadingAvailability = true;
      availabilityError = null;
    });

    try {
      final response = await ApiService.getProviderAvailability(
        email: widget.providerEmail,
      );

      if (!mounted) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final validSlots = <Map<String, dynamic>>[];

      for (final item in response) {
        if (item is! Map) continue;

        final slot = Map<String, dynamic>.from(item);

        final availableValue = slot['available'];
        final available = availableValue == true ||
            availableValue.toString().toLowerCase() == 'true';

        final start = _parseTime(slot['startTime']);
        final end = _parseTime(slot['endTime']);

        if (!available || start == null || end == null) continue;
        if (_minutes(start) >= _minutes(end)) continue;

        final specificDate = _parseDate(slot['specificDate']);
        final weekday = _weekdayFromValue(slot['dayOfWeek']);

        // Accept either a valid specific date or a weekly weekday.
        if (specificDate != null) {
          if (specificDate.isBefore(today)) continue;
        } else if (weekday == null) {
          continue;
        }

        validSlots.add(slot);
      }

      setState(() {
        availabilitySlots = validSlots;
        isLoadingAvailability = false;

        if (validSlots.isEmpty) {
          availabilityError =
              'This provider has not added any future available days and times yet.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingAvailability = false;
        availabilityError = 'Could not load availability. Please try again.';
      });
    }
  }

  int? _weekdayFromValue(dynamic value) {
    if (value == null) return null;

    const days = {
      'MONDAY': DateTime.monday,
      'TUESDAY': DateTime.tuesday,
      'WEDNESDAY': DateTime.wednesday,
      'THURSDAY': DateTime.thursday,
      'FRIDAY': DateTime.friday,
      'SATURDAY': DateTime.saturday,
      'SUNDAY': DateTime.sunday,
    };

    return days[value.toString().toUpperCase()];
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;

    try {
      final parsed = DateTime.parse(value.toString());
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  TimeOfDay? _parseTime(dynamic value) {
    if (value == null) return null;

    final parts = value.toString().split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _formatDate(DateTime date) =>
      '${_weekdayName(date.weekday)}, ${date.day}/${date.month}/${date.year}';

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> get _availableDates {
    if (availabilitySlots.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates = <String, DateTime>{};

    // Add future dates matching weekly availability.
    final weekdays = availabilitySlots
        .where((slot) => _parseDate(slot['specificDate']) == null)
        .map((slot) => _weekdayFromValue(slot['dayOfWeek']))
        .whereType<int>()
        .toSet();

    for (int i = 0; i < 90; i++) {
      final date = today.add(Duration(days: i));

      if (weekdays.contains(date.weekday)) {
        dates[_dateKey(date)] = date;
      }
    }

    // Add exact dates entered by the provider.
    for (final slot in availabilitySlots) {
      final date = _parseDate(slot['specificDate']);

      if (date != null && !date.isBefore(today)) {
        dates[_dateKey(date)] = date;
      }
    }

    final result = dates.values.toList()
      ..sort((a, b) => a.compareTo(b));

    return result;
  }

  List<Map<String, dynamic>> _slotsForDate(DateTime date) {
    final result = <Map<String, dynamic>>[];

    for (final slot in availabilitySlots) {
      final specificDate = _parseDate(slot['specificDate']);

      if (specificDate != null) {
        // Specific-date availability applies only to that exact date.
        if (_sameDate(specificDate, date)) {
          result.add(slot);
        }
      } else {
        // Weekly availability applies to matching weekdays.
        if (_weekdayFromValue(slot['dayOfWeek']) == date.weekday) {
          result.add(slot);
        }
      }
    }

    return result;
  }

  List<TimeOfDay> _timesForDate(DateTime date) {
    final result = <TimeOfDay>[];
    final seenMinutes = <int>{};

    for (final slot in _slotsForDate(date)) {
      final start = _parseTime(slot['startTime']);
      final end = _parseTime(slot['endTime']);

      if (start == null || end == null) continue;

      final startMinutes = _minutes(start);
      final endMinutes = _minutes(end);

      for (int minute = startMinutes;
          minute < endMinutes;
          minute += 30) {
        if (seenMinutes.add(minute)) {
          result.add(
            TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
          );
        }
      }
    }

    result.sort((a, b) => _minutes(a).compareTo(_minutes(b)));
    return result;
  }

  Future<void> _selectDate() async {
    final dates = _availableDates;
    if (dates.isEmpty) return;

    final pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.65,
          ),
          decoration: const BoxDecoration(
            color: _kBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Choose an available date',
                  style: TextStyle(
                    color: _kBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: dates.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: _kBorder),
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final isSelected = selectedDate != null &&
                        _sameDate(selectedDate!, date);

                    return ListTile(
                      leading: const Icon(
                        Icons.calendar_month_rounded,
                        color: _kBlack,
                      ),
                      title: Text(
                        _formatDate(date),
                        style: TextStyle(
                          color: _kBlack,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: _kSuccess)
                          : const Icon(
                              Icons.chevron_right,
                              color: _kTextSecondary,
                            ),
                      onTap: () => Navigator.pop(context, date),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (pickedDate != null && mounted) {
      setState(() {
        selectedDate = pickedDate;
        selectedTime = null;
      });
    }
  }

  Future<void> _selectTime() async {
    if (selectedDate == null) {
      _showMessage('Please select an available date first.');
      return;
    }

    final times = _timesForDate(selectedDate!);

    if (times.isEmpty) {
      _showMessage('No time slots are available for this date.');
      return;
    }

    final pickedTime = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
          ),
          decoration: const BoxDecoration(
            color: _kBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Available times • ${_formatDate(selectedDate!)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _kBlack,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: times.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: _kBorder),
                  itemBuilder: (context, index) {
                    final time = times[index];
                    final isSelected = selectedTime != null &&
                        _minutes(selectedTime!) == _minutes(time);

                    return ListTile(
                      leading: const Icon(
                        Icons.access_time_rounded,
                        color: _kBlack,
                      ),
                      title: Text(
                        _formatTime(time),
                        style: TextStyle(
                          color: _kBlack,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: _kSuccess)
                          : null,
                      onTap: () => Navigator.pop(context, time),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (pickedTime != null && mounted) {
      setState(() => selectedTime = pickedTime);
    }
  }

  void _showMessage(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> submitRequest() async {
    if (isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (isLoadingAvailability) {
      _showMessage('Please wait while availability loads.');
      return;
    }

    if (selectedDate == null || selectedTime == null) {
      _showMessage('Please select an available date and time.');
      return;
    }

    final selectedMinutes = _minutes(selectedTime!);

    final isTimeAvailable = _slotsForDate(selectedDate!).any((slot) {
      final start = _parseTime(slot['startTime']);
      final end = _parseTime(slot['endTime']);

      if (start == null || end == null) return false;

      return selectedMinutes >= _minutes(start) &&
          selectedMinutes < _minutes(end);
    });

    if (!isTimeAvailable) {
      _showMessage(
        'Selected time is outside the provider availability.',
        color: _kDanger,
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final services = await ApiService.getProviderServices(
        email: widget.providerEmail,
      );

      if (!mounted) return;

      if (services == null || services.isEmpty) {
        _showMessage('No services found for this provider.', color: _kDanger);
        return;
      }

      final matchingServices = services.where((service) {
        return service['category']?.toString() == widget.serviceName;
      }).toList();

      if (matchingServices.isEmpty) {
        _showMessage('Selected service is not available.', color: _kDanger);
        return;
      }

      final serviceId = int.tryParse(
        matchingServices.first['id'].toString(),
      );

      if (serviceId == null) {
        _showMessage('Invalid service.', color: _kDanger);
        return;
      }

      final result = await ApiService.createServiceRequest(
        customerEmail: widget.customerEmail,
        providerEmail: widget.providerEmail,
        serviceId: serviceId,
        requestedDate: _dateKey(selectedDate!),
        requestedTime:
            '${selectedTime!.hour.toString().padLeft(2, '0')}:'
            '${selectedTime!.minute.toString().padLeft(2, '0')}',
        address: addressController.text.trim(),
        description: descriptionController.text.trim(),
      );

      if (!mounted) return;

      if (result != null) {
        _showMessage(
          'Service request submitted successfully!',
          color: _kSuccess,
        );
        Navigator.pop(context);
      } else {
        _showMessage(
          'Failed to submit request. Check availability and try again.',
          color: _kDanger,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Something went wrong. Please try again.',
          color: _kDanger,
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration({
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
    bool enabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
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
        onPressed: enabled ? onPressed : null,
        child: Row(
          children: [
            Icon(icon, size: 18, color: _kBlack),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                  color: hasValue ? _kBlack : _kTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableDates = _availableDates;

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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              _InfoTile(
                icon: Icons.person_rounded,
                title: 'Provider',
                subtitle: widget.providerName,
              ),
              _InfoTile(
                icon: Icons.build_rounded,
                title: 'Service',
                subtitle: widget.serviceName,
              ),
              const SizedBox(height: 12),
              _label('Select Available Date'),
              const SizedBox(height: 8),
              _pickerButton(
                onPressed: _selectDate,
                icon: Icons.calendar_today_rounded,
                hasValue: selectedDate != null,
                text: isLoadingAvailability
                    ? 'Loading availability...'
                    : selectedDate == null
                        ? 'Choose available date'
                        : _formatDate(selectedDate!),
                enabled: !isLoadingAvailability && availableDates.isNotEmpty,
              ),
              if (isLoadingAvailability) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(
                  color: _kYellow,
                  backgroundColor: _kBorder,
                ),
              ],
              if (!isLoadingAvailability && availabilityError != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: _kDanger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          availabilityError!,
                          style: const TextStyle(
                            color: _kTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadAvailability,
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: _kBlack),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _label('Select Available Time'),
              const SizedBox(height: 8),
              _pickerButton(
                onPressed: _selectTime,
                icon: Icons.access_time_rounded,
                hasValue: selectedTime != null,
                text: selectedTime == null
                    ? 'Choose available time'
                    : _formatTime(selectedTime!),
                enabled: !isLoadingAvailability &&
                    selectedDate != null &&
                    _timesForDate(selectedDate!).isNotEmpty,
              ),
              const SizedBox(height: 20),
              _label('Service Address'),
              const SizedBox(height: 8),
              TextFormField(
                controller: addressController,
                maxLines: 2,
                cursorColor: _kBlack,
                style: const TextStyle(fontSize: 15, color: _kBlack),
                decoration: _inputDecoration(
                  hint: 'Enter your service address',
                  icon: Icons.location_on_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _label('Describe Your Problem'),
              const SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                cursorColor: _kBlack,
                style: const TextStyle(fontSize: 15, color: _kBlack),
                decoration: _inputDecoration(
                  hint: 'Describe what service you need...',
                  icon: Icons.description_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your problem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kYellow,
                    foregroundColor: _kBlack,
                    disabledBackgroundColor: _kBorder,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onPressed: isSubmitting || isLoadingAvailability
                      ? null
                      : submitRequest,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _kBlack,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    isSubmitting ? 'Submitting...' : 'Submit Request',
                    style: const TextStyle(fontSize: 17),
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