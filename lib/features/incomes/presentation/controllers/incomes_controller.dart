import 'package:get/get.dart';
import '../../domain/entities/income.dart';
import '../../domain/usecases/incomes_usecases.dart';

class IncomesController extends GetxController {
  final GetIncomesUseCase getIncomesUseCase;
  final GetIncomeByIdUseCase getIncomeByIdUseCase;
  final CreateIncomeUseCase createIncomeUseCase;
  final UpdateIncomeUseCase updateIncomeUseCase;
  final DeleteIncomeUseCase deleteIncomeUseCase;

  IncomesController({
    required this.getIncomesUseCase,
    required this.getIncomeByIdUseCase,
    required this.createIncomeUseCase,
    required this.updateIncomeUseCase,
    required this.deleteIncomeUseCase,
  });

  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;
  final RxList<Income> incomes = <Income>[].obs;
  final RxString errorMessage = ''.obs;
  final Rx<Income?> selectedIncome = Rx<Income?>(null);

  @override
  void onInit() {
    super.onInit();
    loadIncomes();
  }

  Future<void> loadIncomes({bool refresh = false}) async {
    try {
      if (refresh) {
        isRefreshing.value = true;
      } else {
        if (isLoading.value) return;
        isLoading.value = true;
      }
      errorMessage.value = '';
      final result = await getIncomesUseCase.call();
      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar('Error', failure.message, snackPosition: SnackPosition.TOP);
          }
        },
        (loadedIncomes) {
          incomes.value = loadedIncomes;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar('Error', errorMessage.value, snackPosition: SnackPosition.TOP);
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> getIncomeById(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await getIncomeByIdUseCase.call(GetIncomeByIdParams(id: id));
      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar('Error', failure.message, snackPosition: SnackPosition.TOP);
          }
        },
        (income) { selectedIncome.value = income; },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createIncome({required String description, required double amount}) async {
    try {
      isCreating.value = true;
      errorMessage.value = '';
      final result = await createIncomeUseCase.call(CreateIncomeParams(description: description, amount: amount));
      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar('Error', failure.message, snackPosition: SnackPosition.TOP);
          }
          return false;
        },
        (income) { loadIncomes(refresh: true); return true; },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  Future<bool> updateIncome({required String id, String? description, double? amount}) async {
    try {
      isUpdating.value = true;
      errorMessage.value = '';
      final result = await updateIncomeUseCase.call(UpdateIncomeParams(id: id, description: description, amount: amount));
      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar('Error', failure.message, snackPosition: SnackPosition.TOP);
          }
          return false;
        },
        (income) {
          if (selectedIncome.value?.id == income.id) selectedIncome.value = income;
          loadIncomes(refresh: true);
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> deleteIncome(String id) async {
    try {
      isDeleting.value = true;
      errorMessage.value = '';
      final result = await deleteIncomeUseCase.call(DeleteIncomeParams(id: id));
      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar('Error', failure.message, snackPosition: SnackPosition.TOP);
          }
          return false;
        },
        (_) {
          if (selectedIncome.value?.id == id) selectedIncome.value = null;
          loadIncomes(refresh: true);
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  Future<void> refreshIncomes() async => await loadIncomes(refresh: true);
  void clearSelectedIncome() { selectedIncome.value = null; }

  double get totalIncomesAmount => incomes.fold(0.0, (sum, i) => sum + i.amount);
  int get incomesCount => incomes.length;

  List<Income> get todayIncomes {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return incomes.where((i) {
      final d = DateTime(i.createdAt.year, i.createdAt.month, i.createdAt.day);
      return d == today;
    }).toList();
  }
  double get todayTotalAmount => todayIncomes.fold(0.0, (sum, i) => sum + i.amount);

  List<Income> get weekIncomes {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return incomes.where((i) {
      final d = DateTime(i.createdAt.year, i.createdAt.month, i.createdAt.day);
      return d.isAfter(startDate.subtract(const Duration(days: 1))) && d.isBefore(now.add(const Duration(days: 1)));
    }).toList();
  }
  double get weekTotalAmount => weekIncomes.fold(0.0, (sum, i) => sum + i.amount);

  List<Income> get monthIncomes {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return incomes.where((i) {
      final d = DateTime(i.createdAt.year, i.createdAt.month, i.createdAt.day);
      return d.isAfter(startOfMonth.subtract(const Duration(days: 1))) && d.isBefore(now.add(const Duration(days: 1)));
    }).toList();
  }
  double get monthTotalAmount => monthIncomes.fold(0.0, (sum, i) => sum + i.amount);
}
