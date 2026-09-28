import 'package:flutter/material.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/core/constants/app_screen.dart';
import 'package:glumate_mobile/widgets/status_style.dart';
import 'package:glumate_mobile/data/models/glycemia_entry.dart';
import 'package:glumate_mobile/data/repositories/dashboard_repository.dart';

// Constante temporaire pour le mock si non disponible
const kGlycemiaTrend = [
  {'day': 'Lun', 'value': 105},
  {'day': 'Mar', 'value': 120},
  {'day': 'Mer', 'value': 95},
  {'day': 'Jeu', 'value': 140},
  {'day': 'Ven', 'value': 110},
  {'day': 'Sam', 'value': 125},
  {'day': 'Dim', 'value': 115},
];

class TrendChart extends StatelessWidget {
  const TrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final item in kGlycemiaTrend) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${item['value']}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.subtle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: ((item['value'] as int) - 60)
                                .clamp(20, 100)
                                .toDouble(),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [AppColors.primary, Color(0x662563EB)],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['day'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _LegendChip(label: 'Glycemie', color: AppColors.primary),
              SizedBox(width: 12),
              _LegendChip(
                label: 'Zone cible',
                color: Color(0xFFDCFCE7),
                textColor: AppColors.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
    this.textColor = AppColors.muted,
  });
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyTrendChart extends StatelessWidget {
  const _EmptyTrendChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart_rounded,
              size: 40, color: AppColors.border),
          const SizedBox(height: 12),
          const Text(
            'Aucune mesure sur 7 jours',
            style: TextStyle(
              color: AppColors.subtle,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scannez votre lecteur de glycémie pour commencer',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.subtle, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class DynamicTrendChart extends StatelessWidget {
  const DynamicTrendChart({required this.trend, super.key});
  final List<DayTrend> trend;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const TrendChart();
    final maxVal = trend.map((t) => t.value).reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal > 0 ? maxVal : 200.0;

    return SizedBox(
      height: 170,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.map((item) {
                final barH = ((item.value / safeMax) * 100).clamp(4.0, 100.0);
                final status = item.value > 0
                    ? getGlycemiaStatus(item.value.toInt())
                    : GlycemiaStatus.normal;
                final barColor = item.value == 0
                    ? AppColors.border
                    : statusStyle(status).color.withValues(alpha: 0.8);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (item.value > 0)
                          Text(
                            item.value.toStringAsFixed(0),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.subtle),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          height: barH,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: barColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(item.day,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _LegendChip(label: 'Normal', color: AppColors.secondary),
              SizedBox(width: 12),
              _LegendChip(
                  label: 'Hyperglycémie',
                  color: AppColors.warnBg,
                  textColor: AppColors.accentDark),
            ],
          ),
        ],
      ),
    );
  }
}
