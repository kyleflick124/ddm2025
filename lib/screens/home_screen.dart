import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/elder_provider.dart';
import '../models/health_data.dart';
import '../services/firebase_sync_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _MenuItem {
  final String title;
  final IconData icon;
  final String route;
  _MenuItem(this.title, this.icon, this.route);
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Firebase health data
  HealthData? _healthData;
  bool _insideGeofence = true;
  DateTime _lastUpdate = DateTime.now();
  bool _isLoading = true;

  // Firebase
  String get _elderId => ref.read(activeElderIdProvider) ?? 'elder_demo';
  final FirebaseSyncService _syncService = FirebaseSyncService();
  StreamSubscription? _healthSubscription;

  // UI / timer
  int _updateInterval = 5;

  final List<_MenuItem> menuItems = [
    _MenuItem('Painel', Icons.dashboard, '/dashboard'),
    _MenuItem('Alertas', Icons.notifications, '/alerts'),
    _MenuItem('Dispositivo', Icons.watch, '/device'),
    _MenuItem('Mapa', Icons.map, '/map'),
  ];

  // =========================
  // LIFECYCLE
  // =========================

  @override
  void initState() {
    super.initState();
    _subscribeToHealthData();
  }

  @override
  void dispose() {
    _healthSubscription?.cancel();
    super.dispose();
  }

  // =========================
  // FIREBASE
  // =========================

  void _subscribeToHealthData() {
    _healthSubscription = _syncService
        .listenToHealthData(_elderId)
        .listen((healthData) {
      if (healthData != null) {
        setState(() {
          _healthData = healthData;
          _lastUpdate = healthData.timestamp;
          _isLoading = false;
        });
      }
    });

    // fallback loading timeout
    Future.delayed(const Duration(seconds: 5), () {
      if (_isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _refreshStatus() {
    setState(() {
      _lastUpdate = DateTime.now();
    });

    _syncService.getHealthData(_elderId).then((data) {
      if (data != null) {
        setState(() {
          _healthData = data;
          _lastUpdate = data.timestamp;
        });
      }
    });
  }

  String _timeSinceUpdate() {
    final diff = DateTime.now().difference(_lastUpdate);
    if (diff.inMinutes < 1) return 'Atualizado há poucos segundos';
    if (diff.inMinutes < 60) return 'Atualizado há ${diff.inMinutes} min';
    return 'Atualizado há ${diff.inHours} h';
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final bool isDark = themeMode == ThemeMode.dark;
    final bool isWide = MediaQuery.of(context).size.width > 700;
    final crossAxisCount = isWide ? 4 : 2;

    final cardTextColor = isDark ? Colors.white : Colors.black87;

    final hasData = _healthData != null;
    final heartRate = _healthData?.heartRate ?? 0;
    final spo2 = _healthData?.spo2 ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Monitoramento de Idosos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(context, '/profile', (r) => r.isFirst),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(context, '/settings', (r) => r.isFirst),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TranslatedText(
                      'Resumo do Idoso Monitorado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cardTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isLoading)
                      const CircularProgressIndicator()
                    else if (!hasData)
                      const TranslatedText('Aguardando dados do smartwatch...')
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatusItem(
                            icon: Icons.favorite,
                            label: 'Batimentos',
                            value: '$heartRate bpm',
                            color: heartRate > 110 || heartRate < 50
                                ? Colors.red
                                : Colors.green,
                          ),
                          _StatusItem(
                            icon: Icons.bloodtype,
                            label: 'Oxigênio',
                            value: '$spo2%',
                            color: spo2 < 94 ? Colors.orange : Colors.green,
                          ),
                          _StatusItem(
                            icon: Icons.location_on,
                            label: 'Geofence',
                            value: _insideGeofence
                                ? 'Dentro da área segura'
                                : 'Fora da área segura',
                            color: _insideGeofence
                                ? Colors.green
                                : Colors.redAccent,
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),
                    Text(
                      _timeSinceUpdate(),
                      style: TextStyle(fontSize: 12, color: cardTextColor),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _refreshStatus,
                      icon: const Icon(Icons.refresh),
                      label: const TranslatedText('Atualizar agora'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: GridView.builder(
                itemCount: menuItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return _HoverAnimatedButton(
                    color: isDark ? Colors.grey[700]! : Colors.blue.shade100,
                    hoverColor: isDark ? Colors.teal[700]! : Colors.blue.shade200,
                    iconColor: isDark ? Colors.white : Colors.blueAccent,
                    icon: item.icon,
                    label: item.title,
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, item.route, (r) => r.isFirst),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// WIDGETS AUXILIARES
// =========================

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 36, color: color),
        const SizedBox(height: 4),
        TranslatedText(label),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _HoverAnimatedButton extends StatefulWidget {
  final Color color;
  final Color hoverColor;
  final Color? iconColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HoverAnimatedButton({
    required this.color,
    required this.hoverColor,
    this.iconColor,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_HoverAnimatedButton> createState() => _HoverAnimatedButtonState();
}

class _HoverAnimatedButtonState extends State<_HoverAnimatedButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final currentColor = isHovered ? widget.hoverColor : widget.color;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 40, color: widget.iconColor),
                const SizedBox(height: 10),
                TranslatedText(widget.label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
