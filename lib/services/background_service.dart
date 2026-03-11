import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'package:cublink/services/notification_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart, 
      autoStart: false, // Prevents battery drain until parent turns it on
      isForegroundMode: true,
      notificationChannelId: 'safety_alerts',
      initialNotificationTitle: 'Cublink Security Active',
      initialNotificationContent: 'Monitoring Geofence in background...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  await Firebase.initializeApp();
  await NotificationService.init();

  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    service.stopSelf();
    return;
  }

  DatabaseReference locRef = FirebaseDatabase.instance.ref('users/$uid/live_location');
  DatabaseReference geoRef = FirebaseDatabase.instance.ref('users/$uid/active_geofence');
  DatabaseReference settingsRef = FirebaseDatabase.instance.ref('users/$uid/settings'); // 🔥 Added settings ref!

  LatLng safeZoneCenter = const LatLng(8.5502, 76.9393);
  double safeZoneRadius = 200.0;
  bool isGeofenceActive = false;
  
  // Settings Flags
  bool alertGeofenceEnabled = true;
  bool alertOfflineEnabled = true;

  // Spam Prevention Flags
  bool hasNotifiedOutside = false;
  bool hasNotifiedInside = true;
  bool hasNotifiedOffline = false;

  // Offline Tracking Variables
  DateTime? lastDataTime;
  Timer? checkConnectionTimer;

  // 1. Listen for Settings Changes
  settingsRef.onValue.listen((event) {
    final data = event.snapshot.value as Map?;
    if (data != null) {
      alertGeofenceEnabled = data['geofence_alerts'] ?? true;
      alertOfflineEnabled = data['offline_alerts'] ?? true;
    }
  });

  // 2. Listen for Geofence Changes
  geoRef.onValue.listen((event) {
    final data = event.snapshot.value as Map?;
    if (data != null) {
      isGeofenceActive = data['isActive'] ?? false;
      if (isGeofenceActive) {
        safeZoneCenter = LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble());
        safeZoneRadius = (data['radius'] as num).toDouble();
      }
    }
  });

  // 3. Listen for Location Changes & Do Math
  locRef.onValue.listen((event) {
    final data = event.snapshot.value as Map?;
    if (data != null) {
      // Record heartbeat for offline tracking
      lastDataTime = DateTime.now();
      hasNotifiedOffline = false; // Reset offline spam flag

      if (isGeofenceActive) {
        double lat = (data['lat'] as num).toDouble();
        double lng = (data['lng'] as num).toDouble();
        LatLng studentLocation = LatLng(lat, lng);

        final double distance = const Distance().as(LengthUnit.Meter, safeZoneCenter, studentLocation);
        bool isInsideSafeZone = distance <= safeZoneRadius;

        // 🔥 Added alertGeofenceEnabled check!
        if (!isInsideSafeZone && !hasNotifiedOutside && alertGeofenceEnabled) {
          NotificationService.showNotification(
            id: 900, title: "🚨 URGENT: OUTSIDE SAFE ZONE", body: "The student has left the designated Geofence!"
          );
          hasNotifiedOutside = true;
          hasNotifiedInside = false;
        } else if (isInsideSafeZone && !hasNotifiedInside && alertGeofenceEnabled) {
          NotificationService.showNotification(
            id: 901, title: "✅ SAFE ZONE ENTERED", body: "The student has safely returned to the Geofence."
          );
          hasNotifiedInside = true;
          hasNotifiedOutside = false;
        }
      }
    }
  });

  // 4. The Doctor Timer (Checks for Offline Status)
  checkConnectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
    if (lastDataTime != null) {
      final timeDiff = DateTime.now().difference(lastDataTime!).inSeconds;
      
      // If 20 seconds pass without a heartbeat
      if (timeDiff > 20) {
         if (!hasNotifiedOffline && alertOfflineEnabled) { // 🔥 Added alertOfflineEnabled check!
           NotificationService.showNotification(
             id: 902, 
             title: "⚠️ URGENT: Device Offline", 
             body: "The ID card has lost connection or battery."
           );
           hasNotifiedOffline = true; 
         }
      }
    }
  });

  // Listen for Stop Command
  service.on('stopService').listen((event) {
    checkConnectionTimer?.cancel(); // Kill the timer to prevent memory leaks
    service.stopSelf();
  });
}