import 'package:equatable/equatable.dart';

class Income extends Equatable {
  final String id;
  final String description;
  final double amount;
  final String createdById;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Income({
    required this.id,
    required this.description,
    required this.amount,
    required this.createdById,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  String get userName => createdBy ?? 'Usuario desconocido';

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final incomeDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (incomeDate == today) {
      return 'Hoy';
    } else if (incomeDate == yesterday) {
      return 'Ayer';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  @override
  List<Object?> get props => [id, description, amount, createdById, createdBy, updatedBy, createdAt, updatedAt];

  Income copyWith({
    String? id,
    String? description,
    double? amount,
    String? createdById,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Income(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      createdById: createdById ?? this.createdById,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
