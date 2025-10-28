// lib/features/credits/data/models/refund_history_model.dart

import '../../domain/entities/refund_history.dart';

class RefundHistoryModel extends RefundHistory {
  RefundHistoryModel({
    required super.id,
    required super.type,
    required super.amount,
    required super.description,
    required super.balanceAfter,
    super.paymentMethodId,
    super.paymentMethod,
    super.clientId,
    required super.clientName,
    super.clientPhone,
    required super.createdBy,
    required super.createdAt,
  });

  factory RefundHistoryModel.fromJson(Map<String, dynamic> json) {
    return RefundHistoryModel(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      paymentMethodId: json['paymentMethodId'] as String?,
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethodInfoModel.fromJson(
              json['paymentMethod'] as Map<String, dynamic>)
          : null,
      clientId: json['clientId'] as String?,
      clientName: json['clientName'] as String? ?? 'Desconocido',
      clientPhone: json['clientPhone'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'balanceAfter': balanceAfter,
      'paymentMethodId': paymentMethodId,
      'paymentMethod': paymentMethod != null
          ? {
              'id': paymentMethod!.id,
              'name': paymentMethod!.name,
              'icon': paymentMethod!.icon,
            }
          : null,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PaymentMethodInfoModel extends PaymentMethodInfo {
  PaymentMethodInfoModel({
    required super.id,
    required super.name,
    super.icon,
  });

  factory PaymentMethodInfoModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfoModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
    );
  }
}
