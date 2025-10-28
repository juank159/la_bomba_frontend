// lib/features/credits/presentation/pages/credit_detail_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidos_frontend/features/credits/domain/entities/credit_transaction.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/core/utils/date_formatter.dart';
import '../../../../app/core/utils/price_input_formatter.dart';
import '../controllers/credits_controller.dart';
import '../controllers/payment_method_controller.dart';
import '../../domain/entities/credit.dart';

/// CreditDetailPage - Page showing credit details with payment history
class CreditDetailPage extends StatefulWidget {
  final String creditId;

  const CreditDetailPage({super.key, required this.creditId});

  @override
  State<CreditDetailPage> createState() => _CreditDetailPageState();
}

class _CreditDetailPageState extends State<CreditDetailPage> {
  late CreditsController controller;
  late PaymentMethodController paymentMethodController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CreditsController>();
    paymentMethodController = Get.put(PaymentMethodController());
    controller.clearSelectedCredit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getCreditById(widget.creditId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingWidget(message: 'Cargando crédito...');
        }

        final credit = controller.selectedCredit.value;
        if (credit == null) {
          return _buildErrorState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConfig.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCreditHeader(credit),
              const SizedBox(height: AppConfig.paddingLarge),
              _buildCreditSummary(credit),
              const SizedBox(height: AppConfig.paddingLarge),
              _buildTraceabilityInfo(credit),
              const SizedBox(height: AppConfig.paddingLarge),
              _buildPaymentHistory(credit),
            ],
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Detalle del Crédito'),
      centerTitle: true,
      actions: [
        Obx(() {
          final credit = controller.selectedCredit.value;
          if (credit == null) return const SizedBox.shrink();

          return PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              if (credit.isPending)
                const PopupMenuItem(
                  value: 'add_payment',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Agregar Pago'),
                    ],
                  ),
                ),
              if (credit.isPending)
                const PopupMenuItem(
                  value: 'add_debt',
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Agregar Deuda'),
                    ],
                  ),
                ),
              // TODO: Funcionalidad de eliminar crédito comentada temporalmente
              // hasta definir el comportamiento correcto para manejo de dinero
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCreditHeader(Credit credit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Get.theme.colorScheme.primaryContainer,
              child: Text(
                credit.clientInitials,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: AppConfig.paddingLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    credit.clientName,
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConfig.paddingSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: credit.isPaid
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppConfig.borderRadius,
                      ),
                    ),
                    child: Text(
                      credit.statusText,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: credit.isPaid ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditSummary(Credit credit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del Crédito',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            Text(credit.description, style: Get.textTheme.bodyMedium),
            const SizedBox(height: AppConfig.paddingMedium),
            const Divider(),
            const SizedBox(height: AppConfig.paddingMedium),
            _buildAmountRow(
              'Monto Total',
              credit.totalAmount,
              Colors.blue,
              true,
            ),
            const SizedBox(height: AppConfig.paddingSmall),
            _buildAmountRow('Pagado', credit.paidAmount, Colors.green, true),
            const SizedBox(height: AppConfig.paddingSmall),
            // Mostrar Pendiente (siempre >= 0, aunque haya sobrepago)
            _buildAmountRow(
              'Pendiente',
              credit.remainingAmount > 0 ? credit.remainingAmount : 0,
              credit.remainingAmount > 0 ? Colors.orange : Colors.grey,
              true,
            ),
            // Si hay sobrepago, mostrar saldo a favor generado
            if (credit.remainingAmount < 0) ...[
              const SizedBox(height: AppConfig.paddingSmall),
              _buildOverpaymentBadge(credit.remainingAmount.abs()),
            ],
            const SizedBox(height: AppConfig.paddingMedium),
            _buildProgressBar(credit),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount,
    Color color,
    bool isBold,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          NumberFormatter.formatCurrency(amount),
          style: Get.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOverpaymentBadge(double overpaymentAmount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: Colors.green[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo a Favor Generado',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'El cliente pagó más del monto adeudado',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            NumberFormatter.formatCurrency(overpaymentAmount),
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(Credit credit) {
    // Limitar el progreso a máximo 100% para visualización
    final displayProgress = credit.paymentProgress > 1.0
        ? 1.0
        : credit.paymentProgress;
    final progressPercentage = credit.paymentProgress > 1.0
        ? 100.0
        : (credit.paymentProgress * 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso del Pago',
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${progressPercentage.toStringAsFixed(1)}%',
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: credit.isPaid ? Colors.green : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: displayProgress,
            minHeight: 12,
            backgroundColor: Get.theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              credit.isPaid ? Colors.green : Get.theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTraceabilityInfo(Credit credit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de Trazabilidad',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            if (credit.createdBy != null)
              _buildTraceRow(
                'Creado por',
                credit.createdBy!,
                _formatDate(credit.createdAt),
                Icons.person_add,
              ),
            if (credit.updatedBy != null) ...[
              const SizedBox(height: AppConfig.paddingSmall),
              _buildTraceRow(
                'Última modificación',
                credit.updatedBy!,
                _formatDate(credit.updatedAt),
                Icons.edit,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTraceRow(
    String label,
    String username,
    String date,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '$username - $date',
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistory(Credit credit) {
    // Combine transactions list for unified history
    final transactions = credit.transactions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historial de Movimientos',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${transactions.length}',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            if (transactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConfig.paddingLarge),
                  child: Text(
                    'No hay movimientos registrados',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final transaction = transactions[index];

                  // Calcular saldo pendiente antes de esta transacción
                  final remainingBeforeTransaction =
                      _calculateRemainingBeforeTransaction(
                        credit.totalAmount,
                        transactions,
                        index,
                      );

                  return _buildTransactionItem(
                    transaction,
                    remainingBeforeTransaction,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Calcula el saldo pendiente antes de una transacción específica
  double _calculateRemainingBeforeTransaction(
    double totalAmount,
    List<CreditTransaction> transactions,
    int currentIndex,
  ) {
    double remaining = totalAmount;

    // Procesar todas las transacciones anteriores
    for (int i = 0; i < currentIndex; i++) {
      final trans = transactions[i];
      if (trans.isPayment) {
        remaining -= trans.amount;
      } else if (trans.isDebtIncrease) {
        remaining += trans.amount;
      }
    }

    return remaining;
  }

  /// Construye el item de transacción con detección de sobrepago
  Widget _buildTransactionItem(
    CreditTransaction transaction,
    double remainingBeforeTransaction,
  ) {
    final isPayment = transaction.isPayment;
    final isCharge = transaction.isCharge;
    final isDebtIncrease = transaction.isDebtIncrease;

    // Detectar si hay sobrepago (solo en pagos)
    final hasOverpayment =
        isPayment &&
        remainingBeforeTransaction > 0 &&
        transaction.amount > remainingBeforeTransaction;

    double? amountForDebt;
    double? overpaymentAmount;

    if (hasOverpayment) {
      amountForDebt = remainingBeforeTransaction;
      overpaymentAmount = transaction.amount - remainingBeforeTransaction;
    }

    // Determinar color e ícono según tipo
    Color transactionColor;
    IconData transactionIcon;
    String transactionLabel;
    String transactionSign;

    if (isPayment) {
      transactionColor = Colors.green;
      transactionIcon = hasOverpayment
          ? Icons.account_balance_wallet
          : Icons.payment;
      transactionLabel = hasOverpayment ? 'Pago con Sobrepago' : 'Pago';
      transactionSign = '-';
    } else if (isCharge) {
      transactionColor = Colors.blue;
      transactionIcon = Icons.receipt_long;
      transactionLabel = 'Deuda Inicial';
      transactionSign = '+';
    } else {
      // isDebtIncrease
      transactionColor = Colors.orange;
      transactionIcon = Icons.trending_up;
      transactionLabel = 'Aumento de Deuda';
      transactionSign = '+';
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: transactionColor.withOpacity(0.1),
        child: Icon(transactionIcon, color: transactionColor),
      ),
      title: Row(
        children: [
          Text(
            transactionSign,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: transactionColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            NumberFormatter.formatCurrency(transaction.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: transactionColor,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            transactionLabel,
            style: Get.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: transactionColor,
            ),
          ),
          if (transaction.description != null &&
              transaction.description!.isNotEmpty)
            Text(transaction.description!),
          // Mostrar desglose de sobrepago
          if (hasOverpayment &&
              amountForDebt != null &&
              overpaymentAmount != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Desglose del pago:',
                        style: Get.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '• Pagó deuda pendiente:',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.green[800],
                        ),
                      ),
                      Text(
                        NumberFormatter.formatCurrency(amountForDebt),
                        style: Get.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '• Saldo a favor generado:',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.green[800],
                        ),
                      ),
                      Text(
                        NumberFormatter.formatCurrency(overpaymentAmount),
                        style: Get.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _formatDate(transaction.createdAt),
            style: Get.textTheme.bodySmall,
          ),
          if (transaction.createdBy != null)
            Text(
              'Por: ${transaction.createdBy}',
              style: Get.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Get.theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Get.theme.colorScheme.error,
          ),
          const SizedBox(height: AppConfig.paddingMedium),
          const Text('No se pudo cargar el crédito'),
          const SizedBox(height: AppConfig.paddingMedium),
          ElevatedButton.icon(
            onPressed: () => controller.getCreditById(widget.creditId),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'add_payment':
        _showAddPaymentDialog();
        break;
      case 'add_debt':
        _showAddDebtDialog();
        break;
      case 'delete':
        // TODO: Funcionalidad de eliminar crédito comentada temporalmente
        // _showDeleteConfirmation();
        Get.snackbar(
          'En desarrollo',
          'La funcionalidad de eliminar créditos está en desarrollo. Esto requiere una definición clara de cómo manejar créditos con dinero involucrado.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        break;
    }
  }

  void _showAddPaymentDialog() {
    final credit = controller.selectedCredit.value;
    if (credit == null) return;

    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final RxString selectedPaymentMethodId = ''.obs;

    // Set first method as default if there are active methods
    if (paymentMethodController.activePaymentMethods.isNotEmpty) {
      selectedPaymentMethodId.value =
          paymentMethodController.activePaymentMethods.first.id;
    }

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('Agregar Pago'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Saldo pendiente: ${NumberFormatter.formatCurrency(credit.remainingAmount)}',
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: AppConfig.paddingSmall),
              Container(
                padding: const EdgeInsets.all(AppConfig.paddingSmall),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Si pagas más del saldo pendiente, el exceso se guardará como saldo a favor del cliente',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              _buildPaymentMethodSelector(selectedPaymentMethodId),
              const SizedBox(height: AppConfig.paddingMedium),
              CustomInput(
                controller: amountController,
                hintText: 'Monto del pago *',
                prefixIcon: const Icon(Icons.attach_money),
                keyboardType: TextInputType.number,
                inputFormatters: [PriceInputFormatter()],
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              CustomInput(
                controller: descriptionController,
                hintText: 'Descripción *',
                prefixIcon: const Icon(Icons.description),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isAddingPayment.value
                  ? null
                  : () async {
                      // Validar método de pago
                      if (selectedPaymentMethodId.value.isEmpty) {
                        Get.snackbar(
                          'Error',
                          'Por favor selecciona un método de pago',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.red[100],
                          colorText: Colors.red[900],
                        );
                        return;
                      }

                      // Parse the formatted amount using PriceFormatter
                      final amount = PriceFormatter.parse(
                        amountController.text.trim(),
                      );

                      if (amount <= 0) {
                        Get.snackbar(
                          'Error',
                          'El monto debe ser mayor a cero',
                          snackPosition: SnackPosition.TOP,
                        );
                        return;
                      }

                      // Validar descripción
                      if (descriptionController.text.trim().isEmpty) {
                        Get.snackbar(
                          'Error',
                          'La descripción es obligatoria',
                          snackPosition: SnackPosition.TOP,
                        );
                        return;
                      }

                      // Si el pago excede el saldo pendiente, mostrar confirmación
                      if (amount > credit.remainingAmount) {
                        final overpayment = amount - credit.remainingAmount;
                        final confirmed = await Get.dialog<bool>(
                          AlertDialog(
                            title: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                const Text('Sobrepago Detectado'),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'El monto ingresado es mayor al saldo pendiente:',
                                  style: Get.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: AppConfig.paddingMedium),
                                _buildAmountRow(
                                  'Saldo pendiente',
                                  credit.remainingAmount,
                                  Colors.orange,
                                  true,
                                ),
                                const SizedBox(height: AppConfig.paddingSmall),
                                _buildAmountRow(
                                  'Monto a pagar',
                                  amount,
                                  Colors.blue,
                                  true,
                                ),
                                const Divider(height: AppConfig.paddingMedium),
                                _buildAmountRow(
                                  'Exceso (saldo a favor)',
                                  overpayment,
                                  Colors.green,
                                  true,
                                ),
                                const SizedBox(height: AppConfig.paddingMedium),
                                Container(
                                  padding: const EdgeInsets.all(
                                    AppConfig.paddingSmall,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppConfig.borderRadius,
                                    ),
                                  ),
                                  child: Text(
                                    'El exceso de ${NumberFormatter.formatCurrency(overpayment)} se guardará como saldo a favor del cliente para futuros pagos.',
                                    style: Get.textTheme.bodySmall?.copyWith(
                                      color: Colors.green[700],
                                    ),
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
                                child: const Text('Confirmar Pago'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true) {
                          return;
                        }
                      }

                      final success = await controller.addPayment(
                        creditId: credit.id,
                        amount: amount,
                        description: descriptionController.text.trim(),
                        paymentMethodId: selectedPaymentMethodId.value,
                      );

                      // Close dialog immediately on success
                      if (success) {
                        Get.back();
                        // Wait a bit to ensure dialog closes before showing snackbar
                        await Future.delayed(const Duration(milliseconds: 100));
                        Get.snackbar(
                          'Éxito',
                          'Pago agregado exitosamente',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor:
                              Get.theme.colorScheme.primaryContainer,
                          colorText: Get.theme.colorScheme.onPrimaryContainer,
                        );
                      }
                    },
              child: controller.isAddingPayment.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Agregar'),
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

  // TODO: Funcionalidad de eliminar pago comentada temporalmente
  // hasta definir el comportamiento correcto para manejo de dinero
  // void _showDeletePaymentConfirmation(String paymentId) {
  //   Get.dialog(
  //     AlertDialog(
  //       title: const Text('Eliminar Pago'),
  //       content: const Text(
  //         '¿Estás seguro de que deseas eliminar este pago? Esta acción quedará registrada.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Get.back(),
  //           child: const Text('Cancelar'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             Get.back();
  //             final success = await controller.removePayment(
  //               creditId: widget.creditId,
  //               paymentId: paymentId,
  //             );
  //             if (!success) {
  //               // Error message already shown by controller
  //             }
  //           },
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //           child: const Text('Eliminar'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // TODO: Funcionalidad de eliminar crédito comentada temporalmente
  // hasta definir el comportamiento correcto para manejo de dinero
  // void _showDeleteConfirmation() {
  //   Get.dialog(
  //     AlertDialog(
  //       title: const Text('Eliminar Crédito'),
  //       content: const Text(
  //         '¿Estás seguro de que deseas eliminar este crédito? Esta acción quedará registrada pero el crédito no se eliminará permanentemente.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Get.back(),
  //           child: const Text('Cancelar'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             Get.back();
  //             final success = await controller.deleteCredit(widget.creditId);
  //             if (success) {
  //               Get.offNamed(AppRoutes.credits);
  //             }
  //           },
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //           child: const Text('Eliminar'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showAddDebtDialog() {
    final credit = controller.selectedCredit.value;
    if (credit == null) return;

    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Agregar Deuda'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Saldo actual: ${NumberFormatter.formatCurrency(credit.remainingAmount)}',
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              CustomInput(
                controller: amountController,
                hintText: 'Monto a agregar *',
                prefixIcon: const Icon(Icons.attach_money),
                keyboardType: TextInputType.number,
                inputFormatters: [PriceInputFormatter()],
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              CustomInput(
                controller: descriptionController,
                hintText: '¿Qué está llevando? *',
                prefixIcon: const Icon(Icons.description),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isCreating.value
                  ? null
                  : () async {
                      // Parse the formatted amount using PriceFormatter
                      final amount = PriceFormatter.parse(
                        amountController.text.trim(),
                      );

                      if (amount <= 0) {
                        Get.snackbar(
                          'Error',
                          'El monto debe ser mayor a cero',
                          snackPosition: SnackPosition.TOP,
                        );
                        return;
                      }

                      if (descriptionController.text.trim().isEmpty) {
                        Get.snackbar(
                          'Error',
                          'La descripción es obligatoria',
                          snackPosition: SnackPosition.TOP,
                        );
                        return;
                      }

                      final success = await controller.addAmountToCredit(
                        creditId: credit.id,
                        amount: amount,
                        description: descriptionController.text.trim(),
                      );

                      // Close dialog immediately on success
                      if (success) {
                        Get.back();
                        // Wait a bit to ensure dialog closes before showing snackbar
                        await Future.delayed(const Duration(milliseconds: 100));
                        Get.snackbar(
                          'Éxito',
                          'Monto agregado al crédito exitosamente',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor:
                              Get.theme.colorScheme.primaryContainer,
                          colorText: Get.theme.colorScheme.onPrimaryContainer,
                        );
                      }
                    },
              child: controller.isCreating.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Agregar'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDateTime(date);
  }
}
