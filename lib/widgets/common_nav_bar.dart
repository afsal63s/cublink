import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🔥 NEEDED FOR THEME
import 'package:cublink/providers/theme_provider.dart'; // 🔥 NEEDED FOR THEME

class CommonNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap; 
  final String studentName; 

  const CommonNavBar({
    super.key, 
    required this.currentIndex, 
    required this.onTap, 
    required this.studentName
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 GRAB THE THEME
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      height: 80, 
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D2A) : const Color(0xFF1A9E75),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            // Make shadow stronger in dark mode so it pops off the background
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.shield_outlined, Icons.shield, 0),
          _buildNavItem(Icons.location_on_outlined, Icons.location_on, 1),
          _buildNavItem(Icons.warning_amber_rounded, Icons.warning_rounded, 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, int index) {
    bool isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: isSelected 
            ? BoxDecoration(
                color: Colors.white.withOpacity(0.2), 
                shape: BoxShape.circle,
              )
            : null,
        child: Icon(
          isSelected ? activeIcon : icon,
          color: Colors.white,
          size: isSelected ? 32 : 28, 
        ),
      ),
    );
  }
}