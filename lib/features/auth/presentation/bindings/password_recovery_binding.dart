import 'package:get/get.dart';

import '../../../../app/core/di/service_locator.dart';
import '../controllers/password_recovery_controller.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import '../../domain/usecases/verify_reset_code_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';

/// GetX binding for Password Recovery feature
class PasswordRecoveryBinding extends Bindings {
  @override
  void dependencies() {
    // Register PasswordRecoveryController with all its dependencies
    Get.lazyPut<PasswordRecoveryController>(
      () => PasswordRecoveryController(
        requestPasswordResetUseCase: getIt<RequestPasswordResetUseCase>(),
        verifyResetCodeUseCase: getIt<VerifyResetCodeUseCase>(),
        resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
      ),
    );
  }
}
