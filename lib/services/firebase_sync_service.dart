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

  /// Listen only to NEW alerts (for notifications)
  /// Returns stream of individual new alerts added after subscription
  Stream<Map<String, dynamic>> listenToNewAlerts(String elderId) {
    final ref = _database.ref(getAlertsPath(elderId));
    // Listen to child_added events
    // We filter by timestamp client-side or assume connection time
    final startTime = DateTime.now().toIso8601String();
    
    return ref.orderByChild('timestamp').startAt(startTime).onChildAdded.map((event) {
      if (event.snapshot.value == null) return <String, dynamic>{};
      return Map<String, dynamic>.from(event.snapshot.value as Map);
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

  // ==================== Multi-Elder System Operations ====================

  /// Get path for caregiver data
  static String getCaregiverPath(String caregiverId) {
    return 'caregivers/$caregiverId';
  }

  /// Get path for caregiver's elders list
  static String getCaregiverEldersPath(String caregiverId) {
    return 'caregivers/$caregiverId/elders';
  }

  /// Get path for elder's profile
  static String getElderProfilePath(String elderId) {
    return 'elders/$elderId/profile';
  }

  /// Register a new caregiver
  Future<void> registerCaregiver({
    required String caregiverId,
    required String email,
    required String name,
  }) async {
    final ref = _database.ref(getCaregiverPath(caregiverId));
    await ref.set({
      'email': email,
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Register a new elder and link to caregiver
  Future<String> registerElder({
    required String caregiverId,
    required String name,
    required String age,
    String? phone,
    String? email,
    String? medicalCondition,
  }) async {
    // Generate unique elder ID
    final elderId = 'elder_${_uuid.v4().substring(0, 8)}';
    
    // Create elder profile
    final elderRef = _database.ref(getElderProfilePath(elderId));
    await elderRef.set({
      'name': name,
      'age': age,
      'phone': phone ?? '',
      'email': email ?? '',
      'medicalCondition': medicalCondition ?? '',
      'createdAt': DateTime.now().toIso8601String(),
      'caregiverId': caregiverId,
    });

    // Link elder to caregiver
    await linkElderToCaregiver(caregiverId, elderId);

    // Check if there is a pending elder registration for this email
    if (email != null && email.isNotEmpty) {
      final pendingAuthUid = await checkAndLinkPendingElder(email);
      if (pendingAuthUid != null) {
        // Link the auth UID immediately
        await linkElderAuthUid(elderId, pendingAuthUid);
        // Remove from pending
        await removePendingElder(email);
      }
    }

    // Set as active elder if first one
    final elders = await getCaregiverElders(caregiverId);
    if (elders.length == 1) {
      await setActiveElder(caregiverId, elderId);
    }

    return elderId;
  }

  /// Link an existing elder to a caregiver
  Future<void> linkElderToCaregiver(String caregiverId, String elderId) async {
    final ref = _database.ref('${getCaregiverEldersPath(caregiverId)}/$elderId');
    await ref.set({
      'linkedAt': DateTime.now().toIso8601String(),
      'active': true,
    });
  }

  /// Remove elder from caregiver's list
  Future<void> unlinkElderFromCaregiver(String caregiverId, String elderId) async {
    final ref = _database.ref('${getCaregiverEldersPath(caregiverId)}/$elderId');
    await ref.remove();
  }

  /// Get all elders for a caregiver
  Future<List<Map<String, dynamic>>> getCaregiverElders(String caregiverId) async {
    final ref = _database.ref(getCaregiverEldersPath(caregiverId));
    final snapshot = await ref.get();
    
    if (!snapshot.exists) return [];
    
    final data = snapshot.value as Map<dynamic, dynamic>;
    final List<Map<String, dynamic>> elders = [];
    
    for (final entry in data.entries) {
      final elderId = entry.key as String;
      final elderProfile = await getElderProfile(elderId);
      if (elderProfile != null) {
        elders.add({
          'id': elderId,
          ...elderProfile,
        });
      }
    }
    
    return elders;
  }

  /// Get elder profile
  Future<Map<String, dynamic>?> getElderProfile(String elderId) async {
    final ref = _database.ref(getElderProfilePath(elderId));
    final snapshot = await ref.get();
    
    if (!snapshot.exists) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  /// Update elder profile
  Future<void> updateElderProfile(String elderId, Map<String, dynamic> data) async {
    final ref = _database.ref(getElderProfilePath(elderId));
    await ref.update(data);
  }

  /// Set active elder for a caregiver
  Future<void> setActiveElder(String caregiverId, String elderId) async {
    final ref = _database.ref('${getCaregiverPath(caregiverId)}/activeElder');
    await ref.set(elderId);
  }

  /// Get active elder for a caregiver
  Future<String?> getActiveElder(String caregiverId) async {
    final ref = _database.ref('${getCaregiverPath(caregiverId)}/activeElder');
    final snapshot = await ref.get();
    
    if (!snapshot.exists) return null;
    return snapshot.value as String;
  }

  /// Listen to caregiver's elders list
  Stream<List<Map<String, dynamic>>> listenToCaregiverElders(String caregiverId) {
    final ref = _database.ref(getCaregiverEldersPath(caregiverId));
    return ref.onValue.asyncMap((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Map<String, dynamic>>[];
      
      final List<Map<String, dynamic>> elders = [];
      for (final entry in data.entries) {
        final elderId = entry.key as String;
        final elderProfile = await getElderProfile(elderId);
        if (elderProfile != null) {
          elders.add({
            'id': elderId,
            ...elderProfile,
          });
        }
      }
      return elders;
    });
  }

  /// Listen to active elder changes
  Stream<String?> listenToActiveElder(String caregiverId) {
    final ref = _database.ref('${getCaregiverPath(caregiverId)}/activeElder');
    return ref.onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return event.snapshot.value as String;
    });
  }

  /// Find elder by email (for automatic linking on login)
  /// Returns elderId if found, null otherwise
  Future<String?> findElderByEmail(String email) async {
    if (email.isEmpty) return null;
    
    try {
      final ref = _database.ref('elders');
      final snapshot = await ref.get();
      
      if (!snapshot.exists) return null;
      
      final elders = snapshot.value as Map<dynamic, dynamic>;
      
      for (final entry in elders.entries) {
        final elderId = entry.key as String;
        final elderData = entry.value as Map<dynamic, dynamic>;
        
        // Check profile email
        if (elderData['profile'] != null) {
          final profile = elderData['profile'] as Map<dynamic, dynamic>;
          final elderEmail = profile['email']?.toString().toLowerCase() ?? '';
          
          if (elderEmail == email.toLowerCase()) {
            return elderId;
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update elder with their auth UID (for login linking)
  Future<void> linkElderAuthUid(String elderId, String authUid) async {
    final ref = _database.ref(getElderProfilePath(elderId));
    await ref.update({
      'authUid': authUid,
      'linkedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Register a pending elder (logged in before caregiver added them)
  /// This allows future linking when caregiver adds this email
  Future<void> registerPendingElder({
    required String email,
    required String authUid,
    required String name,
  }) async {
    if (email.isEmpty) return;
    
    final ref = _database.ref('pendingElders/${email.replaceAll('.', '_').replaceAll('@', '_')}');
    await ref.set({
      'email': email,
      'authUid': authUid,
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// Check for pending elder and link them when caregiver registers elder with matching email
  Future<String?> checkAndLinkPendingElder(String email) async {
    if (email.isEmpty) return null;
    
    try {
      final key = email.replaceAll('.', '_').replaceAll('@', '_');
      final ref = _database.ref('pendingElders/$key');
      final snapshot = await ref.get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data['authUid'] as String?;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Remove pending elder after successful linking
  Future<void> removePendingElder(String email) async {
    if (email.isEmpty) return;
    
    final key = email.replaceAll('.', '_').replaceAll('@', '_');
    final ref = _database.ref('pendingElders/$key');
    await ref.remove();
  }
}

