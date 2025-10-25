import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../storage/secure_storage.dart';
import '../errors/exceptions.dart';
import '../../config/api_config.dart';
import '../../config/app_config.dart';

/// HTTP client wrapper using Dio with authentication and error handling
class DioClient {
  late Dio _dio;
  final SecureStorage _secureStorage;
  final Logger _logger;

  DioClient(this._secureStorage) : _logger = Logger() {
    _dio = Dio();
    _configureDio();
    _setupInterceptors();
  }

  /// Configure Dio with base options
  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiConfig.sendTimeout),
      headers: {
        ApiConfig.contentTypeHeader: ApiConfig.jsonContentType,
        ApiConfig.acceptHeader: ApiConfig.jsonContentType,
      },
    );
  }

  /// Setup interceptors for authentication, logging, and error handling
  void _setupInterceptors() {
    // Auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // Logging interceptor (only in debug mode)
    if (AppConfig.isDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (object) {
            _logger.d(object.toString());
          },
        ),
      );
    }
  }

  /// Handle request interceptor - add authentication headers
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Add authorization header if token exists
      final accessToken = await _secureStorage.read('access_token');
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers[ApiConfig.authorizationHeader] = 
          '${ApiConfig.bearerPrefix}$accessToken';
        _logger.i('🔐 Adding auth token: ${accessToken.substring(0, 20)}...');
      } else {
        _logger.w('⚠️ No access token found');
      }

      _logger.i('REQUEST: ${options.method} ${options.path}');
      handler.next(options);
    } catch (e) {
      _logger.e('Error in request interceptor: $e');
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          message: 'Request interceptor error',
        ),
      );
    }
  }

  /// Handle response interceptor - log responses
  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.i('RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  /// Handle error interceptor - convert errors and handle token refresh
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    _logger.e('ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
    _logger.e('Error message: ${error.message}');

    // Handle unauthorized error (token expired)
    if (error.response?.statusCode == 401) {
      // Try to refresh token
      final refreshSuccess = await _tryRefreshToken();
      
      if (refreshSuccess) {
        // Retry the original request
        try {
          final clonedRequest = await _cloneRequest(error.requestOptions);
          final response = await _dio.fetch(clonedRequest);
          handler.resolve(response);
          return;
        } catch (e) {
          _logger.e('Failed to retry request after token refresh: $e');
        }
      } else {
        // Clear tokens and redirect to login
        await _secureStorage.clearAuthData();
      }
    }

    // Convert Dio errors to custom exceptions
    final customError = _mapDioErrorToException(error);
    final dioException = DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      error: customError,
      message: customError.message,
    );

    handler.next(dioException);
  }

  /// Try to refresh the authentication token
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await _dio.post(
        ApiConfig.refreshTokenEndpoint,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {
            ApiConfig.authorizationHeader: '${ApiConfig.bearerPrefix}$refreshToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newAccessToken != null) {
          await _secureStorage.saveAccessToken(newAccessToken);
          if (newRefreshToken != null) {
            await _secureStorage.saveRefreshToken(newRefreshToken);
          }
          return true;
        }
      }
    } catch (e) {
      _logger.e('Token refresh failed: $e');
    }

    return false;
  }

  /// Clone a request options for retry
  Future<RequestOptions> _cloneRequest(RequestOptions options) async {
    final accessToken = await _secureStorage.getAccessToken();
    
    return options.copyWith(
      headers: {
        ...options.headers,
        if (accessToken != null)
          ApiConfig.authorizationHeader: '${ApiConfig.bearerPrefix}$accessToken',
      },
    );
  }

  /// Map Dio errors to custom exceptions
  AppException _mapDioErrorToException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ConnectionTimeoutException(
          'Connection timeout',
          originalError: error,
        );
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final messageData = error.response?.data?['message'];
        String message;

        if (messageData is List) {
          // Si el mensaje es una lista (como errores de validación)
          message = messageData.join(', ');
        } else if (messageData is String) {
          message = messageData;
        } else {
          message = error.message ?? 'Server error';
        }

        return ServerException.fromResponse(statusCode, message);
      
      case DioExceptionType.cancel:
        return NetworkException(
          'Request cancelled',
          code: 'REQUEST_CANCELLED',
          originalError: error,
        );
      
      case DioExceptionType.connectionError:
        return ConnectionException(
          'Connection error',
          originalError: error,
        );
      
      case DioExceptionType.badCertificate:
        return NetworkException(
          'Bad certificate',
          code: 'BAD_CERTIFICATE',
          originalError: error,
        );
      
      case DioExceptionType.unknown:
      default:
        return NetworkException(
          error.message ?? 'Unknown network error',
          code: 'UNKNOWN_NETWORK_ERROR',
          originalError: error,
        );
    }
  }

  // HTTP Methods

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _mapDioErrorToException(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _mapDioErrorToException(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _mapDioErrorToException(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _mapDioErrorToException(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioErrorToException(e);
    }
  }

  /// Download file
  Future<Response> download(
    String urlPath,
    String savePath, {
    void Function(int, int)? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Options? options,
  }) async {
    try {
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioErrorToException(e);
    }
  }

  /// Get the underlying Dio instance
  Dio get dio => _dio;

  /// Update base URL
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// Add custom interceptor
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  /// Remove interceptor
  void removeInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }

  /// Clear all interceptors
  void clearInterceptors() {
    _dio.interceptors.clear();
    _setupInterceptors(); // Re-setup default interceptors
  }

  /// Close the client and cancel all requests
  void close({bool force = false}) {
    _dio.close(force: force);
  }
}