import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static const String _channelId = 'texflow_alerts';
  static const String _channelName = 'TexFlow Alerts';
  static const String _channelDescription = 'Bottleneck and production alerts';

  Future<void> initialize() async {
    // Initialize local notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    // Request permissions
    await _requestPermissions();

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      // TODO: Send token to backend
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification tap when app is terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    // Firebase Messaging permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Local notifications permissions (iOS)
    await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message - could save to local storage
    print('Background message: ${message.data}');
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _handleMessagePayload(payload);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    
    if (notification == null) return;

    await _localNotifications.show(
      const Uuid().v4().hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _encodePayload(data),
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
    print('Handle notification payload: $payload');
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});