import 'package:flutter/material.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/data/models/user_model.dart';
import 'package:glumate_mobile/data/repositories/auth_repository.dart';
import 'package:glumate_mobile/widgets/app_input.dart';
import 'package:provider/provider.dart';

class ModifierProfilScreen extends StatefulWidget {
  const ModifierProfilScreen({this.onBack, super.key});
  final VoidCallback? onBack;

  @override
  State<ModifierProfilScreen> createState() => _ModifierProfilScreenState();
}

class _ModifierProfilScreenState extends State<ModifierProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _cibleMinCtrl = TextEditingController();
  final _cibleMaxCtrl = TextEditingController();
  final _contactNomCtrl = TextEditingController();
  final _contactTelCtrl = TextEditingController();
  final _traitementsCtrl = TextEditingController();
  final _regimeInsulineCtrl = TextEditingController();
  final _dfgCtrl = TextEditingController();

  String? _dateOfBirth;
  String? _gender;
  String? _typeDiabete;
  bool _insuffisanceRenale = false;
  bool _maladieCardiovasculaire = false;
  bool _grossesse = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  String? _normalizeGender(String? raw) {
    if (raw == null) return null;
    final upper = raw.toUpperCase();
    if (upper == 'HOMME' || upper == 'MALE') return 'HOMME';
    if (upper == 'FEMME' || upper == 'FEMALE') return 'FEMME';
    if (upper == 'AUTRE' || upper == 'OTHER') return 'AUTRE';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final auth = context.read<AuthService>();
      final user = await auth.getCurrentProfile();
      setState(() {
        _phoneCtrl.text = user.phone ?? '';
        _dateOfBirth = user.dateOfBirth != null
            ? '${user.dateOfBirth!.year}-${user.dateOfBirth!.month.toString().padLeft(2, '0')}-${user.dateOfBirth!.day.toString().padLeft(2, '0')}'
            : null;
        _gender = _normalizeGender(user.gender);
        _weightCtrl.text = user.weight?.toString() ?? '';
        _heightCtrl.text = user.height?.toString() ?? '';
        _cibleMinCtrl.text = user.cibleGlycemiqueMin?.toString() ?? '';
        _cibleMaxCtrl.text = user.cibleGlycemiqueMax?.toString() ?? '';
        _contactNomCtrl.text = user.contactUrgenceNom ?? '';
        _contactTelCtrl.text = user.contactUrgenceTel ?? '';
        _typeDiabete = user.typeDiabete;
        _traitementsCtrl.text = user.traitementsActuels ?? '';
        _regimeInsulineCtrl.text = user.regimeInsuline ?? '';
        _insuffisanceRenale = user.insuffisanceRenale ?? false;
        _dfgCtrl.text = user.dfg?.toString() ?? '';
        _maladieCardiovasculaire = user.maladieCardiovasculaire ?? false;
        _grossesse = user.grossesse ?? false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final auth = context.read<AuthService>();
      await auth.updateProfile(
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        weight: double.tryParse(_weightCtrl.text.trim()),
        height: double.tryParse(_heightCtrl.text.trim()),
        cibleGlycemiqueMin: double.tryParse(_cibleMinCtrl.text.trim()),
        cibleGlycemiqueMax: double.tryParse(_cibleMaxCtrl.text.trim()),
        contactUrgenceNom: _contactNomCtrl.text.trim().isEmpty ? null : _contactNomCtrl.text.trim(),
        contactUrgenceTel: _contactTelCtrl.text.trim().isEmpty ? null : _contactTelCtrl.text.trim(),
        typeDiabete: _typeDiabete,
        traitementsActuels: _traitementsCtrl.text.trim().isEmpty ? null : _traitementsCtrl.text.trim(),
        regimeInsuline: _regimeInsulineCtrl.text.trim().isEmpty ? null : _regimeInsulineCtrl.text.trim(),
        insuffisanceRenale: _insuffisanceRenale,
        dfg: _dfgCtrl.text.trim().isEmpty ? null : double.tryParse(_dfgCtrl.text.trim()),
        maladieCardiovasculaire: _maladieCardiovasculaire,
        grossesse: _grossesse,
      );

      setState(() {
        _successMessage = 'Profil mis à jour avec succès';
        _isLoading = false;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          widget.onBack?.call();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _cibleMinCtrl.dispose();
    _cibleMaxCtrl.dispose();
    _contactNomCtrl.dispose();
    _contactTelCtrl.dispose();
    _traitementsCtrl.dispose();
    _regimeInsulineCtrl.dispose();
    _dfgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.text),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Modifier mon profil',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_successMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green.shade700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              AppInput(
                controller: _phoneCtrl,
                label: 'Téléphone',
                hint: '06 12 34 56 78',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dateOfBirth ?? 'Date de naissance',
                          style: TextStyle(
                            color: _dateOfBirth != null ? AppColors.text : Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _gender,
                    hint: const Text('Genre'),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'HOMME', child: Text('Homme')),
                      DropdownMenuItem(value: 'FEMME', child: Text('Femme')),
                      DropdownMenuItem(value: 'AUTRE', child: Text('Autre')),
                    ],
                    onChanged: (value) {
                      setState(() => _gender = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _weightCtrl,
                label: 'Poids (kg)',
                hint: '70',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _heightCtrl,
                label: 'Taille (cm)',
                hint: '175',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _cibleMinCtrl,
                label: 'Cible glycémique min (g/L)',
                hint: '0.8',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _cibleMaxCtrl,
                label: 'Cible glycémique max (g/L)',
                hint: '1.2',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _contactNomCtrl,
                label: 'Nom du contact d\'urgence',
                hint: 'Dupont',
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _contactTelCtrl,
                label: 'Téléphone du contact d\'urgence',
                hint: '06 98 76 54 32',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              const Text(
                'Informations médicales',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _typeDiabete,
                    hint: const Text('Type de diabète'),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'TYPE1', child: Text('Type 1')),
                      DropdownMenuItem(value: 'TYPE2', child: Text('Type 2')),
                      DropdownMenuItem(value: 'GESTATIONNEL', child: Text('Gestationnel')),
                    ],
                    onChanged: (value) {
                      setState(() => _typeDiabete = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _traitementsCtrl,
                label: 'Traitements actuels',
                hint: 'Liste des médicaments...',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _regimeInsulineCtrl,
                label: 'Régime insulinique',
                hint: 'Basal + Rapide...',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Insuffisance rénale'),
                value: _insuffisanceRenale,
                onChanged: (value) {
                  setState(() => _insuffisanceRenale = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (_insuffisanceRenale)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AppInput(
                    controller: _dfgCtrl,
                    label: 'DFG (mL/min/1.73m²)',
                    hint: '90',
                    keyboardType: TextInputType.number,
                  ),
                ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Maladie cardiovasculaire'),
                value: _maladieCardiovasculaire,
                onChanged: (value) {
                  setState(() => _maladieCardiovasculaire = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              if (_gender == 'FEMME')
                SwitchListTile(
                  title: const Text('Grossesse en cours'),
                  value: _grossesse,
                  onChanged: (value) {
                    setState(() => _grossesse = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Enregistrer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
