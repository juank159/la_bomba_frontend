import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/auth_controller.dart';

/// Splash screen that checks authentication status and navigates accordingly
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthenticationStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: AppConfig.animationDurationMedium,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      // Get auth controller (already initialized in main.dart)
      final authController = Get.find<AuthController>();

      // Wait for the auth controller to initialize
      while (!authController.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Add minimum splash duration for better UX
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Navigate based on authentication status
      if (authController.isAuthenticated) {
        // Navigate based on user role
        _navigateBasedOnRole(authController);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      // If there's an error, default to login page
      if (mounted) {
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }

  /// Navigate based on user role
  void _navigateBasedOnRole(AuthController authController) {
    if (authController.isAdmin) {
      Get.offAllNamed('/products');
    } else if (authController.user?.role.isSupervisor ?? false) {
      Get.offAllNamed('/supervisor');
    } else if (authController.isEmployee) {
      Get.offAllNamed('/products');
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;
    final surfaceColor = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo/Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(AppConfig.borderRadiusLarge),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 60,
                          color: primaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: AppConfig.paddingLarge),
                      
                      // App Name
                      Text(
                        AppConfig.appName,
                        style: TextStyle(
                          fontSize: AppConfig.titleFontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: AppConfig.paddingSmall),
                      
                      // App Description
                      Text(
                        AppConfig.appDescription,
                        style: TextStyle(
                          fontSize: AppConfig.bodyFontSize,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      
                      const SizedBox(height: AppConfig.paddingXLarge),
                      
                      // Loading Indicator
                      const CustomLoadingWidget(
                        color: Colors.white,
                        size: 24,
                      ),
                      
                      const SizedBox(height: AppConfig.paddingMedium),
                      
                      // Loading Text
                      Text(
                        'Iniciando...',
                        style: TextStyle(
                          fontSize: AppConfig.captionFontSize,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}