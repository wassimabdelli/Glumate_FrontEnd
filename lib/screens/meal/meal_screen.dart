import 'package:flutter/material.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/widgets/screen_header.dart';
import 'package:glumate_mobile/widgets/back_circle_button.dart';
import 'package:glumate_mobile/widgets/toggle_pills.dart';
import 'package:glumate_mobile/widgets/app_card.dart';
import 'package:glumate_mobile/widgets/action_placeholder.dart';
import 'package:glumate_mobile/widgets/summary_stat.dart';
import 'package:glumate_mobile/widgets/choice_pill.dart';
import 'package:glumate_mobile/widgets/app_input.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({required this.onBack, super.key});
  final VoidCallback onBack;

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  bool _scannerTab = true;
  bool _scanned = false;
  String _mealType = 'Dejeuner';
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();

  static const mealTypes = ['Petit-dejeuner', 'Dejeuner', 'Diner', 'Collation'];

  static const detectedItems = [
    ('Poulet roti', '150g', '0g', '248 kcal'),
    ('Riz basmati', '100g', '28g', '130 kcal'),
    ('Haricots verts', '80g', '6g', '28 kcal'),
    ("Huile d'olive", '10ml', '0g', '90 kcal'),
  ];

  static const suggestions = [
    ('Salade nicoise', '18g', '310 kcal'),
    ('Gratin de courgettes', '22g', '280 kcal'),
    ('Tartare de saumon', '8g', '340 kcal'),
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('meal-screen'),
      color: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            title: 'Analyse de repas',
            subtitle: 'IA de vision nutritionnelle',
            gradient: const [AppColors.secondary, AppColors.secondaryDark],
            leading: BackCircleButton(onTap: widget.onBack),
          ),
          Transform.translate(
            offset: const Offset(0, -16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  TogglePills(
                    firstLabel: 'Scanner image',
                    secondLabel: 'Saisie manuelle',
                    firstSelected: _scannerTab,
                    onFirstTap: () => setState(() => _scannerTab = true),
                    onSecondTap: () => setState(() => _scannerTab = false),
                    color: AppColors.secondary,
                    firstIcon: Icons.camera_alt_rounded,
                    secondIcon: Icons.edit_rounded,
                  ),
                  const SizedBox(height: 14),
                  if (_scannerTab)
                    Column(
                      children: [
                        AppCard(
                          child: !_scanned
                              ? ActionPlaceholder(
                                  icon: Icons.upload_rounded,
                                  title: 'Photographier votre repas',
                                  subtitle:
                                      "L'IA identifiera les aliments automatiquement",
                                  color: AppColors.secondary,
                                  background: AppColors.goodBg,
                                  borderColor: const Color(0xFFA7F3D0),
                                  onTap: () => setState(() => _scanned = true),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.secondaryDark,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Repas identifie par Vision IA',
                                          style: TextStyle(
                                            color: AppColors.secondaryDark,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ...detectedItems.map(
                                      (item) => Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.$1,
                                                    style: const TextStyle(
                                                      color: AppColors.text,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    item.$2,
                                                    style: const TextStyle(
                                                      color: AppColors.muted,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${item.$3} glucides',
                                                  style: const TextStyle(
                                                    color: AppColors.secondary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  item.$4,
                                                  style: const TextStyle(
                                                    color: AppColors.subtle,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 28),
                                    const Row(
                                      children: [
                                        Expanded(
                                          child: SummaryStat(
                                            value: '34g',
                                            label: 'Glucides',
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                        Expanded(
                                          child: SummaryStat(
                                            value: '496',
                                            label: 'Calories',
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Expanded(
                                          child: SummaryStat(
                                            value: '4',
                                            label: 'Aliments',
                                            color: AppColors.accentDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                        if (_scanned) ...[
                          const SizedBox(height: 14),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Type de repas',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: mealTypes
                                      .map(
                                        (type) => ChoicePill(
                                          label: type,
                                          selected: _mealType == type,
                                          color: AppColors.secondary,
                                          onTap: () => setState(() {
                                            _mealType = type;
                                          }),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: widget.onBack,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: const Text('Enregistrer ce repas'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    AppCard(
                      child: Column(
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: mealTypes
                                .map(
                                  (type) => ChoicePill(
                                    label: type,
                                    selected: _mealType == type,
                                    color: AppColors.secondary,
                                    onTap: () =>
                                        setState(() => _mealType = type),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          AppInput(
                            label: 'Description du repas',
                            hint: 'Ex: poulet grille avec riz et legumes...',
                            controller: _descriptionController,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          AppInput(
                            label: 'Glucides estimes (g)',
                            hint: '0',
                            controller: _carbsController,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _descriptionController.text.isEmpty
                                  ? null
                                  : widget.onBack,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text('Enregistrer'),
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
                        const Text(
                          'Suggestions de repas sains',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...suggestions.map(
                          (suggestion) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        suggestion.$1,
                                        style: const TextStyle(
                                          color: AppColors.text,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${suggestion.$3} · IG modere',
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  suggestion.$2,
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
