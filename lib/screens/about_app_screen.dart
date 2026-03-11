import 'package:flutter/material.dart';
import 'package:cublink/widgets/background_wave_painter.dart'; 
import 'package:provider/provider.dart'; // 🔥 NEEDED FOR THEME
import 'package:cublink/providers/theme_provider.dart'; // 🔥 NEEDED FOR THEME

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    // 🔥 1. Grab the theme state!
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      body: Stack(
        children: [
          // 1. DYNAMIC BACKGROUND GRADIENT
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
          
          // 2. DYNAMIC BACKGROUND WAVES
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
                // --- CUSTOM HEADER ---
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 20, top: 10, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_circle_left, color: isDark ? Colors.white54 : Colors.black54, size: 40),
                        onPressed: () => Navigator.pop(context),
                      ),
                      
                      Text(
                        "About App",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary, // Dynamically picks the right green
                        ),
                      ),
                      
                      const SizedBox(width: 56), 
                    ],
                  ),
                ),

                const Spacer(),

                // --- ABOUT CARD ---
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface, // DYNAMIC SURFACES!
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), 
                        blurRadius: 15, 
                        offset: const Offset(0, 5)
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        height: 100, 
                        width: 100,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, 
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.15), 
                              blurRadius: 20, 
                              offset: const Offset(0, 8)
                            )
                          ]
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/main_logo.png', 
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      
                      // App Name
                      Text(
                        "cublink",
                        style: TextStyle(
                          fontFamily: 'Surgena', 
                          fontSize: 42, 
                          color: Theme.of(context).colorScheme.primary
                        ),
                      ),
                      
                      const SizedBox(height: 5),

                      Text(
                        "Version 1.0.0",
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 30),

                      // Description
                      Text(
                        "A smart student safety system designed to provide real-time location tracking and secure geofencing for parents and schools.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, height: 1.6, color: textColor),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // --- FOOTER ---
                Text(
                  "© 2026 Cublink Team",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}