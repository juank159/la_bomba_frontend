import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/password_recovery_controller.dart';
import '../widgets/code_input_field.dart';
import '../widgets/countdown_timer.dart';

/// Verify code page
class VerifyCodePage extends StatelessWidget {
  const VerifyCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Verificar Código'),
      ),
      body: SafeArea(
        child: GetX<PasswordRecoveryController>(
          builder: (controller) {
            return LoadingOverlay(
              isLoading: controller.isLoading,
              message: 'Verificando código...',
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConfig.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppConfig.paddingLarge),

                    // Header
                    _buildHeader(theme),

                    const SizedBox(height: AppConfig.paddingXLarge),

                    // Email display
                    _buildEmailDisplay(controller, theme),

                    const SizedBox(height: AppConfig.paddingXLarge),

                    // Code input
                    CodeInputField(
                      controllers: controller.codeControllers,
                      errorText: controller.codeError,
                      onComplete: controller.verifyCode,
                      onChanged: () => controller.clearFieldError('code'),
                    ),

                    const SizedBox(height: AppConfig.paddingXLarge),

                    // Verify button
                    ElevatedButton.icon(
                      onPressed: controller.isLoading ? null : controller.verifyCode,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Verificar Código'),
                    ),

                    const SizedBox(height: AppConfig.paddingLarge),

                    // Resend code
                    _buildResendCode(controller, theme),
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
            Icons.verified_user,
            size: 40,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppConfig.paddingMedium),
        Text(
          'Ingresa el Código',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConfig.paddingSmall),
        Text(
          'Te enviamos un código de 6 dígitos a tu email',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailDisplay(PasswordRecoveryController controller, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.paddingMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.email_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppConfig.paddingSmall),
          Flexible(
            child: Text(
              controller.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendCode(PasswordRecoveryController controller, ThemeData theme) {
    return Column(
      children: [
        Text(
          '¿No recibiste el código?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppConfig.paddingSmall),
        const CountdownTimer(),
      ],
    );
  }
}
