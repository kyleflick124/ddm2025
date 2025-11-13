import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simplified device status model for the watch
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
}

final deviceStatusProvider = StateProvider<DeviceStatus?>((ref) => null);

// Device settings (update rate in seconds)
final deviceSettingsProvider = StateProvider<int>((ref) => 300);
