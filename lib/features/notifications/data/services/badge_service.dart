// lib/features/notifications/data/services/badge_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

/// Service to handle app badge counter (icon notification count)
class BadgeService {
  /// Update app badge with count
  Future<void> updateBadge(int count) async {
    try {
      // Check if badge is supported on this device
      final isSupported = await FlutterAppBadger.isAppBadgeSupported();

      if (!isSupported) {
        if (kDebugMode) {
          print('⚠️ App badge not supported on this device');
        }
        return;
      }

      if (count > 0) {
        // Set badge count
        await FlutterAppBadger.updateBadgeCount(count);
        if (kDebugMode) {
          print('🔢 Badge count updated: $count');
        }
      } else {
        // Remove badge if count is 0
        await FlutterAppBadger.removeBadge();
        if (kDebugMode) {
          print('🔢 Badge removed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating badge: $e');
      }
    }
  }

  /// Increment badge count by 1
  /// Note: You need to track the current count in your app state
  /// This is a helper method that updates the badge with a specific count
  Future<void> incrementBadge({int currentCount = 0}) async {
    try {
      final isSupported = await FlutterAppBadger.isAppBadgeSupported();

      if (!isSupported) {
        return;
      }

      // Increment the provided count by 1
      final newCount = currentCount + 1;
      await FlutterAppBadger.updateBadgeCount(newCount);

      if (kDebugMode) {
        print('🔢 Badge incremented to: $newCount');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error incrementing badge: $e');
      }
    }
  }

  /// Clear app badge
  Future<void> clearBadge() async {
    try {
      await FlutterAppBadger.removeBadge();

      if (kDebugMode) {
        print('🔢 Badge cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing badge: $e');
      }
    }
  }

  /// Check if badge is supported on this device
  Future<bool> isBadgeSupported() async {
    try {
      return await FlutterAppBadger.isAppBadgeSupported();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking badge support: $e');
      }
      return false;
    }
  }
}
