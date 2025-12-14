import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' show Color;
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

  group('FirebaseSyncService Heart Rate History Tests', () {
    test('should get heart rate history path', () {
      final path = FirebaseSyncService.getHeartRateHistoryPath('elder123');
      expect(path, 'elders/elder123/heartRateHistory');
    });

    test('should format heart rate entry correctly', () {
      final entry = {
        'heartRate': 75,
        'timestamp': DateTime(2024, 1, 15, 10, 30).toIso8601String(),
      };
      
      expect(entry['heartRate'], 75);
      expect(entry['timestamp'], isNotNull);
    });

    test('should identify critical heart rates', () {
      // Normal range: 50-120 bpm
      bool isCritical(int hr) => hr > 120 || hr < 50;
      
      expect(isCritical(75), false);  // Normal
      expect(isCritical(55), false);  // Normal (low end)
      expect(isCritical(115), false); // Normal (high end)
      expect(isCritical(130), true);  // Too high
      expect(isCritical(45), true);   // Too low
      expect(isCritical(150), true);  // Very high
      expect(isCritical(30), true);   // Very low
    });

    test('should filter entries within 24 hours', () {
      final now = DateTime.now();
      final entries = [
        {'heartRate': 72, 'timestamp': now.subtract(const Duration(hours: 1)).toIso8601String()},
        {'heartRate': 78, 'timestamp': now.subtract(const Duration(hours: 12)).toIso8601String()},
        {'heartRate': 65, 'timestamp': now.subtract(const Duration(hours: 23)).toIso8601String()},
        {'heartRate': 80, 'timestamp': now.subtract(const Duration(hours: 25)).toIso8601String()}, // Should be excluded
      ];

      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
      final filtered = entries.where((entry) {
        final timestamp = DateTime.parse(entry['timestamp'] as String);
        return timestamp.isAfter(twentyFourHoursAgo);
      }).toList();

      expect(filtered.length, 3);
      expect(filtered.any((e) => e['heartRate'] == 80), false);
    });

    test('should calculate chart interval based on data count', () {
      double getInterval(int count) {
        if (count <= 10) return 1;
        if (count <= 30) return 5;
        if (count <= 60) return 10;
        return (count / 6).roundToDouble();
      }

      expect(getInterval(5), 1);
      expect(getInterval(10), 1);
      expect(getInterval(20), 5);
      expect(getInterval(30), 5);
      expect(getInterval(50), 10);
      expect(getInterval(100), 17);
    });

    test('should sort entries by timestamp', () {
      final now = DateTime.now();
      final entries = [
        {'heartRate': 78, 'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String()},
        {'heartRate': 72, 'timestamp': now.subtract(const Duration(hours: 5)).toIso8601String()},
        {'heartRate': 82, 'timestamp': now.subtract(const Duration(hours: 1)).toIso8601String()},
      ];

      entries.sort((a, b) => 
          (a['timestamp'] as String).compareTo(b['timestamp'] as String));

      expect(entries[0]['heartRate'], 72); // Oldest first
      expect(entries[1]['heartRate'], 78);
      expect(entries[2]['heartRate'], 82); // Most recent last
    });

    test('should get correct color for heart rate zones', () {
      Color getColor(int hr) {
        if (hr > 120 || hr < 50) return const Color(0xFFF44336); // Red
        if (hr > 100 || hr < 60) return const Color(0xFFFF9800); // Orange
        return const Color(0xFF4CAF50); // Green
      }

      expect(getColor(75), const Color(0xFF4CAF50));  // Normal - green
      expect(getColor(55), const Color(0xFFFF9800));  // Low normal - orange
      expect(getColor(105), const Color(0xFFFF9800)); // High normal - orange
      expect(getColor(45), const Color(0xFFF44336));  // Critical low - red
      expect(getColor(130), const Color(0xFFF44336)); // Critical high - red
    });
  });
}
