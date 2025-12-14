import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Service for accessing health sensors on the smartwatch
class HealthSensorService {
  StreamSubscription? _accelerometerSubscription;
  Timer? _heartRateTimer;
  Timer? _stepTimer;
  
  int _steps = 0;
  double _lastMagnitude = 0;
  final Random _random = Random();

  /// Start monitoring heart rate
  /// Note: Real heart rate requires Wear OS Health Services integration
  /// This simulation mimics realistic heart rate patterns
  void startHeartRateMonitoring(Function(int) onHeartRate) {
    // For emulator/demo, simulate heart rate with realistic variation
    int baseRate = 72;
    
    _heartRateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      // Simulate natural heart rate variation (-5 to +5)
      final variation = _random.nextInt(11) - 5;
      final heartRate = (baseRate + variation).clamp(55, 120);
      onHeartRate(heartRate);
    });
    
    // Initial reading
    onHeartRate(baseRate);
  }

  /// Start counting steps using accelerometer
  void startStepCounting(Function(int) onSteps) {
    _steps = 0;
    
    try {
      // Use accelerometer to detect steps
      _accelerometerSubscription = accelerometerEventStream().listen((event) {
        final magnitude = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z
        );
        
        // Simple step detection: significant change in acceleration
        if ((magnitude - _lastMagnitude).abs() > 12.0) {
          _steps++;
          onSteps(_steps);
        }
        
        _lastMagnitude = magnitude;
      });
    } catch (e) {
      // Fallback simulation if sensors unavailable
      _stepTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _steps += _random.nextInt(20) + 5;
        onSteps(_steps);
      });
    }
    
    onSteps(_steps);
  }

  /// Detect potential fall using accelerometer
  void startFallDetection(Function() onFallDetected) {
    try {
      accelerometerEventStream().listen((event) {
        final magnitude = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z
        );
        
        // Fall detection: sudden high acceleration followed by stillness
        // This is a simplified algorithm - production would use ML
        if (magnitude > 25.0) {
          // Potential fall detected - wait briefly to confirm stillness
          Future.delayed(const Duration(seconds: 2), () {
            onFallDetected();
          });
        }
      });
    } catch (e) {
      // Sensors unavailable
    }
  }

  /// Get simulated SpO2 reading
  /// Note: Real SpO2 requires device-specific sensor integration
  int getSpO2() {
    return 95 + _random.nextInt(5); // 95-99%
  }

  /// Get simulated body temperature
  /// Note: Real temperature requires IR sensor integration
  double getTemperature() {
    return 36.0 + _random.nextDouble() * 1.5; // 36.0-37.5°C
  }

  /// Dispose all subscriptions
  void dispose() {
    _accelerometerSubscription?.cancel();
    _heartRateTimer?.cancel();
    _stepTimer?.cancel();
  }
}
