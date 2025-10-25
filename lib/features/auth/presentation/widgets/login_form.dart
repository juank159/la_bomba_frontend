import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../controllers/auth_controller.dart';
import 'email_autocomplete_input.dart';

/// Login form widget with validation and reactive state management
class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<AuthController>(
      builder: (controller) {
        return Column(
          children: [
            // Error Message Display
            if (controller.errorMessage != null) ...[
              _buildErrorMessage(controller.errorMessage!),
              const SizedBox(height: AppConfig.paddingLarge),
            ],

            // Email Input with Autocomplete
            EmailAutocompleteInput(
              controller: controller.emailController,
              errorText: controller.emailError,
              onChanged: (_) => controller.clearFieldError('email'),
            ),

            const SizedBox(height: AppConfig.paddingLarge),

            // Password Input
            CustomInput(
              label: 'Contraseña',
              hint: 'Ingresa tu contraseña',
              controller: controller.passwordController,
              obscureText: true,
              prefixIcon: const Icon(Icons.lock_outline),
              errorText: controller.passwordError,
              onChanged: (_) => controller.clearFieldError('password'),
            ),

            const SizedBox(height: AppConfig.paddingXLarge),

            // Login Button
            CustomButton(
              text: 'Iniciar Sesión',
              icon: Icons.login,
              isLoading: controller.isLoading,
              onPressed: controller.isLoading ? null : controller.login,
            ),

            const SizedBox(height: AppConfig.paddingMedium),

            // Forgot Password Button
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ],
        );
      },
    );
  }

  /// Build error message widget
  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(AppConfig.paddingMedium),
      decoration: BoxDecoration(
        color: AppConfig.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(
          color: AppConfig.errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppConfig.errorColor,
            size: 20,
          ),
          const SizedBox(width: AppConfig.paddingSmall),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppConfig.errorColor,
                fontSize: AppConfig.captionFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppConfig.errorColor,
            onPressed: () {
              Get.find<AuthController>().clearError();
            },
          ),
        ],
      ),
    );
  }

  /// Build demo credentials helper for development
  Widget _buildDemoCredentials(AuthController controller) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: AppConfig.paddingMedium),
        Text(
          'Credenciales de prueba',
          style: TextStyle(
            fontSize: AppConfig.captionFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: AppConfig.paddingSmall),
        Wrap(
          spacing: AppConfig.paddingSmall,
          runSpacing: AppConfig.paddingSmall,
          children: [
            _buildDemoButton(
              'Admin',
              () {
                controller.emailController.text = 'admin@pedidos.com';
                controller.passwordController.text = 'admin123';
              },
            ),
            _buildDemoButton(
              'Empleado',
              () {
                controller.emailController.text = 'empleado@pedidos.com';
                controller.passwordController.text = 'empleado123';
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Build demo credential button
  Widget _buildDemoButton(String label, VoidCallback onPressed) {
    return CustomTextButton(
      text: label,
      onPressed: onPressed,
      icon: Icons.person,
    );
  }
}