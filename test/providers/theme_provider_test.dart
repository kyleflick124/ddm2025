import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:elder_monitor/providers/theme_provider.dart';

void main() {
  group('ThemeProvider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should have default theme as system', () {
      final themeMode = container.read(themeProvider);
      expect(themeMode, ThemeMode.system);
    });

    test('should change theme to dark', () {
      container.read(themeProvider.notifier).state = ThemeMode.dark;
      final themeMode = container.read(themeProvider);
      expect(themeMode, ThemeMode.dark);
    });

    test('should change theme to light', () {
      container.read(themeProvider.notifier).state = ThemeMode.light;
      final themeMode = container.read(themeProvider);
      expect(themeMode, ThemeMode.light);
    });

    test('should toggle between dark and light', () {
      container.read(themeProvider.notifier).state = ThemeMode.dark;
      expect(container.read(themeProvider), ThemeMode.dark);
      
      container.read(themeProvider.notifier).state = ThemeMode.light;
      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('should maintain state after multiple changes', () {
      container.read(themeProvider.notifier).state = ThemeMode.dark;
      container.read(themeProvider.notifier).state = ThemeMode.light;
      container.read(themeProvider.notifier).state = ThemeMode.dark;
      
      final themeMode = container.read(themeProvider);
      expect(themeMode, ThemeMode.dark);
    });

    test('should support all ThemeMode values', () {
      for (final mode in ThemeMode.values) {
        container.read(themeProvider.notifier).state = mode;
        expect(container.read(themeProvider), mode);
      }
    });
  });
}
