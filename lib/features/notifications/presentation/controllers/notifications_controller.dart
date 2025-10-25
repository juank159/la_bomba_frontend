import 'package:get/get.dart';
import 'dart:async';
import '../../domain/entities/notification.dart';
import '../../data/repositories/notifications_repository_impl.dart';

class NotificationsController extends GetxController {
  final NotificationsRepositoryImpl repository;

  NotificationsController({required this.repository});

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxList<Notification> notifications = <Notification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxString errorMessage = ''.obs;

  // Timer para polling de notificaciones
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    startPolling();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  /// Inicia el polling para actualizar el contador cada 60 segundos
  /// Optimizado para no sobrecargar el servidor
  void startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      // Solo actualizar el contador, no todas las notificaciones
      loadUnreadCount();
    });
  }

  /// Refresca completamente las notificaciones (pull-to-refresh)
  Future<void> refreshNotifications() async {
    await loadNotifications();
  }

  /// Carga todas las notificaciones
  Future<void> loadNotifications() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await repository.getNotifications();

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
          );
        },
        (notificationsList) {
          notifications.assignAll(notificationsList);
          // Actualizar contador de no leídas
          unreadCount.value = notificationsList.where((n) => !n.isRead).length;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Carga solo el contador de notificaciones no leídas
  Future<void> loadUnreadCount() async {
    try {
      final result = await repository.getUnreadCount();

      result.fold(
        (failure) {
          // No mostramos error para no molestar al usuario
          print('Error al cargar contador: ${failure.message}');
        },
        (count) {
          unreadCount.value = count;
        },
      );
    } catch (e) {
      print('Error inesperado al cargar contador: $e');
    }
  }

  /// Marca una notificación como leída
  Future<void> markAsRead(String id) async {
    try {
      final result = await repository.markAsRead(id);

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
          );
        },
        (_) {
          // Actualizar localmente
          final index = notifications.indexWhere((n) => n.id == id);
          if (index != -1) {
            final notification = notifications[index];
            notifications[index] = Notification(
              id: notification.id,
              type: notification.type,
              title: notification.title,
              message: notification.message,
              isRead: true,
              productId: notification.productId,
              relatedTaskId: notification.relatedTaskId,
              createdAt: notification.createdAt,
            );

            // Actualizar contador
            unreadCount.value = notifications.where((n) => !n.isRead).length;
          }
        },
      );
    } catch (e) {
      print('Error al marcar como leída: $e');
    }
  }

  /// Marca todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    try {
      final result = await repository.markAllAsRead();

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
          );
        },
        (_) {
          // Actualizar localmente
          notifications.value = notifications.map((n) {
            return Notification(
              id: n.id,
              type: n.type,
              title: n.title,
              message: n.message,
              isRead: true,
              productId: n.productId,
              relatedTaskId: n.relatedTaskId,
              createdAt: n.createdAt,
            );
          }).toList();

          unreadCount.value = 0;

          Get.snackbar(
            'Éxito',
            'Todas las notificaciones marcadas como leídas',
            snackPosition: SnackPosition.TOP,
          );
        },
      );
    } catch (e) {
      print('Error al marcar todas como leídas: $e');
    }
  }

  /// Elimina una notificación
  Future<void> deleteNotification(String id) async {
    try {
      final result = await repository.deleteNotification(id);

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
          );
        },
        (_) {
          // Remover localmente
          final notification = notifications.firstWhere((n) => n.id == id);
          notifications.removeWhere((n) => n.id == id);

          // Actualizar contador si era no leída
          if (!notification.isRead) {
            unreadCount.value = notifications.where((n) => !n.isRead).length;
          }
        },
      );
    } catch (e) {
      print('Error al eliminar notificación: $e');
    }
  }

  /// Obtiene las notificaciones no leídas
  List<Notification> get unreadNotifications {
    return notifications.where((n) => !n.isRead).toList();
  }

  /// Verifica si hay notificaciones no leídas
  bool get hasUnreadNotifications {
    return unreadCount.value > 0;
  }

  /// Elimina todas las notificaciones leídas
  Future<void> deleteReadNotifications() async {
    try {
      final result = await repository.deleteReadNotifications();

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
          );
        },
        (deletedCount) {
          // Remover localmente
          notifications.removeWhere((n) => n.isRead);

          Get.snackbar(
            'Éxito',
            '$deletedCount notificaciones eliminadas',
            snackPosition: SnackPosition.TOP,
          );
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al eliminar notificaciones: $e',
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}
