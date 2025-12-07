import 'package:flutter_test/flutter_test.dart';
import 'package:elder_monitor/services/translation_service.dart';

void main() {
  group('TranslationService Tests', () {
    late TranslationService translationService;

    setUp(() {
      translationService = TranslationService();
    });

    test('should support required language codes', () {
      final supportedLanguages = TranslationService.supportedLanguages;
      
      expect(supportedLanguages, contains('pt'));
      expect(supportedLanguages, contains('en'));
      expect(supportedLanguages, contains('es'));
      expect(supportedLanguages, contains('fr'));
      expect(supportedLanguages, contains('zh'));
    });

    test('should have language names for all codes', () {
      expect(translationService.getLanguageName('pt'), 'Português');
      expect(translationService.getLanguageName('en'), 'English');
      expect(translationService.getLanguageName('es'), 'Español');
      expect(translationService.getLanguageName('fr'), 'Français');
      expect(translationService.getLanguageName('zh'), '中文');
    });

    test('should return unknown for unsupported language', () {
      expect(translationService.getLanguageName('xx'), 'Unknown');
    });

    test('should have cached translations for common strings', () {
      // Common UI strings should have cached translations
      final commonStrings = [
        'Monitoramento de Idosos',
        'Configurações',
        'Alertas',
        'Painel',
        'Mapa',
        'Dispositivo',
      ];
      
      for (final str in commonStrings) {
        // Cache lookup should not throw
        expect(() => translationService.getCached(str, 'pt'), returnsNormally);
      }
    });

    test('should detect source language', () {
      expect(translationService.detectLanguage('Hello world'), 'en');
      expect(translationService.detectLanguage('Olá como você'), 'pt');
      expect(translationService.detectLanguage('Hola cómo estás'), 'es');
      expect(translationService.detectLanguage('Bonjour comment'), 'fr');
    });

    test('should validate language code format', () {
      expect(translationService.isValidLanguageCode('pt'), true);
      expect(translationService.isValidLanguageCode('en'), true);
      expect(translationService.isValidLanguageCode(''), false);
      expect(translationService.isValidLanguageCode('invalid'), false);
    });
  });

  group('TranslationCache Tests', () {
    test('should store and retrieve translations', () {
      final cache = TranslationCache();
      
      cache.set('Hello', 'pt', 'Olá');
      cache.set('Hello', 'es', 'Hola');
      
      expect(cache.get('Hello', 'pt'), 'Olá');
      expect(cache.get('Hello', 'es'), 'Hola');
    });

    test('should return null for missing translations', () {
      final cache = TranslationCache();
      
      expect(cache.get('NotCached', 'pt'), isNull);
    });

    test('should clear cache', () {
      final cache = TranslationCache();
      
      cache.set('Hello', 'pt', 'Olá');
      cache.clear();
      
      expect(cache.get('Hello', 'pt'), isNull);
    });

    test('should count cached entries', () {
      final cache = TranslationCache();
      
      cache.set('Hello', 'pt', 'Olá');
      cache.set('Hello', 'es', 'Hola');
      cache.set('Goodbye', 'pt', 'Tchau');
      
      expect(cache.size, 3);
    });
  });
}
