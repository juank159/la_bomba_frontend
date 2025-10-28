class Notification {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? productId;
  final String? relatedTaskId;
  final String? temporaryProductId;
  final String? creditId;
  final DateTime createdAt;

  const Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.productId,
    this.relatedTaskId,
    this.temporaryProductId,
    this.creditId,
    required this.createdAt,
  });
}
