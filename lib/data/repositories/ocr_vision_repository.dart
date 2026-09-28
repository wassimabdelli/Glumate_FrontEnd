import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:glumate_mobile/core/config/app_config.dart';
import 'package:glumate_mobile/data/repositories/auth_repository.dart';

// ─── DTOs ────────────────────────────────────────────────────────────────────

class ReleveGlycemieResult {
  const ReleveGlycemieResult({
    required this.id,
    required this.valeurGlycemie,
    required this.dateHeure,
    required this.moment,
    required this.statut,
    this.notes,
    required this.userId,
  });

  final int? id;
  final double valeurGlycemie;
  final String dateHeure;
  final String moment;
  final String statut;
  final String? notes;
  final int userId;

  factory ReleveGlycemieResult.fromJson(Map<String, dynamic> j) =>
      ReleveGlycemieResult(
        id: j['id'] as int?,
        valeurGlycemie: (j['valeurGlycemie'] as num).toDouble(),
        dateHeure: j['dateHeure'] as String,
        moment: j['moment'] as String,
        statut: j['statut'] as String,
        notes: j['notes'] as String?,
        userId: j['userId'] as int,
      );
}

class MealAnalysisResult {
  const MealAnalysisResult({
    required this.id,
    required this.dateHeure,
    required this.typeRepas,
    required this.description,
    required this.estimationGlucides,
    required this.userId,
  });

  final int? id;
  final String dateHeure;
  final String typeRepas;
  final String description;
  final int estimationGlucides;
  final int userId;

  factory MealAnalysisResult.fromJson(Map<String, dynamic> j) =>
      MealAnalysisResult(
        id: j['id'] as int?,
        dateHeure: j['dateHeure'] as String,
        typeRepas: j['typeRepas'] as String,
        description: j['description'] as String,
        estimationGlucides: (j['estimationGlucides'] as num).toInt(),
        userId: j['userId'] as int,
      );
}

// ─── Modes d'analyse ─────────────────────────────────────────────────────────

enum OcrVisionMode { ocr, vision }

// ─── Service ─────────────────────────────────────────────────────────────────

class OcrVisionService extends ChangeNotifier {
  OcrVisionService(this._authService) {
    _fastApiDio = Dio(BaseOptions(
      baseUrl: AppConfig.fastApiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: const Duration(seconds: 60), // plus long pour l'analyse IA
    ));
  }

  final AuthService _authService;
  late final Dio _fastApiDio;

  OcrVisionMode mode = OcrVisionMode.ocr;
  bool isLoading = false;
  String? errorMessage;

  // Résultats OCR
  List<ReleveGlycemieResult> ocrResults = [];

  // Résultat Vision (dernier repas analysé)
  MealAnalysisResult? visionResult;

  // Historique Vision
  List<MealAnalysisResult> visionHistory = [];

  int? get _userId => _authService.currentUser?.id;

  void setMode(OcrVisionMode newMode) {
    if (mode == newMode) return;
    mode = newMode;
    errorMessage = null;
    notifyListeners();
  }

  // ── OCR : analyser une image de lecteur de glycémie ──────────────────────

  Future<void> extractGlycemiaFromImage(File imageFile) async {
    if (_userId == null) {
      errorMessage = 'Utilisateur non connecté';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split(Platform.pathSeparator).last,
        ),
        'user_id': _userId.toString(),
      });

      final response = await _fastApiDio.post<Map<String, dynamic>>(
        '/api/v1/ocr/extract-glycemia',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final body = response.data ?? {};
      final dataList = (body['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ReleveGlycemieResult.fromJson)
          .toList();

      ocrResults = dataList;
    } on DioException catch (e) {
      errorMessage = _dioError(e, 'Erreur lors de l\'analyse OCR.');
    } catch (e) {
      errorMessage = 'Erreur inattendue: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOcrHistory() async {
    if (_userId == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _fastApiDio.get<Map<String, dynamic>>(
        '/api/v1/ocr/results/$_userId',
      );
      final body = response.data ?? {};
      ocrResults = (body['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ReleveGlycemieResult.fromJson)
          .toList();
    } on DioException catch (e) {
      errorMessage = _dioError(e, 'Impossible de charger l\'historique OCR.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Vision : analyser une photo de repas ─────────────────────────────────

  Future<void> analyzeMealImage(File imageFile) async {
    if (_userId == null) {
      errorMessage = 'Utilisateur non connecté';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    visionResult = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split(Platform.pathSeparator).last,
        ),
        'user_id': _userId.toString(),
      });

      final response = await _fastApiDio.post<Map<String, dynamic>>(
        '/api/v1/vision/analyze-meal',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final body = response.data ?? {};
      visionResult = MealAnalysisResult.fromJson(body);
      // Ajouter en tête d'historique local
      if (visionResult != null) {
        visionHistory = [visionResult!, ...visionHistory];
      }
    } on DioException catch (e) {
      errorMessage = _dioError(e, 'Erreur lors de l\'analyse du repas.');
    } catch (e) {
      errorMessage = 'Erreur inattendue: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVisionHistory() async {
    if (_userId == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _fastApiDio.get<Map<String, dynamic>>(
        '/api/v1/vision/results/$_userId',
      );
      final body = response.data ?? {};
      visionHistory = (body['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MealAnalysisResult.fromJson)
          .toList();
    } on DioException catch (e) {
      errorMessage = _dioError(e, 'Impossible de charger l\'historique repas.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void clearResult() {
    ocrResults = [];
    visionResult = null;
    errorMessage = null;
    notifyListeners();
  }

  String _dioError(DioException e, String fallback) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Délai dépassé. Vérifiez votre connexion.';
      case DioExceptionType.connectionError:
        return 'Impossible de joindre le serveur IA.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 404) return 'Utilisateur introuvable (id $_userId).';
        final data = e.response?.data;
        if (data is Map) {
          final detail = data['detail'];
          if (detail is String && detail.isNotEmpty) return detail;
        }
        return fallback;
      default:
        return fallback;
    }
  }
}
