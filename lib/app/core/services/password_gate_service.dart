import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../network/dio_client.dart';
import '../di/service_locator.dart';

/// Service to protect sensitive data with admin password verification.
/// Caches verification for the current session to avoid repeated prompts.
class PasswordGateService {
  static final PasswordGateService _instance = PasswordGateService._();
  factory PasswordGateService() => _instance;
  PasswordGateService._();

  // Session-level cache - verified screens persist until app restart
  final Set<String> _verifiedGates = {};

  bool isVerified(String gateId) => _verifiedGates.contains(gateId);

  void clearAll() => _verifiedGates.clear();

  /// Show password dialog and verify against backend.
  /// Returns true if password is correct, false if cancelled or wrong.
  Future<bool> requestAccess({
    required String gateId,
    String title = 'Verificacion Requerida',
    String message = 'Ingresa tu contraseña para continuar',
  }) async {
    // Already verified this session
    if (_verifiedGates.contains(gateId)) return true;

    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isLoading = false.obs;
    final errorMsg = ''.obs;
    final obscure = true.obs;

    final result = await Get.dialog<bool>(
      PopScope(
        canPop: true,
        child: Obx(() => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() => TextFormField(
                  controller: passwordController,
                  obscureText: obscure.value,
                  enabled: !isLoading.value,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.key),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(obscure.value ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => obscure.value = !obscure.value,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa tu contraseña';
                    return null;
                  },
                  onFieldSubmitted: (_) async {
                    if (formKey.currentState!.validate()) {
                      await _verify(passwordController.text.trim(), gateId, isLoading, errorMsg);
                    }
                  },
                )),
                if (errorMsg.value.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMsg.value,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading.value ? null : () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: isLoading.value
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        await _verify(passwordController.text.trim(), gateId, isLoading, errorMsg);
                      }
                    },
              icon: isLoading.value
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 18),
              label: Text(isLoading.value ? 'Verificando...' : 'Confirmar'),
            ),
          ],
        )),
      ),
      barrierDismissible: false,
    );

    passwordController.dispose();
    return result ?? false;
  }

  Future<void> _verify(String password, String gateId, RxBool isLoading, RxString errorMsg) async {
    isLoading.value = true;
    errorMsg.value = '';

    try {
      final dioClient = getIt<DioClient>();
      final response = await dioClient.post(
        '/auth/verify-password',
        data: {'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _verifiedGates.add(gateId);
        Get.back(result: true);
      } else {
        errorMsg.value = 'Contraseña incorrecta';
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('401') || msg.contains('Unauthorized') || msg.contains('incorrecta')) {
        errorMsg.value = 'Contraseña incorrecta';
      } else {
        errorMsg.value = 'Error de conexion. Intenta de nuevo.';
      }
    } finally {
      isLoading.value = false;
    }
  }
}
