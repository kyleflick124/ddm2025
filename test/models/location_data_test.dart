import 'package:flutter_test/flutter_test.dart';
import 'package:elder_monitor/models/location_data.dart';

void main() {
  group('LocationData Model Tests', () {
    test('should create LocationData with all fields', () {
      final timestamp = DateTime.now();
      final location = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 10.5,
        timestamp: timestamp,
      );
      
      expect(location.latitude, -23.5505);
      expect(location.longitude, -46.6333);
      expect(location.accuracy, 10.5);
      expect(location.timestamp, timestamp);
    });

    test('should handle different coordinate values', () {
      // São Paulo
      final sp = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      // New York
      final ny = LocationData(
        latitude: 40.7128,
        longitude: -74.0060,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      // Tokyo
      final tokyo = LocationData(
        latitude: 35.6762,
        longitude: 139.6503,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      expect(sp.latitude, isNegative);
      expect(ny.latitude, isPositive);
      expect(tokyo.longitude, isPositive);
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
      final location = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 10.5,
        timestamp: timestamp,
      );
      
      final json = location.toJson();
      
      expect(json['latitude'], -23.5505);
      expect(json['longitude'], -46.6333);
      expect(json['accuracy'], 10.5);
      expect(json['timestamp'], timestamp.toIso8601String());
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'latitude': -23.5505,
        'longitude': -46.6333,
        'accuracy': 10.5,
        'timestamp': '2024-01-15T10:30:00.000',
      };
      
      final location = LocationData.fromJson(json);
      
      expect(location.latitude, -23.5505);
      expect(location.longitude, -46.6333);
      expect(location.accuracy, 10.5);
    });

    test('should calculate distance between two points', () {
      final point1 = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      final point2 = LocationData(
        latitude: -23.5510,
        longitude: -46.6340,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      final distance = point1.distanceTo(point2);
      
      // Should be a small distance (less than 100 meters)
      expect(distance, greaterThan(0));
      expect(distance, lessThan(100));
    });

    test('should detect if location is within radius', () {
      final center = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      final nearPoint = LocationData(
        latitude: -23.5506,
        longitude: -46.6334,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      final farPoint = LocationData(
        latitude: -23.5600,
        longitude: -46.6500,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      expect(nearPoint.isWithinRadius(center, 100), true);
      expect(farPoint.isWithinRadius(center, 100), false);
    });

    test('should handle edge case coordinates', () {
      // North Pole
      final northPole = LocationData(
        latitude: 90.0,
        longitude: 0.0,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      // South Pole
      final southPole = LocationData(
        latitude: -90.0,
        longitude: 0.0,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      // Date line
      final dateLine = LocationData(
        latitude: 0.0,
        longitude: 180.0,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      expect(northPole.latitude, 90.0);
      expect(southPole.latitude, -90.0);
      expect(dateLine.longitude, 180.0);
    });

    test('should indicate if location is accurate', () {
      final accurate = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      final inaccurate = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 100.0,
        timestamp: DateTime.now(),
      );
      
      expect(accurate.isAccurate(), true);
      expect(inaccurate.isAccurate(), false);
    });
  });
}
