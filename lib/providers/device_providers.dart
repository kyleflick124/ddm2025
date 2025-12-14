import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_sync_service.dart';

/// Device status model
class DeviceStatus {
  final String deviceId;
  final DateTime lastUpdate;
  final int batteryLevel; // percent
  final bool gpsSignal;
  final bool emergencyMode;

  DeviceStatus({
    required this.deviceId,
    required this.lastUpdate,
    required this.batteryLevel,
    required this.gpsSignal,
    required this.emergencyMode,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      deviceId: json['deviceId'] ?? 'unknown',
      lastUpdate: DateTime.tryParse(json['lastSync'] ?? '') ?? DateTime.now(),
      batteryLevel: json['batteryLevel'] ?? 0,
      gpsSignal: json['gpsSignal'] ?? true,
      emergencyMode: json['emergencyMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'lastSync': lastUpdate.toIso8601String(),
    'batteryLevel': batteryLevel,
    'gpsSignal': gpsSignal,
    'emergencyMode': emergencyMode,
  };
}

final deviceStatusProvider = StateProvider<DeviceStatus?>((ref) => null);

/// Update interval settings (in seconds)
/// Supports: 60 (1 min), 300 (5 min), 600 (10 min), 1800 (30 min)
final updateIntervalProvider = StateNotifierProvider<UpdateIntervalNotifier, int>((ref) {
  return UpdateIntervalNotifier();
});

class UpdateIntervalNotifier extends StateNotifier<int> {
  UpdateIntervalNotifier() : super(300) { // Default: 5 minutes
    _loadInterval();
  }

  /// Available intervals in seconds
  static const List<int> availableIntervals = [60, 300, 600, 1800];
  
  /// Interval labels in Portuguese
  static const Map<int, String> intervalLabels = {
    60: 'Tempo real (1 min)',
    300: 'Normal (5 min)',
    600: 'Economia (10 min)',
    1800: 'Ultra economia (30 min)',
  };

  Future<void> _loadInterval() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('updateInterval');
    if (saved != null && availableIntervals.contains(saved)) {
      state = saved;
    }
  }

  /// Set update interval and save to preferences
  Future<void> setInterval(int seconds) async {
    if (!availableIntervals.contains(seconds)) return;
    
    state = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('updateInterval', seconds);
  }

  /// Get optimal interval based on battery level
  static int getOptimalInterval(int batteryLevel) {
    if (batteryLevel < 20) return 1800; // Ultra saving
    if (batteryLevel < 40) return 600;  // Economy
    if (batteryLevel < 60) return 300;  // Normal
    return 60; // Real-time when battery is good
  }

  /// Set interval remotely via Firebase
  Future<void> setRemoteInterval(String elderId, int seconds) async {
    // This would sync to Firebase for smartwatch to pick up
    if (!availableIntervals.contains(seconds)) return;
    
    final syncService = FirebaseSyncService();
    // In real implementation, this would update a settings path
    // For now, we'll use the device path
    await syncService.saveGeofence(
      elderId, 
      'settings', 
      0, 0, 
      seconds.toDouble(), 
      'updateInterval',
    );
  }
}

/// Emergency mode provider
final emergencyModeProvider = StateNotifierProvider<EmergencyModeNotifier, bool>((ref) {
  return EmergencyModeNotifier();
});

class EmergencyModeNotifier extends StateNotifier<bool> {
  EmergencyModeNotifier() : super(false);

  void activate() {
    state = true;
  }

  void deactivate() {
    state = false;
  }

  void toggle() {
    state = !state;
  }
}
