import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';
import '../customer/chat_screen.dart';

// ============================================================
// DESIGN TOKENS
// ============================================================

const Color _kYellow = Color(0xFFFFC400);
const Color _kYellowSoft = Color(0xFFFFF6D8);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kSurfaceMuted = Color(0xFFF3F3EE);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);
const Color _kDanger = Color(0xFFD92D20);
const Color _kSuccess = Color(0xFF1B7A3C);

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> _kWeekdays = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

// Statuses where the provider has to do something next.
const Set<String> _kNeedsAction = {
  'PENDING',
  'NEGOTIATING',
  'CUSTOMER_TIME_PROPOSED',
};

enum _RequestFilter { all, needsAction, approved, waiting, rejected }

class _StatusStyle {
  final Color background;
  final Color foreground;
  final IconData icon;

  const _StatusStyle(this.background, this.foreground, this.icon);
}

_StatusStyle _styleFor(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return const _StatusStyle(
        Color(0xFFFFF1BF), Color(0xFF7A5A00), Icons.hourglass_top_rounded);
    case 'ACCEPTED':
    case 'CONFIRMED':
      return const _StatusStyle(_kBlack, _kYellow, Icons.check_rounded);
    case 'TIME_PROPOSED':
    case 'RESCHEDULE_PROPOSED':
      return const _StatusStyle(
        _kYellowSoft, Color(0xFF7A5A00), Icons.schedule_send_rounded);
    case 'CUSTOMER_TIME_PROPOSED':
    case 'NEGOTIATING':
      return const _StatusStyle(
        _kYellowSoft, Color(0xFF7A5A00), Icons.event_repeat_rounded);
    case 'IN_PROGRESS':
      return const _StatusStyle(
        Color(0xFFE3EEFF), Color(0xFF2457A6), Icons.handyman_rounded);
    case 'COMPLETED':
      return const _StatusStyle(
        Color(0xFFDFF5E6), _kSuccess, Icons.verified_rounded);
    case 'REJECTED':
    case 'DECLINED':
    case 'CANCELLED':
    case 'CANCELED':
      return const _StatusStyle(
        Color(0xFFFDE3E3), Color(0xFFB3261E), Icons.block_rounded);
    default:
      return const _StatusStyle(
        Color(0xFFEDEDE8), _kTextSecondary, Icons.info_outline_rounded);
  }
}

// ============================================================
// SCREEN
// ============================================================

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});

  @override
  State<ProviderRequestsScreen> createState() =>
      _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen> {
  List<dynamic> requests = [];

  bool isLoading = true;
  bool hasError = false;

  _RequestFilter selectedFilter = _RequestFilter.all;
  bool showHistory = false;

  final Set<int> processingRequests = {};

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  // ----------------------------------------------------------
  // DATA
  // ----------------------------------------------------------

  Future<void> loadRequests() async {
    final email = Session.email;

    if (email.isEmpty) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final result = await ApiService.getProviderRequests(email: email);

      if (!mounted) return;

      setState(() {
        requests = result;
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        hasError = true;
      });

      // Only interrupt with a toast when we already have data on screen.
      if (requests.isNotEmpty) {
        showMessage('Could not refresh. Showing your last loaded requests.');
      }
    }
  }

  void setProcessing(int requestId, bool value) {
    if (!mounted) return;

    setState(() {
      if (value) {
        processingRequests.add(requestId);
      } else {
        processingRequests.remove(requestId);
      }
    });
  }

  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: success ? _kSuccess : _kDanger,
          content: Row(
            children: [
              Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  // ----------------------------------------------------------
  // ACTIONS
  // ----------------------------------------------------------

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    Color confirmColor = _kBlack,
    Color confirmForeground = _kYellow,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          message,
          style: const TextStyle(color: _kTextSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Not now',
              style: TextStyle(color: _kTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: confirmForeground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> updateStatus(
    int requestId,
    String status, {
    String? reason,
  }) async {
    if (processingRequests.contains(requestId)) return;

    setProcessing(requestId, true);

    try {
      final success = await ApiService.updateServiceRequestStatus(
        requestId: requestId,
        email: Session.email,
        status: status,
        reason: reason,
      );

      if (!mounted) return;

      if (success) {
        const messages = {
          'ACCEPTED': 'Request accepted.',
          'REJECTED': 'Request rejected.',
          'IN_PROGRESS': 'Service started.',
          'COMPLETED': 'Service completed. Find it under History.',
        };

        showMessage(messages[status] ?? 'Request updated.', success: true);
        await loadRequests();
      } else {
        showMessage('Could not update the request. Please try again.');
      }
    } catch (e) {
      showMessage('Something went wrong. Check your connection and retry.');
    } finally {
      setProcessing(requestId, false);
    }
  }

  Future<void> completeService(int requestId) async {
    final ok = await _confirm(
      title: 'Mark as completed?',
      message: 'The customer will be notified that the service is finished.',
      confirmLabel: 'Complete',
    );

    if (ok) await updateStatus(requestId, 'COMPLETED');
  }

  Future<void> respondToCustomerProposedTime(
    int requestId, {
    required bool accept,
  }) async {
    if (processingRequests.contains(requestId)) return;

    setProcessing(requestId, true);

    try {
      final success = accept
          ? await ApiService.acceptCustomerProposedTime(
              requestId: requestId,
              email: Session.email,
            )
          : await ApiService.declineCustomerProposedTime(
              requestId: requestId,
              email: Session.email,
            );

      if (!mounted) return;

      if (success) {
        showMessage(
          accept
              ? 'Appointment time accepted.'
              : 'Proposed time declined.',
          success: true,
        );
        await loadRequests();
      } else {
        showMessage(
          accept
              ? 'Could not accept this time. Check your availability.'
              : 'Could not decline the proposed time.',
        );
      }
    } catch (e) {
      showMessage('Something went wrong. Check your connection and retry.');
    } finally {
      setProcessing(requestId, false);
    }
  }

  Future<void> showRejectDialog(int requestId) async {
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RejectReasonDialog(),
    );

    if (!mounted || reason == null || reason.trim().isEmpty) return;

    await updateStatus(requestId, 'REJECTED', reason: reason.trim());
  }

  Future<void> showProposeTimeDialog(
    int requestId, {
    required bool isReschedule,
  }) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      helpText: 'Choose appointment date',
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: _pickerTheme,
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      helpText: 'Choose appointment time',
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: _pickerTheme,
    );

    if (time == null || !mounted) return;

    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (!picked.isAfter(DateTime.now())) {
      showMessage('Pick a time in the future.');
      return;
    }

    final proposedDate =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final proposedTime =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';

    final ok = await _confirm(
      title: isReschedule ? 'Send new time?' : 'Send this time?',
      message: '${formatDate(proposedDate)} at ${formatTime(proposedTime)}'
          '\n\nThe customer will be asked to confirm.',
      confirmLabel: 'Send to customer',
    );

    if (!ok || !mounted) return;
    if (processingRequests.contains(requestId)) return;

    setProcessing(requestId, true);

    try {
      final success = await ApiService.proposeServiceRequestTime(
        requestId: requestId,
        email: Session.email,
        proposedDate: proposedDate,
        proposedTime: proposedTime,
      );

      if (!mounted) return;

      if (success) {
        showMessage(
          isReschedule
              ? 'New time sent to the customer.'
              : 'Appointment time sent to the customer.',
          success: true,
        );
        await loadRequests();
      } else {
        showMessage('Could not send this time. Check your availability.');
      }
    } catch (e) {
      showMessage('Something went wrong. Check your connection and retry.');
    } finally {
      setProcessing(requestId, false);
    }
  }

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: _kBlack,
          onPrimary: _kYellow,
          surface: Colors.white,
        ),
      ),
      child: child!,
    );
  }

  // ----------------------------------------------------------
  // FORMATTING
  // ----------------------------------------------------------

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Not scheduled';

    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;

    return '${_kWeekdays[parsed.weekday - 1]}, '
        '${parsed.day} ${_kMonths[parsed.month - 1]} ${parsed.year}';
  }

  String formatTime(String? time) {
    if (time == null || time.isEmpty) return 'Not scheduled';

    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');

      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return '$hour:$minute $period';
    } catch (e) {
      return time;
    }
  }

  String displayStatus(String status) {
    switch (status) {
      case 'TIME_PROPOSED':
        return 'Time sent';
      case 'RESCHEDULE_PROPOSED':
        return 'New time sent';
      case 'CUSTOMER_TIME_PROPOSED':
        return 'Customer proposed time';
      case 'NEGOTIATING':
        return 'Needs new time';
      case 'IN_PROGRESS':
        return 'In progress';
      default:
        if (status.isEmpty) return 'Pending';
        final lower = status.replaceAll('_', ' ').toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }
  }

  String filterLabel(_RequestFilter filter) {
    switch (filter) {
      case _RequestFilter.all:
        return 'All';
      case _RequestFilter.needsAction:
        return 'Needs action';
      case _RequestFilter.approved:
        return 'Approved';
      case _RequestFilter.waiting:
        return 'Waiting on customer';
      case _RequestFilter.rejected:
        return 'Rejected';
    }
  }

  // ----------------------------------------------------------
  // FILTERING
  // ----------------------------------------------------------

  String _statusOf(dynamic request) =>
      request['status']?.toString() ?? 'PENDING';

  int _idOf(dynamic request) =>
      int.tryParse(request['id']?.toString() ?? '') ?? 0;

  bool _matches(String status, _RequestFilter filter) {
    if (status == 'COMPLETED') return false;

    switch (filter) {
      case _RequestFilter.all:
        return true;
      case _RequestFilter.needsAction:
        return _kNeedsAction.contains(status);
      case _RequestFilter.approved:
        return status == 'ACCEPTED' ||
            status == 'CONFIRMED' ||
            status == 'IN_PROGRESS';
      case _RequestFilter.waiting:
        return status == 'TIME_PROPOSED' || status == 'RESCHEDULE_PROPOSED';
      case _RequestFilter.rejected:
        return status == 'REJECTED';
    }
  }

  int countFor(_RequestFilter filter) =>
      requests.where((r) => _matches(_statusOf(r), filter)).length;

  int get historyCount =>
      requests.where((r) => _statusOf(r) == 'COMPLETED').length;

  List<dynamic> get visibleRequests {
    final result = requests.where((request) {
      final status = _statusOf(request);
      return showHistory
          ? status == 'COMPLETED'
          : _matches(status, selectedFilter);
    }).toList();

    result.sort((a, b) {
      if (!showHistory) {
        final aUrgent = _kNeedsAction.contains(_statusOf(a));
        final bUrgent = _kNeedsAction.contains(_statusOf(b));
        if (aUrgent != bUrgent) return aUrgent ? -1 : 1;
      }
      return _idOf(b).compareTo(_idOf(a));
    });

    return result;
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

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
          'Service requests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadRequests,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? _buildSkeleton()
          : RefreshIndicator(
              color: _kBlack,
              backgroundColor: _kYellow,
              onRefresh: loadRequests,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  _buildTabSwitcher(),
                  const SizedBox(height: 14),
                  if (!showHistory) ...[
                    _buildActionBanner(),
                    _buildFilterBar(),
                    const SizedBox(height: 16),
                  ],
                  if (hasError && requests.isEmpty)
                    _buildErrorState()
                  else if (visibleRequests.isEmpty)
                    _buildEmptyState()
                  else
                    ...visibleRequests.map(
                      (request) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildRequestCard(request),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // ----------------------------------------------------------
  // TAB SWITCHER (Active / History)
  // ----------------------------------------------------------

  Widget _buildTabSwitcher() {
    Widget tab(String label, bool selected, int count, VoidCallback onTap) {
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: '$label, $count',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? _kBlack : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : _kTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? _kYellow : _kSurfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _kBlack,
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

    final activeCount = requests
        .where((r) => _statusOf(r) != 'COMPLETED')
        .length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          tab('Active', !showHistory, activeCount, () {
            setState(() => showHistory = false);
          }),
          tab('History', showHistory, historyCount, () {
            setState(() => showHistory = true);
          }),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // "NEEDS YOUR RESPONSE" BANNER
  // ----------------------------------------------------------

  Widget _buildActionBanner() {
    final count = countFor(_RequestFilter.needsAction);

    if (count == 0 || selectedFilter == _RequestFilter.needsAction) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(
          () => selectedFilter = _RequestFilter.needsAction,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _kYellowSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kYellow),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: _kBlack),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  count == 1
                      ? '1 request needs your response'
                      : '$count requests need your response',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _kBlack,
                  ),
                ),
              ),
              const Text(
                'View',
                style: TextStyle(fontWeight: FontWeight.w800, color: _kBlack),
              ),
              const Icon(Icons.chevron_right_rounded, color: _kBlack),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // FILTER BAR
  // ----------------------------------------------------------

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _RequestFilter.values.map((filter) {
          final selected = selectedFilter == filter;
          final count = countFor(filter);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filter == _RequestFilter.all
                    ? filterLabel(filter)
                    : '${filterLabel(filter)} · $count',
              ),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => selectedFilter = filter),
              selectedColor: _kYellow,
              backgroundColor: Colors.white,
              side: BorderSide(color: selected ? _kYellow : _kBorder),
              labelStyle: TextStyle(
                color: _kBlack,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ----------------------------------------------------------
  // REQUEST CARD
  // ----------------------------------------------------------

  Widget _buildRequestCard(dynamic request) {
    final customer = request['customer'];
    final service = request['service'];

    final customerName = customer?['name']?.toString() ?? 'Unknown customer';
    final customerEmail = customer?['email']?.toString() ?? '';
    final serviceName = service?['name']?.toString() ?? 'Unknown service';

    final serviceType = request['serviceType']?.toString() ?? 'SCHEDULED';
    final isScheduled = serviceType == 'SCHEDULED';

    final date = request['requestedDate']?.toString();
    final time = request['requestedTime']?.toString();
    final proposedDate = request['proposedDate']?.toString();
    final proposedTime = request['proposedTime']?.toString();

    final address = request['address']?.toString() ?? '';
    final description = request['description']?.toString() ?? '';
    final rejectionReason = request['rejectionReason']?.toString() ?? '';

    final status = _statusOf(request);
    final requestId = int.tryParse(request['id']?.toString() ?? '');
    final isProcessing =
        requestId != null && processingRequests.contains(requestId);

    final hasProposedTime = (status == 'TIME_PROPOSED' ||
            status == 'RESCHEDULE_PROPOSED' ||
            status == 'CUSTOMER_TIME_PROPOSED') &&
        (proposedDate?.isNotEmpty ?? false) &&
        (proposedTime?.isNotEmpty ?? false);

    final needsAction = _kNeedsAction.contains(status);

    final hasRequestedSlot = (date?.isNotEmpty ?? false) ||
        (time?.isNotEmpty ?? false);

    final requestedText = hasRequestedSlot
        ? '${formatDate(date)} at ${formatTime(time)}'
        : (isScheduled ? 'Not scheduled' : 'As soon as possible');

    return Semantics(
      container: true,
      label: '$customerName, $serviceName, ${displayStatus(status)}',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: needsAction ? _kYellow : _kBorder,
            width: needsAction ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (needsAction)
              Container(
                width: double.infinity,
                color: _kYellow,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 7,
                ),
                child: const Text(
                  'Waiting for your response',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _kBlack,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(
                    customerName: customerName,
                    customerEmail: customerEmail,
                    serviceName: serviceName,
                    status: status,
                  ),
                  const SizedBox(height: 16),

                  // KEY DETAILS
                  _detailRow(
                    isScheduled
                        ? Icons.calendar_month_rounded
                        : Icons.flash_on_rounded,
                    isScheduled ? 'Requested time' : 'On-demand request',
                    requestedText,
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    Icons.location_on_rounded,
                    'Location',
                    address.isEmpty ? 'No address provided' : address,
                    muted: address.isEmpty,
                  ),

                  if (hasProposedTime) ...[
                    const SizedBox(height: 14),
                    _buildProposedTimeBox(
                      proposedDate!,
                      proposedTime!,
                      fromCustomer: status == 'CUSTOMER_TIME_PROPOSED',
                    ),
                  ],

                  if (status == 'NEGOTIATING') ...[
                    const SizedBox(height: 14),
                    _infoMessage(
                      'The customer declined your proposed time. '
                      'Send a new appointment time.',
                      icon: Icons.event_repeat_rounded,
                    ),
                  ],

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer notes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: _kBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (status == 'REJECTED' && rejectionReason.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE3E3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Why you rejected this',
                            style: TextStyle(
                              fontSize: 12,
                              color: _kDanger,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rejectionReason,
                            style: const TextStyle(
                              color: _kBlack,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  ..._buildActions(
                    requestId: requestId,
                    status: status,
                    isScheduled: isScheduled,
                    isProcessing: isProcessing,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader({
    required String customerName,
    required String customerEmail,
    required String serviceName,
    required String status,
  }) {
    final initial =
        customerName.isNotEmpty ? customerName[0].toUpperCase() : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _kYellow,
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _kBlack,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _kBlack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                serviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _StatusChip(status: status, label: displayStatus(status)),
            ],
          ),
        ),
        if (customerEmail.isNotEmpty)
          IconButton(
            tooltip: 'Chat with $customerName',
            style: IconButton.styleFrom(
              backgroundColor: _kSurfaceMuted,
              foregroundColor: _kBlack,
              fixedSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUserEmail: customerEmail,
                    otherUserName: customerName,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildProposedTimeBox(
    String proposedDate,
    String proposedTime, {
    required bool fromCustomer,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kYellowSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kYellow),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded, color: _kBlack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fromCustomer
                      ? 'Time proposed by customer'
                      : 'Time you proposed',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatDate(proposedDate)} at ${formatTime(proposedTime)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

  // ----------------------------------------------------------
  // CARD ACTIONS (one primary action per state)
  // ----------------------------------------------------------

  List<Widget> _buildActions({
    required int? requestId,
    required String status,
    required bool isScheduled,
    required bool isProcessing,
  }) {
    if (requestId == null) return const [];

    const gap = SizedBox(height: 10);
    final List<Widget> actions = [];

    switch (status) {
      case 'PENDING':
        if (isScheduled) {
          actions.addAll([
            _primaryButton(
              label: 'Accept request',
              icon: Icons.check_rounded,
              isLoading: isProcessing,
              onPressed: () => updateStatus(requestId, 'ACCEPTED'),
            ),
            gap,
            Row(
              children: [
                Expanded(
                  child: _outlineButton(
                    label: 'Suggest time',
                    icon: Icons.edit_calendar_rounded,
                    color: _kBlack,
                    isLoading: isProcessing,
                    onPressed: () => showProposeTimeDialog(
                      requestId,
                      isReschedule: false,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _outlineButton(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    color: _kDanger,
                    isLoading: isProcessing,
                    onPressed: () => showRejectDialog(requestId),
                  ),
                ),
              ],
            ),
          ]);
        } else {
          actions.addAll([
            _primaryButton(
              label: 'Accept & set time',
              icon: Icons.calendar_month_rounded,
              isLoading: isProcessing,
              onPressed: () => showProposeTimeDialog(
                requestId,
                isReschedule: false,
              ),
            ),
            gap,
            _outlineButton(
              label: 'Reject request',
              icon: Icons.close_rounded,
              color: _kDanger,
              isLoading: isProcessing,
              onPressed: () => showRejectDialog(requestId),
            ),
          ]);
        }
        break;

      case 'NEGOTIATING':
        actions.add(
          _primaryButton(
            label: 'Send new time',
            icon: Icons.calendar_month_rounded,
            isLoading: isProcessing,
            onPressed: () => showProposeTimeDialog(
              requestId,
              isReschedule: true,
            ),
          ),
        );
        break;

      case 'TIME_PROPOSED':
      case 'RESCHEDULE_PROPOSED':
        actions.add(
          _infoMessage(
            'Time sent. We will update this request when the customer '
            'responds.',
            icon: Icons.hourglass_top_rounded,
          ),
        );
        break;

      case 'CUSTOMER_TIME_PROPOSED':
        actions.add(
          Row(
            children: [
              Expanded(
                child: _outlineButton(
                  label: 'Decline',
                  icon: Icons.close_rounded,
                  color: _kDanger,
                  isLoading: isProcessing,
                  onPressed: () => respondToCustomerProposedTime(
                    requestId,
                    accept: false,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _primaryButton(
                  label: 'Accept time',
                  icon: Icons.check_rounded,
                  isLoading: isProcessing,
                  onPressed: () => respondToCustomerProposedTime(
                    requestId,
                    accept: true,
                  ),
                ),
              ),
            ],
          ),
        );
        break;

      case 'ACCEPTED':
      case 'CONFIRMED':
        actions.add(
          _primaryButton(
            label: 'Start service',
            icon: Icons.play_circle_outline_rounded,
            isLoading: isProcessing,
            onPressed: () => updateStatus(requestId, 'IN_PROGRESS'),
          ),
        );
        break;

      case 'IN_PROGRESS':
        actions.add(
          _primaryButton(
            label: 'Mark as completed',
            icon: Icons.check_circle_outline_rounded,
            isLoading: isProcessing,
            onPressed: () => completeService(requestId),
          ),
        );
        break;
    }

    if (actions.isEmpty) return const [];

    return [const SizedBox(height: 18), ...actions];
  }

  // ----------------------------------------------------------
  // SHARED WIDGETS
  // ----------------------------------------------------------

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kBlack,
                ),
              )
            : Icon(icon, size: 19),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kYellow,
          foregroundColor: _kBlack,
          disabledBackgroundColor: _kYellow.withValues(alpha: 0.5),
          disabledForegroundColor: _kBlack.withValues(alpha: 0.6),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          disabledForegroundColor: color.withValues(alpha: 0.4),
          side: BorderSide(
            color: isLoading ? color.withValues(alpha: 0.3) : color,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _infoMessage(String message, {IconData icon = Icons.info_outline}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kYellowSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kBlack),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _kBlack,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    bool muted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _kSurfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: _kBlack),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: muted ? _kTextSecondary : _kBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // LOADING / EMPTY / ERROR STATES
  // ----------------------------------------------------------

  Widget _buildSkeleton() {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: _kSurfaceMuted,
            borderRadius: BorderRadius.circular(8),
          ),
        );

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        bar(double.infinity, 52),
        const SizedBox(height: 18),
        for (int i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: _kSurfaceMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [bar(140, 14), const SizedBox(height: 8), bar(90, 12)],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                bar(double.infinity, 12),
                const SizedBox(height: 10),
                bar(200, 12),
                const SizedBox(height: 18),
                bar(double.infinity, 48),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;

    if (showHistory) {
      title = 'No completed bookings yet';
      subtitle = 'Finished services will appear here.';
    } else if (selectedFilter == _RequestFilter.all) {
      title = 'No requests yet';
      subtitle = 'New customer requests will show up here. Pull down to check '
          'for updates.';
    } else {
      title = 'Nothing under "${filterLabel(selectedFilter)}"';
      subtitle = 'Try another filter to see your other requests.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          _circleIcon(Icons.assignment_rounded),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kBlack,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: _kTextSecondary,
            ),
          ),
          if (!showHistory && selectedFilter != _RequestFilter.all) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  setState(() => selectedFilter = _RequestFilter.all),
              child: const Text(
                'Show all requests',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _kBlack,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          _circleIcon(Icons.cloud_off_rounded),
          const SizedBox(height: 18),
          const Text(
            'Could not load your requests',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kBlack,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check your connection and try again.',
            style: TextStyle(fontSize: 13, color: _kTextSecondary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 160,
            child: _primaryButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              onPressed: () {
                setState(() => isLoading = true);
                loadRequests();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: _kYellow.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 38, color: _kBlack),
    );
  }
}

// ============================================================
// STATUS CHIP
// ============================================================

class _StatusChip extends StatelessWidget {
  final String status;
  final String label;

  const _StatusChip({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: style.foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: style.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REJECTION REASON DIALOG
// ============================================================

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  static const List<String> _quickReasons = [
    'Not available at that time',
    'Outside my service area',
    'Not a service I offer',
    'Fully booked',
  ];

  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _useQuickReason(String reason) {
    _controller.text = reason;
    _controller.selection = TextSelection.collapsed(offset: reason.length);
    setState(() => _errorMessage = null);
  }

  void _submitReason() {
    final reason = _controller.text.trim();

    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Add a reason so the customer knows why.');
      return;
    }

    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Reject this request?',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The customer will see your reason.',
              style: TextStyle(color: _kTextSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickReasons
                  .map(
                    (reason) => ActionChip(
                      label: Text(reason),
                      labelStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _kBlack,
                      ),
                      backgroundColor: _kSurfaceMuted,
                      side: BorderSide.none,
                      onPressed: () => _useQuickReason(reason),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLines: 3,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
              decoration: InputDecoration(
                hintText: 'Write a reason',
                errorText: _errorMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBlack, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: _kTextSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kDanger,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _submitReason,
          child: const Text('Reject request'),
        ),
      ],
    );
  }
}