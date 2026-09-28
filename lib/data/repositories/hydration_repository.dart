import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:glumate_mobile/core/services/api_client.dart';

class HydrationTargetResponse {
  final double targetLiters;
  final int totalGlasses;
  final double glassSizeLiters;

  HydrationTargetResponse({
    required this.targetLiters,
    required this.totalGlasses,
    required this.glassSizeLiters,
  });

  factory HydrationTargetResponse.fromJson(Map<String, dynamic> json) {
    return HydrationTargetResponse(
      targetLiters: (json['targetLiters'] as num).toDouble(),
      totalGlasses: json['totalGlasses'] as int,
      glassSizeLiters: (json['glassSizeLiters'] as num).toDouble(),
    );
  }
}

class HydrationRepository extends ChangeNotifier {
  final ApiClient _apiClient;

  HydrationRepository._(this._apiClient);

  static Future<HydrationRepository> create() async {
    final apiClient = await ApiClient.getInstance();
    return HydrationRepository._(apiClient);
  }

  Future<HydrationTargetResponse> fetchHydrationTarget(int userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/hydration/target/$userId',
      );

      return HydrationTargetResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<HydrationTargetResponse> fetchHydrationTargetNullable(int? userId) async {
    if (userId == null) {
      throw Exception('User ID is null');
    }
    return fetchHydrationTarget(userId);
  }

  Exception _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    String message = 'Erreur lors de la récupération de l\'objectif d\'hydratation';

    if (statusCode == 404) {
      message = 'Utilisateur non trouvé';
    } else if (statusCode == 500) {
      message = 'Erreur interne du serveur';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Délai de connexion dépassé. Vérifiez votre réseau.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Impossible de se connecter au serveur.';
    }

    return Exception(message);
  }
}
