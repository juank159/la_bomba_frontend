import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../network/dio_client.dart';
import '../di/service_locator.dart';

/// Service to protect sensitive data with admin password verification.
class PasswordGateService {
  static final PasswordGateService _instance = PasswordGateService._();
  factory PasswordGateService() => _instance;
  PasswordGateService._();

  final Set<String> _verifiedGates = {};

  bool isVerified(String gateId) => _verifiedGates.contains(gateId);
  void clearAll() => _verifiedGates.clear();
  void markVerified(String gateId) => _verifiedGates.add(gateId);

  Future<bool> requestAccess({
    required String gateId,
    String title = 'Verificacion Requerida',
    String message = 'Ingresa tu contraseña para continuar',
  }) async {
    if (_verifiedGates.contains(gateId)) return true;

    final result = await Get.dialog<bool>(
      _PasswordDialog(
        title: title,
        message: message,
        onVerified: () => _verifiedGates.add(gateId),
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }
}

class _PasswordDialog extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onVerified;

  const _PasswordDialog({
    required this.title,
    required this.message,
    required this.onVerified,
  });

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMsg = '';
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final dioClient = getIt<DioClient>();
      final response = await dioClient.post(
        '/auth/verify-password',
        data: {'password': _passwordController.text.trim()},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onVerified();
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() => _errorMsg = 'Contraseña incorrecta');
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('401') || msg.contains('Unauthorized') || msg.contains('incorrecta')) {
        setState(() => _errorMsg = 'Contraseña incorrecta');
      } else {
        setState(() => _errorMsg = 'Error de conexion. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  widget.message,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              enabled: !_isLoading,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.key),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa tu contraseña';
                return null;
              },
              onFieldSubmitted: (_) => _verify(),
            ),
            if (_errorMsg.isNotEmpty) ...[
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
                      child: Text(_errorMsg, style: const TextStyle(color: Colors.red, fontSize: 13)),
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
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _verify,
          icon: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check, size: 18),
          label: Text(_isLoading ? 'Verificando...' : 'Confirmar'),
        ),
      ],
    );
  }
}
