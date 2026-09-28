import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/core/constants/app_screen.dart';
import 'package:glumate_mobile/widgets/app_card.dart';
import 'package:glumate_mobile/widgets/screen_header.dart';
import 'package:glumate_mobile/data/repositories/auth_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onNavigate, super.key});
  final ValueChanged<AppScreen> onNavigate;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    final initials = user != null
        ? '${user.firstname.isNotEmpty ? user.firstname[0] : ''}${user.lastname.isNotEmpty ? user.lastname[0] : ''}'
            .toUpperCase()
        : 'U';

    // ── Cibles glycémiques depuis le profil ──────────────────────────────────
    final cibleMin = user?.cibleGlycemiqueMin;
    final cibleMax = user?.cibleGlycemiqueMax;
    // Convertir g/L → mg/dL si les valeurs semblent être en g/L (< 10)
    final cibleMinMg = cibleMin != null
        ? (cibleMin < 10 ? (cibleMin * 1000).round() : cibleMin.round())
        : 70;
    final cibleMaxMg = cibleMax != null
        ? (cibleMax < 10 ? (cibleMax * 1000).round() : cibleMax.round())
        : 180;

    // ── IMC ─────────────────────────────────────────────────────────────────
    String imcLabel = '—';
    String imcStatus = '';
    if (user?.weight != null && user?.height != null && user!.height! > 0) {
      final h = user.height! / 100;
      final imc = user.weight! / (h * h);
      imcLabel = imc.toStringAsFixed(1);
      imcStatus = imc < 18.5
          ? 'Sous-poids'
          : imc < 25
              ? 'Normal'
              : imc < 30
                  ? 'Surpoids'
                  : 'Obésité';
    }

    // ── Âge ─────────────────────────────────────────────────────────────────
    String ageLabel = '—';
    if (user?.dateOfBirth != null) {
      final age = DateTime.now().difference(user!.dateOfBirth!).inDays ~/ 365;
      ageLabel = '$age ans';
    }

    return ListView(
      key: const ValueKey('home-screen'),
      padding: EdgeInsets.zero,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        ScreenHeader(
          title: user?.fullName ?? 'GluMate',
          subtitle: 'Bonjour',
          gradient: const [AppColors.primary, AppColors.primaryDark],
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0x33FFFFFF),
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          bottom: Row(
            children: [
              Expanded(
                child: DashboardStat(
                  title: 'Âge',
                  value: ageLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DashboardStat(
                  title: 'Poids',
                  value: user?.weight != null
                      ? '${user!.weight!.toStringAsFixed(0)} kg'
                      : '—',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DashboardStat(
                  title: 'IMC',
                  value: imcLabel,
                ),
              ),
            ],
          ),
        ),

        Transform.translate(
          offset: const Offset(0, -16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [

                // ── Carte profil médical ──────────────────────────────────
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.medical_information_rounded,
                                size: 20, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('Profil médical',
                                style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                          ),
                          IconButton(
                            onPressed: () => onNavigate(AppScreen.profile),
                            icon: const Icon(Icons.chevron_right_rounded,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _MedicalChip(
                              label: 'Cible à jeun',
                              value: '$cibleMinMg–$cibleMaxMg mg/dL',
                              icon: Icons.track_changes_rounded,
                              color: AppColors.primary,
                              bg: const Color(0xFFEFF6FF),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MedicalChip(
                              label: 'IMC',
                              value: imcStatus.isNotEmpty
                                  ? '$imcLabel · $imcStatus'
                                  : '—',
                              icon: Icons.monitor_weight_rounded,
                              color: AppColors.secondary,
                              bg: AppColors.goodBg,
                            ),
                          ),
                        ],
                      ),
                      if (user?.height != null || user?.gender != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (user?.height != null)
                              Expanded(
                                child: _MedicalChip(
                                  label: 'Taille',
                                  value:
                                      '${user!.height!.toStringAsFixed(0)} cm',
                                  icon: Icons.straighten_rounded,
                                  color: AppColors.accentDark,
                                  bg: AppColors.warnBg,
                                ),
                              ),
                            if (user?.height != null && user?.gender != null)
                              const SizedBox(width: 10),
                            if (user?.gender != null)
                              Expanded(
                                child: _MedicalChip(
                                  label: 'Sexe',
                                  value: user!.gender!,
                                  icon: Icons.person_rounded,
                                  color: const Color(0xFF7C3AED),
                                  bg: const Color(0xFFF5F3FF),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Dernière glycémie (placeholder) ──────────────────────
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionRow(
                        icon: Icons.monitor_heart_outlined,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: AppColors.primary,
                        title: 'Dernière glycémie',
                        onTap: () => onNavigate(AppScreen.ocrVision),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('—',
                              style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(width: 6),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text('mg/dL',
                                style: TextStyle(
                                    color: AppColors.subtle,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.goodBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.document_scanner_rounded,
                                    size: 13, color: AppColors.secondaryDark),
                                SizedBox(width: 4),
                                Text('Scanner pour mesurer',
                                    style: TextStyle(
                                        color: AppColors.secondaryDark,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Afficher la cible glycémique du profil
                      _RangeBarProfile(
                          cibleMin: cibleMinMg, cibleMax: cibleMaxMg),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Dernier repas ─────────────────────────────────────────
                AppCard(
                  child: Column(
                    children: [
                      _sectionRow(
                        icon: Icons.restaurant_menu_rounded,
                        iconBg: AppColors.goodBg,
                        iconColor: AppColors.secondary,
                        title: 'Dernier repas',
                        onTap: () => onNavigate(AppScreen.ocrVision),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => onNavigate(AppScreen.ocrVision),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 4),
                          child: Column(
                            children: [
                              Icon(Icons.add_a_photo_rounded,
                                  size: 32,
                                  color: AppColors.secondary.withValues(
                                      alpha: 0.5)),
                              const SizedBox(height: 8),
                              const Text('Analysez votre prochain repas',
                                  style: TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                'IA Vision · Estimation glucides · Adapté diabète',
                                style: TextStyle(
                                    color: AppColors.subtle.withValues(
                                        alpha: 0.8),
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Actions rapides ───────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.document_scanner_rounded,
                        title: 'Scanner\nglycémie',
                        color: AppColors.primary,
                        background: const Color(0xFFEFF6FF),
                        onTap: () => onNavigate(AppScreen.ocrVision),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.restaurant_rounded,
                        title: 'Analyser\nrepas',
                        color: AppColors.secondary,
                        background: AppColors.goodBg,
                        onTap: () => onNavigate(AppScreen.ocrVision),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.chat_bubble_rounded,
                        title: 'Conseils\nmédicaux',
                        color: AppColors.accent,
                        background: AppColors.warnBg,
                        onTap: () => onNavigate(AppScreen.chatbot),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Conseil personnalisé basé sur le profil ───────────────
                _PersonalizedAdviceCard(user: user),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _sectionRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
        ),
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _MedicalChip extends StatelessWidget {
  const _MedicalChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeBarProfile extends StatelessWidget {
  const _RangeBarProfile({required this.cibleMin, required this.cibleMax});
  final int cibleMin;
  final int cibleMax;

  @override
  Widget build(BuildContext context) {
    const rangeMin = 50.0;
    const rangeMax = 350.0;
    final leftFraction =
        ((cibleMin - rangeMin) / (rangeMax - rangeMin)).clamp(0.0, 1.0);
    final rightFraction =
        ((cibleMax - rangeMin) / (rangeMax - rangeMin)).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          height: 16,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final w = constraints.maxWidth;
              return Stack(
                children: [
                  Positioned(
                    top: 5,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    left: w * leftFraction,
                    width: w * (rightFraction - leftFraction),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.goodBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('50',
                style: TextStyle(fontSize: 10, color: AppColors.subtle)),
            Text(
              'Cible : $cibleMin–$cibleMax mg/dL',
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
            const Text('350',
                style: TextStyle(fontSize: 10, color: AppColors.subtle)),
          ],
        ),
      ],
    );
  }
}

class _PersonalizedAdviceCard extends StatelessWidget {
  const _PersonalizedAdviceCard({required this.user});
  final dynamic user; 

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    double? imc;
    if (user.weight != null && user.height != null && user.height > 0) {
      final h = user.height / 100.0;
      imc = user.weight / (h * h);
    }

    final List<(IconData, Color, String, String)> conseils = [
      if (imc != null && imc >= 25)
        (
          Icons.directions_walk_rounded,
          AppColors.secondary,
          'Activité physique',
          '30 min de marche par jour aide à réduire la glycémie et l\'IMC.',
        ),
      if (user.cibleGlycemiqueMax != null)
        (
          Icons.lunch_dining_rounded,
          AppColors.primary,
          'Alimentation',
          'Évitez les glucides rapides. Votre cible post-prandiale : < ${(user.cibleGlycemiqueMax < 10 ? user.cibleGlycemiqueMax * 1000 : user.cibleGlycemiqueMax).toStringAsFixed(0)} mg/dL.',
        ),
      (
        Icons.monitor_heart_rounded,
        AppColors.accentDark,
        'Surveillance',
        'Mesurez votre glycémie régulièrement avec l\'OCR pour un suivi précis.',
      ),
    ];

    if (conseils.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded,
                  size: 18, color: AppColors.accentDark),
              SizedBox(width: 8),
              Text('Conseils personnalisés',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          ...conseils.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.$2.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(c.$1, size: 18, color: c.$2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.$3,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                          const SizedBox(height: 3),
                          Text(c.$4,
                              style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class DashboardStat extends StatelessWidget {
  const DashboardStat({required this.title, required this.value, super.key});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.background,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String title;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
