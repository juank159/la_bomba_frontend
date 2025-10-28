// lib/features/credits/presentation/widgets/refund_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/client_balance_controller.dart';
import '../controllers/payment_method_controller.dart';
import '../../domain/entities/client_balance.dart';
import '../../../../app/core/utils/price_input_formatter.dart';
import '../../../../app/core/utils/number_formatter.dart';

/// Diálogo para devolver dinero al cliente
class RefundDialog extends StatelessWidget {
  final ClientBalance balance;
  final ClientBalanceController balanceController;
  final PaymentMethodController paymentMethodController;
  final VoidCallback onRefundSuccess;

  const RefundDialog({
    super.key,
    required this.balance,
    required this.balanceController,
    required this.paymentMethodController,
    required this.onRefundSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController(
      text: 'Devolución de saldo a favor',
    );
    final priceFormatter = PriceInputFormatter();
    final RxString selectedPaymentMethodId = ''.obs;

    // Set first method as default if there are active methods
    if (paymentMethodController.activePaymentMethods.isNotEmpty) {
      selectedPaymentMethodId.value =
          paymentMethodController.activePaymentMethods.first.id;
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.payments_outlined, color: Colors.orange[700]),
          const SizedBox(width: 8),
          const Text('Devolver Dinero al Cliente'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientInfo(context),
            const SizedBox(height: 16),
            _buildWarningInfo(context),
            const SizedBox(height: 16),
            _buildPaymentMethodSelector(selectedPaymentMethodId),
            const SizedBox(height: 16),
            _buildAmountField(amountController, priceFormatter),
            const SizedBox(height: 16),
            _buildDescriptionField(descriptionController),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () => _handleRefund(
            context,
            amountController,
            descriptionController,
            selectedPaymentMethodId,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Confirmar Devolución'),
        ),
      ],
    );
  }

  Widget _buildClientInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cliente:',
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            balance.clientName,
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saldo disponible:',
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            balance.formattedBalance,
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.orange[900]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Esta acción devolverá dinero al cliente y reducirá su saldo a favor',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector(RxString selectedPaymentMethodId) {
    return Obx(() {
      final activeMethods = paymentMethodController.activePaymentMethods;

      if (activeMethods.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, size: 20, color: Colors.red[900]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No hay métodos de pago activos. Por favor, configura al menos un método de pago.',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.red[900],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return DropdownButtonFormField<String>(
        value: selectedPaymentMethodId.value.isEmpty
            ? null
            : selectedPaymentMethodId.value,
        decoration: const InputDecoration(
          labelText: 'Método de Pago *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.payment),
        ),
        items: activeMethods.map((method) {
          return DropdownMenuItem(
            value: method.id,
            child: Row(
              children: [
                Text(
                  method.displayIcon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(method.name),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            selectedPaymentMethodId.value = value;
          }
        },
      );
    });
  }

  Widget _buildAmountField(
    TextEditingController controller,
    PriceInputFormatter formatter,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [formatter],
      autofocus: true,
      decoration: const InputDecoration(
        labelText: 'Monto a devolver *',
        prefixText: '\$',
        border: OutlineInputBorder(),
        hintText: '10.000',
        helperText: 'Ingresa el monto que devolverás al cliente',
      ),
    );
  }

  Widget _buildDescriptionField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Descripción (opcional)',
        border: OutlineInputBorder(),
        hintText: 'Ej: Devolución por solicitud del cliente',
      ),
      maxLines: 2,
    );
  }

  Future<void> _handleRefund(
    BuildContext context,
    TextEditingController amountController,
    TextEditingController descriptionController,
    RxString selectedPaymentMethodId,
  ) async {
    final amount = PriceFormatter.parse(amountController.text.trim());

    // Validar monto
    if (amount <= 0) {
      Get.snackbar(
        '❌ Error',
        'Por favor ingresa un monto válido mayor a cero',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return;
    }

    if (amount > balance.balance) {
      Get.snackbar(
        '❌ Monto Excedido',
        'El monto ${NumberFormatter.formatCurrency(amount)} excede el saldo disponible de ${balance.formattedBalance}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Confirmar devolución
    final confirmed = await _showConfirmationDialog(amount);
    if (confirmed != true) return;

    Get.back(); // Cerrar diálogo principal

    // Validar método de pago
    if (selectedPaymentMethodId.value.isEmpty) {
      Get.snackbar(
        '❌ Error',
        'Por favor selecciona un método de pago',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return;
    }

    // Ejecutar devolución
    final success = await balanceController.refundBalance(
      clientId: balance.clientId,
      amount: amount,
      description: descriptionController.text.trim().isEmpty
          ? 'Devolución de saldo a favor'
          : descriptionController.text.trim(),
      paymentMethodId: selectedPaymentMethodId.value,
    );

    if (success) {
      print('✅ Saldo devuelto correctamente');
      onRefundSuccess();
    }
  }

  Future<bool?> _showConfirmationDialog(double amount) {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar Devolución'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de devolver ${NumberFormatter.formatCurrency(amount)} a ${balance.clientName}?',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo actual:'),
                      Text(
                        balance.formattedBalance,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monto a devolver:'),
                      Text(
                        NumberFormatter.formatCurrency(amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nuevo saldo:'),
                      Text(
                        NumberFormatter.formatCurrency(balance.balance - amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Devolución'),
          ),
        ],
      ),
    );
  }
}
