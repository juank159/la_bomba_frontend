// lib/features/credits/domain/entities/payment_method.dart

import 'package:equatable/equatable.dart';

/// Entidad que representa un método de pago
class PaymentMethod extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final bool isActive;
  /// true solo para el método que representa efectivo físico en caja
  /// (Efectivo). El cierre de caja de Verduras usa esto para saber qué
  /// ventas cuentan como plata real en el cajón vs dinero que fue a un
  /// banco (Nequi, Bancolombia, etc.).
  final bool isCash;
  final String createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentMethod({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.isActive,
    this.isCash = false,
    required this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        icon,
        isActive,
        isCash,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
      ];

  /// Obtiene el icono de Flutter según el nombre del icono
  String get displayIcon {
    switch (icon) {
      case 'cash':
        return '💵';
      case 'bank_transfer':
        return '🏦';
      case 'mobile_payment':
        return '📱';
      case 'debit_card':
        return '💳';
      case 'credit_card':
        return '💳';
      default:
        return '💰';
    }
  }
}
