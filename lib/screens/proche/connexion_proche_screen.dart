import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/core/constants/app_screen.dart';
import 'package:glumate_mobile/widgets/app_input.dart';
import 'package:glumate_mobile/data/repositories/proche_auth_repository.dart';

class ConnexionProcheScreen extends StatefulWidget {
  const ConnexionProcheScreen({this.onNavigate, super.key});
  final ValueChanged<AppScreen>? onNavigate;

  @override
  State<ConnexionProcheScreen> createState() => _ConnexionProcheScreenState();
}

class _ConnexionProcheScreenState extends State<ConnexionProcheScreen> {
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String? _errorMessage;

  String? _validateCode(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ requis';
    if (v.trim().length != 5) return 'Le code doit contenir 5 chiffres';
    if (!RegExp(r'^\d{5}$').hasMatch(v.trim())) return 'Le code doit contenir uniquement des chiffres';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final procheAuthRepo = context.read<ProcheAuthRepository>();
      await procheAuthRepo.verifyCode(_codeCtrl.text.trim());

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        widget.onNavigate?.call(AppScreen.accueilProche);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
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
          onPressed: () => widget.onNavigate?.call(AppScreen.login),
        ),
        title: const Text(
          'Connexion Proche',
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

              const Text(
                'Entrez le code à 5 chiffres',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ce code vous a été envoyé par email',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 32),

              AppInput(
                label: 'Code',
                hint: '12345',
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                validator: _validateCode,
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
                          'Se connecter',
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
