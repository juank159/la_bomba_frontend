import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

/// Base interface for all use cases in the application
/// T is the return type, P is the parameters type
abstract class UseCase<T, P> {
  Future<Either<Failure, T>> call(P params);
}

/// Use case for operations that don't require parameters
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}