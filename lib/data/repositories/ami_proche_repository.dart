import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:glumate_mobile/core/services/api_client.dart';
import 'package:glumate_mobile/data/models/ami_proche_model.dart';

class AmiProcheRepository extends ChangeNotifier {
  final ApiClient _apiClient;

  AmiProcheRepository._(this._apiClient);

  static Future<AmiProcheRepository> create() async {
    final apiClient = await ApiClient.getInstance();
    return AmiProcheRepository._(apiClient);
  }

  Future<AmiProcheModel> createAmiProche({
    required int patientId,
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/ami-proche',
        data: {
          'patientId': patientId,
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'telephone': telephone,
        },
      );

      return AmiProcheModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<AmiProcheModel>> fetchAmiProches(int patientId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/ami-proche/patient/$patientId',
      );

      return (response.data! as List)
          .map((json) => AmiProcheModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    String message = 'Erreur lors de la gestion des proches';

    if (statusCode == 404) {
      message = 'Ressource non trouvée';
    } else if (statusCode == 400) {
      message = 'Données invalides';
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
