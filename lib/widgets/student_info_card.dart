import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:cublink/providers/student_provider.dart'; 
import 'package:cublink/providers/theme_provider.dart'; // 🔥 NEEDED FOR THEME

class StudentInfoCard extends StatelessWidget {
  final String name;
  final String className;
  final String school;
  final String regNo;
  final String guardianName;
  final String contact;

  const StudentInfoCard({
    super.key,
    required this.name,
    required this.className,
    required this.school,
    required this.regNo,
    required this.contact,
    required this.guardianName,
  });

  @override
  Widget build(BuildContext context) {
    final student = Provider.of<StudentProvider>(context);
    
    // 🔥 GRAB THE THEME
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // DYNAMIC SURFACE COLOR
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), 
            blurRadius: 15
          )
        ]
      ),
      child: Column(
        children: [
          // --- DYNAMIC PROFILE PICTURE ---
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Dark border in dark mode, light border in light mode
              border: Border.all(color: isDark ? const Color(0xFF121A18) : Colors.grey.shade200, width: 3),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: isDark ? const Color(0xFF1E2D2A) : const Color(0xFFB2DFDB),
              backgroundImage: student.profileImageUrl.isNotEmpty
                  ? NetworkImage(student.profileImageUrl)
                  : null,
              child: student.profileImageUrl.isEmpty
                  ? Icon(Icons.person, size: 60, color: isDark ? Colors.white54 : Colors.white)
                  : null,
            ),
          ),
          
          const SizedBox(height: 15),
          
          Text(
            regNo,
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: textColor // DYNAMIC TEXT
            ),
          ),
          
          const SizedBox(height: 30),

          _buildRow("Name :", name, isDark, textColor),
          const SizedBox(height: 10),
          _buildRow("Class :", className, isDark, textColor),
          const SizedBox(height: 10),
          _buildRow("School :", school, isDark, textColor),
          const SizedBox(height: 10),
          _buildRow("Guardian :", guardianName, isDark, textColor),
          const SizedBox(height: 10),
          _buildRow("Contact :", contact, isDark, textColor),
        ],
      ),
    );
  }

  // Updated Helper Widget to Accept Theme Colors
  Widget _buildRow(String label, String value, bool isDark, Color? textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80, 
            child: Text(
              label, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: isDark ? Colors.white54 : Colors.black54 // DYNAMIC LABEL
              ),
            ),
          ),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                fontSize: 16,
                color: textColor // DYNAMIC VALUE
              ),
            ),
          )
        ],
      ),
    );
  }
}