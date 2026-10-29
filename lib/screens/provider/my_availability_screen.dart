import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/session.dart';

const Color _yellow = Color(0xFFFFC400);
const Color _yellowSoft = Color(0xFFFFF3C4);
const Color _black = Color(0xFF0D0D0D);
const Color _background = Color(0xFFF6F6F2);
const Color _secondary = Color(0xFF6B6B6B);
const Color _border = Color(0xFFE4E4DE);
const Color _success = Color(0xFF1B7A3C);
const Color _danger = Color(0xFFD92D20);

// index == DateTime.weekday - 1
const List<String> _dayKeys = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];

const Map<String, String> _dayNames = {
  'MONDAY': 'Monday',
  'TUESDAY': 'Tuesday',
  'WEDNESDAY': 'Wednesday',
  'THURSDAY': 'Thursday',
  'FRIDAY': 'Friday',
  'SATURDAY': 'Saturday',
  'SUNDAY': 'Sunday',
};

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

// ============================================================
// HELPERS
// ============================================================

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dayKeyOf(DateTime d) => _dayKeys[d.weekday - 1];

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String _shortDate(DateTime d) =>
    '${d.day} ${_monthNames[d.month - 1].substring(0, 3)} ${d.year}';

String _longDate(DateTime d) =>
    '${_dayNames[_dayKeyOf(d)]}, ${d.day} ${_monthNames[d.month - 1]} ${d.year}';

bool _isAvail(Map<String, dynamic> slot) =>
    slot['available'] == true ||
    slot['available']?.toString().toLowerCase() == 'true';

bool _isSpecific(Map<String, dynamic> slot) =>
    slot['specificDate'] != null && slot['specificDate'].toString().isNotEmpty;

DateTime? _slotDate(Map<String, dynamic> slot) {
  if (!_isSpecific(slot)) return null;
  final text = slot['specificDate'].toString();
  final first10 = text.length >= 10 ? text.substring(0, 10) : text;
  final parsed = DateTime.tryParse(first10);
  return parsed == null ? null : _dateOnly(parsed);
}

String _slotDay(Map<String, dynamic> slot) =>
    slot['dayOfWeek']?.toString().toUpperCase() ?? '';

int _minutesOfString(dynamic value) {
  if (value == null) return 0;
  final t = value.toString();
  if (t.length < 5) return 0;
  final h = int.tryParse(t.substring(0, 2)) ?? 0;
  final m = int.tryParse(t.substring(3, 5)) ?? 0;
  return h * 60 + m;
}

int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

String _apiTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

TimeOfDay? _todFrom(dynamic value) {
  if (value == null) return null;
  final parts = value.toString().split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h, minute: m);
}

String _pretty(dynamic value) {
  final t = _todFrom(value);
  if (t == null) return '--:--';
  final suffix = t.hour >= 12 ? 'PM' : 'AM';
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h12:${t.minute.toString().padLeft(2, '0')} $suffix';
}

String _duration(TimeOfDay s, TimeOfDay e) {
  final diff = _minutesOf(e) - _minutesOf(s);
  if (diff <= 0) return '';
  final h = diff ~/ 60;
  final m = diff % 60;
  if (h > 0 && m > 0) return '${h}h ${m}m';
  if (h > 0) return '${h}h';
  return '${m}m';
}

Widget _pickerTheme(BuildContext context, Widget? child) {
  return Theme(
    data: Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: _black,
        onPrimary: _yellow,
        surface: Colors.white,
        onSurface: _black,
      ),
    ),
    child: child!,
  );
}

// ============================================================
// SCREEN
// ============================================================

enum _Marker { none, weekly, specific, specificOff }

class MyAvailabilityScreen extends StatefulWidget {
  const MyAvailabilityScreen({super.key});

  @override
  State<MyAvailabilityScreen> createState() => _MyAvailabilityScreenState();
}

class _MyAvailabilityScreenState extends State<MyAvailabilityScreen> {
  List<Map<String, dynamic>> slots = [];
  bool isLoading = true;
  bool isSaving = false;
  bool hasError = false;

  late final DateTime today;
  late DateTime selectedDate;
  late DateTime month;

  int tab = 0; // 0 = calendar, 1 = all hours

  @override
  void initState() {
    super.initState();
    today = _dateOnly(DateTime.now());
    selectedDate = today;
    month = DateTime(today.year, today.month);
    loadAvailability();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> loadAvailability({bool showSpinner = true}) async {
    if (Session.email.isEmpty) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
      });
      return;
    }

    if (showSpinner && mounted) setState(() => isLoading = true);

    try {
      final result =
          await ApiService.getProviderAvailability(email: Session.email);
      if (!mounted) return;

      final list = result
          .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map))
          .toList()
        ..sort((a, b) => _minutesOfString(a['startTime'])
            .compareTo(_minutesOfString(b['startTime'])));

      setState(() {
        slots = list;
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      debugPrint('Load availability error: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _message(String text, {bool isError = false}) {
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
          backgroundColor: isError ? _danger : _success,
        ),
      );
  }

  List<Map<String, dynamic>> _specificFor(DateTime date) => slots
      .where((s) =>
          _isSpecific(s) &&
          _slotDate(s) != null &&
          _sameDay(_slotDate(s)!, date))
      .toList();

  List<Map<String, dynamic>> _weeklyFor(DateTime date) {
    final key = _dayKeyOf(date);
    return slots.where((s) => !_isSpecific(s) && _slotDay(s) == key).toList();
  }

  _Marker _markerFor(DateTime date) {
    final specific = _specificFor(date);
    if (specific.isNotEmpty) {
      return specific.any(_isAvail) ? _Marker.specific : _Marker.specificOff;
    }
    final weekly = _weeklyFor(date);
    if (weekly.any(_isAvail)) return _Marker.weekly;
    return _Marker.none;
  }

  int get _weeklyDaysCount => _dayKeys
      .where((k) => slots
          .any((s) => !_isSpecific(s) && _slotDay(s) == k && _isAvail(s)))
      .length;

  int get _upcomingDatesCount => slots.where((s) {
        final d = _slotDate(s);
        return d != null && !d.isBefore(today);
      }).length;

  // ============================================================
  // ADD / EDIT
  // ============================================================

  Future<void> _openSheet({
    Map<String, dynamic>? editing,
    DateTime? initialDate,
    String initialMode = 'specific',
  }) async {
    if (Session.email.isEmpty) {
      _message('User session not found. Please login again.', isError: true);
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AvailabilitySheet(
        today: today,
        slots: slots,
        editingSlot: editing,
        initialDate: initialDate,
        initialMode: initialMode,
      ),
    );

    if (result == null || !mounted) return;
    await _save(result, editing: editing);
  }

  Future<void> _save(
    Map<String, dynamic> result, {
    Map<String, dynamic>? editing,
  }) async {
    final mode = result['mode'] as String;
    final start = result['start'] as TimeOfDay;
    final end = result['end'] as TimeOfDay;
    final dates = List<DateTime>.from(result['dates'] as List);
    final days = List<String>.from(result['days'] as List);

    setState(() => isSaving = true);

    int total = 0;
    int saved = 0;

    try {
      if (editing != null) {
        total = 1;
        final id = int.tryParse(editing['id']?.toString() ?? '');
        if (id != null) {
          final ok = mode == 'specific'
              ? await ApiService.editProviderAvailability(
                  id: id,
                  email: Session.email,
                  startTime: _apiTime(start),
                  endTime: _apiTime(end),
                  date: _dateKey(dates.first),
                )
              : await ApiService.editProviderAvailability(
                  id: id,
                  email: Session.email,
                  startTime: _apiTime(start),
                  endTime: _apiTime(end),
                  dayOfWeek: days.first,
                );
          if (ok) saved++;
        }
      } else if (mode == 'specific') {
        total = dates.length;
        for (final date in dates) {
          final ok = await ApiService.addDateProviderAvailability(
            email: Session.email,
            date: _dateKey(date),
            startTime: _apiTime(start),
            endTime: _apiTime(end),
          );
          if (ok) saved++;
        }
      } else {
        total = days.length;
        for (final day in days) {
          final ok = await ApiService.addProviderAvailability(
            email: Session.email,
            dayOfWeek: day,
            startTime: _apiTime(start),
            endTime: _apiTime(end),
          );
          if (ok) saved++;
        }
      }
    } catch (e) {
      debugPrint('Save availability error: $e');
    }

    if (!mounted) return;
    setState(() => isSaving = false);

    if (saved == total && total > 0) {
      _message(editing != null
          ? 'Changes saved.'
          : total == 1
              ? 'Availability saved.'
              : 'Availability saved for $total ${mode == 'specific' ? 'dates' : 'days'}.');
    } else if (saved > 0) {
      _message('Saved $saved of $total. Please retry the rest.', isError: true);
    } else {
      _message('Could not save availability. Check the backend.',
          isError: true);
    }

    if (saved > 0) {
      if (mode == 'specific' && dates.isNotEmpty) {
        setState(() {
          selectedDate = dates.first;
          month = DateTime(dates.first.year, dates.first.month);
          tab = 0;
        });
      }
      await loadAvailability(showSpinner: false);
    }
  }

  // ============================================================
  // TOGGLE / DELETE
  // ============================================================

  Future<void> _toggle(Map<String, dynamic> slot, bool value) async {
    final id = int.tryParse(slot['id']?.toString() ?? '');
    if (Session.email.isEmpty || id == null) {
      _message('Availability details are invalid.', isError: true);
      return;
    }

    final previous = slot['available'];
    setState(() {
      slot['available'] = value;
      isSaving = true;
    });

    bool ok = false;
    try {
      ok = await ApiService.updateProviderAvailability(
        id: id,
        email: Session.email,
        available: value,
      );
    } catch (e) {
      debugPrint('Toggle error: $e');
    }

    if (!mounted) return;
    setState(() {
      isSaving = false;
      if (!ok) slot['available'] = previous;
    });

    _message(
      ok
          ? (value ? 'Availability turned on.' : 'Availability turned off.')
          : 'Could not update availability.',
      isError: !ok,
    );
  }

  String _slotTitle(Map<String, dynamic> slot) {
    final d = _slotDate(slot);
    if (d != null) return _shortDate(d);
    return 'Every ${_dayNames[_slotDay(slot)] ?? _slotDay(slot)}';
  }

  Future<void> _delete(Map<String, dynamic> slot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _danger.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: _danger, size: 28),
        ),
        title: const Text(
          'Delete availability?',
          style: TextStyle(fontWeight: FontWeight.w800, color: _black),
        ),
        content: Text(
          '${_slotTitle(slot)}, ${_pretty(slot['startTime'])} – ${_pretty(slot['endTime'])} will be removed from your schedule.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _secondary, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _black,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final id = int.tryParse(slot['id']?.toString() ?? '');
    if (id == null || Session.email.isEmpty) {
      _message('Availability details are invalid.', isError: true);
      return;
    }

    setState(() => isSaving = true);
    bool ok = false;
    try {
      ok = await ApiService.deleteProviderAvailability(
        id: id,
        email: Session.email,
      );
    } catch (e) {
      debugPrint('Delete error: $e');
    }
    if (!mounted) return;
    setState(() => isSaving = false);

    if (ok) {
      _message('Availability deleted.');
      await loadAvailability(showSpinner: false);
    } else {
      _message('Could not delete availability.', isError: true);
    }
  }

  // ============================================================
  // UI: HEADER, TABS
  // ============================================================

  Widget _buildSummary() {
    final weekly = _weeklyDaysCount;
    final dates = _upcomingDatesCount;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _black,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _yellow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.event_available_rounded, color: _black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slots.isEmpty
                      ? 'No working hours yet'
                      : '$weekly weekly ${weekly == 1 ? 'day' : 'days'} • $dates upcoming ${dates == 1 ? 'date' : 'dates'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Specific dates take priority over your weekly hours.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    Widget item(String label, IconData icon, int index) {
      final active = tab == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => tab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: active ? _black : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: active ? _yellow : _secondary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : _secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          item('Calendar', Icons.calendar_month_rounded, 0),
          item('All hours', Icons.list_alt_rounded, 1),
        ],
      ),
    );
  }

  // ============================================================
  // UI: CALENDAR TAB
  // ============================================================

  Widget _buildCalendarTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MonthCalendar(
          month: month,
          today: today,
          onMonthChanged: (m) => setState(() => month = m),
          onDateTap: (d) => setState(() => selectedDate = d),
          isSelected: (d) => _sameDay(d, selectedDate),
          markerFor: _markerFor,
          allowPast: true,
          showLegend: true,
        ),
        const SizedBox(height: 22),
        _buildSelectedDay(),
      ],
    );
  }

  Widget _buildSelectedDay() {
    final specific = _specificFor(selectedDate);
    final weekly = _weeklyFor(selectedDate);
    final isPast = selectedDate.isBefore(today);
    final overridden = specific.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sameDay(selectedDate, today)
                        ? 'Today'
                        : _dayNames[_dayKeyOf(selectedDate)]!,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _longDate(selectedDate),
                    style: const TextStyle(color: _secondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (!isPast)
              TextButton.icon(
                onPressed: isSaving
                    ? null
                    : () => _openSheet(initialDate: selectedDate),
                style: TextButton.styleFrom(
                  foregroundColor: _black,
                  backgroundColor: _yellow.withValues(alpha: 0.28),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add hours'),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (specific.isEmpty && weekly.isEmpty)
          _emptyBox(
            icon: Icons.event_busy_outlined,
            title: 'No working hours on this day',
            subtitle: isPast
                ? 'This date has already passed.'
                : 'Tap “Add hours” to open this date for bookings.',
          )
        else ...[
          if (specific.isNotEmpty) ...[
            _sectionLabel('Specific date hours', Icons.event_outlined),
            for (final s in specific) _slotCard(s),
          ],
          if (weekly.isNotEmpty) ...[
            _sectionLabel(
              overridden ? 'Weekly hours (overridden)' : 'Weekly hours',
              Icons.repeat_rounded,
            ),
            for (final s in weekly)
              Opacity(opacity: overridden ? 0.5 : 1, child: _slotCard(s)),
          ],
        ],
      ],
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _secondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: _secondary,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: _secondary),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, color: _black)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _secondary, fontSize: 13)),
        ],
      ),
    );
  }

  // ============================================================
  // UI: ALL HOURS TAB
  // ============================================================

  Widget _buildListTab() {
    if (slots.isEmpty) {
      return _emptyBox(
        icon: Icons.calendar_month_outlined,
        title: 'No working hours added yet.',
        subtitle: 'Tap Add Availability to create your schedule.',
      );
    }

    final specific = slots.where(_isSpecific).toList()
      ..sort((a, b) {
        final da = _slotDate(a) ?? DateTime(9999);
        final db = _slotDate(b) ?? DateTime(9999);
        final c = da.compareTo(db);
        return c != 0
            ? c
            : _minutesOfString(a['startTime'])
                .compareTo(_minutesOfString(b['startTime']));
      });

    final upcoming = specific
        .where((s) => !(_slotDate(s) ?? today).isBefore(today))
        .toList();
    final past = specific
        .where((s) => (_slotDate(s) ?? today).isBefore(today))
        .toList();

    final weekly = slots.where((s) => !_isSpecific(s)).toList()
      ..sort((a, b) {
        final c = _dayKeys
            .indexOf(_slotDay(a))
            .compareTo(_dayKeys.indexOf(_slotDay(b)));
        return c != 0
            ? c
            : _minutesOfString(a['startTime'])
                .compareTo(_minutesOfString(b['startTime']));
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _listHeader('Upcoming dates', upcoming.length),
        if (upcoming.isEmpty)
          _emptyBox(
            icon: Icons.event_outlined,
            title: 'No upcoming specific dates',
            subtitle: 'Add one-off dates from the Add Availability button.',
          )
        else
          for (final s in upcoming) _slotCard(s),
        const SizedBox(height: 18),
        _listHeader('Weekly hours', weekly.length),
        if (weekly.isEmpty)
          _emptyBox(
            icon: Icons.repeat_rounded,
            title: 'No weekly hours',
            subtitle: 'Add hours that repeat every week.',
          )
        else
          for (final s in weekly) _slotCard(s),
        if (past.isNotEmpty) ...[
          const SizedBox(height: 18),
          _listHeader('Past dates', past.length),
          for (final s in past) Opacity(opacity: 0.55, child: _slotCard(s)),
        ],
      ],
    );
  }

  Widget _listHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _black,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _yellowSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 12.5, color: _black),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SLOT CARD
  // ============================================================

  Widget _slotCard(Map<String, dynamic> slot) {
    final available = _isAvail(slot);
    final specific = _isSpecific(slot);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: available ? _yellow : _border,
          width: available ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: available
                  ? _yellow.withValues(alpha: 0.25)
                  : _border.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              specific ? Icons.event_rounded : Icons.repeat_rounded,
              color: available ? _black : _secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _slotTitle(slot),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: available ? _black : _secondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_pretty(slot['startTime'])} – ${_pretty(slot['endTime'])}',
                  style: const TextStyle(color: _secondary, fontSize: 13.5),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: available ? _success : _danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        available ? 'Available for bookings' : 'Not available',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: available ? _success : _danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: available,
            thumbColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.selected) ? _yellow : Colors.white),
            trackColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.selected) ? _black : _border),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            onChanged: isSaving ? null : (v) => _toggle(slot, v),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            enabled: !isSaving,
            icon: const Icon(Icons.more_vert_rounded, color: _secondary),
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'edit') {
                _openSheet(
                  editing: slot,
                  initialMode: specific ? 'specific' : 'weekly',
                );
              } else {
                _delete(slot);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 20, color: _black),
                  SizedBox(width: 10),
                  Text('Edit'),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 20, color: _danger),
                  SizedBox(width: 10),
                  Text('Delete', style: TextStyle(color: _danger)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 52, color: _secondary),
          const SizedBox(height: 14),
          const Text(
            'Could not load your schedule',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: _black),
          ),
          const SizedBox(height: 6),
          Text(
            Session.email.isEmpty
                ? 'User session not found. Please login again.'
                : 'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _secondary),
          ),
          if (Session.email.isNotEmpty) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: loadAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: _black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Availability',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Go to today',
            onPressed: () => setState(() {
              selectedDate = today;
              month = DateTime(today.year, today.month);
              tab = 0;
            }),
            icon: const Icon(Icons.today_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : loadAvailability,
            icon: const Icon(Icons.refresh),
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        bottom: isSaving
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: _yellow,
                  backgroundColor: Colors.transparent,
                ),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            isSaving ? null : () => _openSheet(initialDate: selectedDate),
        backgroundColor: isSaving ? _border : _yellow,
        foregroundColor: _black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Availability',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _black))
          : RefreshIndicator(
              onRefresh: () => loadAvailability(showSpinner: false),
              color: _black,
              backgroundColor: _yellow,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                children: [
                  if (hasError && slots.isEmpty)
                    _buildErrorState()
                  else ...[
                    _buildSummary(),
                    const SizedBox(height: 16),
                    _buildTabs(),
                    const SizedBox(height: 16),
                    if (tab == 0) _buildCalendarTab() else _buildListTab(),
                  ],
                ],
              ),
            ),
    );
  }
}

// ============================================================
// REUSABLE MONTH CALENDAR
// ============================================================
class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime today;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateTap;
  final bool Function(DateTime) isSelected;
  final bool Function(DateTime)? isInRange;
  final _Marker Function(DateTime)? markerFor;
  final bool allowPast;
  final bool showLegend;

  const _MonthCalendar({
    required this.month,
    required this.today,
    required this.onMonthChanged,
    required this.onDateTap,
    required this.isSelected,
    this.isInRange,
    this.markerFor,
    this.allowPast = false,
    this.showLegend = false,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final leading = first.weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cellCount = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final canGoBack = month.isAfter(DateTime(today.year, today.month));

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: canGoBack
                    ? () =>
                        onMonthChanged(DateTime(month.year, month.month - 1))
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
                color: _black,
              ),
              Expanded(
                child: Text(
                  '${_monthNames[month.month - 1]} ${month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _black,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () =>
                    onMonthChanged(DateTime(month.year, month.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded),
                color: _black,
              ),
            ],
          ),
          Row(
            children: [
              for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: _secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final n = index - leading + 1;
              if (n < 1 || n > daysInMonth) return const SizedBox.shrink();
              return _cell(DateTime(month.year, month.month, n));
            },
          ),
          if (showLegend) ...[
            const SizedBox(height: 8),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 4,
              children: [
                _LegendDot(color: _success, label: 'Specific date'),
                _LegendDot(color: _yellow, label: 'Weekly'),
                _LegendDot(color: _danger, label: 'Switched off'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(DateTime date) {
    final selected = isSelected(date);
    final inRange = isInRange?.call(date) ?? false;
    final isToday = _sameDay(date, today);
    final disabled = !allowPast && date.isBefore(today);
    final marker = markerFor?.call(date) ?? _Marker.none;

    Color? dot;
    switch (marker) {
      case _Marker.specific:
        dot = _success;
        break;
      case _Marker.specificOff:
        dot = _danger;
        break;
      case _Marker.weekly:
        dot = _yellow;
        break;
      case _Marker.none:
        dot = null;
    }

    return Padding(
      padding: const EdgeInsets.all(2.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: disabled ? null : () => onDateTap(date),
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? _black
                : inRange
                    ? _yellow.withValues(alpha: 0.35)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isToday && !selected
                ? Border.all(color: _yellow, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight:
                      selected || isToday ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? _yellow
                      : disabled
                          ? _secondary.withValues(alpha: 0.4)
                          : _black,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dot ?? Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _secondary, fontSize: 12)),
      ],
    );
  }
}

// ============================================================
// ADD / EDIT SHEET
// Owns all of its own state, then returns a result map.
// ============================================================
class _AvailabilitySheet extends StatefulWidget {
  final DateTime today;
  final List<Map<String, dynamic>> slots;
  final Map<String, dynamic>? editingSlot;
  final DateTime? initialDate;
  final String initialMode;

  const _AvailabilitySheet({
    required this.today,
    required this.slots,
    this.editingSlot,
    this.initialDate,
    this.initialMode = 'specific',
  });

  @override
  State<_AvailabilitySheet> createState() => _AvailabilitySheetState();
}

class _AvailabilitySheetState extends State<_AvailabilitySheet> {
  late String mode; // 'specific' | 'weekly'
  String selMode = 'single'; // single | multiple | range

  DateTime? selectedDate;
  final Set<DateTime> multiDates = {};
  DateTime? rangeStart;
  DateTime? rangeEnd;
  late DateTime month;

  final Set<String> weeklyDays = {};

  TimeOfDay? start;
  TimeOfDay? end;
  String? errorText;

  bool get editing => widget.editingSlot != null;

  static const _presets = <String, List<TimeOfDay>>{
    'Morning': [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 12, minute: 0)],
    'Afternoon': [
      TimeOfDay(hour: 13, minute: 0),
      TimeOfDay(hour: 17, minute: 0)
    ],
    'Evening': [TimeOfDay(hour: 17, minute: 0), TimeOfDay(hour: 21, minute: 0)],
    'Full day': [TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 17, minute: 0)],
  };

  @override
  void initState() {
    super.initState();
    final slot = widget.editingSlot;
    final t = widget.today;
    month = DateTime(t.year, t.month);

    if (slot != null) {
      start = _todFrom(slot['startTime']);
      end = _todFrom(slot['endTime']);
      if (_isSpecific(slot)) {
        mode = 'specific';
        selectedDate = _slotDate(slot);
        if (selectedDate != null) {
          month = DateTime(selectedDate!.year, selectedDate!.month);
        }
      } else {
        mode = 'weekly';
        weeklyDays.add(_slotDay(slot));
      }
    } else {
      mode = widget.initialMode;
      final d = widget.initialDate;
      if (d != null && !d.isBefore(t)) {
        selectedDate = d;
        month = DateTime(d.year, d.month);
      }
      if (selectedDate != null) weeklyDays.add(_dayKeyOf(selectedDate!));
    }
  }

  // ---------- selection ----------

  void _tapDate(DateTime date) {
    final day = _dateOnly(date);
    setState(() {
      errorText = null;
      if (selMode == 'single') {
        selectedDate = day;
      } else if (selMode == 'multiple') {
        multiDates.contains(day) ? multiDates.remove(day) : multiDates.add(day);
      } else {
        if (rangeStart == null || rangeEnd != null) {
          rangeStart = day;
          rangeEnd = null;
        } else if (day.isBefore(rangeStart!)) {
          rangeEnd = rangeStart;
          rangeStart = day;
        } else {
          rangeEnd = day;
        }
      }
    });
  }

  bool _isSel(DateTime date) {
    final day = _dateOnly(date);
    if (selMode == 'single') {
      return selectedDate != null && _sameDay(day, selectedDate!);
    }
    if (selMode == 'multiple') return multiDates.contains(day);
    if (rangeStart == null) return false;
    return _sameDay(day, rangeStart!) ||
        (rangeEnd != null && _sameDay(day, rangeEnd!));
  }

  bool _inRange(DateTime date) {
    if (selMode != 'range' || rangeStart == null || rangeEnd == null) {
      return false;
    }
    final day = _dateOnly(date);
    return day.isAfter(rangeStart!) && day.isBefore(rangeEnd!);
  }

  List<DateTime> _chosenDates() {
    if (selMode == 'single') {
      return selectedDate == null ? [] : [selectedDate!];
    }
    if (selMode == 'multiple') return multiDates.toList()..sort();
    if (rangeStart == null) return [];
    final last = rangeEnd ?? rangeStart!;
    final out = <DateTime>[];
    var cur = _dateOnly(rangeStart!);
    while (!cur.isAfter(last)) {
      out.add(cur);
      cur = DateTime(cur.year, cur.month, cur.day + 1);
    }
    return out;
  }

  _Marker _existingMarker(DateTime date) {
    final has = widget.slots.any((s) {
      final d = _slotDate(s);
      return d != null && _sameDay(d, date);
    });
    return has ? _Marker.specific : _Marker.none;
  }

  String _selectionSummary() {
    final dates = _chosenDates();
    if (selMode == 'range' && rangeStart != null && rangeEnd == null) {
      return 'Start: ${_shortDate(rangeStart!)}. Now choose an end date.';
    }
    if (dates.isEmpty) return 'Tap a date on the calendar.';
    if (dates.length == 1) return _longDate(dates.first);
    return '${dates.length} dates selected '
        '(${_shortDate(dates.first)} → ${_shortDate(dates.last)})';
  }

  // ---------- time ----------

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? start : end) ?? const TimeOfDay(hour: 9, minute: 0),
      builder: _pickerTheme,
    );
    if (picked == null) return;
    setState(() {
      errorText = null;
      if (isStart) {
        start = picked;
      } else {
        end = picked;
      }
    });
  }

  // ---------- validate & submit ----------

  String? _overlapError(int s, int e, List<DateTime> dates) {
    final editingId = widget.editingSlot?['id']?.toString();
    for (final slot in widget.slots) {
      if (editingId != null && slot['id']?.toString() == editingId) continue;
      final sStart = _minutesOfString(slot['startTime']);
      final sEnd = _minutesOfString(slot['endTime']);
      if (!(s < sEnd && e > sStart)) continue;

      if (mode == 'specific' && _isSpecific(slot)) {
        final d = _slotDate(slot);
        if (d != null && dates.any((x) => _sameDay(x, d))) {
          return 'These hours overlap existing hours on ${_shortDate(d)}.';
        }
      } else if (mode == 'weekly' &&
          !_isSpecific(slot) &&
          weeklyDays.contains(_slotDay(slot))) {
        return 'These hours overlap existing hours on '
            '${_dayNames[_slotDay(slot)]}.';
      }
    }
    return null;
  }

  void _submit() {
    final dates = mode == 'specific' ? _chosenDates() : <DateTime>[];

    if (mode == 'specific') {
      if (dates.isEmpty) {
        setState(() => errorText = 'Please select at least one date.');
        return;
      }
      if (selMode == 'range' && rangeEnd == null) {
        setState(() => errorText = 'Please choose the end of the date range.');
        return;
      }
    } else if (weeklyDays.isEmpty) {
      setState(() => errorText = 'Please select at least one weekday.');
      return;
    }

    if (start == null || end == null) {
      setState(() => errorText = 'Please select both start and end times.');
      return;
    }
    final s = _minutesOf(start!);
    final e = _minutesOf(end!);
    if (e <= s) {
      setState(() => errorText = 'End time must be after the start time.');
      return;
    }

    final clash = _overlapError(s, e, dates);
    if (clash != null) {
      setState(() => errorText = clash);
      return;
    }

    Navigator.of(context).pop({
      'mode': mode,
      'dates': dates,
      'days': _dayKeys.where(weeklyDays.contains).toList(),
      'start': start,
      'end': end,
    });
  }

  String get _submitLabel {
    if (editing) return 'Save changes';
    if (mode == 'specific') {
      final n = _chosenDates().length;
      return n > 1 ? 'Save $n dates' : 'Save date';
    }
    final n = weeklyDays.length;
    return n > 1 ? 'Save $n days' : 'Save weekly hours';
  }

  // ---------- widgets ----------

  Widget _modeToggle() {
    Widget item(String label, IconData icon, String value) {
      final active = mode == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            mode = value;
            errorText = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: active ? _black : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: active ? _yellow : _secondary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : _secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          item('Specific dates', Icons.event_rounded, 'specific'),
          item('Weekly', Icons.repeat_rounded, 'weekly'),
        ],
      ),
    );
  }

  Widget _selModeChips() {
    Widget chip(String label, String value) {
      final selected = selMode == value;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: _yellow,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? _yellow : _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(
          color: _black,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 13,
        ),
        onSelected: (_) => setState(() {
          selMode = value;
          errorText = null;
          // keep a sensible carry-over
          final keep = selectedDate;
          multiDates.clear();
          rangeStart = null;
          rangeEnd = null;
          if (value == 'multiple' && keep != null) multiDates.add(keep);
          if (value == 'range' && keep != null) rangeStart = keep;
          if (value == 'single') selectedDate = keep;
        }),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Single date', 'single'),
        chip('Multiple dates', 'multiple'),
        chip('Date range', 'range'),
      ],
    );
  }

  Widget _specificSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!editing) ...[
          _selModeChips(),
          const SizedBox(height: 14),
        ],
        _MonthCalendar(
          month: month,
          today: widget.today,
          onMonthChanged: (m) => setState(() => month = m),
          onDateTap: _tapDate,
          isSelected: _isSel,
          isInRange: _inRange,
          markerFor: _existingMarker,
          allowPast: false,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _yellowSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_available_rounded,
                  size: 20, color: _black),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectionSummary(),
                  style: const TextStyle(
                    color: _black,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 4, top: 10),
          child: Text(
            'Green dots show dates that already have hours.',
            style: TextStyle(color: _secondary, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _weeklySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          editing ? 'Repeats every' : 'Repeat every',
          style: const TextStyle(fontWeight: FontWeight.w800, color: _black),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final key in _dayKeys)
              FilterChip(
                label: Text(_dayNames[key]!.substring(0, 3)),
                selected: weeklyDays.contains(key),
                showCheckmark: false,
                backgroundColor: Colors.white,
                selectedColor: _black,
                side: BorderSide(
                    color: weeklyDays.contains(key) ? _black : _border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                labelStyle: TextStyle(
                  color: weeklyDays.contains(key) ? _yellow : _black,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (v) => setState(() {
                  errorText = null;
                  if (editing) {
                    weeklyDays
                      ..clear()
                      ..add(key);
                  } else if (v) {
                    weeklyDays.add(key);
                  } else {
                    weeklyDays.remove(key);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          editing
              ? 'Choose the weekday these hours repeat on.'
              : 'Pick one or more weekdays. The same hours repeat every week.',
          style: const TextStyle(color: _secondary, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _timeButton(String label, TimeOfDay? value, bool isStart) {
    final filled = value != null;
    return InkWell(
      onTap: () => _pickTime(isStart),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: filled ? _yellow : _border, width: filled ? 1.8 : 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: _black, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          const TextStyle(color: _secondary, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(
                    filled ? value.format(context) : 'Select',
                    style: TextStyle(
                      color: filled ? _black : _secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeSection() {
    final dur = (start != null && end != null) ? _duration(start!, end!) : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Working hours',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, color: _black)),
            ),
            if (dur.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _yellowSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(dur,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12.5)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in _presets.entries)
              ActionChip(
                label: Text(entry.key),
                backgroundColor: _yellowSoft,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                labelStyle: const TextStyle(
                    color: _black, fontWeight: FontWeight.w700),
                onPressed: () => setState(() {
                  start = entry.value[0];
                  end = entry.value[1];
                  errorText = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _timeButton('Start time', start, true)),
            const SizedBox(width: 12),
            Expanded(child: _timeButton('End time', end, false)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = editing
        ? (mode == 'specific' ? 'Edit date hours' : 'Edit weekly hours')
        : 'Add availability';

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: _border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _yellow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _black,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: _secondary),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!editing) ...[
                    _modeToggle(),
                    const SizedBox(height: 16),
                  ],
                  if (mode == 'specific')
                    _specificSection()
                  else
                    _weeklySection(),
                  const SizedBox(height: 22),
                  _timeSection(),
                  if (errorText != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              color: _danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorText!,
                              style: const TextStyle(
                                color: _danger,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Sticky action bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: _background,
              border: Border(top: BorderSide(color: _border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _black,
                        side: const BorderSide(color: _border, width: 1.3),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
                        backgroundColor: _yellow,
                        foregroundColor: _black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle:
                            const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      child: Text(_submitLabel),
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