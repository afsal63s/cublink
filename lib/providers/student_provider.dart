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
        // SILENTLY CATCH ERRORS (Prevents Crash on Logout)
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
    if (uid == null) throw Exception("User not logged in");

    final DatabaseReference userRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://clublink-2bbc3-default-rtdb.asia-southeast1.firebasedatabase.app'
    ).ref('users/$uid/student_info');

    String? newImageUrl;

    // 1. Upload Image FIRST
    if (newImageFile != null) {
      final storage = FirebaseStorage.instanceFor(
        bucket: 'gs://clublink-2bbc3.firebasestorage.app'
      );
      final storageRef = storage.ref().child('users/$uid/profile.jpg');
      
      // If this fails (e.g., due to Firebase Storage Rules), the function stops here 
      // and throws the error back to the UI screen.
      await storageRef.putFile(newImageFile);
      newImageUrl = await storageRef.getDownloadURL();
    }

    // 2. Update Database ONLY if storage succeeded (or if no image was picked)
    Map<String, dynamic> updates = {
      'name': newName,
      'guardian': newGuardian,
      'contact': newPhone,
    };
    
    // Add the image URL to the update packet only if we successfully uploaded a new one
    if (newImageUrl != null) {
      updates['profile_image'] = newImageUrl;
    }

    await userRef.update(updates);
  }

  // --- REMOVE IMAGE ---
  Future<void> removeProfileImage() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    final userRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://clublink-2bbc3-default-rtdb.asia-southeast1.firebasedatabase.app'
    ).ref('users/$uid/student_info');

    final storage = FirebaseStorage.instanceFor(
      bucket: 'gs://clublink-2bbc3.firebasestorage.app'
    );
    
    try {
      // Attempt to delete the file
      await storage.ref().child('users/$uid/profile.jpg').delete();
    } on FirebaseException catch (e) {
      // If the error is simply that the file doesn't exist, ignore it and proceed to clear DB
      if (e.code != 'object-not-found') {
        rethrow; // If it's a permission error, STOP and throw to the UI
      }
    }

    // Clear the DB only if the file was deleted (or didn't exist anyway)
    await userRef.update({'profile_image': ""});
    profileImageUrl = ""; 
    notifyListeners();
  }
}