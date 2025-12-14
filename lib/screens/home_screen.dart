import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
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
  // Health data from Firebase (real data from smartwatch)
  HealthData? _healthData;
  bool _insideGeofence = true;
  DateTime _lastUpdate = DateTime.now();
  bool _isLoading = true;

  // Elder ID for Firebase sync
  final String _elderId = 'elder_demo';
  
  // Firebase sync service
  final FirebaseSyncService _syncService = FirebaseSyncService();
  StreamSubscription? _healthSubscription;

  final List<_MenuItem> menuItems = [
    _MenuItem('Painel', Icons.dashboard, '/dashboard'),
    _MenuItem('Alertas', Icons.notifications, '/alerts'),
    _MenuItem('Dispositivo', Icons.watch, '/device'),
    _MenuItem('Mapa', Icons.map, '/map'),
  ];

  @override
  void initState() {
    super.initState();
    _subscribeToHealthData();
  }

  @override
  void dispose() {
    _healthSubscription?.cancel();
    super.dispose();
  void _refreshStatus() async {
    final rand = Random();
    final newHeartRate = 60 + rand.nextInt(60); // 60–120 bpm
    final newSpo2 = 90 + rand.nextInt(10); // 90–99%
    final newInsideGeofence = rand.nextBool();
    final newLastUpdate = DateTime.now();

    setState(() {
      heartRate = newHeartRate;
      spo2 = newSpo2;
      insideGeofence = newInsideGeofence;
      lastUpdate = newLastUpdate;
      _progress = 0.0;
    });

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('heart_rate', newHeartRate);
    await prefs.setInt('spo2', newSpo2);
    await prefs.setBool('inside_geofence', newInsideGeofence);
    await prefs.setString('last_update', newLastUpdate.toIso8601String());
  }

  void _subscribeToHealthData() {
    // Listen to real health data from Firebase (from smartwatch)
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

    // Also listen to location for geofence status
    _syncService.listenToLocation(_elderId).listen((location) {
      // Geofence check would be done here with real data
      // For now, we update the timestamp
      if (location != null) {
        setState(() {
          _lastUpdate = location.timestamp;
        });
      }
    });

    // Set loading to false after initial timeout - no simulated data
    Future.delayed(const Duration(seconds: 5), () {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
          // No simulated data - leave _healthData as null
        });
      }
    });
  }

  void _refreshStatus() {
    setState(() {
      _lastUpdate = DateTime.now();
    });
    
    // Re-fetch from Firebase
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

  @override
  void initState() {
    super.initState();
    _loadSessionData();
    _startAutoUpdate();
  }

  Future<void> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      heartRate = prefs.getInt('heart_rate') ?? 78;
      spo2 = prefs.getInt('spo2') ?? 96;
      insideGeofence = prefs.getBool('inside_geofence') ?? true;
      final lastUpdateStr = prefs.getString('last_update');
      if (lastUpdateStr != null) {
        lastUpdate = DateTime.tryParse(lastUpdateStr) ?? DateTime.now();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final bool isDark = themeMode == ThemeMode.dark;
    final bool isWide = MediaQuery.of(context).size.width > 700;
    final crossAxisCount = isWide ? 4 : 2;

    final cardTextColor = isDark ? Colors.white : Colors.black87;
    final progressColor = isDark ? Colors.tealAccent : Colors.blueAccent;
    final progressBgColor = isDark ? Colors.white12 : Colors.grey.shade300;

    // Get health values - show placeholder if no data
    final hasData = _healthData != null;
    final heartRate = _healthData?.heartRate ?? 0;
    final spo2 = _healthData?.spo2 ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Monitoramento de Idosos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Perfil',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/profile', (route) => route.isFirst);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/settings', (route) => route.isFirst);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Panel
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? Colors.grey[850] : Colors.white,
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
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      )
                    else if (!hasData)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.watch_off, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            TranslatedText(
                              'Aguardando dados do smartwatch...',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 4),
                            TranslatedText(
                              'Certifique-se de que o relógio está conectado',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
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
                            color:
                                _insideGeofence ? Colors.green : Colors.redAccent,
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Status indicator
                    if (_healthData?.isCritical == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 8),
                            TranslatedText(
                              'Atenção: Sinais vitais críticos!',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    Text(
                      'Próxima atualização em $_updateInterval s',
                      style: TextStyle(
                          fontSize: 12, color: cardTextColor.withOpacity(0.6)),
                    ),
                    Text(
                      _timeSinceUpdate(),
                      style: TextStyle(
                          fontSize: 12, color: cardTextColor.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? Colors.teal[700] : Colors.blue.shade100,
                      ),
                      onPressed: _refreshStatus,
                      icon: const Icon(Icons.refresh),
                      label: const TranslatedText('Atualizar agora'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Feature Grid
            Expanded(
              child: GridView.builder(
                itemCount: menuItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.1 : 1.0,
                ),
                itemBuilder: (context, index) {
                  final item = menuItems[index];

                  final baseColor =
                      isDark ? Colors.grey[700]! : Colors.blue.shade100;
                  final hoverColor =
                      isDark ? Colors.teal[700]! : Colors.blue.shade200;
                  final iconColor = isDark ? Colors.white : Colors.blueAccent;

                  if (item.title == 'Alertas') {
                    return FutureBuilder<int>(
                      future: _getUnreadCount(),
                      builder: (context, snapshot) {
                        final unread = snapshot.data ?? 0;
                        final hasUnread = unread > 0;
                        return _HoverAnimatedButton(
                          color: hasUnread ? Colors.red.shade100 : baseColor,
                          hoverColor:
                              hasUnread ? Colors.red.shade200 : hoverColor,
                          iconColor: hasUnread ? Colors.redAccent : iconColor,
                          icon: item.icon,
                          label: item.title,
                          badgeCount: unread,
                          onTap: () => Navigator.pushNamedAndRemoveUntil(
                              context, item.route, (route) => route.isFirst),
                        );
                      },
                    );
                  }

                  return _HoverAnimatedButton(
                    color: baseColor,
                    hoverColor: hoverColor,
                    iconColor: iconColor,
                    icon: item.icon,
                    label: item.title,
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, item.route, (route) => route.isFirst),
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

// StatusItem widget
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
        TranslatedText(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// HoverAnimatedButton widget
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
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
          ],
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
                TranslatedText(
                  widget.label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: widget.iconColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
