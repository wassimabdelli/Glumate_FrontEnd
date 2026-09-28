import 'package:flutter/material.dart';
import 'package:glumate_mobile/widgets/app_card.dart';
import 'package:glumate_mobile/widgets/choice_pill_button.dart';

class TogglePills extends StatelessWidget {
  const TogglePills({
    required this.firstLabel,
    required this.secondLabel,
    required this.firstSelected,
    required this.onFirstTap,
    required this.onSecondTap,
    required this.color,
    super.key,
    this.firstIcon,
    this.secondIcon,
  });
  final String firstLabel;
  final String secondLabel;
  final bool firstSelected;
  final VoidCallback onFirstTap;
  final VoidCallback onSecondTap;
  final Color color;
  final IconData? firstIcon;
  final IconData? secondIcon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: ChoicePillButton(
              label: firstLabel,
              selected: firstSelected,
              color: color,
              icon: firstIcon,
              onTap: onFirstTap,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ChoicePillButton(
              label: secondLabel,
              selected: !firstSelected,
              color: color,
              icon: secondIcon,
              onTap: onSecondTap,
            ),
          ),
        ],
      ),
    );
  }
}
