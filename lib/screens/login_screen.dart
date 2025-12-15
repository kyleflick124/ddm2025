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
  String? selectedRole; // 'cuidador' | 'idoso'
  bool _isLoading = false;

  final _googleAuthService = GoogleAuthService();
  final _syncService = FirebaseSyncService();

  /// Wear OS detection (SAFE)
  bool get _isSmartwatch {
    try {
      if (kIsWeb || !Platform.isAndroid) return false;

      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return false;

      final view = views.first;
      final logicalWidth =
          view.physicalSize.width / view.devicePixelRatio;

      return logicalWidth < 300;
    } catch (_) {
      return false;
    }
  }

  // ===================== LOGIN FLOW =====================

  Future<void> _loginWithGoogle() async {
    if (selectedRole == null) {
      _showSnack('Selecione como deseja acessar');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _googleAuthService.signInWithGoogle();
      if (!mounted || user == null) {
        _showSnack('Login cancelado');
        return;
      }

      // 🚀 navegação IMEDIATA para idoso (não bloqueia UI)
      if (selectedRole == 'idoso' && mounted) {
        Future.microtask(() {
          Navigator.pushReplacementNamed(
            context,
            _isSmartwatch ? '/watch_home' : '/elder_home',
          );
        });
      }

      await _handleSuccessfulLogin(user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro no login: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSuccessfulLogin(User user) async {
    if (selectedRole == 'cuidador') {
      await _handleCaregiverLogin(user);
    } else {
      await _handleElderLogin(user);
    }
  }

  // ===================== CAREGIVER =====================

  Future<void> _handleCaregiverLogin(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('caregiver_id', user.uid);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }

    // background tasks
    _syncService.registerCaregiver(
      caregiverId: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? 'Cuidador',
    ).catchError((_) {});

    ref.read(elderProvider.notifier).setCaregiverId(user.uid);
  }

  // ===================== ELDER =====================

  Future<void> _handleElderLogin(User user) async {
    final email = user.email ?? '';
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('elder_email', email);
    await prefs.setString('elder_auth_uid', user.uid);

    String? elderId;
    try {
      elderId = await _syncService
          .findElderByEmail(email)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      elderId = null;
    }

    if (elderId != null) {
      await prefs.setString('elder_id', elderId);

      _syncService
          .linkElderAuthUid(elderId, user.uid)
          .catchError((_) {});

      _showSnack(
        'Vinculado ao seu cuidador com sucesso!',
        color: Colors.green,
      );
    } else {
      _syncService.registerPendingElder(
        email: email,
        authUid: user.uid,
        name: user.displayName ?? 'Idoso',
      ).catchError((_) {});

      _showSnack(
        'Aguardando seu cuidador vincular você.',
        color: Colors.blue,
      );
    }
  }

  // ===================== UI =====================

  void _showSnack(String text, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TranslatedText(text),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = MediaQuery.of(context).size.width < 300;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(isDark),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 24),
              child: _buildCard(isSmallScreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[900]!, Colors.grey[800]!]
              : [Colors.teal[50]!, Colors.white],
        ),
      ),
    );
  }

  Widget _buildCard(bool isSmallScreen) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 20),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.elderly,
                size: isSmallScreen ? 40 : 80, color: Colors.teal),
            const SizedBox(height: 12),
            const TranslatedText(
              'Elder Monitor',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const TranslatedText('Como deseja acessar?'),
            const SizedBox(height: 16),
            _buildRoles(isSmallScreen),
            const SizedBox(height: 24),
            _buildLoginButton(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildRoles(bool isSmall) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            icon: Icons.person_outline,
            label: 'Cuidador',
            description: isSmall ? '' : 'Monitore seus idosos',
            isSelected: selectedRole == 'cuidador',
            isCompact: isSmall,
            onTap: () => setState(() => selectedRole = 'cuidador'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleCard(
            icon: Icons.elderly,
            label: 'Idoso',
            description: isSmall ? '' : 'Veja seu status',
            isSelected: selectedRole == 'idoso',
            isCompact: isSmall,
            onTap: () => setState(() => selectedRole = 'idoso'),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isSmall) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _loginWithGoogle,
      icon: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.login),
      label: const TranslatedText('Entrar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 16, horizontal: 32),
      ),
    );
  }
}

// ===================== ROLE CARD =====================

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
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isCompact ? 8 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Colors.teal.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(icon,
                size: isCompact ? 24 : 40,
                color: isSelected ? Colors.teal : Colors.grey),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.teal : Colors.grey[700],
              ),
            ),
            if (!isCompact && description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]
          ],
        ),
      ),
    );
  }
}
