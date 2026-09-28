import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:glumate_mobile/core/services/api_client.dart';
import 'package:glumate_mobile/core/services/storage_service.dart';
import 'package:glumate_mobile/data/models/auth_response_model.dart';
import 'package:glumate_mobile/data/models/login_request_model.dart';
import 'package:glumate_mobile/data/models/register_request_model.dart';
import 'package:glumate_mobile/data/models/user_model.dart';


class AuthService extends ChangeNotifier {
  final ApiClient _apiClient;
  final StorageService _storage;

  bool _isAuthenticated = false;
  UserModel? _currentUser;

  AuthService._(this._apiClient, this._storage);

  static Future<AuthService> create() async {
    final apiClient = await ApiClient.getInstance();
    final storage = await StorageService.getInstance();
    final service = AuthService._(apiClient, storage);
    await service._loadSavedSession();
    return service;
  }

  bool get isAuthenticated => _isAuthenticated;
  UserModel? get currentUser => _currentUser;
  String? get token => _storage.getToken();

  Future<void> _loadSavedSession() async {
    final savedUser = _storage.getUser();
    final savedToken = _storage.getToken();
    if (savedUser != null && savedToken != null && savedToken.isNotEmpty) {
      _isAuthenticated = true;
      _currentUser = savedUser;
      notifyListeners();
      registerFcmToken();
    }
  }

  Future<AuthResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: request.toJson(),
      );

      final authResponse = AuthResponseModel.fromJson(response.data!);

      await _storage.saveToken(authResponse.accessToken);
      await _storage.saveUser(authResponse.user);

      _isAuthenticated = true;
      _currentUser = authResponse.user;
      notifyListeners();
      registerFcmToken();

      return authResponse;
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: request.toJson(),
      );

      final authResponse = AuthResponseModel.fromJson(response.data!);

      await _storage.saveToken(authResponse.accessToken);
      await _storage.saveUser(authResponse.user);

      _isAuthenticated = true;
      _currentUser = authResponse.user;
      notifyListeners();
      registerFcmToken();

      return authResponse;
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<UserModel> getCurrentProfile() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/users/profile',
      );
      final user = UserModel.fromJson(response.data!);
      await _storage.saveUser(user);
      _currentUser = user;
      notifyListeners();
      return user;
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserModel> updateProfile({
    String? phone,
    String? dateOfBirth,
    String? gender,
    double? weight,
    double? height,
    double? cibleGlycemiqueMin,
    double? cibleGlycemiqueMax,
    String? contactUrgenceNom,
    String? contactUrgenceTel,
    String? typeDiabete,
    String? traitementsActuels,
    String? regimeInsuline,
    bool? insuffisanceRenale,
    double? dfg,
    bool? maladieCardiovasculaire,
    bool? grossesse,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (phone != null) data['phone'] = phone;
      if (dateOfBirth != null) data['dateOfBirth'] = dateOfBirth;
      if (gender != null) data['gender'] = gender;
      if (weight != null) data['weight'] = weight;
      if (height != null) data['height'] = height;
      if (cibleGlycemiqueMin != null) data['cibleGlycemiqueMin'] = cibleGlycemiqueMin;
      if (cibleGlycemiqueMax != null) data['cibleGlycemiqueMax'] = cibleGlycemiqueMax;
      if (contactUrgenceNom != null) data['contactUrgenceNom'] = contactUrgenceNom;
      if (contactUrgenceTel != null) data['contactUrgenceTel'] = contactUrgenceTel;
      if (typeDiabete != null) data['typeDiabete'] = typeDiabete;
      if (traitementsActuels != null) data['traitementsActuels'] = traitementsActuels;
      if (regimeInsuline != null) data['regimeInsuline'] = regimeInsuline;
      if (insuffisanceRenale != null) data['insuffisanceRenale'] = insuffisanceRenale;
      if (dfg != null) data['dfg'] = dfg;
      if (maladieCardiovasculaire != null) data['maladieCardiovasculaire'] = maladieCardiovasculaire;
      if (grossesse != null) data['grossesse'] = grossesse;

      final response = await _apiClient.put<Map<String, dynamic>>(
        '/api/v1/users/profile',
        data: data,
      );
      final user = UserModel.fromJson(response.data!);
      await _storage.saveUser(user);
      _currentUser = user;
      notifyListeners();
      return user;
    } on DioException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> registerFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final deviceToken = await messaging.getToken();

      if (deviceToken == null || deviceToken.isEmpty) {
        debugPrint('[AuthService] Impossible de recuperer le token FCM');
        return;
      }

      if (!_isAuthenticated) {
        return;
      }

      await _apiClient.put<void>(
        '/api/v1/users/fcm-token',
        data: {'fcmToken': deviceToken},
      );
      debugPrint('[AuthService] FCM token enregistre avec succes');
    } on DioException catch (e) {
      debugPrint('[AuthService] Erreur enregistrement FCM token: ${e.message}');
    } catch (e) {
      debugPrint('[AuthService] Erreur inattendue FCM token: $e');
    }
  }

  Future<void> confirmerVerificationNocturne(int verificationId) async {
    try {
      await _apiClient.post<void>(
        '/api/v1/verification-nocturne/$verificationId/confirmer',
      );
      debugPrint('[AuthService] Verification nocturne $verificationId confirmee');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        throw Exception('Verification introuvable');
      }
      if (status == 403) {
        throw Exception('Operation interdite');
      }
      throw Exception('Erreur lors de la confirmation (statut $status)');
    }
  }

  Exception _handleAuthError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    String message = 'Erreur de connexion au serveur';

    if (statusCode == 401) {
      message = 'Email ou mot de passe incorrect';
    } else if (statusCode == 400) {
      if (data is Map<String, dynamic>) {
        final errors = data['message'];
        if (errors != null) {
          if (errors is List) {
            message = errors.join(', ');
          } else if (errors is String) {
            message = errors;
          }
        }
      }
    } else if (statusCode == 409) {
      message = 'Un compte existe déjà avec cet email';
    } else if (statusCode == 500) {
      message = 'Erreur interne du serveur';
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Délai de connexion dépassé. Vérifiez votre réseau.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Impossible de se connecter au serveur. Vérifiez que le backend est démarré.';
    }

    return Exception(message);
  }
}
