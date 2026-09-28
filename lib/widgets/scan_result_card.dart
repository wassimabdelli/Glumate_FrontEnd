import 'package:flutter/material.dart';
import 'package:glumate_mobile/core/constants/app_screen.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/widgets/status_badge.dart';

class ScanResultCard extends StatelessWidget {
  const ScanResultCard({
    required this.value,
    required this.status,
    required this.title,
    required this.color,
    required this.onReset,
    super.key,
  });
  final int value;
  final GlycemiaStatus status;
  final String title;
  final Color color;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.secondaryDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.secondaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '$value mg/dL',
                  style: TextStyle(
                    color: color,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                StatusBadge(status: status),
              ],
            ),
          ),
          TextButton(
            onPressed: onReset,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
              ),
            ),
            child: const Text('Rescanner une autre photo'),
          ),
        ],
      ),
    );
  }
}
