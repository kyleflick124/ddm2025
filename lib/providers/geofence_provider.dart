import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeofenceArea {
  final String id;
  final LatLng center;
  final double radius; // meters
  final String name;
  GeofenceArea({required this.id, required this.center, required this.radius, required this.name});
}

final geofenceProvider = StateNotifierProvider<GeofenceNotifier, List<GeofenceArea>>((ref) {
  return GeofenceNotifier();
});

class GeofenceNotifier extends StateNotifier<List<GeofenceArea>> {
  GeofenceNotifier() : super([]);

  void add(GeofenceArea g) {
    state = [...state, g];
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void update(GeofenceArea g) {
    state = state.map((e) => e.id == g.id ? g : e).toList();
  }
}
