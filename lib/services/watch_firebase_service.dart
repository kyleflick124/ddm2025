import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

/// Service for syncing smartwatch data with Firebase
class WatchFirebaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  static const Uuid _uuid = Uuid();

  /// Send health data to Firebase
  Future<void> sendHealthData({
    required String elderId,
    required int heartRate,
    required int spo2,
    required int steps,
    required double temperature,
    required String bloodPressure,
  }) async {
    try {
      final ref = _database.ref('elders/$elderId/health');
      await ref.set({
        'heartRate': heartRate,
        'spo2': spo2,
        'steps': steps,
        'temperature': temperature,
        'bloodPressure': bloodPressure,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Add heart rate entry to history (for 24h chart)
  Future<void> sendHeartRateToHistory({
    required String elderId,
    required int heartRate,
  }) async {
    try {
      final ref = _database.ref('elders/$elderId/heartRateHistory').push();
      await ref.set({
        'heartRate': heartRate,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail for history entries
    }
  }

  /// Send current location to Firebase
  Future<void> sendLocation({required String elderId}) async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final ref = _database.ref('elders/$elderId/location');
        await ref.set({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Location unavailable
    }
  }

  /// Update device status
  Future<void> updateDeviceStatus({
    required String elderId,
    required int batteryLevel,
    bool isCharging = false,
  }) async {
    try {
      final ref = _database.ref('elders/$elderId/device');
      await ref.update({
        'batteryLevel': batteryLevel,
        'isCharging': isCharging,
        'lastSync': DateTime.now().toIso8601String(),
        'model': 'Elder Watch v1',
        'firmwareVersion': '1.0.0',
      });
    } catch (e) {
      // Silent fail for status updates
    }
  }

  /// Send emergency alert
  Future<void> sendEmergencyAlert({
    required String elderId,
    required String type,
    required String message,
  }) async {
    try {
      final alertId = _uuid.v4();
      final ref = _database.ref('elders/$elderId/alerts/$alertId');
      await ref.set({
        'id': alertId,
        'title': 'Emergência',
        'body': message,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'meta': {
          'priority': 'critical',
          'source': 'watch',
        },
      });

      // Also update a quick-access emergency flag
      final emergencyRef = _database.ref('elders/$elderId/emergency');
      await emergencyRef.set({
        'active': true,
        'timestamp': DateTime.now().toIso8601String(),
        'type': type,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Send fall detection alert
  Future<void> sendFallAlert({required String elderId}) async {
    await sendEmergencyAlert(
      elderId: elderId,
      type: 'fall',
      message: 'Possível queda detectada! Verificar imediatamente.',
    );
  }

  /// Clear emergency state
  Future<void> clearEmergency({required String elderId}) async {
    try {
      final ref = _database.ref('elders/$elderId/emergency');
      await ref.set({
        'active': false,
        'clearedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail
    }
  }
}
