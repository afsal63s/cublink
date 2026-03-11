import 'package:cublink/providers/student_provider.dart';
import 'package:cublink/screens/main_screen.dart';
import 'package:cublink/widgets/background_wave_painter.dart';
import 'package:cublink/widgets/side_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cublink/providers/theme_provider.dart'; // 🔥 NEEDED FOR THEME

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  @override
  Widget build(BuildContext context) {
    final studentData = context.watch<StudentProvider>(); 
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    // 🔥 GRAB THE THEME
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      endDrawer: const SideMenuDrawer(), 
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Builder(builder: (context) => IconButton(
                        onPressed: () => Scaffold.of(context).openEndDrawer(), 
                        icon: Icon(Icons.menu, size: 30, color: isDark ? Colors.white : Colors.black87)
                      ))
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                Text(
                  'Greetings!',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary, // DYNAMIC
                  ),
                ),

                SizedBox(height: height*0.06),
                
                Container(
                  height: height*0.4,
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/girl.png',
                    fit: BoxFit.contain,
                    errorBuilder: ((context,error,stack) =>
                    Icon(Icons.image, size: 80, color: isDark ? Colors.white12 : Colors.black12)),
                  ),
                ),
                
                const Spacer(),
                
                // Pass context to the builder so it can read the theme
                _buildStudentCard(context, studentData, isDark),
                
                const SizedBox(height: 50)
              ],
            )
          )
        ],
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentProvider studentData, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24), 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // DYNAMIC SURFACE
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              // --- DYNAMIC PROFILE PICTURE SECTION ---
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 3), 
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4)
                    )
                  ]
                ),
                child: CircleAvatar(
                  radius: 35, 
                  backgroundColor: isDark ? const Color(0xFF1E2D2A) : const Color(0xFF81D4FA),
                  backgroundImage: studentData.profileImageUrl.isNotEmpty
                      ? NetworkImage(studentData.profileImageUrl)
                      : null,
                  child: studentData.profileImageUrl.isEmpty 
                      ? Icon(Icons.person, size: 40, color: isDark ? Colors.white54 : Colors.white)
                      : null,
                ),
              ),
              // ---------------------------------------
              
              const SizedBox(width: 20), 
              
              Expanded( 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(context: context, label: "Name :", value: studentData.studentName),
                    _InfoRow(context: context, label: "Class :", value: studentData.studentClass),
                    _InfoRow(context: context, label: "School :", value: studentData.schoolName),
                    _InfoRow(context: context, label: "Contact :", value: studentData.emergencyContact),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      studentData.registerNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15, 
                        letterSpacing: 1.1,
                        color: Theme.of(context).textTheme.bodyLarge?.color, // DYNAMIC
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          Align(
            alignment: Alignment.bottomRight, 
            child: ElevatedButton(
              onPressed: studentData.isLoading ? null : () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => MainScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Theme.of(context).colorScheme.primary : Colors.white, // Mint in dark mode
                foregroundColor: Colors.black, // Keep text black for high contrast on mint
                elevation: 3,
                shadowColor: isDark ? Theme.of(context).colorScheme.primary.withOpacity(0.4) : Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), 
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  Text(
                    "Get Started", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward, size: 18), 
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final BuildContext context; // Pass context to access theme
  final String label;
  final String value;
  const _InfoRow({required this.context, required this.label, required this.value});

  @override
  Widget build(BuildContext _) { // Use the passed context
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0), 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(
            "$label ",
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: textColor // DYNAMIC
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.normal, 
                color: textColor // DYNAMIC
              ),
              overflow: TextOverflow.ellipsis, 
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}