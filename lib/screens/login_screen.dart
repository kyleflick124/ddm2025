import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? selectedRole; // 'cuidador' ou 'idoso'
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  void _navigateAfterLogin() {
    if (selectedRole == 'cuidador') {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (selectedRole == 'idoso') {
      Navigator.pushReplacementNamed(context, '/elder_home');
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      final User? user = await _googleAuthService.signInWithGoogle();

      if (!mounted) return;

      if (user != null) {
        _navigateAfterLogin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login com Google cancelado'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro no login com Google: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bem-vindo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 32),

              // Email
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Senha
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),

              const SizedBox(height: 24),

              const Text(
                'Como deseja acessar?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 12),

              // CUIDADOR
              OutlinedButton(
                onPressed: () => setState(() => selectedRole = 'cuidador'),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      selectedRole == 'cuidador' ? Colors.teal : Colors.transparent,
                  side: BorderSide(
                    color: selectedRole == 'cuidador'
                        ? Colors.teal
                        : Colors.grey,
                  ),
                ),
                child: Text(
                  'Sou Cuidador',
                  style: TextStyle(
                    color: selectedRole == 'cuidador'
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // IDOSO
              OutlinedButton(
                onPressed: () => setState(() => selectedRole = 'idoso'),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      selectedRole == 'idoso' ? Colors.teal : Colors.transparent,
                  side: BorderSide(
                    color: selectedRole == 'idoso'
                        ? Colors.teal
                        : Colors.grey,
                  ),
                ),
                child: Text(
                  'Sou o Idoso',
                  style: TextStyle(
                    color:
                        selectedRole == 'idoso' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // LOGIN NORMAL
              ElevatedButton(
                onPressed: selectedRole == null ? null : _navigateAfterLogin,
                child: const Text('Entrar'),
              ),

              const SizedBox(height: 16),

              // DIVISOR
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('ou'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 16),

              // LOGIN COM GOOGLE
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Entrar com Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: selectedRole == null ? null : _loginWithGoogle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
