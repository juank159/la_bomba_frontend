import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../domain/entities/order.dart';

/// Status badge widget for displaying order status with appropriate colors
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool isLarge;
  final bool showIcon;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isLarge = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? AppConfig.paddingMedium : AppConfig.paddingSmall,
        vertical: isLarge ? AppConfig.paddingSmall : AppConfig.paddingSmall / 2,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(
          isLarge ? AppConfig.borderRadius : AppConfig.borderRadius / 2,
        ),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getIcon(),
              size: isLarge ? 16 : 12,
              color: _getTextColor(),
            ),
            SizedBox(width: isLarge ? 6 : 4),
          ],
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: isLarge ? AppConfig.captionFontSize : AppConfig.smallFontSize,
              fontWeight: FontWeight.w600,
              color: _getTextColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (status) {
      case OrderStatus.pending:
        return AppConfig.warningColor.withOpacity(0.1);
      case OrderStatus.completed:
        return AppConfig.successColor.withOpacity(0.1);
    }
  }

  Color _getBorderColor() {
    switch (status) {
      case OrderStatus.pending:
        return AppConfig.warningColor.withOpacity(0.3);
      case OrderStatus.completed:
        return AppConfig.successColor.withOpacity(0.3);
    }
  }

  Color _getTextColor() {
    switch (status) {
      case OrderStatus.pending:
        return AppConfig.warningColor;
      case OrderStatus.completed:
        return AppConfig.successColor;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case OrderStatus.pending:
        return Icons.access_time;
      case OrderStatus.completed:
        return Icons.check_circle;
    }
  }
}