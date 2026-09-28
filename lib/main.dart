import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:glumate_mobile/firebase_options.dart';
import 'package:provider/provider.dart';

import 'package:glumate_mobile/core/services/api_client.dart';
import 'package:glumate_mobile/core/services/hydration_notification_service.dart';
import 'package:glumate_mobile/core/services/storage_service.dart';
import 'package:glumate_mobile/data/repositories/auth_repository.dart';
import 'package:glumate_mobile/data/repositories/hydration_repository.dart';
import 'package:glumate_mobile/data/repositories/ocr_vision_repository.dart';
import 'package:glumate_mobile/data/repositories/report_repository.dart';
import 'package:glumate_mobile/data/repositories/chat_repository.dart';
import 'package:glumate_mobile/data/repositories/dashboard_repository.dart';
import 'package:glumate_mobile/data/repositories/ami_proche_repository.dart';
import 'package:glumate_mobile/data/repositories/proche_auth_repository.dart';

import 'package:glumate_mobile/navigation/glumate_root.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] Message recu en arriere-plan: ${message.messageId}');
  if (message.data['type'] == 'verification_nocturne') {
    debugPrint('[FCM] Type: verification_nocturne, id=${message.data['verificationId']}');
  } else if (message.data['type'] == 'alerte_patient') {
    debugPrint('[FCM] Type: alerte_patient, id=${message.data['verificationId']}');
    afficherAppelEntrant(message.data);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final storage = await StorageService.getInstance();
  final apiClient = await ApiClient.getInstance();
  final authService = await AuthService.create();
  final chatService = ChatService(apiClient, authService);
  final ocrVisionService = OcrVisionService(authService);
  final dashboardService = DashboardService(apiClient, authService);
  final reportService = ReportService(authService);
  final hydrationRepository = await HydrationRepository.create();
  final amiProcheRepository = await AmiProcheRepository.create();
  final procheAuthRepository = await ProcheAuthRepository.create();
  
  final hydrationNotificationService = HydrationNotificationService();
  await hydrationNotificationService.initialize();
  await hydrationNotificationService.requestPermissions();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<ChatService>.value(value: chatService),
        ChangeNotifierProvider<OcrVisionService>.value(value: ocrVisionService),
        ChangeNotifierProvider<DashboardService>.value(value: dashboardService),
        ChangeNotifierProvider<ReportService>.value(value: reportService),
        ChangeNotifierProvider<HydrationRepository>.value(value: hydrationRepository),
        ChangeNotifierProvider<AmiProcheRepository>.value(value: amiProcheRepository),
        ChangeNotifierProvider<ProcheAuthRepository>.value(value: procheAuthRepository),
        Provider<HydrationNotificationService>.value(value: hydrationNotificationService),
      ],
      child: const GluMateApp(),
    ),
  );
}
