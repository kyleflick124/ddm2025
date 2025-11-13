import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Recent point model
class TrackPoint {
  final LatLng latLng;
  final DateTime timestamp;
  TrackPoint(this.latLng, this.timestamp);
}

// Map controller state
class MapControllerState {
  final LatLng? current;
  final List<TrackPoint> history;
  final bool playing;
  MapControllerState({this.current, this.history = const [], this.playing = false});
}

final mapControllerProvider = StateNotifierProvider<MapControllerNotifier, MapControllerState>((ref) {
  return MapControllerNotifier();
});

class MapControllerNotifier extends StateNotifier<MapControllerState> {
  MapControllerNotifier() : super(MapControllerState());

  void setCurrent(LatLng pos) {
    state = MapControllerState(current: pos, history: state.history, playing: state.playing);
  }

  void addPoint(TrackPoint p) {
    final newHist = [...state.history, p];
    state = MapControllerState(current: p.latLng, history: newHist, playing: state.playing);
  }

  void setPlaying(bool playing) {
    state = MapControllerState(current: state.current, history: state.history, playing: playing);
  }

  void clearHistory() {
    state = MapControllerState(current: state.current, history: [], playing: false);
  }
}
