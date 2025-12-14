import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_sync_service.dart';
import '../providers/locale_provider.dart';
import '../providers/elder_provider.dart';

class DeviceScreen extends ConsumerStatefulWidget {
  const DeviceScreen({super.key});

  @override
  ConsumerState<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends ConsumerState<DeviceScreen> {
  Map<String, dynamic>? _deviceStatus;
  bool _isLoading = true;
  bool _isOnline = false;

  String get _elderId => ref.read(activeElderIdProvider) ?? 'elder_demo';
  final FirebaseSyncService _syncService = FirebaseSyncService();
  StreamSubscription? _deviceSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToDeviceStatus();
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToDeviceStatus() {
    _deviceSubscription = _syncService
        .listenToDeviceStatus(_elderId)
        .listen((status) {
      if (status != null) {
        setState(() {
          _deviceStatus = status;
          _isLoading = false;
          _isOnline = _checkIfOnline(status['lastSync']);
        });
      }
    });

    // Timeout for loading
    Future.delayed(const Duration(seconds: 5), () {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  bool _checkIfOnline(String? lastSync) {
    if (lastSync == null) return false;
    try {
      final dt = DateTime.parse(lastSync);
      final diff = DateTime.now().difference(dt);
      return diff.inMinutes < 5; // Consider online if updated within 5 minutes
    } catch (e) {
      return false;
    }
  }

  String _formatLastSync(String? lastSync) {
    if (lastSync == null) return 'Desconhecido';
    try {
      final dt = DateTime.parse(lastSync);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Agora';
      if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Há ${diff.inHours} h';
      return 'Há ${diff.inDays} dias';
    } catch (e) {
      return 'Desconhecido';
    }
  }

  void _requestSync() {
    // This would trigger a sync request to the smartwatch
    // For now, just show a message that we're waiting
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: TranslatedText('Aguardando sincronização do relógio...'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    
    // Extract device info from Firebase data
    final batteryLevel = _deviceStatus?['batteryLevel'] ?? 0;
    final isCharging = _deviceStatus?['isCharging'] ?? false;
    final model = _deviceStatus?['model'] ?? 'Desconhecido';
    final firmwareVersion = _deviceStatus?['firmwareVersion'] ?? 'Desconhecido';
    final lastSync = _deviceStatus?['lastSync'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Dispositivo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Device Status Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _deviceStatus == null
                          ? _buildNoDeviceState()
                          : _buildDeviceInfo(
                              batteryLevel: batteryLevel,
                              isCharging: isCharging,
                              model: model,
                              firmwareVersion: firmwareVersion,
                              lastSync: lastSync,
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ações Rápidas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _ActionButton(
                          icon: Icons.sync,
                          label: 'Sincronizar',
                          color: Colors.lightBlueAccent,
                          onTap: _requestSync,
                        ),
                        _ActionButton(
                          icon: Icons.location_searching,
                          label: 'Localizar',
                          color: Colors.lightBlueAccent,
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/map');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNoDeviceState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.watch_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const TranslatedText(
          'Relógio não conectado',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TranslatedText(
          'Aguardando dados do smartwatch do idoso...',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        const TranslatedText(
          'Certifique-se de que o relógio está: Ligado, Com o app aberto, Conectado à internet',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDeviceInfo({
    required int batteryLevel,
    required bool isCharging,
    required String model,
    required String firmwareVersion,
    required String? lastSync,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Status do Relógio',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isOnline ? 'Online' : 'Offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.watch, color: Colors.blueAccent),
          title: Text('Modelo: $model'),
          subtitle: Text('Firmware $firmwareVersion'),
        ),
        ListTile(
          leading: Icon(
            isCharging ? Icons.battery_charging_full : _getBatteryIcon(batteryLevel),
            color: _getBatteryColor(batteryLevel),
          ),
          title: Text('Bateria: $batteryLevel%'),
          subtitle: Text(isCharging ? 'Carregando' : _getBatteryStatus(batteryLevel)),
        ),
        ListTile(
          leading: Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            color: _isOnline ? Colors.green : Colors.grey,
          ),
          title: Text('Conectividade: ${_isOnline ? "Conectado" : "Desconectado"}'),
          subtitle: Text('Última sincronização: ${_formatLastSync(lastSync)}'),
        ),
      ],
    );
  }

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full;
    if (level > 50) return Icons.battery_5_bar;
    if (level > 20) return Icons.battery_3_bar;
    return Icons.battery_alert;
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }

  String _getBatteryStatus(int level) {
    if (level > 80) return 'Excelente';
    if (level > 50) return 'Bom';
    if (level > 20) return 'Baixo';
    return 'Crítico - Carregar agora!';
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final currentColor =
        isHovered ? widget.color.withOpacity(0.8) : widget.color;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 40, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
