import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cublink/auth_wrapper.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  double _scale = 0.5;

  @override
  void initState() {
    super.initState();
    
    // Start animation shortly after screen loads
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _scale = 1.0;
        });
      }
    });

    // Navigate to AuthWrapper after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Theme Detection
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121A18) : const Color(0xFFE0F2F1), 
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 1200),
          opacity: _opacity,
          curve: Curves.easeInOut,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 1200),
            scale: _scale,
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                // 🔥 THE FIX: No padding, pure circular clip
                // 🔥 THE FLAWLESS CIRCLE FIX
                  Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F8F8), // Matches your logo's background perfectly
                          shape: BoxShape.circle,
                          // 🔥 BOX SHADOW COMPLETELY REMOVED! No more ugly borders.
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/main_logo.png',
                            fit: BoxFit.contain, // Keeps your logo perfectly proportioned
                          ),
                        ),
                      ),
                const SizedBox(height: 25),
                
                // App Name
                Text(
                  "CUBLINK",
                  style: TextStyle(
                    fontFamily: 'Surgera', 
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8.0,
                    color: isDark ? Colors.white : const Color(0xFF1A9E75),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Tagline
                Text(
                  "Smart Campus Tracking",
                  style: TextStyle(
                    fontFamily: 'Surgera', 
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.0,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}