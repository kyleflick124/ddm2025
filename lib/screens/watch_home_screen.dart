import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/health_sensor_service.dart';
import '../services/watch_firebase_service.dart';
import '../providers/locale_provider.dart';

class WatchHomeScreen extends ConsumerStatefulWidget {
  const WatchHomeScreen({super.key});

  @override
  ConsumerState<WatchHomeScreen> createState() => _WatchHomeScreenState();
}

class _WatchHomeScreenState extends ConsumerState<WatchHomeScreen> {
  final HealthSensorService _sensorService = HealthSensorService();
  final WatchFirebaseService _firebaseService = WatchFirebaseService();
  final Battery _battery = Battery();
  
  int _heartRate = 0;
  int _spo2 = 98;
  int _steps = 0;
  double _temperature = 36.5;
  int _batteryLevel = 0;
  bool _isCharging = false;
  bool _isSending = false;
  bool _isEmergency = false;
  bool _isConnected = false;
  bool _fallDetected = false;
  bool _isLinked = false;
  Timer? _updateTimer;
  StreamSubscription? _batterySubscription;
  
  // Elder ID - loaded from SharedPreferences
  String _elderId = '';

  @override
  void initState() {
    super.initState();
    _loadElderId();
    _initBattery();
  }

  Future<void> _loadElderId() async {
    final prefs = await SharedPreferences.getInstance();
    final elderId = prefs.getString('elder_id');
    
    if (elderId != null && elderId.isNotEmpty) {
      setState(() {
        _elderId = elderId;
        _isLinked = true;
      });
      _startMonitoring();
    } else {
      // Not linked yet - show message but still allow usage
      setState(() {
        _elderId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
        _isLinked = false;
      });
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _batterySubscription?.cancel();
    _sensorService.dispose();
    super.dispose();
  }


  void _initBattery() async {
    // Get initial battery level
    _batteryLevel = await _battery.batteryLevel;
    
    // Listen to battery state changes
    _batterySubscription = _battery.onBatteryStateChanged.listen((state) {
      setState(() {
        _isCharging = state == BatteryState.charging || state == BatteryState.full;
      });
    });

    // Update battery level periodically
    Timer.periodic(const Duration(minutes: 1), (_) async {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
        });
      }
    });
  }

  void _startMonitoring() {
    // Start reading sensors
    _sensorService.startHeartRateMonitoring((rate) {
      setState(() => _heartRate = rate);
    });

    _sensorService.startStepCounting((steps) {
      setState(() => _steps = steps);
    });

    // Start fall detection
    _sensorService.startFallDetection(() {
      _onFallDetected();
    });

    // Simulate SpO2 and temperature readings (would come from real sensors)
    // These typically require specialized hardware APIs
    Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() {
          // Slight variations to show real-time updates
          _spo2 = 96 + (DateTime.now().second % 3);
          _temperature = 36.3 + (DateTime.now().second % 5) * 0.1;
        });
      }
    });

    // Send data to Firebase every 30 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendDataToFirebase();
    });

    // Initial send after 2 seconds
    Future.delayed(const Duration(seconds: 2), _sendDataToFirebase);
  }

  void _onFallDetected() {
    if (_fallDetected) return; // Prevent multiple triggers
    
    setState(() => _fallDetected = true);
    
    // Send fall alert to Firebase
    _firebaseService.sendEmergencyAlert(
      elderId: _elderId,
      type: 'fall',
      message: 'Possível queda detectada!',
    );

    // Show confirmation dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.orange.shade900,
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 8),
              TranslatedText('Queda Detectada?', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: TranslatedText(
            'Você está bem? Se não responder em 30 segundos, seu cuidador será alertado.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelFallAlert();
              },
              child: TranslatedText('Estou Bem', style: TextStyle(color: Colors.green)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmFallEmergency();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: TranslatedText('Preciso de Ajuda', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // Auto-confirm emergency after 30 seconds if no response
    Future.delayed(const Duration(seconds: 30), () {
      if (_fallDetected && mounted) {
        _confirmFallEmergency();
      }
    });
  }

  void _cancelFallAlert() {
    setState(() => _fallDetected = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TranslatedText('Alerta cancelado'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmFallEmergency() {
    _firebaseService.sendEmergencyAlert(
      elderId: _elderId,
      type: 'fall_confirmed',
      message: 'QUEDA CONFIRMADA - Assistência necessária!',
    );
    
    setState(() {
      _fallDetected = false;
      _isEmergency = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TranslatedText('Emergência enviada ao cuidador!'),
        backgroundColor: Colors.red,
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isEmergency = false);
      }
    });
  }

  Future<void> _sendDataToFirebase() async {
    if (_isSending) return;
    
    setState(() => _isSending = true);
    
    try {
      // Update battery level
      _batteryLevel = await _battery.batteryLevel;

      // Send health data
      await _firebaseService.sendHealthData(
        elderId: _elderId,
        heartRate: _heartRate,
        spo2: _spo2,
        steps: _steps,
        temperature: _temperature,
        bloodPressure: '120/80', // Would need separate device
      );

      // Send heart rate to history (for 24h chart)
      if (_heartRate > 0) {
        await _firebaseService.sendHeartRateToHistory(
          elderId: _elderId,
          heartRate: _heartRate,
        );
      }

      // Send location
      await _firebaseService.sendLocation(
        elderId: _elderId,
      );

      // Update device status with real battery
      await _firebaseService.updateDeviceStatus(
        elderId: _elderId,
        batteryLevel: _batteryLevel,
        isCharging: _isCharging,
      );

      setState(() => _isConnected = true);

      // Check for critical conditions and send alerts
      if (_heartRate > 120 || _heartRate < 50 && _heartRate > 0) {
        await _firebaseService.sendEmergencyAlert(
          elderId: _elderId,
          type: 'heart_rate',
          message: 'Frequência cardíaca anormal: $_heartRate bpm',
        );
      }

      if (_spo2 < 92) {
        await _firebaseService.sendEmergencyAlert(
          elderId: _elderId,
          type: 'spo2',
          message: 'Nível de oxigênio baixo: $_spo2%',
        );
      }

      if (_batteryLevel < 15) {
        await _firebaseService.sendEmergencyAlert(
          elderId: _elderId,
          type: 'battery',
          message: 'Bateria do relógio muito baixa: $_batteryLevel%',
        );
      }

    } catch (e) {
      setState(() => _isConnected = false);
      debugPrint('Failed to send data: $e');
    }
    
    setState(() => _isSending = false);
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
              // Connection status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: _isConnected ? Colors.green : Colors.grey,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isConnected ? 'Conectado' : 'Offline',
                    style: TextStyle(
                      fontSize: 10,
                      color: _isConnected ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isCharging ? Icons.battery_charging_full : Icons.battery_full,
                    color: _batteryLevel > 20 ? Colors.green : Colors.red,
                    size: 12,
                  ),
                  Text(
                    '$_batteryLevel%',
                    style: TextStyle(
                      fontSize: 10,
                      color: _batteryLevel > 20 ? Colors.white54 : Colors.red,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),

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
                    _heartRate > 0 ? '$_heartRate' : '--',
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
              
              const SizedBox(height: 4),

              // SpO2 and Temperature
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.air,
                    color: _spo2 < 94 ? Colors.orange : Colors.blue,
                    size: 16,
                  ),
                  Text(
                    ' $_spo2%',
                    style: TextStyle(
                      fontSize: 12,
                      color: _spo2 < 94 ? Colors.orange : Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.thermostat,
                    color: Colors.orange,
                    size: 16,
                  ),
                  Text(
                    ' ${_temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Steps Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_walk,
                    color: Colors.blue,
                    size: 16,
                  ),
                  Text(
                    ' $_steps passos',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Sync indicator
              if (_isSending)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.tealAccent,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Sincronizando...',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.tealAccent,
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 12),
              
              // Emergency Button
              GestureDetector(
                onLongPress: _triggerEmergency,
                child: Container(
                  width: 70,
                  height: 70,
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
                          size: 24,
                        ),
                        Text(
                          'SOS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isEmergency ? Colors.red : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 6),
              
              const Text(
                'Segure para emergência',
                style: TextStyle(
                  fontSize: 9,
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
