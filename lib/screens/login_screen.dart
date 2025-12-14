import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_auth_service.dart';
import '../services/firebase_sync_service.dart';
import '../providers/elder_provider.dart';
import '../providers/locale_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? selectedRole; // 'cuidador' ou 'idoso'
  bool _isLoading = false;
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final FirebaseSyncService _syncService = FirebaseSyncService();

  /// Check if running on a Wear OS smartwatch
  bool get _isSmartwatch {
    if (kIsWeb) return false;
    // Wear OS typically has small screen size
    // Also check for Android (Wear OS is Android-based)
    if (!Platform.isAndroid) return false;
    
    // Get screen size to check if it's a watch
    // Watches typically have screen width < 300
    final screenSize = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
    final pixelRatio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final logicalWidth = screenSize.width / pixelRatio;
    
    return logicalWidth < 300;
  }

  Future<void> _loginWithGoogle() async {
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText('Selecione como deseja acessar')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final User? user = await _googleAuthService.signInWithGoogle();

      if (!mounted) return;

      if (user != null) {
        await _handleSuccessfulLogin(user);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: TranslatedText('Login cancelado')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no login: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSuccessfulLogin(User user) async {
    if (selectedRole == 'cuidador') {
      // Save caregiver ID locally first (fast)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('caregiver_id', user.uid);
      
      // Navigate immediately - don't wait for Firebase
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
      
      // Register caregiver in Firebase in background (don't await)
      _syncService.registerCaregiver(
        caregiverId: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'Cuidador',
      ).catchError((_) {});
      
      // Load elders in background (don't block navigation)
      ref.read(elderProvider.notifier).setCaregiverId(user.uid);
      
    } else if (selectedRole == 'idoso') {
      // Check if running on smartwatch
      if (_isSmartwatch) {
        // Go to watch interface for smartwatch
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/watch_home');
        }
      } else {
        // Go to elder home for phone/tablet
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/elder_home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 300;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.grey[900]!, Colors.grey[800]!]
                    : [Colors.teal[50]!, Colors.white],
              ),
            ),
          ),
          
          // Content
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Icon
                      Icon(
                        Icons.elderly,
                        size: isSmallScreen ? 40 : 80,
                        color: Colors.teal,
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 16),
                      
                      TranslatedText(
                        'Elder Monitor',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 28, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      if (!isSmallScreen)
                        TranslatedText(
                          'Monitoramento de idosos',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),

                      SizedBox(height: isSmallScreen ? 12 : 32),

                      TranslatedText(
                        'Como deseja acessar?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 16, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 8 : 16),

                      // Role Selection
                      Row(
                        children: [
                          Expanded(
                            child: _RoleCard(
                              icon: Icons.person_outline,
                              label: 'Cuidador',
                              description: isSmallScreen ? '' : 'Monitore seus idosos',
                              isSelected: selectedRole == 'cuidador',
                              isCompact: isSmallScreen,
                              onTap: () => setState(() => selectedRole = 'cuidador'),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 6 : 12),
                          Expanded(
                            child: _RoleCard(
                              icon: Icons.elderly,
                              label: 'Idoso',
                              description: isSmallScreen ? '' : 'Veja seu status',
                              isSelected: selectedRole == 'idoso',
                              isCompact: isSmallScreen,
                              onTap: () => setState(() => selectedRole = 'idoso'),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 12 : 24),

                      // Google Login Button
                      ElevatedButton.icon(
                        icon: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.login, size: isSmallScreen ? 16 : 24),
                        label: TranslatedText(
                          'Entrar',
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _loginWithGoogle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isCompact ? 8 : 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: isCompact ? 24 : 40,
              color: isSelected ? Colors.teal : Colors.grey,
            ),
            SizedBox(height: isCompact ? 4 : 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 11 : 14,
                color: isSelected ? Colors.teal : Colors.grey[700],
              ),
            ),
            if (!isCompact && description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
