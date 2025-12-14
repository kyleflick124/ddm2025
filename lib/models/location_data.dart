import 'dart:math';

/// Model representing GPS location data from the smartwatch
class LocationData {
  /// Latitude in degrees
  final double latitude;
  
  /// Longitude in degrees
  final double longitude;
  
  /// Location accuracy in meters
  final double accuracy;
  
  /// Timestamp when this location was collected
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  /// Calculate distance to another location in meters using Haversine formula
  double distanceTo(LocationData other) {
    const double earthRadius = 6371000; // meters
    
    final lat1Rad = latitude * pi / 180;
    final lat2Rad = other.latitude * pi / 180;
    final deltaLat = (other.latitude - latitude) * pi / 180;
    final deltaLng = (other.longitude - longitude) * pi / 180;
    
    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Check if this location is within a certain radius of another location
  bool isWithinRadius(LocationData center, double radiusMeters) {
    return distanceTo(center) <= radiusMeters;
  }

  /// Check if location accuracy is considered good (< 20 meters)
  bool isAccurate({double threshold = 20.0}) {
    return accuracy <= threshold;
  }

  /// Serialize to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Deserialize from JSON (Firebase)
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Create a copy with optional updated fields
  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, accuracy: $accuracy m)';
  }
}
