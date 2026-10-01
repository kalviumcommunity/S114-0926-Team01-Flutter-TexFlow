import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // NOTE: do not touch `FirebaseMessaging.instance` in a field initialiser.
  // Accessing it before `Firebase.initializeApp()` (or on an unsupported
  // platform) throws, and because this class is a singleton that would poison
  // every later access. It is resolved lazily inside [initialize] instead.
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  FirebaseMessaging? _messaging;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  bool _initialized = false;
  bool _firebaseAvailable = false;
  List<String> _warnings = const [];

  static const String _channelId = 'texflow_alerts';
  static const String _channelName = 'TexFlow Alerts';
  static const String _channelDescription = 'Bottleneck and production alerts';

  /// Whether Firebase Messaging is usable after [initialize] ran.
  bool get isFirebaseAvailable => _firebaseAvailable;

  /// Non-fatal problems encountered during setup (e.g. FCM unavailable).
  List<String> get warnings => List.unmodifiable(_warnings);

  /// Sets up local notifications and, when available, Firebase Messaging.
  ///
  /// Safe to call more than once; concurrent and repeated calls are ignored.
  /// Never throws: push-notification problems must not take the app down.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final warnings = <String>[];

    // Local notifications are independent of Firebase and are the only channel
    // guaranteed to work offline / without platform push config.
    try {
      await _initLocalNotifications();
    } catch (error) {
      warnings.add('Local notifications unavailable: $error');
    }

    if (Firebase.apps.isEmpty) {
      warnings.add(
        'Firebase Messaging disabled: Firebase is not initialised on this '
        'build. See initializeFirebase() in lib/core/firebase/.',
      );
      _warnings = warnings;
      return;
    }

    final platform = defaultTargetPlatform;
    if (!kIsWeb &&
        platform != TargetPlatform.android &&
        platform != TargetPlatform.iOS) {
      warnings.add('Firebase Messaging is not supported on $platform.');
      _warnings = warnings;
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        // TODO: Send token to backend
      }

      // Replacing the stored subscription keeps this idempotent.
      await _foregroundSubscription?.cancel();
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      _messaging = messaging;
      _firebaseAvailable = true;
    } catch (error) {
      _firebaseAvailable = false;
      warnings.add('Firebase Messaging unavailable: $error');
    }

    _warnings = warnings;
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createNotificationChannel();

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      await _showLocalNotification(message);
    } catch (error) {
      debugPrint('Failed to show foreground notification: $error');
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message - could save to local storage
    debugPrint('Background message: ${message.data}');
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _handleMessagePayload(payload);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      const Uuid().v4().hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _encodePayload(message.data),
    );
  }

  String _encodePayload(Map<String, dynamic> data) {
    return const Uuid().v4(); // In production, encode actual data
  }

  void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('type')) {
      _handleMessagePayload(data['type']);
    }
  }

  void _handleMessagePayload(String payload) {
    // Navigate based on payload type
    // Could use a navigator key or event bus
    debugPrint('Handle notification payload: $payload');
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging?.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging?.unsubscribeFromTopic(topic);
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(service.dispose);
  return service;
});
