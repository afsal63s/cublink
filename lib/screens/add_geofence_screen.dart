import 'package:cublink/providers/geofence_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart'; // 🔥 NEEDED FOR THEME
import 'package:cublink/providers/theme_provider.dart'; // 🔥 NEEDED FOR THEME

class AddGeofenceScreen extends StatefulWidget {
  // Pass existing zone data if we are editing. Null means we are adding a new one.
  final Map<String, dynamic>? existingZone;
  
  const AddGeofenceScreen({super.key, this.existingZone});

  @override
  State<AddGeofenceScreen> createState() => _AddGeofenceScreenState();
}

class _AddGeofenceScreenState extends State<AddGeofenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final MapController _mapController = MapController();
  final TextEditingController _nameController = TextEditingController();
  
  LatLng _center = const LatLng(0, 0); 
  double _radiusValue = 200;
  bool _isLoadingLocation = true; 

  @override
  void initState() {
    super.initState();
    
    if (widget.existingZone != null) {
      _nameController.text = widget.existingZone!['name'];
      _center = LatLng(widget.existingZone!['lat'], widget.existingZone!['lng']);
      _radiusValue = widget.existingZone!['radiusValue'];
      _isLoadingLocation = false;
    } else {
      _fetchDeviceLocation();
    }
  }

  Future<void> _fetchDeviceLocation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final snapshot = await FirebaseDatabase.instance.ref('users/$uid/live_location').get();
        if (snapshot.exists) {
          final data = snapshot.value as Map;
          if (mounted) {
            setState(() {
              _center = LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble());
              _isLoadingLocation = false;
            });
            _mapController.move(_center, 16.0);
            return;
          }
        }
      } catch (e) {
        debugPrint("Error fetching live location: $e");
      }
    }
    
    if (mounted) {
      setState(() {
        _center = const LatLng(8.5502, 76.9393); 
        _isLoadingLocation = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 GRAB THE THEME
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      body: Stack(
        children: [
          // 1. The Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _center = camera.center;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                // 🔥 DYNAMIC MAP TILES
                urlTemplate: isDark 
                    ? 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png'
                    : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.cublink.app',
              ),
              if (!_isLoadingLocation) 
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _center,
                      radius: _radiusValue, 
                      useRadiusInMeter: true,
                      // Adjusted color so it pops perfectly on dark tiles
                      color: isDark ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.3),
                      borderColor: isDark ? Theme.of(context).colorScheme.primary : Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
            ],
          ),

          // LOADING OVERLAY
          if (_isLoadingLocation)
            Container(
              color: isDark ? const Color(0xFF121A18).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: isDark ? Theme.of(context).colorScheme.primary : Colors.black),
                    const SizedBox(height: 15),
                    Text(
                      "Locating ID Card...", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor)
                    )
                  ],
                ),
              ),
            ),

          // 2. The Fixed "Picker" Pin
          if (!_isLoadingLocation)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40), 
                child: Icon(
                  Icons.location_on, 
                  size: 50, 
                  color: isDark ? Theme.of(context).colorScheme.primary : Colors.red // Mint pin in dark mode!
                ),
              ),
            ),

          // 3. Bottom Control Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface, // DYNAMIC BACKGROUND
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DYNAMIC TEXT FIELD
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: textColor), // Prevents transparent typing
                      decoration: InputDecoration(
                        labelText: "Zone Name (e.g. School, Home)",
                        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none, // Cleaner look
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty){
                          return "Please enter a name for this zone";
                        }
                        final provider = Provider.of<GeofenceProvider>(context, listen: false);
                        if (provider.isNameDuplicate(value, excludeId: widget.existingZone?['id'])){
                          return "This name already exists";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // RADIUS SLIDER
                  Text(
                    "Radius: ${_radiusValue.toInt()} meters", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor)
                  ),
                  Slider(
                    value: _radiusValue,
                    min: 50,
                    max: 1000, 
                    activeColor: isDark ? Theme.of(context).colorScheme.primary : Colors.blueAccent,
                    inactiveColor: isDark ? Colors.grey[800] : null,
                    onChanged: (val) {
                      setState(() {
                        _radiusValue = val; 
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  
                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Theme.of(context).colorScheme.primary : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: _isLoadingLocation ? null : () {
                        if (_formKey.currentState!.validate()){
                          Map<String, dynamic> returnedZone = {
                          "name": _nameController.text.isEmpty ? "New Zone" : _nameController.text,
                          "address": "Custom Location", 
                          "radius": "${_radiusValue.toInt()}m",
                          "radiusValue": _radiusValue,
                          "lat": _center.latitude,
                          "lng": _center.longitude,
                          "status": widget.existingZone?['status'] ?? "Inactive",
                          "icon": widget.existingZone?['icon'] ?? Icons.place,
                          "color": widget.existingZone?['color'] ?? Colors.teal,
                        };
                        
                        Navigator.pop(context, returnedZone); 
                        }
                        else{
                          debugPrint("Validation failed!");
                        }
                      },
                      child: Text(
                        widget.existingZone == null ? "Create Zone" : "Update Zone", 
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white, 
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // 4. Back Button (Wrapped in a circular container so it's always visible over the map)
          Positioned(
            top: 50, left: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Padding(
                  padding: const EdgeInsets.only(left: 6.0), // Centers the iOS arrow visually
                  child: Icon(Icons.arrow_back_ios, color: textColor),
                ), 
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}