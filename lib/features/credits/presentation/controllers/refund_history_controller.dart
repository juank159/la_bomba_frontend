// lib/features/credits/presentation/controllers/refund_history_controller.dart

import 'package:get/get.dart';
import '../../data/datasources/client_balance_remote_datasource.dart';
import '../../domain/entities/refund_history.dart';
import '../../../../app/core/network/dio_client.dart';

class RefundHistoryController extends GetxController {
  final RxList<RefundHistory> refunds = <RefundHistory>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  late final ClientBalanceRemoteDataSource _dataSource;

  @override
  void onInit() {
    super.onInit();
    _dataSource = ClientBalanceRemoteDataSourceImpl(Get.find<DioClient>());
    loadRefundHistory();
  }

  Future<void> loadRefundHistory() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('📥 Cargando historial de devoluciones...');
      final refundsList = await _dataSource.getAllRefunds();

      refunds.value = refundsList;
      print('✅ Devoluciones cargadas: ${refunds.length}');

    } catch (e) {
      print('❌ Error al cargar historial de devoluciones: $e');
      errorMessage.value = _getErrorMessage(e);

      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('SocketException') ||
        errorStr.contains('Failed host lookup')) {
      return 'Sin conexión a internet';
    } else if (errorStr.contains('TimeoutException')) {
      return 'Tiempo de espera agotado';
    } else if (errorStr.contains('401')) {
      return 'Sesión expirada. Por favor inicia sesión nuevamente';
    } else if (errorStr.contains('403')) {
      return 'No tienes permiso para ver esta información';
    } else if (errorStr.contains('500')) {
      return 'Error en el servidor';
    } else {
      return 'Error al cargar historial de devoluciones';
    }
  }

  double get totalRefunded {
    return refunds.fold(0.0, (sum, refund) => sum + refund.amount);
  }
}
