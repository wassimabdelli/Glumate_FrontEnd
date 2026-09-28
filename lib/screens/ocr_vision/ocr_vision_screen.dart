import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/widgets/app_card.dart';
import 'package:glumate_mobile/widgets/screen_header.dart';
import 'package:glumate_mobile/widgets/data_list_tile.dart';
import 'package:glumate_mobile/data/repositories/ocr_vision_repository.dart';

class OcrVisionScreen extends StatefulWidget {
  const OcrVisionScreen({super.key});

  @override
  State<OcrVisionScreen> createState() => _OcrVisionScreenState();
}

class _OcrVisionScreenState extends State<OcrVisionScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<OcrVisionService>();
      if (svc.mode == OcrVisionMode.ocr) {
        svc.loadOcrHistory();
      } else {
        svc.loadVisionHistory();
      }
    });
  }

  Future<void> _pickAndAnalyze() async {
    final svc = context.read<OcrVisionService>();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                svc.mode == OcrVisionMode.ocr
                    ? 'Analyser un lecteur de glycémie'
                    : 'Analyser une assiette',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                svc.mode == OcrVisionMode.ocr
                    ? 'Prenez ou choisissez une photo de votre lecteur'
                    : 'Prenez ou choisissez une photo de votre repas',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Caméra',
                      color: AppColors.primary,
                      onTap: () => Navigator.pop(ctx, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Galerie',
                      color: AppColors.secondary,
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    if (svc.mode == OcrVisionMode.ocr) {
      await svc.extractGlycemiaFromImage(file);
    } else {
      await svc.analyzeMealImage(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OcrVisionService>(
      builder: (context, svc, _) {
        return Column(
          key: const ValueKey('ocr-vision-screen'),
          children: [
            ScreenHeader(
              title: 'OCR & Vision IA',
              subtitle: 'Analyse automatique par intelligence artificielle',
              gradient: const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
              bottom: _ModeToggle(
                isOcr: svc.mode == OcrVisionMode.ocr,
                onOcrTap: () {
                  svc.setMode(OcrVisionMode.ocr);
                  svc.loadOcrHistory();
                },
                onVisionTap: () {
                  svc.setMode(OcrVisionMode.vision);
                  svc.loadVisionHistory();
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: [
                  _AnalyzeButton(
                    mode: svc.mode,
                    isLoading: svc.isLoading,
                    onTap: svc.isLoading ? null : _pickAndAnalyze,
                  ),
                  const SizedBox(height: 20),

                  if (svc.errorMessage != null) ...[
                    _ErrorBanner(
                      message: svc.errorMessage!,
                      onDismiss: svc.clearError,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (svc.mode == OcrVisionMode.ocr) ...[
                    if (svc.ocrResults.isNotEmpty) ...[
                      _SectionTitle(
                        title: 'Relevés extraits',
                        count: svc.ocrResults.length,
                      ),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: svc.ocrResults
                              .map((r) => _OcrResultTile(result: r))
                              .toList(),
                        ),
                      ),
                    ] else if (!svc.isLoading) ...[
                      _EmptyState(
                        icon: Icons.monitor_heart_rounded,
                        title: 'Aucun relevé',
                        subtitle:
                            'Prenez en photo votre lecteur de glycémie pour extraire automatiquement la valeur.',
                      ),
                    ],
                  ],

                  if (svc.mode == OcrVisionMode.vision) ...[
                    if (svc.visionResult != null) ...[
                      _SectionTitle(title: 'Dernier repas analysé'),
                      const SizedBox(height: 10),
                      _MealResultCard(result: svc.visionResult!),
                      const SizedBox(height: 20),
                    ],
                    if (svc.visionHistory.isNotEmpty) ...[
                      _SectionTitle(
                        title: 'Historique repas',
                        count: svc.visionHistory.length,
                      ),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: svc.visionHistory
                              .map((r) => _VisionHistoryTile(result: r))
                              .toList(),
                        ),
                      ),
                    ] else if (!svc.isLoading && svc.visionResult == null) ...[
                      _EmptyState(
                        icon: Icons.restaurant_rounded,
                        title: 'Aucun repas analysé',
                        subtitle:
                            'Prenez en photo votre assiette pour estimer les glucides et adapter votre insuline.',
                      ),
                    ],
                  ],

                  if (svc.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.isOcr,
    required this.onOcrTap,
    required this.onVisionTap,
  });
  final bool isOcr;
  final VoidCallback onOcrTap;
  final VoidCallback onVisionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              icon: Icons.monitor_heart_rounded,
              label: 'Glycémie OCR',
              active: isOcr,
              onTap: onOcrTap,
            ),
          ),
          Expanded(
            child: _ModeTab(
              icon: Icons.restaurant_rounded,
              label: 'Repas Vision',
              active: !isOcr,
              onTap: onVisionTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? const Color(0xFF7C3AED) : const Color(0xAAFFFFFF),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color:
                    active ? const Color(0xFF7C3AED) : const Color(0xAAFFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  const _AnalyzeButton({
    required this.mode,
    required this.isLoading,
    required this.onTap,
  });
  final OcrVisionMode mode;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isOcr = mode == OcrVisionMode.ocr;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOcr
                ? [const Color(0xFF7C3AED), const Color(0xFF5B21B6)]
                : [AppColors.secondary, AppColors.secondaryDark],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isOcr
                      ? const Color(0xFF7C3AED)
                      : AppColors.secondary)
                  .withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Icon(
                      isOcr
                          ? Icons.document_scanner_rounded
                          : Icons.camera_enhance_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
            ),
            const SizedBox(height: 14),
            Text(
              isLoading
                  ? 'Analyse en cours...'
                  : isOcr
                      ? 'Scanner un lecteur de glycémie'
                      : 'Analyser une assiette',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLoading
                  ? "L'IA Gemini traite votre image"
                  : isOcr
                      ? 'Galerie ou caméra · JPEG, PNG, WebP'
                      : 'Estimation glucides · Conseils diabète',
              style: const TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.count});
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.badBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded,
                color: Color(0xFFDC2626), size: 18),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 34, color: const Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OcrResultTile extends StatelessWidget {
  const _OcrResultTile({required this.result});
  final ReleveGlycemieResult result;

  Color get _statusColor {
    switch (result.statut) {
      case 'HYPOGLYCEMIE':
        return const Color(0xFFDC2626);
      case 'HYPERGLYCEMIE':
        return AppColors.accentDark;
      default:
        return AppColors.secondaryDark;
    }
  }

  Color get _statusBg {
    switch (result.statut) {
      case 'HYPOGLYCEMIE':
        return AppColors.badBg;
      case 'HYPERGLYCEMIE':
        return AppColors.warnBg;
      default:
        return AppColors.goodBg;
    }
  }

  IconData get _statusIcon {
    switch (result.statut) {
      case 'HYPOGLYCEMIE':
        return Icons.warning_amber_rounded;
      case 'HYPERGLYCEMIE':
        return Icons.trending_up_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  String get _momentLabel {
    switch (result.moment) {
      case 'A_JEUN':
        return 'À jeun';
      case 'AVANT_REPAS':
        return 'Avant repas';
      case 'APRES_REPAS':
        return 'Après repas';
      case 'COUCHER':
        return 'Coucher';
      default:
        return 'Autre';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DataListTile(
      icon: Icons.monitor_heart_rounded,
      iconColor: _statusColor,
      iconBackground: _statusBg,
      title: '${result.valeurGlycemie.toStringAsFixed(0)} mg/dL',
      subtitle: result.notes ?? _momentLabel,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusBg,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon, size: 12, color: _statusColor),
                const SizedBox(width: 4),
                Text(
                  result.statut,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _momentLabel,
            style: const TextStyle(color: AppColors.subtle, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MealResultCard extends StatelessWidget {
  const _MealResultCard({required this.result});
  final MealAnalysisResult result;

  String get _typeLabel {
    switch (result.typeRepas) {
      case 'PETIT_DEJEUNER':
        return 'Petit-déjeuner';
      case 'DEJEUNER':
        return 'Déjeuner';
      case 'DINER':
        return 'Dîner';
      default:
        return 'Collation';
    }
  }

  Color get _typeColor {
    switch (result.typeRepas) {
      case 'PETIT_DEJEUNER':
        return AppColors.accent;
      case 'DEJEUNER':
        return AppColors.primary;
      case 'DINER':
        return const Color(0xFF7C3AED);
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _typeLabel,
                  style: TextStyle(
                    color: _typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, AppColors.secondaryDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.grain_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      '${result.estimationGlucides}g',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'glucides',
                      style: TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            result.description,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.subtle),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  result.estimationGlucides > 60
                      ? 'Repas riche en glucides — vérifiez votre insuline'
                      : result.estimationGlucides > 30
                          ? 'Apport glucidique modéré'
                          : 'Apport glucidique faible',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisionHistoryTile extends StatelessWidget {
  const _VisionHistoryTile({required this.result});
  final MealAnalysisResult result;

  String get _typeLabel {
    switch (result.typeRepas) {
      case 'PETIT_DEJEUNER':
        return 'Petit-dej.';
      case 'DEJEUNER':
        return 'Déjeuner';
      case 'DINER':
        return 'Dîner';
      default:
        return 'Collation';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DataListTile(
      icon: Icons.restaurant_rounded,
      iconColor: AppColors.secondary,
      iconBackground: AppColors.goodBg,
      title: _typeLabel,
      subtitle: result.description.length > 60
          ? '${result.description.substring(0, 60)}...'
          : result.description,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${result.estimationGlucides}g',
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const Text(
            'glucides',
            style: TextStyle(color: AppColors.subtle, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
