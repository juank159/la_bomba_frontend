import 'package:equatable/equatable.dart';

/// Supplier entity representing a supplier in the domain layer
/// Matches the backend Supplier entity structure
class Supplier extends Equatable {
  final String id;
  final String nombre;
  final String? celular;
  final String? email;
  final String? direccion;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Supplier({
    required this.id,
    required this.nombre,
    this.celular,
    this.email,
    this.direccion,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        nombre,
        celular,
        email,
        direccion,
        isActive,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Supplier(id: $id, nombre: $nombre, celular: $celular, email: $email, direccion: $direccion, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  /// Copy with method for creating modified instances
  Supplier copyWith({
    String? id,
    String? nombre,
    String? celular,
    String? email,
    String? direccion,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      celular: celular ?? this.celular,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if the supplier is currently active
  bool get isCurrentlyActive => isActive;

  /// Get a display-friendly status text
  String get statusText => isActive ? 'Activo' : 'Inactivo';

  /// Get supplier initials (for avatar)
  String get initials {
    final parts = nombre.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, nombre.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Check if supplier has contact information
  bool get hasContactInfo => celular != null || email != null;

  /// Check if supplier has complete information
  bool get hasCompleteInfo =>
      celular != null && email != null && direccion != null;
}
