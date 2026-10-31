import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../main.dart' show handleNotificationNavigation;

// Yellow & black palette (local to this screen)
const Color _kYellow = Color(0xFFFFC400);
const Color _kYellowSoft = Color(0xFFFFF7D6);
const Color _kBlack = Color(0xFF0D0D0D);
const Color _kBackground = Color(0xFFF6F6F2);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kBorder = Color(0xFFE4E4DE);
const Color _kDanger = Color(0xFFD92D20);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? errorMessage;

  int get unreadCount =>
      notifications.where((item) => !_isRead(item)).length;

  bool _isRead(Map<String, dynamic> item) {
    final value = item['isRead'] ?? item['is_read'] ?? item['read'];

    if (value == true || value == 1) return true;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _text(dynamic value, [String fallback = '']) {
    return value?.toString() ?? fallback;
  }

  DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final dynamic response = await ApiService.getNotifications();
      final List<Map<String, dynamic>> result = [];

      dynamic data = response;

      if (response is Map) {
        data = response['data'] ?? response['notifications'] ?? [];
      }

      if (data is List) {
        for (final dynamic item in data) {
          if (item is Map) {
            result.add(Map<String, dynamic>.from(item));
          }
        }
      }

      result.sort((a, b) {
        final dateA = _date(a['createdAt'] ?? a['created_at']);
        final dateB = _date(b['createdAt'] ?? b['created_at']);

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      if (!mounted) return;

      setState(() {
        notifications = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> markAsRead(
    Map<String, dynamic> notification,
  ) async {
    if (_isRead(notification)) return;

    final dynamic rawId =
        notification['id'] ?? notification['notificationId'];
    final int? id = _toInt(rawId);

    if (id == null) {
      _showMessage('There are no unread notifications.');
      return;
    }

    try {
      await ApiService.markNotificationAsRead(id);

      if (!mounted) return;

      setState(() {
        final index = notifications.indexWhere(
          (item) => _toInt(
                item['id'] ?? item['notificationId'],
              ) ==
              id,
        );

        if (index != -1) {
          notifications[index]['isRead'] = true;
          notifications[index]['is_read'] = true;
          notifications[index]['read'] = true;
        }
      });
    } catch (e) {
      if (mounted) {
        _showMessage('Notification eka read karanna bari una.');
      }
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    if (unreadCount == 0) {
      _showMessage('There are no unread notifications.');
      return;
    }

    try {
      await ApiService.markAllNotificationsAsRead();

      if (!mounted) return;

      setState(() {
        for (final item in notifications) {
          item['isRead'] = true;
          item['is_read'] = true;
          item['read'] = true;
        }
      });

      _showMessage('All notifications marked as read.');
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to update notifications.');
      }
    }
  }

  Future<void> deleteNotification(
    Map<String, dynamic> notification,
  ) async {
    final int? id = _toInt(
      notification['id'] ?? notification['notificationId'],
    );

    if (id == null) {
      _showMessage('Notification ID eka invalid.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Delete notification?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _kBlack,
          ),
        ),
        content: const Text(
         'Are you sure you want to delete this notification?',
          style: TextStyle(color: _kTextSecondary),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _kBlack,
            ),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _kDanger,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteNotification(id);

      if (!mounted) return;

      setState(() {
        notifications.removeWhere(
          (item) =>
              _toInt(item['id'] ?? item['notificationId']) == id,
        );
      });

      _showMessage('Notification deleted successfully!');
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to delete notification.');
      }
    }
  }

  Future<void> clearAllNotifications() async {
    if (notifications.isEmpty) {
      _showMessage('No notifications to clear.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Clear all notifications?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _kBlack,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete all notifications?',
          style: TextStyle(color: _kTextSecondary),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _kBlack,
            ),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _kDanger,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.clearAllNotifications();

      if (!mounted) return;

      setState(() {
        notifications.clear();
      });

      _showMessage('All notifications cleared successfully!');
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to clear notifications.');
      }
    }
  }

  Future<void> handleNotificationTap(
    Map<String, dynamic> notification,
  ) async {
    // Mark notification as read first.
    await markAsRead(notification);

    if (!mounted) return;

    // Navigate according to notification type.
    handleNotificationNavigation(notification);
  }

  String _formatDate(dynamic value) {
    final date = _date(value);
    if (date == null) return '';

    final local = date.toLocal();
    final difference = DateTime.now().difference(local);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${local.day}/${local.month}/${local.year}';
  }

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'NEW_SERVICE_REQUEST':
        return Icons.assignment_outlined;
      case 'BOOKING_CONFIRMED':
        return Icons.check_circle_outline;
      case 'BOOKING_CANCELLED':
        return Icons.cancel_outlined;
      case 'PAYMENT_SUCCESS':
        return Icons.payments_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'mark_all') {
                markAllNotificationsAsRead();
              } else if (value == 'clear_all') {
                clearAllNotifications();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'mark_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: _kBlack),
                    SizedBox(width: 10),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, color: _kBlack),
                    SizedBox(width: 10),
                    Text('Clear all notifications'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _kBlack),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: _kDanger.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: _kDanger,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load notifications.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kBlack,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kYellow,
                  foregroundColor: _kBlack,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: loadNotifications,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return RefreshIndicator(
        color: _kBlack,
        backgroundColor: _kYellow,
        onRefresh: loadNotifications,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 150),
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: _kYellow.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none,
                  size: 44,
                  color: _kBlack,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final hasHeader = unreadCount > 0;

    return RefreshIndicator(
      color: _kBlack,
      backgroundColor: _kYellow,
      onRefresh: loadNotifications,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length + (hasHeader ? 1 : 0),
        itemBuilder: (context, rawIndex) {
          // Unread summary pill
          if (hasHeader && rawIndex == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _kBlack,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _kYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$unreadCount unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final index = hasHeader ? rawIndex - 1 : rawIndex;
          final item = notifications[index];

          final title = _text(item['title'], 'Notification');
          final message = _text(item['message']);
          final type = _text(
            item['type'] ?? item['notificationType'],
          );
          final createdAt = item['createdAt'] ?? item['created_at'];
          final read = _isRead(item);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: read ? Colors.white : _kYellowSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: read ? _kBorder : _kYellow.withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => handleNotificationTap(item),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: read
                              ? const Color(0xFFF1F1EC)
                              : _kYellow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _iconForType(type),
                          size: 23,
                          color: _kBlack,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        letterSpacing: -0.2,
                                        color: _kBlack,
                                        fontWeight: read
                                            ? FontWeight.w600
                                            : FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (!read)
                                    Container(
                                      width: 9,
                                      height: 9,
                                      margin: const EdgeInsets.only(
                                        left: 6,
                                      ),
                                      decoration:
                                          const BoxDecoration(
                                        color: _kBlack,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                message,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.4,
                                  color: _kTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: _kTextSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: _kTextSecondary,
                          size: 22,
                        ),
                        onSelected: (value) {
                          if (value == 'delete') {
                            deleteNotification(item);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: _kDanger,
                                ),
                                SizedBox(width: 10),
                                Text('Delete notification'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}