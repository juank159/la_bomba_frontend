import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/services/preferences_service.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/repositories/auth_repository.dart';

/// Auth controller using GetX for state management
class AuthController extends GetxController {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthRepository authRepository;
  final PreferencesService _preferencesService = getIt<PreferencesService>();

  AuthController({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.authRepository,
  });

  // Reactive variables
  final _isLoading = false.obs;
  final _isInitialized = false.obs;
  final _user = Rx<User?>(null);
  final _errorMessage = RxnString();
  final _isAuthenticated = false.obs;

  // Getters for reactive variables
  bool get isLoading => _isLoading.value;
  bool get isInitialized => _isInitialized.value;
  User? get user => _user.value;
  String? get errorMessage => _errorMessage.value;
  bool get isAuthenticated => _isAuthenticated.value;

  // Form controllers for login
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Form validation
  final _emailError = RxnString();
  final _passwordError = RxnString();

  String? get emailError => _emailError.value;
  String? get passwordError => _passwordError.value;

  @override
  void onInit() {
    super.onInit();
    _loadLastEmail();
    checkAuthenticationStatus();
  }

  /// Load last used email
  void _loadLastEmail() {
    final lastEmail = _preferencesService.getLastEmail();
    if (lastEmail != null && lastEmail.isNotEmpty) {
      emailController.text = lastEmail;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Check initial authentication status
  Future<void> checkAuthenticationStatus() async {
    try {
      _isLoading.value = true;
      
      final isAuthResult = await authRepository.isAuthenticated();
      await isAuthResult.fold(
        (failure) async {
          _isAuthenticated.value = false;
          _user.value = null;
        },
        (isAuth) async {
          if (isAuth) {
            // Get current user if authenticated
            final userResult = await authRepository.getCurrentUser();
            userResult.fold(
              (failure) {
                _isAuthenticated.value = false;
                _user.value = null;
              },
              (currentUser) {
                _isAuthenticated.value = currentUser != null;
                _user.value = currentUser;
              },
            );
          } else {
            _isAuthenticated.value = false;
            _user.value = null;
          }
        },
      );
    } catch (e) {
      _isAuthenticated.value = false;
      _user.value = null;
    } finally {
      _isLoading.value = false;
      _isInitialized.value = true;
    }
  }

  /// Login with email and password
  Future<void> login() async {
    if (!_validateLoginForm()) return;

    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      _clearFormErrors();

      final params = LoginParams(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final result = await loginUseCase(params);

      result.fold(
        (failure) {
          _handleLoginFailure(failure);
        },
        (user) async {
          _user.value = user;
          _isAuthenticated.value = true;

          // Save email for autocomplete
          final email = emailController.text.trim();
          await _preferencesService.saveEmail(email);
          await _preferencesService.setLastEmail(email);

          _clearLoginForm();

          // Navigate to home page
          Get.offAllNamed(AppRoutes.home);
        },
      );
    } catch (e) {
      _errorMessage.value = 'Error inesperado: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _isLoading.value = true;
      
      final result = await logoutUseCase();
      
      result.fold(
        (failure) {
          // Even if server logout fails, clear local data
          _clearUserData();
          Get.offAllNamed(AppRoutes.login);
        },
        (_) {
          _clearUserData();
          Get.offAllNamed(AppRoutes.login);
        },
      );
    } catch (e) {
      // Force logout locally even if there's an error
      _clearUserData();
      Get.offAllNamed(AppRoutes.login);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Validate login form
  bool _validateLoginForm() {
    bool isValid = true;
    _clearFormErrors();

    // Email validation
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _emailError.value = 'El email es requerido';
      isValid = false;
    } else if (!GetUtils.isEmail(email)) {
      _emailError.value = 'El formato del email es inválido';
      isValid = false;
    }

    // Password validation
    final password = passwordController.text;
    if (password.isEmpty) {
      _passwordError.value = 'La contraseña es requerida';
      isValid = false;
    } else if (password.length < 6) {
      _passwordError.value = 'La contraseña debe tener al menos 6 caracteres';
      isValid = false;
    }

    return isValid;
  }

  /// Clear form validation errors
  void _clearFormErrors() {
    _emailError.value = null;
    _passwordError.value = null;
  }

  /// Clear login form
  void _clearLoginForm() {
    emailController.clear();
    passwordController.clear();
    _clearFormErrors();
  }

  /// Handle login failure
  void _handleLoginFailure(Failure failure) {
    if (failure is ValidationFailure) {
      _errorMessage.value = failure.message;
    } else if (failure is AuthFailure) {
      _errorMessage.value = failure.message;
    } else if (failure is NetworkFailure) {
      _errorMessage.value = failure.message;
    } else if (failure is ServerFailure) {
      _errorMessage.value = failure.message;
    } else {
      _errorMessage.value = 'Error de conexión. Por favor intenta nuevamente.';
    }
  }

  /// Clear user data
  void _clearUserData() {
    _user.value = null;
    _isAuthenticated.value = false;
    _errorMessage.value = null;
    _clearLoginForm();
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = null;
  }

  /// Clear field errors
  void clearFieldError(String field) {
    switch (field) {
      case 'email':
        _emailError.value = null;
        break;
      case 'password':
        _passwordError.value = null;
        break;
    }
  }

  /// Check if user has admin role
  bool get isAdmin => user?.role.isAdmin ?? false;

  /// Check if user has supervisor role
  bool get isSupervisor => user?.role.isSupervisor ?? false;

  /// Check if user has employee role
  bool get isEmployee => user?.role.isEmployee ?? false;

  /// Get user display name
  String get userDisplayName => user?.username ?? 'Usuario';

  /// Get user role display name
  String get userRoleDisplayName => user?.role.displayName ?? '';

  /// Refresh authentication token
  Future<void> refreshToken() async {
    final result = await authRepository.refreshToken();
    result.fold(
      (failure) {
        // If refresh fails, logout user
        logout();
      },
      (_) {
        // Token refreshed successfully
      },
    );
  }
}