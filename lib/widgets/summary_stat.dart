import 'package:flutter/material.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';

class SummaryStat extends StatelessWidget {
  const SummaryStat({
    required this.value,
    required this.label,
    required this.color,
    super.key,
    this.lightText = false,
  });
  final String value;
  final String label;
  final Color color;
  final bool lightText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: lightText ? const Color(0xCCFFFFFF) : AppColors.subtle,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
