import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'screens/welcome_screen.dart';
import 'utils/app_colors.dart';
import 'utils/session.dart';

final FlutterLocalNotificationsPlugin
    flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint('========== BACKGROUND FCM ==========');
  debugPrint('MESSAGE ID: ${message.messageId}');
  debugPrint('TITLE: ${message.notification?.title}');
  debugPrint('BODY: ${message.notification?.body}');
  debugPrint('====================================');
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
  debugPrint('INITIAL TOKEN EXISTS: '
      '${fcmToken != null && fcmToken.isNotEmpty}');

  if (fcmToken != null && fcmToken.isNotEmpty) {
    debugPrint('TOKEN LENGTH: ${fcmToken.length}');
    debugPrint(
      'TOKEN FINGERPRINT: '
      '${fcmToken.hashCode.toRadixString(16)}',
    );
  }

  debugPrint('======================================');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint('========== FOREGROUND FCM ==========');
    debugPrint('CURRENT SESSION EMAIL: ${Session.email}');
    debugPrint('MESSAGE ID: ${message.messageId}');
    debugPrint('TITLE: ${message.notification?.title}');
    debugPrint('BODY: ${message.notification?.body}');
    debugPrint('====================================');

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
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('========== FCM OPENED ==========');
    debugPrint('CURRENT SESSION EMAIL: ${Session.email}');
    debugPrint('TITLE: ${message.notification?.title}');
    debugPrint('BODY: ${message.notification?.body}');
    debugPrint('================================');
  });

  final RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    debugPrint('APP OPENED FROM FCM NOTIFICATION');
    debugPrint('TITLE: ${initialMessage.notification?.title}');
    debugPrint('BODY: ${initialMessage.notification?.body}');
  }

  runApp(const SkillLinkApp());
}

class SkillLinkApp extends StatelessWidget {
  const SkillLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}