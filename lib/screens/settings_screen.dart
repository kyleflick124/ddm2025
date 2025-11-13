import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabledTemp = true;
  bool _darkThemeTemp = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _notificationsEnabledTemp = prefs.getBool('notifications') ?? true;
      _darkThemeTemp = prefs.getBool('darkTheme') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabledTemp);
    await prefs.setBool('darkTheme', _darkThemeTemp);

    // Atualiza provider
    ref.read(themeProvider.notifier).state =
        _darkThemeTemp ? ThemeMode.dark : ThemeMode.light;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Configurações salvas!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('Tema escuro'),
              value: _darkThemeTemp,
              onChanged: (val) {
                setState(() => _darkThemeTemp = val);
              },
            ),
            SwitchListTile(
              title: const Text('Notificações ativadas'),
              value: _notificationsEnabledTemp,
              onChanged: (val) => setState(() => _notificationsEnabledTemp = val),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Salvar configurações'),
            ),
          ],
        ),
      ),
    );
  }
}
