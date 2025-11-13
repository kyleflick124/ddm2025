import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode? themeMode;
  final Locale? locale;
  final bool seenOnboarding;
  SettingsState({this.themeMode, this.locale, this.seenOnboarding = false});
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode');
    final localeCode = prefs.getString('localeCode');
    final seen = prefs.getBool('seenOnboarding') ?? false;

    state = SettingsState(
      themeMode: theme != null ? ThemeMode.values.firstWhere((e) => e.name == theme, orElse: () => ThemeMode.system) : null,
      locale: localeCode != null ? Locale(localeCode) : null,
      seenOnboarding: seen,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    state = SettingsState(themeMode: mode, locale: state.locale, seenOnboarding: state.seenOnboarding);
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale != null) {
      await prefs.setString('localeCode', locale.languageCode);
    } else {
      await prefs.remove('localeCode');
    }
    state = SettingsState(themeMode: state.themeMode, locale: locale, seenOnboarding: state.seenOnboarding);
  }

  Future<void> setSeenOnboarding(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', seen);
    state = SettingsState(themeMode: state.themeMode, locale: state.locale, seenOnboarding: seen);
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
