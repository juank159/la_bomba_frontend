import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/invoice.dart';
import '../repositories/invoices_repository.dart';

/// Use case for getting all invoices
class GetInvoicesUseCase {
  final InvoicesRepository repository;

  GetInvoicesUseCase(this.repository);

  Future<Either<Failure, List<Invoice>>> call() async {
    try {
      return await repository.getAllInvoices();
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener facturas: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}

/// Parameters for getting a single invoice by ID
class GetInvoiceByIdParams {
  final String id;

  const GetInvoiceByIdParams({required this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetInvoiceByIdParams && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Use case for getting a single invoice by ID
class GetInvoiceByIdUseCase {
  final InvoicesRepository repository;

  GetInvoiceByIdUseCase(this.repository);

  Future<Either<Failure, Invoice>> call(GetInvoiceByIdParams params) async {
    try {
      if (params.id.trim().isEmpty) {
        return Left(
          ValidationFailure.required('ID', 'El ID de la factura es requerido'),
        );
      }

      return await repository.getInvoiceById(params.id.trim());
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener la factura: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
