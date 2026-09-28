import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:glumate_mobile/core/config/app_config.dart';
import 'package:glumate_mobile/data/repositories/auth_repository.dart';

// ── DTOs ─────────────────────────────────────────────────────────────────────

class ReportReleve {
  const ReportReleve({
    required this.valeurGlycemie,
    required this.dateHeure,
    required this.moment,
    required this.statut,
    this.notes,
  });
  final double valeurGlycemie;
  final String dateHeure;
  final String moment;
  final String statut;
  final String? notes;

  factory ReportReleve.fromJson(Map<String, dynamic> j) => ReportReleve(
        valeurGlycemie: (j['valeurGlycemie'] as num).toDouble(),
        dateHeure: j['dateHeure'] as String,
        moment: j['moment'] as String? ?? 'AUTRE',
        statut: j['statut'] as String? ?? 'NORMAL',
        notes: j['notes'] as String?,
      );
}

class ReportRepas {
  const ReportRepas({
    required this.typeRepas,
    required this.dateHeure,
    required this.description,
    required this.estimationGlucides,
  });
  final String typeRepas;
  final String dateHeure;
  final String description;
  final int estimationGlucides;

  factory ReportRepas.fromJson(Map<String, dynamic> j) => ReportRepas(
        typeRepas: j['typeRepas'] as String? ?? 'COLLATION',
        dateHeure: j['dateHeure'] as String,
        description: j['description'] as String? ?? '',
        estimationGlucides: (j['estimationGlucides'] as num? ?? 0).toInt(),
      );
}

class ReportStats {
  const ReportStats({
    required this.nbMesuresTotal,
    required this.nbNormal,
    required this.nbHypoglycemie,
    required this.nbHyperglycemie,
    this.moyenneGlycemie,
    required this.nbRepasAnalyses,
  });
  final int nbMesuresTotal;
  final int nbNormal;
  final int nbHypoglycemie;
  final int nbHyperglycemie;
  final double? moyenneGlycemie;
  final int nbRepasAnalyses;

  factory ReportStats.fromJson(Map<String, dynamic> j) => ReportStats(
        nbMesuresTotal: (j['nbMesuresTotal'] as num? ?? 0).toInt(),
        nbNormal: (j['nbNormal'] as num? ?? 0).toInt(),
        nbHypoglycemie: (j['nbHypoglycemie'] as num? ?? 0).toInt(),
        nbHyperglycemie: (j['nbHyperglycemie'] as num? ?? 0).toInt(),
        moyenneGlycemie: j['moyenneGlycemie'] != null
            ? (j['moyenneGlycemie'] as num).toDouble()
            : null,
        nbRepasAnalyses: (j['nbRepasAnalyses'] as num? ?? 0).toInt(),
      );
}

class MedicalReport {
  const MedicalReport({
    required this.generatedAt,
    required this.releves,
    required this.repas,
    required this.stats,
    required this.conseils,
  });
  final String generatedAt;
  final List<ReportReleve> releves;
  final List<ReportRepas> repas;
  final ReportStats stats;
  final String conseils;

  factory MedicalReport.fromJson(Map<String, dynamic> j) => MedicalReport(
        generatedAt: j['generatedAt'] as String? ?? '',
        releves: (j['releves'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ReportReleve.fromJson)
            .toList(),
        repas: (j['repas'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ReportRepas.fromJson)
            .toList(),
        stats: ReportStats.fromJson(
            j['stats'] as Map<String, dynamic>? ?? {}),
        conseils: j['conseils'] as String? ?? '',
      );
}

// ── Service ──────────────────────────────────────────────────────────────────

class ReportService extends ChangeNotifier {
  ReportService(this._authService) {
    _fastApiDio = Dio(BaseOptions(
      baseUrl: AppConfig.fastApiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: const Duration(seconds: 90), // Gemini peut prendre du temps
    ));
  }

  final AuthService _authService;
  late final Dio _fastApiDio;

  MedicalReport? report;
  bool isLoading = false;
  String? errorMessage;

  int? get _userId => _authService.currentUser?.id;

  Future<void> generate() async {
    final uid = _userId;
    if (uid == null) {
      errorMessage = 'Utilisateur non connecté';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    report = null;
    notifyListeners();

    try {
      final response = await _fastApiDio.get<Map<String, dynamic>>(
        '/api/v1/report/$uid',
      );
      final body = response.data;
      if (body != null) {
        report = MedicalReport.fromJson(body);
      }
    } on DioException catch (e) {
      errorMessage = _err(e);
      debugPrint('[ReportService] Erreur: ${e.type} ${e.response?.statusCode} ${e.response?.data}');
    } catch (e) {
      errorMessage = 'Erreur inattendue: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    report = null;
    errorMessage = null;
    notifyListeners();
  }

  // Fonction statique de nettoyage des caractères accentués
  static String _cleanText(String text) {
    // Nettoyage agressif : remplacer tous les caractères non-ASCII
    String cleaned = '';
    for (int i = 0; i < text.length; i++) {
      int codeUnit = text.codeUnitAt(i);
      if (codeUnit < 128) {
        // Caractère ASCII standard
        cleaned += text[i];
      } else {
        // Caractère non-ASCII : essayer de remplacer
        String char = text[i];
        switch (char) {
          case 'é': case 'è': case 'ê': case 'ë': cleaned += 'e'; break;
          case 'É': case 'È': case 'Ê': case 'Ë': cleaned += 'E'; break;
          case 'à': case 'â': case 'ä': cleaned += 'a'; break;
          case 'À': case 'Â': case 'Ä': cleaned += 'A'; break;
          case 'ô': case 'ö': cleaned += 'o'; break;
          case 'Ô': case 'Ö': cleaned += 'O'; break;
          case 'î': case 'ï': cleaned += 'i'; break;
          case 'Î': case 'Ï': cleaned += 'I'; break;
          case 'ù': case 'û': case 'ü': cleaned += 'u'; break;
          case 'Ù': case 'Û': case 'Ü': cleaned += 'U'; break;
          case 'ç': cleaned += 'c'; break;
          case 'Ç': cleaned += 'C'; break;
          case 'œ': cleaned += 'oe'; break;
          case 'Œ': cleaned += 'OE'; break;
          case 'æ': cleaned += 'ae'; break;
          case 'Æ': cleaned += 'AE'; break;
          default: cleaned += ''; break; // Supprimer les autres caractères
        }
      }
    }
    return cleaned;
  }

  Future<void> downloadPdf(MedicalReport report, dynamic user) async {
    try {
      final pdf = pw.Document();
      
      final dateStr = report.generatedAt.isNotEmpty
          ? report.generatedAt.substring(0, 10)
          : '—';
      final userName = user != null ? '${user.firstname} ${user.lastname}' : 'Patient';

      debugPrint('[ReportService] Conseils bruts: "${report.conseils}"');
      debugPrint('[ReportService] Conseils vide: ${report.conseils.isEmpty}');

      final cleanUserName = _cleanText(userName);
      final cleanConseils = _cleanText(report.conseils);

      debugPrint('[ReportService] Conseils apres nettoyage: '
          '"${cleanConseils.length > 100 ? cleanConseils.substring(0, 100) : cleanConseils}..."');

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header avec fond violet
            pw.Container(
              padding: pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF7C3AED),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Rapport Medical - GluMate',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Patient: $cleanUserName',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 14),
                  ),
                  pw.Text('Genere le: $dateStr',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            
            // Statistiques
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF3F4F6),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Statistiques',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF7C3AED),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Mesures totales: ${report.stats.nbMesuresTotal}')),
                      pw.Expanded(child: pw.Text('Normales: ${report.stats.nbNormal}')),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Hypoglycemies: ${report.stats.nbHypoglycemie}')),
                      pw.Expanded(child: pw.Text('Hyperglycemies: ${report.stats.nbHyperglycemie}')),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  if (report.stats.moyenneGlycemie != null)
                    pw.Text('Moyenne glycemie: ${report.stats.moyenneGlycemie} mg/dL'),
                  pw.Text('Repas analyses: ${report.stats.nbRepasAnalyses}'),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            
            // Dernieres glycemies
            pw.Text('Dernieres glycemies (10)',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF7C3AED),
              ),
            ),
            pw.SizedBox(height: 12),
            ...report.releves.take(10).map((r) {
              final cleanNotes = r.notes != null ? _cleanText(r.notes!) : '';
              final displayNotes = cleanNotes.length > 200
                  ? '${cleanNotes.substring(0, 200)}...'
                  : cleanNotes;

              return pw.Container(
                margin: pw.EdgeInsets.only(bottom: 8),
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('${r.valeurGlycemie} mg/dL',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                        ),
                        pw.Spacer(),
                        pw.Text(r.statut,
                          style: pw.TextStyle(
                            color: r.statut == 'NORMAL' ? PdfColors.green : 
                                   r.statut == 'HYPOGLYCEMIE' ? PdfColors.red : PdfColors.orange,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('${r.dateHeure} - ${_cleanText(r.moment)}',
                      style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                    ),
                    if (displayNotes.isNotEmpty)
                      pw.Text(displayNotes,
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 24),
            
            // Derniers repas
            if (report.repas.isNotEmpty) ...[
              pw.Text('Derniers repas',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF7C3AED),
                ),
              ),
              pw.SizedBox(height: 12),
              ...report.repas.take(5).map((r) {
                final cleanDescription = _cleanText(r.description);
                final displayDescription = cleanDescription.length > 200 
                    ? '${cleanDescription.substring(0, 200)}...' 
                    : cleanDescription;
                
                return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 8),
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_cleanText(r.typeRepas),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(displayDescription,
                        style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('${r.estimationGlucides}g glucides'),
                          pw.Spacer(),
                          pw.Text(r.dateHeure,
                            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 24),
            ],
            
            // Conseils
            pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFFFF7ED),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFFED7AA)),
              ),
              child: pw.Text('Conseils',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFFEA580C),
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              cleanConseils.isNotEmpty ? cleanConseils : 'Aucun conseil disponible',
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 24),
            
            // Avertissement
            pw.Container(
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFFEE2E2),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromInt(0xFECACA)),
              ),
              child: pw.Text('Attention: Ce rapport est genere par IA a titre informatif uniquement. Il ne remplace pas un avis medical professionnel.',
                style: pw.TextStyle(
                  color: PdfColor.fromInt(0xDC2626),
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ];
        },
      ));

      // Sauvegarder dans le vrai dossier Downloads public
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        directory = await getDownloadsDirectory();
      }
      
      if (directory == null || !directory.existsSync()) {
        errorMessage = 'Impossible d\'acceder au repertoire Downloads';
        notifyListeners();
        return;
      }
      
      final file = File('${directory.path}/rapport_glumate_$dateStr.pdf');
      await file.writeAsBytes(await pdf.save());
      
      debugPrint('[ReportService] PDF sauvegarde: ${file.path}');
    } catch (e, stackTrace) {
      debugPrint('[ReportService] Erreur lors de la generation du PDF: $e');
      debugPrint('[ReportService] StackTrace: $stackTrace');
      errorMessage = 'Erreur lors de la generation du PDF: ${e.toString()}';
      notifyListeners();
    }
  }

  String _err(DioException e) {
    switch (e.type) {
      case DioExceptionType.receiveTimeout:
        return 'L\'IA prend trop de temps. Réessayez.';
      case DioExceptionType.connectionError:
        return 'Serveur IA injoignable.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 404) return 'Utilisateur introuvable.';
        final data = e.response?.data;
        if (data is Map) {
          final d = data['detail'];
          if (d is String && d.isNotEmpty) return d;
        }
        return 'Erreur serveur ($status).';
      default:
        return 'Impossible de générer le rapport.';
    }
  }
}
