import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/watch_home_screen.dart';
import 'services/health_sensor_service.dart';
import 'services/watch_firebase_service.dart';

void main() {
  runApp(const ProviderScope(child: ElderWatchApp()));
}

class ElderWatchApp extends StatelessWidget {
  const ElderWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elder Watch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal,
        colorScheme: ColorScheme.dark(
          primary: Colors.teal,
          secondary: Colors.tealAccent,
        ),
        useMaterial3: true,
      ),
      home: const WatchHomeScreen(),
    );
  }
}
