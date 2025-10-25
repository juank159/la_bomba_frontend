import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../controllers/password_recovery_controller.dart';

/// Reset password page
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Nueva Contraseña'),
      ),
      body: SafeArea(
        child: GetX<PasswordRecoveryController>(
          builder: (controller) {
            return LoadingOverlay(
              isLoading: controller.isLoading,
              message: 'Actualizando contraseña...',
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

                    // New password input
                    CustomInput(
                      label: 'Nueva Contraseña',
                      hint: 'Mínimo 6 caracteres',
                      controller: controller.newPasswordController,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: controller.newPasswordError,
                      onChanged: (_) => controller.clearFieldError('newPassword'),
                    ),

                    const SizedBox(height: AppConfig.paddingMedium),

                    // Confirm password input
                    CustomInput(
                      label: 'Confirmar Contraseña',
                      hint: 'Repite tu contraseña',
                      controller: controller.confirmPasswordController,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: controller.confirmPasswordError,
                      onChanged: (_) => controller.clearFieldError('confirmPassword'),
                    ),

                    const SizedBox(height: AppConfig.paddingSmall),

                    // Password requirements
                    _buildPasswordRequirements(theme),

                    const SizedBox(height: AppConfig.paddingXLarge),

                    // Reset password button
                    ElevatedButton.icon(
                      onPressed: controller.isLoading ? null : controller.resetPassword,
                      icon: const Icon(Icons.check),
                      label: const Text('Actualizar Contraseña'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.successColor,
                        foregroundColor: Colors.white,
                      ),
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
            color: AppConfig.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConfig.borderRadiusLarge),
          ),
          child: Icon(
            Icons.lock_open,
            size: 40,
            color: AppConfig.successColor,
          ),
        ),
        const SizedBox(height: AppConfig.paddingMedium),
        Text(
          'Nueva Contraseña',
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
      'Ingresa tu nueva contraseña. Asegúrate de que sea segura y fácil de recordar.',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPasswordRequirements(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.paddingMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppConfig.paddingSmall),
              Text(
                'Requisitos de la contraseña:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConfig.paddingSmall),
          _buildRequirement(theme, 'Mínimo 6 caracteres'),
          _buildRequirement(theme, 'Las contraseñas deben coincidir'),
        ],
      ),
    );
  }

  Widget _buildRequirement(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: AppConfig.paddingMedium),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppConfig.paddingSmall),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
