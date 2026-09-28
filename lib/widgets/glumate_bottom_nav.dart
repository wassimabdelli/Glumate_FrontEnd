import 'package:flutter/material.dart';
import 'package:glumate_mobile/core/constants/app_screen.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';

class GluMateBottomNav extends StatelessWidget {
  const GluMateBottomNav({
    required this.currentScreen,
    required this.onNavigate,
    super.key,
  });
  final AppScreen currentScreen;
  final ValueChanged<AppScreen> onNavigate;

  @override
  Widget build(BuildContext context) {
    const items = <({AppScreen screen, IconData icon, String label})>[
      (screen: AppScreen.home, icon: Icons.home_rounded, label: 'Accueil'),
      (
        screen: AppScreen.ocrVision,
        icon: Icons.document_scanner_rounded,
        label: 'OCR & Vision',
      ),
      (
        screen: AppScreen.chatbot,
        icon: Icons.chat_bubble_rounded,
        label: 'Conseils',
      ),
      (screen: AppScreen.profile, icon: Icons.person_rounded, label: 'Profil'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 18),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onNavigate(item.screen),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: currentScreen == item.screen
                            ? AppColors.primary
                            : AppColors.subtle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: currentScreen == item.screen
                              ? AppColors.primary
                              : AppColors.subtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
