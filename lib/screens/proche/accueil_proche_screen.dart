import 'package:flutter/material.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/core/constants/app_screen.dart';
import 'package:glumate_mobile/data/repositories/proche_auth_repository.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccueilProcheScreen extends StatefulWidget {
  const AccueilProcheScreen({this.onNavigate, super.key});
  final ValueChanged<AppScreen>? onNavigate;

  @override
  State<AccueilProcheScreen> createState() => _AccueilProcheScreenState();
}

class _AccueilProcheScreenState extends State<AccueilProcheScreen> {
  String? _patientNom;
  String? _patientPrenom;

  @override
  void initState() {
    super.initState();
    _loadPatientInfo();
  }

  Future<void> _loadPatientInfo() async {
    final procheAuthRepo = context.read<ProcheAuthRepository>();
    final nom = await procheAuthRepo.getPatientNom();
    final prenom = await procheAuthRepo.getPatientPrenom();
    if (mounted) {
      setState(() {
        _patientNom = nom;
        _patientPrenom = prenom;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('proche_access_token');
    await prefs.remove('proche_patient_nom');
    await prefs.remove('proche_patient_prenom');
    if (mounted) {
      widget.onNavigate?.call(AppScreen.login);
    }
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
          'Accueil Proche',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              if (_patientPrenom != null && _patientNom != null)
                Text(
                  'Vous êtes le contact de confiance de $_patientPrenom $_patientNom',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              if (_patientPrenom != null && _patientNom != null)
                Text(
                  'Vous recevrez une alerte si $_patientPrenom ne confirme pas sa vérification nocturne.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _logout,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Se déconnecter',
                    style: TextStyle(
                      fontSize: 15,
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
