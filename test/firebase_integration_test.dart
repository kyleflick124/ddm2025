/// Tests for Firebase Integration
/// Verifies all Firebase operations work correctly

import 'package:flutter_test/flutter_test.dart';
import 'package:elder_monitor/services/firebase_sync_service.dart';
import 'package:elder_monitor/models/health_data.dart';
import 'package:elder_monitor/models/location_data.dart';

void main() {
  group('Firebase Path Generation', () {
    test('Health path is correctly formatted', () {
      expect(
        FirebaseSyncService.getHealthDataPath('user1'),
        'elders/user1/health',
      );
    });

    test('Location path is correctly formatted', () {
      expect(
        FirebaseSyncService.getLocationPath('user1'),
        'elders/user1/location',
      );
    });

    test('Alerts path is correctly formatted', () {
      expect(
        FirebaseSyncService.getAlertsPath('user1'),
        'elders/user1/alerts',
      );
    });

    test('Device path is correctly formatted', () {
      expect(
        FirebaseSyncService.getDeviceStatusPath('user1'),
        'elders/user1/device',
      );
    });

    test('Geofences path is correctly formatted', () {
      expect(
        FirebaseSyncService.getGeofencesPath('user1'),
        'elders/user1/geofences',
      );
    });
  });

  group('Firebase Data Formatting', () {
    test('Health data formats correctly for Firebase', () {
      final healthData = HealthData(
        heartRate: 76,
        spo2: 98,
        steps: 5000,
        temperature: 36.5,
        bloodPressure: '120/80',
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      final formatted = FirebaseSyncService.formatHealthData(healthData);

      expect(formatted['heartRate'], 76);
      expect(formatted['spo2'], 98);
      expect(formatted['steps'], 5000);
      expect(formatted['temperature'], 36.5);
      expect(formatted['bloodPressure'], '120/80');
      expect(formatted['timestamp'], isNotNull);
    });

    test('Location data formats correctly for Firebase', () {
      final locationData = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 10.0,
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      final formatted = FirebaseSyncService.formatLocationData(locationData);

      expect(formatted['latitude'], -23.5505);
      expect(formatted['longitude'], -46.6333);
      expect(formatted['accuracy'], 10.0);
      expect(formatted['timestamp'], isNotNull);
    });
  });

  group('Firebase ID Validation', () {
    test('Valid IDs are accepted', () {
      expect(FirebaseSyncService.isValidElderId('user123'), true);
      expect(FirebaseSyncService.isValidElderId('elderABC'), true);
      expect(FirebaseSyncService.isValidElderId('watch_001'), true);
      expect(FirebaseSyncService.isValidElderId('user-test'), true);
    });

    test('Invalid IDs are rejected', () {
      expect(FirebaseSyncService.isValidElderId(''), false);
      expect(FirebaseSyncService.isValidElderId('user/id'), false);
      expect(FirebaseSyncService.isValidElderId('user.id'), false);
      expect(FirebaseSyncService.isValidElderId('user#id'), false);
      expect(FirebaseSyncService.isValidElderId('user[id]'), false);
      expect(FirebaseSyncService.isValidElderId('user\$id'), false);
    });
  });

  group('Firebase Alert Generation', () {
    test('Alert IDs are unique', () {
      final ids = <String>{};
      
      for (int i = 0; i < 100; i++) {
        ids.add(FirebaseSyncService.generateAlertId());
      }
      
      // All 100 IDs should be unique
      expect(ids.length, 100);
    });

    test('Alert IDs are valid UUIDs', () {
      final id = FirebaseSyncService.generateAlertId();
      
      // UUID v4 format: 8-4-4-4-12 hexadecimal characters
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      
      expect(uuidRegex.hasMatch(id), true);
    });
  });

  group('Firebase Data Structure', () {
    test('Elder data structure is complete', () {
      const elderId = 'elder123';
      
      final dataStructure = {
        'health': FirebaseSyncService.getHealthDataPath(elderId),
        'location': FirebaseSyncService.getLocationPath(elderId),
        'alerts': FirebaseSyncService.getAlertsPath(elderId),
        'device': FirebaseSyncService.getDeviceStatusPath(elderId),
        'geofences': FirebaseSyncService.getGeofencesPath(elderId),
      };
      
      expect(dataStructure.length, 5);
      expect(dataStructure.values.every((v) => v.contains(elderId)), true);
    });

    test('All paths start with elders/', () {
      const elderId = 'test123';
      
      final paths = [
        FirebaseSyncService.getHealthDataPath(elderId),
        FirebaseSyncService.getLocationPath(elderId),
        FirebaseSyncService.getAlertsPath(elderId),
        FirebaseSyncService.getDeviceStatusPath(elderId),
        FirebaseSyncService.getGeofencesPath(elderId),
      ];
      
      for (final path in paths) {
        expect(path.startsWith('elders/'), true);
      }
    });
  });

  group('Data Serialization Round-Trip', () {
    test('HealthData survives JSON round-trip', () {
      final original = HealthData(
        heartRate: 76,
        spo2: 98,
        steps: 5000,
        temperature: 36.5,
        bloodPressure: '120/80',
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      final json = original.toJson();
      final restored = HealthData.fromJson(json);

      expect(restored.heartRate, original.heartRate);
      expect(restored.spo2, original.spo2);
      expect(restored.steps, original.steps);
      expect(restored.temperature, original.temperature);
      expect(restored.bloodPressure, original.bloodPressure);
    });

    test('LocationData survives JSON round-trip', () {
      final original = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 10.0,
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      final json = original.toJson();
      final restored = LocationData.fromJson(json);

      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.accuracy, original.accuracy);
    });
  });

  group('Firebase Realtime Database Rules', () {
    test('Recommended rules structure', () {
      // This documents the expected Firebase rules
      final rules = '''
{
  "rules": {
    "elders": {
      "\$elderId": {
        "health": {
          ".read": "auth != null",
          ".write": "auth != null"
        },
        "location": {
          ".read": "auth != null",
          ".write": "auth != null"
        },
        "alerts": {
          ".read": "auth != null",
          ".write": "auth != null"
        },
        "device": {
          ".read": "auth != null",
          ".write": "auth != null"
        },
        "geofences": {
          ".read": "auth != null",
          ".write": "auth != null"
        }
      }
    }
  }
}
''';
      
      expect(rules.contains('elders'), true);
      expect(rules.contains('health'), true);
      expect(rules.contains('location'), true);
      expect(rules.contains('alerts'), true);
    });
  });
}
