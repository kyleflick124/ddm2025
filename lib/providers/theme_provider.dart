import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ThemeMode global: ThemeMode.system inicialmente
final themeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});
