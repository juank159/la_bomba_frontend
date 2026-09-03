// lib/features/corresponsal/presentation/controllers/corresponsal_controller.dart

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/corresponsal_entry.dart';
import '../../domain/usecases/corresponsal_usecases.dart';

/// Wraps Get.snackbar() so a missing Overlay can't crash the calling code -
/// same defensive pattern used across the app.
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

class CorresponsalController extends GetxController {
  final GetCorresponsalEntriesUseCase getEntriesUseCase;
  final CreateCorresponsalEntryUseCase createEntryUseCase;
  final DeleteCorresponsalEntryUseCase deleteEntryUseCase;

  CorresponsalController({
    required this.getEntriesUseCase,
    required this.createEntryUseCase,
    required this.deleteEntryUseCase,
  });

  final RxList<CorresponsalEntry> entries = <CorresponsalEntry>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  // Filtro por fecha - por defecto, solo "hoy". Igual al que se usa en
  // Gastos (CustomDateRangePicker): null = sin rango elegido = hoy.
  final Rx<DateTime?> filterStart = Rx<DateTime?>(null);
  final Rx<DateTime?> filterEnd = Rx<DateTime?>(null);
  final RxString filterLabel = 'Hoy'.obs;

  List<CorresponsalEntry> get filteredEntries {
    final start = filterStart.value;
    final end = filterEnd.value;

    if (start == null || end == null) {
      final now = DateTime.now();
      return entries.where((e) {
        final d = e.createdAt.toLocal();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();
    }

    return entries.where((e) {
      final d = e.createdAt.toLocal();
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  double get filteredTotal => filteredEntries.fold(0.0, (sum, e) => sum + e.amount);

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

  Future<void> loadEntries() async {
    try {
      isLoading.value = true;
      final result = await getEntriesUseCase(NoParams());
      result.fold(
        (failure) => safeSnackbar('Error', 'Error al cargar los registros: ${failure.message}', snackPosition: SnackPosition.TOP),
        (loaded) => entries.assignAll(loaded),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createEntry({required double amount, String? note}) async {
    try {
      isSaving.value = true;
      final result = await createEntryUseCase(CreateCorresponsalEntryParams(amount: amount, note: note));
      return result.fold(
        (failure) {
          safeSnackbar('Error al guardar', failure.message, snackPosition: SnackPosition.TOP);
          return false;
        },
        (entry) {
          entries.insert(0, entry);
          return true;
        },
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    final result = await deleteEntryUseCase(DeleteCorresponsalEntryParams(id: id));
    return result.fold(
      (failure) {
        safeSnackbar('Error al eliminar', failure.message, snackPosition: SnackPosition.TOP);
        return false;
      },
      (_) {
        entries.removeWhere((e) => e.id == id);
        return true;
      },
    );
  }
}
