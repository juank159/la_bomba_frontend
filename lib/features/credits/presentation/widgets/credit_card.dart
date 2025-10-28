// lib/features/credits/presentation/widgets/credit_card.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/core/utils/date_formatter.dart';
import '../../domain/entities/credit.dart';

/// CreditCard - Widget to display credit information in a card
class CreditCard extends StatelessWidget {
  final Credit credit;
  final VoidCallback? onTap;

  const CreditCard({
    super.key,
    required this.credit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular si hay sobrepago (saldo a favor)
    final overpayment = credit.paidAmount > credit.totalAmount
        ? credit.paidAmount - credit.totalAmount
        : 0.0;
    final hasOverpayment = overpayment > 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        horizontal: AppConfig.paddingMedium,
        vertical: AppConfig.paddingSmall,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with client name and status
              Row(
                children: [
                  // Avatar with initials
                  _buildAvatar(),
                  const SizedBox(width: AppConfig.paddingMedium),
                  // Client name and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credit.clientName,
                          style: Get.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(credit.createdAt),
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  _buildStatusBadge(hasOverpayment, overpayment),
                ],
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              // Description
              Text(
                credit.description,
                style: Get.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              // Progress bar
              _buildProgressBar(),
              const SizedBox(height: AppConfig.paddingSmall),
              // Amounts row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Total amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        NumberFormatter.formatCurrency(credit.totalAmount),
                        style: Get.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Paid amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Pagado',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        NumberFormatter.formatCurrency(credit.paidAmount),
                        style: Get.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  // Remaining amount OR Overpayment
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        hasOverpayment ? 'A Favor' : 'Pendiente',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        hasOverpayment
                            ? NumberFormatter.formatCurrency(overpayment)
                            : NumberFormatter.formatCurrency(credit.remainingAmount),
                        style: Get.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasOverpayment
                              ? Colors.green[700]
                              : (credit.isPaid ? Colors.green : Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build avatar with initials
  Widget _buildAvatar() {
    return CircleAvatar(
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      child: Text(
        credit.clientInitials,
        style: TextStyle(
          color: Get.theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build status badge
  Widget _buildStatusBadge(bool hasOverpayment, double overpayment) {
    // Si hay sobrepago, mostrar badge especial de "Saldo a Favor"
    if (hasOverpayment) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConfig.paddingSmall,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          border: Border.all(color: Colors.green[700]!, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 14,
              color: Colors.green[700],
            ),
            const SizedBox(width: 4),
            Text(
              'Saldo a Favor',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Badge normal de estado
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConfig.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: credit.isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Text(
        credit.statusText,
        style: Get.textTheme.bodySmall?.copyWith(
          color: credit.isPaid ? Colors.green : Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build progress bar
  Widget _buildProgressBar() {
    // Limitar progreso al 100% máximo para visualización
    final displayProgress = credit.paymentProgress > 1.0 ? 1.0 : credit.paymentProgress;
    final progressPercentage = (credit.paymentProgress * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              '$progressPercentage%',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: displayProgress,
            minHeight: 8,
            backgroundColor: Get.theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              credit.isPaid ? Colors.green : Get.theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return DateFormatter.formatRelative(date);
  }
}
