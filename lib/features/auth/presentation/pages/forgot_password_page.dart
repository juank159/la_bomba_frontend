import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../controllers/password_recovery_controller.dart';

/// Forgot password page
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
      ),
      body: SafeArea(
        child: GetX<PasswordRecoveryController>(
          builder: (controller) {
            return LoadingOverlay(
              isLoading: controller.isLoading,
              message: 'Enviando código...',
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConfig.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppConfig.paddingLarge),

                    // Header
                    _buildHeader(theme),

                    const SizedBox(height: AppConfig.paddingXLarge),

                    // Description
                    _buildDescription(theme),

                    const SizedBox(height: AppConfig.paddingXLarge),

                    // Email input
                    CustomInput(
                      label: 'Email',
                      hint: 'tu@email.com',
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: controller.emailError,
                      onChanged: (_) => controller.clearFieldError('email'),
                    ),

                    const SizedBox(height: AppConfig.paddingXLarge),

                    // Send code button
                    ElevatedButton.icon(
                      onPressed: controller.isLoading ? null : controller.requestPasswordReset,
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar Código'),
                    ),

                    const SizedBox(height: AppConfig.paddingLarge),

                    // Back to login
                    TextButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver al inicio de sesión'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppConfig.borderRadiusLarge),
          ),
          child: Icon(
            Icons.lock_reset,
            size: 40,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppConfig.paddingMedium),
        Text(
          '¿Olvidaste tu contraseña?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Text(
      'Ingresa tu email y te enviaremos un código de 6 dígitos para recuperar tu contraseña.',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }
}
