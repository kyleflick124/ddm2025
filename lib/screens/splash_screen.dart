import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load saved preferences
    final prefs = await SharedPreferences.getInstance();

    // Restore language
    final savedLanguage = prefs.getString('last_language');
    if (savedLanguage != null) {
      ref.read(localeProvider.notifier).state = Locale(savedLanguage);
    }

    // Restore theme
    final savedTheme = prefs.getBool('darkTheme');
    if (savedTheme != null) {
      ref.read(themeProvider.notifier).state =
          savedTheme ? ThemeMode.dark : ThemeMode.light;
    }

    // Navigate after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final lastRoute = prefs.getString('last_route');
        // If there's a saved route and it's not splash or login, go there
        if (lastRoute != null &&
            lastRoute != '/splash' &&
            lastRoute != '/login' &&
            lastRoute.isNotEmpty) {
          Navigator.pushReplacementNamed(context, lastRoute);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.watch, size: 100, color: Colors.blue.shade700),
            const SizedBox(height: 20),
            const Text(
              "Elder Monitor",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const TranslatedText("Cuidando de quem você ama"),
          ],
        ),
      ),
    );
  }
}
