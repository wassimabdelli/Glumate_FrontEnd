import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:glumate_mobile/core/services/api_client.dart';
import 'package:glumate_mobile/data/repositories/auth_repository.dart';

// ── DTOs ─────────────────────────────────────────────────────────────────────

class DayTrend {
  const DayTrend({required this.day, required this.value});
  final String day;
  final double value;

  factory DayTrend.fromJson(Map<String, dynamic> j) => DayTrend(
        day: j['day'] as String? ?? '',
        value: (j['value'] as num? ?? 0).toDouble(),
      );
}

class DashboardData {
  const DashboardData({
    this.lastGlycemiaValue,
    this.lastGlycemiaDateHeure,
    this.lastGlycemiaMoment,
    this.lastGlycemiaStatut,
    this.avgGlycemia7d,
    this.minGlycemia7d,
    this.maxGlycemia7d,
    this.totalMeasures7d = 0,
    this.trend7d = const [],
    this.lastMealType,
    this.lastMealDescription,
    this.lastMealGlucides,
    this.lastMealDateHeure,
    this.totalMeasures = 0,
    this.totalMeals = 0,
  });

  final double? lastGlycemiaValue;
  final String? lastGlycemiaDateHeure;
  final String? lastGlycemiaMoment;
  final String? lastGlycemiaStatut;
  final double? avgGlycemia7d;
  final double? minGlycemia7d;
  final double? maxGlycemia7d;
  final int totalMeasures7d;
  final List<DayTrend> trend7d;
  final String? lastMealType;
  final String? lastMealDescription;
  final int? lastMealGlucides;
  final String? lastMealDateHeure;
  final int totalMeasures;
  final int totalMeals;

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
        lastGlycemiaValue: j['lastGlycemiaValue'] != null
            ? (j['lastGlycemiaValue'] as num).toDouble()
            : null,
        lastGlycemiaDateHeure: j['lastGlycemiaDateHeure'] as String?,
        lastGlycemiaMoment: j['lastGlycemiaMoment'] as String?,
        lastGlycemiaStatut: j['lastGlycemiaStatut'] as String?,
        avgGlycemia7d: j['avgGlycemia7d'] != null
            ? (j['avgGlycemia7d'] as num).toDouble()
            : null,
        minGlycemia7d: j['minGlycemia7d'] != null
            ? (j['minGlycemia7d'] as num).toDouble()
            : null,
        maxGlycemia7d: j['maxGlycemia7d'] != null
            ? (j['maxGlycemia7d'] as num).toDouble()
            : null,
        totalMeasures7d: (j['totalMeasures7d'] as num? ?? 0).toInt(),
        trend7d: (j['trend7d'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DayTrend.fromJson)
            .toList(),
        lastMealType: j['lastMealType'] as String?,
        lastMealDescription: j['lastMealDescription'] as String?,
        lastMealGlucides: j['lastMealGlucides'] != null
            ? (j['lastMealGlucides'] as num).toInt()
            : null,
        lastMealDateHeure: j['lastMealDateHeure'] as String?,
        totalMeasures: (j['totalMeasures'] as num? ?? 0).toInt(),
        totalMeals: (j['totalMeals'] as num? ?? 0).toInt(),
      );
}

// ── Service ──────────────────────────────────────────────────────────────────

class DashboardService extends ChangeNotifier {
  DashboardService(this._apiClient, this._authService) {
    // Se recharge automatiquement quand AuthService change (login/logout)
    _authService.addListener(_onAuthChanged);
  }

  final ApiClient _apiClient;
  final AuthService _authService;

  DashboardData? data;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (_authService.isAuthenticated && _authService.currentUser?.id != null) {
      load();
    } else if (!_authService.isAuthenticated) {
      // Reset au logout
      data = null;
      errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> load() async {
    final uid = _authService.currentUser?.id;
    if (uid == null) {
      // Log pour debug
      debugPrint('[DashboardService] userId est null — impossible de charger');
      return;
    }

    debugPrint('[DashboardService] Chargement dashboard pour userId=$uid');
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/dashboard/summary/$uid',
      );
      final body = response.data;
      debugPrint('[DashboardService] Réponse reçue: $body');
      if (body != null) {
        data = DashboardData.fromJson(body);
        debugPrint('[DashboardService] trend7d count: ${data!.trend7d.length}');
        debugPrint('[DashboardService] lastGlycemia: ${data!.lastGlycemiaValue}');
      }
    } on DioException catch (e) {
      errorMessage = _err(e);
      debugPrint('[DashboardService] Erreur DIO: ${e.type} — ${e.response?.statusCode} — ${e.response?.data}');
    } catch (e) {
      errorMessage = 'Erreur inattendue';
      debugPrint('[DashboardService] Erreur inattendue: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _err(DioException e) {
    if (e.type == DioExceptionType.connectionError) return 'Serveur injoignable';
    if (e.response?.statusCode == 401) return 'Session expirée';
    return 'Impossible de charger le tableau de bord';
  }
}
