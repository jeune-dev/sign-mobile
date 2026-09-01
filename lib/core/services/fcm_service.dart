import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';
import '../routes/app_router.dart';
import '../../injection_container.dart';
import 'token_service.dart';

// ─── Canal Android ────────────────────────────────────────────────────────────
const _kChannelId   = 'sign_push_channel';
const _kChannelName = 'Notifications Sign';
const _kChannelDesc = 'Contrats, factures et documents à signer';

// ─── Plugin local notifications ───────────────────────────────────────────────
final FlutterLocalNotificationsPlugin _localNotif =
    FlutterLocalNotificationsPlugin();

/// Handler background/terminated — doit être une fonction top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase est déjà initialisé par main() — rien à faire ici
  // Le SDK FCM affiche la notification système automatiquement en background/terminated
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  /// Initialise FCM :
  ///   1. Canal Android + plugin local notifications
  ///   2. Demande de permission
  ///   3. Upload du token FCM au backend
  ///   4. Handlers (foreground / background tap / terminated tap)
  static Future<void> init() async {
    // ── 1. Initialiser le plugin local notifications ──────────────────────────
    await _initLocalNotifications();

    // ── 2. Demander la permission (Android 13+ / iOS) ─────────────────────────
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // L'utilisateur a refusé — on ne peut pas envoyer de pushs
      return;
    }

    // ── 3. Upload du token au backend (permission accordée → getToken() réussit)
    await _uploadToken();

    // ── 4. Écouter les refreshs de token
    _messaging.onTokenRefresh.listen((_) => _uploadToken());

    // ── 5. Handler messages en FOREGROUND ─────────────────────────────────────
    // FCM ne montre PAS de notification système quand l'app est au premier plan
    // → on l'affiche manuellement via flutter_local_notifications
    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      if (notif == null) return;
      _showLocalNotification(
        title: notif.title ?? 'SIGNS',
        body: notif.body ?? '',
        data: message.data,
      );
    });

    // ── 6. Handler tap sur notif quand l'app était en ARRIÈRE-PLAN ────────────
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _ouvrirDepuisNotification(message.data);
    });

    // ── 7. Handler tap sur notif quand l'app était TERMINÉE ───────────────────
    // L'app a été lancée DEPUIS une notification : le Navigator n'existe pas
    // encore au moment où l'on lit le message, d'où le report après la
    // première frame.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ouvrirDepuisNotification(initial.data);
      });
    }
  }

  // ── Initialise le plugin local notifications + canal Android ─────────────────
  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit  = DarwinInitializationSettings();

    await _localNotif.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: (response) {
        // Tap sur une notification affichée alors que l'app était ouverte.
        // Elle ne menait nulle part auparavant, faute de BuildContext ici :
        // la navigation passe désormais par la clé globale, et les données du
        // message voyagent dans le `payload`.
        final charge = response.payload;
        if (charge == null || charge.isEmpty) return;
        try {
          final donnees = jsonDecode(charge) as Map<String, dynamic>;
          _ouvrirDepuisNotification(donnees);
        } catch (_) {
          // Charge illisible : on ouvre l'app sans redirection plutôt que
          // de planter sur un tap.
        }
      },
    );

    // Créer le canal Android (obligatoire Android 8+)
    if (Platform.isAndroid) {
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _kChannelId,
              _kChannelName,
              description: _kChannelDesc,
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );
    }
  }

  // ── Affiche une notification locale (foreground) ──────────────────────────────
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
    );

    await _localNotif.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: notifDetails,
      // Sans cette charge, le tap sur la notification n'aurait aucune donnée
      // pour savoir vers quelle page rediriger.
      payload: jsonEncode(data),
    );
  }

  /// Envoie le token FCM au backend (best-effort).
  /// Appelé depuis init() après que la permission a été accordée.
  static Future<void> _uploadToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final isAuth = await sl<TokenService>().isAuthenticated;
      if (!isAuth) return;

      await sl<Dio>().post(
        Env.accountDeviceToken,
        data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
    } catch (_) {
      // Best-effort — ne pas bloquer si le backend est indisponible
    }
  }

  /// Appelé uniquement depuis AuthBloc après un login réussi,
  /// pour les cas où init() n'a pas encore été appelé (rare).
  static Future<void> uploadToken() => _uploadToken();

  /// Redirige vers la rubrique concernée par la notification.
  ///
  /// Appelée dans les trois situations : app ouverte, app en arrière-plan,
  /// app relancée depuis la notification. Elle passe par la clé de Navigator
  /// globale plutôt que par un `BuildContext` : celui qui avait servi à
  /// initialiser le service peut être démonté, et dans le cas d'un lancement
  /// depuis une notification, aucun écran n'existe encore.
  static Future<void> _ouvrirDepuisNotification(
    Map<String, dynamic> data,
  ) async {
    final type = data['type'] as String?;
    if (type == null) return;

    final navigateur = AppRouter.navigatorKey.currentState;
    if (navigateur == null) return;

    final role = await _getUserRole();

    // L'onglet « Documents » ne porte pas le même index selon l'espace :
    // 2 chez le particulier, 3 chez le professionnel.
    final estClient = role == 'Particulier';
    navigateur.pushNamedAndRemoveUntil(
      estClient ? AppRouter.clientRoute : AppRouter.professionnelRoute,
      (route) => false,
      arguments: NotificationNavArgs(
        initialTabIndex: estClient ? 2 : 3,
        contractType: type,
      ),
    );
  }

  static Future<String?> _getUserRole() async {
    try {
      return await sl<FlutterSecureStorage>().read(key: 'user_role');
    } catch (_) {
      return null;
    }
  }
}

/// Arguments passés aux pages home lors d'un tap sur notification
class NotificationNavArgs {
  final int initialTabIndex;
  final String? contractType;
  const NotificationNavArgs({required this.initialTabIndex, this.contractType});
}
