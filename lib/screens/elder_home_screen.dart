import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:elder_monitor/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';

class ElderHomeScreen extends ConsumerStatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  ConsumerState<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _MenuItem {
  final String title;
  final IconData icon;
  final String route;
  _MenuItem(this.title, this.icon, this.route);
}

class _ElderHomeScreenState extends ConsumerState<ElderHomeScreen> {
  int heartRate = 78;
  int spo2 = 96;
  bool insideGeofence = true;
  DateTime lastUpdate = DateTime.now();

  Timer? _timer;
  double _progress = 0.0;
  final int _updateInterval = 10; // intervalo fixo

  final List<_MenuItem> menuItems = [
    _MenuItem('Painel', Icons.dashboard, '/dashboard'),
    _MenuItem('Alertas', Icons.notifications, '/alerts'),
    _MenuItem('Dispositivo', Icons.watch, '/device'),
    _MenuItem('Mapa', Icons.map, '/map'),
  ];

  Future<int> _getUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('alerts');
    if (stored == null) return 0;
    final alerts = List<Map<String, dynamic>>.from(jsonDecode(stored));
    return alerts.where((a) => !a['read']).length;
  }

  void _refreshStatus() {
    final rand = Random();
    setState(() {
      heartRate = 60 + rand.nextInt(60); // 60–120 bpm
      spo2 = 90 + rand.nextInt(10); // 90–99%
      insideGeofence = rand.nextBool();
      lastUpdate = DateTime.now();
      _progress = 0.0;
    });
  }

  void _startAutoUpdate() {
    _timer?.cancel();
    const tick = Duration(milliseconds: 100);
    final totalTicks = _updateInterval * 10; // 100ms * 10 = 1s
    int currentTick = 0;

    _timer = Timer.periodic(tick, (t) {
      setState(() {
        currentTick++;
        _progress = currentTick / totalTicks;
        if (_progress >= 1.0) {
          _refreshStatus();
          currentTick = 0;
          _progress = 0.0;
        }
      });
    });
  }

  String _timeSinceUpdate() {
    final diff = DateTime.now().difference(lastUpdate);
    if (diff.inMinutes < 1) return 'Atualizado há poucos segundos';
    if (diff.inMinutes < 60) return 'Atualizado há ${diff.inMinutes} min';
    return 'Atualizado há ${diff.inHours} h';
  }

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    _startAutoUpdate();
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

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Monitoramento de Idosos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Perfil',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/elder_profile', (route) => route.isFirst);
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
            // --- PAINEL DE STATUS DO IDOSO ---
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatusItem(
                          icon: Icons.favorite,
                          label: 'Batimentos',
                          value: '$heartRate bpm',
                          color: heartRate > 110 || heartRate < 60
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
                          value: insideGeofence
                              ? 'Dentro da área segura'
                              : 'Fora da área segura',
                          color:
                              insideGeofence ? Colors.green : Colors.redAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: progressBgColor,
                      color: progressColor,
                    ),
                    const SizedBox(height: 8),
                    TranslatedText(
                      'Próxima atualização em $_updateInterval s',
                      style: TextStyle(
                          fontSize: 12,
                          color: cardTextColor.withOpacity(0.6)),
                    ),
                    TranslatedText(
                      _timeSinceUpdate(),
                      style: TextStyle(
                          fontSize: 12,
                          color: cardTextColor.withOpacity(0.6)),
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

            // --- GRADE DE FUNCIONALIDADES ---
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
                          color:
                              hasUnread ? Colors.red.shade100 : baseColor,
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

// StatusItem
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
        TranslatedText(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// HoverAnimatedButton
class _HoverAnimatedButton extends StatefulWidget {
  final Color color;
  final Color hoverColor;
  final Color? iconColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badgeCount;

  const _HoverAnimatedButton({
    required this.color,
    required this.hoverColor,
    this.iconColor,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount,
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
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Center(
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
              if (widget.badgeCount != null && widget.badgeCount! > 0)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TranslatedText(
                      widget.badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
