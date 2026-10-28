import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../utils/session.dart';
import '../customer/chat_screen.dart';

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);
const Color _kDanger = Color(0xFFD92D20);
const Color _kSuccess = Color(0xFF1B7A3C);

// ==================== Provider Requests Screen ====================

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({
    super.key,
  });

  @override
  State<ProviderRequestsScreen> createState() =>
      _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState
    extends State<ProviderRequestsScreen> {
  List<dynamic> requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  // ==================== Load Requests ====================

  Future<void> loadRequests() async {
    final email = Session.email;

    if (email.isEmpty) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      return;
    }

    final result = await ApiService.getProviderRequests(
      email: email,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      requests = result;
      isLoading = false;
    });
  }

  // ==================== Update Status ====================

  Future<void> updateStatus(
    int requestId,
    String status,
  ) async {
    final email = Session.email;

    if (email.isEmpty) {
      return;
    }

    final success =
        await ApiService.updateServiceRequestStatus(
      requestId: requestId,
      email: email,
      status: status,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'ACCEPTED'
                ? 'Service request accepted.'
                : status == 'COMPLETED'
                    ? 'Service request completed.'
                    : 'Service request rejected.',
          ),
          backgroundColor: status == 'ACCEPTED'
              ? _kSuccess
              : _kDanger,
        ),
      );

      await loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to update service request.',
          ),
        ),
      );
    }
  }

  // ==================== Format Date ====================

  String formatDate(String date) {
    final parts = date.split('-');

    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }

    return date;
  }

  // ==================== Format Time ====================

  String formatTime(String time) {
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

  // ==================== Build ====================

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
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _kBlack,
              ),
            )
          : requests.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: _kBlack,
                  backgroundColor: _kYellow,
                  onRefresh: loadRequests,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final request = requests[index];

                      final customer =
                          request['customer'];

                      final service =
                          request['service'];

                      final customerName =
                          customer?['name']?.toString() ??
                              'Unknown Customer';

                      final customerEmail =
                          customer?['email']?.toString() ??
                              '';

                      final serviceName =
                          service?['name']?.toString() ??
                              'Unknown Service';

                      final date =
                          request['requestedDate']
                                  ?.toString() ??
                              '';

                      final time =
                          request['requestedTime']
                                  ?.toString() ??
                              '';

                      final address =
                          request['address']?.toString() ??
                              '';

                      final description =
                          request['description']
                                  ?.toString() ??
                              '';

                      final status =
                          request['status']?.toString() ??
                              'PENDING';

                      final requestId =
                          int.tryParse(
                        request['id'].toString(),
                      );

                      final displayStatus =
                          status.isNotEmpty
                              ? status[0].toUpperCase() +
                                  status
                                      .substring(1)
                                      .toLowerCase()
                              : 'Pending';

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(22),
                          border:
                              Border.all(color: _kBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // ==================== Customer Header ====================

                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration:
                                        const BoxDecoration(
                                      color: _kYellow,
                                      shape:
                                          BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons
                                          .person_rounded,
                                      color: _kBlack,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Expanded(
                                    child: Text(
                                      customerName,
                                      maxLines: 1,
                                      overflow: TextOverflow
                                          .ellipsis,
                                      style:
                                          const TextStyle(
                                        fontSize: 17,
                                        fontWeight:
                                            FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: _kBlack,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusChip(
                                    status: status,
                                    label: displayStatus,
                                  ),
                                ],
                              ),

                              const Divider(
                                height: 28,
                                color: Color(0xFFEFEFEA),
                              ),

                              // ==================== Service ====================

                              Container(
                                padding: const EdgeInsets
                                    .symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _kBlack,
                                  borderRadius:
                                      BorderRadius.circular(
                                    10,
                                  ),
                                ),
                                child: Text(
                                  serviceName,
                                  style:
                                      const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: _kYellow,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              // ==================== Date ====================

                              _iconRow(
                                Icons
                                    .calendar_today_rounded,
                                formatDate(date),
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              // ==================== Time ====================

                              _iconRow(
                                Icons
                                    .access_time_rounded,
                                formatTime(time),
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              // ==================== Address ====================

                              _iconRow(
                                Icons
                                    .location_on_rounded,
                                address,
                              ),

                              // ==================== Description ====================

                              if (description
                                  .isNotEmpty) ...[
                                const SizedBox(
                                  height: 14,
                                ),
                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.all(
                                    12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF6F6F2,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  child: Text(
                                    description,
                                    style:
                                        const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color:
                                          _kTextSecondary,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(
                                height: 18,
                              ),

                              // ==================== Chat Customer ====================

                              if (customerEmail
                                  .isNotEmpty)
                                SizedBox(
                                  width:
                                      double.infinity,
                                  height: 48,
                                  child:
                                      OutlinedButton
                                          .icon(
                                    style: OutlinedButton
                                        .styleFrom(
                                      foregroundColor:
                                          _kBlack,
                                      side:
                                          const BorderSide(
                                        color: _kBlack,
                                        width: 1.3,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          14,
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  ChatScreen(
                                            otherUserEmail:
                                                customerEmail,
                                            otherUserName:
                                                customerName,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons
                                          .chat_bubble_outline_rounded,
                                      size: 19,
                                    ),
                                    label:
                                        const Text(
                                      'Chat with Customer',
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                                    ),
                                  ),
                                ),

                              // ==================== Pending Actions ====================

                              if (status == 'PENDING') ...[
                                const SizedBox(
                                  height: 12,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child:
                                          OutlinedButton
                                              .icon(
                                        onPressed:
                                            requestId ==
                                                    null
                                                ? null
                                                : () {
                                                    updateStatus(
                                                      requestId,
                                                      'REJECTED',
                                                    );
                                                  },
                                        icon:
                                            const Icon(
                                          Icons
                                              .close_rounded,
                                        ),
                                        label:
                                            const Text(
                                          'Reject',
                                        ),
                                        style:
                                            OutlinedButton
                                                .styleFrom(
                                          foregroundColor:
                                              _kDanger,
                                          side:
                                              const BorderSide(
                                            color:
                                                _kDanger,
                                            width: 1.3,
                                          ),
                                          minimumSize:
                                              const Size
                                                  .fromHeight(
                                            48,
                                          ),
                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              14,
                                            ),
                                          ),
                                          textStyle:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Expanded(
                                      child:
                                          ElevatedButton
                                              .icon(
                                        onPressed:
                                            requestId ==
                                                    null
                                                ? null
                                                : () {
                                                    updateStatus(
                                                      requestId,
                                                      'ACCEPTED',
                                                    );
                                                  },
                                        icon:
                                            const Icon(
                                          Icons
                                              .check_rounded,
                                        ),
                                        label:
                                            const Text(
                                          'Accept',
                                        ),
                                        style:
                                            ElevatedButton
                                                .styleFrom(
                                          backgroundColor:
                                              _kYellow,
                                          foregroundColor:
                                              _kBlack,
                                          elevation: 0,
                                          shadowColor:
                                              Colors
                                                  .transparent,
                                          minimumSize:
                                              const Size
                                                  .fromHeight(
                                            48,
                                          ),
                                          shape:
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              14,
                                            ),
                                          ),
                                          textStyle:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              // ==================== Accepted ====================

                              if (status == 'ACCEPTED') ...[
                                const SizedBox(
                                  height: 12,
                                ),
                                SizedBox(
                                  width:
                                      double.infinity,
                                  height: 48,
                                  child:
                                      ElevatedButton
                                          .icon(
                                    onPressed:
                                        requestId ==
                                                null
                                            ? null
                                            : () {
                                                updateStatus(
                                                  requestId,
                                                  'COMPLETED',
                                                );
                                              },
                                    icon: const Icon(
                                      Icons
                                          .check_circle_outline_rounded,
                                      size: 19,
                                    ),
                                    label: const Text(
                                      'Mark as Completed',
                                      style:
                                          TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                      ),
                                    ),
                                    style:
                                        ElevatedButton
                                            .styleFrom(
                                      backgroundColor:
                                          _kYellow,
                                      foregroundColor:
                                          _kBlack,
                                      elevation: 0,
                                      shadowColor:
                                          Colors
                                              .transparent,
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  // ==================== Empty State ====================

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EmptyRequestsIcon(),
          SizedBox(height: 16),
          Text(
            'No service requests available.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Icon Row ====================

  Widget _iconRow(
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
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
        const SizedBox(
          width: 10,
        ),
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

// ==================== Status Chip ====================

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
        background = _kBlack;
        foreground = _kYellow;
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

class _EmptyRequestsIcon extends StatelessWidget {
  const _EmptyRequestsIcon();

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
        Icons.assignment_rounded,
        size: 38,
        color: _kBlack,
      ),
    );
  }
}