// lib/features/credits/presentation/controllers/credits_controller.dart

import 'package:get/get.dart';

import '../../domain/entities/credit.dart';
import '../../domain/usecases/credits_usecases.dart';

/// CreditsController using GetX for reactive state management
/// Handles credits list, CRUD operations, and payment management
class CreditsController extends GetxController {
  final GetCreditsUseCase getCreditsUseCase;
  final GetCreditByIdUseCase getCreditByIdUseCase;
  final CreateCreditUseCase createCreditUseCase;
  final UpdateCreditUseCase updateCreditUseCase;
  final AddPaymentUseCase addPaymentUseCase;
  final RemovePaymentUseCase removePaymentUseCase;
  final DeleteCreditUseCase deleteCreditUseCase;
  final GetPendingCreditByClientUseCase getPendingCreditByClientUseCase;
  final AddAmountToCreditUseCase addAmountToCreditUseCase;

  CreditsController({
    required this.getCreditsUseCase,
    required this.getCreditByIdUseCase,
    required this.createCreditUseCase,
    required this.updateCreditUseCase,
    required this.addPaymentUseCase,
    required this.removePaymentUseCase,
    required this.deleteCreditUseCase,
    required this.getPendingCreditByClientUseCase,
    required this.addAmountToCreditUseCase,
  });

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;
  final RxBool isAddingPayment = false.obs;
  final RxBool isRemovingPayment = false.obs;
  final RxList<Credit> credits = <Credit>[].obs;
  final RxString errorMessage = ''.obs;
  final Rx<Credit?> selectedCredit = Rx<Credit?>(null);
  final RxString filterStatus = 'pending'.obs; // all, pending, paid - Inicia en 'pending' por defecto

  @override
  void onInit() {
    super.onInit();
    loadCredits();
  }

  /// Load all credits
  Future<void> loadCredits({bool refresh = false}) async {
    try {
      // Set loading states
      if (refresh) {
        isRefreshing.value = true;
      } else {
        if (isLoading.value) return;
        isLoading.value = true;
      }

      // Clear error message
      errorMessage.value = '';

      // Execute use case
      final result = await getCreditsUseCase.call();

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
        },
        (loadedCredits) {
          credits.value = loadedCredits;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Get credit by ID
  Future<void> getCreditById(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final params = GetCreditByIdParams(id: id);
      final result = await getCreditByIdUseCase.call(params);

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
        },
        (credit) {
          selectedCredit.value = credit;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new credit
  Future<bool> createCredit({
    required String clientId,
    required String description,
    required double totalAmount,
  }) async {
    try {
      isCreating.value = true;
      errorMessage.value = '';

      final params = CreateCreditParams(
        clientId: clientId,
        description: description,
        totalAmount: totalAmount,
      );

      final result = await createCreditUseCase.call(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
          return false;
        },
        (credit) {
          // Refresh list
          loadCredits(refresh: true);
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  /// Update an existing credit
  Future<bool> updateCredit({
    required String id,
    String? clientId,
    String? description,
    double? totalAmount,
  }) async {
    try {
      isUpdating.value = true;
      errorMessage.value = '';

      final params = UpdateCreditParams(
        id: id,
        clientId: clientId,
        description: description,
        totalAmount: totalAmount,
      );

      final result = await updateCreditUseCase.call(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
          return false;
        },
        (credit) {
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Éxito',
              'Crédito actualizado exitosamente',
              snackPosition: SnackPosition.TOP,
            );
          }
          // Update selected credit if it's the same
          if (selectedCredit.value?.id == credit.id) {
            selectedCredit.value = credit;
          }
          // Refresh list
          loadCredits(refresh: true);
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Add a payment to a credit
  Future<bool> addPayment({
    required String creditId,
    required double amount,
    String? description,
  }) async {
    try {
      isAddingPayment.value = true;
      errorMessage.value = '';

      final params = AddPaymentParams(
        creditId: creditId,
        amount: amount,
        description: description,
      );

      final result = await addPaymentUseCase.call(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
          return false;
        },
        (credit) {
          // Update selected credit
          selectedCredit.value = credit;
          // Refresh list
          loadCredits(refresh: true);
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
      return false;
    } finally {
      isAddingPayment.value = false;
    }
  }

  /// Remove a payment from a credit
  Future<bool> removePayment({
    required String creditId,
    required String paymentId,
  }) async {
    try {
      isRemovingPayment.value = true;
      errorMessage.value = '';

      final params = RemovePaymentParams(
        creditId: creditId,
        paymentId: paymentId,
      );

      final result = await removePaymentUseCase.call(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
          return false;
        },
        (credit) {
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Éxito',
              'Pago eliminado exitosamente',
              snackPosition: SnackPosition.TOP,
            );
          }
          // Update selected credit
          selectedCredit.value = credit;
          // Refresh list
          loadCredits(refresh: true);
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
      return false;
    } finally {
      isRemovingPayment.value = false;
    }
  }

  /// Delete a credit
  Future<bool> deleteCredit(String id) async {
    try {
      isDeleting.value = true;
      errorMessage.value = '';

      final params = DeleteCreditParams(id: id);
      final result = await deleteCreditUseCase.call(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
          return false;
        },
        (_) {
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Éxito',
              'Crédito eliminado exitosamente',
              snackPosition: SnackPosition.TOP,
            );
          }
          // Clear selected credit if it's the deleted one
          if (selectedCredit.value?.id == id) {
            selectedCredit.value = null;
          }
          // Refresh list
          loadCredits(refresh: true);
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  /// Refresh credits list
  Future<void> refreshCredits() async {
    await loadCredits(refresh: true);
  }

  /// Clear selected credit data
  void clearSelectedCredit() {
    selectedCredit.value = null;
  }

  /// Filter credits by status
  List<Credit> get filteredCredits {
    if (filterStatus.value == 'all') {
      return credits;
    } else if (filterStatus.value == 'pending') {
      return credits.where((credit) => credit.isPending).toList();
    } else if (filterStatus.value == 'paid') {
      return credits.where((credit) => credit.isPaid).toList();
    }
    return credits;
  }

  /// Set filter status
  void setFilterStatus(String status) {
    filterStatus.value = status;
  }

  /// Get total pending amount across all credits
  double get totalPendingAmount {
    return credits
        .where((credit) => credit.isPending)
        .fold(0.0, (sum, credit) => sum + credit.remainingAmount);
  }

  /// Get total paid amount across all credits
  double get totalPaidAmount {
    return credits.fold(0.0, (sum, credit) => sum + credit.paidAmount);
  }

  /// Get pending credits count
  int get pendingCreditsCount {
    return credits.where((credit) => credit.isPending).length;
  }

  /// Get paid credits count
  int get paidCreditsCount {
    return credits.where((credit) => credit.isPaid).length;
  }

  /// Get pending credit for a client
  Future<Credit?> getPendingCreditByClient(String clientId) async {
    try {
      final params = GetPendingCreditByClientParams(clientId: clientId);
      final result = await getPendingCreditByClientUseCase.call(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          return null;
        },
        (credit) => credit,
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      return null;
    }
  }

  /// Add amount to an existing credit
  Future<bool> addAmountToCredit({
    required String creditId,
    required double amount,
    required String description,
  }) async {
    try {
      isCreating.value = true;
      errorMessage.value = '';

      final params = AddAmountToCreditParams(
        creditId: creditId,
        amount: amount,
        description: description,
      );

      final result = await addAmountToCreditUseCase.call(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
          return false;
        },
        (credit) {
          // Update selected credit if it's the same
          if (selectedCredit.value?.id == credit.id) {
            selectedCredit.value = credit;
          }
          // Refresh list
          loadCredits(refresh: true);
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
      return false;
    } finally {
      isCreating.value = false;
    }
  }
}
