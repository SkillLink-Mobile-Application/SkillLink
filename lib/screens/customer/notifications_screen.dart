
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../provider/provider_requests_screen.dart';

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
      _showMessage('Notification ID eka invalid.');
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

      _showMessage('Notifications okkoma read kala.');
    } catch (e) {
      if (mounted) {
        _showMessage('Notifications update karanna bari una.');
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
        title: const Text('Delete notification?'),
        content: const Text(
         'Are you sure you want to delete this notification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
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
      _showMessage('Notifications naha.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'Are you sure you want to delete all notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
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
    final String type = _text(
      notification['type'] ?? notification['notificationType'],
    ).toUpperCase();

    await markAsRead(notification);

    if (!mounted) return;

    if (type == 'NEW_SERVICE_REQUEST') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const ProviderRequestsScreen(),
        ),
      );
    } else {
      final message = _text(
        notification['message'] ?? notification['title'],
        'Notification',
      );
      _showMessage(message);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
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
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined),
                    SizedBox(width: 8),
                    Text('Clear all notifications'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text('Notifications load karanna bari una.'),
              const SizedBox(height: 12),
              ElevatedButton(
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
        onRefresh: loadNotifications,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 150),
            Icon(
              Icons.notifications_none,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Center(child: Text('No notifications yet')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadNotifications,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];

          final title = _text(item['title'], 'Notification');
          final message = _text(item['message']);
          final type = _text(
            item['type'] ?? item['notificationType'],
          );
          final createdAt = item['createdAt'] ?? item['created_at'];
          final read = _isRead(item);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: read
                ? Theme.of(context).cardColor
                : Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                child: Icon(_iconForType(type)),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight:
                      read ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!read)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  PopupMenuButton<String>(
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
                            Icon(Icons.delete_outline),
                            SizedBox(width: 8),
                            Text('Delete notification'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () => handleNotificationTap(item),
            ),
          );
        },
      ),
    );
  }
}
