// lib/features/corresponsal/domain/entities/corresponsal_entry.dart

import 'package:equatable/equatable.dart';

/// A commission charged for the banking correspondent service (e.g.
/// someone withdraws \$1,000,000 and gets charged \$1,000 - that \$1,000
/// is what this records). Small on purpose: amount + an optional note,
/// no editing - wrong entries get deleted and re-added.
class CorresponsalEntry extends Equatable {
  final String id;
  final double amount;
  final String? note;
  final String createdById;
  final String? createdBy;
  final DateTime createdAt;

  const CorresponsalEntry({
    required this.id,
    required this.amount,
    this.note,
    required this.createdById,
    this.createdBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, amount, note, createdById, createdBy, createdAt];

  String get userName => createdBy ?? 'Usuario desconocido';

  String get formattedTime {
    final localTime = createdAt.toLocal();
    int hour = localTime.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }
    return '$hour:${localTime.minute.toString().padLeft(2, '0')} $period';
  }
}
