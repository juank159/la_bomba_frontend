import '../../domain/entities/client.dart';

/// Client model for data layer that extends Client entity
/// Handles JSON serialization/deserialization matching backend structure
class ClientModel extends Client {
  const ClientModel({
    required super.id,
    required super.nombre,
    super.celular,
    super.email,
    super.direccion,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create ClientModel from JSON
  factory ClientModel.fromJson(Map<String, dynamic> json) {
    try {
      return ClientModel(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        celular: json['celular'] as String?,
        email: json['email'] as String?,
        direccion: json['direccion'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      throw FormatException('Error parsing ClientModel from JSON: $e', json);
    }
  }

  /// Convert ClientModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'celular': celular,
      'email': email,
      'direccion': direccion,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert ClientModel to Client entity
  Client toEntity() {
    return Client(
      id: id,
      nombre: nombre,
      celular: celular,
      email: email,
      direccion: direccion,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create ClientModel from Client entity
  factory ClientModel.fromEntity(Client client) {
    return ClientModel(
      id: client.id,
      nombre: client.nombre,
      celular: client.celular,
      email: client.email,
      direccion: client.direccion,
      isActive: client.isActive,
      createdAt: client.createdAt,
      updatedAt: client.updatedAt,
    );
  }

  /// Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'ClientModel(id: $id, nombre: $nombre, celular: $celular, email: $email, direccion: $direccion, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  /// Create a copy of ClientModel with updated fields
  ClientModel copyWith({
    String? id,
    String? nombre,
    String? celular,
    String? email,
    String? direccion,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientModel(
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
}
