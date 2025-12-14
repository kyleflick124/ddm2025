import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for translating app text using MyMemory Translation API
class TranslationService {
  static const String _baseUrl = 'https://api.mymemory.translated.net/get';
  
  /// Supported language codes
  static const List<String> supportedLanguages = ['pt', 'en', 'es', 'fr', 'zh'];
  
  /// Language names for display
  static const Map<String, String> _languageNames = {
    'pt': 'Português',
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'zh': '中文',
  };

  final TranslationCache _cache = TranslationCache();

  /// Translate text from source language to target language
  Future<String> translate(String text, String fromLang, String toLang) async {
    if (text.isEmpty) return text;
    if (fromLang == toLang) return text;
    
    // Check cache first
    final cached = _cache.get(text, toLang);
    if (cached != null) return cached;
    
    try {
      final uri = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(text)}&langpair=$fromLang|$toLang');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translatedText = data['responseData']['translatedText'] as String;
        
        // Cache the result
        _cache.set(text, toLang, translatedText);
        
        return translatedText;
      }
    } catch (e) {
      // Fall back to original text on error
      print('Translation error: $e');
    }
    
    return text;
  }

  /// Translate multiple texts at once
  Future<List<String>> translateBatch(
    List<String> texts,
    String fromLang,
    String toLang,
  ) async {
    final results = <String>[];
    for (final text in texts) {
      results.add(await translate(text, fromLang, toLang));
    }
    return results;
  }

  /// Get language name for display
  String getLanguageName(String code) {
    return _languageNames[code] ?? 'Unknown';
  }

  /// Check if translation is cached
  String? getCached(String text, String targetLang) {
    return _cache.get(text, targetLang);
  }

  /// Simple language detection based on common words
  String detectLanguage(String text) {
    final lowerText = text.toLowerCase();
    
    // Check for Portuguese
    if (lowerText.contains('olá') || lowerText.contains('mundo') || 
        lowerText.contains('como') || lowerText.contains('você')) {
      return 'pt';
    }
    
    // Check for Spanish  
    if (lowerText.contains('hola') || lowerText.contains('cómo') ||
        lowerText.contains('está') || lowerText.contains('qué')) {
      return 'es';
    }
    
    // Check for French
    if (lowerText.contains('bonjour') || lowerText.contains('monde') ||
        lowerText.contains('comment') || lowerText.contains('vous')) {
      return 'fr';
    }
    
    // Default to English
    return 'en';
  }

  /// Validate language code
  bool isValidLanguageCode(String code) {
    return supportedLanguages.contains(code);
  }

  /// Clear translation cache
  void clearCache() {
    _cache.clear();
  }
}

/// Cache for storing translations to reduce API calls
class TranslationCache {
  final Map<String, String> _cache = {};

  /// Get cached translation
  String? get(String text, String targetLang) {
    return _cache['$text|$targetLang'];
  }

  /// Store translation in cache
  void set(String text, String targetLang, String translation) {
    _cache['$text|$targetLang'] = translation;
  }

  /// Clear all cached translations
  void clear() {
    _cache.clear();
  }

  /// Get number of cached entries
  int get size => _cache.length;
}

/// Pre-cached common UI translations for offline use
class CommonTranslations {
  static const Map<String, Map<String, String>> translations = {
    'Monitoramento de Idosos': {
      'en': 'Elderly Monitoring',
      'es': 'Monitoreo de Ancianos',
      'fr': 'Surveillance des Personnes Âgées',
      'zh': '老年人监护',
    },
    'Configurações': {
      'en': 'Settings',
      'es': 'Configuración',
      'fr': 'Paramètres',
      'zh': '设置',
    },
    'Alertas': {
      'en': 'Alerts',
      'es': 'Alertas',
      'fr': 'Alertes',
      'zh': '警报',
    },
    'Painel': {
      'en': 'Dashboard',
      'es': 'Panel',
      'fr': 'Tableau de bord',
      'zh': '仪表板',
    },
    'Mapa': {
      'en': 'Map',
      'es': 'Mapa',
      'fr': 'Carte',
      'zh': '地图',
    },
    'Dispositivo': {
      'en': 'Device',
      'es': 'Dispositivo',
      'fr': 'Appareil',
      'zh': '设备',
    },
    'Batimentos': {
      'en': 'Heart Rate',
      'es': 'Frecuencia Cardíaca',
      'fr': 'Fréquence Cardiaque',
      'zh': '心率',
    },
    'Passos': {
      'en': 'Steps',
      'es': 'Pasos',
      'fr': 'Pas',
      'zh': '步数',
    },
    'Sono': {
      'en': 'Sleep',
      'es': 'Sueño',
      'fr': 'Sommeil',
      'zh': '睡眠',
    },
    'Localização em Tempo Real': {
      'en': 'Real-Time Location',
      'es': 'Ubicación en Tiempo Real',
      'fr': 'Localisation en Temps Réel',
      'zh': '实时位置',
    },
    'Área segura': {
      'en': 'Safe Zone',
      'es': 'Zona Segura',
      'fr': 'Zone Sûre',
      'zh': '安全区域',
    },
    'Fora da área segura': {
      'en': 'Outside Safe Zone',
      'es': 'Fuera de la Zona Segura',
      'fr': 'En dehors de la Zone Sûre',
      'zh': '在安全区外',
    },
    'Dentro da área segura': {
      'en': 'Inside Safe Zone',
      'es': 'Dentro de la Zona Segura',
      'fr': 'Dans la Zone Sûre',  
      'zh': '在安全区内',
    },
    'Emergência': {
      'en': 'Emergency',
      'es': 'Emergencia',
      'fr': 'Urgence',
      'zh': '紧急情况',
    },
    'Queda detectada': {
      'en': 'Fall Detected',
      'es': 'Caída Detectada',
      'fr': 'Chute Détectée',
      'zh': '检测到跌倒',
    },
    'Bateria baixa': {
      'en': 'Low Battery',
      'es': 'Batería Baja',
      'fr': 'Batterie Faible',
      'zh': '低电量',
    },
  };

  /// Get pre-cached translation
  static String? get(String text, String targetLang) {
    return translations[text]?[targetLang];
  }
}
