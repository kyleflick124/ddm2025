import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:elder_monitor/providers/tracking_providers.dart';

void main() {
  group('TrackPoint Tests', () {
    test('should create TrackPoint with correct values', () {
      final timestamp = DateTime.now();
      final latLng = const LatLng(-23.5505, -46.6333);
      
      final trackPoint = TrackPoint(latLng, timestamp);
      
      expect(trackPoint.latLng.latitude, -23.5505);
      expect(trackPoint.latLng.longitude, -46.6333);
      expect(trackPoint.timestamp, timestamp);
    });

    test('should handle multiple TrackPoints', () {
      final points = [
        TrackPoint(const LatLng(-23.5505, -46.6333), DateTime.now()),
        TrackPoint(const LatLng(-23.5510, -46.6340), DateTime.now()),
        TrackPoint(const LatLng(-23.5515, -46.6350), DateTime.now()),
      ];
      
      expect(points.length, 3);
      expect(points[0].latLng.latitude, -23.5505);
      expect(points[2].latLng.latitude, -23.5515);
    });
  });

  group('MapControllerState Tests', () {
    test('should create default state with null current and empty history', () {
      final state = MapControllerState();
      
      expect(state.current, isNull);
      expect(state.history, isEmpty);
      expect(state.playing, false);
    });

    test('should create state with current position', () {
      const currentPos = LatLng(-23.5505, -46.6333);
      final state = MapControllerState(current: currentPos);
      
      expect(state.current, currentPos);
      expect(state.history, isEmpty);
    });

    test('should create state with history', () {
      final history = [
        TrackPoint(const LatLng(-23.5505, -46.6333), DateTime.now()),
        TrackPoint(const LatLng(-23.5510, -46.6340), DateTime.now()),
      ];
      final state = MapControllerState(history: history);
      
      expect(state.history.length, 2);
    });

    test('should create state with playing flag', () {
      final state = MapControllerState(playing: true);
      
      expect(state.playing, true);
    });
  });

  group('MapControllerNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should have initial empty state', () {
      final state = container.read(mapControllerProvider);
      
      expect(state.current, isNull);
      expect(state.history, isEmpty);
      expect(state.playing, false);
    });

    test('should set current position', () {
      const pos = LatLng(-23.5505, -46.6333);
      container.read(mapControllerProvider.notifier).setCurrent(pos);
      
      final state = container.read(mapControllerProvider);
      expect(state.current?.latitude, -23.5505);
      expect(state.current?.longitude, -46.6333);
    });

    test('should add point to history', () {
      final point = TrackPoint(const LatLng(-23.5505, -46.6333), DateTime.now());
      container.read(mapControllerProvider.notifier).addPoint(point);
      
      final state = container.read(mapControllerProvider);
      expect(state.history.length, 1);
      expect(state.current?.latitude, -23.5505);
    });

    test('should add multiple points to history', () {
      final notifier = container.read(mapControllerProvider.notifier);
      
      notifier.addPoint(TrackPoint(const LatLng(-23.5505, -46.6333), DateTime.now()));
      notifier.addPoint(TrackPoint(const LatLng(-23.5510, -46.6340), DateTime.now()));
      notifier.addPoint(TrackPoint(const LatLng(-23.5515, -46.6350), DateTime.now()));
      
      final state = container.read(mapControllerProvider);
      expect(state.history.length, 3);
      // Current should be the last added point
      expect(state.current?.latitude, -23.5515);
    });

    test('should set playing state', () {
      container.read(mapControllerProvider.notifier).setPlaying(true);
      
      final state = container.read(mapControllerProvider);
      expect(state.playing, true);
    });

    test('should toggle playing state', () {
      final notifier = container.read(mapControllerProvider.notifier);
      
      notifier.setPlaying(true);
      expect(container.read(mapControllerProvider).playing, true);
      
      notifier.setPlaying(false);
      expect(container.read(mapControllerProvider).playing, false);
    });

    test('should clear history', () {
      final notifier = container.read(mapControllerProvider.notifier);
      
      notifier.addPoint(TrackPoint(const LatLng(-23.5505, -46.6333), DateTime.now()));
      notifier.addPoint(TrackPoint(const LatLng(-23.5510, -46.6340), DateTime.now()));
      
      expect(container.read(mapControllerProvider).history.length, 2);
      
      notifier.clearHistory();
      
      final state = container.read(mapControllerProvider);
      expect(state.history, isEmpty);
      expect(state.playing, false);
    });

    test('should maintain current position after clearing history', () {
      final notifier = container.read(mapControllerProvider.notifier);
      
      notifier.addPoint(TrackPoint(const LatLng(-23.5505, -46.6333), DateTime.now()));
      notifier.clearHistory();
      
      final state = container.read(mapControllerProvider);
      expect(state.current?.latitude, -23.5505); // Current is preserved
      expect(state.history, isEmpty);
    });
  });
}
