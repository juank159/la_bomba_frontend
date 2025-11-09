import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/product_update_task_model.dart';
import '../../domain/entities/product_update_task.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/dio_client.dart';

abstract class SupervisorRemoteDataSource {
  Future<List<ProductUpdateTaskModel>> getPendingTasks();
  Future<List<ProductUpdateTaskModel>> getCompletedTasks();
  Future<ProductUpdateTaskModel> completeTask(String taskId, String? notes);
  Future<TaskStatsModel> getTaskStats();
  Future<ProductUpdateTaskModel> createTask({
    required String productId,
    required ChangeType changeType,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? description,
    String? adminNotes,
  });
}

class SupervisorRemoteDataSourceImpl implements SupervisorRemoteDataSource {
  final DioClient dioClient;

  SupervisorRemoteDataSourceImpl({
    required this.dioClient,
  });

  @override
  Future<List<ProductUpdateTaskModel>> getPendingTasks() async {
    try {
      final response = await dioClient.get('/product-update-tasks/pending');

      final List<dynamic> jsonList = response.data is List
          ? response.data
          : json.decode(response.data);

      return jsonList
          .map((json) => ProductUpdateTaskModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const ServerException('Unauthorized');
      }
      throw ServerException('Failed to get pending tasks: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get pending tasks: $e');
    }
  }

  @override
  Future<List<ProductUpdateTaskModel>> getCompletedTasks() async {
    try {
      final response = await dioClient.get('/product-update-tasks/completed');

      final List<dynamic> jsonList = response.data is List
          ? response.data
          : json.decode(response.data);

      return jsonList
          .map((json) => ProductUpdateTaskModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const ServerException('Unauthorized');
      }
      throw ServerException('Failed to get completed tasks: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get completed tasks: $e');
    }
  }

  @override
  Future<ProductUpdateTaskModel> completeTask(String taskId, String? notes) async {
    try {
      final body = notes != null ? {'notes': notes} : <String, dynamic>{};

      final response = await dioClient.patch(
        '/product-update-tasks/$taskId/complete',
        data: body,
      );

      return ProductUpdateTaskModel.fromJson(
        response.data is Map ? response.data : json.decode(response.data),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const ServerException('Unauthorized');
      } else if (e.response?.statusCode == 404) {
        throw const ServerException('Task not found');
      }
      throw ServerException('Failed to complete task: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to complete task: $e');
    }
  }

  @override
  Future<TaskStatsModel> getTaskStats() async {
    try {
      final response = await dioClient.get('/product-update-tasks/stats');

      return TaskStatsModel.fromJson(
        response.data is Map ? response.data : json.decode(response.data),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const ServerException('Unauthorized');
      }
      throw ServerException('Failed to get task stats: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get task stats: $e');
    }
  }

  @override
  Future<ProductUpdateTaskModel> createTask({
    required String productId,
    required ChangeType changeType,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? description,
    String? adminNotes,
  }) async {
    try {
      final body = {
        'productId': productId,
        'changeType': changeType.value,
        if (oldValue != null) 'oldValue': oldValue,
        if (newValue != null) 'newValue': newValue,
        if (description != null) 'description': description,
        if (adminNotes != null) 'adminNotes': adminNotes,
      };

      final response = await dioClient.post(
        '/product-update-tasks',
        data: body,
      );

      return ProductUpdateTaskModel.fromJson(
        response.data is Map ? response.data : json.decode(response.data),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const ServerException('Unauthorized');
      }
      throw ServerException('Failed to create task: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to create task: $e');
    }
  }
}