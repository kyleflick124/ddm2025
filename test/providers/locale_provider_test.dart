import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:elder_monitor/services/translation_service.dart';
import 'package:elder_monitor/providers/locale_provider.dart';

void main() {
  group('Locale and Translation Tests', () {
    test('TranslationService should support all required languages', () {
      final supported = TranslationService.supportedLanguages;
      expect(supported, contains('pt'));
      expect(supported, contains('en'));
      expect(supported, contains('es'));
      expect(supported, contains('fr'));
      expect(supported, contains('zh'));
      expect(supported.length, 5);
    });

    test('TranslationService should get language names correctly', () {
      final service = TranslationService();
      expect(service.getLanguageName('pt'), 'Português');
      expect(service.getLanguageName('en'), 'English');
      expect(service.getLanguageName('es'), 'Español');
      expect(service.getLanguageName('fr'), 'Français');
      expect(service.getLanguageName('zh'), '中文');
      expect(service.getLanguageName('xx'), 'Desconhecido');
    });

    test('TranslationService should validate language codes', () {
      final service = TranslationService();
      expect(service.isValidLanguageCode('pt'), true);
      expect(service.isValidLanguageCode('en'), true);
      expect(service.isValidLanguageCode('es'), true);
      expect(service.isValidLanguageCode('fr'), true);
      expect(service.isValidLanguageCode('zh'), true);
      expect(service.isValidLanguageCode('xx'), false);
      expect(service.isValidLanguageCode(''), false);
    });

    test('CommonTranslations should have entries for common strings', () {
      final translations = CommonTranslations.translations;
      expect(translations.containsKey('Alertas'), true);
      expect(translations.containsKey('Configurações'), true);
      expect(translations.containsKey('Monitoramento de Idosos'), true);
    });

    test('CommonTranslations should return correct translations', () {
      expect(CommonTranslations.get('Alertas', 'en'), 'Alerts');
      expect(CommonTranslations.get('Alertas', 'es'), 'Alertas');
      expect(CommonTranslations.get('Alertas', 'fr'), 'Alertes');
      expect(CommonTranslations.get('Alertas', 'zh'), '警报');
    });

    test('TranslateParams should have equality', () {
      final p1 = TranslateParams('Hello');
      final p2 = TranslateParams('Hello');
      final p3 = TranslateParams('World');
      
      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });

    test('tr extension should create TranslateParams', () {
      final params = 'Hello'.tr;
      expect(params, isA<TranslateParams>());
      expect(params.text, 'Hello');
    });

    test('Locale should support all required languages', () {
      final locales = ['pt', 'en', 'es', 'fr', 'zh'];
      
      for (final code in locales) {
        final locale = Locale(code);
        expect(locale.languageCode, code);
      }
    });

    test('TranslationCache should work correctly', () {
      final cache = TranslationCache();
      
      cache.set('hello', 'en', 'Hello');
      expect(cache.get('hello', 'en'), 'Hello');
      expect(cache.get('hello', 'pt'), isNull);
      
      cache.clear();
      expect(cache.get('hello', 'en'), isNull);
    });
  });
}
