import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/core/constants/app_screen.dart';
import 'package:glumate_mobile/widgets/app_card.dart';
import 'package:glumate_mobile/widgets/app_input.dart';
import 'package:glumate_mobile/data/repositories/auth_repository.dart';
import 'package:glumate_mobile/data/repositories/proche_auth_repository.dart';
import 'package:glumate_mobile/data/models/login_request_model.dart';
import 'package:glumate_mobile/data/models/register_request_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.onLoginSuccess, this.onNavigate, super.key});
  final VoidCallback onLoginSuccess;
  final ValueChanged<AppScreen>? onNavigate;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthMode _mode = AuthMode.login;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  final _firstnameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  final _forgotEmailCtrl = TextEditingController();
  final _procheCodeCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _firstnameCtrl.dispose();
    _lastnameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _forgotEmailCtrl.dispose();
    _procheCodeCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? const Color(0xFFDC2626) : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ requis';
    final emailRegex = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(v.trim())) return 'Email invalide';
    return null;
  }

  String? _validatePwd(String? v) {
    if (v == null || v.isEmpty) return 'Champ requis';
    if (v.length < 6) return 'Minimum 6 caracteres';
    return null;
  }

  String? _validateRequired(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ requis';
    return null;
  }

  String? _validateProcheCode(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ requis';
    final codeRegex = RegExp(r'^\d{5}$');
    if (!codeRegex.hasMatch(v.trim())) return 'Code invalide (5 chiffres requis)';
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
      if (_mode == AuthMode.login) {
        await auth.login(LoginRequestModel(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        ));
        _showSnack('Connexion reussie !');
        widget.onLoginSuccess();
      } else if (_mode == AuthMode.register) {
        if (_passwordCtrl.text != _confirmPwdCtrl.text) {
          setState(() => _errorMessage = 'Les mots de passe ne correspondent pas');
          return;
        }
        await auth.register(RegisterRequestModel(
          firstname: _firstnameCtrl.text,
          lastname: _lastnameCtrl.text,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        ));
        _showSnack('Compte cree avec succes !');
        widget.onLoginSuccess();
      } else if (_mode == AuthMode.proche) {
        final procheAuth = context.read<ProcheAuthRepository>();
        await procheAuth.verifyCode(_procheCodeCtrl.text);
        _showSnack('Connexion reussie !');
        widget.onNavigate?.call(AppScreen.accueilProche);
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        _showSnack('Lien de reinitialisation envoye par email');
        setState(() => _mode = AuthMode.login);
      }
    } on Exception catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('login-screen'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE), Color(0xFFE0F2FE)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 44, 24, 32),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D2563EB),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.monitor_heart_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'GluMate',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Votre compagnon diabete intelligent',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (_mode != AuthMode.forgot) _authTabs(),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: AppCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_mode == AuthMode.forgot) ...[
                    TextButton.icon(
                      onPressed: () => setState(() => _mode = AuthMode.login),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Retour'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mot de passe oublie',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 18),
                      child: Text(
                        'Entrez votre email pour recevoir un lien de reinitialisation.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                    AppInput(
                      label: 'Adresse email',
                      hint: 'marie.dupont@email.com',
                      controller: _forgotEmailCtrl,
                      validator: _validateEmail,
                    ),
                  ],
                  if (_mode == AuthMode.register) ...[
                    Row(
                      children: [
                        Expanded(
                          child: AppInput(
                            label: 'Prenom',
                            hint: 'Marie',
                            controller: _firstnameCtrl,
                            validator: _validateRequired,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppInput(
                            label: 'Nom',
                            hint: 'Dupont',
                            controller: _lastnameCtrl,
                            validator: _validateRequired,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_mode == AuthMode.login || _mode == AuthMode.register)
                    AppInput(
                      label: 'Adresse email',
                      hint: 'marie.dupont@email.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                  if (_mode == AuthMode.login || _mode == AuthMode.register) ...[
                    const SizedBox(height: 16),
                    AppInput(
                      label: 'Mot de passe',
                      hint: '••••••••',
                      obscureText: !_showPassword,
                      controller: _passwordCtrl,
                      validator: _validatePwd,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.subtle,
                        ),
                      ),
                    ),
                  ],
                  if (_mode == AuthMode.register) ...[
                    const SizedBox(height: 16),
                    AppInput(
                      label: 'Confirmer le mot de passe',
                      hint: '••••••••',
                      obscureText: !_showConfirmPassword,
                      controller: _confirmPwdCtrl,
                      validator: _validatePwd,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() {
                            _showConfirmPassword = !_showConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.subtle,
                        ),
                      ),
                    ),
                  ],
                  if (_mode == AuthMode.proche)
                    AppInput(
                      label: 'Code de connexion',
                      hint: 'Entrez le code à 5 chiffres reçu par email',
                      controller: _procheCodeCtrl,
                      keyboardType: TextInputType.number,
                      validator: _validateProcheCode,
                    ),
                  if (_mode == AuthMode.login)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() => _mode = AuthMode.forgot);
                          _errorMessage = null;
                        },
                        child: const Text('Mot de passe oublie ?'),
                      ),
                    ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.badBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
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
                          : Text(
                              switch (_mode) {
                                AuthMode.login => 'Se connecter',
                                AuthMode.register => 'Creer mon compte',
                                AuthMode.forgot => 'Envoyer le lien',
                                AuthMode.proche => 'Rejoindre en tant que proche',
                              },
                              style: const TextStyle(
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
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Donnees securisees selon RGPD & HDS',
              style: TextStyle(
                color: AppColors.subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _authTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _authTabButton(
              label: 'Connexion',
              active: _mode == AuthMode.login,
              onTap: () {
                setState(() {
                  _mode = AuthMode.login;
                  _errorMessage = null;
                });
              },
            ),
          ),
          Expanded(
            child: _authTabButton(
              label: 'Inscription',
              active: _mode == AuthMode.register,
              onTap: () {
                setState(() {
                  _mode = AuthMode.register;
                  _errorMessage = null;
                });
              },
            ),
          ),
          Expanded(
            child: _authTabButton(
              label: 'Proche',
              active: _mode == AuthMode.proche,
              onTap: () {
                setState(() {
                  _mode = AuthMode.proche;
                  _errorMessage = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _authTabButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
