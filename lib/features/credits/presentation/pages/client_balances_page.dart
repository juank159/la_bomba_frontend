// lib/features/credits/presentation/pages/client_balances_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/client_balance_controller.dart';
import '../../domain/entities/client_balance.dart';
import '../../domain/entities/client_balance_transaction.dart';

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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Get.back();
                                _showUseBalanceDialog(context, balance);
                              },
                              icon: const Icon(Icons.payment),
                              label: const Text('Usar Saldo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Get.back();
                                _showRefundBalanceDialog(context, balance);
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Devolver'),
                            ),
                          ),
                        ],
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

  void _showUseBalanceDialog(BuildContext context, ClientBalance balance) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController(
      text: 'Uso de saldo a favor',
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Usar Saldo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cliente: ${balance.clientName}'),
            Text('Saldo disponible: ${balance.formattedBalance}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto a usar',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
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
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                Get.snackbar('Error', 'Ingresa un monto válido');
                return;
              }

              Get.back();

              final success = await controller.useBalance(
                clientId: balance.clientId,
                amount: amount,
                description: descriptionController.text,
              );

              if (success) {
                print('✅ Saldo usado correctamente');
              }
            },
            child: const Text('Usar Saldo'),
          ),
        ],
      ),
    );
  }

  void _showRefundBalanceDialog(BuildContext context, ClientBalance balance) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController(
      text: 'Devolución de saldo a favor',
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Devolver Saldo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cliente: ${balance.clientName}'),
            Text('Saldo disponible: ${balance.formattedBalance}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto a devolver',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
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
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                Get.snackbar('Error', 'Ingresa un monto válido');
                return;
              }

              Get.back();

              final success = await controller.refundBalance(
                clientId: balance.clientId,
                amount: amount,
                description: descriptionController.text,
              );

              if (success) {
                print('✅ Saldo devuelto correctamente');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Devolver'),
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
