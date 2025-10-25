import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../controllers/password_recovery_controller.dart';

/// Widget that displays countdown timer for code resend
class CountdownTimer extends StatelessWidget {
  const CountdownTimer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = Get.find<PasswordRecoveryController>();

    return GetX<PasswordRecoveryController>(
      builder: (controller) {
        if (controller.canResend) {
          return TextButton.icon(
            onPressed: controller.resendCode,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Reenviar código'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConfig.paddingMedium,
            vertical: AppConfig.paddingSmall,
          ),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 20,
                color: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: AppConfig.paddingSmall),
              Text(
                'Reenviar en ${controller.resendCountdown}s',
                style: TextStyle(
                  fontSize: AppConfig.captionFontSize,
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
