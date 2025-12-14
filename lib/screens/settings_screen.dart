import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../services/translation_service.dart';
import '../providers/session_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabledTemp = true;
  bool _darkThemeTemp = false;
  String _selectedLanguage = 'pt';

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
      _selectedLanguage = prefs.getString('last_language') ?? 'pt';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabledTemp);
    await prefs.setBool('darkTheme', _darkThemeTemp);
    await prefs.setString('last_language', _selectedLanguage);

    // Update theme provider
    ref.read(themeProvider.notifier).state =
        _darkThemeTemp ? ThemeMode.dark : ThemeMode.light;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: TranslatedText('Configurações salvas!')),
    );

    // Atualiza provider de idioma
    ref.read(localeProvider.notifier).state = Locale(_selectedLanguage);

    // Salva no session provider
    ref.read(sessionProvider.notifier).saveLastLanguage(_selectedLanguage);

  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final translationService = ref.watch(translationServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Configurações'),
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
            // Language Selector
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TranslatedText(
                      'Idioma',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: currentLocale.languageCode,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: TranslationService.supportedLanguages.map((code) {
                        return DropdownMenuItem(
                          value: code,
                          child: Row(
                            children: [
                              _getFlagEmoji(code),
                              const SizedBox(width: 12),
                              Text(translationService.getLanguageName(code)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (code) {
                        if (code != null) {
                          ref.read(localeProvider.notifier).setLocale(code);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Theme and Notifications
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const TranslatedText('Tema escuro'),
                    subtitle: TranslatedText(
                      _darkThemeTemp ? 'Ativado' : 'Desativado',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    secondary: Icon(
                      _darkThemeTemp ? Icons.dark_mode : Icons.light_mode,
                      color: _darkThemeTemp ? Colors.amber : Colors.grey,
                    ),
                    value: _darkThemeTemp,
                    onChanged: (val) {
                      setState(() => _darkThemeTemp = val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const TranslatedText('Notificações ativadas'),
                    subtitle: TranslatedText(
                      _notificationsEnabledTemp 
                          ? 'Recebendo alertas' 
                          : 'Alertas desativados',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    secondary: Icon(
                      _notificationsEnabledTemp 
                          ? Icons.notifications_active 
                          : Icons.notifications_off,
                      color: _notificationsEnabledTemp ? Colors.blue : Colors.grey,
                    ),
                    value: _notificationsEnabledTemp,
                    onChanged: (val) => setState(() => _notificationsEnabledTemp = val),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const TranslatedText('Salvar configurações'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // App info
            Card(
              elevation: 1,
              color: Theme.of(context).colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    TranslatedText(
                      'Elder Monitor',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Versão 1.0.0',
                      style: TextStyle(fontSize: 12),
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

  Widget _getFlagEmoji(String languageCode) {
    final flags = {
      'pt': '🇧🇷',
      'en': '🇺🇸',
      'es': '🇪🇸',
      'fr': '🇫🇷',
      'zh': '🇨🇳',
    };
    return Text(
      flags[languageCode] ?? '🌐',
      style: const TextStyle(fontSize: 24),
    );
  }
}
