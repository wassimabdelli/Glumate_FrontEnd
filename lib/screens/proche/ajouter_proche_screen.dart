import 'package:flutter/material.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/core/constants/app_screen.dart';
import 'package:glumate_mobile/data/models/ami_proche_model.dart';
import 'package:glumate_mobile/data/repositories/auth_repository.dart';
import 'package:glumate_mobile/data/repositories/ami_proche_repository.dart';
import 'package:glumate_mobile/widgets/app_input.dart';
import 'package:provider/provider.dart';

class AjouterProcheScreen extends StatefulWidget {
  const AjouterProcheScreen({this.onNavigate, super.key});
  final ValueChanged<AppScreen>? onNavigate;

  @override
  State<AjouterProcheScreen> createState() => _AjouterProcheScreenState();
}

class _AjouterProcheScreenState extends State<AjouterProcheScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  AmiProcheModel? _createdAmiProche;

  String? _validateRequired(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ requis';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ requis';
    final emailRegex = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(v.trim())) return 'Email invalide';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthService>();
      final user = auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final amiProcheRepo = context.read<AmiProcheRepository>();
      
      final result = await amiProcheRepo.createAmiProche(
        patientId: user.id!,
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        telephone: _telephoneCtrl.text.trim().isEmpty ? null : _telephoneCtrl.text.trim(),
      );

      setState(() {
        _createdAmiProche = result;
        _isLoading = false;
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
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
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
          onPressed: () => widget.onNavigate?.call(AppScreen.profile),
        ),
        title: const Text(
          'Ajouter un proche',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
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
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              if (_createdAmiProche != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF059669), size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Proche ajouté avec succès !',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Code de connexion :',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _createdAmiProche!.code,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Un email a été envoyé à ${_createdAmiProche!.email} avec ce code. ${_createdAmiProche!.prenom} pourra l\'utiliser pour se connecter en tant que proche.',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              AppInput(
                label: 'Nom',
                hint: 'Entrez le nom',
                controller: _nomCtrl,
                validator: _validateRequired,
              ),
              const SizedBox(height: 16),
              
              AppInput(
                label: 'Prénom',
                hint: 'Entrez le prénom',
                controller: _prenomCtrl,
                validator: _validateRequired,
              ),
              const SizedBox(height: 16),
              
              AppInput(
                label: 'Email',
                hint: 'exemple@email.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              
              AppInput(
                label: 'Téléphone (optionnel)',
                hint: '+33 6 12 34 56 78',
                controller: _telephoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Ajouter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
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
