
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'screens/welcome_screen.dart';
import 'screens/customer/customer_bookings_screen.dart';
import 'screens/provider/provider_requests_screen.dart';
import 'screens/customer/chat_screen.dart';

import 'utils/app_colors.dart';
import 'utils/session.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

Map<String, dynamic>? _pendingNotificationData;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();

  debugPrint('========== BACKGROUND FCM ==========');
  debugPrint('TITLE: ${message.notification?.title}');
  debugPrint('BODY: ${message.notification?.body}');
  debugPrint('DATA: ${message.data}');
  debugPrint('====================================');
}

Map<String, dynamic> _notificationDataFromRemote(
  RemoteMessage message,
) {
  final data = Map<String, dynamic>.from(message.data);

  data['title'] ??= message.notification?.title ?? 'SkillLink';
  data['message'] ??= message.notification?.body ?? '';

  return data;
}

void handleNotificationNavigation(
  Map<String, dynamic> data,
) {
  final navigator = navigatorKey.currentState;

  if (navigator == null) {
    _pendingNotificationData = data;
    return;
  }

  final type = (data['type'] ??
          data['notificationType'] ??
          data['notification_type'] ??
          '')
      .toString()
      .toUpperCase();

  final title = (data['title'] ?? '')
      .toString()
      .trim()
      .toUpperCase();

  final isChatNotification =
      type == 'NEW_MESSAGE' ||
      type == 'MESSAGE' ||
      type == 'CHAT_MESSAGE' ||
      title == 'NEW MESSAGE';

  debugPrint('========== NOTIFICATION NAVIGATION ==========');
  debugPrint('TYPE: $type');
  debugPrint('TITLE: $title');
  debugPrint('ACTIVE ROLE: ${Session.activeRole}');
  debugPrint('DATA: $data');
  debugPrint('==============================================');

  // Chat notification navigation
  if (isChatNotification) {
    final otherUserEmail = (data['senderEmail'] ??
            data['sender_email'] ??
            data['otherUserEmail'] ??
            data['other_user_email'] ??
            data['email'] ??
            '')
        .toString()
        .trim();

    final otherUserName = (data['senderName'] ??
            data['sender_name'] ??
            data['otherUserName'] ??
            data['other_user_name'] ??
            data['name'] ??
            'User')
        .toString()
        .trim();

    if (otherUserEmail.isEmpty) {
      debugPrint(
        'Cannot open chat: sender email is missing from notification data.',
      );
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserEmail: otherUserEmail,
          otherUserName:
              otherUserName.isEmpty ? 'User' : otherUserName,
        ),
      ),
    );
    return;
  }

  switch (type) {
    case 'NEW_SERVICE_REQUEST':
      if (Session.activeRole == 'PROVIDER') {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => const ProviderRequestsScreen(),
          ),
        );
      } else {
        debugPrint(
          'Cannot open provider requests. Active role: ${Session.activeRole}',
        );
      }
      break;

    case 'TIME_DECLINED':
    case 'APPOINTMENT_CONFIRMED':
    case 'BOOKING_CONFIRMED':
    case 'BOOKING_CANCELLED':
    case 'BOOKING_REJECTED':
    case 'APPOINTMENT_REJECTED':
    case 'RESCHEDULE_PROPOSED':
    case 'TIME_PROPOSED':
    case 'CUSTOMER_TIME_ACCEPTED':
    case 'REQUEST_ACCEPTED':
    case 'SERVICE_STARTED':
    case 'SERVICE_COMPLETED':
    case 'REQUEST_REJECTED':

      if (Session.activeRole == 'CUSTOMER') {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => const CustomerBookingsScreen(),
          ),
        );
      } else if (Session.activeRole == 'PROVIDER') {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => const ProviderRequestsScreen(),
          ),
        );
      } else {
        debugPrint(
          'Cannot navigate. Unknown active role: ${Session.activeRole}',
        );
      }
      break;

    default:
      debugPrint('Unknown notification type: $type');
      break;
  }
}

void _processPendingNotification() {
  final data = _pendingNotificationData;

  if (data == null || navigatorKey.currentState == null) {
    return;
  }

  _pendingNotificationData = null;
  handleNotificationNavigation(data);
}

@pragma('vm:entry-point')
void notificationTapBackground(
  NotificationResponse response,
) {
  debugPrint('Background local notification tapped.');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (response) {
      debugPrint('Local notification tapped.');
      debugPrint('PAYLOAD: ${response.payload}');

      final payload = response.payload;

      if (payload == null || payload.isEmpty) return;

      try {
        final decoded = jsonDecode(payload);

        if (decoded is Map) {
          handleNotificationNavigation(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (e) {
        debugPrint('Notification payload error: $e');
      }
    },
    onDidReceiveBackgroundNotificationResponse:
        notificationTapBackground,
  );

  const AndroidNotificationChannel channel =
      AndroidNotificationChannel(
    'skilllink_notifications',
    'SkillLink Notifications',
    description: 'Notifications from SkillLink',
    importance: Importance.high,
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final String? fcmToken =
      await FirebaseMessaging.instance.getToken();

  debugPrint('========== DEVICE FCM DEBUG ==========');
  debugPrint(
    'INITIAL TOKEN EXISTS: ${fcmToken != null && fcmToken.isNotEmpty}',
  );

  if (fcmToken != null && fcmToken.isNotEmpty) {
    debugPrint('TOKEN LENGTH: ${fcmToken.length}');
    debugPrint(
      'TOKEN FINGERPRINT: ${fcmToken.hashCode.toRadixString(16)}',
    );
  }

  debugPrint('======================================');

  // Foreground FCM notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint('========== FOREGROUND FCM ==========');
    debugPrint('CURRENT SESSION EMAIL: ${Session.email}');
    debugPrint('TITLE: ${message.notification?.title}');
    debugPrint('BODY: ${message.notification?.body}');
    debugPrint('DATA: ${message.data}');
    debugPrint('====================================');

    final notificationData =
        _notificationDataFromRemote(message);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'skilllink_notifications',
      'SkillLink Notifications',
      channelDescription: 'Notifications from SkillLink',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      id: message.messageId?.hashCode ?? message.hashCode,
      title: message.notification?.title ?? 'SkillLink',
      body: message.notification?.body ??
          'You have a new notification',
      notificationDetails: notificationDetails,
      payload: jsonEncode(notificationData),
    );
  });

  // FCM notification tapped while app is in background
  FirebaseMessaging.onMessageOpenedApp.listen(
    (RemoteMessage message) {
      debugPrint('========== FCM OPENED ==========');
      debugPrint('CURRENT SESSION EMAIL: ${Session.email}');
      debugPrint('DATA: ${message.data}');
      debugPrint('================================');

      handleNotificationNavigation(
        _notificationDataFromRemote(message),
      );
    },
  );

  // FCM notification tapped while app was terminated
  final RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    debugPrint('APP OPENED FROM FCM NOTIFICATION');

    _pendingNotificationData =
        _notificationDataFromRemote(initialMessage);
  }

  runApp(const SkillLinkApp());
}

class SkillLinkApp extends StatelessWidget {
  const SkillLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SkillLink',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const WelcomeScreen(),
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _processPendingNotification();
        });

        return child ?? const SizedBox.shrink();
      },
    );
  }
}
