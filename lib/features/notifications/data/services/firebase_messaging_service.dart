// lib/features/notifications/data/services/firebase_messaging_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import 'local_notification_service.dart';
import 'badge_service.dart';

/// Service to handle Firebase Cloud Messaging (Push Notifications)
class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final LocalNotificationService _localNotificationService;
  final AuthRepository _authRepository;
  final BadgeService _badgeService;

  FirebaseMessagingService({
    required LocalNotificationService localNotificationService,
    required AuthRepository authRepository,
    required BadgeService badgeService,
  })  : _localNotificationService = localNotificationService,
        _authRepository = authRepository,
        _badgeService = badgeService;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // 1. Request notification permissions
      await _requestPermissions();

      // 2. Get FCM token and save to backend
      await _getAndSaveToken();

      // 3. Setup notification handlers
      _setupMessageHandlers();

      // 4. Handle notification taps
      _setupNotificationTapHandlers();

      if (kDebugMode) {
        print('✅ Firebase Messaging initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Firebase Messaging: $e');
      }
    }
  }

  /// Request notification permissions (especially important for iOS)
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    if (kDebugMode) {
      print('📱 Notification permission status: ${settings.authorizationStatus}');
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('✅ User granted notification permissions');
      }
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('⚠️ User granted provisional notification permissions');
      }
    } else {
      if (kDebugMode) {
        print('❌ User declined notification permissions');
      }
    }
  }

  /// Get FCM token and save to backend
  Future<void> _getAndSaveToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('📲 FCM Token: $token');
        }

        // Save token to backend
        await _saveTokenToBackend(token);

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          if (kDebugMode) {
            print('🔄 FCM Token refreshed: $newToken');
          }
          _saveTokenToBackend(newToken);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token: $e');
      }
    }
  }

  /// Save FCM token to backend
  Future<void> _saveTokenToBackend(String token) async {
    try {
      // Check if user is authenticated
      final isAuthResult = await _authRepository.isAuthenticated();

      isAuthResult.fold(
        (failure) {
          if (kDebugMode) {
            print('❌ Error checking authentication: ${failure.message}');
          }
        },
        (isAuth) async {
          if (!isAuth) {
            if (kDebugMode) {
              print('⚠️ User not authenticated, skipping FCM token save');
            }
            return;
          }

          // Update FCM token in backend
          final result = await _authRepository.updateFcmToken(token);

          result.fold(
            (failure) {
              if (kDebugMode) {
                print('❌ Error saving FCM token to backend: ${failure.message}');
              }
            },
            (_) {
              if (kDebugMode) {
                print('💾 FCM Token saved to backend successfully: $token');
              }
            },
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error saving FCM token to backend: $e');
      }
    }
  }

  /// Setup handlers for incoming messages
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('📬 Notification received (foreground):');
        print('   Title: ${message.notification?.title}');
        print('   Body: ${message.notification?.body}');
        print('   Data: ${message.data}');
      }

      // Show local notification when app is in foreground
      _localNotificationService.showNotification(
        title: message.notification?.title ?? 'Nueva notificación',
        body: message.notification?.body ?? '',
        payload: message.data,
      );

      // Update badge count to 1 (indicating unread notifications)
      _badgeService.updateBadge(1);
    });

    // Handle messages when app is in background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Setup handlers for notification taps
  void _setupNotificationTapHandlers() {
    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('🔔 User tapped notification (background):');
        print('   Data: ${message.data}');
      }

      // Clear badge when user opens notification
      _badgeService.clearBadge();

      _handleNotificationTap(message.data);
    });

    // Handle notification tap when app was terminated
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('🔔 User tapped notification (terminated):');
          print('   Data: ${message.data}');
        }

        // Clear badge when user opens notification
        _badgeService.clearBadge();

        _handleNotificationTap(message.data);
      }
    });
  }

  /// Handle notification tap navigation
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
        print('   ProductId: $productId');
        print('   CreditId: $creditId');
      }

      // Navigate based on notification type
      switch (type) {
        case 'SUPERVISOR_TASK':
          // Navigate to supervisor tasks page
          Get.offAllNamed('/supervisor', arguments: {'taskId': taskId});
          break;

        case 'ADMIN_TASK':
          // Navigate to admin tasks page
          Get.offAllNamed('/admin-tasks', arguments: {'taskId': taskId});
          break;

        case 'PRODUCT_UPDATE':
          // Navigate to supervisor tasks page for product updates
          Get.offAllNamed('/supervisor', arguments: {'taskId': taskId});
          break;

        case 'PRODUCT_APPROVED':
          // Navigate to products page with specific product
          Get.offAllNamed('/products', arguments: {'productId': productId});
          break;

        case 'CREDIT_REMINDER':
          // Navigate to credits page
          Get.offAllNamed('/credits', arguments: {'creditId': creditId});
          break;

        case 'ORDER_UPDATE':
          // Navigate to orders page
          Get.offAllNamed('/orders');
          break;

        default:
          // Navigate to home/products by default
          Get.offAllNamed('/products');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification tap: $e');
      }
      // Fallback to products page
      Get.offAllNamed('/products');
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Delete FCM token (useful for logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      if (kDebugMode) {
        print('🗑️ FCM Token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting FCM token: $e');
      }
    }
  }
}

/// Top-level function to handle background messages
/// Must be a top-level function (cannot be a class method)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('📬 Notification received (background):');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');
  }

  // Note: This runs in a separate isolate, so we can't access app state here
  // Background notifications are automatically shown by the system
}
