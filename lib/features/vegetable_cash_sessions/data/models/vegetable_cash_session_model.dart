// lib/features/vegetable_cash_sessions/data/models/vegetable_cash_session_model.dart

import '../../domain/entities/vegetable_cash_session.dart';

class VegetableCashSessionModel extends VegetableCashSession {
  const VegetableCashSessionModel({
    required super.id,
    required super.status,
    required super.openedBy,
    required super.openedAt,
    required super.openingAmount,
    super.closedBy,
    super.closedAt,
    super.closingAmount,
    super.expectedAmount,
    super.difference,
    super.notes,
  });

  factory VegetableCashSessionModel.fromJson(Map<String, dynamic> json) {
    return VegetableCashSessionModel(
      id: json['id'] as String,
      status: CashSessionStatus.fromString(json['status'] as String? ?? 'open'),
      openedBy: json['openedBy'] as String? ?? '',
      openedAt: DateTime.parse(json['openedAt'] as String),
      openingAmount: _parseDouble(json['openingAmount']) ?? 0,
      closedBy: json['closedBy'] as String?,
      closedAt: json['closedAt'] != null ? DateTime.parse(json['closedAt'] as String) : null,
      closingAmount: _parseDouble(json['closingAmount']),
      expectedAmount: _parseDouble(json['expectedAmount']),
      difference: _parseDouble(json['difference']),
      notes: json['notes'] as String?,
    );
  }

  VegetableCashSession toEntity() {
    return VegetableCashSession(
      id: id,
      status: status,
      openedBy: openedBy,
      openedAt: openedAt,
      openingAmount: openingAmount,
      closedBy: closedBy,
      closedAt: closedAt,
      closingAmount: closingAmount,
      expectedAmount: expectedAmount,
      difference: difference,
      notes: notes,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class VegetableCashSessionSummaryModel extends VegetableCashSessionSummary {
  const VegetableCashSessionSummaryModel({
    required super.session,
    required super.cashSales,
    required super.cashExpenses,
    required super.expectedAmount,
  });

  factory VegetableCashSessionSummaryModel.fromJson(Map<String, dynamic> json) {
    return VegetableCashSessionSummaryModel(
      session: json['session'] != null
          ? VegetableCashSessionModel.fromJson(json['session'] as Map<String, dynamic>).toEntity()
          : null,
      cashSales: _parseDouble(json['cashSales']) ?? 0,
      cashExpenses: _parseDouble(json['cashExpenses']) ?? 0,
      expectedAmount: _parseDouble(json['expectedAmount']) ?? 0,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
