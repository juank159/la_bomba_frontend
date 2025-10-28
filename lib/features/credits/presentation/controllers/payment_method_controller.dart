// lib/features/credits/presentation/controllers/payment_method_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/payment_method_repository.dart';

class PaymentMethodController extends GetxController {
  final PaymentMethodRepository _repository = getIt<PaymentMethodRepository>();

  // Estado
  final RxList<PaymentMethod> paymentMethods = <PaymentMethod>[].obs;
  final RxList<PaymentMethod> activePaymentMethods = <PaymentMethod>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<PaymentMethod?> selectedPaymentMethod = Rx<PaymentMethod?>(null);

  @override
  void onInit() {
    super.onInit();
    loadAllPaymentMethods();
  }

  /// Carga todos los métodos de pago
  Future<void> loadAllPaymentMethods() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _repository.getAllPaymentMethods();

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          print('❌ Error al cargar métodos de pago: ${failure.message}');
        },
        (loadedMethods) {
          paymentMethods.value = loadedMethods;
          activePaymentMethods.value =
              loadedMethods.where((m) => m.isActive).toList();
          print('✅ Métodos de pago cargados: ${loadedMethods.length}');
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      print('❌ Error inesperado: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtiene un método de pago por ID
  Future<PaymentMethod?> getPaymentMethodById(String id) async {
    try {
      final result = await _repository.getPaymentMethodById(id);

      return result.fold(
        (failure) {
          print('❌ Error al cargar método de pago: ${failure.message}');
          return null;
        },
        (method) {
          print('✅ Método de pago cargado: ${method.name}');
          return method;
        },
      );
    } catch (e) {
      print('❌ Error inesperado: $e');
      return null;
    }
  }

  /// Crea un nuevo método de pago
  Future<bool> createPaymentMethod({
    required String name,
    String? description,
    String? icon,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('➕ Creando método de pago: $name');

      final result = await _repository.createPaymentMethod(
        name: name,
        description: description,
        icon: icon,
      );

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          print('❌ Error al crear método de pago: ${failure.message}');
          _showErrorSnackbar('Error al crear método de pago', failure.message);
          return false;
        },
        (newMethod) {
          print('✅ Método de pago creado: ${newMethod.name}');
          _showSuccessSnackbar(
            '✅ Método Creado',
            'El método de pago "${newMethod.name}" ha sido creado exitosamente',
          );
          // Recargar métodos de pago
          loadAllPaymentMethods();
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

  /// Actualiza un método de pago existente
  Future<bool> updatePaymentMethod({
    required String id,
    String? name,
    String? description,
    String? icon,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('✏️ Actualizando método de pago: $id');

      final result = await _repository.updatePaymentMethod(
        id: id,
        name: name,
        description: description,
        icon: icon,
      );

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          print('❌ Error al actualizar método de pago: ${failure.message}');
          _showErrorSnackbar(
              'Error al actualizar método de pago', failure.message);
          return false;
        },
        (updatedMethod) {
          print('✅ Método de pago actualizado: ${updatedMethod.name}');
          _showSuccessSnackbar(
            '✅ Método Actualizado',
            'El método de pago "${updatedMethod.name}" ha sido actualizado',
          );
          // Recargar métodos de pago
          loadAllPaymentMethods();
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

  /// Elimina un método de pago
  Future<bool> deletePaymentMethod(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🗑️ Eliminando método de pago: $id');

      final result = await _repository.deletePaymentMethod(id);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          print('❌ Error al eliminar método de pago: ${failure.message}');
          _showErrorSnackbar('Error al eliminar método de pago', failure.message);
          return false;
        },
        (_) {
          print('✅ Método de pago eliminado');
          _showSuccessSnackbar(
            '✅ Método Eliminado',
            'El método de pago ha sido eliminado exitosamente',
          );
          // Recargar métodos de pago
          loadAllPaymentMethods();
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

  /// Activa o desactiva un método de pago
  Future<bool> togglePaymentMethodStatus(String id, bool isActive) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔄 Cambiando estado del método de pago: $id a ${isActive ? "activo" : "inactivo"}');

      final result = await _repository.activatePaymentMethod(
        id: id,
        isActive: isActive,
      );

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          print('❌ Error al cambiar estado del método de pago: ${failure.message}');
          _showErrorSnackbar(
              'Error al cambiar estado', failure.message);
          return false;
        },
        (updatedMethod) {
          print('✅ Estado del método de pago actualizado: ${updatedMethod.name}');
          _showSuccessSnackbar(
            '✅ Estado Actualizado',
            'El método de pago "${updatedMethod.name}" ahora está ${isActive ? "activo" : "inactivo"}',
          );
          // Recargar métodos de pago
          loadAllPaymentMethods();
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

  /// Selecciona un método de pago para ver detalles
  void selectPaymentMethod(PaymentMethod? method) {
    selectedPaymentMethod.value = method;
  }

  /// Obtiene solo los métodos de pago activos
  List<PaymentMethod> getActivePaymentMethods() {
    return paymentMethods.where((m) => m.isActive).toList();
  }
}
