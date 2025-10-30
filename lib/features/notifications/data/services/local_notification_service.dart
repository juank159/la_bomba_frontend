// lib/features/notifications/data/services/local_notification_service.dart

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

/// Service to handle local notifications (shown when app is in foreground)
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize local notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android 8.0+
      await _createNotificationChannels();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Local Notifications initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing local notifications: $e');
      }
    }
  }

  /// Create notification channels for Android 8.0+
  Future<void> _createNotificationChannels() async {
    // Default channel
    const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      'default_channel',
      'Notificaciones Generales',
      description: 'Notificaciones generales de la aplicación',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    // Supervisor tasks channel
    const AndroidNotificationChannel supervisorChannel = AndroidNotificationChannel(
      'supervisor_tasks',
      'Tareas de Supervisor',
      description: 'Notificaciones de tareas asignadas a supervisores',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    // Admin tasks channel
    const AndroidNotificationChannel adminChannel = AndroidNotificationChannel(
      'admin_tasks',
      'Tareas de Admin',
      description: 'Notificaciones de tareas administrativas',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    // Products channel
    const AndroidNotificationChannel productsChannel = AndroidNotificationChannel(
      'products',
      'Productos',
      description: 'Notificaciones sobre productos aprobados o actualizados',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    // Credits channel
    const AndroidNotificationChannel creditsChannel = AndroidNotificationChannel(
      'credits',
      'Créditos',
      description: 'Recordatorios de créditos pendientes',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    // Orders channel
    const AndroidNotificationChannel ordersChannel = AndroidNotificationChannel(
      'orders',
      'Pedidos',
      description: 'Actualizaciones de pedidos',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    // Create all channels
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(supervisorChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(adminChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(productsChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(creditsChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(ordersChannel);

    if (kDebugMode) {
      print('✅ Notification channels created');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('🔔 Local notification tapped:');
      print('   Payload: ${response.payload}');
    }

    if (response.payload != null) {
      try {
        // Parse payload as JSON
        final data = jsonDecode(response.payload!);
        _handleNotificationTap(data);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error parsing notification payload: $e');
        }
      }
    }
  }

  /// Handle notification tap navigation (same logic as FirebaseMessagingService)
  void _handleNotificationTap(Map<String, dynamic> data) {
    try {
      final type = data['type'] as String?;
      final taskId = data['taskId'] as String?;
      final productId = data['productId'] as String?;
      final creditId = data['creditId'] as String?;

      if (kDebugMode) {
        print('🎯 Handling notification tap:');
        print('   Type: $type');
        print('   TaskId: $taskId');
      }

      // Navigate based on notification type
      switch (type) {
        case 'SUPERVISOR_TASK':
          Get.offAllNamed('/supervisor', arguments: {'taskId': taskId});
          break;

        case 'ADMIN_TASK':
          Get.offAllNamed('/admin-tasks', arguments: {'taskId': taskId});
          break;

        case 'PRODUCT_UPDATE':
          Get.offAllNamed('/supervisor', arguments: {'taskId': taskId});
          break;

        case 'PRODUCT_APPROVED':
          Get.offAllNamed('/products', arguments: {'productId': productId});
          break;

        case 'CREDIT_REMINDER':
          Get.offAllNamed('/credits', arguments: {'creditId': creditId});
          break;

        case 'ORDER_UPDATE':
          Get.offAllNamed('/orders');
          break;

        default:
          Get.offAllNamed('/products');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification tap: $e');
      }
      Get.offAllNamed('/products');
    }
  }

  /// Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? channelId,
    String? channelName,
  }) async {
    try {
      // Android notification details
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId ?? 'default_channel',
            channelName ?? 'Notificaciones Generales',
            channelDescription: 'Notificaciones generales de la aplicación',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            number: 1,  // Badge number
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF2196F3),
            styleInformation: BigTextStyleInformation(body),
            ticker: title,
            visibility: NotificationVisibility.public,
          );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
        sound: 'default',
      );

      // Combined notification details
      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert payload to JSON string
      final payloadString = payload != null ? jsonEncode(payload) : null;

      // Show notification
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: payloadString,
      );

      if (kDebugMode) {
        print('📬 Local notification shown:');
        print('   Title: $title');
        print('   Body: $body');
        print('   Channel: ${channelId ?? 'default_channel'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing local notification: $e');
      }
    }
  }

  /// Show notification for Supervisor tasks
  Future<void> showSupervisorTaskNotification({
    required String title,
    required String body,
    required String taskId,
  }) async {
    await showNotification(
      title: title,
      body: body,
      channelId: 'supervisor_tasks',
      channelName: 'Tareas de Supervisor',
      payload: {'type': 'SUPERVISOR_TASK', 'taskId': taskId},
    );
  }

  /// Show notification for Admin tasks
  Future<void> showAdminTaskNotification({
    required String title,
    required String body,
    required String taskId,
  }) async {
    await showNotification(
      title: title,
      body: body,
      channelId: 'admin_tasks',
      channelName: 'Tareas de Admin',
      payload: {'type': 'ADMIN_TASK', 'taskId': taskId},
    );
  }

  /// Show notification for Product updates
  Future<void> showProductNotification({
    required String title,
    required String body,
    required String productId,
  }) async {
    await showNotification(
      title: title,
      body: body,
      channelId: 'products',
      channelName: 'Productos',
      payload: {'type': 'PRODUCT_APPROVED', 'productId': productId},
    );
  }

  /// Show notification for Credit reminders
  Future<void> showCreditNotification({
    required String title,
    required String body,
    required String creditId,
  }) async {
    await showNotification(
      title: title,
      body: body,
      channelId: 'credits',
      channelName: 'Créditos',
      payload: {'type': 'CREDIT_REMINDER', 'creditId': creditId},
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
      if (kDebugMode) {
        print('🗑️ All local notifications cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling notifications: $e');
      }
    }
  }

  /// Cancel specific notification by id
  Future<void> cancel(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      if (kDebugMode) {
        print('🗑️ Notification $id cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling notification: $e');
      }
    }
  }
}
