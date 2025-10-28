// lib/features/credits/presentation/pages/client_balances_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/client_balance_controller.dart';
import '../../domain/entities/client_balance.dart';
import '../../domain/entities/client_balance_transaction.dart';
import '../../../../app/core/utils/price_input_formatter.dart';
import '../../../../app/core/utils/number_formatter.dart';

class ClientBalancesPage extends StatelessWidget {
  ClientBalancesPage({super.key});

  final ClientBalanceController controller = Get.put(ClientBalanceController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saldos a Favor de Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadAllBalances(),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.balances.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => controller.loadAllBalances(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (controller.balances.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay clientes con saldo a favor',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los saldos aparecerán cuando haya sobrepagos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadAllBalances(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.balances.length,
            itemBuilder: (context, index) {
              final balance = controller.balances[index];
              return _buildBalanceCard(context, balance);
            },
          ),
        );
      }),
    );
  }

  Widget _buildBalanceCard(BuildContext context, ClientBalance balance) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showBalanceDetails(context, balance),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(
                      Icons.account_circle,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.clientName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Saldo disponible',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        balance.formattedBalance,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (balance.lastTransaction != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(balance.lastTransaction!.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (balance.transactions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.history, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${balance.transactions.length} transacciones',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const Spacer(),
                    Text(
                      'Ver detalles →',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBalanceDetails(BuildContext context, ClientBalance balance) {
    controller.selectBalance(balance);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        balance.clientName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        balance.formattedBalance,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Este saldo se usará automáticamente al crear nuevos créditos',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.blue[900],
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            _showRefundBalanceDialog(context, balance);
                          },
                          icon: const Icon(Icons.payments_outlined),
                          label: const Text('Devolver Dinero al Cliente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Historial de Transacciones',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoadingTransactions.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.transactions.isEmpty) {
                      return const Center(
                        child: Text('No hay transacciones'),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = controller.transactions[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: transaction.isPositive
                                ? Colors.green[100]
                                : Colors.red[100],
                            child: Icon(
                              transaction.isPositive
                                  ? Icons.add
                                  : Icons.remove,
                              color: transaction.isPositive
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                          title: Text(transaction.type.displayName),
                          subtitle: Text(
                            transaction.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                transaction.formattedAmount,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: transaction.isPositive
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                              ),
                              Text(
                                _formatDate(transaction.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRefundBalanceDialog(BuildContext context, ClientBalance balance) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController(
      text: 'Devolución de saldo a favor',
    );
    final priceFormatter = PriceInputFormatter();

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payments_outlined, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Devolver Dinero al Cliente'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
            ),
            const SizedBox(height: 16),
            Container(
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
                      'Esta acción devolverá dinero en efectivo al cliente y reducirá su saldo a favor',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [priceFormatter],
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Monto a devolver *',
                prefixText: '\$',
                border: OutlineInputBorder(),
                hintText: '10.000',
                helperText: 'Ingresa el monto que devolverás en efectivo',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
                hintText: 'Ej: Devolución por solicitud del cliente',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final amount = PriceFormatter.parse(amountController.text.trim());
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

              // Confirmación adicional
              final confirmed = await Get.dialog<bool>(
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

              if (confirmed != true) return;

              Get.back(); // Cerrar diálogo principal

              final success = await controller.refundBalance(
                clientId: balance.clientId,
                amount: amount,
                description: descriptionController.text.trim().isEmpty
                    ? 'Devolución de saldo a favor'
                    : descriptionController.text.trim(),
              );

              if (success) {
                print('✅ Saldo devuelto correctamente');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar Devolución'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
