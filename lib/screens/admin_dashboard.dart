import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cublink/screens/login_screen.dart';
import 'package:cublink/widgets/background_wave_painter.dart'; 
import 'package:provider/provider.dart'; // 🔥 NEEDED FOR THEME
import 'package:cublink/providers/theme_provider.dart'; // 🔥 NEEDED FOR THEME

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Prototype Student UID
  final String targetStudentUID = "7FID9RVwbGah5K8SfZXl7tMqInl2";

  final MapController _mapController = MapController();
  late DatabaseReference _locRef;
  late DatabaseReference _infoRef;
  StreamSubscription? _locSub;

  LatLng _studentLocation = const LatLng(8.5502, 76.9393);
  String _deviceStatus = "Syncing...";
  String _currentAddress = "Locating..."; 
  String _studentName = "Loading Student..."; 
  
  int _lastHeartbeat = 0;
  bool _isOnline = false;
  bool _isSyncing = true;
  bool _isFirstLocationLoad = true; 
  DateTime? _lastDataTime;
  Timer? _checkConnectionTimer;

  final Color _safeColor = const Color(0xFF1A9E75);
  final Color _dangerColor = const Color(0xFFE53935);
  final Color _offlineColor = const Color(0xFF757575);
  final Color _syncColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://clublink-2bbc3-default-rtdb.asia-southeast1.firebasedatabase.app'
    );

    _locRef = db.ref('users/$targetStudentUID/live_location');
    _infoRef = db.ref('users/$targetStudentUID/student_info');

    _fetchStudentInfo();
    _startListening();

    _checkConnectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_lastDataTime != null) {
        final timeDiff = DateTime.now().difference(_lastDataTime!).inSeconds;
        if (timeDiff > 20 && mounted) {
          setState(() {
            _isOnline = false;
            _isSyncing = false;
          });
        }
      }
    });
  }

  Future<void> _fetchStudentInfo() async {
    try {
      final snapshot = await _infoRef.child('name').get();
      if (snapshot.exists && mounted) {
        setState(() {
          _studentName = snapshot.value.toString();
        });
      } else {
         setState(() {
          _studentName = "Unknown Student";
        });
      }
    } catch (e) {
      debugPrint("Error fetching name: $e");
    }
  }

  void _startListening() {
    _locSub = _locRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && mounted) {
        double lat = (data['lat'] as num?)?.toDouble() ?? 8.5502;
        double lng = (data['lng'] as num?)?.toDouble() ?? 76.9393;
        String currentStatus = data['status']?.toString() ?? "Live Tracking";
        int currentHeartbeat = (data['heartbeat'] as num?)?.toInt() ?? 0;

        _updateAddress(lat, lng); 

        setState(() {
          _studentLocation = LatLng(lat, lng);
          _deviceStatus = currentStatus;

          if (currentHeartbeat != _lastHeartbeat || _lastHeartbeat == 0) {
            _lastDataTime = DateTime.now();
            _lastHeartbeat = currentHeartbeat;
            _isOnline = true;
            _isSyncing = false;
          }
          
          if (_isFirstLocationLoad) {
             _mapController.move(_studentLocation, 16.0);
             _isFirstLocationLoad = false;
          }
        });
      }
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
  void dispose() {
    _locSub?.cancel();
    _checkConnectionTimer?.cancel();
    super.dispose();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface, // DYNAMIC THEME
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Confirm Logout', 
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)
          ),
          content: Text(
            'Are you sure you want to securely log out of the Admin Control Center?',
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 15),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(context).pop(); 
                _logout(); 
              },
              child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    // 🔥 GRAB THE THEME
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    // Admin Status Logic
    String statusTitle;
    Color currentColor;
    IconData currentIcon;

    if (_isSyncing) {
      statusTitle = "Syncing...";
      currentColor = _syncColor;
      currentIcon = Icons.wifi_find_rounded;
    } else if (!_isOnline) {
      statusTitle = "Offline";
      currentColor = _offlineColor;
      currentIcon = Icons.wifi_off_rounded;
    } else if (_deviceStatus.contains("Indoors") || _deviceStatus.contains("Syncing GPS")) {
      statusTitle = "Warning / Indoors";
      currentColor = _syncColor;
      currentIcon = Icons.warning_rounded;
    } else {
      statusTitle = "Active & Live";
      currentColor = _safeColor;
      currentIcon = Icons.check_circle_rounded;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. DYNAMIC GRADIENT BACKGROUND
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                  ? [const Color(0xFF121A18), const Color(0xFF1E2D2A)] 
                  : [const Color(0xFFD7FBEA), const Color(0xFFE0F2F1)],
              ),
            ),
          ),
          
          // 2. DYNAMIC WAVE PAINTER
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundWavePainter(
                waveColor: isDark 
                  ? Colors.white.withOpacity(0.03) 
                  : Colors.white.withOpacity(0.5),
              ),
            ),
          ),

          // 3. MAIN CONTENT
          SafeArea(
            child: Column(
              children: [
                // --- CUSTOM HEADER WITH LOGOUT BUTTON ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Control Center',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary, // DYNAMIC
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showLogoutDialog, 
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surface, // DYNAMIC
                          foregroundColor: const Color(0xFFE53935), 
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(isDark ? 0.4 : 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
                        ),
                      )
                    ],
                  ),
                ),

                // --- SCROLLABLE DASHBOARD ---
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SYSTEM HEALTH", 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2)
                        ),
                        const SizedBox(height: 15),
                        
                        // STATS ROW
                        Row(
                          children: [
                            Expanded(child: _buildStatCard(context, "Total Devices", "1", Colors.blue, isDark)),
                            const SizedBox(width: 15),
                            Expanded(child: _buildStatCard(context, "Active Now", _isOnline ? "1" : "0", _safeColor, isDark)),
                          ],
                        ),
                        const SizedBox(height: 35),

                        Text(
                          "LIVE FLEET MAP", 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2)
                        ),
                        const SizedBox(height: 15),

                        // MINI MAP CARD WITH STACK
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface, 
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _studentLocation,
                                    initialZoom: 16,
                                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                                  ),
                                  children: [
                                    TileLayer(
                                      // 🔥 MAGIC THEME MAP TILES!
                                      urlTemplate: isDark 
                                          ? 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png'
                                          : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                                      subdomains: const ['a', 'b', 'c', 'd'],
                                      userAgentPackageName: 'com.cublink.app',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: _studentLocation,
                                          width: 40, height: 40,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: currentColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 3))],
                                            ),
                                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: 10, bottom: 10,
                                  child: FloatingActionButton(
                                    mini: true,
                                    heroTag: "adminRecenter",
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    onPressed: () => _mapController.move(_studentLocation, 16.0),
                                    child: Icon(Icons.my_location, color: textColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 35),

                        Text(
                          "DEVICE ROSTER", 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2)
                        ),
                        const SizedBox(height: 15),

                        // DEVICE DETAILS CARD
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface, 
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 50, width: 50,
                                decoration: BoxDecoration(color: currentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                                child: Icon(currentIcon, color: currentColor, size: 28),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Student: $_studentName", 
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)
                                    ),
                                    const SizedBox(height: 4),
                                    Text(statusTitle, style: TextStyle(color: currentColor, fontWeight: FontWeight.w900, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isOnline || _isSyncing ? _currentAddress : "Last seen: ${_lastDataTime?.hour}:${_lastDataTime?.minute.toString().padLeft(2, '0')}", 
                                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 40), 
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for the top stats (Updated to pass context and isDark)
  Widget _buildStatCard(BuildContext context, String title, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // DYNAMIC
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 32)),
        ],
      ),
    );
  }
}