import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> alerts = [];

  final List<String> predefinedTitles = [
    'Queda detectada',
    'Bateria baixa',
    'Fora da área segura',
    'Inatividade prolongada',
    'Frequência cardíaca elevada',
  ];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('alerts');
    if (stored != null) {
      setState(() {
        alerts = List<Map<String, dynamic>>.from(jsonDecode(stored));
      });
    } else {
      alerts = [
        {'title': 'Queda detectada', 'time': 'Há 2 min', 'read': false},
        {'title': 'Bateria baixa', 'time': 'Há 10 min', 'read': false},
        {'title': 'Fora da área segura', 'time': 'Há 30 min', 'read': true},
      ];
      _saveAlerts();
    }
  }

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alerts', jsonEncode(alerts));
  }

  Future<void> _addAlert(String title, String time) async {
    setState(() {
      alerts.insert(0, {'title': title, 'time': time, 'read': false});
    });
    await _saveAlerts();
  }

  Future<void> _markAsRead(int index) async {
    setState(() {
      alerts[index]['read'] = true;
    });
    await _saveAlerts();
  }

  Future<void> _showAddAlertDialog() async {
    String? selectedTitle = predefinedTitles.first;
    String selectedTime = 'Agora';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Alerta Simulado'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedTitle,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de alerta'),
                    items: predefinedTitles
                        .map((title) =>
                            DropdownMenuItem(value: title, child: Text(title)))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedTitle = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTime,
                    decoration: const InputDecoration(
                        labelText: 'Tempo desde o alerta'),
                    items: [
                      'Agora',
                      'Há 2 min',
                      'Há 10 min',
                      'Há 30 min',
                      'Há 1 h',
                      'Há 3 h',
                    ]
                        .map((time) =>
                            DropdownMenuItem(value: time, child: Text(time)))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedTime = value ?? 'Agora'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedTitle != null) {
                  _addAlert(selectedTitle!, selectedTime);
                }
                Navigator.pop(context);
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAll() async {
    setState(() {
      alerts.clear();
    });
    await _saveAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: const Text('Alertas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert),
            tooltip: 'Adicionar alerta simulado',
            onPressed: _showAddAlertDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Limpar todos os alertas',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: alerts.isEmpty
          ? Center(
              child: Text(
                'Nenhum alerta disponível.',
                style: TextStyle(
                  color: isDark ? Colors.teal[700] : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final isRead = alert['read'] ?? false;

                IconData icon;
                Color iconColor;
                Color cardColor;

                switch (alert['title']) {
                  case 'Bateria baixa':
                    icon = Icons.battery_alert;
                    iconColor = Colors.redAccent;
                    cardColor = isRead ? Colors.grey[100]! : Colors.red.shade50;
                    break;
                  case 'Queda detectada':
                    icon = Icons.warning;
                    iconColor = Colors.redAccent;
                    cardColor = isRead ? Colors.grey[100]! : Colors.red.shade50;
                    break;
                  case 'Fora da área segura':
                    icon = Icons.location_off;
                    iconColor = Colors.redAccent;
                    cardColor = isRead ? Colors.grey[100]! : Colors.red.shade50;
                    break;
                  default:
                    icon = Icons.notifications_active;
                    iconColor = Colors.blueAccent;
                    cardColor =
                        isRead ? Colors.grey[100]! : Colors.blue.shade50;
                }

                return Card(
                  color: cardColor,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(icon, color: iconColor),
                    title: Text(
                      alert['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // sempre preto
                      ),
                    ),
                    subtitle: Text(
                      alert['time'],
                      style:
                          const TextStyle(color: Colors.black), // sempre preto
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
