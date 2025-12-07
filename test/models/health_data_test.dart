import 'package:flutter_test/flutter_test.dart';
import 'package:elder_monitor/models/health_data.dart';

void main() {
  group('HealthData Model Tests', () {
    test('should create HealthData with all required fields', () {
      final timestamp = DateTime.now();
      final healthData = HealthData(
        heartRate: 76,
        spo2: 98,
        steps: 4523,
        temperature: 36.8,
        bloodPressure: '120/80',
        timestamp: timestamp,
      );
      
      expect(healthData.heartRate, 76);
      expect(healthData.spo2, 98);
      expect(healthData.steps, 4523);
      expect(healthData.temperature, 36.8);
      expect(healthData.bloodPressure, '120/80');
      expect(healthData.timestamp, timestamp);
    });

    test('should validate heart rate within normal range', () {
      final healthData = HealthData(
        heartRate: 76,
        spo2: 98,
        steps: 0,
        temperature: 36.5,
        bloodPressure: '120/80',
        timestamp: DateTime.now(),
      );
      
      expect(healthData.isHeartRateNormal, true);
    });

    test('should detect abnormal heart rate (too high)', () {
      final healthData = HealthData(
        heartRate: 120,
        spo2: 98,
        steps: 0,
        temperature: 36.5,
        bloodPressure: '120/80',
        timestamp: DateTime.now(),
      );
      
      expect(healthData.isHeartRateNormal, false);
    });

    test('should detect abnormal heart rate (too low)', () {
      final healthData = HealthData(
        heartRate: 45,
        spo2: 98,
        steps: 0,
        temperature: 36.5,
        bloodPressure: '120/80',
        timestamp: DateTime.now(),
      );
      
      expect(healthData.isHeartRateNormal, false);
    });

    test('should detect low SpO2', () {
      final healthData = HealthData(
        heartRate: 76,
        spo2: 92,
        steps: 0,
        temperature: 36.5,
        bloodPressure: '120/80',
        timestamp: DateTime.now(),
      );
      
      expect(healthData.isSpo2Normal, false);
    });

    test('should detect normal SpO2', () {
      final healthData = HealthData(
        heartRate: 76,
        spo2: 98,
        steps: 0,
        temperature: 36.5,
        bloodPressure: '120/80',
        timestamp: DateTime.now(),
      );
      
      expect(healthData.isSpo2Normal, true);
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
      final healthData = HealthData(
        heartRate: 76,
        spo2: 98,
        steps: 4523,
        temperature: 36.8,
        bloodPressure: '120/80',
        timestamp: timestamp,
      );
      
      final json = healthData.toJson();
      
      expect(json['heartRate'], 76);
      expect(json['spo2'], 98);
      expect(json['steps'], 4523);
      expect(json['temperature'], 36.8);
      expect(json['bloodPressure'], '120/80');
      expect(json['timestamp'], timestamp.toIso8601String());
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'heartRate': 76,
        'spo2': 98,
        'steps': 4523,
        'temperature': 36.8,
        'bloodPressure': '120/80',
        'timestamp': '2024-01-15T10:30:00.000',
      };
      
      final healthData = HealthData.fromJson(json);
      
      expect(healthData.heartRate, 76);
      expect(healthData.spo2, 98);
      expect(healthData.steps, 4523);
      expect(healthData.temperature, 36.8);
      expect(healthData.bloodPressure, '120/80');
    });

    test('should handle extreme values', () {
      final healthData = HealthData(
        heartRate: 200,
        spo2: 100,
        steps: 50000,
        temperature: 42.0,
        bloodPressure: '180/120',
        timestamp: DateTime.now(),
      );
      
      expect(healthData.heartRate, 200);
      expect(healthData.spo2, 100);
      expect(healthData.steps, 50000);
    });

    test('should calculate if health status is critical', () {
      // Critical: very low SpO2 or very abnormal heart rate
      final criticalHealth = HealthData(
        heartRate: 40,
        spo2: 85,
        steps: 0,
        temperature: 39.5,
        bloodPressure: '150/100',
        timestamp: DateTime.now(),
      );
      
      expect(criticalHealth.isCritical, true);
    });

    test('should detect normal overall health', () {
      final normalHealth = HealthData(
        heartRate: 72,
        spo2: 98,
        steps: 5000,
        temperature: 36.5,
        bloodPressure: '120/80',
        timestamp: DateTime.now(),
      );
      
      expect(normalHealth.isCritical, false);
    });
  });
}
