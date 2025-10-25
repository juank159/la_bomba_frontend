import '../../domain/entities/notification.dart';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.message,
    required super.isRead,
    super.productId,
    super.relatedTaskId,
    super.temporaryProductId,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['isRead'] as bool,
      productId: json['productId'] as String?,
      relatedTaskId: json['relatedTaskId'] as String?,
      temporaryProductId: json['temporaryProductId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'isRead': isRead,
      'productId': productId,
      'relatedTaskId': relatedTaskId,
      'temporaryProductId': temporaryProductId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Notification toEntity() {
    return Notification(
      id: id,
      type: type,
      title: title,
      message: message,
      isRead: isRead,
      productId: productId,
      relatedTaskId: relatedTaskId,
      temporaryProductId: temporaryProductId,
      createdAt: createdAt,
    );
  }
}
