import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/health_data.dart';
import '../models/location_data.dart';

/// Service for synchronizing data with Firebase Realtime Database
class FirebaseSyncService {
  final FirebaseDatabase _database;
  static const Uuid _uuid = Uuid();

  FirebaseSyncService({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  // ==================== Path Generation ====================

  /// Get path for elder's health data
  static String getHealthDataPath(String elderId) {
    return 'elders/$elderId/health';
  }

  /// Get path for elder's location
  static String getLocationPath(String elderId) {
    return 'elders/$elderId/location';
  }

  /// Get path for elder's alerts
  static String getAlertsPath(String elderId) {
    return 'elders/$elderId/alerts';
  }

  /// Get path for device status
  static String getDeviceStatusPath(String elderId) {
    return 'elders/$elderId/device';
  }

  /// Get path for elder's geofences
  static String getGeofencesPath(String elderId) {
    return 'elders/$elderId/geofences';
  }

  /// Get path for heart rate history
  static String getHeartRateHistoryPath(String elderId) {
    return 'elders/$elderId/heartRateHistory';
  }

  // ==================== Data Formatting ====================

  /// Format HealthData for Firebase write
  static Map<String, dynamic> formatHealthData(HealthData data) {
    return data.toJson();
  }

  /// Format LocationData for Firebase write
  static Map<String, dynamic> formatLocationData(LocationData data) {
    return data.toJson();
  }

  // ==================== Validation ====================

  /// Validate elder ID format (no special characters)
  static bool isValidElderId(String id) {
    if (id.isEmpty) return false;
    final invalidChars = RegExp(r'[.#$\[\]/]');
    return !invalidChars.hasMatch(id);
  }

  /// Generate unique alert ID
  static String generateAlertId() {
    return _uuid.v4();
  }

  // ==================== Health Data Operations ====================

  /// Write health data to Firebase (from smartwatch)
  Future<void> writeHealthData(String elderId, HealthData data) async {
    final ref = _database.ref(getHealthDataPath(elderId));
    await ref.set(formatHealthData(data));
  }

  /// Listen to health data updates (for caregiver app)
  Stream<HealthData?> listenToHealthData(String elderId) {
    final ref = _database.ref(getHealthDataPath(elderId));
    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return HealthData.fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Get latest health data once
  Future<HealthData?> getHealthData(String elderId) async {
    final ref = _database.ref(getHealthDataPath(elderId));
    final snapshot = await ref.get();
    if (!snapshot.exists) return null;
    final data = snapshot.value as Map<dynamic, dynamic>;
    return HealthData.fromJson(Map<String, dynamic>.from(data));
  }

  // ==================== Heart Rate History Operations ====================

  /// Add heart rate entry to history (from smartwatch)
  Future<void> addHeartRateEntry(String elderId, int heartRate) async {
    final ref = _database.ref(getHeartRateHistoryPath(elderId)).push();
    await ref.set({
      'heartRate': heartRate,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Listen to heart rate history (for caregiver app chart)
  /// Returns last 24 hours of data
  Stream<List<Map<String, dynamic>>> listenToHeartRateHistory(String elderId) {
    final ref = _database.ref(getHeartRateHistoryPath(elderId));
    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
      
      final entries = data.entries
          .map((e) => Map<String, dynamic>.from(e.value as Map))
          .where((entry) {
            try {
              final timestamp = DateTime.parse(entry['timestamp'] as String);
              return timestamp.isAfter(twentyFourHoursAgo);
            } catch (_) {
              return false;
            }
          })
          .toList();
      
      // Sort by timestamp
      entries.sort((a, b) => 
          (a['timestamp'] as String).compareTo(b['timestamp'] as String));
      
      return entries;
    });
  }

  /// Clean up old heart rate entries (older than 24h)
  Future<void> cleanOldHeartRateEntries(String elderId) async {
    final ref = _database.ref(getHeartRateHistoryPath(elderId));
    final snapshot = await ref.get();
    if (!snapshot.exists) return;
    
    final data = snapshot.value as Map<dynamic, dynamic>;
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
    
    for (final entry in data.entries) {
      try {
        final entryData = entry.value as Map;
        final timestamp = DateTime.parse(entryData['timestamp'] as String);
        if (timestamp.isBefore(twentyFourHoursAgo)) {
          await ref.child(entry.key as String).remove();
        }
      } catch (_) {
        // Skip invalid entries
      }
    }
  }

  // ==================== Location Operations ====================

  /// Write location data to Firebase (from smartwatch)
  Future<void> writeLocation(String elderId, LocationData location) async {
    final ref = _database.ref(getLocationPath(elderId));
    await ref.set(formatLocationData(location));
  }

  /// Listen to location updates (for caregiver app)
  Stream<LocationData?> listenToLocation(String elderId) {
    final ref = _database.ref(getLocationPath(elderId));
    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return LocationData.fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Write location history entry
  Future<void> addLocationHistory(String elderId, LocationData location) async {
    final ref = _database.ref('${getLocationPath(elderId)}/history').push();
    await ref.set(formatLocationData(location));
  }

  // ==================== Alert Operations ====================

  /// Create a new alert
  Future<void> createAlert(
    String elderId,
    String title,
    String body, {
    Map<String, dynamic>? meta,
  }) async {
    final alertId = generateAlertId();
    final ref = _database.ref('${getAlertsPath(elderId)}/$alertId');
    await ref.set({
      'id': alertId,
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
      'meta': meta,
    });
  }

  /// Mark alert as read
  Future<void> markAlertRead(String elderId, String alertId) async {
    final ref = _database.ref('${getAlertsPath(elderId)}/$alertId/read');
    await ref.set(true);
  }

  /// Listen to alerts (for caregiver app)
  Stream<List<Map<String, dynamic>>> listenToAlerts(String elderId) {
    final ref = _database.ref(getAlertsPath(elderId));
    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries
          .map((e) => Map<String, dynamic>.from(e.value as Map))
          .toList()
        ..sort((a, b) => 
            (b['timestamp'] as String).compareTo(a['timestamp'] as String));
    });
  }

  // ==================== Device Status Operations ====================

  /// Update device status (from smartwatch)
  Future<void> updateDeviceStatus(
    String elderId, {
    required int batteryLevel,
    required bool isCharging,
    String? firmwareVersion,
    String? model,
  }) async {
    final ref = _database.ref(getDeviceStatusPath(elderId));
    await ref.update({
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'lastSync': DateTime.now().toIso8601String(),
      if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
      if (model != null) 'model': model,
    });
  }

  /// Listen to device status (for caregiver app)
  Stream<Map<String, dynamic>?> listenToDeviceStatus(String elderId) {
    final ref = _database.ref(getDeviceStatusPath(elderId));
    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    });
  }

  // ==================== Geofence Operations ====================

  /// Save geofence area
  Future<void> saveGeofence(
    String elderId,
    String geofenceId,
    double centerLat,
    double centerLng,
    double radius,
    String name,
  ) async {
    final ref = _database.ref('${getGeofencesPath(elderId)}/$geofenceId');
    await ref.set({
      'id': geofenceId,
      'centerLat': centerLat,
      'centerLng': centerLng,
      'radius': radius,
      'name': name,
    });
  }

  /// Listen to geofences
  Stream<List<Map<String, dynamic>>> listenToGeofences(String elderId) {
    final ref = _database.ref(getGeofencesPath(elderId));
    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries
          .map((e) => Map<String, dynamic>.from(e.value as Map))
          .toList();
    });
  }

  /// Delete geofence
  Future<void> deleteGeofence(String elderId, String geofenceId) async {
    final ref = _database.ref('${getGeofencesPath(elderId)}/$geofenceId');
    await ref.remove();
  }
}
