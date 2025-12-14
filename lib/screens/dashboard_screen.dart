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
  List<Map<String, dynamic>> _heartRateHistory = [];
  bool _isLoading = true;
  int? _touchedIndex;
  
  final String _elderId = 'elder_demo';
  final FirebaseSyncService _syncService = FirebaseSyncService();
  StreamSubscription? _healthSubscription;
  StreamSubscription? _deviceSubscription;
  StreamSubscription? _historySubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToData();
  }

  @override
  void dispose() {
    _healthSubscription?.cancel();
    _deviceSubscription?.cancel();
    _historySubscription?.cancel();
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

    // Listen to heart rate history for chart
    _historySubscription = _syncService
        .listenToHeartRateHistory(_elderId)
        .listen((history) {
      setState(() {
        _heartRateHistory = history;
      });
    });

    // No simulated fallback - just set loading to false
    Future.delayed(const Duration(seconds: 5), () {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if we have real data
    final hasData = _healthData != null;
    final healthData = _healthData;

    final batteryLevel = _deviceStatus?['batteryLevel'] ?? 0;
    final isCharging = _deviceStatus?['isCharging'] ?? false;

    // Health items only if we have data
    final healthItems = hasData ? [
      _HealthMetric('Batimentos', '${healthData!.heartRate} bpm', Icons.favorite, 
          healthData.isHeartRateNormal ? Colors.green : Colors.redAccent),
      _HealthMetric('Passos', '${healthData.steps}', Icons.directions_walk, Colors.blue),
      _HealthMetric('Oxigênio', '${healthData.spo2}%', Icons.air, 
          healthData.isSpo2Normal ? Colors.green : Colors.orange),
      _HealthMetric('Temp.', '${healthData.temperature}°C', Icons.thermostat, 
          healthData.isTemperatureNormal ? Colors.orange : Colors.red),
      _HealthMetric('Pressão', healthData.bloodPressure, Icons.monitor_heart, Colors.purple),
      _HealthMetric('Status', healthData.isCritical ? 'Crítico' : 'Normal', Icons.watch, 
          healthData.isCritical ? Colors.red : Colors.teal),
    ] : <_HealthMetric>[];

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

                      if (healthItems.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.watch_off, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              TranslatedText(
                                'Aguardando dados do smartwatch...',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              TranslatedText(
                                'Os dados serão exibidos quando o relógio estiver conectado',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in healthItems)
                            Container(
                              width: itemWidth,
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: item.color.withValues(alpha: 0.3)),
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

                  // Interactive Heart Rate Chart
                  _buildHeartRateChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeartRateChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const TranslatedText(
              'Histórico de Batimentos (24h)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (_heartRateHistory.isNotEmpty)
              Text(
                '${_heartRateHistory.length} registros',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_heartRateHistory.isEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  TranslatedText(
                    'Aguardando dados de batimentos...',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  TranslatedText(
                    'O gráfico aparecerá quando o relógio enviar dados',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                // Touched point info
                if (_touchedIndex != null && _touchedIndex! < _heartRateHistory.length)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _getHeartRateColor(_heartRateHistory[_touchedIndex!]['heartRate'] as int),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_heartRateHistory[_touchedIndex!]['heartRate']} bpm - ${_formatChartTime(_heartRateHistory[_touchedIndex!]['timestamp'] as String)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                // Chart
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 20,
                        getDrawingHorizontalLine: (value) {
                          // Highlight critical zones
                          if (value == 120 || value == 50) {
                            return FlLine(
                              color: Colors.red.withValues(alpha: 0.5),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            );
                          }
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: _getChartInterval(),
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < _heartRateHistory.length) {
                                final timestamp = _heartRateHistory[index]['timestamp'] as String;
                                return Transform.rotate(
                                  angle: -0.5,
                                  child: Text(
                                    _formatChartTimeShort(timestamp),
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 20,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: value > 120 || value < 50 
                                      ? Colors.red 
                                      : Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      minY: 40,
                      maxY: 140,
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchCallback: (event, response) {
                          if (response?.lineBarSpots != null && 
                              response!.lineBarSpots!.isNotEmpty) {
                            setState(() {
                              _touchedIndex = response.lineBarSpots!.first.spotIndex;
                            });
                          }
                        },
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (spot) => Colors.black87,
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final hr = spot.y.toInt();
                              return LineTooltipItem(
                                '$hr bpm',
                                TextStyle(
                                  color: _getHeartRateColor(hr),
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: Colors.redAccent,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              final hr = spot.y.toInt();
                              final isCritical = hr > 120 || hr < 50;
                              return FlDotCirclePainter(
                                radius: isCritical ? 5 : 3,
                                color: _getHeartRateColor(hr),
                                strokeWidth: isCritical ? 2 : 1,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.redAccent.withValues(alpha: 0.3),
                                Colors.redAccent.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          spots: _buildChartSpots(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Legend
        if (_heartRateHistory.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Normal (50-120)'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red, 'Crítico'),
              ],
            ),
          ),
      ],
    );
  }

  List<FlSpot> _buildChartSpots() {
    return _heartRateHistory.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final hr = (entry.value['heartRate'] as int).toDouble();
      return FlSpot(index, hr);
    }).toList();
  }

  double _getChartInterval() {
    final count = _heartRateHistory.length;
    if (count <= 10) return 1;
    if (count <= 30) return 5;
    if (count <= 60) return 10;
    return (count / 6).roundToDouble();
  }

  Color _getHeartRateColor(int hr) {
    if (hr > 120 || hr < 50) return Colors.red;
    if (hr > 100 || hr < 60) return Colors.orange;
    return Colors.green;
  }

  String _formatChartTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _formatChartTimeShort(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.hour}h';
    } catch (_) {
      return '';
    }
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
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
