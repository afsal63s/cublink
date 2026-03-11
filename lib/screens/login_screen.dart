import 'package:cublink/screens/admin_dashboard.dart';
import 'package:cublink/screens/home_screen.dart';
import 'package:cublink/widgets/background_wave_painter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:cublink/providers/student_provider.dart'; 
import 'package:cublink/providers/theme_provider.dart'; // 🔥 NEEDED FOR THEME

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (credential.user != null) {
         await Provider.of<StudentProvider>(context, listen: false).fetchStudentData();
      }
      
      if (credential.user?.email == "cublink.adm@gmail.com") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboard())
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen())
        );
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Login Failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      resizeToAvoidBottomInset: true,
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
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('cublink', style: TextStyle(
                      fontFamily: 'Surgena',
                      fontSize: 50,
                      color: Theme.of(context).colorScheme.primary // DYNAMIC
                    ),),
                    const SizedBox(height: 40,),
                    Text("Login To Your Account",
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).textTheme.bodyLarge?.color, // DYNAMIC
                        fontWeight: FontWeight.w900
                      ),),
                    const SizedBox(height: 30,),
                    
                    _buildCustomField(
                      controller: _emailController, 
                      hintText: 'username', 
                      obscureText: false, 
                      isDark: isDark // Pass the theme state!
                    ),
                    const SizedBox(height: 20,),
                    
                    _buildCustomField(
                      controller: _passwordController, 
                      hintText: 'password', 
                      obscureText: !_isPasswordVisible, 
                      isPasswordField: true, 
                      isDark: isDark // Pass the theme state!
                    ),
                    
                    const SizedBox(height: 40,),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Theme.of(context).colorScheme.primary : const Color(0xFF5BE2AA), 
                          foregroundColor: Colors.black,
                          elevation: 5,
                          shadowColor: isDark ? Theme.of(context).colorScheme.primary.withOpacity(0.4) : const Color(0xFF5BE2AA).withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)
                          )
                        ),
                        child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white,)
                        : const Text('Login',
                          style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold
                          ),),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Field with Theme Logic
  Widget _buildCustomField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    bool isPasswordField = false,
    required bool isDark, // 🔥 Added parameter
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // DYNAMIC (White in light, Pine in dark)
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5)
          )
        ]
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color), // Make typed text visible
        decoration: InputDecoration(
          filled: false,
          hintText: hintText,
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[400], fontWeight: FontWeight.bold),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: isPasswordField 
          ? IconButton(
             icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off,
             color: isDark ? Colors.white54 : Colors.grey,
             ),
             onPressed: () {
               setState(() {
                 _isPasswordVisible = !_isPasswordVisible;
               });
             },
          ): null
        ),
      ),
    );
  }
}