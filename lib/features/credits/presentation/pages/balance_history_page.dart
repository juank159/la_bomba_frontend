// lib/features/credits/presentation/pages/balance_history_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/client_balance_controller.dart';
import '../../domain/entities/client_balance.dart';
import '../../domain/entities/client_balance_transaction.dart';
import '../../../../app/core/utils/date_formatter.dart';

/// Pantalla profesional que muestra el historial completo de transacciones
/// de saldos a favor de todos los clientes
class BalanceHistoryPage extends StatefulWidget {
  const BalanceHistoryPage({super.key});

  @override
  State<BalanceHistoryPage> createState() => _BalanceHistoryPageState();
}

class _BalanceHistoryPageState extends State<BalanceHistoryPage> {
  late ClientBalanceController controller;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    controller = Get.find<ClientBalanceController>();
  }

  /// Obtiene todas las transacciones de depósito de todos los clientes
  List<_TransactionWithClient> _getAllDepositTransactions() {
    final List<_TransactionWithClient> allTransactions = [];

    for (final balance in controller.balances) {
      final deposits = balance.transactions
          .where((t) => t.type == BalanceTransactionType.deposit)
          .toList();

      for (final transaction in deposits) {
        allTransactions.add(_TransactionWithClient(
          transaction: transaction,
          clientName: balance.clientName,
          clientId: balance.clientId,
        ));
      }
    }

    // Ordenar por fecha (más reciente primero)
    allTransactions.sort((a, b) =>
      b.transaction.createdAt.compareTo(a.transaction.createdAt)
    );

    return allTransactions;
  }

  /// Filtra transacciones por búsqueda
  List<_TransactionWithClient> _getFilteredTransactions() {
    final allTransactions = _getAllDepositTransactions();

    if (_searchQuery.isEmpty) {
      return allTransactions;
    }

    return allTransactions.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.clientName.toLowerCase().contains(query) ||
             item.transaction.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Transacciones'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por cliente o descripción...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Lista de transacciones
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.balances.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredTransactions = _getFilteredTransactions();

              if (filteredTransactions.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadAllBalances(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final item = filteredTransactions[index];
                    return _buildTransactionCard(context, item);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.history_outlined : Icons.search_off,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No hay transacciones registradas'
                : 'No se encontraron resultados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Las transacciones de saldo aparecerán aquí'
                : 'Intenta con otra búsqueda',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, _TransactionWithClient item) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final hasCreditLink = item.transaction.relatedCreditId != null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: hasCreditLink
            ? () => Get.toNamed('/credits/${item.transaction.relatedCreditId}')
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono de crédito
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cliente
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.clientName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Descripción
                    Text(
                      item.transaction.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Monto y fecha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currencyFormatter.format(item.transaction.amount),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatter.formatDateTime(item.transaction.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Flecha de navegación
              if (hasCreditLink)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clase auxiliar para combinar transacción con información del cliente
class _TransactionWithClient {
  final ClientBalanceTransaction transaction;
  final String clientName;
  final String clientId;

  _TransactionWithClient({
    required this.transaction,
    required this.clientName,
    required this.clientId,
  });
}
