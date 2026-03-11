import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // REQUIRED FOR SAVING

class ThemeProvider with ChangeNotifier {
  late ThemeMode _themeMode;

  // Constructor safely accepts the saved preference
  ThemeProvider(bool? savedIsDark) {
    if (savedIsDark == null) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = savedIsDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  ThemeMode get themeMode => _themeMode;

  // INTELLIGENT GETTER: Syncs with system if no manual choice is made
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // TOGGLE AND SAVE
  Future<void> toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isOn);
  }
}

class AppThemes {
  // -----------------------------------------
  // ☀️ LIGHT THEME
  // -----------------------------------------
  static final lightTheme = ThemeData(
    scaffoldBackgroundColor: const Color(0xFFDFFBF6), 
    primaryColor: const Color(0xFF1A9E75), 
    
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5BE2AA), 
      primary: const Color(0xFF5BE2AA),
      brightness: Brightness.light,
      surface: Colors.white, 
    ),
    
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: InputBorder.none, 
      hintStyle: TextStyle(color: Colors.grey),
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      systemOverlayStyle: SystemUiOverlayStyle.dark, 
    ),
  );

  // -----------------------------------------
  // 🌙 DARK THEME
  // -----------------------------------------
  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: const Color(0xFF121A18), 
    primaryColor: const Color(0xFF5BE2AA), 
    
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A9E75), 
      primary: const Color(0xFF5BE2AA),
      brightness: Brightness.dark,
      surface: const Color(0xFF1E2D2A), 
    ),
    
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF1E2D2A), 
      border: InputBorder.none, 
      hintStyle: TextStyle(color: Colors.white54),
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
  );
}