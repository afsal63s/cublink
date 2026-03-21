import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:cublink/auth_wrapper.dart'; // Ensure this path is correct

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  double _scale = 0.6; // Started slightly higher for a faster pop

  @override
  void initState() {
    super.initState();
    
    // 1. Snappy Entrance Animation
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _scale = 1.0;
        });
      }
    });

    // 2. Custom Slide + Fade Transition to AuthWrapper
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Snappy Slide Up Configuration
              const begin = Offset(0.0, 0.08); // Start 8% lower
              const end = Offset.zero;
              const curve = Curves.easeOutQuart; 

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 450), // Standard premium speed
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Detect theme from your ThemeProvider/System
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121A18) : const Color(0xFFDFFBF6), 
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 800), // Speed up from 1200ms
          opacity: _opacity,
          curve: Curves.easeIn,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 800), // Speed up from 1200ms
            scale: _scale,
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                // Logo Container
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F8F8), 
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/main_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                
                // Brand Name (Stylized lowercase)
                Text(
                  "cublink",
                  style: TextStyle(
                    fontFamily: 'Surgena', // Matches your pubspec naming
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0, // Reduced slightly for lowercase look
                    color: isDark ? const Color(0xFF5BE2AA) : const Color(0xFF1A9E75),
                  ),
                ),
                const SizedBox(height: 4),
                
                // Tagline (Professional ALL CAPS)
                Text(
                  "SMART CAMPUS TRACKING",
                  style: GoogleFonts.inter( 
                    fontSize: 11,
                    fontWeight: FontWeight.w800, // Extra bold for visibility
                    letterSpacing: 5.0,        // High spacing for premium look
                    color: isDark ? Colors.white54 : Colors.black45,
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