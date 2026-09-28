import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:glumate_mobile/core/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProcheAuthRepository extends ChangeNotifier {
  final ApiClient _apiClient;

  ProcheAuthRepository._(this._apiClient);

  static Future<ProcheAuthRepository> create() async {
    final apiClient = await ApiClient.getInstance();
    return ProcheAuthRepository._(apiClient);
  }

  Future<VerifyCodeResponse> verifyCode(String code) async {
    try {
      // Get FCM token
      final messaging = FirebaseMessaging.instance;
      final deviceToken = await messaging.getToken();
      
      if (deviceToken == null) {
        throw Exception('Impossible de récupérer le token FCM');
      }

      // Determine platform
      final platform = Platform.isAndroid ? 'android' : 'ios';

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/ami-proche/verify-code',
        data: {
          'code': code,
          'deviceToken': deviceToken,
          'platform': platform,
        },
      );

      final verifyResponse = VerifyCodeResponse.fromJson(response.data!);

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('proche_access_token', verifyResponse.accessToken);
      await prefs.setString('proche_patient_nom', verifyResponse.patientNom);
      await prefs.setString('proche_patient_prenom', verifyResponse.patientPrenom);

      return verifyResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateDeviceToken() async {
    try {
      // Get access token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('proche_access_token');
      
      if (accessToken == null) {
        throw Exception('Token d\'accès non trouvé. Veuillez vous reconnecter.');
      }

      // Get current FCM token
      final messaging = FirebaseMessaging.instance;
      final deviceToken = await messaging.getToken();
      
      if (deviceToken == null) {
        throw Exception('Impossible de récupérer le token FCM');
      }

      // Determine platform
      final platform = Platform.isAndroid ? 'android' : 'ios';

      await _apiClient.put(
        '/api/v1/ami-proche/device-token',
        data: {
          'deviceToken': deviceToken,
          'platform': platform,
        },
        options: Options(
          headers: {
            'X-Proche-Access-Token': accessToken,
          },
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('proche_access_token');
  }

  Future<String?> getPatientNom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('proche_patient_nom');
  }

  Future<String?> getPatientPrenom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('proche_patient_prenom');
  }

  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('proche_access_token');
    await prefs.remove('proche_patient_nom');
    await prefs.remove('proche_patient_prenom');
  }

  Future<void> confirmerAlerteVue(int verificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('proche_access_token');

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Token d\'accès non trouvé. Veuillez vous reconnecter.');
      }

      await _apiClient.post<void>(
        '/api/v1/verification-nocturne/$verificationId/alerte-vue',
        options: Options(
          headers: {
            'X-Proche-Access-Token': accessToken,
          },
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    String message = 'Erreur lors de la connexion proche';

    if (statusCode == 404) {
      message = 'Code invalide';
    } else if (statusCode == 401) {
      message = 'Token d\'accès invalide';
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

class VerifyCodeResponse {
  final String accessToken;
  final String patientNom;
  final String patientPrenom;

  VerifyCodeResponse({
    required this.accessToken,
    required this.patientNom,
    required this.patientPrenom,
  });

  factory VerifyCodeResponse.fromJson(Map<String, dynamic> json) {
    return VerifyCodeResponse(
      accessToken: json['accessToken'] as String? ?? '',
      patientNom: json['patientNom'] as String? ?? '',
      patientPrenom: json['patientPrenom'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'patientNom': patientNom,
      'patientPrenom': patientPrenom,
    };
  }
}
