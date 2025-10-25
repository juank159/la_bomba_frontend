import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/auth_controller.dart';
import '../widgets/login_form.dart';

/// Login page with form validation and GetX state management
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: GetX<AuthController>(
          builder: (controller) {
            return LoadingOverlay(
              isLoading: controller.isLoading,
              message: 'Iniciando sesión...',
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConfig.paddingLarge),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 
                               MediaQuery.of(context).viewPadding.top - 
                               (AppConfig.paddingLarge * 2),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppConfig.paddingXLarge),
                        
                        // Header Section
                        _buildHeader(),
                        
                        const SizedBox(height: AppConfig.paddingXLarge),
                        
                        // Login Form
                        const Expanded(
                          child: LoginForm(),
                        ),
                        
                        const SizedBox(height: AppConfig.paddingLarge),
                        
                        // Footer
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build header section with app logo and welcome text
  Widget _buildHeader() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;
        final onSurfaceColor = theme.colorScheme.onSurface;
        final onSurfaceVariantColor = theme.colorScheme.onSurfaceVariant;

        return Column(
          children: [
            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(AppConfig.borderRadiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 50,
                color: theme.colorScheme.onPrimary,
              ),
            ),

            const SizedBox(height: AppConfig.paddingLarge),

            // Welcome Text
            Text(
              'Bienvenido',
              style: TextStyle(
                fontSize: AppConfig.titleFontSize,
                fontWeight: FontWeight.bold,
                color: onSurfaceColor,
              ),
            ),

            const SizedBox(height: AppConfig.paddingSmall),

            Text(
              'Inicia sesión para continuar',
              style: TextStyle(
                fontSize: AppConfig.bodyFontSize,
                color: onSurfaceVariantColor,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build footer section
  Widget _buildFooter() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final subtitleColor = theme.colorScheme.onSurfaceVariant.withOpacity(0.6);

        return Column(
          children: [
            // Version Info
            Text(
              'Version ${AppConfig.appVersion}',
              style: TextStyle(
                fontSize: AppConfig.smallFontSize,
                color: subtitleColor,
              ),
            ),

            const SizedBox(height: AppConfig.paddingSmall),

            // Company Name
            Text(
              AppConfig.companyName,
              style: TextStyle(
                fontSize: AppConfig.smallFontSize,
                color: subtitleColor,
              ),
            ),
          ],
        );
      },
    );
  }
}