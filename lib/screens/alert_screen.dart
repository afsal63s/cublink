import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:provider/provider.dart'; // 🔥 NEEDED FOR THEME
import 'package:cublink/providers/theme_provider.dart'; // 🔥 NEEDED FOR THEME

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription? _settingsSub;

  // Toggle States
  bool _geofenceAlerts = true;
  bool _offlineAlerts = true;
  bool _backgroundTracking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _listenToSettings(); 
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _listenToSettings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    DatabaseReference settingsRef = FirebaseDatabase.instance.ref('users/$uid/settings');
    
    _settingsSub = settingsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && mounted) {
        setState(() {
          if (data.containsKey('geofence_alerts')) _geofenceAlerts = data['geofence_alerts'];
          if (data.containsKey('offline_alerts')) _offlineAlerts = data['offline_alerts'];
          if (data.containsKey('background_tracking')) _backgroundTracking = data['background_tracking'];
        });
      }
    }, onError: (Object error) {
      debugPrint("AlertScreen: Ignoring database error: $error");
    });
  }

  Future<void> _toggleGeofence(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      setState(() => _geofenceAlerts = value); 
      try {
        await FirebaseDatabase.instance.ref('users/$uid/settings').update({'geofence_alerts': value});
      } catch (e) { debugPrint("Error: $e"); }
    }
  }

  Future<void> _toggleOffline(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      setState(() => _offlineAlerts = value); 
      try {
        await FirebaseDatabase.instance.ref('users/$uid/settings').update({'offline_alerts': value});
      } catch (e) { debugPrint("Error: $e"); }
    }
  }

  Future<void> _toggleBackgroundTracking(bool value) async {
    setState(() => _backgroundTracking = value);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseDatabase.instance.ref('users/$uid/settings').update({'background_tracking': value});
      } catch (e) { debugPrint("Error: $e"); }
    }

    final service = FlutterBackgroundService();
    if (value) {
      await service.startService(); 
    } else {
      service.invoke("stopService"); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 GRAB THE THEME
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DYNAMIC HEADER
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
                          "Safety Alerts",
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
                          "History & Preferences",
                          // Fixed transparent font issue here
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.blueGrey[400], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // TAB BAR (Upgraded for Dark Mode)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2D2A) : const Color(0xFFE0F2F1), // Pine in dark mode
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: isDark ? const Color(0xFF121A18) : Colors.white, // Slate in dark mode
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [ BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 4, offset: const Offset(0, 2)) ]
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Theme.of(context).colorScheme.primary, 
                unselectedLabelColor: isDark ? Colors.white54 : Colors.blueGrey[400], 
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(5),
                tabs: const [ Tab(text: "History Log"), Tab(text: "Settings") ],
              ),
            ),

            const SizedBox(height: 20),

            // TAB CONTENT
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [ 
                  const HistoryLogTab(), 
                  _buildSettingsTab(isDark) // Pass the theme down
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: SETTINGS 
  // ==========================================
  Widget _buildSettingsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildSwitchTile("Geofence Alerts", "Notify when entering/leaving zones", _geofenceAlerts, _toggleGeofence, Icons.location_on_rounded, isDark),
        _buildSwitchTile("Offline Alerts", "Notify if connection drops", _offlineAlerts, _toggleOffline, Icons.wifi_off_rounded, isDark),
        _buildSwitchTile("Background Tracking", "Keep monitoring when app is closed", _backgroundTracking, _toggleBackgroundTracking, Icons.screen_lock_portrait_rounded, isDark),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // DYNAMIC
        borderRadius: BorderRadius.circular(18),
        boxShadow: [ BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4)) ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        activeThumbColor: Colors.white,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : const Color(0xFFE0F2F1), 
            borderRadius: BorderRadius.circular(12)
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          // Fixed transparent font issue here
          child: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[600])),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

// ============================================================================
// 🔥 HISTORY LOG TAB
// ============================================================================
class HistoryLogTab extends StatefulWidget {
  const HistoryLogTab({super.key});

  @override
  State<HistoryLogTab> createState() => _HistoryLogTabState();
}

class _HistoryLogTabState extends State<HistoryLogTab> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; 

  @override
  Widget build(BuildContext context) {
    super.build(context); 

    // 🔥 GRAB THE THEME FOR THE TAB
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text("Not logged in"));

    return Column(
      children: [
        // CLEAR HISTORY BUTTON
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🔥 FIXED "RECENT ACTIVITY" COLOR SO IT'S NOT TOO DARK
              Text("Recent Activity", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
              TextButton.icon(
                onPressed: () { FirebaseDatabase.instance.ref('users/$uid/alert_history').remove(); }, 
                icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.redAccent),
                label: const Text("Clear All", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),

        // FIREBASE STREAM LIST
        Expanded(
          child: StreamBuilder(
            stream: FirebaseDatabase.instance.ref('users/$uid/alert_history').onValue, 
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Error loading history"));
              if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));

              final data = snapshot.data?.snapshot.value as Map?;
              
              if (data == null || data.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 60, color: isDark ? Colors.white24 : Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text("No alerts yet", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[400], fontSize: 16)),
                    ],
                  ),
                );
              }

              List<Map<String, dynamic>> alerts = [];
              data.forEach((key, value) { alerts.add(Map<String, dynamic>.from(value)); });
              
              alerts.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                itemCount: alerts.length,
                itemBuilder: (context, index) { return _buildAlertCard(alerts[index], isDark, textColor); },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, bool isDark, Color? textColor) {
    Color iconColor;
    Color bgColor;
    IconData icon;

    // 🔥 Updated icon backgrounds to use sleek dark-mode opacity instead of jarring pastel colors
    switch (alert['type']) {
      case 'danger':
        iconColor = Colors.redAccent;
        bgColor = isDark ? Colors.redAccent.withOpacity(0.15) : Colors.red[50]!;
        icon = Icons.gpp_bad_rounded;
        break;
      case 'warning':
        iconColor = const Color(0xFFF57C00); 
        bgColor = isDark ? const Color(0xFFF57C00).withOpacity(0.15) : const Color(0xFFFFF3E0); 
        icon = Icons.wifi_off_rounded;
        break;
      case 'success':
        iconColor = const Color(0xFF1A9E75); 
        bgColor = isDark ? const Color(0xFF1A9E75).withOpacity(0.15) : const Color(0xFFE8F5E9); 
        icon = Icons.verified_user_rounded; 
        break;
      default:
        iconColor = Colors.grey;
        bgColor = isDark ? Colors.white12 : Colors.grey[100]!;
        icon = Icons.notifications;
    }

    DateTime time = DateTime.fromMillisecondsSinceEpoch(alert['timestamp'] ?? 0);
    String hour = time.hour > 12 ? (time.hour - 12).toString() : (time.hour == 0 ? "12" : time.hour.toString());
    String minute = time.minute.toString().padLeft(2, '0');
    String ampm = time.hour >= 12 ? "PM" : "AM";
    String formattedTime = "$hour:$minute $ampm";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // DYNAMIC SURFACE
        borderRadius: BorderRadius.circular(18),
        boxShadow: [ BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 4)) ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          alert['title'].toString().replaceAll('🚨 ', '').replaceAll('✅ ', '').replaceAll('⚠️ ', ''), 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor), // DYNAMIC TEXT
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          // Fixed transparent font issue here
          child: Text(
            alert['message'].toString(),
            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 13), 
          ),
        ),
        trailing: Text(
          formattedTime,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[400]),
        ),
      ),
    );
  }
}