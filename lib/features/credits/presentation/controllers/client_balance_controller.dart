// lib/features/credits/presentation/controllers/client_balance_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../domain/entities/client_balance.dart';
import '../../domain/entities/client_balance_transaction.dart';
import '../../domain/repositories/client_balance_repository.dart';

class ClientBalanceController extends GetxController {
  final ClientBalanceRepository _repository = getIt<ClientBalanceRepository>();

  // Estado
  final RxList<ClientBalance> balances = <ClientBalance>[].obs;
  final RxList<ClientBalanceTransaction> transactions = <ClientBalanceTransaction>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingTransactions = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<ClientBalance?> selectedBalance = Rx<ClientBalance?>(null);

  @override
  void onInit() {
    super.onInit();
    loadAllBalances();
  }

  /// Carga todos los saldos de clientes
  Future<void> loadAllBalances() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _repository.getAllClientBalances();

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          print('❌ Error al cargar saldos: ${failure.message}');
        },
        (loadedBalances) {
          balances.value = loadedBalances;
          print('✅ Saldos cargados: ${loadedBalances.length}');
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      print('❌ Error inesperado: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Carga el saldo de un cliente específico
  Future<ClientBalance?> getClientBalance(String clientId) async {
    try {
      final result = await _repository.getClientBalance(clientId);

      return result.fold(
        (failure) {
          print('❌ Error al cargar saldo del cliente: ${failure.message}');
          return null;
        },
        (balance) {
          print('✅ Saldo del cliente cargado: ${balance?.formattedBalance ?? "sin saldo"}');
          return balance;
        },
      );
    } catch (e) {
      print('❌ Error inesperado: $e');
      return null;
    }
  }

  /// Carga las transacciones de un cliente
  Future<void> loadClientTransactions(String clientId) async {
    try {
      isLoadingTransactions.value = true;

      final result = await _repository.getClientTransactions(clientId);

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          print('❌ Error al cargar transacciones: ${failure.message}');
        },
        (loadedTransactions) {
          transactions.value = loadedTransactions;
          print('✅ Transacciones cargadas: ${loadedTransactions.length}');
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      print('❌ Error inesperado: $e');
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  /// Usa saldo del cliente para pagar
  Future<bool> useBalance({
    required String clientId,
    required double amount,
    required String description,
    String? relatedCreditId,
    String? relatedOrderId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('💰 Usando saldo: $amount para cliente $clientId');

      final result = await _repository.useBalance(
        clientId: clientId,
        amount: amount,
        description: description,
        relatedCreditId: relatedCreditId,
        relatedOrderId: relatedOrderId,
      );

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          print('❌ Error al usar saldo: ${failure.message}');
          _showErrorSnackbar('Error al usar saldo', failure.message);
          return false;
        },
        (updatedBalance) {
          print('✅ Saldo usado correctamente. Nuevo saldo: ${updatedBalance.formattedBalance}');
          _showSuccessSnackbar(
            'Saldo usado',
            'Se usaron \$${amount.toStringAsFixed(2)} del saldo',
          );
          // Recargar saldos
          loadAllBalances();
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      print('❌ Error inesperado: $e');
      _showErrorSnackbar('Error', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Devuelve saldo al cliente
  Future<bool> refundBalance({
    required String clientId,
    required double amount,
    required String description,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('💸 Devolviendo saldo: $amount a cliente $clientId');

      final result = await _repository.refundBalance(
        clientId: clientId,
        amount: amount,
        description: description,
      );

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          print('❌ Error al devolver saldo: ${failure.message}');
          _showErrorSnackbar('Error al devolver saldo', failure.message);
          return false;
        },
        (updatedBalance) {
          print('✅ Saldo devuelto correctamente. Nuevo saldo: ${updatedBalance.formattedBalance}');
          _showSuccessSnackbar(
            'Saldo devuelto',
            'Se devolvieron \$${amount.toStringAsFixed(2)} al cliente',
          );
          // Recargar saldos
          loadAllBalances();
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      print('❌ Error inesperado: $e');
      _showErrorSnackbar('Error', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Ajusta saldo manualmente (corrección)
  Future<bool> adjustBalance({
    required String clientId,
    required double amount,
    required String description,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('⚙️ Ajustando saldo: $amount para cliente $clientId');

      final result = await _repository.adjustBalance(
        clientId: clientId,
        amount: amount,
        description: description,
      );

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          print('❌ Error al ajustar saldo: ${failure.message}');
          _showErrorSnackbar('Error al ajustar saldo', failure.message);
          return false;
        },
        (updatedBalance) {
          print('✅ Saldo ajustado correctamente. Nuevo saldo: ${updatedBalance.formattedBalance}');
          _showSuccessSnackbar(
            'Saldo ajustado',
            'Ajuste de \$${amount.toStringAsFixed(2)} aplicado',
          );
          // Recargar saldos
          loadAllBalances();
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      print('❌ Error inesperado: $e');
      _showErrorSnackbar('Error', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Muestra snackbar de éxito
  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  /// Muestra snackbar de error
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  /// Limpia el mensaje de error
  void clearError() {
    errorMessage.value = '';
  }

  /// Selecciona un saldo para ver detalles
  void selectBalance(ClientBalance? balance) {
    selectedBalance.value = balance;
    if (balance != null) {
      loadClientTransactions(balance.clientId);
    } else {
      transactions.clear();
    }
  }
}
