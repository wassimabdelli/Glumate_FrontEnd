import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/widgets/app_card.dart';
import 'package:glumate_mobile/widgets/screen_header.dart';
import 'package:glumate_mobile/widgets/back_circle_button.dart';
import 'package:glumate_mobile/widgets/data_list_tile.dart';
import 'package:glumate_mobile/data/repositories/auth_repository.dart';
import 'package:glumate_mobile/data/repositories/report_repository.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({required this.onBack, super.key});
  final VoidCallback onBack;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportService>().generate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Consumer<ReportService>(
      builder: (context, svc, _) {
        return Column(
          key: const ValueKey('report-screen'),
          children: [
            ScreenHeader(
              title: 'Rapport médical',
              subtitle: 'Généré par IA Gemini · Personnalisé',
              gradient: const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
              leading: BackCircleButton(onTap: widget.onBack),
              trailing: svc.report != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => svc.downloadPdf(svc.report!, user),
                          icon: const Icon(Icons.download_rounded,
                              color: Colors.white),
                          tooltip: 'Télécharger PDF',
                        ),
                        IconButton(
                          onPressed: () => svc.generate(),
                          icon: const Icon(Icons.refresh_rounded,
                              color: Colors.white),
                          tooltip: 'Régénérer',
                        ),
                      ],
                    )
                  : null,
            ),
            Expanded(
              child: svc.isLoading
                  ? _buildLoading()
                  : svc.errorMessage != null
                      ? _buildError(svc)
                      : svc.report == null
                          ? _buildEmpty(svc)
                          : _buildReport(svc.report!, user),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF7C3AED),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Gemini analyse votre dossier...',
              style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 8),
          const Text('Cela peut prendre 10 à 30 secondes',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError(ReportService svc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            Text(svc.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: svc.generate,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ReportService svc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.analytics_rounded,
              size: 48, color: AppColors.border),
          const SizedBox(height: 16),
          const Text('Aucun rapport généré',
              style: TextStyle(
                  color: AppColors.text, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: svc.generate,
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED)),
            icon: const Icon(Icons.analytics_rounded),
            label: const Text('Générer le rapport'),
          ),
        ],
      ),
    );
  }

  Widget _buildReport(MedicalReport r, dynamic user) {
    final dateStr = r.generatedAt.isNotEmpty
        ? r.generatedAt.substring(0, 10)
        : '—';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        AppCard(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user != null ? '${user.firstname} ${user.lastname}' : 'Patient',
                      style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text('Généré le $dateStr',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text('IA Gemini',
                          style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ReportSectionTitle(
                  icon: Icons.bar_chart_rounded,
                  title: 'Statistiques globales',
                  color: AppColors.primary),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      value: '${r.stats.nbMesuresTotal}',
                      label: 'Mesures totales',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatBox(
                      value: r.stats.moyenneGlycemie != null
                          ? '${r.stats.moyenneGlycemie!.toStringAsFixed(0)}'
                          : '—',
                      label: 'Moy. mg/dL',
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatBox(
                      value: '${r.stats.nbRepasAnalyses}',
                      label: 'Repas analysés',
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatusBar(
                      label: 'Normal',
                      count: r.stats.nbNormal,
                      total: r.stats.nbMesuresTotal,
                      color: AppColors.secondaryDark,
                      bg: AppColors.goodBg,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusBar(
                      label: 'Hypo',
                      count: r.stats.nbHypoglycemie,
                      total: r.stats.nbMesuresTotal,
                      color: const Color(0xFFDC2626),
                      bg: AppColors.badBg,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusBar(
                      label: 'Hyper',
                      count: r.stats.nbHyperglycemie,
                      total: r.stats.nbMesuresTotal,
                      color: AppColors.accentDark,
                      bg: AppColors.warnBg,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (r.releves.isNotEmpty) ...[
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: _ReportSectionTitle(
                    icon: Icons.monitor_heart_rounded,
                    title: '3 derniers relevés glycémiques',
                    color: AppColors.primary,
                  ),
                ),
                ...r.releves.map((rel) => _RelEveTile(releve: rel)),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        if (r.repas.isNotEmpty) ...[
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: _ReportSectionTitle(
                    icon: Icons.restaurant_rounded,
                    title: '3 derniers repas analysés',
                    color: AppColors.secondary,
                  ),
                ),
                ...r.repas.map((rep) => _RepasTile(repas: rep)),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ReportSectionTitle(
                icon: Icons.psychology_rounded,
                title: 'Analyse & Conseils IA',
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 12, color: Color(0xFF7C3AED)),
                    SizedBox(width: 5),
                    Text('Gemini 3.6 Flash',
                        style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                r.conseils,
                style: const TextStyle(
                    color: AppColors.text, fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                '⚠️ Ce rapport est généré par IA à titre informatif uniquement. '
                'Il ne remplace pas un avis médical professionnel.',
                style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportSectionTitle extends StatelessWidget {
  const _ReportSectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });
  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.bg,
  });
  final String label;
  final int count;
  final int total;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w900, fontSize: 18)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          Text('$pct%',
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RelEveTile extends StatelessWidget {
  const _RelEveTile({required this.releve});
  final ReportReleve releve;

  Color get _color {
    switch (releve.statut) {
      case 'HYPOGLYCEMIE':
        return const Color(0xFFDC2626);
      case 'HYPERGLYCEMIE':
        return AppColors.accentDark;
      default:
        return AppColors.secondaryDark;
    }
  }

  Color get _bg {
    switch (releve.statut) {
      case 'HYPOGLYCEMIE':
        return AppColors.badBg;
      case 'HYPERGLYCEMIE':
        return AppColors.warnBg;
      default:
        return AppColors.goodBg;
    }
  }

  String get _momentLabel {
    switch (releve.moment) {
      case 'A_JEUN': return 'À jeun';
      case 'AVANT_REPAS': return 'Avant repas';
      case 'APRES_REPAS': return 'Après repas';
      case 'COUCHER': return 'Coucher';
      default: return 'Autre';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DataListTile(
      icon: Icons.monitor_heart_rounded,
      iconColor: _color,
      iconBackground: _bg,
      title: '${releve.valeurGlycemie.toStringAsFixed(0)} mg/dL',
      subtitle: '${releve.dateHeure.length > 10 ? releve.dateHeure.substring(0, 10) : releve.dateHeure} · $_momentLabel',
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: _bg, borderRadius: BorderRadius.circular(99)),
            child: Text(releve.statut,
                style: TextStyle(
                    color: _color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
          if (releve.notes != null && releve.notes!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              releve.notes!.length > 20
                  ? '${releve.notes!.substring(0, 20)}...'
                  : releve.notes!,
              style:
                  const TextStyle(color: AppColors.subtle, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _RepasTile extends StatelessWidget {
  const _RepasTile({required this.repas});
  final ReportRepas repas;

  String get _typeLabel {
    switch (repas.typeRepas) {
      case 'PETIT_DEJEUNER': return 'Petit-déj.';
      case 'DEJEUNER': return 'Déjeuner';
      case 'DINER': return 'Dîner';
      default: return 'Collation';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DataListTile(
      icon: Icons.restaurant_rounded,
      iconColor: AppColors.secondary,
      iconBackground: AppColors.goodBg,
      title: _typeLabel,
      subtitle: repas.description.length > 55
          ? '${repas.description.substring(0, 55)}...'
          : repas.description,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${repas.estimationGlucides}g',
              style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
          const Text('glucides',
              style:
                  TextStyle(color: AppColors.subtle, fontSize: 10)),
        ],
      ),
    );
  }
}
