import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cublink/screens/add_geofence_screen.dart'; 
import 'package:cublink/providers/geofence_provider.dart'; 
import 'package:cublink/providers/theme_provider.dart'; // 🔥 NEEDED FOR THEME

class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({super.key});

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GeofenceProvider>(context, listen: false).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 GRAB THE THEME
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER SECTION ---
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10, right: 20),
              child: Row(
                children: [
                  const SizedBox(width: 60), 
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Safe Zones",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary, // DYNAMIC
                            letterSpacing: 0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Manage your active geofences",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.blueGrey[400], // DYNAMIC
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. LIST CONTENT ---
            Expanded(
              child: Consumer<GeofenceProvider>(
                builder: (context, provider, child) {
                  
                  // Loading State
                  if (provider.isLoading) {
                     return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
                  }

                  // Empty State
                  if (provider.geofences.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 60, color: isDark ? Colors.white24 : Colors.black26),
                          const SizedBox(height: 15),
                          Text(
                            "No Safe Zones saved yet.\nClick 'Add Zone' below!", 
                            textAlign: TextAlign.center,
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16)
                          ),
                        ],
                      ),
                    );
                  }

                  // The List
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), 
                    itemCount: provider.geofences.length,
                    itemBuilder: (context, index) {
                      final zone = provider.geofences[index];
                      
                      return Dismissible(
                        key: Key(zone.id), 
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 25),
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 35),
                        ),
                        onDismissed: (direction) {
                          provider.deleteGeofence(zone.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${zone.name} deleted")),
                          );
                        },
                        
                        // Card UI
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface, // 🔥 FIXED: DYNAMIC CARD BACKGROUND
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              final Map<String, dynamic>? updatedZone = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddGeofenceScreen(
                                  existingZone: {
                                    'id': zone.id,
                                    'name': zone.name,
                                    'radiusValue': zone.radius,
                                    'lat': zone.latitude,
                                    'lng': zone.longitude,
                                    'status': zone.isActive ? "Active" : "Inactive"
                                  }
                                )),
                              );

                              if (updatedZone != null) {
                                  provider.updateGeofence(
                                   zone.id, 
                                   updatedZone['name'], 
                                   updatedZone['radiusValue'],
                                   updatedZone['lat'],
                                   updatedZone['lng']
                                  );
                              }
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  // 🔥 Dynamic Icon Background
                                  color: isDark ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle 
                                ),
                                child: Icon(Icons.location_on, color: isDark ? Theme.of(context).colorScheme.primary : Colors.blue, size: 28,),
                              ),
                              title: Text(
                                zone.name,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor), // 🔥 DYNAMIC TEXT
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text("Custom Map Zone", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.radar, size: 14, color: isDark ? Colors.white54 : Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text("Radius: ${zone.radius.toInt()}m", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[500], fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                              
                              trailing: Switch(
                                value: zone.isActive,
                                activeColor: Colors.white,
                                activeTrackColor: Theme.of(context).colorScheme.primary, // Matches theme
                                inactiveThumbColor: isDark ? Colors.grey[400] : null,
                                inactiveTrackColor: isDark ? Colors.grey[800] : null,
                                onChanged: (val) {
                                  provider.toggleGeofence(zone.id, val, zone);
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final Map<String, dynamic>? newZone = await Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const AddGeofenceScreen())
            );

            if (newZone != null && context.mounted) {
               Provider.of<GeofenceProvider>(context, listen: false).addGeofence(
                 newZone["name"],
                 newZone["lat"],
                 newZone["lng"],
                 newZone["radiusValue"]
               );
            }
          },
          // 🔥 Make the button pop! Black in light mode, Mint in dark mode.
          backgroundColor: isDark ? Theme.of(context).colorScheme.primary : Colors.black,
          icon: Icon(Icons.add_location_alt, color: isDark ? Colors.black : Colors.white),
          label: Text("Add Zone", style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}