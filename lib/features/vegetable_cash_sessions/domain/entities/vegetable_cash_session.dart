// lib/features/vegetable_cash_sessions/domain/entities/vegetable_cash_session.dart

import 'package:equatable/equatable.dart';

enum CashSessionStatus {
  open('open'),
  closed('closed');

  const CashSessionStatus(this.value);
  final String value;

  static CashSessionStatus fromString(String value) {
    return value == 'closed' ? CashSessionStatus.closed : CashSessionStatus.open;
  }
}

/// One cash-register shift for the vegetables stand: opens with a
/// starting cash amount, closes with a physical count compared against
/// what's expected (opening amount + cash sales - cash-funded expenses
/// during the shift).
class VegetableCashSession extends Equatable {
  final String id;
  final CashSessionStatus status;
  final String openedBy;
  final DateTime openedAt;
  final double openingAmount;
  final String? closedBy;
  final DateTime? closedAt;
  final double? closingAmount;
  final double? expectedAmount;
  final double? difference;
  final String? notes;

  const VegetableCashSession({
    required this.id,
    required this.status,
    required this.openedBy,
    required this.openedAt,
    required this.openingAmount,
    this.closedBy,
    this.closedAt,
    this.closingAmount,
    this.expectedAmount,
    this.difference,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id,
        status,
        openedBy,
        openedAt,
        openingAmount,
        closedBy,
        closedAt,
        closingAmount,
        expectedAmount,
        difference,
        notes,
      ];

  bool get isOpen => status == CashSessionStatus.open;
  bool get hasDiscrepancy => difference != null && difference != 0;
  bool get isSurplus => (difference ?? 0) > 0;

  String _formatted(DateTime dt) {
    final localTime = dt.toLocal();
    int hour = localTime.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }
    return '${localTime.day}/${localTime.month}/${localTime.year} $hour:${localTime.minute.toString().padLeft(2, '0')} $period';
  }

  String get formattedOpenedAt => _formatted(openedAt);
  String get formattedClosedAt => closedAt != null ? _formatted(closedAt!) : '';
}

/// How much came in through one payment method (Efectivo, Nequi,
/// Bancolombia, ...) during a cash session - the traceability breakdown
/// behind the single cash total shown on close.
class CashSessionPaymentBreakdown extends Equatable {
  final String paymentMethodId;
  final String paymentMethodName;
  final bool isCash;
  final double total;
  final int count;

  const CashSessionPaymentBreakdown({
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.isCash,
    required this.total,
    required this.count,
  });

  @override
  List<Object?> get props => [paymentMethodId, paymentMethodName, isCash, total, count];
}

/// Live snapshot of the currently open session (or none), with totals
/// computed on the fly - used to show "how much should be in the drawer
/// right now" before actually closing it.
class VegetableCashSessionSummary extends Equatable {
  final VegetableCashSession? session;
  final double cashSales;
  final double cashExpenses;
  final double expectedAmount;
  final List<CashSessionPaymentBreakdown> paymentBreakdown;

  const VegetableCashSessionSummary({
    required this.session,
    required this.cashSales,
    required this.cashExpenses,
    required this.expectedAmount,
    this.paymentBreakdown = const [],
  });

  @override
  List<Object?> get props => [session, cashSales, cashExpenses, expectedAmount, paymentBreakdown];

  bool get isOpen => session != null;
}
