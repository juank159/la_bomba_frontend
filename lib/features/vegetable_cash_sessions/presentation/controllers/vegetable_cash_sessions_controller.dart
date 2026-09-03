// lib/features/vegetable_cash_sessions/presentation/controllers/vegetable_cash_sessions_controller.dart

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../domain/entities/vegetable_cash_session.dart';
import '../../domain/usecases/vegetable_cash_sessions_usecases.dart';

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

class VegetableCashSessionsController extends GetxController {
  final OpenCashSessionUseCase openCashSessionUseCase;
  final CloseCashSessionUseCase closeCashSessionUseCase;
  final GetCurrentCashSessionUseCase getCurrentCashSessionUseCase;
  final GetCashSessionsHistoryUseCase getCashSessionsHistoryUseCase;
  final GetCashSessionByIdUseCase getCashSessionByIdUseCase;

  VegetableCashSessionsController({
    required this.openCashSessionUseCase,
    required this.closeCashSessionUseCase,
    required this.getCurrentCashSessionUseCase,
    required this.getCashSessionsHistoryUseCase,
    required this.getCashSessionByIdUseCase,
  });

  final Rx<VegetableCashSessionSummary?> current = Rx<VegetableCashSessionSummary?>(null);
  final RxBool isLoadingCurrent = false.obs;
  final RxBool isOpeningOrClosing = false.obs;

  final RxList<VegetableCashSession> history = <VegetableCashSession>[].obs;
  final RxBool isLoadingHistory = false.obs;

  final Rx<VegetableCashSession?> selectedSession = Rx<VegetableCashSession?>(null);
  final RxBool isLoadingSessionDetail = false.obs;

  bool get hasOpenSession => current.value?.isOpen ?? false;

  Future<void> loadCurrent() async {
    try {
      isLoadingCurrent.value = true;
      final result = await getCurrentCashSessionUseCase();
      result.fold(
        (failure) => safeSnackbar('Error', 'Error al consultar la caja: ${failure.message}', snackPosition: SnackPosition.TOP),
        (summary) => current.value = summary,
      );
    } finally {
      isLoadingCurrent.value = false;
    }
  }

  Future<bool> openSession({required double openingAmount, String? notes}) async {
    try {
      isOpeningOrClosing.value = true;
      final result = await openCashSessionUseCase(openingAmount: openingAmount, notes: notes);
      return result.fold(
        (failure) {
          safeSnackbar('No se pudo abrir la caja', failure.message, snackPosition: SnackPosition.TOP);
          return false;
        },
        (session) {
          safeSnackbar('Caja abierta', 'Turno abierto con fondo de \$${openingAmount.toStringAsFixed(0)}', snackPosition: SnackPosition.TOP);
          loadCurrent();
          return true;
        },
      );
    } finally {
      isOpeningOrClosing.value = false;
    }
  }

  Future<bool> closeSession({required double closingAmount, String? notes}) async {
    try {
      isOpeningOrClosing.value = true;
      final result = await closeCashSessionUseCase(closingAmount: closingAmount, notes: notes);
      return result.fold(
        (failure) {
          safeSnackbar('No se pudo cerrar la caja', failure.message, snackPosition: SnackPosition.TOP);
          return false;
        },
        (session) {
          safeSnackbar('Caja cerrada', 'Turno cerrado correctamente', snackPosition: SnackPosition.TOP);
          loadCurrent();
          return true;
        },
      );
    } finally {
      isOpeningOrClosing.value = false;
    }
  }

  Future<void> loadHistory() async {
    try {
      isLoadingHistory.value = true;
      final result = await getCashSessionsHistoryUseCase();
      result.fold(
        (failure) => safeSnackbar('Error', 'Error al cargar el historial: ${failure.message}', snackPosition: SnackPosition.TOP),
        (loaded) => history.assignAll(loaded),
      );
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> loadSessionById(String id) async {
    try {
      isLoadingSessionDetail.value = true;
      selectedSession.value = null;
      final result = await getCashSessionByIdUseCase(id);
      result.fold(
        (failure) => safeSnackbar('Error', 'Error al cargar el turno: ${failure.message}', snackPosition: SnackPosition.TOP),
        (session) => selectedSession.value = session,
      );
    } finally {
      isLoadingSessionDetail.value = false;
    }
  }
}
