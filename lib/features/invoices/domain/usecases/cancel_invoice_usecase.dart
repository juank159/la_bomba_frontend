import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/invoice.dart';
import '../repositories/invoices_repository.dart';

/// Use case for cancelling an existing invoice
class CancelInvoiceUseCase {
  final InvoicesRepository repository;

  CancelInvoiceUseCase(this.repository);

  Future<Either<Failure, Invoice>> call(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Left(
          ValidationFailure.required('ID', 'El ID de la factura es requerido'),
        );
      }

      return await repository.cancelInvoice(id.trim());
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al anular la factura: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
