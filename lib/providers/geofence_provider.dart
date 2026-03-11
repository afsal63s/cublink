import 'dart:async'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cublink/models/geofence_model.dart'; 

class GeofenceProvider with ChangeNotifier {
  List<Geofence> _geofences = [];
  bool _isLoading = true;

  // Temporary storage
  Map<dynamic, dynamic>? _activeZoneData;
  Map<dynamic, dynamic>? _savedZonesRawData;

  List<Geofence> get geofences => _geofences;
  bool get isLoading => _isLoading;

  DatabaseReference? _userRef;
  DatabaseReference? _activeRef;

  // --- 1. CONNECTION KEEPERS (To stop memory leaks) ---
  StreamSubscription? _activeSub;
  StreamSubscription? _savedSub;

  void init() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    
    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // --- 2. SAFETY CHECK: Cancel old connections if they exist ---
    _activeSub?.cancel();
    _savedSub?.cancel();

    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://clublink-2bbc3-default-rtdb.asia-southeast1.firebasedatabase.app'
    );

    _userRef = database.ref('users/$uid/saved_geofences');
    _activeRef = database.ref('users/$uid/active_geofence');

    // --- 3. LISTEN TO ACTIVE ZONE ---
    _activeSub = _activeRef!.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null && data['isActive'] == true) {
        _activeZoneData = data;
      } else {
        _activeZoneData = null; // No active zone
      }
      
      _buildGeofenceList();
    });

    // --- 4. LISTEN TO SAVED ZONES ---
    _savedSub = _userRef!.onValue.listen((event) {
      _savedZonesRawData = event.snapshot.value as Map<dynamic, dynamic>?;
      
      _isLoading = false;
      _buildGeofenceList();
    }, onError: (error) {
      debugPrint("⚠️ Geofence Provider Error: $error");
      _isLoading = false;
      notifyListeners();
    });
  }

  // --- 5. THE CLEANUP FUNCTION ---
  Future<void> clearData() async {
    debugPrint("🧹 Cleaning up Geofence Provider...");
    
    await _activeSub?.cancel();
    await _savedSub?.cancel();
    _activeSub = null;
    _savedSub = null;

    _geofences = [];
    _activeZoneData = null;
    _savedZonesRawData = null;
    _isLoading = true;
    
    notifyListeners();
  }

  // Helper to Combine Data
  void _buildGeofenceList() {
    _geofences = [];
    if (_savedZonesRawData != null) {
      _savedZonesRawData!.forEach((key, value) {
        try {
          // Force key to string to prevent parsing errors
          Geofence geo = Geofence.fromMap(key.toString(), value);
          
          bool isReallyActive = false;
          
          if (_activeZoneData != null && _activeZoneData!['lat'] != null) {
            bool sameName = _activeZoneData!['name'] == geo.name;
            
            // 🔥 CRITICAL FIX: Cast to `num` first, then `toDouble()` 
            // This stops Firebase from crashing the app when it returns an Int instead of a Double
            double activeLat = (_activeZoneData!['lat'] as num).toDouble();
            
            bool sameLat = (geo.latitude - activeLat).abs() < 0.0001;
            
            if (sameName && sameLat) {
              isReallyActive = true;
            }
          }

          _geofences.add(Geofence(
             id: geo.id,
             name: geo.name,
             latitude: geo.latitude,
             longitude: geo.longitude,
             radius: geo.radius,
             isActive: isReallyActive, 
           ));
           
        } catch (e) {
          debugPrint("⚠️ Error parsing geofence: $e");
        }
      });
    }
    
    // 🔥 CRITICAL FIX 2: Tell the UI to update!
    notifyListeners();
  }

  Future<void> addGeofence(String name, double lat, double lng, double radius) async {
    if (_userRef == null) return;
    final newRef = _userRef!.push();
    await newRef.set({
      'name': name,
      'latitude': lat,
      'longitude': lng,
      'radius': radius,
      'isActive': false, 
    });
  }

  Future<void> updateGeofence(String id, String name, double radius, double lat, double lng) async {
    if (_userRef == null) return;
    
    await _userRef!.child(id).update({
      'name': name,
      'radius': radius,
      'latitude': lat,
      'longitude': lng,
    });

    final index = _geofences.indexWhere((g) => g.id == id);
    if (index != -1 && _geofences[index].isActive) {
      if (_activeRef != null) {
        await _activeRef!.update({
          'name': name,
          'radius': radius,
          'lat': lat,
          'lng': lng,
        });
      }
    }
  }

  Future<void> deleteGeofence(String id) async {
    if (_userRef == null) return;
    await _userRef!.child(id).remove();
  }

  Future<void> toggleGeofence(String id, bool newValue, Geofence geo) async {
    if (_activeRef == null || _userRef == null) return;

    if (newValue == true) {
      await _activeRef!.set({
        'isActive': true,
        'name': geo.name,
        'lat': geo.latitude,
        'lng': geo.longitude,
        'radius': geo.radius,
      });

      if (_savedZonesRawData != null) {
        _savedZonesRawData!.forEach((key, value) async {
          if (key != id) {
             await _userRef!.child(key).update({'isActive': false});
          }
        });
      }

      await _userRef!.child(id).update({'isActive': true});

    } else {
      await _activeRef!.set({'isActive': false});
      await _userRef!.child(id).update({'isActive': false});
    }
  }
}