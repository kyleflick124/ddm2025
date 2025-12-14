import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/locale_provider.dart';

/// Service for handling push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to relevant screen
    // This would typically be handled by the app's navigation
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification when app is in foreground
    showLocalNotification(
      title: message.notification?.title ?? 'Elder Monitor',
      body: message.notification?.body ?? '',
    );
  }

  /// Get FCM token for this device
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Subscribe to topic for receiving notifications
  Future<void> subscribeToElder(String elderId) async {
    await _messaging.subscribeToTopic('elder_$elderId');
  }

  /// Unsubscribe from elder notifications
  Future<void> unsubscribeFromElder(String elderId) async {
    await _messaging.unsubscribeFromTopic('elder_$elderId');
  }

  /// Show a local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'elder_monitor_channel',
      'Elder Monitor Alerts',
      channelDescription: 'Notifications for elder monitoring alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }

  /// Show emergency notification
  Future<void> showEmergencyNotification(String elderName) async {
    await showLocalNotification(
      title: '🚨 EMERGÊNCIA - SOS',
      body: '$elderName acionou o botão de emergência!',
      payload: 'emergency',
    );
  }

  /// Show fall detected notification
  Future<void> showFallNotification(String elderName) async {
    await showLocalNotification(
      title: '⚠️ Queda Detectada',
      body: 'Possível queda detectada para $elderName',
      payload: 'fall',
    );
  }

  /// Show geofence exit notification
  Future<void> showGeofenceExitNotification(String elderName) async {
    await showLocalNotification(
      title: '📍 Saída da Área Segura',
      body: '$elderName saiu da área segura definida',
      payload: 'geofence',
    );
  }

  /// Show low battery notification
  Future<void> showLowBatteryNotification(String elderName, int level) async {
    await showLocalNotification(
      title: '🔋 Bateria Baixa',
      body: 'Bateria do relógio de $elderName está em $level%',
      payload: 'battery',
    );
  }
}

/// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Handle background notification
  print('Background message: ${message.notification?.title}');
}
