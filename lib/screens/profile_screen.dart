import 'dart:async';
import 'dart:convert';
import 'package:elder_monitor/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/elder_provider.dart';
import '../providers/locale_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _medicalController = TextEditingController();

  bool _isAddingElder = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  Future<void> _addElder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final result = await ref.read(elderProvider.notifier).registerElder(
      name: _nameController.text,
      age: _ageController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      medicalCondition: _medicalController.text,
    );

    setState(() => _isSaving = false);

    if (result != null && mounted) {
      _clearForm();
      setState(() => _isAddingElder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText('Idoso adicionado com sucesso!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText('Erro ao adicionar idoso')),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _ageController.clear();
    _phoneController.clear();
    _emailController.clear();
    _medicalController.clear();
  }

  void _selectElder(String elderId) {
    ref.read(elderProvider.notifier).setActiveElder(elderId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: TranslatedText('Idoso selecionado para monitoramento')),
    );
  }

  Future<void> _removeElder(String elderId, String elderName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const TranslatedText('Remover idoso'),
        content: Text('Deseja remover "$elderName" da sua lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const TranslatedText('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const TranslatedText('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(elderProvider.notifier).removeElder(elderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final elderState = ref.watch(elderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final cardColor = isDark ? Colors.grey[850]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final accentColor = isDark ? Colors.teal[400]! : Colors.teal;

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Meus Idosos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: elderState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Card(
                    color: accentColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.elderly, size: 40, color: Colors.white),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const TranslatedText(
                                  'Idosos monitorados',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${elderState.elders.length} cadastrado(s)',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Active Elder Selector
                  if (elderState.elders.isNotEmpty) ...[
                    Card(
                      color: cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TranslatedText(
                              'Idoso ativo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TranslatedText(
                              'Selecione qual idoso você deseja monitorar',
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: elderState.activeElderId,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                              ),
                              items: elderState.elders.map((elder) {
                                return DropdownMenuItem(
                                  value: elder['id'] as String,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: accentColor,
                                        child: Text(
                                          (elder['name'] as String? ?? 'I')[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(elder['name'] as String? ?? 'Idoso'),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _selectElder(value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Elders List
                  TranslatedText(
                    'Lista de idosos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (elderState.elders.isEmpty)
                    Card(
                      color: cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.person_add_alt_1, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const TranslatedText(
                              'Nenhum idoso cadastrado',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const TranslatedText(
                              'Adicione um idoso para começar a monitorar',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...elderState.elders.map((elder) => _buildElderCard(
                      elder,
                      isActive: elder['id'] == elderState.activeElderId,
                      cardColor: cardColor,
                      textColor: textColor,
                      accentColor: accentColor,
                    )),

                  const SizedBox(height: 24),

                  // Add Elder Button/Form
                  if (!_isAddingElder)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _isAddingElder = true),
                      icon: const Icon(Icons.person_add),
                      label: const TranslatedText('Adicionar idoso'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    _buildAddElderForm(cardColor, textColor),
                ],
              ),
            ),
    );
  }

  Widget _buildElderCard(
    Map<String, dynamic> elder, {
    required bool isActive,
    required Color cardColor,
    required Color textColor,
    required Color accentColor,
  }) {
    final name = elder['name'] as String? ?? 'Idoso';
    final age = elder['age'] as String? ?? '';
    final phone = elder['phone'] as String? ?? '';
    final id = elder['id'] as String;

    return Card(
      color: isActive ? accentColor.withValues(alpha: 0.1) : cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive 
            ? BorderSide(color: accentColor, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accentColor,
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ATIVO',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (age.isNotEmpty)
              Text('Idade: $age anos', style: TextStyle(color: textColor.withValues(alpha: 0.7))),
            if (phone.isNotEmpty)
              Text(phone, style: TextStyle(color: textColor.withValues(alpha: 0.7))),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'select') {
              _selectElder(id);
            } else if (value == 'remove') {
              _removeElder(id, name);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'select',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline),
                  SizedBox(width: 8),
                  TranslatedText('Selecionar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  TranslatedText('Remover', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddElderForm(Color cardColor, Color textColor) {
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.teal),
                  const SizedBox(width: 8),
                  TranslatedText(
                    'Novo Idoso',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _isAddingElder = false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Idade *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Idade é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medicalController,
                decoration: const InputDecoration(
                  labelText: 'Condição médica',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_information),
                  hintText: 'Ex: Hipertensão, Diabetes...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _addElder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const TranslatedText(
                        'Salvar idoso',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
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
