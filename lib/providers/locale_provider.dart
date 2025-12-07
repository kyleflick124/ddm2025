import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';

/// Provider for managing the current locale
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('pt')) {
    _loadLocale();
  }

  /// Load saved locale from SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('locale') ?? 'pt';
    state = Locale(savedLocale);
  }

  /// Change locale and persist to storage
  Future<void> setLocale(String languageCode) async {
    if (TranslationService.supportedLanguages.contains(languageCode)) {
      state = Locale(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('locale', languageCode);
    }
  }
}

/// Provider for translation service instance
final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});

/// Provider for getting translated text
/// Usage: ref.watch(translate('Hello'))
final translateProvider = Provider.family<Future<String>, TranslateParams>((ref, params) async {
  final service = ref.watch(translationServiceProvider);
  final locale = ref.watch(localeProvider);
  
  // If already in Portuguese (source), return original
  if (locale.languageCode == 'pt') {
    return params.text;
  }
  
  // Check pre-cached common translations first
  final cached = CommonTranslations.get(params.text, locale.languageCode);
  if (cached != null) return cached;
  
  // Use service cache or API
  return service.translate(params.text, 'pt', locale.languageCode);
});

/// Parameters for translation
class TranslateParams {
  final String text;
  
  TranslateParams(this.text);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslateParams &&
          runtimeType == other.runtimeType &&
          text == other.text;

  @override
  int get hashCode => text.hashCode;
}

/// Extension for easy translation access
extension TranslationExtension on String {
  TranslateParams get tr => TranslateParams(this);
}

/// Widget that automatically translates its child text
class TranslatedText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    
    // If Portuguese, show directly
    if (locale.languageCode == 'pt') {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    
    // Check common translations
    final cached = CommonTranslations.get(text, locale.languageCode);
    if (cached != null) {
      return Text(
        cached,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Use FutureBuilder for API translations
    return FutureBuilder<String>(
      future: ref.read(translationServiceProvider).translate(text, 'pt', locale.languageCode),
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// Language selector dropdown widget
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final translationService = ref.watch(translationServiceProvider);
    
    return DropdownButton<String>(
      value: currentLocale.languageCode,
      items: TranslationService.supportedLanguages.map((code) {
        return DropdownMenuItem(
          value: code,
          child: Text(translationService.getLanguageName(code)),
        );
      }).toList(),
      onChanged: (code) {
        if (code != null) {
          ref.read(localeProvider.notifier).setLocale(code);
        }
      },
    );
  }
}
