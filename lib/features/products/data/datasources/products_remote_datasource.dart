//library: frontend/lib/features/products/data/datasources/products_remote_datasource.dart
import 'package:dio/dio.dart';

import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/config/api_config.dart';
import '../models/product_model.dart';

/// Abstract class defining the contract for products remote data source
abstract class ProductsRemoteDataSource {
  /// Get all products with optional pagination and search
  Future<List<ProductModel>> getAllProducts({
    int page = 0,
    int limit = 20,
    String? search,
  });

  /// Get a specific product by its ID
  Future<ProductModel> getProductById(String id);

  /// Search products by description or barcode
  Future<List<ProductModel>> searchProducts(
    String query, {
    int page = 0,
    int limit = 20,
  });

  /// Get total count of products
  Future<int> getProductsCount({String? search});

  /// Check if a product with the given barcode exists
  Future<bool> productExistsByBarcode(String barcode);

  /// Update a product's information
  Future<ProductModel> updateProduct(
    String id,
    Map<String, dynamic> updatedData,
  );

  /// Create a new product
  Future<ProductModel> createProduct(Map<String, dynamic> productData);

  /// Create a new product with supervisor task
  Future<Map<String, dynamic>> createProductWithSupervisorTask(Map<String, dynamic> productData);

  /// Create a temporary product
  Future<Map<String, dynamic>> createTemporaryProduct(Map<String, dynamic> temporaryProductData);

  /// Get all temporary products
  Future<List<Map<String, dynamic>>> getAllTemporaryProducts();

  /// Get temporary product by ID
  Future<Map<String, dynamic>> getTemporaryProductById(String id);

  /// Update temporary product
  Future<Map<String, dynamic>> updateTemporaryProduct(String id, Map<String, dynamic> updateData);

  /// Cancel temporary product
  Future<Map<String, dynamic>> cancelTemporaryProduct(String id, {String? reason});

  /// Complete temporary product by supervisor
  Future<Map<String, dynamic>> completeTemporaryProductBySupervisor(String id, {String? notes, String? barcode});

  /// Update barcode of existing product from temporary product
  Future<Map<String, dynamic>> updateProductBarcodeFromTemporary(String temporaryProductId, String barcode, {String? notes});

  /// Update barcode directly in products table (for real products created by admin)
  Future<Map<String, dynamic>> updateProductBarcode(String productId, String barcode);
}

/// Implementation of ProductsRemoteDataSource using Dio HTTP client
class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  final DioClient dioClient;

  ProductsRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<ProductModel>> getAllProducts({
    int page = 0,
    int limit = 20,
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      final response = await dioClient.get(
        ApiConfig.productsEndpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different response formats
        List<dynamic> productsData;
        if (responseData is Map<String, dynamic>) {
          // If response has pagination metadata
          if (responseData.containsKey('data')) {
            productsData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('products')) {
            productsData = responseData['products'] as List<dynamic>;
          } else {
            // Assume the map itself contains product data
            productsData = [responseData];
          }
        } else if (responseData is List<dynamic>) {
          productsData = responseData;
        } else {
          throw ParseException('Formato de respuesta inválido');
        }

        return productsData
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Error al obtener productos: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(e, 'Error al obtener productos');
    } catch (e) {
      throw ServerException('Error inesperado al obtener productos: $e');
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw ValidationException('El ID del producto es requerido');
      }

      final response = await dioClient.get(
        '${ApiConfig.productsEndpoint}/by-id/$id',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return ProductModel.fromJson(responseData);
        } else {
          throw ParseException(
            'Formato de respuesta inválido para producto individual',
          );
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Producto con ID $id no encontrado');
      } else {
        throw ServerException(
          'Error al obtener producto: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Producto con ID $id no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al obtener producto');
    } catch (e) {
      throw ServerException('Error inesperado al obtener producto: $e');
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(
    String query, {
    int page = 0,
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        throw ValidationException('La consulta de búsqueda es requerida');
      }

      final response = await dioClient.get(
        '${ApiConfig.productsEndpoint}',
        queryParameters: {'search': query.trim(), 'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different response formats
        List<dynamic> productsData;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            productsData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('results')) {
            productsData = responseData['results'] as List<dynamic>;
          } else {
            productsData = [responseData];
          }
        } else if (responseData is List<dynamic>) {
          productsData = responseData;
        } else {
          throw ParseException('Formato de respuesta inválido para búsqueda');
        }

        return productsData
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Error en la búsqueda de productos: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(
        e,
        'Error en la búsqueda de productos',
      );
    } catch (e) {
      throw ServerException('Error inesperado en la búsqueda de productos: $e');
    }
  }

  @override
  Future<int> getProductsCount({String? search}) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      final response = await dioClient.get(
        '${ApiConfig.productsEndpoint}/count',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return responseData['count'] as int? ??
              responseData['total'] as int? ??
              0;
        } else if (responseData is int) {
          return responseData;
        } else {
          throw ParseException('Formato de respuesta inválido para conteo');
        }
      } else {
        throw ServerException(
          'Error al obtener conteo de productos: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(
        e,
        'Error al obtener conteo de productos',
      );
    } catch (e) {
      throw ServerException('Error inesperado al obtener conteo: $e');
    }
  }

  @override
  Future<bool> productExistsByBarcode(String barcode) async {
    try {
      if (barcode.trim().isEmpty) {
        throw ValidationException('El código de barras es requerido');
      }

      final response = await dioClient.get(
        '${ApiConfig.productsEndpoint}/exists',
        queryParameters: {'barcode': barcode.trim()},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return responseData['exists'] as bool? ?? false;
        } else if (responseData is bool) {
          return responseData;
        } else {
          return false;
        }
      } else if (response.statusCode == 404) {
        return false;
      } else {
        throw ServerException(
          'Error al verificar código de barras: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return false;
      }
      throw _mapDioExceptionToServerException(
        e,
        'Error al verificar código de barras',
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al verificar código de barras: $e',
      );
    }
  }

  @override
  Future<ProductModel> updateProduct(
    String id,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      print('🚀 UpdateProduct DataSource: ID=$id, Data=$updatedData');
      print('🔍 DATASOURCE: updatedData keys: ${updatedData.keys.toList()}');
      print(
        '🔍 DATASOURCE: updatedData values: ${updatedData.values.toList()}',
      );
      print('🔍 DATASOURCE: Contains IVA? ${updatedData.containsKey("iva")}');
      if (updatedData.containsKey("iva")) {
        print('🔍 DATASOURCE: IVA value: ${updatedData["iva"]}');
      }

      if (id.trim().isEmpty) {
        throw ValidationException('El ID del producto es requerido');
      }

      if (updatedData.isEmpty) {
        throw ValidationException('Los datos de actualización son requeridos');
      }

      final url = '${ApiConfig.productsEndpoint}/by-id/$id';
      print('🚀 Making PATCH request to: $url');
      print('🔍 DATASOURCE: Request body being sent to Dio: $updatedData');

      final response = await dioClient.patch(url, data: updatedData);

      print('🚀 Response received: status=${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        print('🔍 DATASOURCE: Raw response data: $responseData');
        print('🔍 DATASOURCE: Response data type: ${responseData.runtimeType}');

        if (responseData is Map<String, dynamic>) {
          print('🔍 DATASOURCE: IVA in response: ${responseData['iva']}');
          print(
            '🔍 DATASOURCE: All fields in response: ${responseData.keys.toList()}',
          );
          print(
            '✅ DataSource: Update successful, calling ProductModel.fromJson',
          );
          return ProductModel.fromJson(responseData);
        } else {
          throw ParseException(
            'Formato de respuesta inválido para actualización de producto',
          );
        }
      } else if (response.statusCode == 404) {
        print('❌ DataSource UPDATE: Response 404 - Producto no encontrado');
        throw NotFoundException(
          '❌ DATASOURCE UPDATE 404: Producto con ID $id no encontrado',
        );
      } else {
        throw ServerException(
          'Error al actualizar producto: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      print(
        '❌ DataSource: DioException caught - Status: ${e.response?.statusCode}',
      );
      if (e.response?.statusCode == 404) {
        print('❌ DataSource UPDATE: DioException 404 - Producto no encontrado');
        throw NotFoundException(
          '❌ DATASOURCE UPDATE DIOEXCEPTION 404: Producto con ID $id no encontrado',
        );
      }
      throw _mapDioExceptionToServerException(
        e,
        'Error al actualizar producto',
      );
    } catch (e) {
      throw ServerException('Error inesperado al actualizar producto: $e');
    }
  }

  @override
  Future<ProductModel> createProduct(Map<String, dynamic> productData) async {
    try {
      print('🚀 CreateProduct DataSource: Data=$productData');

      if (productData.isEmpty) {
        throw ValidationException('Los datos del producto son requeridos');
      }

      if (!productData.containsKey('description') || (productData['description'] as String).trim().isEmpty) {
        throw ValidationException('La descripción del producto es requerida');
      }

      if (!productData.containsKey('barcode')) {
        throw ValidationException('El código de barras es requerido');
      }

      if (!productData.containsKey('precioA')) {
        throw ValidationException('El precio del producto es requerido');
      }

      final url = ApiConfig.productsEndpoint;
      print('🚀 Making POST request to: $url');
      print('🔍 DATASOURCE: Request body being sent to Dio: $productData');

      final response = await dioClient.post(url, data: productData);

      print('🚀 Response received: status=${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;

        print('🔍 DATASOURCE: Raw response data: $responseData');
        print('🔍 DATASOURCE: Response data type: ${responseData.runtimeType}');

        if (responseData is Map<String, dynamic>) {
          print('✅ DataSource: Create successful, calling ProductModel.fromJson');
          return ProductModel.fromJson(responseData);
        } else {
          throw ParseException(
            'Formato de respuesta inválido para creación de producto',
          );
        }
      } else {
        throw ServerException(
          'Error al crear producto: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      print(
        '❌ DataSource: DioException caught - Status: ${e.response?.statusCode}',
      );
      throw _mapDioExceptionToServerException(
        e,
        'Error al crear producto',
      );
    } catch (e) {
      throw ServerException('Error inesperado al crear producto: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> createProductWithSupervisorTask(Map<String, dynamic> productData) async {
    try {
      print('🎯 CreateProductWithSupervisorTask DataSource: Data=$productData');

      if (productData.isEmpty) {
        throw ValidationException('Los datos del producto son requeridos');
      }

      if (!productData.containsKey('description') || (productData['description'] as String).trim().isEmpty) {
        throw ValidationException('La descripción del producto es requerida');
      }

      if (!productData.containsKey('precioA')) {
        throw ValidationException('El precio del producto es requerido');
      }

      if (!productData.containsKey('iva')) {
        throw ValidationException('El IVA es requerido');
      }

      final url = '${ApiConfig.productsEndpoint}/with-supervisor-task';
      print('🚀 Making POST request to: $url');
      print('🔍 DATASOURCE: Request body being sent: $productData');

      final response = await dioClient.post(url, data: productData);

      print('🚀 Response received: status=${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;

        print('🔍 DATASOURCE: Raw response data: $responseData');
        print('✅ DataSource: Product with supervisor task created successfully');

        if (responseData is Map<String, dynamic>) {
          return responseData;
        }

        throw ServerException('Respuesta del servidor en formato inválido');
      }

      throw ServerException(
        'Error al crear producto con tarea de supervisor: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(
        e,
        'Error al crear producto con tarea de supervisor',
      );
    } catch (e) {
      throw ServerException('Error inesperado al crear producto con tarea de supervisor: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> createTemporaryProduct(Map<String, dynamic> temporaryProductData) async {
    try {
      print('🚀 CreateTemporaryProduct DataSource: Data=$temporaryProductData');

      if (temporaryProductData.isEmpty) {
        throw ValidationException('Los datos del producto temporal son requeridos');
      }

      if (!temporaryProductData.containsKey('name') || (temporaryProductData['name'] as String).trim().isEmpty) {
        throw ValidationException('El nombre del producto es requerido');
      }

      if (!temporaryProductData.containsKey('createdBy')) {
        throw ValidationException('El ID del usuario es requerido');
      }

      final url = '${ApiConfig.productsEndpoint}/temporary';
      print('🚀 Making POST request to: $url');
      print('🔍 DATASOURCE: Request body being sent to Dio: $temporaryProductData');

      final response = await dioClient.post(url, data: temporaryProductData);

      print('🚀 Response received: status=${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;

        print('🔍 DATASOURCE: Raw response data: $responseData');
        print('🔍 DATASOURCE: Response data type: ${responseData.runtimeType}');

        if (responseData is Map<String, dynamic>) {
          print('✅ DataSource: Create temporary product successful');
          return responseData;
        } else {
          throw ParseException(
            'Formato de respuesta inválido para creación de producto temporal',
          );
        }
      } else {
        throw ServerException(
          'Error al crear producto temporal: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      print(
        '❌ DataSource: DioException caught - Status: ${e.response?.statusCode}',
      );
      throw _mapDioExceptionToServerException(
        e,
        'Error al crear producto temporal',
      );
    } catch (e) {
      throw ServerException('Error inesperado al crear producto temporal: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllTemporaryProducts() async {
    try {
      final response = await dioClient.get('${ApiConfig.productsEndpoint}/temporary');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is List) {
          return List<Map<String, dynamic>>.from(responseData);
        } else {
          throw ParseException('Formato de respuesta inválido');
        }
      } else {
        throw ServerException(
          'Error al obtener productos temporales: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(e, 'Error al obtener productos temporales');
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getTemporaryProductById(String id) async {
    try {
      final response = await dioClient.get('${ApiConfig.productsEndpoint}/temporary/$id');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return responseData;
        } else {
          throw ParseException('Formato de respuesta inválido');
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Producto temporal no encontrado');
      } else {
        throw ServerException(
          'Error al obtener producto temporal: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Producto temporal no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al obtener producto temporal');
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> updateTemporaryProduct(String id, Map<String, dynamic> updateData) async {
    try {
      final response = await dioClient.patch(
        '${ApiConfig.productsEndpoint}/temporary/$id',
        data: updateData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return responseData;
        } else {
          throw ParseException('Formato de respuesta inválido');
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Producto temporal no encontrado');
      } else {
        throw ServerException(
          'Error al actualizar producto temporal: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Producto temporal no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al actualizar producto temporal');
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> cancelTemporaryProduct(String id, {String? reason}) async {
    try {
      final response = await dioClient.post(
        '${ApiConfig.productsEndpoint}/temporary/$id/cancel',
        data: {'reason': reason},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return responseData;
        } else {
          throw ParseException('Formato de respuesta inválido');
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Producto temporal no encontrado');
      } else {
        throw ServerException(
          'Error al cancelar producto temporal: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Producto temporal no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al cancelar producto temporal');
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> completeTemporaryProductBySupervisor(String id, {String? notes, String? barcode}) async {
    try {
      // Build request body with optional fields
      final requestData = <String, dynamic>{
        'notes': notes,
      };

      // Only include barcode if provided
      if (barcode != null && barcode.trim().isNotEmpty) {
        requestData['barcode'] = barcode.trim();
      }

      print('🚀 CompleteTemporaryProductBySupervisor DataSource: ID=$id, Data=$requestData');

      final response = await dioClient.post(
        '${ApiConfig.productsEndpoint}/temporary/$id/complete-supervisor',
        data: requestData,
      );

      print('🚀 Response received: status=${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          print('✅ DataSource: Temporary product completed successfully');
          return responseData;
        } else {
          throw ParseException('Formato de respuesta inválido');
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Producto temporal no encontrado');
      } else {
        throw ServerException(
          'Error al completar producto temporal: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      print('❌ DataSource: DioException caught - Status: ${e.response?.statusCode}');
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Producto temporal no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al completar producto temporal');
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> updateProductBarcodeFromTemporary(String temporaryProductId, String barcode, {String? notes}) async {
    try {
      // Build request body
      final requestData = <String, dynamic>{
        'barcode': barcode.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      print('🚀 UpdateProductBarcodeFromTemporary DataSource: ID=$temporaryProductId, Data=$requestData');

      final response = await dioClient.post(
        '${ApiConfig.productsEndpoint}/temporary/$temporaryProductId/update-barcode',
        data: requestData,
      );

      print('🚀 Response received: status=${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          print('✅ DataSource: Product barcode updated successfully');
          return responseData;
        } else {
          throw ParseException('Formato de respuesta inválido');
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Producto temporal o producto no encontrado');
      } else {
        throw ServerException(
          'Error al actualizar código de barras: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      print('❌ DataSource: DioException caught - Status: ${e.response?.statusCode}');
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Producto temporal o producto no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al actualizar código de barras');
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  /// Update barcode directly in products table (for real products, not temporary)
  Future<Map<String, dynamic>> updateProductBarcode(String productId, String barcode) async {
    try {
      print('🚀 UpdateProductBarcode DataSource: ProductID=$productId, Barcode=$barcode');

      final response = await dioClient.patch(
        '${ApiConfig.productsEndpoint}/by-id/$productId/barcode',
        data: {'barcode': barcode.trim()},
      );

      print('🚀 Response received: status=${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          print('✅ DataSource: Product barcode updated successfully');
          return responseData;
        } else {
          throw ParseException('Formato de respuesta inválido');
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Producto no encontrado');
      } else {
        throw ServerException(
          'Error al actualizar código de barras: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      print('❌ DataSource: DioException caught - Status: ${e.response?.statusCode}');
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Producto no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al actualizar código de barras');
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  /// Helper method to map DioException to ServerException
  ServerException _mapDioExceptionToServerException(
    DioException dioException,
    String contextMessage,
  ) {
    final statusCode = dioException.response?.statusCode ?? 0;
    final errorMessage =
        dioException.response?.data?['message'] as String? ??
        dioException.message ??
        contextMessage;

    switch (statusCode) {
      case 400:
        return BadRequestException(errorMessage);
      case 401:
        return UnauthorizedException(errorMessage);
      case 403:
        return ForbiddenException(errorMessage);
      case 404:
        return NotFoundException(errorMessage);
      case 409:
        return ConflictException(errorMessage);
      case 422:
        return ValidationException(errorMessage);
      case 500:
        return InternalServerException(errorMessage);
      case 502:
        return BadGatewayException(errorMessage);
      case 503:
        return ServiceUnavailableException(errorMessage);
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return ClientException(errorMessage, statusCode: statusCode);
        } else if (statusCode >= 500) {
          return ServerException(errorMessage, statusCode: statusCode);
        } else {
          return ServerException(
            '$contextMessage: $errorMessage',
            statusCode: statusCode,
          );
        }
    }
  }
}
