// lib/features/corresponsal/data/models/corresponsal_entry_model.dart

import '../../domain/entities/corresponsal_entry.dart';

class CorresponsalEntryModel extends CorresponsalEntry {
  const CorresponsalEntryModel({
    required super.id,
    required super.amount,
    super.note,
    required super.createdById,
    super.createdBy,
    required super.createdAt,
  });

  factory CorresponsalEntryModel.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'] is String ? double.parse(json['amount'] as String) : (json['amount'] as num).toDouble();

    String? createdBy;
    final rawCreatedBy = json['createdBy'];
    if (rawCreatedBy is String) {
      createdBy = rawCreatedBy;
    } else if (rawCreatedBy is Map<String, dynamic>) {
      createdBy = rawCreatedBy['username'] as String?;
    }

    return CorresponsalEntryModel(
      id: json['id'] as String,
      amount: amount,
      note: json['note'] as String?,
      createdById: json['createdById'] as String,
      createdBy: createdBy,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  CorresponsalEntry toEntity() {
    return CorresponsalEntry(
      id: id,
      amount: amount,
      note: note,
      createdById: createdById,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
