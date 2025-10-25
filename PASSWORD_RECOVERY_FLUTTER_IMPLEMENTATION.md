# 🔐 IMPLEMENTACIÓN COMPLETA - Password Recovery Flutter

Este documento contiene TODO el código que falta para completar el sistema de recuperación de contraseña en Flutter.

---

## 📁 ESTRUCTURA DE ARCHIVOS A CREAR/MODIFICAR

```
lib/features/auth/
├── data/
│   ├── models/
│   │   ├── request_password_reset_model.dart      ✅ CREADO
│   │   ├── verify_reset_code_model.dart          ✅ CREADO
│   │   └── reset_password_model.dart             ✅ CREADO
│   ├── datasources/
│   │   └── auth_remote_datasource.dart           ✅ ACTUALIZADO
│   └── repositories/
│       └── auth_repository_impl.dart             ⚠️ ACTUALIZAR
├── domain/
│   ├── repositories/
│   │   └── auth_repository.dart                  ⚠️ ACTUALIZAR
│   └── usecases/
│       ├── request_password_reset_usecase.dart   📝 CREAR
│       ├── verify_reset_code_usecase.dart        📝 CREAR
│       └── reset_password_usecase.dart           📝 CREAR
└── presentation/
    ├── controllers/
    │   └── password_recovery_controller.dart     📝 CREAR
    ├── pages/
    │   ├── forgot_password_page.dart             📝 CREAR
    │   ├── verify_code_page.dart                 📝 CREAR
    │   └── reset_password_page.dart              📝 CREAR
    └── widgets/
        ├── code_input_field.dart                 📝 CREAR
        └── countdown_timer.dart                  📝 CREAR

lib/app/config/
└── routes.dart                                   ⚠️ ACTUALIZAR
```

---

## 1️⃣ ACTUALIZAR REPOSITORY (Domain)

**Archivo**: `lib/features/auth/domain/repositories/auth_repository.dart`

Agregar estos métodos al abstract class:

```dart
// AGREGAR ESTOS IMPORTS AL INICIO
import '../../../data/models/request_password_reset_model.dart';
import '../../../data/models/verify_reset_code_model.dart';
import '../../../data/models/reset_password_model.dart';

// AGREGAR ESTOS MÉTODOS AL ABSTRACT CLASS
abstract class AuthRepository {
  // ... métodos existentes ...

  /// Request password reset code
  Future<Either<Failure, void>> requestPasswordReset(String email);

  /// Verify password reset code
  Future<Either<Failure, bool>> verifyResetCode(String email, String code);

  /// Reset password with code
  Future<Either<Failure, void>> resetPassword(String email, String code, String newPassword);
}
```

---

## 2️⃣ ACTUALIZAR REPOSITORY IMPLEMENTATION (Data)

**Archivo**: `lib/features/auth/data/repositories/auth_repository_impl.dart`

Agregar estos imports:

```dart
import '../models/request_password_reset_model.dart';
import '../models/verify_reset_code_model.dart';
import '../models/reset_password_model.dart';
```

Agregar estos métodos a la clase `AuthRepositoryImpl`:

```dart
@override
Future<Either<Failure, void>> requestPasswordReset(String email) async {
  try {
    await remoteDataSource.requestPasswordReset(
      RequestPasswordResetModel(email: email),
    );
    return const Right(null);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, code: e.code));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(UnexpectedFailure(e.toString()));
  }
}

@override
Future<Either<Failure, bool>> verifyResetCode(String email, String code) async {
  try {
    final isValid = await remoteDataSource.verifyResetCode(
      VerifyResetCodeModel(email: email, code: code),
    );
    return Right(isValid);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, code: e.code));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(UnexpectedFailure(e.toString()));
  }
}

@override
Future<Either<Failure, void>> resetPassword(String email, String code, String newPassword) async {
  try {
    await remoteDataSource.resetPassword(
      ResetPasswordModel(email: email, code: code, newPassword: newPassword),
    );
    return const Right(null);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message, code: e.code));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  } catch (e) {
    return Left(UnexpectedFailure(e.toString()));
  }
}
```

---

## 3️⃣ CREAR USE CASES (Domain)

### A) Request Password Reset UseCase

**Archivo**: `lib/features/auth/domain/usecases/request_password_reset_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Use case for requesting password reset
class RequestPasswordResetUseCase implements UseCase<void, String> {
  final AuthRepository repository;

  RequestPasswordResetUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String email) async {
    return await repository.requestPasswordReset(email);
  }
}
```

### B) Verify Reset Code UseCase

**Archivo**: `lib/features/auth/domain/usecases/verify_reset_code_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class VerifyResetCodeParams {
  final String email;
  final String code;

  const VerifyResetCodeParams({
    required this.email,
    required this.code,
  });
}

/// Use case for verifying password reset code
class VerifyResetCodeUseCase implements UseCase<bool, VerifyResetCodeParams> {
  final AuthRepository repository;

  VerifyResetCodeUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(VerifyResetCodeParams params) async {
    return await repository.verifyResetCode(params.email, params.code);
  }
}
```

### C) Reset Password UseCase

**Archivo**: `lib/features/auth/domain/usecases/reset_password_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordParams {
  final String email;
  final String code;
  final String newPassword;

  const ResetPasswordParams({
    required this.email,
    required this.code,
    required this.newPassword,
  });
}

/// Use case for resetting password
class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await repository.resetPassword(
      params.email,
      params.code,
      params.newPassword,
    );
  }
}
```

---

## 4️⃣ CREAR CONTROLLER (Presentation)

**Archivo**: `lib/features/auth/presentation/controllers/password_recovery_controller.dart`

```dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/config/app_config.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import '../../domain/usecases/verify_reset_code_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';

/// Controller for password recovery flow
class PasswordRecoveryController extends GetxController {
  final RequestPasswordResetUseCase requestPasswordResetUseCase;
  final VerifyResetCodeUseCase verifyResetCodeUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  PasswordRecoveryController({
    required this.requestPasswordResetUseCase,
    required this.verifyResetCodeUseCase,
    required this.resetPasswordUseCase,
  });

  // Reactive variables
  final _isLoading = false.obs;
  final _errorMessage = RxnString();
  final _email = ''.obs;
  final _code = ''.obs;
  final _expiryTime = Rxn<DateTime>();

  // Getters
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;
  String get email => _email.value;
  String get code => _code.value;
  DateTime? get expiryTime => _expiryTime.value;

  // Form controllers
  final emailController = TextEditingController();
  final codeControllers = List.generate(6, (_) => TextEditingController());
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Form validation
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
    super.onClose();
  }

  /// Request password reset code
  Future<void> requestPasswordReset() async {
    if (!_validateEmail()) return;

    _isLoading.value = true;
    _errorMessage.value = null;

    final email = emailController.text.trim();

    final result = await requestPasswordResetUseCase(email);

    result.fold(
      (failure) {
        _isLoading.value = false;
        _errorMessage.value = _getFailureMessage(failure);
        _showErrorSnackbar(_errorMessage.value!);
      },
      (_) {
        _isLoading.value = false;
        _email.value = email;

        // Set expiry time (15 minutes from now)
        _expiryTime.value = DateTime.now().add(const Duration(minutes: 15));

        // Navigate to verify code page
        Get.toNamed(Routes.verifyCode);

        _showSuccessSnackbar(
          'Código enviado. Revisa tu email.'
        );
      },
    );
  }

  /// Verify reset code
  Future<void> verifyCode() async {
    if (!_validateCode()) return;

    _isLoading.value = true;
    _errorMessage.value = null;

    final code = codeControllers.map((c) => c.text).join();
    _code.value = code;

    final result = await verifyResetCodeUseCase(
      VerifyResetCodeParams(email: _email.value, code: code),
    );

    result.fold(
      (failure) {
        _isLoading.value = false;
        _errorMessage.value = _getFailureMessage(failure);
        _showErrorSnackbar(_errorMessage.value!);
      },
      (isValid) {
        _isLoading.value = false;
        if (isValid) {
          // Navigate to reset password page
          Get.toNamed(Routes.resetPassword);
        } else {
          _showErrorSnackbar('Código inválido');
        }
      },
    );
  }

  /// Reset password
  Future<void> resetPassword() async {
    if (!_validateNewPassword()) return;

    _isLoading.value = true;
    _errorMessage.value = null;

    final newPassword = newPasswordController.text.trim();

    final result = await resetPasswordUseCase(
      ResetPasswordParams(
        email: _email.value,
        code: _code.value,
        newPassword: newPassword,
      ),
    );

    result.fold(
      (failure) {
        _isLoading.value = false;
        _errorMessage.value = _getFailureMessage(failure);
        _showErrorSnackbar(_errorMessage.value!);
      },
      (_) {
        _isLoading.value = false;

        // Clear all data
        _clearData();

        // Show success and navigate to login
        Get.until((route) => route.settings.name == Routes.login);

        _showSuccessSnackbar(
          'Contraseña actualizada exitosamente. Por favor inicia sesión.'
        );
      },
    );
  }

  /// Validate email
  bool _validateEmail() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _emailError.value = 'El email es requerido';
      return false;
    }

    if (!GetUtils.isEmail(email)) {
      _emailError.value = 'Email inválido';
      return false;
    }

    _emailError.value = null;
    return true;
  }

  /// Validate code
  bool _validateCode() {
    final code = codeControllers.map((c) => c.text).join();

    if (code.length != 6) {
      _codeError.value = 'El código debe tener 6 dígitos';
      return false;
    }

    if (!GetUtils.isNumericOnly(code)) {
      _codeError.value = 'El código debe contener solo números';
      return false;
    }

    _codeError.value = null;
    return true;
  }

  /// Validate new password
  bool _validateNewPassword() {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty) {
      _newPasswordError.value = 'La contraseña es requerida';
      return false;
    }

    if (newPassword.length < AppConfig.minPasswordLength) {
      _newPasswordError.value =
        'La contraseña debe tener al menos ${AppConfig.minPasswordLength} caracteres';
      return false;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError.value = 'Confirma tu contraseña';
      return false;
    }

    if (newPassword != confirmPassword) {
      _confirmPasswordError.value = 'Las contraseñas no coinciden';
      return false;
    }

    _newPasswordError.value = null;
    _confirmPasswordError.value = null;
    return true;
  }

  /// Clear all data
  void _clearData() {
    emailController.clear();
    for (var controller in codeControllers) {
      controller.clear();
    }
    newPasswordController.clear();
    confirmPasswordController.clear();
    _email.value = '';
    _code.value = '';
    _expiryTime.value = null;
    _errorMessage.value = null;
  }

  /// Get failure message
  String _getFailureMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return AppConfig.networkErrorMessage;
    } else {
      return AppConfig.genericErrorMessage;
    }
  }

  /// Show error snackbar
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppConfig.errorColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Éxito',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppConfig.successColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Resend code
  Future<void> resendCode() async {
    await requestPasswordReset();
  }
}
```

---

## 5️⃣ CREAR WIDGETS AUXILIARES

### A) Code Input Field Widget

**Archivo**: `lib/features/auth/presentation/widgets/code_input_field.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/config/app_config.dart';

/// Custom code input field for 6-digit code
class CodeInputField extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback? onCompleted;

  const CodeInputField({
    super.key,
    required this.controllers,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextField(
            controller: controllers[index],
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                // Move to next field
                FocusScope.of(context).nextFocus();
              }

              // Check if all fields are filled
              final allFilled = controllers.every((c) => c.text.isNotEmpty);
              if (allFilled && onCompleted != null) {
                onCompleted!();
              }
            },
            onTap: () {
              controllers[index].selection = TextSelection(
                baseOffset: 0,
                extentOffset: controllers[index].text.length,
              );
            },
          ),
        );
      }),
    );
  }
}
```

### B) Countdown Timer Widget

**Archivo**: `lib/features/auth/presentation/widgets/countdown_timer.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/config/app_config.dart';

/// Countdown timer widget
class CountdownTimer extends StatefulWidget {
  final DateTime expiryTime;
  final VoidCallback? onExpired;

  const CountdownTimer({
    super.key,
    required this.expiryTime,
    this.onExpired,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
      if (_remaining.inSeconds <= 0) {
        _timer?.cancel();
        widget.onExpired?.call();
      }
    });
  }

  void _updateRemaining() {
    setState(() {
      _remaining = widget.expiryTime.difference(DateTime.now());
      if (_remaining.isNegative) {
        _remaining = Duration.zero;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;

    final isExpiringSoon = _remaining.inMinutes < 2;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConfig.paddingMedium,
        vertical: AppConfig.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: isExpiringSoon
            ? AppConfig.errorColor.withOpacity(0.1)
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 20,
            color: isExpiringSoon
                ? AppConfig.errorColor
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: AppConfig.paddingSmall),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isExpiringSoon
                  ? AppConfig.errorColor
                  : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 6️⃣ ACTUALIZAR ROUTES

**Archivo**: `lib/app/config/routes.dart`

Agregar estas rutas a la clase Routes:

```dart
class Routes {
  // ... rutas existentes ...

  // Password recovery routes
  static const forgotPassword = '/forgot-password';
  static const verifyCode = '/verify-code';
  static const resetPassword = '/reset-password';
}
```

Y agregar las páginas al GetPages:

```dart
static final pages = [
  // ... páginas existentes ...

  // Password recovery pages
  GetPage(
    name: Routes.forgotPassword,
    page: () => const ForgotPasswordPage(),
    binding: PasswordRecoveryBinding(),
  ),
  GetPage(
    name: Routes.verifyCode,
    page: () => const VerifyCodePage(),
    binding: PasswordRecoveryBinding(),
  ),
  GetPage(
    name: Routes.resetPassword,
    page: () => const ResetPasswordPage(),
    binding: PasswordRecoveryBinding(),
  ),
];
```

**NOTA**: Necesitas crear el binding también (ver siguiente sección).

---

## 7️⃣ CREAR BINDING

**Archivo**: `lib/features/auth/presentation/bindings/password_recovery_binding.dart`

```dart
import 'package:get/get.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import '../../domain/usecases/verify_reset_code_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../controllers/password_recovery_controller.dart';

class PasswordRecoveryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PasswordRecoveryController>(
      () => PasswordRecoveryController(
        requestPasswordResetUseCase: getIt<RequestPasswordResetUseCase>(),
        verifyResetCodeUseCase: getIt<VerifyResetCodeUseCase>(),
        resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
      ),
    );
  }
}
```

---

## 8️⃣ ACTUALIZAR SERVICE LOCATOR

**Archivo**: `lib/app/core/di/service_locator.dart`

Agregar estos registros en la función de configuración:

```dart
// Password recovery use cases
getIt.registerLazySingleton(
  () => RequestPasswordResetUseCase(getIt()),
);

getIt.registerLazySingleton(
  () => VerifyResetCodeUseCase(getIt()),
);

getIt.registerLazySingleton(
  () => ResetPasswordUseCase(getIt()),
);
```

---

## 9️⃣ MODIFICAR LOGIN PARA AGREGAR BOTÓN "OLVIDÉ MI CONTRASEÑA"

**Archivo**: `lib/features/auth/presentation/widgets/login_form.dart`

Busca el widget del botón de login y agrega DEBAJO:

```dart
// Login button
ElevatedButton(...),

const SizedBox(height: AppConfig.paddingMedium),

// Forgot password button
TextButton(
  onPressed: () {
    Get.toNamed(Routes.forgotPassword);
  },
  child: const Text('¿Olvidaste tu contraseña?'),
),
```

---

## ✅ CHECKLIST FINAL

Para implementar completamente el sistema:

- [ ] Crear los 3 use cases
- [ ] Actualizar AuthRepository (domain)
- [ ] Actualizar AuthRepositoryImpl (data)
- [ ] Crear PasswordRecoveryController
- [ ] Crear las 3 pantallas (next message)
- [ ] Crear los 2 widgets (CodeInputField, CountdownTimer)
- [ ] Crear PasswordRecoveryBinding
- [ ] Actualizar Routes
- [ ] Actualizar Service Locator
- [ ] Modificar LoginForm para agregar botón

---

**NOTA**: En el siguiente mensaje te envío el código de las 3 PANTALLAS que son las más grandes.

