import 'package:dio/dio.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<int> getUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<int> deleteReadNotifications();
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final DioClient dioClient;

  NotificationsRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await dioClient.get('/notifications');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Error al obtener notificaciones: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await dioClient.get('/notifications/unread-count');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['count'] as int;
      } else {
        throw ServerException(
          'Error al obtener contador: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      final response = await dioClient.patch('/notifications/$id/mark-as-read');

      if (response.statusCode != 200) {
        throw ServerException(
          'Error al marcar como leída: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final response = await dioClient.patch('/notifications/mark-all-as-read');

      if (response.statusCode != 200) {
        throw ServerException(
          'Error al marcar todas como leídas: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      final response = await dioClient.delete('/notifications/$id');

      if (response.statusCode != 200) {
        throw ServerException(
          'Error al eliminar notificación: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<int> deleteReadNotifications() async {
    try {
      final response = await dioClient.delete('/notifications/read/all');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['deletedCount'] as int;
      } else {
        throw ServerException(
          'Error al eliminar notificaciones leídas: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  ServerException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    final message = e.response?.data?['message'] as String? ?? e.message ?? 'Error de conexión';

    switch (statusCode) {
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      default:
        return ServerException(message, statusCode: statusCode);
    }
  }
}
