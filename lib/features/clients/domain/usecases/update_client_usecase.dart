import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/client.dart';
import '../repositories/clients_repository.dart';

/// Parameters for updating a client
class UpdateClientParams {
  final String id;
  final String? nombre;
  final String? celular;
  final String? email;
  final String? direccion;
  final bool? isActive;

  const UpdateClientParams({
    required this.id,
    this.nombre,
    this.celular,
    this.email,
    this.direccion,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (nombre != null && nombre!.isNotEmpty) data['nombre'] = nombre;
    if (celular != null) data['celular'] = celular!.isEmpty ? null : celular;
    if (email != null) data['email'] = email!.isEmpty ? null : email;
    if (direccion != null) data['direccion'] = direccion!.isEmpty ? null : direccion;
    if (isActive != null) data['isActive'] = isActive;

    return data;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateClientParams &&
        other.id == id &&
        other.nombre == nombre &&
        other.celular == celular &&
        other.email == email &&
        other.direccion == direccion &&
        other.isActive == isActive;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      nombre.hashCode ^
      celular.hashCode ^
      email.hashCode ^
      direccion.hashCode ^
      isActive.hashCode;

  @override
  String toString() {
    return 'UpdateClientParams(id: $id, nombre: $nombre, celular: $celular, email: $email, direccion: $direccion, isActive: $isActive)';
  }
}

/// Use case for updating a client
class UpdateClientUseCase {
  final ClientsRepository repository;

  UpdateClientUseCase(this.repository);

  /// Execute the use case to update a client
  ///
  /// [params] - Parameters containing the client ID and updated information
  ///
  /// Returns the updated client or a failure
  Future<Either<Failure, Client>> call(UpdateClientParams params) async {
    try {
      // Validate ID is not empty
      if (params.id.trim().isEmpty) {
        return Left(ValidationFailure.required(
            'ID', 'El ID del cliente es requerido'));
      }

      // Validate at least one field is being updated
      final updateData = params.toJson();
      if (updateData.isEmpty) {
        return Left(ValidationFailure.invalid(
            'datos', 'Debe proporcionar al menos un campo para actualizar'));
      }

      // Validate nombre if provided
      if (params.nombre != null && params.nombre!.trim().isEmpty) {
        return Left(ValidationFailure.required(
            'nombre', 'El nombre del cliente no puede estar vacío'));
      }

      // Validate email format if provided
      if (params.email != null && params.email!.isNotEmpty) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(params.email!)) {
          return Left(
              ValidationFailure.invalid('email', 'El email no es válido'));
        }
      }

      return await repository.updateClient(params.id.trim(), updateData);
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al actualizar el cliente: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}
