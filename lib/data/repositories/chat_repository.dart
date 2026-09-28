import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import 'package:glumate_mobile/core/services/api_client.dart';
import 'package:glumate_mobile/core/config/app_config.dart';
import 'package:glumate_mobile/data/models/chat_message_model.dart';
import 'package:glumate_mobile/data/repositories/auth_repository.dart';

class ChatService extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthService _authService;

  // Dio client dédié FastAPI (RAG) — baseUrl différent de Spring Boot
  late final Dio _fastApiDio;

  ChatService(this._apiClient, this._authService) {
    _fastApiDio = Dio(BaseOptions(
      baseUrl: AppConfig.fastApiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ));
  }

  final List<ChatMessage> messages = <ChatMessage>[];
  bool isSending = false;
  String? errorMessage;

  bool get isEmpty => messages.isEmpty;

  int? get _userId => _authService.currentUser?.id;

  static const ChatMessage _welcomeMessage = ChatMessage(
    role: 'bot',
    text:
        'Bonjour ! Je suis votre assistant medical GluMate. Je peux vous aider '
        'sur le diabete, la nutrition et la gestion de votre glycemie.',
  );

  Future<void> loadHistory() async {
    messages.clear();
    errorMessage = null;
    
    if (_userId == null) {
      messages.add(_welcomeMessage);
      notifyListeners();
      return;
    }
    
    try {
      // FastAPI RAG: GET /api/v1/rag/history/{userId}
      // Retourne { "data": [ { role, content, dateHeure, sourcesJson, confidence } ] }
      final response = await _fastApiDio.get<Map<String, dynamic>>(
        '/api/v1/rag/history/$_userId',
      );
      final body = response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final rawList = (body['data'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e as Map<String, dynamic>)
          .toList();

      for (final json in rawList) {
        final role = json['role'] as String? ?? '';
        final content = json['content'] as String? ?? '';
        final confidence = json['confidence'] as String?;
        final sourcesJson = json['sourcesJson'] as String?;
        
        if (content.isEmpty) continue;
        
        // Parse sources from JSON string if available
        List<String> sources = [];
        if (sourcesJson != null && sourcesJson.isNotEmpty) {
          try {
            final sourcesList = jsonDecode(sourcesJson) as List<dynamic>;
            sources = sourcesList
                .whereType<Map<String, dynamic>>()
                .map((src) {
                  final meta = src['metadata'];
                  if (meta is Map<String, dynamic>) {
                    final s = meta['source'];
                    if (s is String && s.isNotEmpty) return s;
                  }
                  return 'Source medicale';
                })
                .toSet()
                .toList();
          } catch (_) {}
        }
        
        messages.add(ChatMessage(
          role: role == 'USER' ? 'user' : 'bot',
          text: content,
          confidenceLabel: confidence,
          sources: sources,
        ));
      }

      if (messages.isEmpty) {
        messages.add(_welcomeMessage);
      }
    } on DioException catch (e) {
      errorMessage = _errorMessage(e, defaultMsg: 'Impossible de charger l\'historique.');
      if (messages.isEmpty) {
        messages.add(_welcomeMessage);
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> ask(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    if (_userId == null) {
      errorMessage = 'Utilisateur non connecté';
      notifyListeners();
      return;
    }

    final userMessage = ChatMessage(role: 'user', text: trimmed);
    messages.add(userMessage);
    isSending = true;
    errorMessage = null;
    notifyListeners();

    try {
      // FastAPI RAG: POST /api/v1/rag/chat?user_id={userId}
      // Body: { "question": "..." }
      // La réponse: { "answer": "...", "confidence": "...", "sources": [...] }
      final response = await _fastApiDio.post<Map<String, dynamic>>(
        '/api/v1/rag/chat',
        queryParameters: <String, dynamic>{'user_id': _userId},
        data: <String, dynamic>{'question': trimmed},
      );
      final data = response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final answer = (data['answer'] as String? ?? '').trim();
      final confidenceLabel = data['confidence'] as String?;
      final safetyAction = data['safety_action'] as String? ?? 'pass';
      // FastAPI retourne sources comme une List directement, pas une String
      final sourcesList = data['sources'] as List<dynamic>? ?? <dynamic>[];
      final triggeredRulesList = data['triggered_rules'] as List<dynamic>? ?? <dynamic>[];
      
      List<String> sourcesLabel = [];
      try {
        sourcesLabel = sourcesList
            .whereType<Map<String, dynamic>>()
            .map((src) {
              final meta = src['metadata'];
              if (meta is Map<String, dynamic>) {
                final s = meta['source'];
                if (s is String && s.isNotEmpty) return s;
              }
              return 'Source medicale';
            })
            .toSet()
            .take(3)
            .toList();
      } catch (_) {}

      List<TriggeredRule> triggeredRules = [];
      try {
        triggeredRules = triggeredRulesList
            .whereType<Map<String, dynamic>>()
            .map((rule) => TriggeredRule.fromJson(rule))
            .toList();
      } catch (_) {}

      String reply;
      if (answer.isEmpty) {
        reply = "Je n'ai pas pu traiter votre question. Merci de reformuler.";
      } else {
        reply = answer;
      }

      messages.add(ChatMessage(
        role: 'bot',
        text: reply,
        sources: sourcesLabel,
        confidenceLabel: confidenceLabel,
        safetyAction: safetyAction,
        triggeredRules: triggeredRules,
      ));
    } on DioException catch (e) {
      errorMessage = _errorMessage(e,
          defaultMsg: 'Erreur reseau lors de l\'envoi. Merci de reessayer.');
      messages.add(ChatMessage(
        role: 'bot',
        text: errorMessage!,
      ));
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    // Note: Endpoint clear n'existe pas dans Spring Boot
    // On efface seulement localement
    messages
      ..clear()
      ..add(_welcomeMessage);
    errorMessage = null;
    notifyListeners();
  }

  String _errorMessage(DioException e, {required String defaultMsg}) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Duree d\'attente depassee. Verifiez votre connexion.';
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return 'Impossible de joindre le serveur. Verifiez le reseau.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 401) return 'Session expiree. Veuillez vous reconnecter.';
        final data = e.response?.data;
        if (data is Map) {
          final msg = data['message'];
          if (msg is String && msg.isNotEmpty) return msg;
          if (msg is List && msg.isNotEmpty) {
            final first = msg.first;
            if (first is String && first.isNotEmpty) return first;
          }
        }
        return defaultMsg;
      case DioExceptionType.cancel:
        return 'Requete annulee.';
      case DioExceptionType.unknown:
      default:
        return defaultMsg;
    }
  }
}
