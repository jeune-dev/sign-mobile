import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';
import '../routes/app_router.dart';
import '../../injection_container.dart';
import 'token_service.dart';

/// Handler background/terminated — doit être une fonction top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase est déjà initialisé par main() — rien à faire ici
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  /// Initialise FCM : permissions + handlers + envoi du token au backend
  static Future<void> init(BuildContext context) async {
    // 1. Demander la permission (iOS + Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Handler messages en arrière-plan
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Handler message quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((message) {
      // On ne fait rien en foreground — la notif système apparaît automatiquement
    });

    // 4. Handler tap sur notif quand l'app était en arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (context.mounted) _handleNotificationTap(context, message.data);
    });

    // 5. Handler tap sur notif quand l'app était terminée
    final initial = await _messaging.getInitialMessage();
    if (initial != null && context.mounted) {
      // Petit délai pour laisser le widget tree se construire
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(context, initial.data);
      });
    }

    // 6. Envoyer le token au backend
    await _uploadToken();

    // 7. Écouter les refreshs de token
    _messaging.onTokenRefresh.listen((_) => _uploadToken());
  }

  /// Envoie le token FCM au backend (best-effort).
  /// Public — appelé aussi depuis AuthBloc juste après un login réussi,
  /// sans avoir besoin de BuildContext.
  static Future<void> uploadToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      // Vérifier que le JWT est valide avant d'envoyer
      final isAuth = await sl<TokenService>().isAuthenticated;
      if (!isAuth) return;

      // Le Dio injecté a déjà l'intercepteur Authorization
      await sl<Dio>().post(
        Env.accountDeviceToken,
        data: {'token': token, 'platform': 'android'},
      );
    } catch (_) {
      // Best-effort — ne pas bloquer si le backend est down
    }
  }

  // Alias privé pour l'usage interne (init + onTokenRefresh)
  static Future<void> _uploadToken() => uploadToken();

  /// Navigation basée sur le type de contrat reçu dans la notification
  static Future<void> _handleNotificationTap(BuildContext context, Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    if (type == null || !context.mounted) return;

    final role = await _getUserRole();
    if (!context.mounted) return;

    if (role == 'Particulier') {
      // Client → onglet Contrats de la ClientPage
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.clientRoute,
        (route) => false,
        arguments: _buildClientArgs(type),
      );
    } else {
      // Professionnel / Indépendant → ProfessionnelPage onglet Contrats
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.professionnelRoute,
        (route) => false,
        arguments: _buildProfArgs(type),
      );
    }
  }

  static Future<String?> _getUserRole() async {
    try {
      return await sl<FlutterSecureStorage>().read(key: 'user_role');
    } catch (_) {
      return null;
    }
  }

  static NotificationNavArgs _buildClientArgs(String type) {
    return NotificationNavArgs(initialTabIndex: 2, contractType: type);
  }

  static NotificationNavArgs _buildProfArgs(String type) {
    return NotificationNavArgs(initialTabIndex: 3, contractType: type);
  }
}

/// Arguments passés aux pages home lors d'un tap sur notification
class NotificationNavArgs {
  final int initialTabIndex;
  final String? contractType;
  const NotificationNavArgs({required this.initialTabIndex, this.contractType});
}
