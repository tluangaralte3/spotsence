// lib/services/notification_service.dart
//
// Handles Firebase Cloud Messaging for Xplooria.
//
// Topics (all users auto-subscribed on login):
//   new_dares      – public dare / challenge created
//   new_dilemmas   – community dilemma posted
//   new_listings   – admin added a spot/restaurant/cafe/hotel/homestay/etc.
//   new_ventures   – admin added a tour venture / adventure package
//
// Tap routing: the FCM `data` payload carries `type` and `id`, which are
// mapped to the correct GoRouter path. Navigation uses the app's
// [navigatorKey] that is also wired into GoRouter.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background handler (must be a top-level function, not a class member)
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised before this callback executes.
  debugPrint(
    'FCM [background]: ${message.notification?.title} – ${message.data}',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // A GlobalKey shared with GoRouter so we can navigate from anywhere.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final _fcm = FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();

  // Android notification channel — must match the manifest meta-data.
  static const _channelId = 'xplooria_channel';
  static const _channelName = 'Xplooria Notifications';
  static const _channelDesc =
      'Alerts for new dares, listings, ventures and dilemmas';

  // FCM topic names — Cloud Functions publish to these.
  static const _topicNewDares = 'new_dares';
  static const _topicNewListings = 'new_listings';
  static const _topicNewVentures = 'new_ventures';
  static const _topicNewDilemmas = 'new_dilemmas';

  static const _allTopics = [
    _topicNewDares,
    _topicNewListings,
    _topicNewVentures,
    _topicNewDilemmas,
  ];

  // ── Initialise ────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // 1. Request permission (Android 13+, iOS, macOS).
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2. iOS foreground presentation options.
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Initialise flutter_local_notifications (foreground display on Android
    //    and iOS when the app is open).
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FirebaseMessaging
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotif.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotifTap,
    );

    // 4. Create the Android notification channel (Android 8+).
    if (!kIsWeb && Platform.isAndroid) {
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.high,
              playSound: true,
            ),
          );
    }

    // 5. Foreground FCM message → show local notification.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 6. Notification tapped while app is in the background (not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // 7. App launched from a terminated state via a notification tap.
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // Delay very briefly so GoRouter has finished building its initial route.
      Future.delayed(const Duration(milliseconds: 500), () {
        _onNotificationTap(initial);
      });
    }
  }

  // ── Topic management ──────────────────────────────────────────────────────

  /// Call after a successful sign-in or registration.
  Future<void> subscribeToTopics() async {
    for (final topic in _allTopics) {
      await _fcm.subscribeToTopic(topic);
    }
    debugPrint('FCM: subscribed to ${_allTopics.join(', ')}');
  }

  /// Call on sign-out.
  Future<void> unsubscribeFromTopics() async {
    for (final topic in _allTopics) {
      await _fcm.unsubscribeFromTopic(topic);
    }
    debugPrint('FCM: unsubscribed from all topics');
  }

  // ── Token management ──────────────────────────────────────────────────────

  /// Saves (or refreshes) the FCM token for a user so the backend can send
  /// targeted (non-topic) notifications in future features.
  Future<void> saveTokenToFirestore(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenRefreshedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM token saved for user $userId');

      // Refresh token listener.
      _fcm.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
          'lastTokenRefreshedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('FCM token save error: $e');
    }
  }

  // ── Message handlers ──────────────────────────────────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    await _localNotif.show(
      // Use hash of message ID so concurrent notifications don't overwrite.
      message.messageId.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _routeFor(message.data),
    );
  }

  void _onLocalNotifTap(NotificationResponse response) {
    final route = response.payload ?? AppRoutes.home;
    _navigate(route);
  }

  void _onNotificationTap(RemoteMessage message) {
    _navigate(_routeFor(message.data));
  }

  // ── Route resolution ──────────────────────────────────────────────────────

  /// Maps the FCM `data` payload to the correct GoRouter path.
  String _routeFor(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    final id = data['id'] as String? ?? '';

    switch (type) {
      case 'dare':
        return id.isNotEmpty ? AppRoutes.darePath(id) : AppRoutes.community;
      case 'venture':
        return id.isNotEmpty
            ? AppRoutes.ventureDetailPath(id)
            : AppRoutes.tourPackages;
      case 'listing':
        return AppRoutes.listings;
      case 'dilemma':
        return AppRoutes.community;
      default:
        return AppRoutes.home;
    }
  }

  void _navigate(String route) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      GoRouter.of(context).go(route);
    }
  }
}
