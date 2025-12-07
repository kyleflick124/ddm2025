import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/health_sensor_service.dart';
import '../services/watch_firebase_service.dart';

class WatchHomeScreen extends ConsumerStatefulWidget {
  const WatchHomeScreen({super.key});

  @override
  ConsumerState<WatchHomeScreen> createState() => _WatchHomeScreenState();
}

class _WatchHomeScreenState extends ConsumerState<WatchHomeScreen> {
  final HealthSensorService _sensorService = HealthSensorService();
  final WatchFirebaseService _firebaseService = WatchFirebaseService();
  
  int _heartRate = 0;
  int _steps = 0;
  bool _isSending = false;
  bool _isEmergency = false;
  Timer? _updateTimer;
  
  // Elder ID - would be configured during setup
  final String _elderId = 'elder_demo';

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _sensorService.dispose();
    super.dispose();
  }

  void _startMonitoring() {
    // Start reading sensors
    _sensorService.startHeartRateMonitoring((rate) {
      setState(() => _heartRate = rate);
    });

    _sensorService.startStepCounting((steps) {
      setState(() => _steps = steps);
    });

    // Send data to Firebase every 30 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendDataToFirebase();
    });

    // Initial send
    Future.delayed(const Duration(seconds: 5), _sendDataToFirebase);
  }

  Future<void> _sendDataToFirebase() async {
    if (_isSending) return;
    
    setState(() => _isSending = true);
    
    try {
      await _firebaseService.sendHealthData(
        elderId: _elderId,
        heartRate: _heartRate,
        spo2: 98, // Would come from sensor
        steps: _steps,
        temperature: 36.5, // Would come from sensor
        bloodPressure: '120/80', // Would need separate device
      );

      await _firebaseService.sendLocation(
        elderId: _elderId,
      );

      await _firebaseService.updateDeviceStatus(
        elderId: _elderId,
        batteryLevel: await _getBatteryLevel(),
      );
    } catch (e) {
      debugPrint('Failed to send data: $e');
    }
    
    setState(() => _isSending = false);
  }

  Future<int> _getBatteryLevel() async {
    // In real app, use battery_plus package
    return 78;
  }

  void _triggerEmergency() {
    setState(() => _isEmergency = true);
    
    _firebaseService.sendEmergencyAlert(
      elderId: _elderId,
      type: 'manual',
      message: 'O idoso acionou o botão de emergência!',
    );

    // Visual/haptic feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 EMERGÊNCIA ENVIADA!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );

    // Reset after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isEmergency = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isRound = screenSize.width == screenSize.height;
    
    return Scaffold(
      backgroundColor: _isEmergency ? Colors.red.shade900 : Colors.black,
      body: Center(
        child: Container(
          width: screenSize.width,
          height: screenSize.height,
          decoration: BoxDecoration(
            shape: isRound ? BoxShape.circle : BoxShape.rectangle,
            color: _isEmergency ? Colors.red.shade900 : Colors.black,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Heart Rate Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    color: _heartRate > 100 || _heartRate < 50 
                        ? Colors.red 
                        : Colors.redAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_heartRate',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    ' bpm',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Steps Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_walk,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_steps passos',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Sync indicator
              if (_isSending)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.tealAccent,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Enviando...',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.tealAccent,
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 20),
              
              // Emergency Button
              GestureDetector(
                onLongPress: _triggerEmergency,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isEmergency ? Colors.white : Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: _isEmergency ? Colors.red : Colors.white,
                          size: 28,
                        ),
                        Text(
                          'SOS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isEmergency ? Colors.red : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Segure para emergência',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
