import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:glumate_mobile/core/theme/app_colors.dart';
import 'package:glumate_mobile/core/constants/app_screen.dart';
import 'package:glumate_mobile/widgets/glumate_bottom_nav.dart';

import 'package:glumate_mobile/data/repositories/auth_repository.dart';
import 'package:glumate_mobile/data/repositories/chat_repository.dart';
import 'package:glumate_mobile/data/repositories/dashboard_repository.dart';


import 'package:glumate_mobile/screens/auth/login_screen.dart';
import 'package:glumate_mobile/screens/home/home_screen.dart';
import 'package:glumate_mobile/screens/ocr_vision/ocr_vision_screen.dart';
import 'package:glumate_mobile/screens/report/report_screen.dart';
import 'package:glumate_mobile/screens/glycemia/glycemia_screen.dart';
import 'package:glumate_mobile/screens/meal/meal_screen.dart';
import 'package:glumate_mobile/screens/chatbot/chatbot_screen.dart';
import 'package:glumate_mobile/screens/profile/profile_screen.dart';
import 'package:glumate_mobile/screens/profile/modifier_profil_screen.dart';
import 'package:glumate_mobile/screens/hydration/hydratation_screen.dart';
import 'package:glumate_mobile/screens/proche/ajouter_proche_screen.dart';
import 'package:glumate_mobile/screens/proche/connexion_proche_screen.dart';
import 'package:glumate_mobile/screens/proche/accueil_proche_screen.dart';
import 'package:glumate_mobile/screens/proche/verification_nocturne_screen.dart';
import 'package:glumate_mobile/screens/proche/appel_urgence_proche_screen.dart';

Future<void> afficherAppelEntrant(Map<String, dynamic> data) async {
  final patientPrenom = (data['patientPrenom'] as String?) ?? '';
  final patientNom = (data['patientNom'] as String?) ?? '';
  final message = (data['message'] as String?) ?? '';
  final verificationId = (data['verificationId'] as String?) ?? '';

  final uuid = const Uuid().v4();
  final params = CallKitParams(
    id: uuid,
    nameCaller: '$patientPrenom $patientNom'.trim().isEmpty
        ? 'Alerte GluMate'
        : '$patientPrenom $patientNom',
    appName: 'GluMate',
    handle: 'Alerte nocturne',
    type: 0,
    textAccept: 'Accepter',
    textDecline: 'Refuser',
    extra: <String, dynamic>{
      'message': message,
      'patientNom': patientNom,
      'patientPrenom': patientPrenom,
      'verificationId': verificationId,
    },
    android: AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#EF4444',
      backgroundUrl: '',
      actionColor: '#4CAF50',
      incomingCallNotificationChannelName: 'Appels urgents',
    ),
    ios: IOSParams(
      iconName: 'CallKitLogo',
      handleType: 'generic',
      supportsVideo: false,
      maximumCallGroups: 1,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'system_ringtone_default',
    ),
  );

  try {
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    debugPrint('[CallKit] Appel entrant affiche pour verification $verificationId');
  } catch (e) {
    debugPrint('[CallKit] Erreur affichage appel entrant: $e');
  }
}

class GluMateApp extends StatelessWidget {
  const GluMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GluMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
      ),
      home: const GluMateRoot(),
    );
  }
}

class GluMateRoot extends StatefulWidget {
  const GluMateRoot({super.key});

  @override
  State<GluMateRoot> createState() => _GluMateRootState();
}

class _GluMateRootState extends State<GluMateRoot> {
  AppScreen _screen = AppScreen.login;
  int? _pendingVerificationId;
  String? _pendingAlerteMessage;
  String? _pendingAlertePatientNom;
  String? _pendingAlertePatientPrenom;
  int? _pendingAlerteVerificationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.isAuthenticated) {
        setState(() => _screen = AppScreen.home);
        context.read<ChatService>().loadHistory();
        context.read<DashboardService>().load();
      }
      _setupFcmListeners();
      _setupCallKitListener();
    });
  }

  void _setupCallKitListener() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      if (event.event == 'actionCallAccept') {
        final extra = event.body;
        if (extra == null || extra is! Map<String, dynamic>) return;
        final message = (extra['message'] as String?) ?? '';
        final patientNom = (extra['patientNom'] as String?) ?? '';
        final patientPrenom = (extra['patientPrenom'] as String?) ?? '';
        final rawVid = extra['verificationId'];
        final verificationId = rawVid is String ? int.tryParse(rawVid) : null;

        if (mounted) {
          setState(() {
            _pendingAlerteMessage = message;
            _pendingAlertePatientNom = patientNom;
            _pendingAlertePatientPrenom = patientPrenom;
            _pendingAlerteVerificationId = verificationId ?? 0;
            _screen = AppScreen.appelUrgenceProche;
          });
        }
      }
    });
  }

  void _setupFcmListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Message recu app ouverte: ${message.messageId}');
      if (message.data['type'] == 'verification_nocturne') {
        final rawId = message.data['verificationId'];
        final verificationId = rawId is String ? int.tryParse(rawId) : null;
        if (verificationId != null && mounted) {
          setState(() {
            _pendingVerificationId = verificationId;
            _screen = AppScreen.verificationNocturne;
          });
        }
      } else if (message.data['type'] == 'alerte_patient') {
        afficherAppelEntrant(message.data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Notification ouverte depuis arriere-plan: ${message.messageId}');
      if (message.data['type'] == 'verification_nocturne') {
        final rawId = message.data['verificationId'];
        final verificationId = rawId is String ? int.tryParse(rawId) : null;
        if (verificationId != null && mounted) {
          setState(() {
            _pendingVerificationId = verificationId;
            _screen = AppScreen.verificationNocturne;
          });
        }
      } else if (message.data['type'] == 'alerte_patient') {
        final data = message.data;
        final messageTexte = (data['message'] as String?) ?? '';
        final patientNom = (data['patientNom'] as String?) ?? '';
        final patientPrenom = (data['patientPrenom'] as String?) ?? '';
        final rawVid = data['verificationId'];
        final verificationId = rawVid is String ? int.tryParse(rawVid) ?? 0 : 0;
        if (mounted) {
          setState(() {
            _pendingAlerteMessage = messageTexte;
            _pendingAlertePatientNom = patientNom;
            _pendingAlertePatientPrenom = patientPrenom;
            _pendingAlerteVerificationId = verificationId;
            _screen = AppScreen.appelUrgenceProche;
          });
        }
      }
    });
  }

  void _navigate(AppScreen screen) => setState(() => _screen = screen);

  void _loginSuccess() {
    setState(() => _screen = AppScreen.home);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatService>().loadHistory();
    });
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    final chat = context.read<ChatService>();
    chat.messages.clear();
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    chat.notifyListeners();
    setState(() => _screen = AppScreen.login);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        final isLoggedIn = auth.isAuthenticated;
        final mainScreens = const {
          AppScreen.home,
          AppScreen.ocrVision,
          AppScreen.chatbot,
          AppScreen.profile,
        };
        final procheScreens = const {
          AppScreen.connexionProche,
          AppScreen.accueilProche,
        };

        Widget effectiveScreen;
        if (!isLoggedIn && !procheScreens.contains(_screen)) {
          effectiveScreen = LoginScreen(onLoginSuccess: _loginSuccess, onNavigate: _navigate);
        } else if (procheScreens.contains(_screen)) {
          switch (_screen) {
            case AppScreen.connexionProche:
              effectiveScreen = ConnexionProcheScreen(onNavigate: _navigate);
              break;
            case AppScreen.accueilProche:
              effectiveScreen = AccueilProcheScreen(onNavigate: _navigate);
              break;
            default:
              effectiveScreen = const SizedBox.shrink();
          }
        } else {
          switch (_screen) {
            case AppScreen.login:
              effectiveScreen = const SizedBox.shrink();
              break;
            case AppScreen.home:
              effectiveScreen = HomeScreen(onNavigate: _navigate);
              break;
            case AppScreen.glycemia:
              effectiveScreen =
                  GlycemiaScreen(onBack: () => _navigate(AppScreen.home));
              break;
            case AppScreen.meal:
              effectiveScreen =
                  MealScreen(onBack: () => _navigate(AppScreen.home));
              break;
            case AppScreen.chatbot:
              effectiveScreen =
                  ChatbotScreen(onBack: () => _navigate(AppScreen.home));
              break;
            case AppScreen.ocrVision:
              effectiveScreen = const OcrVisionScreen();
              break;
            case AppScreen.profile:
              effectiveScreen = ProfileScreen(
                onLogout: _logout,
                onNavigate: _navigate,
              );
              break;
            case AppScreen.report:
              effectiveScreen = ReportScreen(onBack: () => _navigate(AppScreen.profile));
              break;
            case AppScreen.ajouterProche:
              effectiveScreen = AjouterProcheScreen(onNavigate: _navigate);
              break;
            case AppScreen.hydratation:
              effectiveScreen = HydrationScreen(onBack: () => _navigate(AppScreen.profile));
              break;
            case AppScreen.modifierProfil:
              effectiveScreen = ModifierProfilScreen(onBack: () => _navigate(AppScreen.profile));
              break;
            case AppScreen.verificationNocturne:
              final vid = _pendingVerificationId ?? 0;
              effectiveScreen = VerificationNocturneScreen(
                verificationId: vid,
                onConfirmed: () {
                  setState(() {
                    _pendingVerificationId = null;
                    _screen = AppScreen.home;
                  });
                },
              );
              break;
            case AppScreen.appelUrgenceProche:
              effectiveScreen = AppelUrgenceProcheScreen(
                message: _pendingAlerteMessage ?? '',
                patientNom: _pendingAlertePatientNom ?? '',
                patientPrenom: _pendingAlertePatientPrenom ?? '',
                verificationId: _pendingAlerteVerificationId ?? 0,
                onConfirmed: () {
                  setState(() {
                    _pendingAlerteMessage = null;
                    _pendingAlertePatientNom = null;
                    _pendingAlertePatientPrenom = null;
                    _pendingAlerteVerificationId = null;
                    _screen = AppScreen.accueilProche;
                  });
                },
              );
              break;
            default:
              effectiveScreen = const SizedBox.shrink();
          }
        }

        final showNav =
            isLoggedIn && mainScreens.contains(_screen) && _screen != AppScreen.login;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: effectiveScreen,
            ),
          ),
          bottomNavigationBar: showNav
              ? GluMateBottomNav(currentScreen: _screen, onNavigate: _navigate)
              : null,
        );
      },
    );
  }
}
