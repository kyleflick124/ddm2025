import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../models/health_data.dart';
import '../services/firebase_sync_service.dart';
import 'dart:async';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  HealthData? _healthData;
  Map<String, dynamic>? _deviceStatus;
  bool _isLoading = true;
  
  final String _elderId = 'elder_demo';
  final FirebaseSyncService _syncService = FirebaseSyncService();
  StreamSubscription? _healthSubscription;
  StreamSubscription? _deviceSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToData();
  }

  @override
  void dispose() {
    _healthSubscription?.cancel();
    _deviceSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToData() {
    // Listen to health data from Firebase
    _healthSubscription = _syncService
        .listenToHealthData(_elderId)
        .listen((data) {
      if (data != null) {
        setState(() {
          _healthData = data;
          _isLoading = false;
        });
      }
    });

    // Listen to device status
    _deviceSubscription = _syncService
        .listenToDeviceStatus(_elderId)
        .listen((status) {
      if (status != null) {
        setState(() {
          _deviceStatus = status;
        });
      }
    });

    // Fallback to default data after timeout
    Future.delayed(const Duration(seconds: 3), () {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
          _healthData = HealthData(
            heartRate: 76,
            spo2: 98,
            steps: 4523,
            temperature: 36.8,
            bloodPressure: '120/80',
            timestamp: DateTime.now(),
          );
          _deviceStatus = {
            'batteryLevel': 78,
            'isCharging': false,
            'lastSync': DateTime.now().toIso8601String(),
          };
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final healthData = _healthData ?? HealthData(
      heartRate: 76,
      spo2: 98,
      steps: 4523,
      temperature: 36.8,
      bloodPressure: '120/80',
      timestamp: DateTime.now(),
    );

    final batteryLevel = _deviceStatus?['batteryLevel'] ?? 78;
    final isCharging = _deviceStatus?['isCharging'] ?? false;

    final healthItems = [
      _HealthMetric('Batimentos', '${healthData.heartRate} bpm', Icons.favorite, 
          healthData.isHeartRateNormal ? Colors.green : Colors.redAccent),
      _HealthMetric('Passos', '${healthData.steps}', Icons.directions_walk, Colors.blue),
      _HealthMetric('Oxigênio', '${healthData.spo2}%', Icons.air, 
          healthData.isSpo2Normal ? Colors.green : Colors.orange),
      _HealthMetric('Temp.', '${healthData.temperature}°C', Icons.thermostat, 
          healthData.isTemperatureNormal ? Colors.orange : Colors.red),
      _HealthMetric('Pressão', healthData.bloodPressure, Icons.monitor_heart, Colors.purple),
      _HealthMetric('Status', healthData.isCritical ? 'Crítico' : 'Normal', Icons.watch, 
          healthData.isCritical ? Colors.red : Colors.teal),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Painel de Monitoramento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const TranslatedText(
          'Modo Emergência',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          // Create emergency alert in Firebase
          _syncService.createAlert(
            _elderId,
            'Emergência acionada',
            'O cuidador acionou o modo de emergência.',
            meta: {'priority': 'critical'},
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: TranslatedText('⚠️ Emergência acionada! Contatando familiares...'),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Health Indicators
                  const TranslatedText(
                    'Indicadores de Saúde',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmall = constraints.maxWidth < 500;
                      final itemWidth = isSmall
                          ? constraints.maxWidth / 2 - 12
                          : constraints.maxWidth / 6 - 8;

                      return Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in healthItems)
                            Container(
                              width: itemWidth,
                              decoration: BoxDecoration(
                                color: item.color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: item.color.withOpacity(0.3)),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(item.icon, color: item.color, size: 26),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.value,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: item.color,
                                      fontSize: 13,
                                    ),
                                  ),
                                  TranslatedText(
                                    item.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Device Status Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const TranslatedText('Último Check-in'),
                              Text(
                                _formatLastSync(),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const TranslatedText('Bateria do Relógio'),
                              Row(
                                children: [
                                  Icon(
                                    isCharging ? Icons.battery_charging_full : Icons.battery_full,
                                    color: batteryLevel > 20 ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$batteryLevel%',
                                    style: TextStyle(
                                      color: batteryLevel > 20 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Activity Chart
                  const TranslatedText(
                    'Resumo de Atividade',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}h',
                                    style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 10,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}m',
                                    style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: Colors.blueAccent,
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blueAccent.withOpacity(0.2),
                            ),
                            spots: const [
                              FlSpot(0, 10),
                              FlSpot(1, 20),
                              FlSpot(2, 35),
                              FlSpot(3, 30),
                              FlSpot(4, 40),
                              FlSpot(5, 45),
                              FlSpot(6, 50),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatLastSync() {
    final lastSync = _deviceStatus?['lastSync'];
    if (lastSync == null) return 'Desconhecido';
    
    try {
      final dt = DateTime.parse(lastSync);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Agora';
      if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
      return 'Há ${diff.inHours} h';
    } catch (e) {
      return 'Desconhecido';
    }
  }
}

class _HealthMetric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _HealthMetric(this.title, this.value, this.icon, this.color);
}
