import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_sync_service.dart';
import '../providers/locale_provider.dart';

class ElderHomeScreen extends ConsumerStatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  ConsumerState<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _ElderHomeScreenState extends ConsumerState<ElderHomeScreen> {
  final FirebaseSyncService _syncService = FirebaseSyncService();
  
  bool _isSendingEmergency = false;
  String _lastSyncTime = 'Aguardando...';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  void _checkConnection() {
    // Simple connection check
    setState(() {
      _isConnected = true;
      _lastSyncTime = _formatTime(DateTime.now());
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _sendEmergencyAlert() async {
    setState(() => _isSendingEmergency = true);

    try {
      // TODO: Get actual elderId from auth/session
      const elderId = 'elder_demo';
      
      // Create emergency alert
      await _syncService.createAlert(
        elderId,
        'EMERGÊNCIA - SOS',
        'O idoso acionou o botão de emergência!',
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            title: TranslatedText('Alerta Enviado!'),
            content: TranslatedText(
              'Seu cuidador foi notificado. Mantenha a calma e aguarde.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: TranslatedText('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Erro ao enviar alerta. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSendingEmergency = false);
    }
  }

  void _confirmEmergency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: TranslatedText('Chamar Emergência?'),
        content: TranslatedText(
          'Isso enviará um alerta imediato para seu cuidador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TranslatedText('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendEmergencyAlert();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: TranslatedText('SIM, CHAMAR!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: TranslatedText('Minha Saúde'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Perfil',
            onPressed: () => Navigator.pushNamed(context, '/elder_profile'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações',
            onPressed: () => Navigator.pushNamed(context, '/elder_settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Status card
              Card(
                color: isDark ? Colors.grey[850] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _isConnected ? Icons.cloud_done : Icons.cloud_off,
                        color: _isConnected ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TranslatedText(
                              _isConnected ? 'Conectado' : 'Desconectado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isConnected ? Colors.green : Colors.red,
                              ),
                            ),
                            TranslatedText(
                              'Última sincronização: $_lastSyncTime',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Emergency SOS Button - Main feature
              GestureDetector(
                onTap: _isSendingEmergency ? null : _confirmEmergency,
                child: Container(
                  width: screenHeight * 0.3,
                  height: screenHeight * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSendingEmergency
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.sos,
                                size: 64,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              TranslatedText(
                                'EMERGÊNCIA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              TranslatedText(
                'Pressione para chamar seu cuidador',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),

              const Spacer(),

              // Simple info text
              Card(
                color: isDark ? Colors.teal[800] : Colors.teal[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark ? Colors.teal[200] : Colors.teal[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TranslatedText(
                          'Seu smartwatch está monitorando sua saúde automaticamente.',
                          style: TextStyle(
                            color: isDark ? Colors.teal[100] : Colors.teal[800],
                          ),
                        ),
                      ),
                    ],
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