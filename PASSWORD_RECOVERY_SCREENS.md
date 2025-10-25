# 🎨 PANTALLAS DE PASSWORD RECOVERY - Flutter

Código completo de las 3 pantallas siguiendo tu arquitectura y estilo.

---

## 1️⃣ FORGOT PASSWORD PAGE

**Archivo**: `lib/features/auth/presentation/pages/forgot_password_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
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
                    _buildEmailInput(controller, theme),

                    const SizedBox(height: AppConfig.paddingXLarge),

                    // Send code button
                    _buildSendCodeButton(controller),

                    const SizedBox(height: AppConfig.paddingLarge),

                    // Back to login
                    _buildBackToLogin(),
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

  Widget _buildEmailInput(PasswordRecoveryController controller, ThemeData theme) {
    return TextField(
      controller: controller.emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'tu@email.com',
        prefixIcon: const Icon(Icons.email_outlined),
        errorText: controller.emailError,
      ),
      onSubmitted: (_) => controller.requestPasswordReset(),
    );
  }

  Widget _buildSendCodeButton(PasswordRecoveryController controller) {
    return ElevatedButton.icon(
      onPressed: controller.requestPasswordReset,
      icon: const Icon(Icons.send),
      label: const Text('Enviar Código'),
    );
  }

  Widget _buildBackToLogin() {
    return TextButton.icon(
      onPressed: () => Get.back(),
      icon: const Icon(Icons.arrow_back),
      label: const Text('Volver al inicio de sesión'),
    );
  }
}
```

---

## 2️⃣ VERIFY CODE PAGE

**Archivo**: `lib/features/auth/presentation/pages/verify_code_page.dart`

```dart
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

                    const SizedBox(height: AppConfig.paddingLarge),

                    // Timer
                    if (controller.expiryTime != null)
                      Center(
                        child: CountdownTimer(
                          expiryTime: controller.expiryTime!,
                          onExpired: () {
                            Get.snackbar(
                              'Código Expirado',
                              'El código ha expirado. Por favor solicita uno nuevo.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppConfig.errorColor,
                              colorText: Colors.white,
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: AppConfig.paddingXLarge),

                    // Code input
                    CodeInputField(
                      controllers: controller.codeControllers,
                      onCompleted: controller.verifyCode,
                    ),

                    if (controller.codeError != null) ...[
                      const SizedBox(height: AppConfig.paddingSmall),
                      Text(
                        controller.codeError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: AppConfig.paddingXLarge),

                    // Verify button
                    _buildVerifyButton(controller),

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

  Widget _buildVerifyButton(PasswordRecoveryController controller) {
    return ElevatedButton.icon(
      onPressed: controller.verifyCode,
      icon: const Icon(Icons.check_circle),
      label: const Text('Verificar Código'),
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
        TextButton.icon(
          onPressed: controller.resendCode,
          icon: const Icon(Icons.refresh),
          label: const Text('Reenviar Código'),
        ),
      ],
    );
  }
}
```

---

## 3️⃣ RESET PASSWORD PAGE

**Archivo**: `lib/features/auth/presentation/pages/reset_password_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/password_recovery_controller.dart';

/// Reset password page
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

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
                    _buildNewPasswordInput(controller, theme),

                    const SizedBox(height: AppConfig.paddingMedium),

                    // Confirm password input
                    _buildConfirmPasswordInput(controller, theme),

                    const SizedBox(height: AppConfig.paddingSmall),

                    // Password requirements
                    _buildPasswordRequirements(theme),

                    const SizedBox(height: AppConfig.paddingXLarge),

                    // Reset password button
                    _buildResetButton(controller),
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

  Widget _buildNewPasswordInput(PasswordRecoveryController controller, ThemeData theme) {
    return TextField(
      controller: controller.newPasswordController,
      obscureText: _obscureNewPassword,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Nueva Contraseña',
        hintText: 'Mínimo ${AppConfig.minPasswordLength} caracteres',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureNewPassword = !_obscureNewPassword;
            });
          },
        ),
        errorText: controller.newPasswordError,
      ),
    );
  }

  Widget _buildConfirmPasswordInput(PasswordRecoveryController controller, ThemeData theme) {
    return TextField(
      controller: controller.confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Confirmar Contraseña',
        hintText: 'Repite tu contraseña',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
        errorText: controller.confirmPasswordError,
      ),
      onSubmitted: (_) => controller.resetPassword(),
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
          _buildRequirement(
            theme,
            'Mínimo ${AppConfig.minPasswordLength} caracteres',
          ),
          _buildRequirement(
            theme,
            'Las contraseñas deben coincidir',
          ),
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

  Widget _buildResetButton(PasswordRecoveryController controller) {
    return ElevatedButton.icon(
      onPressed: controller.resetPassword,
      icon: const Icon(Icons.check),
      label: const Text('Actualizar Contraseña'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConfig.successColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
```

---

## ✅ CARACTERÍSTICAS DE LAS PANTALLAS

### Forgot Password Page:
- ✅ Header con ícono y título
- ✅ Descripción clara del proceso
- ✅ Input de email con validación
- ✅ Botón de envío
- ✅ Botón para volver al login
- ✅ Loading overlay mientras envía

### Verify Code Page:
- ✅ Header con ícono y título
- ✅ Muestra el email al que se envió el código
- ✅ Countdown timer de 15 minutos
- ✅ 6 campos individuales para el código
- ✅ Auto-focus al siguiente campo
- ✅ Validación de código numérico
- ✅ Botón de reenviar código
- ✅ Loading overlay mientras verifica

### Reset Password Page:
- ✅ Header con ícono de éxito
- ✅ Descripción motivacional
- ✅ Input de nueva contraseña con visibilidad toggle
- ✅ Input de confirmación con visibilidad toggle
- ✅ Requisitos de contraseña mostrados
- ✅ Validación de coincidencia
- ✅ Botón verde de actualización
- ✅ Loading overlay mientras actualiza

---

## 🎨 ESTILOS APLICADOS

Todas las pantallas siguen:
- ✅ Material 3 design
- ✅ Tus constantes de AppConfig (padding, border radius, colores)
- ✅ Tema dinámico (light/dark mode)
- ✅ Responsive con SingleChildScrollView
- ✅ Loading overlay consistente
- ✅ Íconos descriptivos
- ✅ Mensajes de error claros
- ✅ Snackbars para feedback

---

## 📱 FLUJO DE USUARIO

```
LoginPage
   ↓ Click "¿Olvidaste tu contraseña?"
ForgotPasswordPage
   ↓ Ingresa email → Click "Enviar Código"
VerifyCodePage
   ↓ Ingresa 6 dígitos → Click "Verificar"
ResetPasswordPage
   ↓ Nueva contraseña → Click "Actualizar"
LoginPage (con mensaje de éxito)
```

---

## 🔧 IMPORTS NECESARIOS

Asegúrate de tener estos imports en cada archivo:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/password_recovery_controller.dart';
import '../widgets/code_input_field.dart';      // Solo en verify_code_page
import '../widgets/countdown_timer.dart';        // Solo en verify_code_page
```

---

## ✅ TESTING

Para probar las pantallas sin backend:

1. Comenta la lógica de API en el controller temporalmente
2. Navega manualmente entre pantallas
3. Verifica que todos los inputs funcionen
4. Verifica que el timer funcione (verify code page)
5. Verifica que los toggles de visibilidad funcionen

---

**¡Listo!** Con estas 3 pantallas + el documento anterior tienes TODO el sistema completo de recuperación de contraseña.

