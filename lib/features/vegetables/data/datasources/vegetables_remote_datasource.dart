import 'package:dio/dio.dart';

import '../../../../app/config/api_config.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/repositories/vegetables_repository.dart';
import '../models/vegetable_category_model.dart';
import '../models/vegetable_item_model.dart';
import '../models/vegetable_sale_model.dart';

abstract class VegetablesRemoteDataSource {
  Future<List<VegetableCategoryModel>> getCategories({bool includeInactive = false});
  Future<VegetableCategoryModel> createCategory(VegetableCategoryParams params);
  Future<VegetableCategoryModel> updateCategory(String id, VegetableCategoryParams params);
  Future<void> deleteCategory(String id);

  Future<List<VegetableItemModel>> getItems({bool includeInactive = false});
  Future<VegetableItemModel> createItem(VegetableItemParams params);
  Future<VegetableItemModel> updateItem(String id, VegetableItemParams params);
  Future<void> deleteItem(String id);

  Future<VegetableSaleModel> createSale(List<CreateVegetableSaleItemParams> items);
  Future<List<VegetableSaleModel>> getSales();
  Future<VegetableSaleModel> getSaleById(String id);
}

class VegetablesRemoteDataSourceImpl implements VegetablesRemoteDataSource {
  final DioClient dioClient;

  VegetablesRemoteDataSourceImpl(this.dioClient);

  Map<String, dynamic> _itemJson(VegetableItemParams params) {
    return {
      'name': params.name,
      if (params.categoryId != null && params.categoryId!.isNotEmpty) 'categoryId': params.categoryId,
      'pricingType': params.pricingType.value,
      if (params.pricingType.isWeight) 'pricePerKg': params.pricePerKg,
      if (params.pricingType.isFixed) 'fixedPrice': params.fixedPrice,
    };
  }

  @override
  Future<List<VegetableCategoryModel>> getCategories({bool includeInactive = false}) async {
    try {
      final response = await dioClient.get(
        '${ApiConfig.vegetablesEndpoint}/categories',
        queryParameters: {if (includeInactive) 'includeInactive': 'true'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => VegetableCategoryModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw ServerException('Error del servidor al obtener las categorías', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener las categorías');
    } catch (e) {
      throw ServerException('Error inesperado al obtener las categorías: ${e.toString()}');
    }
  }

  @override
  Future<VegetableCategoryModel> createCategory(VegetableCategoryParams params) async {
    try {
      final response = await dioClient.post(
        '${ApiConfig.vegetablesEndpoint}/categories',
        data: {'name': params.name},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return VegetableCategoryModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Error del servidor al crear la categoría', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'crear la categoría');
    } catch (e) {
      throw ServerException('Error inesperado al crear la categoría: ${e.toString()}');
    }
  }

  @override
  Future<VegetableCategoryModel> updateCategory(String id, VegetableCategoryParams params) async {
    try {
      final response = await dioClient.patch(
        '${ApiConfig.vegetablesEndpoint}/categories/$id',
        data: {'name': params.name},
      );

      if (response.statusCode == 200) {
        return VegetableCategoryModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Error del servidor al actualizar la categoría', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'actualizar la categoría');
    } catch (e) {
      throw ServerException('Error inesperado al actualizar la categoría: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      final response = await dioClient.delete('${ApiConfig.vegetablesEndpoint}/categories/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Error del servidor al eliminar la categoría', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'eliminar la categoría');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar la categoría: ${e.toString()}');
    }
  }

  @override
  Future<List<VegetableItemModel>> getItems({bool includeInactive = false}) async {
    try {
      final response = await dioClient.get(
        '${ApiConfig.vegetablesEndpoint}/items',
        queryParameters: {if (includeInactive) 'includeInactive': 'true'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => VegetableItemModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw ServerException('Error del servidor al obtener el catálogo de verduras', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener el catálogo de verduras');
    } catch (e) {
      throw ServerException('Error inesperado al obtener el catálogo de verduras: ${e.toString()}');
    }
  }

  @override
  Future<VegetableItemModel> createItem(VegetableItemParams params) async {
    try {
      final response = await dioClient.post('${ApiConfig.vegetablesEndpoint}/items', data: _itemJson(params));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return VegetableItemModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Error del servidor al crear el producto', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'crear el producto');
    } catch (e) {
      throw ServerException('Error inesperado al crear el producto: ${e.toString()}');
    }
  }

  @override
  Future<VegetableItemModel> updateItem(String id, VegetableItemParams params) async {
    try {
      final response = await dioClient.patch('${ApiConfig.vegetablesEndpoint}/items/$id', data: _itemJson(params));

      if (response.statusCode == 200) {
        return VegetableItemModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Error del servidor al actualizar el producto', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'actualizar el producto');
    } catch (e) {
      throw ServerException('Error inesperado al actualizar el producto: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    try {
      final response = await dioClient.delete('${ApiConfig.vegetablesEndpoint}/items/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Error del servidor al eliminar el producto', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'eliminar el producto');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar el producto: ${e.toString()}');
    }
  }

  @override
  Future<VegetableSaleModel> createSale(List<CreateVegetableSaleItemParams> items) async {
    try {
      final data = {
        'items': items
            .map((item) => {
                  'vegetableItemId': item.vegetableItemId,
                  if (item.weightKg != null) 'weightKg': item.weightKg,
                  if (item.quantity != null) 'quantity': item.quantity,
                })
            .toList(),
      };

      final response = await dioClient.post('${ApiConfig.vegetablesEndpoint}/sales', data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return VegetableSaleModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Error del servidor al registrar la venta', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'registrar la venta');
    } catch (e) {
      throw ServerException('Error inesperado al registrar la venta: ${e.toString()}');
    }
  }

  @override
  Future<List<VegetableSaleModel>> getSales() async {
    try {
      final response = await dioClient.get('${ApiConfig.vegetablesEndpoint}/sales');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => VegetableSaleModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw ServerException('Error del servidor al obtener las ventas', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener las ventas');
    } catch (e) {
      throw ServerException('Error inesperado al obtener las ventas: ${e.toString()}');
    }
  }

  @override
  Future<VegetableSaleModel> getSaleById(String id) async {
    try {
      final response = await dioClient.get('${ApiConfig.vegetablesEndpoint}/sales/$id');

      if (response.statusCode == 200) {
        return VegetableSaleModel.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Venta con ID $id no encontrada');
      }
      throw ServerException('Error del servidor al obtener la venta', statusCode: response.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Venta con ID $id no encontrada');
      }
      throw _handleDioException(e, 'obtener la venta');
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException('Error inesperado al obtener la venta: ${e.toString()}');
    }
  }

  Exception _handleDioException(DioException e, String operation) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Tiempo de espera agotado al $operation');

      case DioExceptionType.connectionError:
        return NetworkException('Error de conexión al $operation');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] as String? ??
            e.response?.data?['error'] as String? ??
            'Error del servidor';

        switch (statusCode) {
          case 400:
            return ValidationException('Datos inválidos: $message');
          case 401:
            return AuthException('No autorizado para $operation');
          case 403:
            return AuthException('No tiene permisos para $operation');
          case 404:
            return NotFoundException('Recurso no encontrado');
          case 409:
            return ConflictException(message);
          case 422:
            return ValidationException('Error de validación: $message');
          case 500:
            return ServerException('Error interno del servidor al $operation');
          default:
            return ServerException('Error del servidor al $operation: $message', statusCode: statusCode);
        }

      case DioExceptionType.cancel:
        return NetworkException('Operación cancelada al $operation');

      case DioExceptionType.badCertificate:
        return NetworkException('Error de certificado al $operation');

      case DioExceptionType.unknown:
      default:
        return NetworkException('Error de red desconocido al $operation: ${e.message}');
    }
  }
}
