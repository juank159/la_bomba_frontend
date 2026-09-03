// lib/features/vegetable_expenses/presentation/controllers/vegetable_expenses_controller.dart

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/vegetable_expense.dart';
import '../../domain/usecases/vegetable_expenses_usecases.dart';

/// Wraps Get.snackbar() so a missing Overlay can't crash the calling code -
/// same defensive pattern used across the app (see e.g.
/// invoices_controller.dart's safeSnackbar for the full incident writeup).
void safeSnackbar(
  String title,
  String message, {
  SnackPosition? snackPosition,
  Color? backgroundColor,
  Color? colorText,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.delayed(const Duration(milliseconds: 350));
    try {
      Get.snackbar(title, message, snackPosition: snackPosition, backgroundColor: backgroundColor, colorText: colorText);
    } catch (_) {
      // No Overlay available right now - not worth crashing over a toast.
    }
  });
}

/// Controller for the vegetables stand's own operating expenses -
/// deliberately separate from the app's general ExpensesController.
class VegetableExpensesController extends GetxController {
  final GetVegetableExpensesUseCase getExpensesUseCase;
  final CreateVegetableExpenseUseCase createExpenseUseCase;
  final UpdateVegetableExpenseUseCase updateExpenseUseCase;
  final DeleteVegetableExpenseUseCase deleteExpenseUseCase;

  VegetableExpensesController({
    required this.getExpensesUseCase,
    required this.createExpenseUseCase,
    required this.updateExpenseUseCase,
    required this.deleteExpenseUseCase,
  });

  final RxList<VegetableExpense> expenses = <VegetableExpense>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isDeleting = false.obs;

  double get totalAmount => expenses.fold(0.0, (sum, e) => sum + e.amount);

  // Filtro por fecha - mismo patrón que Corresponsal/Ventas/Compras.
  final Rx<DateTime?> filterStart = Rx<DateTime?>(null);
  final Rx<DateTime?> filterEnd = Rx<DateTime?>(null);
  final RxString filterLabel = 'Hoy'.obs;

  List<VegetableExpense> get filteredExpenses {
    final start = filterStart.value;
    final end = filterEnd.value;
    if (start == null || end == null) {
      final now = DateTime.now();
      return expenses.where((e) {
        final d = e.createdAt.toLocal();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();
    }
    return expenses.where((e) {
      final d = e.createdAt.toLocal();
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  double get filteredTotal => filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

  void applyFilter(DateTime start, DateTime end, String label) {
    filterStart.value = start;
    filterEnd.value = end;
    filterLabel.value = label;
  }

  void clearFilter() {
    filterStart.value = null;
    filterEnd.value = null;
    filterLabel.value = 'Hoy';
  }

  Future<void> loadExpenses() async {
    try {
      isLoading.value = true;
      final result = await getExpensesUseCase(NoParams());
      result.fold(
        (failure) => safeSnackbar('Error', 'Error al cargar los gastos: ${failure.message}', snackPosition: SnackPosition.TOP),
        (loaded) => expenses.assignAll(loaded),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createExpense({
    required String description,
    required double amount,
    required ExpenseFundingSource fundingSource,
  }) async {
    try {
      isSaving.value = true;
      final result = await createExpenseUseCase(
        CreateVegetableExpenseParams(description: description, amount: amount, fundingSource: fundingSource),
      );
      return result.fold(
        (failure) {
          safeSnackbar('Error al guardar', failure.message, snackPosition: SnackPosition.TOP);
          return false;
        },
        (expense) {
          expenses.insert(0, expense);
          return true;
        },
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateExpense({required String id, required String description, required double amount}) async {
    try {
      isSaving.value = true;
      final result = await updateExpenseUseCase(
        UpdateVegetableExpenseParams(id: id, description: description, amount: amount),
      );
      return result.fold(
        (failure) {
          safeSnackbar('Error al guardar', failure.message, snackPosition: SnackPosition.TOP);
          return false;
        },
        (updated) {
          final index = expenses.indexWhere((e) => e.id == id);
          if (index >= 0) expenses[index] = updated;
          return true;
        },
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      isDeleting.value = true;
      final result = await deleteExpenseUseCase(DeleteVegetableExpenseParams(id: id));
      return result.fold(
        (failure) {
          safeSnackbar('Error al eliminar', failure.message, snackPosition: SnackPosition.TOP);
          return false;
        },
        (_) {
          expenses.removeWhere((e) => e.id == id);
          return true;
        },
      );
    } finally {
      isDeleting.value = false;
    }
  }
}
