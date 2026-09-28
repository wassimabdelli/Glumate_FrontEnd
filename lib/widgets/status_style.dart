import 'package:flutter/material.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/core/constants/app_screen.dart';

class StatusStyle {
  const StatusStyle({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });
  final String label;
  final Color color;
  final Color background;
  final IconData icon;
}

StatusStyle statusStyle(GlycemiaStatus status) {
  switch (status) {
    case GlycemiaStatus.normal:
      return const StatusStyle(
        label: 'Normal',
        color: AppColors.secondaryDark,
        background: AppColors.goodBg,
        icon: Icons.check_circle,
      );
    case GlycemiaStatus.hypo:
      return const StatusStyle(
        label: 'Hypoglycemie',
        color: Color(0xFFDC2626),
        background: AppColors.badBg,
        icon: Icons.warning_amber_rounded,
      );
    case GlycemiaStatus.hyper:
      return const StatusStyle(
        label: 'Hyperglycemie',
        color: AppColors.accentDark,
        background: AppColors.warnBg,
        icon: Icons.trending_up,
      );
  }
}
