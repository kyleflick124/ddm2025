import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:elder_monitor/providers/geofence_provider.dart';

void main() {
  group('GeofenceArea Tests', () {
    test('should create GeofenceArea with correct values', () {
      final geofence = GeofenceArea(
        id: 'home-1',
        center: const LatLng(-23.5505, -46.6333),
        radius: 100.0,
        name: 'Casa',
      );
      
      expect(geofence.id, 'home-1');
      expect(geofence.center.latitude, -23.5505);
      expect(geofence.center.longitude, -46.6333);
      expect(geofence.radius, 100.0);
      expect(geofence.name, 'Casa');
    });

    test('should handle different radius values', () {
      final small = GeofenceArea(
        id: '1', center: const LatLng(0, 0), radius: 10.0, name: 'Small');
      final large = GeofenceArea(
        id: '2', center: const LatLng(0, 0), radius: 1000.0, name: 'Large');
      
      expect(small.radius, 10.0);
      expect(large.radius, 1000.0);
    });
  });

  group('GeofenceNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should have initial empty state', () {
      final geofences = container.read(geofenceProvider);
      expect(geofences, isEmpty);
    });

    test('should add a geofence', () {
      final geofence = GeofenceArea(
        id: 'home-1',
        center: const LatLng(-23.5505, -46.6333),
        radius: 100.0,
        name: 'Casa',
      );
      
      container.read(geofenceProvider.notifier).add(geofence);
      
      final geofences = container.read(geofenceProvider);
      expect(geofences.length, 1);
      expect(geofences.first.name, 'Casa');
    });

    test('should add multiple geofences', () {
      final notifier = container.read(geofenceProvider.notifier);
      
      notifier.add(GeofenceArea(
        id: 'home', center: const LatLng(-23.5505, -46.6333),
        radius: 100.0, name: 'Casa'));
      notifier.add(GeofenceArea(
        id: 'work', center: const LatLng(-23.5600, -46.6500),
        radius: 200.0, name: 'Trabalho'));
      notifier.add(GeofenceArea(
        id: 'park', center: const LatLng(-23.5700, -46.6600),
        radius: 150.0, name: 'Parque'));
      
      final geofences = container.read(geofenceProvider);
      expect(geofences.length, 3);
    });

    test('should remove a geofence by id', () {
      final notifier = container.read(geofenceProvider.notifier);
      
      notifier.add(GeofenceArea(
        id: 'home', center: const LatLng(-23.5505, -46.6333),
        radius: 100.0, name: 'Casa'));
      notifier.add(GeofenceArea(
        id: 'work', center: const LatLng(-23.5600, -46.6500),
        radius: 200.0, name: 'Trabalho'));
      
      notifier.remove('home');
      
      final geofences = container.read(geofenceProvider);
      expect(geofences.length, 1);
      expect(geofences.first.id, 'work');
    });

    test('should update a geofence', () {
      final notifier = container.read(geofenceProvider.notifier);
      
      notifier.add(GeofenceArea(
        id: 'home', center: const LatLng(-23.5505, -46.6333),
        radius: 100.0, name: 'Casa'));
      
      // Update with new values
      notifier.update(GeofenceArea(
        id: 'home', center: const LatLng(-23.5510, -46.6340),
        radius: 150.0, name: 'Casa Nova'));
      
      final geofences = container.read(geofenceProvider);
      expect(geofences.length, 1);
      expect(geofences.first.name, 'Casa Nova');
      expect(geofences.first.radius, 150.0);
      expect(geofences.first.center.latitude, -23.5510);
    });

    test('should not affect other geofences when updating one', () {
      final notifier = container.read(geofenceProvider.notifier);
      
      notifier.add(GeofenceArea(
        id: 'home', center: const LatLng(-23.5505, -46.6333),
        radius: 100.0, name: 'Casa'));
      notifier.add(GeofenceArea(
        id: 'work', center: const LatLng(-23.5600, -46.6500),
        radius: 200.0, name: 'Trabalho'));
      
      notifier.update(GeofenceArea(
        id: 'home', center: const LatLng(-23.5510, -46.6340),
        radius: 150.0, name: 'Casa Atualizada'));
      
      final geofences = container.read(geofenceProvider);
      final work = geofences.firstWhere((g) => g.id == 'work');
      
      expect(work.name, 'Trabalho');
      expect(work.radius, 200.0);
    });

    test('should handle removing non-existent geofence gracefully', () {
      final notifier = container.read(geofenceProvider.notifier);
      
      notifier.add(GeofenceArea(
        id: 'home', center: const LatLng(-23.5505, -46.6333),
        radius: 100.0, name: 'Casa'));
      
      // Remove non-existent id
      notifier.remove('non-existent');
      
      final geofences = container.read(geofenceProvider);
      expect(geofences.length, 1); // Original still there
    });

    test('should maintain order when adding geofences', () {
      final notifier = container.read(geofenceProvider.notifier);
      
      notifier.add(GeofenceArea(
        id: '1', center: const LatLng(0, 0), radius: 100.0, name: 'First'));
      notifier.add(GeofenceArea(
        id: '2', center: const LatLng(0, 0), radius: 100.0, name: 'Second'));
      notifier.add(GeofenceArea(
        id: '3', center: const LatLng(0, 0), radius: 100.0, name: 'Third'));
      
      final geofences = container.read(geofenceProvider);
      expect(geofences[0].name, 'First');
      expect(geofences[1].name, 'Second');
      expect(geofences[2].name, 'Third');
    });
  });
}
