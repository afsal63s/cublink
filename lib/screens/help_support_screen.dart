import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:cublink/widgets/background_wave_painter.dart'; 
import 'package:provider/provider.dart'; 
import 'package:cublink/providers/theme_provider.dart'; 

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // --- ACTION FUNCTIONS ---
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'cublink.adm@gmail.com',
      query: 'subject=Cublink Support Request&body=Hello Support Team,', 
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint("Could not launch email");
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: '+919605103824', 
    );
    if (!await launchUrl(phoneLaunchUri)) {
      debugPrint("Could not launch phone");
    }
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    // 🔥 GRAB THE THEME
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

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
                // --- CUSTOM HEADER (FIXED ALIGNMENT) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(Icons.arrow_circle_left, color: isDark ? Colors.white54 : Colors.black54, size: 40),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      
                      Text(
                        "Help & Support",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary, // DYNAMIC
                        ),
                      ),
                    ],
                  ),
                ),

                // --- SCROLLABLE CONTENT ---
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        "GEOFENCE & SAFETY",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 15),

                      _buildFAQItem(
                        context,
                        "What is a Geofence?",
                        "A Geofence is a virtual safety boundary (Safe Zone) created around the school or home. If the device crosses this boundary, the app status changes to 'Outside Safe Zone' to alert you.",
                        isDark,
                      ),
                      _buildFAQItem(
                        context,
                        "Can I turn off or edit the Geofence?",
                        "No. To ensure maximum security, Geofences can only be added, edited, or toggled ON/OFF by the School Administrator. This prevents accidental disabling of safety features.",
                        isDark,
                      ),
                      _buildFAQItem(
                        context,
                        "Can I have multiple Safe Zones?",
                        "Currently, the system focuses on one active Safe Zone at a time (usually the School campus) to ensure precise monitoring during school hours.",
                        isDark,
                      ),

                      const SizedBox(height: 30),

                      Text(
                        "DEVICE & PROFILE",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 15),

                      _buildFAQItem(
                        context,
                        "What does 'Device Offline' mean?",
                        "It means the Cublink device has lost internet connection for more than 20 seconds. The map will show the last known location and the time it was last active.",
                        isDark,
                      ),
                      _buildFAQItem(
                        context,
                        "How do I correct my name or class?",
                        "You can easily update your Name, Guardian Name, and Phone Number by going to the Side Menu and selecting 'Edit Profile'.\n\nNote: If your Class/Grade is incorrect, please contact your school administrator as that cannot be changed by students.",
                        isDark,
                      ),

                      const SizedBox(height: 30),

                      // --- CLICKABLE CONTACT CARD ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface, // DYNAMIC
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Column(
                          children: [
                            Text("Need more help?", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.grey)),
                            const SizedBox(height: 15),
                            
                            _buildContactRow(
                              context,
                              icon: Icons.email_outlined, 
                              text: "cublink.adm@gmail.com",
                              onTap: _launchEmail, 
                              isDark: isDark,
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Divider(height: 30, color: isDark ? Colors.white12 : Colors.black12),
                            ),
                            
                            _buildContactRow(
                              context,
                              icon: Icons.phone_outlined, 
                              text: "+91 96051 03824",
                              onTap: _launchPhone, 
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40), 
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget for FAQ ---
  Widget _buildFAQItem(BuildContext context, String question, String answer, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // DYNAMIC
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 5))
        ]
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          question,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        iconColor: Theme.of(context).colorScheme.primary,
        collapsedIconColor: isDark ? Colors.white54 : Colors.black54,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], height: 1.5, fontSize: 14),
            ),
          )
        ],
      ),
    );
  }

  // --- Helper Widget for Contact Rows (NOW WITH EXPANDED FIX) ---
  Widget _buildContactRow(BuildContext context, {required IconData icon, required String text, required VoidCallback onTap, required bool isDark}) {
    return InkWell( 
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : const Color(0xFFE8FDF8), 
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 15),
            
            // 🔥 THE FIX: Text is wrapped in Expanded so it flexes instead of breaking the box
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color, 
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(width: 10),
            Icon(Icons.arrow_outward_rounded, size: 18, color: isDark ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }
}