// lib/features/expenses/presentation/controllers/expenses_controller.dart

import 'package:get/get.dart';

import '../../domain/entities/expense.dart';
import '../../domain/usecases/expenses_usecases.dart';

/// ExpensesController using GetX for reactive state management
/// Handles expenses list and CRUD operations
class ExpensesController extends GetxController {
  final GetExpensesUseCase getExpensesUseCase;
  final GetExpenseByIdUseCase getExpenseByIdUseCase;
  final CreateExpenseUseCase createExpenseUseCase;
  final UpdateExpenseUseCase updateExpenseUseCase;
  final DeleteExpenseUseCase deleteExpenseUseCase;

  ExpensesController({
    required this.getExpensesUseCase,
    required this.getExpenseByIdUseCase,
    required this.createExpenseUseCase,
    required this.updateExpenseUseCase,
    required this.deleteExpenseUseCase,
  });

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;
  final RxList<Expense> expenses = <Expense>[].obs;
  final RxString errorMessage = ''.obs;
  final Rx<Expense?> selectedExpense = Rx<Expense?>(null);

  @override
  void onInit() {
    super.onInit();
    loadExpenses();
  }

  /// Load all expenses
  Future<void> loadExpenses({bool refresh = false}) async {
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
      final result = await getExpensesUseCase.call();

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
        (loadedExpenses) {
          expenses.value = loadedExpenses;
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

  /// Get expense by ID
  Future<void> getExpenseById(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final params = GetExpenseByIdParams(id: id);
      final result = await getExpenseByIdUseCase.call(params);

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
        (expense) {
          selectedExpense.value = expense;
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

  /// Create a new expense
  Future<bool> createExpense({
    required String description,
    required double amount,
  }) async {
    try {
      isCreating.value = true;
      errorMessage.value = '';

      final params = CreateExpenseParams(
        description: description,
        amount: amount,
      );

      final result = await createExpenseUseCase.call(params);

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
        (expense) {
          // Refresh list
          loadExpenses(refresh: true);
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

  /// Update an existing expense
  Future<bool> updateExpense({
    required String id,
    String? description,
    double? amount,
  }) async {
    try {
      isUpdating.value = true;
      errorMessage.value = '';

      final params = UpdateExpenseParams(
        id: id,
        description: description,
        amount: amount,
      );

      final result = await updateExpenseUseCase.call(params);

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
        (expense) {
          // Update selected expense if it's the same
          if (selectedExpense.value?.id == expense.id) {
            selectedExpense.value = expense;
          }
          // Refresh list
          loadExpenses(refresh: true);
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

  /// Delete an expense
  Future<bool> deleteExpense(String id) async {
    try {
      isDeleting.value = true;
      errorMessage.value = '';

      final params = DeleteExpenseParams(id: id);
      final result = await deleteExpenseUseCase.call(params);

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
          // Clear selected expense if it's the deleted one
          if (selectedExpense.value?.id == id) {
            selectedExpense.value = null;
          }
          // Refresh list
          loadExpenses(refresh: true);
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

  /// Refresh expenses list
  Future<void> refreshExpenses() async {
    await loadExpenses(refresh: true);
  }

  /// Clear selected expense data
  void clearSelectedExpense() {
    selectedExpense.value = null;
  }

  /// Get total expenses amount
  double get totalExpensesAmount {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Get expenses count
  int get expensesCount {
    return expenses.length;
  }

  /// Get expenses for today
  List<Expense> get todayExpenses {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return expenses.where((expense) {
      final expenseDate = DateTime(
        expense.createdAt.year,
        expense.createdAt.month,
        expense.createdAt.day,
      );
      return expenseDate == today;
    }).toList();
  }

  /// Get total amount for today
  double get todayTotalAmount {
    return todayExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Get expenses for this week
  List<Expense> get weekExpenses {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return expenses.where((expense) {
      final expenseDate = DateTime(
        expense.createdAt.year,
        expense.createdAt.month,
        expense.createdAt.day,
      );
      return expenseDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          expenseDate.isBefore(now.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get total amount for this week
  double get weekTotalAmount {
    return weekExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Get expenses for this month
  List<Expense> get monthExpenses {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return expenses.where((expense) {
      final expenseDate = DateTime(
        expense.createdAt.year,
        expense.createdAt.month,
        expense.createdAt.day,
      );
      return expenseDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          expenseDate.isBefore(now.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get total amount for this month
  double get monthTotalAmount {
    return monthExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }
}
