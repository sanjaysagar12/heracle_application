import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  await NotificationService.saveNotification(
    title: message.notification?.title ?? "New Notification",
    body: message.notification?.body ?? "",
    payload: message.data['route'],
    time: DateTime.now(),
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    // 2. Initialize Firebase Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM Token
    try {
        final fcmToken = await messaging.getToken();
        print('FCM Token: $fcmToken');
    } catch (e) {
        print("Error getting FCM token: $e");
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        // Save notification to local storage
        await saveNotification(
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          payload: message.data['route'], 
          time: DateTime.now(),
        );

        showNotification(
          id: message.notification.hashCode,
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          payload: message.data['route'], 
        );
      }
    });
    
    // Check initial unread status
    await checkUnreadStatus();
  }

  ValueNotifier<bool> hasUnreadNotifications = ValueNotifier(false);

  Future<void> checkUnreadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // Simple check: do we have any unread flag?
    // Or we can just use a boolean flag in prefs 'has_unread_notifications'
    // Let's use a simpler boolean flag for badge
    final hasUnread = prefs.getBool('has_unread_notifications') ?? false;
    hasUnreadNotifications.value = hasUnread;
  }

  Future<void> markAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_unread_notifications', false);
    hasUnreadNotifications.value = false;
  }

  static Future<void> saveNotification({
    required String title,
    required String body,
    String? payload,
    required DateTime time,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> notifications = prefs.getStringList('notifications') ?? [];
      
      final newNotification = {
        'title': title,
        'body': body,
        'payload': payload,
        'time': time.toIso8601String(),
        'isRead': false,
      };
      
      notifications.insert(0, jsonEncode(newNotification));
      // Limit to last 50 notifications
      if (notifications.length > 50) {
        notifications.removeRange(50, notifications.length);
      }
      
      await prefs.setStringList('notifications', notifications);
      await prefs.setBool('has_unread_notifications', true);
      
      // We can't access instance members from static method easily without instance
      // But we can check if instance is created
      // Or make this method non-static if possible, or static with instance access
      // Since _instance is static, we can try to access it if initialized? 
      // Actually _instance is available.
      _instance.hasUnreadNotifications.value = true;

    } catch (e) {
      print('Failed to save notification: $e');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'heracle_channel_id',
      'Heracle Notifications',
      channelDescription: 'Main channel for Heracle notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  
  Future<void> requestPermissions() async {
    print("Requesting permissions via Firebase Messaging...");
    await FirebaseMessaging.instance.requestPermission();
  }
}
