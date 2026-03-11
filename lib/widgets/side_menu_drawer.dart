import 'package:cublink/auth_wrapper.dart';
import 'package:cublink/providers/geofence_provider.dart';
import 'package:cublink/providers/student_provider.dart';
import 'package:cublink/providers/theme_provider.dart'; 
import 'package:cublink/screens/about_app_screen.dart';
import 'package:cublink/screens/edit_profile_screen.dart';
import 'package:cublink/screens/help_support_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SideMenuDrawer extends StatelessWidget {
  const SideMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    
    // Listen to live data
    final student = context.watch<StudentProvider>();
    final themeProvider = context.watch<ThemeProvider>(); 
    final isDark = themeProvider.isDarkMode;

    return Drawer(
      // 🔥 Dynamically change drawer background color
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // ============================================
          // 1. HEADER SECTION
          // ============================================
          Container(
            width: double.infinity,
            height: screenHeight * 0.22, 
            padding: const EdgeInsets.fromLTRB(25, 60, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient( 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5BE2AA), Color(0xFF1A9E75)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                // --- Avatar ---
                Container(
                  padding: const EdgeInsets.all(2), 
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: student.profileImageUrl.isNotEmpty
                        ? NetworkImage(student.profileImageUrl)
                        : null,
                    child: student.profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 35, color: Colors.grey)
                        : null,
                  ),
                ),
                
                const SizedBox(width: 15),

                // --- Name ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        student.studentName.isEmpty ? "Student" : student.studentName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Class: ${student.studentClass}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ============================================
          // 2. MENU ITEMS
          // ============================================
          
          _buildMenuItem(
            context,
            icon: Icons.edit_note_rounded,
            title: "Edit Profile",
            isDark: isDark,
            onTap: () {
               Navigator.pop(context); 
               Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            },
          ),

          const Divider(thickness: 1, height: 30, indent: 20, endIndent: 20, color: Colors.grey),

          _buildMenuItem(
            context,
            icon: Icons.help_outline_rounded,
            title: "Help & Support",
            isDark: isDark,
            onTap: () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
            },
          ),

          _buildMenuItem(
            context,
            icon: Icons.info_outline_rounded,
            title: "About App",
            isDark: isDark,
            onTap: () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppScreen()));
            },
          ),

          const Spacer(),

          // ============================================
          // 3. 🔥 THE PREMIUM THEME TOGGLE
          // ============================================
          _buildThemeToggle(context, themeProvider),

          const SizedBox(height: 10),

          // ============================================
          // 4. LOGOUT BUTTON
          // ============================================
          Padding(
            padding: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.red.withOpacity(0.15) : Colors.red[50], 
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                onTap: () => _showLogoutConfirmation(context),
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text(
                  "Log Out",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget: Standard Menu Item ---
  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required bool isDark, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.teal.withOpacity(0.15) : const Color(0xFFE0F2F1), 
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1A9E75), size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  // --- Helper Widget: Premium Minimal Theme Switcher ---
  Widget _buildThemeToggle(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      title: Text(
        "Appearance",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: GestureDetector(
        onTap: () => themeProvider.toggleTheme(!isDark),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 65,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: isDark ? const Color(0xFF1A9E75).withOpacity(0.2) : Colors.grey[200],
            border: Border.all(
              color: isDark ? const Color(0xFF5BE2AA).withOpacity(0.5) : Colors.transparent,
              width: 1.5
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutBack, 
            alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.all(3),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF5BE2AA) : Colors.white,
                boxShadow: [
                  if (!isDark)
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                size: 16,
                color: isDark ? const Color(0xFF121A18) : Colors.orangeAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // 5. THE SAFE LOGOUT DIALOG 🛡️
  // ============================================
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { 
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface, 
          surfaceTintColor: Colors.transparent, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), 
          contentPadding: const EdgeInsets.all(25),
          
          title: Column(
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFF1A9E75), size: 40), 
              const SizedBox(height: 15),
              Text(
                "Log Out?", 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).textTheme.bodyLarge?.color, 
                  fontSize: 22
                )
              ),
            ],
          ),
          
          content: const Text(
            "Are you sure you want to log out of your account?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          
          actionsAlignment: MainAxisAlignment.center, 
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(), 
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              ),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(width: 10),

            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Provider.of<StudentProvider>(context, listen: false).clearData();
                await Provider.of<GeofenceProvider>(context, listen: false).clearData();
                await Future.delayed(const Duration(milliseconds: 500));
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BE2AA), 
                foregroundColor: Colors.black, 
                elevation: 0, 
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("Yes, Logout", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}