// lib/features/credits/presentation/widgets/client_balances_tab.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/client_balance_controller.dart';
import '../../domain/entities/client_balance.dart';
import '../../domain/entities/client_balance_transaction.dart';
import '../../../../app/core/utils/date_formatter.dart';

/// Widget que muestra la lista de saldos a favor de clientes
class ClientBalancesTab extends StatelessWidget {
  final ClientBalanceController controller;
  final Function(ClientBalance) onRefundPressed;

  const ClientBalancesTab({
    super.key,
    required this.controller,
    required this.onRefundPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.balances.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.errorMessage.value.isNotEmpty &&
          controller.balances.isEmpty) {
        return _buildErrorState(context);
      }

      if (controller.balances.isEmpty) {
        return _buildEmptyState(context);
      }

      // Ordenar por fecha de actualización/creación (más recientes primero)
      final sortedBalances = List<ClientBalance>.from(controller.balances)
        ..sort((a, b) {
          // Comparar por updatedAt si existe, si no por createdAt
          final dateA = a.updatedAt ?? a.createdAt;
          final dateB = b.updatedAt ?? b.createdAt;
          return dateB.compareTo(dateA); // Descendente (más reciente primero)
        });

      return RefreshIndicator(
        onRefresh: () => controller.loadAllBalances(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedBalances.length,
          itemBuilder: (context, index) {
            final balance = sortedBalances[index];
            return ClientBalanceCard(
              balance: balance,
              onRefundPressed: () => onRefundPressed(balance),
            );
          },
        ),
      );
    });
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay saldos a favor',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los clientes con saldo a favor aparecerán aquí',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta individual de saldo de cliente
class ClientBalanceCard extends StatelessWidget {
  final ClientBalance balance;
  final VoidCallback onRefundPressed;

  const ClientBalanceCard({
    super.key,
    required this.balance,
    required this.onRefundPressed,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Cliente y Saldo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          balance.clientName[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
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
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Saldo a favor',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  currencyFormatter.format(balance.balance),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            // Origen del Saldo
            if (balance.transactions.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Origen del Saldo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              _buildOriginSection(context, balance),
            ],

            const SizedBox(height: 16),

            // Botón de devolución
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRefundPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Devolver Dinero'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la sección de origen del saldo con hipervínculos a créditos
  Widget _buildOriginSection(BuildContext context, ClientBalance balance) {
    // Filtrar solo transacciones de depósito (son las que generan saldo)
    final depositTransactions = balance.transactions
        .where((t) => t.type == BalanceTransactionType.deposit)
        .toList();

    if (depositTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No hay información de origen disponible',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar SOLO la última transacción (la más reciente)
    return _buildOriginItem(context, depositTransactions.first);
  }

  /// Construye un item de origen individual con navegación al crédito
  Widget _buildOriginItem(BuildContext context, ClientBalanceTransaction transaction) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final hasCreditLink = transaction.relatedCreditId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: hasCreditLink
            ? () => _navigateToCreditDetail(transaction.relatedCreditId!)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            // Icono de crédito
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.receipt_long,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),

            // Información de la transacción
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasCreditLink)
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormatter.format(transaction.amount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDateTime(transaction.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navega al detalle del crédito
  void _navigateToCreditDetail(String creditId) {
    Get.toNamed('/credits/$creditId');
  }
}
