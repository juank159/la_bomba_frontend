import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../app/config/app_config.dart';
import '../controllers/notifications_controller.dart';
import '../../../products/presentation/pages/product_detail_page.dart';

/// Helper functions para notificaciones

String _formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 7) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  } else if (difference.inDays > 0) {
    return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
  } else if (difference.inHours > 0) {
    return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
  } else if (difference.inMinutes > 0) {
    return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
  } else {
    return 'Ahora';
  }
}

IconData _getNotificationIcon(dynamic notification) {
  final message = notification.message.toLowerCase();

  if (message.contains('precio')) {
    return Icons.attach_money;
  } else if (message.contains('información')) {
    return Icons.info_outline;
  } else if (message.contains('iva')) {
    return Icons.receipt_long;
  } else {
    return Icons.task_alt;
  }
}

Color _getNotificationColor(BuildContext context, dynamic notification) {
  final message = notification.message.toLowerCase();

  if (message.contains('precio')) {
    return Colors.green;
  } else if (message.contains('información')) {
    return Colors.blue;
  } else if (message.contains('iva')) {
    return Colors.orange;
  } else {
    return Theme.of(context).colorScheme.primary;
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          // Botón para marcar todas como leídas
          Obx(() {
            if (controller.hasUnreadNotifications) {
              return TextButton(
                onPressed: controller.markAllAsRead,
                child: const Text('Marcar leídas'),
              );
            }
            return const SizedBox.shrink();
          }),
          // Menú con más opciones
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_read') {
                _showDeleteReadConfirmation(context, controller);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_read',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep),
                    SizedBox(width: 8),
                    Text('Eliminar leídas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No tienes notificaciones',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshNotifications,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppConfig.paddingMedium),
            itemCount: controller.notifications.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return _NotificationCard(
                notification: notification,
                onTap: () {
                  _showNotificationDetails(context, controller, notification);
                },
                onDelete: () {
                  _showDeleteConfirmation(context, controller, notification.id);
                },
              );
            },
          ),
        );
      }),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    NotificationsController controller,
    String notificationId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar notificación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta notificación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteNotification(notificationId);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteReadConfirmation(
    BuildContext context,
    NotificationsController controller,
  ) {
    final readCount = controller.notifications.where((n) => n.isRead).length;

    if (readCount == 0) {
      Get.snackbar(
        'Sin notificaciones',
        'No hay notificaciones leídas para eliminar',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar notificaciones leídas'),
        content: Text('¿Estás seguro de que quieres eliminar las $readCount notificaciones leídas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteReadNotifications();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetails(
    BuildContext context,
    NotificationsController controller,
    dynamic notification,
  ) {
    // Marcar como leída al abrir el diálogo
    if (!notification.isRead) {
      controller.markAsRead(notification.id);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getNotificationIcon(notification),
              color: _getNotificationColor(context, notification),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeAgo(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (notification.productId != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Get.to(() => ProductDetailPage(
                      productId: notification.productId,
                    ));
              },
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Ver producto'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final dynamic notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar notificación'),
            content: const Text('¿Estás seguro de que quieres eliminar esta notificación?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        onDelete();
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Container(
          padding: const EdgeInsets.all(AppConfig.paddingMedium),
          decoration: BoxDecoration(
            color: isUnread
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            border: Border.all(
              color: isUnread
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono dinámico según el tipo de notificación
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getNotificationColor(context, notification).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getNotificationColor(context, notification).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getNotificationIcon(notification),
                  color: _getNotificationColor(context, notification),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NUEVO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
