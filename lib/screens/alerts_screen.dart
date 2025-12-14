import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firebase_sync_service.dart';
import '../providers/locale_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> alerts = [];
  bool _isLoading = true;

  final String _elderId = 'elder_demo';
  final FirebaseSyncService _syncService = FirebaseSyncService();
  StreamSubscription? _alertsSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToAlerts();
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToAlerts() {
    // Listen to alerts from Firebase (from smartwatch)
    _alertsSubscription = _syncService
        .listenToAlerts(_elderId)
        .listen((alertsList) {
      setState(() {
        alerts = alertsList;
        _isLoading = false;
      });
    });

    // Set loading to false after timeout
    Future.delayed(const Duration(seconds: 5), () {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _markAsRead(int index) async {
    final alert = alerts[index];
    final alertId = alert['id'];
    if (alertId != null) {
      await _syncService.markAlertRead(_elderId, alertId);
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Agora';
      if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Há ${diff.inHours} h';
      return 'Há ${diff.inDays} dias';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: const TranslatedText('Alertas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const TranslatedText(
                        'Nenhum alerta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TranslatedText(
                        'Os alertas do smartwatch aparecerão aqui',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    final isRead = alert['read'] ?? false;
                    final title = alert['title'] ?? 'Alerta';
                    final body = alert['body'] ?? '';
                    final timestamp = alert['timestamp'] as String?;

                    IconData icon;
                    Color iconColor;
                    Color cardColor;

                    // Determine icon based on alert title or type
                    final lowerTitle = title.toString().toLowerCase();
                    if (lowerTitle.contains('queda') || lowerTitle.contains('fall')) {
                      icon = Icons.warning;
                      iconColor = Colors.redAccent;
                      cardColor = isRead ? Colors.grey[100]! : Colors.red.shade50;
                    } else if (lowerTitle.contains('bateria') || lowerTitle.contains('battery')) {
                      icon = Icons.battery_alert;
                      iconColor = Colors.orange;
                      cardColor = isRead ? Colors.grey[100]! : Colors.orange.shade50;
                    } else if (lowerTitle.contains('área') || lowerTitle.contains('geofence') || lowerTitle.contains('location')) {
                      icon = Icons.location_off;
                      iconColor = Colors.redAccent;
                      cardColor = isRead ? Colors.grey[100]! : Colors.red.shade50;
                    } else if (lowerTitle.contains('emergência') || lowerTitle.contains('emergency') || lowerTitle.contains('sos')) {
                      icon = Icons.emergency;
                      iconColor = Colors.red;
                      cardColor = isRead ? Colors.grey[100]! : Colors.red.shade100;
                    } else if (lowerTitle.contains('cardíac') || lowerTitle.contains('heart') || lowerTitle.contains('bpm')) {
                      icon = Icons.favorite;
                      iconColor = Colors.red;
                      cardColor = isRead ? Colors.grey[100]! : Colors.red.shade50;
                    } else {
                      icon = Icons.notifications_active;
                      iconColor = Colors.blueAccent;
                      cardColor = isRead ? Colors.grey[100]! : Colors.blue.shade50;
                    }

                    return Card(
                      color: cardColor,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(icon, color: iconColor),
                        title: TranslatedText(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (body.isNotEmpty)
                              TranslatedText(
                                body,
                                style: const TextStyle(color: Colors.black87),
                              ),
                            TranslatedText(
                              _formatTime(timestamp),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: !isRead
                            ? IconButton(
                                icon: const Icon(Icons.done, color: Colors.green),
                                tooltip: 'Marcar como lido',
                                onPressed: () => _markAsRead(index),
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
