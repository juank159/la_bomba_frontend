// lib/app/core/guards/auth_guard.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../config/routes.dart';

/// AuthGuard to protect routes that require authentication
class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (route == null) return null;
    // Get the auth controller
    final authController = Get.find<AuthController>();

    // If user is not authenticated, redirect to login
    if (!authController.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }

    // Check role-based access
    return _checkRoleBasedAccess(route, authController);
  }

  /// Check if user has access to the route based on their role
  RouteSettings? _checkRoleBasedAccess(
    String route,
    AuthController authController,
  ) {
    final userRole = authController.user?.role.value.toLowerCase() ?? '';

    switch (route) {
      // Supervisor routes - accessible by supervisors and admins
      case AppRoutes.supervisor:
      case AppRoutes.supervisorDashboard:
        if (!authController.isSupervisor && !authController.isAdmin) {
          return _getDefaultRouteForRole(userRole);
        }
        break;

      // Admin routes - could add specific admin-only routes here
      case AppRoutes.products:
      case AppRoutes.orders:
        // These are accessible by all authenticated users for now
        break;

      default:
        // Allow access to other routes
        break;
    }

    return null; // Allow access
  }

  /// Get default route based on user role
  RouteSettings _getDefaultRouteForRole(String role) {
    switch (role) {
      case 'admin':
        return const RouteSettings(name: AppRoutes.products);
      case 'supervisor':
        return const RouteSettings(name: AppRoutes.supervisor);
      case 'employee':
        return const RouteSettings(name: AppRoutes.products);
      default:
        return const RouteSettings(name: AppRoutes.login);
    }
  }
}

/// Role-specific guards for more granular access control
class AdminGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (route == null) return null;
    final authController = Get.find<AuthController>();

    if (!authController.isAuthenticated || !authController.isAdmin) {
      return _getDefaultRouteForRole(
        authController.user?.role.value.toLowerCase() ?? '',
      );
    }

    return null;
  }

  RouteSettings _getDefaultRouteForRole(String role) {
    switch (role) {
      case 'supervisor':
        return const RouteSettings(name: AppRoutes.supervisor);
      case 'employee':
        return const RouteSettings(name: AppRoutes.products);
      default:
        return const RouteSettings(name: AppRoutes.login);
    }
  }
}

class SupervisorGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (route == null) return null;
    final authController = Get.find<AuthController>();

    // Allow access to both supervisors and admins
    // Admins can view supervisor tasks for monitoring purposes
    if (!authController.isAuthenticated ||
        (!authController.isSupervisor && !authController.isAdmin)) {
      return _getDefaultRouteForRole(
        authController.user?.role.value.toLowerCase() ?? '',
      );
    }

    return null;
  }

  RouteSettings _getDefaultRouteForRole(String role) {
    switch (role) {
      case 'employee':
        return const RouteSettings(name: AppRoutes.products);
      default:
        return const RouteSettings(name: AppRoutes.login);
    }
  }
}
