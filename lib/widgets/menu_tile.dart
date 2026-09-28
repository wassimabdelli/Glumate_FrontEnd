import 'package:flutter/material.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';

class MenuTile extends StatelessWidget {
  const MenuTile({
    required this.icon,
    required this.label,
    super.key,
    this.accent = false,
    this.isLast = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool accent;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: accent ? AppColors.primary : AppColors.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: accent ? AppColors.primary : AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accent ? AppColors.primary : AppColors.subtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
