import 'dart:async';
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // 🔥 NEEDED FOR THEME
import 'package:cublink/providers/theme_provider.dart'; // 🔥 NEEDED FOR THEME

// IMPORT YOUR NOTIFICATION SERVICE HERE
import 'package:cublink/services/notification_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  
  // Database References
  late DatabaseReference _locRef;
  late DatabaseReference _geoRef;
  late DatabaseReference _settingsRef;

  // Stream Subscriptions
  StreamSubscription? _locSub;
  StreamSubscription? _geoSub;
  StreamSubscription? _settingsSub;

  // Location Data
  LatLng _studentLocation = const LatLng(8.5502, 76.9393);
  String _currentAddress = "Locating address..."; 
  
  // Geofence Data
  bool _isGeofenceActive = false; 
  LatLng _safeZoneCenter = const LatLng(8.5502, 76.9393); 
  double _safeZoneRadius = 200.0; 
  bool _isInsideSafeZone = true;
  
  // Settings
  bool _alertGeofenceEnabled = true;
  bool _isBackgroundTrackingOn = false; 

  // Connection Status & Anti-Stale Logic
  bool _isOnline = false;
  bool _isSyncing = true; 
  int _dataCount = 0;     
  DateTime? _lastDataTime;
  Timer? _checkConnectionTimer;

  // ESP32 Status & Heartbeat Tracking
  String _deviceStatus = "Syncing...";
  int _lastHeartbeat = 0;

  // NOTIFICATION SPAM FLAGS
  bool _hasNotifiedOutside = false;
  bool _hasNotifiedInside = true; 
  bool _hasNotifiedOffline = false;

  // Colors
  final Color _safeColor = const Color(0xFF1A9E75); 
  final Color _dangerColor = const Color(0xFFE53935); 
  final Color _offlineColor = const Color(0xFF757575); 
  final Color _syncColor = Colors.orange; 
  final Color _warningColor = const Color(0xFFF57C00); 

  @override
  void initState() {
    super.initState();

    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://clublink-2bbc3-default-rtdb.asia-southeast1.firebasedatabase.app'
      );

      _locRef = db.ref('users/$uid/live_location');
      _geoRef = db.ref('users/$uid/active_geofence');
      _settingsRef = db.ref('users/$uid/settings');

      _startListening(); 
    }
    
    // THE DOCTOR: Checks the heartbeat every 5 seconds
    _checkConnectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_lastDataTime != null) {
        final timeDiff = DateTime.now().difference(_lastDataTime!).inSeconds;
        if (timeDiff > 20 && mounted) {
           setState(() {
              _isOnline = false;
              _isSyncing = false;
              _dataCount = 0;
           });

           if (!_hasNotifiedOffline && !_isBackgroundTrackingOn) {
             NotificationService.showNotification(
               id: 1, 
               title: "⚠️ Device Offline", 
               body: "The ID card has lost connection or battery."
             );
             _hasNotifiedOffline = true; 
           }
        }
      }
    });
  }

  @override
  void dispose() {
    _locSub?.cancel();
    _geoSub?.cancel();
    _settingsSub?.cancel();
    _checkConnectionTimer?.cancel();
    super.dispose();
  }

  void _startListening() {
    // --- 1. SETTINGS LISTENER ---
    _settingsSub = _settingsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && mounted) {
        setState(() {
          _alertGeofenceEnabled = data['geofence_alerts'] ?? true;
          _isBackgroundTrackingOn = data['background_tracking'] ?? false; 
        });
      }
    }, onError: (e) {
      debugPrint("Settings Stream Error (Ignored during logout): $e");
    });

    // --- 2. GEOFENCE LISTENER ---
    _geoSub = _geoRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && mounted) {
        setState(() {
          _isGeofenceActive = data['isActive'] ?? false;
          if (_isGeofenceActive) {
            _safeZoneCenter = LatLng(
              (data['lat'] as num).toDouble(), 
              (data['lng'] as num).toDouble()
            );
            _safeZoneRadius = (data['radius'] as num).toDouble();
          }
        });
      }
    }, onError: (e) {
      debugPrint("Geofence Stream Error (Ignored): $e");
    });

    // --- 3. LOCATION LISTENER ---
    _locSub = _locRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        double lat = (data['lat'] as num).toDouble();
        double lng = (data['lng'] as num).toDouble();
        
        String currentStatus = data['status']?.toString() ?? "Live Tracking";
        int currentHeartbeat = (data['heartbeat'] as num?)?.toInt() ?? 0;
        
        _updateAddress(lat, lng);

        if (mounted) {
          setState(() {
            _studentLocation = LatLng(lat, lng);
            _deviceStatus = currentStatus; 
            
            // HEARTBEAT CHECK
            if (currentHeartbeat != _lastHeartbeat || _lastHeartbeat == 0) {
              _lastDataTime = DateTime.now();
              _lastHeartbeat = currentHeartbeat;
            }
            
            _dataCount++; 
            if (_dataCount > 1) {
               _isOnline = true;
               _isSyncing = false;
            } else {
               _isSyncing = true;
               _isOnline = false;
            }
            
            // --- GEOFENCE CALCULATION & NOTIFICATION TRIGGER ---
            if (_isGeofenceActive) {
              final double distance = const Distance().as(
                LengthUnit.Meter, _safeZoneCenter, _studentLocation
              );
              _isInsideSafeZone = distance <= _safeZoneRadius;

              if (!_isInsideSafeZone && !_hasNotifiedOutside && _alertGeofenceEnabled) {
                if (!_isBackgroundTrackingOn) { 
                  NotificationService.showNotification(
                    id: 2, 
                    title: "🚨 OUTSIDE SAFE ZONE", 
                    body: "The student has left the designated Geofence!"
                  );
                }
                _hasNotifiedOutside = true; 
                _hasNotifiedInside = false;  
              } 
              else if (_isInsideSafeZone && !_hasNotifiedInside && _alertGeofenceEnabled) {
                if (!_isBackgroundTrackingOn) { 
                  NotificationService.showNotification(
                    id: 3, 
                    title: "✅ SAFE ZONE ENTERED", 
                    body: "The student has safely returned to the Geofence."
                  );
                }
                _hasNotifiedInside = true;   
                _hasNotifiedOutside = false; 
              }
            } else {
              _isInsideSafeZone = true; 
            }
            
            _hasNotifiedOffline = false; 
          });
        }
      }
    }, onError: (e) {
      debugPrint("Location Stream Error (Ignored): $e");
    });
  }

  Future<void> _updateAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String newAddress = "${place.street}, ${place.locality}"; 
        if (mounted && _currentAddress != newAddress) {
          setState(() => _currentAddress = newAddress);
        }
      }
    } catch (e) { /* Ignore */ }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 GRAB THE THEME
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    // --- STATUS PRIORITY LOGIC ---
    String statusTitle;
    IconData currentIcon;
    Color currentColor;

    bool isOutside = _isGeofenceActive && !_isInsideSafeZone;

    if (_isSyncing) {
      statusTitle = "Connecting to Device...";
      currentIcon = Icons.wifi_find_rounded;
      currentColor = _syncColor; 
    }
    else if (!_isOnline) {
      statusTitle = "Device Offline";
      currentIcon = Icons.wifi_off_rounded;
      currentColor = _offlineColor;
    } 
    else if (_deviceStatus.contains("Syncing GPS")) {
      statusTitle = "Syncing GPS (Looking for Sky)";
      currentIcon = Icons.satellite_alt_rounded;
      currentColor = _syncColor;
    }
    else if (_deviceStatus.contains("Indoors")) {
      if (isOutside) {
        statusTitle = "Signal Lost (Outside Zone!)";
        currentIcon = Icons.warning_rounded;
        currentColor = _dangerColor; 
      } else {
        statusTitle = "Signal Lost (Indoors)";
        currentIcon = Icons.domain_disabled_rounded;
        currentColor = _warningColor; 
      }
    }
    else if (isOutside) {
      statusTitle = "Outside Safe Zone";
      currentIcon = Icons.gpp_bad_rounded;
      currentColor = _dangerColor;
    }
    else if (_isGeofenceActive) {
      statusTitle = "Safe & Connected";
      currentIcon = Icons.verified_user_rounded;
      currentColor = _safeColor;
    } 
    else {
      statusTitle = "Live Location Active";
      currentIcon = Icons.location_on_rounded;
      currentColor = _safeColor;
    }

    double bottomPadding = MediaQuery.of(context).size.height * 0.13; 

    return Scaffold(
      body: Stack(
        children: [
          // MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _safeZoneCenter, 
              initialZoom: 17, 
              minZoom: 10,
              maxZoom: 20,
            ),
            children: [
              TileLayer(
                // 🔥 DYNAMIC MAP TILES
                urlTemplate: isDark 
                    ? 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png'
                    : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.cublink.app',
              ),
              if (_isGeofenceActive)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _safeZoneCenter,
                      color: _safeColor.withOpacity(0.1), 
                      borderColor: _safeColor,
                      borderStrokeWidth: 2,
                      useRadiusInMeter: true,
                      radius: _safeZoneRadius,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _studentLocation,
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: currentColor, 
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                            ],
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                        ),
                        ClipPath(
                          clipper: TriangleClipper(), 
                          child: Container(color: currentColor, width: 10, height: 8),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),

          // RECENTER BUTTON
          Positioned(
            right: 20,
            bottom: bottomPadding + 90, 
            child: FloatingActionButton(
              heroTag: "recenter",
              onPressed: () => _mapController.move(_studentLocation, 17.0),
              backgroundColor: Theme.of(context).colorScheme.surface, // 🔥 DYNAMIC
              child: Icon(Icons.my_location_rounded, color: textColor), // 🔥 DYNAMIC
            ),
          ),

          // INFO CARD
          Positioned(
            bottom: bottomPadding, 
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface, // 🔥 DYNAMIC
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  // Stronger shadow in dark mode for depth
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 50, width: 50,
                    decoration: BoxDecoration(
                      color: currentColor.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(15)
                    ),
                    child: Icon(currentIcon, color: currentColor, size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusTitle.toUpperCase(), 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: currentColor)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isOnline || _isSyncing 
                              ? _currentAddress 
                              : "Last active: ${_lastDataTime?.hour}:${_lastDataTime?.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600), // 🔥 DYNAMIC
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TriangleClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<ui.Path> oldClipper) => false;
}