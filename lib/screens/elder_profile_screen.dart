import 'dart:convert';
import 'package:elder_monitor/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ElderProfileScreen extends ConsumerStatefulWidget {
  const ElderProfileScreen({super.key});

  @override
  ConsumerState<ElderProfileScreen> createState() => _ElderProfileScreenState();
}

class _ElderProfileScreenState extends ConsumerState<ElderProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _caregiverNameController = TextEditingController();
  final _caregiverEmailController = TextEditingController();
  final _caregiverPhoneController = TextEditingController();

  bool _isEditing = false;
  List<Map<String, String>> _caregivers = [];

  @override
  void initState() {
    super.initState();
    _loadElderData();
    _loadCaregivers();
  }

  Future<void> _loadElderData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('elder_name') ?? 'João Silva';
      _ageController.text = prefs.getString('elder_age') ?? '75';
      _phoneController.text = prefs.getString('elder_phone') ?? '11 91234-5678';
      _emailController.text = prefs.getString('elder_email') ?? 'joao@example.com';
    });
  }

  Future<void> _saveElderData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('elder_name', _nameController.text);
    await prefs.setString('elder_age', _ageController.text);
    await prefs.setString('elder_phone', _phoneController.text);
    await prefs.setString('elder_email', _emailController.text);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: TranslatedText('Dados salvos!')));
  }

  Future<void> _loadCaregivers() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('caregivers');
    if (stored != null) {
      setState(() {
        _caregivers = List<Map<String, String>>.from(
          (jsonDecode(stored) as List).map(
            (item) => Map<String, String>.from(item),
          ),
        );
      });
    } else {
      // Inicializa com cuidadores padrão
      _caregivers = [
        {
          'name': 'Maria Jaqueline',
          'email': 'maria@example.com',
          'phone': '11 91234-5678',
        },
        {
          'name': 'Pedro Pereira',
          'email': 'pedro@example.com',
          'phone': '11 99876-5432',
        },
      ];
      await _saveCaregivers();
    }
  }

  Future<void> _saveCaregivers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('caregivers', jsonEncode(_caregivers));
  }

  Future<void> _addCaregiver() async {
    if (_caregiverNameController.text.isEmpty) return;

    setState(() {
      _caregivers.insert(0, {
        'name': _caregiverNameController.text,
        'email': _caregiverEmailController.text,
        'phone': _caregiverPhoneController.text,
      });
    });

    await _saveCaregivers();

    _caregiverNameController.clear();
    _caregiverEmailController.clear();
    _caregiverPhoneController.clear();
  }

  Future<void> _removeCaregiver(int index) async {
    setState(() {
      _caregivers.removeAt(index);
    });
    await _saveCaregivers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _caregiverNameController.dispose();
    _caregiverEmailController.dispose();
    _caregiverPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Cores ajustadas
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? (Colors.grey[850]!) : Colors.white;
    final buttonColor = isDark ? (Colors.teal[700]!) : Colors.blue.shade100;

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Perfil / Família'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/elder_home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: buttonColor,
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            _buildTextField("Nome", _nameController,
                enabled: _isEditing, textColor: textColor, cardColor: cardColor),
            const SizedBox(height: 12),
            _buildTextField("Idade", _ageController,
                keyboardType: TextInputType.number,
                enabled: _isEditing,
                textColor: textColor,
                cardColor: cardColor),
            const SizedBox(height: 12),
            _buildTextField("Telefone", _phoneController,
                keyboardType: TextInputType.phone,
                enabled: _isEditing,
                textColor: textColor,
                cardColor: cardColor),
            const SizedBox(height: 12),
            _buildTextField("E-mail", _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: _isEditing,
                textColor: textColor,
                cardColor: cardColor),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isEditing ? _saveElderData : () => setState(() => _isEditing = true),
              style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
              child: TranslatedText(_isEditing ? 'Salvar seus dados' : 'Editar seus dados',
                  style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(height: 24),
            TranslatedText('Cuidadores cadastrados',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _caregivers.length,
              itemBuilder: (context, index) {
                final caregiver = _caregivers[index];
                return Card(
                  color: isDark ? (Colors.grey[850]!) : Colors.grey.shade400,
                  child: ListTile(
                    title: Text(caregiver['name'] ?? '', style: TextStyle(color: textColor)),
                    subtitle: TranslatedText(
                        '${caregiver['email'] ?? ''} | ${caregiver['phone'] ?? ''}',
                        style: TextStyle(color: textColor)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _removeCaregiver(index),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TranslatedText('Adicionar cuidador',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            _buildTextField("Nome completo", _caregiverNameController,
                textColor: textColor, cardColor: cardColor),
            const SizedBox(height: 8),
            _buildTextField("E-mail", _caregiverEmailController,
                keyboardType: TextInputType.emailAddress,
                textColor: textColor,
                cardColor: cardColor),
            const SizedBox(height: 8),
            _buildTextField("Celular", _caregiverPhoneController,
                keyboardType: TextInputType.phone,
                textColor: textColor,
                cardColor: cardColor),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addCaregiver,
              style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
              child: const TranslatedText('Adicionar', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String labelKey,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool enabled = true,
    required Color textColor,
    required Color cardColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        label: TranslatedText(
          labelKey,
          style: TextStyle(color: textColor),
        ),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
    );
  }
}
