
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';
import '../customer/chat_screen.dart';

const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);
const Color _kDanger = Color(0xFFD92D20);
const Color _kSuccess = Color(0xFF1B7A3C);

enum _RequestFilter {
  all,
  pending,
  approved,
  rejected,
  waitingForTime,
}

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});

  @override
  State<ProviderRequestsScreen> createState() =>
      _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState
    extends State<ProviderRequestsScreen> {
  List<dynamic> requests = [];

  bool isLoading = true;

  _RequestFilter selectedFilter = _RequestFilter.all;
  bool showHistory = false;

  final Set<int> processingRequests = {};

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  // ============================================================
  // LOAD REQUESTS
  // ============================================================

  Future<void> loadRequests() async {
    final email = Session.email;

    if (email.isEmpty) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      return;
    }

    try {
      final result = await ApiService.getProviderRequests(
        email: email,
      );

      if (!mounted) return;

      setState(() {
        requests = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage('Unable to load service requests.');
    }
  }

  // ============================================================
  // PROCESSING STATE
  // ============================================================

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

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? _kSuccess : _kDanger,
      ),
    );
  }

  // ============================================================
  // UPDATE REQUEST STATUS
  // ============================================================

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
        String message;

        switch (status) {
          case 'ACCEPTED':
            message = 'Service request accepted.';
            break;
          case 'REJECTED':
            message = 'Service request rejected.';
            break;
          case 'IN_PROGRESS':
            message = 'Service marked as in progress.';
            break;
          case 'COMPLETED':
            message = 'Service request completed.';
            break;
          default:
            message = 'Request updated successfully.';
        }

        showMessage(message, success: true);
        await loadRequests();
      } else {
        showMessage('Failed to update service request.');
      }
    } catch (e) {
      if (mounted) {
        showMessage('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setProcessing(requestId, false);
      }
    }
  }

  // ============================================================
  // PROVIDER ACCEPTS OR DECLINES CUSTOMER-PROPOSED TIME
  // Legacy support for existing CUSTOMER_TIME_PROPOSED requests
  // ============================================================

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
              ? 'Customer appointment time accepted.'
              : 'Customer appointment time declined.',
          success: true,
        );

        await loadRequests();
      } else {
        showMessage(
          accept
              ? 'Unable to accept the proposed time. '
                  'Please check your availability.'
              : 'Unable to decline the proposed time.',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setProcessing(requestId, false);
      }
    }
  }

  // ============================================================
  // REJECT REQUEST DIALOG
  // ============================================================

  Future<void> showRejectDialog(int requestId) async {
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RejectReasonDialog(),
    );

    if (!mounted || reason == null || reason.trim().isEmpty) {
      return;
    }

    await updateStatus(
      requestId,
      'REJECTED',
      reason: reason.trim(),
    );
  }

  // ============================================================
  // PROPOSE / RESCHEDULE TIME
  // ============================================================

  Future<void> showProposeTimeDialog(
    int requestId, {
    required bool isReschedule,
  }) async {
    DateTime selectedDate = DateTime.now().add(
      const Duration(days: 1),
    );

    TimeOfDay selectedTime = TimeOfDay.now();

    final dateResult = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      builder: (context, child) {
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
      },
    );

    if (dateResult == null || !mounted) return;

    selectedDate = dateResult;

    final timeResult = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (timeResult == null || !mounted) return;

    selectedTime = timeResult;

    final proposedDate =
        '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';

    final proposedTime =
        '${selectedTime.hour.toString().padLeft(2, '0')}:'
        '${selectedTime.minute.toString().padLeft(2, '0')}';

    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (!selectedDateTime.isAfter(DateTime.now())) {
      showMessage('Please select a future date and time.');
      return;
    }

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
              ? 'New appointment time proposed.'
              : 'Appointment time sent to customer.',
          success: true,
        );

        await loadRequests();
      } else {
        showMessage(
          'Failed to propose time. Check provider availability.',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setProcessing(requestId, false);
      }
    }
  }

  // ============================================================
  // DATE AND TIME FORMATTING
  // ============================================================

  String formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'Not scheduled';
    }

    final parts = date.split('-');

    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }

    return date;
  }

  String formatTime(String? time) {
    if (time == null || time.isEmpty) {
      return 'Not scheduled';
    }

    try {
      final parts = time.split(':');

      int hour = int.parse(parts[0]);
      final minute = parts[1];

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

  // ============================================================
  // STATUS LABEL
  // ============================================================

  String displayStatus(String status) {
    switch (status) {
      case 'TIME_PROPOSED':
        return 'Time Proposed';

      case 'RESCHEDULE_PROPOSED':
        return 'New Time Proposed';

      case 'CUSTOMER_TIME_PROPOSED':
        return 'Customer Proposed Time';

      case 'NEGOTIATING':
        return 'Waiting for New Time';

      case 'IN_PROGRESS':
        return 'In Progress';

      default:
        if (status.isEmpty) return 'Pending';

        return status
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}'
                      '${word.substring(1).toLowerCase()}',
            )
            .join(' ');
    }
  }

  // ============================================================
  // FILTER LABELS
  // ============================================================

  String filterLabel(_RequestFilter filter) {
    switch (filter) {
      case _RequestFilter.all:
        return 'All';

      case _RequestFilter.pending:
        return 'Pending';

      case _RequestFilter.approved:
        return 'Approved';

      case _RequestFilter.rejected:
        return 'Rejected';

      case _RequestFilter.waitingForTime:
        return 'Waiting / New Time';
    }
  }

  // ============================================================
  // FILTER REQUESTS
  // ============================================================

  bool matchesFilter(dynamic request) {
    final status = request['status']?.toString() ?? 'PENDING';

    if (status == 'COMPLETED') return false;

    switch (selectedFilter) {
      case _RequestFilter.all:
        return true;

      case _RequestFilter.pending:
        return status == 'PENDING';

      case _RequestFilter.approved:
        return status == 'ACCEPTED' ||
            status == 'CONFIRMED' ||
            status == 'IN_PROGRESS';

      case _RequestFilter.rejected:
        return status == 'REJECTED';

      case _RequestFilter.waitingForTime:
        return status == 'TIME_PROPOSED' ||
            status == 'RESCHEDULE_PROPOSED' ||
            status == 'NEGOTIATING' ||
            status == 'CUSTOMER_TIME_PROPOSED';
    }
  }

  // ============================================================
  // VISIBLE REQUESTS
  // ============================================================

  List<dynamic> get visibleRequests {
    final result = requests.where((request) {
      final status = request['status']?.toString() ?? '';

      if (showHistory) {
        return status == 'COMPLETED';
      }

      return matchesFilter(request);
    }).toList();

    result.sort((a, b) {
      final aId = int.tryParse(a['id']?.toString() ?? '') ?? 0;
      final bId = int.tryParse(b['id']?.toString() ?? '') ?? 0;

      return bId.compareTo(aId);
    });

    return result;
  }

  int get historyCount {
    return requests.where(
      (request) => request['status']?.toString() == 'COMPLETED',
    ).length;
  }

  // ============================================================
  // BUILD
  // ============================================================

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
          'Service Requests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadRequests,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _kBlack),
            )
          : RefreshIndicator(
              color: _kBlack,
              backgroundColor: _kYellow,
              onRefresh: loadRequests,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  _buildSectionHeading(),
                  const SizedBox(height: 14),
                  _buildFilterBar(),
                  const SizedBox(height: 14),
                  _buildHistoryButton(),
                  const SizedBox(height: 18),
                  if (visibleRequests.isEmpty)
                    _buildEmptyState()
                  else
                    ...visibleRequests.map((request) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildRequestItem(request),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // SECTION HEADING
  // ============================================================

  Widget _buildSectionHeading() {
    return Row(
      children: [
        Expanded(
          child: Text(
            showHistory ? 'Booking History' : 'Your Requests',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _kBlack,
            ),
          ),
        ),
        Text(
          '${visibleRequests.length} requests',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kTextSecondary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar() {
    if (showHistory) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _RequestFilter.values.map((filter) {
          final selected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filterLabel(filter)),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) {
                setState(() {
                  selectedFilter = filter;
                });
              },
              selectedColor: _kYellow,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? _kYellow : _kBorder,
              ),
              labelStyle: TextStyle(
                color: _kBlack,
                fontWeight: selected
                    ? FontWeight.w800
                    : FontWeight.w600,
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

  // ============================================================
  // BOOKING HISTORY BUTTON
  // ============================================================

  Widget _buildHistoryButton() {
    final selected = showHistory;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          showHistory = !showHistory;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: selected ? _kBlack : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _kBlack : _kBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              color: selected ? _kYellow : _kBlack,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selected
                    ? 'Back to Active Requests'
                    : 'Booking History',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : _kBlack,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? _kYellow
                    : const Color(0xFFF3F3EE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$historyCount',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _kBlack,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              selected
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.arrow_forward_ios_rounded,
              size: 16,
              color: selected ? Colors.white : _kTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REQUEST ITEM
  // ============================================================

  Widget _buildRequestItem(dynamic request) {
    final customer = request['customer'];
    final service = request['service'];

    final customerName =
        customer?['name']?.toString() ?? 'Unknown Customer';

    final customerEmail =
        customer?['email']?.toString() ?? '';

    final serviceName =
        service?['name']?.toString() ?? 'Unknown Service';

    final serviceType =
        request['serviceType']?.toString() ?? 'SCHEDULED';

    final date = request['requestedDate']?.toString();
    final time = request['requestedTime']?.toString();

    final proposedDate = request['proposedDate']?.toString();
    final proposedTime = request['proposedTime']?.toString();

    final address = request['address']?.toString() ?? '';
    final description = request['description']?.toString() ?? '';

    final rejectionReason =
        request['rejectionReason']?.toString() ?? '';

    final status = request['status']?.toString() ?? 'PENDING';

    final requestId = int.tryParse(
      request['id']?.toString() ?? '',
    );

    final isScheduled = serviceType == 'SCHEDULED';

    final isProcessing = requestId != null &&
        processingRequests.contains(requestId);

    return _buildRequestCard(
      requestId: requestId,
      customerName: customerName,
      customerEmail: customerEmail,
      serviceName: serviceName,
      serviceType: serviceType,
      isScheduled: isScheduled,
      date: date,
      time: time,
      proposedDate: proposedDate,
      proposedTime: proposedTime,
      address: address,
      description: description,
      rejectionReason: rejectionReason,
      status: status,
      isProcessing: isProcessing,
    );
  }

  // ============================================================
  // REQUEST CARD
  // ============================================================

  Widget _buildRequestCard({
    required int? requestId,
    required String customerName,
    required String customerEmail,
    required String serviceName,
    required String serviceType,
    required bool isScheduled,
    required String? date,
    required String? time,
    required String? proposedDate,
    required String? proposedTime,
    required String address,
    required String description,
    required String rejectionReason,
    required String status,
    required bool isProcessing,
  }) {
    final hasProposedTime =
        (status == 'TIME_PROPOSED' ||
            status == 'RESCHEDULE_PROPOSED' ||
            status == 'CUSTOMER_TIME_PROPOSED') &&
        proposedDate != null &&
        proposedDate.isNotEmpty &&
        proposedTime != null &&
        proposedTime.isNotEmpty;

    return Container(
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CUSTOMER DETAILS
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: _kYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: _kBlack,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _kBlack,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  status: status,
                  label: displayStatus(status),
                ),
              ],
            ),

            const Divider(
              height: 28,
              color: Color(0xFFEFEFEA),
            ),

            // SERVICE NAME
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _kBlack,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                serviceName,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _kYellow,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // SERVICE TYPE
            Row(
              children: [
                Icon(
                  isScheduled
                      ? Icons.calendar_month_rounded
                      : Icons.flash_on_rounded,
                  size: 17,
                  color: _kBlack,
                ),
                const SizedBox(width: 8),
                Text(
                  isScheduled
                      ? 'Scheduled Request'
                      : 'On-Demand Request',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _kBlack,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // REQUESTED DATE
            _iconRow(
              Icons.calendar_today_rounded,
              formatDate(date),
            ),

            const SizedBox(height: 10),

            // REQUESTED TIME
            _iconRow(
              Icons.access_time_rounded,
              formatTime(time),
            ),

            // PROPOSED APPOINTMENT TIME
            if (hasProposedTime) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6D8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kYellow),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proposed Appointment Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _kBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatDate(proposedDate)} at '
                      '${formatTime(proposedTime)}',
                      style: const TextStyle(
                        color: _kBlack,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status == 'CUSTOMER_TIME_PROPOSED'
                          ? 'The customer is waiting for your response.'
                          : 'Waiting for customer confirmation.',
                      style: const TextStyle(
                        color: _kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // NEGOTIATION INFORMATION
            if (status == 'NEGOTIATING') ...[
              const SizedBox(height: 14),
              _infoMessage(
                'The customer rejected your previous proposed time. '
                'Please suggest a new appointment time.',
              ),
            ],

            const SizedBox(height: 10),

            // ADDRESS
            _iconRow(
              Icons.location_on_rounded,
              address.isEmpty ? 'No address provided' : address,
            ),

            // DESCRIPTION
            if (description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: _kTextSecondary,
                  ),
                ),
              ),
            ],

            // REJECTION REASON
            if (status == 'REJECTED' &&
                rejectionReason.isNotEmpty) ...[
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
                      'Rejection Reason',
                      style: TextStyle(
                        color: _kDanger,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
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

            const SizedBox(height: 18),

            // CHAT BUTTON
            if (customerEmail.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kBlack,
                    side: const BorderSide(
                      color: _kBlack,
                      width: 1.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUserEmail: customerEmail,
                          otherUserName: customerName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'Chat with Customer',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

            // ==================================================
            // PENDING REQUEST ACTIONS
            // ==================================================

            if (status == 'PENDING' && requestId != null) ...[
              const SizedBox(height: 12),

              if (isScheduled) ...[
                Row(
                  children: [
                    Expanded(
                      child: _outlineButton(
                        label: 'Reject',
                        icon: Icons.close_rounded,
                        color: _kDanger,
                        isLoading: isProcessing,
                        onPressed: () => showRejectDialog(requestId),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _outlineButton(
                        label: 'Set New Time',
                        icon: Icons.edit_calendar_rounded,
                        color: _kBlack,
                        isLoading: isProcessing,
                        onPressed: () => showProposeTimeDialog(
                          requestId,
                          isReschedule: false,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _primaryButton(
                  label: 'Accept Request',
                  icon: Icons.check_rounded,
                  isLoading: isProcessing,
                  onPressed: () => updateStatus(
                    requestId,
                    'ACCEPTED',
                  ),
                ),
              ] else ...[
                _outlineButton(
                  label: 'Reject Request',
                  icon: Icons.close_rounded,
                  color: _kDanger,
                  isLoading: isProcessing,
                  onPressed: () => showRejectDialog(requestId),
                ),
                const SizedBox(height: 10),
                _primaryButton(
                  label: 'Accept & Set Appointment Time',
                  icon: Icons.calendar_month_rounded,
                  isLoading: isProcessing,
                  onPressed: () => showProposeTimeDialog(
                    requestId,
                    isReschedule: false,
                  ),
                ),
              ],
            ],

            // ==================================================
            // NEGOTIATING: PROVIDER MUST PROPOSE A NEW TIME
            // ==================================================

            if (status == 'NEGOTIATING' &&
                requestId != null) ...[
              const SizedBox(height: 12),
              _primaryButton(
                label: 'Propose New Time',
                icon: Icons.calendar_month_rounded,
                isLoading: isProcessing,
                onPressed: () => showProposeTimeDialog(
                  requestId,
                  isReschedule: true,
                ),
              ),
            ],

            // ==================================================
            // PROVIDER'S PROPOSED TIME
            // ==================================================

            if (status == 'TIME_PROPOSED' ||
                status == 'RESCHEDULE_PROPOSED') ...[
              const SizedBox(height: 12),
              _infoMessage(
                'Your proposed time has been sent. '
                'Waiting for the customer to respond.',
              ),
            ],

            // ==================================================
            // CUSTOMER-PROPOSED TIME: LEGACY SUPPORT
            // ==================================================

            if (status == 'CUSTOMER_TIME_PROPOSED' &&
                requestId != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _outlineButton(
                      label: 'Decline',
                      icon: Icons.close_rounded,
                      color: _kDanger,
                      isLoading: isProcessing,
                      onPressed: () =>
                          respondToCustomerProposedTime(
                        requestId,
                        accept: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _primaryButton(
                      label: 'Accept Time',
                      icon: Icons.check_rounded,
                      isLoading: isProcessing,
                      onPressed: () =>
                          respondToCustomerProposedTime(
                        requestId,
                        accept: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ==================================================
            // ACCEPTED
            // ==================================================

            if (status == 'ACCEPTED' && requestId != null) ...[
              const SizedBox(height: 12),
              _primaryButton(
                label: 'Start Service',
                icon: Icons.play_circle_outline_rounded,
                isLoading: isProcessing,
                onPressed: () => updateStatus(
                  requestId,
                  'IN_PROGRESS',
                ),
              ),
            ],

            // ==================================================
            // IN PROGRESS
            // ==================================================

            if (status == 'IN_PROGRESS' && requestId != null) ...[
              const SizedBox(height: 12),
              _primaryButton(
                label: 'Mark as Completed',
                icon: Icons.check_circle_outline_rounded,
                isLoading: isProcessing,
                onPressed: () => updateStatus(
                  requestId,
                  'COMPLETED',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRIMARY BUTTON
  // ============================================================

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
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
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kYellow,
          foregroundColor: _kBlack,
          disabledBackgroundColor: _kYellow.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OUTLINE BUTTON
  // ============================================================

  Widget _outlineButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
            color: color,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFO MESSAGE
  // ============================================================

  Widget _infoMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: _kBlack,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }

  // ============================================================
  // ICON ROW
  // ============================================================

  Widget _iconRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3EE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: _kBlack,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _kTextSecondary,
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 65),
      child: Column(
        children: [
          const _EmptyRequestsIcon(),
          const SizedBox(height: 16),
          Text(
            showHistory
                ? 'No completed bookings yet.'
                : 'No ${filterLabel(selectedFilter).toLowerCase()} requests.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pull down to refresh.',
            style: TextStyle(
              fontSize: 12,
              color: _kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STATUS CHIP
// ============================================================

class _StatusChip extends StatelessWidget {
  final String status;
  final String label;

  const _StatusChip({
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;

    switch (status.toUpperCase()) {
      case 'PENDING':
        background = const Color(0xFFFFF1BF);
        foreground = const Color(0xFF7A5A00);
        break;

      case 'ACCEPTED':
      case 'CONFIRMED':
        background = _kBlack;
        foreground = _kYellow;
        break;

      case 'TIME_PROPOSED':
      case 'RESCHEDULE_PROPOSED':
      case 'CUSTOMER_TIME_PROPOSED':
      case 'NEGOTIATING':
        background = const Color(0xFFFFF6D8);
        foreground = const Color(0xFF7A5A00);
        break;

      case 'IN_PROGRESS':
        background = const Color(0xFFE3EEFF);
        foreground = const Color(0xFF2457A6);
        break;

      case 'COMPLETED':
        background = const Color(0xFFDFF5E6);
        foreground = _kSuccess;
        break;

      case 'REJECTED':
      case 'DECLINED':
      case 'CANCELLED':
      case 'CANCELED':
        background = const Color(0xFFFDE3E3);
        foreground = const Color(0xFFB3261E);
        break;

      default:
        background = const Color(0xFFEDEDE8);
        foreground = _kTextSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY REQUESTS ICON
// ============================================================

class _EmptyRequestsIcon extends StatelessWidget {
  const _EmptyRequestsIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: _kYellow.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.assignment_rounded,
          size: 38,
          color: _kBlack,
        ),
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
  State<_RejectReasonDialog> createState() =>
      _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final TextEditingController _controller =
      TextEditingController();

  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitReason() {
    final reason = _controller.text.trim();

    if (reason.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a rejection reason.';
      });
      return;
    }

    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Reject Service Request',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please provide a reason for rejecting this request.',
            style: TextStyle(color: _kTextSecondary),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 1000,
            autofocus: true,
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Enter rejection reason...',
              errorText: _errorMessage,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kDanger,
            foregroundColor: Colors.white,
          ),
          onPressed: _submitReason,
          child: const Text('Reject Request'),
        ),
      ],
    );
  }
}
