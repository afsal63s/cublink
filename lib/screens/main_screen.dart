import 'dart:async'; 
import 'package:firebase_database/firebase_database.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cublink/screens/login_screen.dart'; 

import 'package:cublink/providers/student_provider.dart';
import 'package:cublink/screens/alert_screen.dart';
import 'package:cublink/screens/geofence_screen.dart';
import 'package:cublink/screens/map_screen.dart';
import 'package:cublink/widgets/background_wave_painter.dart';
import 'package:flutter/material.dart';
import 'package:cublink/widgets/common_nav_bar.dart';
import 'package:cublink/widgets/side_menu_drawer.dart';
import 'package:cublink/screens/student_details_page.dart';
import 'package:provider/provider.dart'; 
import 'package:cublink/providers/theme_provider.dart'; // 🔥 NEEDED FOR THEME

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = -1; 
  late final List<Widget> _navBarPages;

  // THE BOUNCER VARIABLES
  String? _mySessionId;
  StreamSubscription? _sessionSub;

  @override
  void initState() {
    super.initState();
    _navBarPages = [
      const GeofenceScreen(), // Index 0
      const MapScreen(),      // Index 1
      const AlertScreen()     // Index 2
    ];

    _startSessionBouncer();
  }

  void _startSessionBouncer() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _mySessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final sessionRef = FirebaseDatabase.instance.ref('users/$uid/session_id');
    await sessionRef.set(_mySessionId);

    _sessionSub = sessionRef.onValue.listen((event) {
      final liveSessionId = event.snapshot.value?.toString();
      if (liveSessionId != null && _mySessionId != null && liveSessionId != _mySessionId) {
        _forceLogout();
      }
    });
  }

  void _forceLogout() async {
    _sessionSub?.cancel();
    await FirebaseAuth.instance.signOut();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged out: Your account was accessed on another device."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 4),
        )
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), 
        (route) => false
      );
    }
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentData = context.watch<StudentProvider>();
    
    // 🔥 GRAB THE THEME
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface, // DYNAMIC
      endDrawer: const SideMenuDrawer(),
      body: Stack(
        children: [
          // 1. DYNAMIC BACKGROUND GRADIENT
          Container(
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
          
          // 2. DYNAMIC WAVES
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundWavePainter(
                waveColor: isDark 
                  ? Colors.white.withOpacity(0.03) 
                  : Colors.white.withOpacity(0.5),
              ),
            )
          ),

          SafeArea(
            child: _currentIndex == -1
            ? StudentDetailsPage(
              studentName: studentData.studentName, 
              studentClass: studentData.studentClass, 
              schoolName: studentData.schoolName, 
              registerNumber: studentData.registerNumber, 
              contactNumber: studentData.emergencyContact,
              guardianName: studentData.guardianName,
              )
              : IndexedStack(
                  index: _currentIndex,
                  children: _navBarPages
              ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: CommonNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabChange,
              studentName: studentData.studentName,
            ),
          ),
          
          Positioned(
            top: 50,
            right: 20,
            child: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, size: 30, color: isDark ? Colors.white : Colors.black87), // DYNAMIC ICON COLOR
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ),
          
          Positioned(
             top: 50,
             left: 10,
             child: IconButton(
               icon: Icon(Icons.arrow_circle_left, color: isDark ? Colors.white54 : Colors.black54, size: 40), // DYNAMIC ICON COLOR
               onPressed: () {
                if(_currentIndex != -1){
                  setState(() {
                    _currentIndex = -1;
                  });
                } else {
                  Navigator.of(context).pop();
                }
               }
             ),
          ),
        ],
      ),
    );
  }
}