// lib/features/corresponsal/domain/repositories/corresponsal_repository.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/corresponsal_entry.dart';

abstract class CorresponsalRepository {
  Future<Either<Failure, List<CorresponsalEntry>>> getEntries();
  Future<Either<Failure, CorresponsalEntry>> createEntry({required double amount, String? note});
  Future<Either<Failure, void>> deleteEntry(String id);
}
