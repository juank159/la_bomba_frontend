import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/invoice.dart';
import '../repositories/invoices_repository.dart';

/// Use case for creating a new invoice
class CreateInvoiceUseCase {
  final InvoicesRepository repository;

  CreateInvoiceUseCase(this.repository);

  Future<Either<Failure, Invoice>> call(CreateInvoiceParams params) async {
    try {
      final validationFailure = _validateParams(params);
      if (validationFailure != null) {
        return Left(validationFailure);
      }

      return await repository.createInvoice(params);
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al crear la factura: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  ValidationFailure? _validateParams(CreateInvoiceParams params) {
    if (params.paymentMethodId.trim().isEmpty) {
      return ValidationFailure.required(
        'Método de pago',
        'Debe seleccionar un método de pago',
      );
    }

    if (params.items.isEmpty) {
      return ValidationFailure.required(
        'Productos',
        'La factura debe tener al menos un producto',
      );
    }

    for (int i = 0; i < params.items.length; i++) {
      final item = params.items[i];

      if (item.productId.trim().isEmpty) {
        return ValidationFailure.required(
          'Producto ${i + 1}',
          'El ID del producto es requerido',
        );
      }

      if (item.quantity <= 0) {
        return ValidationFailure(
          'La cantidad del producto ${i + 1} debe ser mayor a 0',
          code: 'INVALID_QUANTITY',
        );
      }
    }

    return null;
  }
}
