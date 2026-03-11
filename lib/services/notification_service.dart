import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('app_logo'); 

    const InitializationSettings settings = 
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings: settings, // <--- Using your correct named parameter syntax
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint("Notification Clicked: ${response.payload}");
      },
    );
  }

  static Future<void> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // 1. Show the physical pop-up on the phone
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'safety_alerts',
      'Safety Alerts',
      channelDescription: 'Notifications for Geofence and Offline status',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF1A9E75),
      icon: 'app_logo', 
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    // --- FIX: Restored your named parameters here! ---
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details, 
    );

    // 🔥 2. AUTO-LOG TO FIREBASE HISTORY
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Figure out the icon color based on the ID we used!
      String type = 'warning'; 
      if (id == 2 || id == 900) type = 'danger'; // Outside Zone
      if (id == 3 || id == 901) type = 'success'; // Safe Zone
      
      try {
        await FirebaseDatabase.instance.ref('users/$uid/alert_history').push().set({
          'title': title,
          'message': body,
          'type': type,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        debugPrint("Failed to log history: $e");
      }
    }
  }
}