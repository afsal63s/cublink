import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class StudentProvider extends ChangeNotifier {
  
  // Data Variables
  String studentName = "Loading...";
  String studentClass = "...";
  String schoolName = "...";
  String emergencyContact = "...";
  String registerNumber = "...";
  bool isLoading = true;
  String guardianName = "...";
  String profileImageUrl = "";

  // Connection Keeper
  StreamSubscription<DatabaseEvent>? _subscription;

  StudentProvider() {
    // Attempt to fetch data immediately if user is already logged in
    if (FirebaseAuth.instance.currentUser != null) {
      fetchStudentData();
    }
  }

  // --- FETCH DATA ---
  Future<void> fetchStudentData() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      isLoading = false;
      notifyListeners();
      return; 
    }

    // Safety: Cancel any existing connection first
    await _subscription?.cancel();

    final DatabaseReference userStudentRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://clublink-2bbc3-default-rtdb.asia-southeast1.firebasedatabase.app'
    ).ref('users/$uid/student_info');
    
    // Start Listening
    _subscription = userStudentRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        studentName = data['name'] ?? "Unknown";
        studentClass = data['class_grade'] ?? "Unknown";
        schoolName = data['school'] ?? "Unknown";
        emergencyContact = data['contact'] ?? "Unknown";
        registerNumber = data['student_id'] ?? "Unknown";
        guardianName = data['guardian'] ?? "Unknown";
        profileImageUrl = data['profile_image'] ?? "";
        
        isLoading = false;
        notifyListeners(); 
      }
    }, onError: (Object error) {
        // 🛑 SILENTLY CATCH ERRORS (Prevents Crash on Logout)
        debugPrint("⚠️ StudentProvider Stream Error (Safe to ignore): $error");
    });
  }

  // --- CLEANUP (Logout) ---
  Future<void> clearData() async {
    debugPrint("🧹 Cleaning up Student Provider...");
    
    // 1. Cancel the subscription
    await _subscription?.cancel(); 
    _subscription = null;
    
    // 2. Clear data from memory
    studentName = "Loading...";
    studentClass = "...";
    schoolName = "...";
    profileImageUrl = "";
    isLoading = true;
    
    // 3. Notify UI that data is gone
    notifyListeners();
  }

  // --- UPDATE PROFILE ---
  Future<void> updateProfile({
    required String newName, 
    required String newGuardian, 
    required String newPhone,
    File? newImageFile, 
  }) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final DatabaseReference userRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://clublink-2bbc3-default-rtdb.asia-southeast1.firebasedatabase.app'
    ).ref('users/$uid/student_info');

    // 1. Upload Image (if changed)
    if (newImageFile != null) {
      try {
        final storage = FirebaseStorage.instanceFor(
          bucket: 'gs://clublink-2bbc3.firebasestorage.app'
        );
        final storageRef = storage.ref().child('users/$uid/profile.jpg');
        await storageRef.putFile(newImageFile);
        String downloadUrl = await storageRef.getDownloadURL();
        await userRef.update({'profile_image': downloadUrl});
      } catch (e) {
        debugPrint("❌ Error uploading image: $e");
      }
    }

    // 2. Update Text Fields
    await userRef.update({
      'name': newName,
      'guardian': newGuardian,
      'contact': newPhone,
    });
  }

  // --- REMOVE IMAGE ---
  Future<void> removeProfileImage() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://clublink-2bbc3-default-rtdb.asia-southeast1.firebasedatabase.app'
    ).ref('users/$uid/student_info');

    try {
      final storage = FirebaseStorage.instanceFor(
          bucket: 'gs://clublink-2bbc3.firebasestorage.app'
      );
      await storage.ref().child('users/$uid/profile.jpg').delete();
    } catch (e) {
      debugPrint("⚠️ Image delete skipped");
    }

    await userRef.update({'profile_image': ""});
    profileImageUrl = ""; 
    notifyListeners();
  }
}