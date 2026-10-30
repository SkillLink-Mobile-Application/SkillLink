
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';
import 'rate_provider_screen.dart';

const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);

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
  bool isProcessing = false;

  String selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'Approved',
    'Rejected',
    'Waiting / New Time',
  ];

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    final email = Session.email;

    if (email.isEmpty) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      return;
    }

    try {
      final result = await ApiService.getCustomerRequests(email: email);

      final Map<int, bool> reviewStatus = {};

      for (final booking in result) {
        final status = booking['status']?.toString() ?? '';
        final requestId = int.tryParse(booking['id']?.toString() ?? '');

        if (status == 'COMPLETED' && requestId != null) {
          reviewStatus[requestId] =
              await ApiService.hasReview(requestId);
        }
      }

      if (!mounted) return;

      // Newest bookings first.
      result.sort((a, b) {
        final dateA = DateTime.tryParse(
          a['createdAt']?.toString() ?? '',
        );
        final dateB = DateTime.tryParse(
          b['createdAt']?.toString() ?? '',
        );

        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      setState(() {
        bookings = result;
        reviewedBookings = reviewStatus;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load bookings.')),
      );
    }
  }

  String formatDate(String date) {
    if (date.isEmpty) return 'Not set';

    final parts = date.split('-');

    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }

    return date;
  }

  String formatTime(String time) {
    if (time.isEmpty) return 'Not set';

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
    } catch (_) {
      return time;
    }
  }

  bool _isWaitingForTime(String status) {
    return status == 'TIME_PROPOSED' ||
        status == 'RESCHEDULE_PROPOSED' ||
        status == 'NEGOTIATING' ||
        status == 'CUSTOMER_TIME_PROPOSED';
  }

  List<dynamic> get activeBookings {
    return bookings.where((booking) {
      final status = booking['status']?.toString() ?? '';

      // Completed requests are displayed only in Booking History.
      if (status == 'COMPLETED') return false;

      switch (selectedFilter) {
        case 'Approved':
          return status == 'ACCEPTED' || status == 'CONFIRMED';

        case 'Rejected':
          return status == 'REJECTED';

        case 'Waiting / New Time':
          return _isWaitingForTime(status);

        default:
          return true;
      }
    }).toList();
  }

  List<dynamic> get completedBookings {
    return bookings.where(
      (booking) => booking['status']?.toString() == 'COMPLETED',
    ).toList();
  }

  Future<void> approveProposedTime(int requestId) async {
    await _runAction(() async {
      final success = await ApiService.confirmServiceRequestTime(
        requestId: requestId,
        email: Session.email,
      );

      if (success) {
        _showMessage('Appointment time confirmed.');
        await loadBookings();
      } else {
        _showMessage('Could not confirm the proposed time.');
      }
    });
  }

  Future<void> rejectProposedTime(int requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject & Get New Time?'),
        content: const Text(
          'Do you want to reject this proposed time and request '
          'a new appointment time from the provider? '
          'Your service request will not be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlack,
              foregroundColor: _kYellow,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject Time'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _runAction(() async {
      final success = await ApiService.declineServiceRequestTime(
        requestId: requestId,
        email: Session.email,
      );

      if (success) {
        _showMessage(
          'Time rejected. Waiting for a new time from the provider.',
        );
        await loadBookings();
      } else {
        _showMessage('Could not reject the proposed time.');
      }
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      await action();
    } catch (e) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String displayStatus(String status) {
    switch (status) {
      case 'TIME_PROPOSED':
        return 'Time Proposed';
      case 'RESCHEDULE_PROPOSED':
        return 'New Time Proposed';
      case 'NEGOTIATING':
        return 'Waiting for New Time';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'ACCEPTED':
        return 'Accepted';
      case 'CUSTOMER_TIME_PROPOSED':
        return 'Proposal Sent';
      default:
        if (status.isEmpty) return 'Pending';
        return status
            .split('_')
            .map((word) => word.isEmpty
                ? word
                : '${word[0]}${word.substring(1).toLowerCase()}')
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = activeBookings;
    final history = completedBookings;

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
          'My Bookings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _kBlack),
            )
          : RefreshIndicator(
              color: _kBlack,
              backgroundColor: _kYellow,
              onRefresh: loadBookings,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFilterSection(),
                  const SizedBox(height: 18),

                  if (filteredBookings.isEmpty)
                    _buildEmptyState(
                      selectedFilter == 'All'
                          ? 'No active bookings available.'
                          : 'No $selectedFilter bookings found.',
                    )
                  else
                    ...filteredBookings.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildBookingCard(
                          booking,
                          isHistory: false,
                        ),
                      ),
                    ),

                  const SizedBox(height: 18),
                  _buildHistorySection(history),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _kBlack,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              final selected = selectedFilter == filter;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: _kYellow,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? _kYellow : _kBorder,
                  ),
                  labelStyle: TextStyle(
                    color: _kBlack,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() => selectedFilter = filter);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(List<dynamic> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: _kBorder, height: 28),
        Row(
          children: [
            const Icon(Icons.history_rounded, color: _kBlack),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Booking History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kBlack,
                ),
              ),
            ),
            Text(
              '${history.length} completed',
              style: const TextStyle(
                fontSize: 12,
                color: _kTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (history.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                'No completed bookings yet.',
                style: TextStyle(color: _kTextSecondary),
              ),
            ),
          )
        else
          ...history.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildBookingCard(
                booking,
                isHistory: true,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBookingCard(
    dynamic booking, {
    required bool isHistory,
  }) {
    final provider = booking['provider'];
    final service = booking['service'];

    final providerName =
        provider?['name']?.toString() ?? 'Unknown Provider';

    final serviceName =
        service?['name']?.toString() ??
        service?['category']?.toString() ??
        'Unknown Service';

    final date = booking['requestedDate']?.toString() ?? '';
    final time = booking['requestedTime']?.toString() ?? '';
    final address = booking['address']?.toString() ?? '';

    final proposedDate =
        booking['proposedDate']?.toString() ?? '';
    final proposedTime =
        booking['proposedTime']?.toString() ?? '';

    final rejectionReason =
        booking['rejectionReason']?.toString() ?? '';

    final status = booking['status']?.toString() ?? 'PENDING';
    final requestId =
        int.tryParse(booking['id']?.toString() ?? '');

    final hasProposal =
        (status == 'TIME_PROPOSED' ||
            status == 'RESCHEDULE_PROPOSED') &&
        proposedDate.isNotEmpty &&
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
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
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
                    providerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
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

            const Divider(height: 26, color: Color(0xFFEFEFEA)),

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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kYellow,
                ),
              ),
            ),

            const SizedBox(height: 14),

            _iconRow(
              Icons.calendar_today_rounded,
              formatDate(date),
            ),

            const SizedBox(height: 10),

            _iconRow(
              Icons.access_time_rounded,
              formatTime(time),
            ),

            const SizedBox(height: 10),

            _iconRow(
              Icons.location_on_rounded,
              address.isEmpty ? 'No address provided' : address,
            ),

            if (hasProposal) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7D9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _kYellow.withValues(alpha: 0.7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          color: _kBlack,
                          size: 19,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Provider Proposed New Time',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _kBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${formatDate(proposedDate)} at ${formatTime(proposedTime)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _kBlack,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Accept this time or reject it to request another time.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (status == 'CUSTOMER_TIME_PROPOSED') ...[
              const SizedBox(height: 14),
              _infoMessage(
                'Your previously proposed time is waiting for provider confirmation.',
              ),
            ],

            if (status == 'NEGOTIATING') ...[
              const SizedBox(height: 14),
              _infoMessage(
                'You requested a new appointment time. '
                'Waiting for the provider to propose another time.',
              ),
            ],

            if (status == 'REJECTED' &&
                rejectionReason.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _infoMessage(
                'Reason: $rejectionReason',
                isError: true,
              ),
            ],

            const SizedBox(height: 16),

            if (hasProposal && requestId != null)
              _buildProposalActions(requestId),

            if (status == 'ACCEPTED')
              SizedBox(
                width: double.infinity,
                height: 46,
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
                    _showMessage(
                      'Contact feature will be added later.',
                    );
                  },
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: const Text('Contact Provider'),
                ),
              ),

            if (isHistory && requestId != null)
              _buildReviewButton(requestId, providerName),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalActions(int requestId) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kYellow,
              foregroundColor: _kBlack,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: isProcessing
                ? null
                : () => approveProposedTime(requestId),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text(
              'Accept Time',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _kBlack,
              side: const BorderSide(color: _kBlack),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isProcessing
                ? null
                : () => rejectProposedTime(requestId),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Reject & Get New Time',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewButton(int requestId, String providerName) {
    final isReviewed = reviewedBookings[requestId] == true;

    if (isReviewed) {
      return SizedBox(
        width: double.infinity,
        height: 46,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            disabledForegroundColor: _kTextSecondary,
            side: const BorderSide(color: _kBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: null,
          icon: const Icon(Icons.check_circle_rounded, size: 18),
          label: const Text('Rated'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kYellow,
          foregroundColor: _kBlack,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
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
        icon: const Icon(Icons.star_rounded, size: 19),
        label: const Text(
          'Rate Provider',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _infoMessage(String message, {bool isError = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? const Color(0xFFFDE3E3)
            : const Color(0xFFF3F3EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError
              ? const Color(0xFFB3261E)
              : _kTextSecondary,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Column(
        children: [
          const _EmptyBookingsIcon(),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

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
          child: Icon(icon, size: 16, color: _kBlack),
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
}

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

      case 'COMPLETED':
        background = const Color(0xFFDFF5E6);
        foreground = const Color(0xFF1B7A3C);
        break;

      case 'REJECTED':
      case 'DECLINED':
      case 'CANCELLED':
      case 'CANCELED':
        background = const Color(0xFFFDE3E3);
        foreground = const Color(0xFFB3261E);
        break;

      case 'TIME_PROPOSED':
      case 'RESCHEDULE_PROPOSED':
      case 'NEGOTIATING':
      case 'CUSTOMER_TIME_PROPOSED':
        background = const Color(0xFFFFF1BF);
        foreground = const Color(0xFF7A5A00);
        break;

      default:
        background = const Color(0xFFEDEDE8);
        foreground = _kTextSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class _EmptyBookingsIcon extends StatelessWidget {
  const _EmptyBookingsIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: _kYellow.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.calendar_month_rounded,
        size: 38,
        color: _kBlack,
      ),
    );
  }
}
