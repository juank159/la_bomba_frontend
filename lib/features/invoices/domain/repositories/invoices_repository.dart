import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/invoice.dart';

/// Parameters for a single line item when creating an invoice
class CreateInvoiceItemParams {
  final String productId;
  final int quantity;

  const CreateInvoiceItemParams({
    required this.productId,
    required this.quantity,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateInvoiceItemParams &&
        other.productId == productId &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => productId.hashCode ^ quantity.hashCode;
}

/// Parameters for creating a new invoice
class CreateInvoiceParams {
  final String? clientId;
  final String paymentMethodId;
  final List<CreateInvoiceItemParams> items;

  const CreateInvoiceParams({
    this.clientId,
    required this.paymentMethodId,
    required this.items,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateInvoiceParams &&
        other.clientId == clientId &&
        other.paymentMethodId == paymentMethodId &&
        other.items.length == items.length;
  }

  @override
  int get hashCode =>
      clientId.hashCode ^ paymentMethodId.hashCode ^ items.hashCode;
}

/// Invoices repository interface defining the contract for invoice data operations
abstract class InvoicesRepository {
  /// Get all invoices, most recent first
  Future<Either<Failure, List<Invoice>>> getAllInvoices();

  /// Get a specific invoice by its ID
  Future<Either<Failure, Invoice>> getInvoiceById(String id);

  /// Create a new invoice
  Future<Either<Failure, Invoice>> createInvoice(CreateInvoiceParams params);

  /// Cancel an existing invoice
  Future<Either<Failure, Invoice>> cancelInvoice(String id);
}
