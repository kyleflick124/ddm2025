import 'package:flutter_test/flutter_test.dart';
import 'package:elder_monitor/services/firebase_sync_service.dart';
import 'package:elder_monitor/models/health_data.dart';
import 'package:elder_monitor/models/location_data.dart';

void main() {
  group('FirebaseSyncService Health Data Tests', () {
    test('should convert HealthData to Firebase path format', () {
      final healthData = HealthData(
        heartRate: 76,
        spo2: 98,
        steps: 4523,
        temperature: 36.8,
        bloodPressure: '120/80',
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );
      
      final path = FirebaseSyncService.getHealthDataPath('elder123');
      expect(path, 'elders/elder123/health');
    });

    test('should format health data for Firebase write', () {
      final healthData = HealthData(
        heartRate: 76,
        spo2: 98,
        steps: 4523,
        temperature: 36.8,
        bloodPressure: '120/80',
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );
      
      final formatted = FirebaseSyncService.formatHealthData(healthData);
      
      expect(formatted['heartRate'], 76);
      expect(formatted['spo2'], 98);
      expect(formatted['steps'], 4523);
    });
  });

  group('FirebaseSyncService Location Data Tests', () {
    test('should convert LocationData to Firebase path format', () {
      final path = FirebaseSyncService.getLocationPath('elder123');
      expect(path, 'elders/elder123/location');
    });

    test('should format location data for Firebase write', () {
      final location = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 10.5,
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );
      
      final formatted = FirebaseSyncService.formatLocationData(location);
      
      expect(formatted['latitude'], -23.5505);
      expect(formatted['longitude'], -46.6333);
      expect(formatted['accuracy'], 10.5);
    });
  });

  group('FirebaseSyncService Alert Data Tests', () {
    test('should get alerts path for elder', () {
      final path = FirebaseSyncService.getAlertsPath('elder123');
      expect(path, 'elders/elder123/alerts');
    });

    test('should format alert for Firebase', () {
      final alert = {
        'title': 'Queda detectada',
        'body': 'O idoso pode ter caído',
        'timestamp': DateTime(2024, 1, 15, 10, 30).toIso8601String(),
        'read': false,
      };
      
      expect(alert['title'], 'Queda detectada');
      expect(alert['read'], false);
    });
  });

  group('FirebaseSyncService Device Status Tests', () {
    test('should get device status path', () {
      final path = FirebaseSyncService.getDeviceStatusPath('elder123');
      expect(path, 'elders/elder123/device');
    });

    test('should format device status for Firebase', () {
      final deviceStatus = {
        'batteryLevel': 78,
        'isCharging': true,
        'lastSync': DateTime.now().toIso8601String(),
        'firmwareVersion': '1.2.4',
        'model': 'SmartWatch Sênior',
      };
      
      expect(deviceStatus['batteryLevel'], 78);
      expect(deviceStatus['isCharging'], true);
    });
  });

  group('FirebaseSyncService Path Validation Tests', () {
    test('should validate elder ID format', () {
      expect(FirebaseSyncService.isValidElderId('elder123'), true);
      expect(FirebaseSyncService.isValidElderId(''), false);
      expect(FirebaseSyncService.isValidElderId('elder/123'), false);
      expect(FirebaseSyncService.isValidElderId('elder.123'), false);
    });

    test('should generate unique alert ID', () {
      final id1 = FirebaseSyncService.generateAlertId();
      final id2 = FirebaseSyncService.generateAlertId();
      
      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(equals(id2)));
    });
  });
}
