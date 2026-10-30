import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';
import 'chat_screen.dart';
import 'rate_provider_screen.dart';

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

// Statuses where the customer has to respond.
const Set<String> _kNeedsResponse = {'TIME_PROPOSED', 'RESCHEDULE_PROPOSED'};

enum _BookingFilter { all, needsResponse, approved, waiting, rejected }

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
        _kYellowSoft, Color(0xFF7A5A00), Icons.event_available_rounded);
    case 'CUSTOMER_TIME_PROPOSED':
    case 'NEGOTIATING':
      return const _StatusStyle(
        _kYellowSoft, Color(0xFF7A5A00), Icons.schedule_send_rounded);
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

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() =>
      _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  List<dynamic> bookings = [];
  Map<int, bool> reviewedBookings = {};

  bool isLoading = true;
  bool hasError = false;

  _BookingFilter selectedFilter = _BookingFilter.all;
  bool showHistory = false;

  final Set<int> processingRequests = {};

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  // ----------------------------------------------------------
  // DATA
  // ----------------------------------------------------------

  Future<void> loadBookings() async {
    final email = Session.email;

    if (email.isEmpty) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final result = await ApiService.getCustomerRequests(email: email);

      // Check review status for all completed bookings in parallel.
      final completedIds = <int>[];
      for (final booking in result) {
        final id = int.tryParse(booking['id']?.toString() ?? '');
        if (booking['status']?.toString() == 'COMPLETED' && id != null) {
          completedIds.add(id);
        }
      }

      final reviewStatus = <int, bool>{};
      await Future.wait(
        completedIds.map((id) async {
          try {
            reviewStatus[id] = await ApiService.hasReview(id);
          } catch (_) {
            reviewStatus[id] = false;
          }
        }),
      );

      if (!mounted) return;

      setState(() {
        bookings = result;
        reviewedBookings = reviewStatus;
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        hasError = true;
      });

      if (bookings.isNotEmpty) {
        _showMessage('Could not refresh. Showing your last loaded bookings.');
      }
    }
  }

  void _showMessage(String message, {bool success = false}) {
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
          backgroundColor: success ? _kSuccess : _kBlack,
          content: Row(
            children: [
              Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: success ? Colors.white : _kYellow,
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

  Future<void> _runAction(
    int requestId,
    Future<void> Function() action,
  ) async {
    if (processingRequests.contains(requestId)) return;

    setState(() => processingRequests.add(requestId));

    try {
      await action();
    } catch (e) {
      _showMessage('Something went wrong. Check your connection and retry.');
    } finally {
      if (mounted) {
        setState(() => processingRequests.remove(requestId));
      }
    }
  }

  Future<void> approveProposedTime(int requestId) async {
    await _runAction(requestId, () async {
      final success = await ApiService.confirmServiceRequestTime(
        requestId: requestId,
        email: Session.email,
      );

      if (success) {
        _showMessage('Appointment time confirmed.', success: true);
        await loadBookings();
      } else {
        _showMessage('Could not confirm this time. Please try again.');
      }
    });
  }

  Future<void> rejectProposedTime(int requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ask for a different time?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'The provider will be asked to suggest another time. '
          'Your booking stays open and is not cancelled.',
          style: TextStyle(color: _kTextSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Keep this time',
              style: TextStyle(color: _kTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlack,
              foregroundColor: _kYellow,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ask for new time'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _runAction(requestId, () async {
      final success = await ApiService.declineServiceRequestTime(
        requestId: requestId,
        email: Session.email,
      );

      if (success) {
        _showMessage(
          'Request sent. The provider will suggest a new time.',
          success: true,
        );
        await loadBookings();
      } else {
        _showMessage('Could not send your request. Please try again.');
      }
    });
  }

  void _openChat(String providerEmail, String providerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserEmail: providerEmail,
          otherUserName: providerName,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // FORMATTING
  // ----------------------------------------------------------

  String formatDate(String date) {
    if (date.isEmpty) return 'Not set';

    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;

    return '${_kWeekdays[parsed.weekday - 1]}, '
        '${parsed.day} ${_kMonths[parsed.month - 1]} ${parsed.year}';
  }

  String formatTime(String time) {
    if (time.isEmpty) return 'Not set';

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
    } catch (_) {
      return time;
    }
  }

  String displayStatus(String status) {
    switch (status) {
      case 'TIME_PROPOSED':
        return 'New time offered';
      case 'RESCHEDULE_PROPOSED':
        return 'New time offered';
      case 'NEGOTIATING':
        return 'Waiting for new time';
      case 'CUSTOMER_TIME_PROPOSED':
        return 'Your time sent';
      case 'IN_PROGRESS':
        return 'In progress';
      default:
        if (status.isEmpty) return 'Pending';
        final lower = status.replaceAll('_', ' ').toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }
  }

  String filterLabel(_BookingFilter filter) {
    switch (filter) {
      case _BookingFilter.all:
        return 'All';
      case _BookingFilter.needsResponse:
        return 'Needs response';
      case _BookingFilter.approved:
        return 'Approved';
      case _BookingFilter.waiting:
        return 'Waiting for provider';
      case _BookingFilter.rejected:
        return 'Rejected';
    }
  }

  // ----------------------------------------------------------
  // FILTERING
  // ----------------------------------------------------------

  String _statusOf(dynamic b) => b['status']?.toString() ?? 'PENDING';

  bool _matches(String status, _BookingFilter filter) {
    if (status == 'COMPLETED') return false;

    switch (filter) {
      case _BookingFilter.all:
        return true;
      case _BookingFilter.needsResponse:
        return _kNeedsResponse.contains(status);
      case _BookingFilter.approved:
        return status == 'ACCEPTED' ||
            status == 'CONFIRMED' ||
            status == 'IN_PROGRESS';
      case _BookingFilter.waiting:
        return status == 'PENDING' ||
            status == 'NEGOTIATING' ||
            status == 'CUSTOMER_TIME_PROPOSED';
      case _BookingFilter.rejected:
        return status == 'REJECTED';
    }
  }

  int countFor(_BookingFilter filter) =>
      bookings.where((b) => _matches(_statusOf(b), filter)).length;

  int get historyCount =>
      bookings.where((b) => _statusOf(b) == 'COMPLETED').length;

  int get activeCount =>
      bookings.where((b) => _statusOf(b) != 'COMPLETED').length;

  int _compareNewestFirst(dynamic a, dynamic b) {
    final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '');
    final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '');

    if (dateA != null && dateB != null) return dateB.compareTo(dateA);

    final idA = int.tryParse(a['id']?.toString() ?? '') ?? 0;
    final idB = int.tryParse(b['id']?.toString() ?? '') ?? 0;
    return idB.compareTo(idA);
  }

  List<dynamic> get visibleBookings {
    final result = bookings.where((b) {
      final status = _statusOf(b);
      return showHistory
          ? status == 'COMPLETED'
          : _matches(status, selectedFilter);
    }).toList();

    result.sort((a, b) {
      if (!showHistory) {
        final aUrgent = _kNeedsResponse.contains(_statusOf(a));
        final bUrgent = _kNeedsResponse.contains(_statusOf(b));
        if (aUrgent != bUrgent) return aUrgent ? -1 : 1;
      }
      return _compareNewestFirst(a, b);
    });

    return result;
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final list = visibleBookings;

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
          'My bookings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: isLoading
          ? _buildSkeleton()
          : RefreshIndicator(
              color: _kBlack,
              backgroundColor: _kYellow,
              onRefresh: loadBookings,
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
                  if (hasError && bookings.isEmpty)
                    _buildErrorState()
                  else if (list.isEmpty)
                    _buildEmptyState()
                  else
                    ...list.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildBookingCard(booking),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // ----------------------------------------------------------
  // TABS, BANNER, FILTERS
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

  Widget _buildActionBanner() {
    final count = countFor(_BookingFilter.needsResponse);

    if (count == 0 || selectedFilter == _BookingFilter.needsResponse) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            setState(() => selectedFilter = _BookingFilter.needsResponse),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _kYellowSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kYellow),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_available_rounded, color: _kBlack),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  count == 1
                      ? '1 provider offered a new time'
                      : '$count providers offered a new time',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _kBlack,
                  ),
                ),
              ),
              const Text(
                'Review',
                style: TextStyle(fontWeight: FontWeight.w800, color: _kBlack),
              ),
              const Icon(Icons.chevron_right_rounded, color: _kBlack),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _BookingFilter.values.map((filter) {
          final selected = selectedFilter == filter;
          final count = countFor(filter);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filter == _BookingFilter.all
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
  // BOOKING CARD
  // ----------------------------------------------------------

  Widget _buildBookingCard(dynamic booking) {
    final provider = booking['provider'];
    final service = booking['service'];

    final providerName = provider?['name']?.toString() ?? 'Unknown provider';
    final providerEmail = provider?['email']?.toString() ?? '';

    final serviceName = service?['name']?.toString() ??
        service?['category']?.toString() ??
        'Unknown service';

    final date = booking['requestedDate']?.toString() ?? '';
    final time = booking['requestedTime']?.toString() ?? '';
    final address = booking['address']?.toString() ?? '';

    final proposedDate = booking['proposedDate']?.toString() ?? '';
    final proposedTime = booking['proposedTime']?.toString() ?? '';
    final rejectionReason = booking['rejectionReason']?.toString() ?? '';

    final status = _statusOf(booking);
    final requestId = int.tryParse(booking['id']?.toString() ?? '');
    final isProcessing =
        requestId != null && processingRequests.contains(requestId);

    final hasProposal = _kNeedsResponse.contains(status) &&
        proposedDate.isNotEmpty &&
        proposedTime.isNotEmpty;

    final needsResponse = _kNeedsResponse.contains(status);
    final isHistory = status == 'COMPLETED';

    final requestedText = date.isEmpty && time.isEmpty
        ? 'As soon as possible'
        : '${formatDate(date)} at ${formatTime(time)}';

    final canChat = providerEmail.isNotEmpty &&
        (status == 'ACCEPTED' ||
            status == 'CONFIRMED' ||
            status == 'IN_PROGRESS' ||
            _kNeedsResponse.contains(status) ||
            status == 'NEGOTIATING' ||
            status == 'CUSTOMER_TIME_PROPOSED' ||
            status == 'PENDING');

    return Semantics(
      container: true,
      label: '$providerName, $serviceName, ${displayStatus(status)}',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: needsResponse ? _kYellow : _kBorder,
            width: needsResponse ? 1.5 : 1,
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
            if (needsResponse)
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
                    providerName: providerName,
                    providerEmail: providerEmail,
                    serviceName: serviceName,
                    status: status,
                    canChat: canChat,
                  ),
                  const SizedBox(height: 16),
                  _detailRow(
                    Icons.calendar_month_rounded,
                    'Your requested time',
                    requestedText,
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    Icons.location_on_rounded,
                    'Location',
                    address.isEmpty ? 'No address provided' : address,
                    muted: address.isEmpty,
                  ),

                  if (hasProposal) ...[
                    const SizedBox(height: 14),
                    _buildProposalBox(proposedDate, proposedTime),
                  ],

                  if (status == 'PENDING') ...[
                    const SizedBox(height: 14),
                    _infoMessage(
                      'Sent to the provider. You will be notified when they '
                      'respond.',
                      icon: Icons.hourglass_top_rounded,
                    ),
                  ],

                  if (status == 'CUSTOMER_TIME_PROPOSED') ...[
                    const SizedBox(height: 14),
                    _infoMessage(
                      'Your proposed time is waiting for the provider to '
                      'confirm.',
                      icon: Icons.schedule_send_rounded,
                    ),
                  ],

                  if (status == 'NEGOTIATING') ...[
                    const SizedBox(height: 14),
                    _infoMessage(
                      'You asked for a different time. The provider will '
                      'suggest a new one.',
                      icon: Icons.schedule_send_rounded,
                    ),
                  ],

                  if (status == 'REJECTED' &&
                      rejectionReason.trim().isNotEmpty) ...[
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
                            'Provider\'s reason',
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

                  if (hasProposal && requestId != null) ...[
                    const SizedBox(height: 18),
                    _primaryButton(
                      label: 'Accept this time',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: isProcessing,
                      onPressed: () => approveProposedTime(requestId),
                    ),
                    const SizedBox(height: 10),
                    _outlineButton(
                      label: 'Ask for a different time',
                      icon: Icons.refresh_rounded,
                      isDisabled: isProcessing,
                      onPressed: () => rejectProposedTime(requestId),
                    ),
                  ],

                  if (isHistory && requestId != null) ...[
                    const SizedBox(height: 18),
                    _buildReviewButton(requestId, providerName),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader({
    required String providerName,
    required String providerEmail,
    required String serviceName,
    required String status,
    required bool canChat,
  }) {
    final initial =
        providerName.isNotEmpty ? providerName[0].toUpperCase() : '?';

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
                providerName,
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
        if (canChat)
          IconButton(
            tooltip: 'Chat with $providerName',
            style: IconButton.styleFrom(
              backgroundColor: _kSurfaceMuted,
              foregroundColor: _kBlack,
              fixedSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            onPressed: () => _openChat(providerEmail, providerName),
          ),
      ],
    );
  }

  Widget _buildProposalBox(String proposedDate, String proposedTime) {
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
                const Text(
                  'Time offered by provider',
                  style: TextStyle(
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

  Widget _buildReviewButton(int requestId, String providerName) {
    if (reviewedBookings[requestId] == true) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            disabledForegroundColor: _kSuccess,
            side: const BorderSide(color: _kBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: null,
          icon: const Icon(Icons.check_circle_rounded, size: 18),
          label: const Text(
            'You rated this provider',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return _primaryButton(
      label: 'Rate provider',
      icon: Icons.star_rounded,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RateProviderScreen(
              serviceRequestId: requestId,
              providerName: providerName,
            ),
          ),
        ).then((_) => loadBookings());
      },
    );
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
    required VoidCallback onPressed,
    bool isDisabled = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: isDisabled ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kBlack,
          disabledForegroundColor: _kBlack.withValues(alpha: 0.4),
          side: BorderSide(
            color: isDisabled ? _kBlack.withValues(alpha: 0.3) : _kBlack,
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
        color: _kSurfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kTextSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _kTextSecondary,
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
                      children: [
                        bar(140, 14),
                        const SizedBox(height: 8),
                        bar(90, 12),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                bar(double.infinity, 12),
                const SizedBox(height: 10),
                bar(200, 12),
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
      subtitle = 'Finished services will appear here, where you can rate '
          'your provider.';
    } else if (selectedFilter == _BookingFilter.all) {
      title = 'No active bookings';
      subtitle = 'When you book a service, you can track it here.';
    } else {
      title = 'Nothing under "${filterLabel(selectedFilter)}"';
      subtitle = 'Try another filter to see your other bookings.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          _circleIcon(Icons.calendar_month_rounded),
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
          if (!showHistory && selectedFilter != _BookingFilter.all) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  setState(() => selectedFilter = _BookingFilter.all),
              child: const Text(
                'Show all bookings',
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
            'Could not load your bookings',
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
                loadBookings();
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