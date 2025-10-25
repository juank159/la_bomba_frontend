import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/routes.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import '../../domain/usecases/verify_reset_code_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';

/// Controller for password recovery flow using GetX
class PasswordRecoveryController extends GetxController {
  final RequestPasswordResetUseCase requestPasswordResetUseCase;
  final VerifyResetCodeUseCase verifyResetCodeUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  PasswordRecoveryController({
    required this.requestPasswordResetUseCase,
    required this.verifyResetCodeUseCase,
    required this.resetPasswordUseCase,
  });

  // Reactive state variables
  final _isLoading = false.obs;
  final _errorMessage = RxnString();
  final _successMessage = RxnString();
  final _email = ''.obs;
  final _code = ''.obs;

  // Countdown timer for resend
  final _canResend = true.obs;
  final _resendCountdown = 60.obs;
  Timer? _resendTimer;

  // Getters
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;
  String? get successMessage => _successMessage.value;
  String get email => _email.value;
  String get code => _code.value;
  bool get canResend => _canResend.value;
  int get resendCountdown => _resendCountdown.value;

  // Form controllers
  final emailController = TextEditingController();
  final codeControllers = List.generate(6, (_) => TextEditingController());
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Form validation errors
  final _emailError = RxnString();
  final _codeError = RxnString();
  final _newPasswordError = RxnString();
  final _confirmPasswordError = RxnString();

  String? get emailError => _emailError.value;
  String? get codeError => _codeError.value;
  String? get newPasswordError => _newPasswordError.value;
  String? get confirmPasswordError => _confirmPasswordError.value;

  @override
  void onClose() {
    emailController.dispose();
    for (var controller in codeControllers) {
      controller.dispose();
    }
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.onClose();
  }

  /// Clear all error and success messages
  void clearMessages() {
    _errorMessage.value = null;
    _successMessage.value = null;
  }

  /// Clear specific field error
  void clearFieldError(String field) {
    switch (field) {
      case 'email':
        _emailError.value = null;
        break;
      case 'code':
        _codeError.value = null;
        break;
      case 'newPassword':
        _newPasswordError.value = null;
        break;
      case 'confirmPassword':
        _confirmPasswordError.value = null;
        break;
    }
    _errorMessage.value = null;
  }

  /// Clear all field errors
  void clearAllErrors() {
    _emailError.value = null;
    _codeError.value = null;
    _newPasswordError.value = null;
    _confirmPasswordError.value = null;
    _errorMessage.value = null;
  }

  /// Request password reset code
  Future<void> requestPasswordReset() async {
    clearMessages();
    clearAllErrors();

    final email = emailController.text.trim();

    if (email.isEmpty) {
      _emailError.value = 'El email es requerido';
      return;
    }

    _isLoading.value = true;

    try {
      final params = RequestPasswordResetParams(email: email);
      final result = await requestPasswordResetUseCase(params);

      result.fold(
        (failure) {
          _emailError.value = failure.message;
        },
        (response) {
          _email.value = email;

          // Show code in message if email failed (development/production fallback)
          if (response != null && response.containsKey('code')) {
            final code = response['code'] as String;
            _successMessage.value = 'Tu código es: $code\n(El email no se envió, usa este código)';
            print('🔑 Recovery code: $code');
          } else {
            _successMessage.value = 'Código enviado a tu email';
          }

          _startResendCountdown();
          Get.toNamed(AppRoutes.verifyCode);
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Verify reset code
  Future<void> verifyCode() async {
    clearMessages();
    clearAllErrors();

    final codeString = codeControllers.map((c) => c.text).join();

    if (codeString.length != 6) {
      _codeError.value = 'Ingresa el código completo';
      return;
    }

    _isLoading.value = true;

    try {
      final params = VerifyResetCodeParams(
        email: _email.value,
        code: codeString,
      );
      final result = await verifyResetCodeUseCase(params);

      result.fold(
        (failure) {
          _codeError.value = failure.message;
          // Clear code inputs on error
          for (var controller in codeControllers) {
            controller.clear();
          }
        },
        (isValid) {
          if (isValid) {
            _code.value = codeString;
            _successMessage.value = 'Código verificado';
            Get.toNamed(AppRoutes.resetPassword);
          } else {
            _codeError.value = 'Código inválido o expirado';
            // Clear code inputs
            for (var controller in codeControllers) {
              controller.clear();
            }
          }
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Reset password with verified code
  Future<void> resetPassword() async {
    clearMessages();
    clearAllErrors();

    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Validate passwords
    if (newPassword.isEmpty) {
      _newPasswordError.value = 'La contraseña es requerida';
      return;
    }

    if (newPassword.length < 6) {
      _newPasswordError.value = 'La contraseña debe tener al menos 6 caracteres';
      return;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError.value = 'Confirma tu contraseña';
      return;
    }

    if (newPassword != confirmPassword) {
      _confirmPasswordError.value = 'Las contraseñas no coinciden';
      return;
    }

    _isLoading.value = true;

    try {
      final params = ResetPasswordParams(
        email: _email.value,
        code: _code.value,
        newPassword: newPassword,
      );
      final result = await resetPasswordUseCase(params);

      result.fold(
        (failure) {
          _errorMessage.value = failure.message;
        },
        (_) {
          _successMessage.value = 'Contraseña actualizada exitosamente';

          // Clear all data
          _email.value = '';
          _code.value = '';
          emailController.clear();
          for (var controller in codeControllers) {
            controller.clear();
          }
          newPasswordController.clear();
          confirmPasswordController.clear();

          // Navigate to login after short delay
          Future.delayed(const Duration(seconds: 1), () {
            Get.offAllNamed(AppRoutes.login);
            Get.snackbar(
              'Éxito',
              'Contraseña actualizada. Inicia sesión con tu nueva contraseña',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF4CAF50),
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          });
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Resend verification code
  Future<void> resendCode() async {
    if (!_canResend.value) {
      return;
    }

    clearMessages();

    // Clear existing code inputs
    for (var controller in codeControllers) {
      controller.clear();
    }

    await requestPasswordReset();
  }

  /// Start resend countdown timer
  void _startResendCountdown() {
    _canResend.value = false;
    _resendCountdown.value = 60;

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown.value > 0) {
        _resendCountdown.value--;
      } else {
        _canResend.value = true;
        timer.cancel();
      }
    });
  }

  /// Navigate back to login
  void backToLogin() {
    Get.offAllNamed(AppRoutes.login);
  }
}
