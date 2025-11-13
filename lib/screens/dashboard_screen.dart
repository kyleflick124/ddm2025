import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthData = [
      _HealthMetric('Batimentos', '76 bpm', Icons.favorite, Colors.redAccent),
      _HealthMetric('Passos', '4.523', Icons.directions_walk, Colors.blue),
      _HealthMetric('Sono', '6h 45m', Icons.bedtime, Colors.indigo),
      _HealthMetric('Temp.', '36.8°C', Icons.thermostat, Colors.orange),
      _HealthMetric('Pressão', '120/80', Icons.monitor_heart, Colors.purple),
      _HealthMetric('Modo', 'Normal', Icons.watch, Colors.teal),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Monitoramento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const Text(
          'Modo Emergência',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Emergência acionada! Contatando familiares...'),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Indicadores de Saúde ---
            Text(
              'Indicadores de Saúde',
              style: Theme.of(context).textTheme.titleLarge,
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
                    for (final item in healthData)
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
                            Text(
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

            // --- Card de Status do Dispositivo ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Último Check-in'),
                        Text('Há 5 minutos', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Bateria do Relógio'),
                        Text('78%', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Gráfico de Atividade ---
            Text(
              'Resumo de Atividade',
              style: Theme.of(context).textTheme.titleLarge,
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
}

class _HealthMetric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _HealthMetric(this.title, this.value, this.icon, this.color);
}
