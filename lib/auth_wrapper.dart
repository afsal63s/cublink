import 'package:cublink/providers/student_provider.dart';
import 'package:cublink/screens/admin_dashboard.dart';
import 'package:cublink/screens/home_screen.dart';
import 'package:cublink/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // This stream listens to Login/Logout events in real-time!
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // 1. If Firebase is still checking, show a loading spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If User is Logged In (Data exists)
        if (snapshot.hasData) {
          final user = snapshot.data!;
          
          // --- Admin Check ---
          if (user.email == "cublink.adm@gmail.com") {
             return const AdminDashboard();
          }
          // --- THE MAGIC: Wake up the Provider! ---
          // We use this weird "PostFrameCallback" to trigger the fetch safely
          // after the widget is built.
          WidgetsBinding.instance.addPostFrameCallback((_) {
             Provider.of<StudentProvider>(context, listen: false).fetchStudentData();
          });

          

          // --- Go to Home ---
          return const HomeScreen();
        }

        // 3. If User is Logged Out
        return const LoginScreen();
      },
    );
  }
}