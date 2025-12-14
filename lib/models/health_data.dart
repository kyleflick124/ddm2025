import 'dart:math';

/// Model representing health data from the smartwatch
class HealthData {
  /// Heart rate in beats per minute
  final int heartRate;
  
  /// Blood oxygen saturation percentage
  final int spo2;
  
  /// Daily step count
  final int steps;
  
  /// Body temperature in Celsius
  final double temperature;
  
  /// Blood pressure as string (e.g., "120/80")
  final String bloodPressure;
  
  /// Timestamp when this data was collected
  final DateTime timestamp;

  const HealthData({
    required this.heartRate,
    required this.spo2,
    required this.steps,
    required this.temperature,
    required this.bloodPressure,
    required this.timestamp,
  });

  /// Check if heart rate is within normal range (50-110 bpm)
  bool get isHeartRateNormal => heartRate >= 50 && heartRate <= 110;

  /// Check if SpO2 is within normal range (>= 94%)
  bool get isSpo2Normal => spo2 >= 94;

  /// Check if temperature is within normal range (35.5-37.5°C)
  bool get isTemperatureNormal => temperature >= 35.5 && temperature <= 37.5;

  /// Check if any vital sign is in critical condition
  bool get isCritical {
    return heartRate < 50 || heartRate > 150 || spo2 < 90 || temperature > 39.0;
  }

  /// Serialize to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'heartRate': heartRate,
      'spo2': spo2,
      'steps': steps,
      'temperature': temperature,
      'bloodPressure': bloodPressure,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Deserialize from JSON (Firebase)
  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      heartRate: json['heartRate'] as int,
      spo2: json['spo2'] as int,
      steps: json['steps'] as int,
      temperature: (json['temperature'] as num).toDouble(),
      bloodPressure: json['bloodPressure'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Create a copy with optional updated fields
  HealthData copyWith({
    int? heartRate,
    int? spo2,
    int? steps,
    double? temperature,
    String? bloodPressure,
    DateTime? timestamp,
  }) {
    return HealthData(
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      steps: steps ?? this.steps,
      temperature: temperature ?? this.temperature,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'HealthData(heartRate: $heartRate, spo2: $spo2, steps: $steps, '
        'temperature: $temperature, bloodPressure: $bloodPressure)';
  }
}
