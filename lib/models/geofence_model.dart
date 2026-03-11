class Geofence {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final bool isActive;

  Geofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.isActive,
  });

  factory Geofence.fromMap(String id, Map<dynamic, dynamic> map) {
    return Geofence(
      id: id,
      name: map['name'] ?? 'Unknown Zone',
      // SAFETY CHECK: Try to parse whatever is in the DB, whether it's String or Number
      latitude: _parseDouble(map['lat']) ?? _parseDouble(map['latitude']) ?? 8.5502,
      longitude: _parseDouble(map['lng']) ?? _parseDouble(map['longitude']) ?? 76.9393,
      // Handle both 'radius' and 'radiusValue' keys to match your old data
      radius: _parseDouble(map['radius']) ?? _parseDouble(map['radiusValue']) ?? 200.0,
      isActive: map['isActive'] ?? false,
    );
  }

  // Helper to safely convert String/Int/Double to Double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remove 'm' if it exists (e.g., "200m")
      String cleanStr = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleanStr);
    }
    return null;
  }
}