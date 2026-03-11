import 'package:cublink/auth_wrapper.dart';
import 'package:cublink/firebase_options.dart';
import 'package:cublink/providers/geofence_provider.dart';
import 'package:cublink/providers/student_provider.dart';
import 'package:cublink/providers/theme_provider.dart';
import 'package:cublink/services/background_service.dart';
import 'package:cublink/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init();

  await NotificationService.requestPermission();

  Future.delayed(const Duration(milliseconds: 500), () async {
     await initializeBackgroundService();
  });
  


  // 1. Fetch saved theme explicitly as a bool?
  final prefs = await SharedPreferences.getInstance();
  final bool? savedTheme = prefs.getBool('isDarkMode');

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => StudentProvider()),
      ChangeNotifierProvider(create: (_) => GeofenceProvider()..init()),
      ChangeNotifierProvider(create: (_) => ThemeProvider(savedTheme)),
    ],
    child: const CubLink()));
}

class CubLink extends StatelessWidget {
  const CubLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child){
          return MaterialApp(
          title: 'Cublink',
          debugShowCheckedModeBanner: false,
          
          // 🔥 Tell the app to listen to the ThemeProvider
          themeMode: themeProvider.themeMode, 
          
          // 🔥 Feed it the blueprints we just made
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          
          home: AuthWrapper()
        );
      }
    );
  }
}