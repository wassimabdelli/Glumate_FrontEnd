import 'package:flutter/material.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/core/constants/app_screen.dart';
import 'package:glumate_mobile/data/repositories/auth_repository.dart';
import 'package:glumate_mobile/data/repositories/hydration_repository.dart';
import 'package:glumate_mobile/core/services/hydration_notification_service.dart';
import 'package:glumate_mobile/widgets/summary_stat.dart';
import 'package:glumate_mobile/widgets/app_card.dart';
import 'package:glumate_mobile/widgets/info_row.dart';
import 'package:glumate_mobile/widgets/switch_tile.dart';
import 'package:glumate_mobile/widgets/menu_tile.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.onLogout, this.onNavigate, super.key});
  final Future<void> Function() onLogout;
  final ValueChanged<AppScreen>? onNavigate;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;
  bool _darkMode = false;
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      await widget.onLogout();
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _handleNotificationToggle(bool value) async {
    setState(() => _notifications = value);
    
    if (value) {
      // Enable hydration notifications
      try {
        final auth = context.read<AuthService>();
        final user = auth.currentUser;
        if (user != null) {
          final hydrationRepo = context.read<HydrationRepository>();
          final notificationService = context.read<HydrationNotificationService>();
          
          final target = await hydrationRepo.fetchHydrationTargetNullable(user.id);
          await notificationService.saveTargetGlasses(target.totalGlasses);
          await notificationService.scheduleNotifications(target.totalGlasses);
        }
      } catch (e) {
        debugPrint('Error enabling hydration notifications: $e');
        setState(() => _notifications = false);
      }
    } else {
      // Disable hydration notifications
      try {
        final notificationService = context.read<HydrationNotificationService>();
        await notificationService.cancelAllNotifications();
      } catch (e) {
        debugPrint('Error disabling hydration notifications: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    final initials = user != null
        ? '${user.firstname.isNotEmpty ? user.firstname[0] : ''}${user.lastname.isNotEmpty ? user.lastname[0] : ''}'
            .toUpperCase()
        : 'U';
    final fullName = user?.fullName ?? 'Utilisateur GluMate';
    final age = user?.dateOfBirth != null
        ? '${DateTime.now().difference(user!.dateOfBirth!).inDays ~/ 365} ans'
        : '';
    final displaySubtitle = user?.gender != null || age.isNotEmpty
        ? '${user?.gender ?? ''}${age.isNotEmpty ? ' · $age' : ''}'
        : 'Profil utilisateur';

    final infoRows = <(String, String)>[
      ('Prenom', user?.firstname ?? '-'),
      ('Nom', user?.lastname ?? '-'),
      ('Email', user?.email ?? '-'),
      (
        'Date de naissance',
        user?.dateOfBirth != null
            ? '${user!.dateOfBirth!.day.toString().padLeft(2, '0')}/${user.dateOfBirth!.month.toString().padLeft(2, '0')}/${user.dateOfBirth!.year}'
            : '-'
      ),
      ('Poids', user?.weight != null ? '${user!.weight!.toStringAsFixed(1)} kg' : '-'),
      ('Taille', user?.height != null ? '${user!.height!.toStringAsFixed(0)} cm' : '-'),
    ];

    final medicalRows = [
      ('Type de diabete', 'Type 2'),
      ('HbA1c cible', '< 7%'),
      (
        'Glycemie cible a jeun',
        user?.cibleGlycemiqueMin != null && user?.cibleGlycemiqueMax != null
            ? '${user!.cibleGlycemiqueMin!.toStringAsFixed(0)}-${user.cibleGlycemiqueMax!.toStringAsFixed(0)} mg/dL'
            : '80-130 mg/dL'
      ),
      ('Glycemie post-prandiale', '< 180 mg/dL'),
    ];

    final urgenceRows = [
      if (user?.contactUrgenceNom != null)
        ('Contact urgence', user!.contactUrgenceNom!),
      if (user?.contactUrgenceTel != null)
        ('Tel urgence', user!.contactUrgenceTel!),
    ];

    return ListView(
      key: const ValueKey('profile-screen'),
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0x33FFFFFF),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displaySubtitle,
                style: const TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Expanded(
                    child: SummaryStat(
                      value: '47',
                      label: 'Mesures',
                      color: Colors.white,
                      lightText: true,
                    ),
                  ),
                  Expanded(
                    child: SummaryStat(
                      value: '83',
                      label: 'Repas',
                      color: Colors.white,
                      lightText: true,
                    ),
                  ),
                  Expanded(
                    child: SummaryStat(
                      value: '28',
                      label: 'Jours actifs',
                      color: Colors.white,
                      lightText: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations personnelles',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...infoRows
                          .map((entry) => InfoRow(label: entry.$1, value: entry.$2)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parametres medicaux',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...medicalRows.map(
                        (entry) => InfoRow(
                          label: entry.$1,
                          value: entry.$2,
                          accentValue: true,
                        ),
                      ),
                      if (urgenceRows.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 24),
                        ...urgenceRows.map(
                          (e) => InfoRow(label: e.$1, value: e.$2),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preferences',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SwitchTile(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications rappels',
                        value: _notifications,
                        onChanged: _handleNotificationToggle,
                      ),
                      const SizedBox(height: 10),
                      SwitchTile(
                        icon: Icons.dark_mode_outlined,
                        label: 'Mode sombre',
                        value: _darkMode,
                        onChanged: (value) => setState(() => _darkMode = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      MenuTile(
                        icon: Icons.edit_rounded,
                        label: 'Modifier mon profil',
                        onTap: () => widget.onNavigate?.call(AppScreen.modifierProfil),
                      ),
                      MenuTile(
                        icon: Icons.person_add_rounded,
                        label: 'Ajouter un proche',
                        onTap: () => widget.onNavigate?.call(AppScreen.ajouterProche),
                      ),
                      MenuTile(
                        icon: Icons.water_drop_rounded,
                        label: 'Hydratation',
                        onTap: () => widget.onNavigate?.call(AppScreen.hydratation),
                      ),
                      // ── Rapport médical ──
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.onNavigate?.call(AppScreen.report),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.analytics_rounded,
                                    color: Colors.white, size: 22),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Générer mon rapport médical',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14)),
                                      SizedBox(height: 2),
                                      Text('IA Gemini · Analyse personnalisée',
                                          style: TextStyle(
                                              color: Color(0xCCFFFFFF),
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded,
                                    color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoggingOut ? null : _handleLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: _isLoggingOut
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFDC2626),
                            ),
                          )
                        : const Icon(Icons.logout_rounded),
                    label: Text(
                      _isLoggingOut ? 'Deconnexion...' : 'Se deconnecter',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
