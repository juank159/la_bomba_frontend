import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/client.dart';
import '../repositories/clients_repository.dart';

/// Parameters for creating a client
class CreateClientParams {
  final String nombre;
  final String? celular;
  final String? email;
  final String? direccion;

  const CreateClientParams({
    required this.nombre,
    this.celular,
    this.email,
    this.direccion,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      if (celular != null && celular!.isNotEmpty) 'celular': celular,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (direccion != null && direccion!.isNotEmpty) 'direccion': direccion,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateClientParams &&
        other.nombre == nombre &&
        other.celular == celular &&
        other.email == email &&
        other.direccion == direccion;
  }

  @override
  int get hashCode =>
      nombre.hashCode ^
      celular.hashCode ^
      email.hashCode ^
      direccion.hashCode;

  @override
  String toString() {
    return 'CreateClientParams(nombre: $nombre, celular: $celular, email: $email, direccion: $direccion)';
  }
}

/// Use case for creating a new client
class CreateClientUseCase {
  final ClientsRepository repository;

  CreateClientUseCase(this.repository);

  /// Execute the use case to create a client
  ///
  /// [params] - Parameters containing the client information
  ///
  /// Returns the created client or a failure
  Future<Either<Failure, Client>> call(CreateClientParams params) async {
    try {
      // Validate nombre is not empty
      if (params.nombre.trim().isEmpty) {
        return Left(ValidationFailure.required(
            'nombre', 'El nombre del cliente es obligatorio'));
      }

      // Validate email format if provided
      if (params.email != null && params.email!.isNotEmpty) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(params.email!)) {
          return Left(
              ValidationFailure.invalid('email', 'El email no es válido'));
        }
      }

      return await repository.createClient(params.toJson());
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al crear el cliente: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}
