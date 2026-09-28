import 'package:flutter/material.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/widgets/status_style.dart';
import 'package:glumate_mobile/data/models/glycemia_entry.dart';

class RangeBar extends StatelessWidget {
  const RangeBar({required this.value, super.key});
  final int value;

  @override
  Widget build(BuildContext context) {
    final clamped = ((value - 50) / 200).clamp(0.0, 1.0);
    final color = statusStyle(getGlycemiaStatus(value)).color;

    return Column(
      children: [
        SizedBox(
          height: 16,
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Positioned(
                left: 50,
                right: 70,
                top: 5,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(-1 + (clamped * 2), 0),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('50', style: TextStyle(fontSize: 10, color: AppColors.subtle)),
            Text(
              '70-180 mg/dL',
              style: TextStyle(fontSize: 10, color: AppColors.muted),
            ),
            Text(
              '250',
              style: TextStyle(fontSize: 10, color: AppColors.subtle),
            ),
          ],
        ),
      ],
    );
  }
}
