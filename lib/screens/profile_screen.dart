import 'dart:async';
import 'package:elder_monitor/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/elder_provider.dart';


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

    if (!mounted) return;

    if (result != null) {
      _clearForm();
      setState(() => _isAddingElder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText('Idoso adicionado com sucesso!')),
      );
    } else {
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
      const SnackBar(
        content: TranslatedText('Idoso selecionado para monitoramento'),
      ),
    );
  }

  Future<void> _removeElder(String elderId, String elderName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const TranslatedText('Remover idoso'),
        content: TranslatedText('Deseja remover "$elderName" da sua lista?'),
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
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: elderState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(elderState, accentColor),
                  const SizedBox(height: 16),

                  if (elderState.elders.isNotEmpty)
                    _buildActiveSelector(
                      elderState,
                      cardColor,
                      textColor,
                      accentColor,
                      isDark,
                    ),

                  const SizedBox(height: 16),

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
                    _buildEmptyState(cardColor)
                  else
                    ...elderState.elders.map(
                      (elder) => _buildElderCard(
                        elder,
                        isActive:
                            elder['id'] == elderState.activeElderId,
                        cardColor: cardColor,
                        textColor: textColor,
                        accentColor: accentColor,
                      ),
                    ),

                  const SizedBox(height: 24),

                  if (!_isAddingElder)
                    ElevatedButton.icon(
                      onPressed: () =>
                          setState(() => _isAddingElder = true),
                      icon: const Icon(Icons.person_add),
                      label:
                          const TranslatedText('Adicionar idoso'),
                    )
                  else
                    _buildAddElderForm(cardColor, textColor),
                ],
              ),
            ),
    );
  }

  // ---------- Widgets auxiliares ----------

  Widget _buildHeader(elderState, Color accentColor) {
    return Card(
      color: accentColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.elderly, size: 40, color: Colors.white),
            const SizedBox(width: 16),
            Column(
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
                TranslatedText(
                  '${elderState.elders.length} cadastrado(s)',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color cardColor) {
    return Card(
      color: cardColor,
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.person_add_alt_1, size: 64),
            SizedBox(height: 12),
            TranslatedText(
              'Nenhum idoso cadastrado',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            TranslatedText(
              'Adicione um idoso para começar a monitorar',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSelector(
    elderState,
    Color cardColor,
    Color textColor,
    Color accentColor,
    bool isDark,
  ) {
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: elderState.activeElderId,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: elderState.elders.map<DropdownMenuItem<String>>(
            (elder) => DropdownMenuItem(
              value: elder['id'],
              child: Text(elder['name']),
            ),
          ).toList(),
          onChanged: (value) {
            if (value != null) _selectElder(value);
          },
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
    final name = elder['name'] ?? 'Idoso';

    return Card(
      color: cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accentColor,
          child: Text(name[0]),
        ),
        title: Text(name),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeElder(elder['id'], name),
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
            children: [
              TextFormField(
                controller: _nameController,
                decoration:
                    const InputDecoration(labelText: 'Nome completo'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSaving ? null : _addElder,
                child: const TranslatedText('Salvar idoso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
