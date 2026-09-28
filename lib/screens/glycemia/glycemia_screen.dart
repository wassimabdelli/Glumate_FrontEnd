import 'package:flutter/material.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/data/models/glycemia_entry.dart';
import 'package:glumate_mobile/widgets/status_badge.dart';
import 'package:glumate_mobile/widgets/screen_header.dart';
import 'package:glumate_mobile/widgets/back_circle_button.dart';
import 'package:glumate_mobile/widgets/toggle_pills.dart';
import 'package:glumate_mobile/widgets/app_card.dart';
import 'package:glumate_mobile/widgets/action_placeholder.dart';
import 'package:glumate_mobile/widgets/scan_result_card.dart';
import 'package:glumate_mobile/widgets/choice_pill.dart';
import 'package:glumate_mobile/widgets/app_input.dart';

class GlycemiaScreen extends StatefulWidget {
  const GlycemiaScreen({required this.onBack, super.key});
  final VoidCallback onBack;

  @override
  State<GlycemiaScreen> createState() => _GlycemiaScreenState();
}

class _GlycemiaScreenState extends State<GlycemiaScreen> {
  bool _scannerTab = true;
  bool _scanned = false;
  String _selectedMoment = 'A jeun';
  final TextEditingController _manualValueController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _manualValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moments = ['A jeun', 'Avant repas', 'Apres repas', 'Au coucher'];
    final scannedValue = 134;
    final manualValue = int.tryParse(_manualValueController.text);

    return Container(
      key: const ValueKey('glycemia-screen'),
      color: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            title: 'Glycemie',
            subtitle: 'Enregistrer une mesure',
            gradient: const [AppColors.primary, AppColors.primaryDark],
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
                    color: AppColors.primary,
                    firstIcon: Icons.camera_alt_rounded,
                    secondIcon: Icons.edit_rounded,
                  ),
                  const SizedBox(height: 14),
                  if (_scannerTab)
                    Column(
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Photo du lecteur de glycemie',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (!_scanned)
                                ActionPlaceholder(
                                  icon: Icons.upload_rounded,
                                  title: 'Telecharger une photo',
                                  subtitle: 'ou prendre une photo directement',
                                  color: AppColors.primary,
                                  background: const Color(0xFFEFF6FF),
                                  borderColor: const Color(0xFFBFDBFE),
                                  onTap: () => setState(() => _scanned = true),
                                )
                              else
                                ScanResultCard(
                                  value: scannedValue,
                                  status: getGlycemiaStatus(scannedValue),
                                  title: 'Valeur detectee par OCR',
                                  color: AppColors.primary,
                                  onReset: () => setState(() => _scanned = false),
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
                                  'Moment de la mesure',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: moments
                                      .map(
                                        (moment) => ChoicePill(
                                          label: moment,
                                          selected: _selectedMoment == moment,
                                          color: AppColors.primary,
                                          onTap: () => setState(() {
                                            _selectedMoment = moment;
                                          }),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                                AppInput(
                                  label: 'Notes',
                                  hint: 'Ex: apres une seance de sport...',
                                  controller: _notesController,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: widget.onBack,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: const Text(
                                      'Enregistrer la mesure',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
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
                          AppInput(
                            label: 'Valeur glycemique (mg/dL)',
                            hint: '0',
                            controller: _manualValueController,
                            keyboardType: TextInputType.number,
                          ),
                          if (manualValue != null) ...[
                            const SizedBox(height: 10),
                            StatusBadge(status: getGlycemiaStatus(manualValue)),
                          ],
                          const SizedBox(height: 16),
                          AppInput(
                            label: 'Date et heure',
                            hint: '18/08/2026 08:15',
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: moments
                                .map(
                                  (moment) => ChoicePill(
                                    label: moment,
                                    selected: _selectedMoment == moment,
                                    color: AppColors.primary,
                                    onTap: () => setState(() {
                                      _selectedMoment = moment;
                                    }),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          AppInput(
                            label: 'Notes',
                            hint: 'Remarques sur cette mesure...',
                            controller: _notesController,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: manualValue == null ? null : widget.onBack,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
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
                          'Mesures recentes',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...kGlycemiaHistory
                            .take(4)
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${entry.value} mg/dL',
                                            style: const TextStyle(
                                              color: AppColors.text,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${entry.date} · ${entry.moment}',
                                            style: const TextStyle(
                                              color: AppColors.subtle,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(status: entry.status),
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
