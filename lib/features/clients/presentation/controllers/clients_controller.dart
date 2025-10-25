// lib/features/clients/presentation/controllers/clients_controller.dart

import 'package:get/get.dart';
import 'dart:async';

import '../../domain/entities/client.dart';
import '../../domain/usecases/get_clients_usecase.dart';
import '../../domain/usecases/create_client_usecase.dart';
import '../../domain/usecases/update_client_usecase.dart';
import '../../domain/usecases/delete_client_usecase.dart';

/// ClientsController using GetX for reactive state management
/// Handles clients list, search, pagination, and CRUD operations
class ClientsController extends GetxController {
  final GetClientsUseCase getClientsUseCase;
  final GetClientByIdUseCase getClientByIdUseCase;
  final CreateClientUseCase createClientUseCase;
  final UpdateClientUseCase updateClientUseCase;
  final DeleteClientUseCase deleteClientUseCase;

  ClientsController({
    required this.getClientsUseCase,
    required this.getClientByIdUseCase,
    required this.createClientUseCase,
    required this.updateClientUseCase,
    required this.deleteClientUseCase,
  });

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;
  final RxList<Client> clients = <Client>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxInt currentPage = 0.obs;
  final RxInt totalClients = 0.obs;
  final RxBool hasMoreClients = true.obs;
  final Rx<Client?> selectedClient = Rx<Client?>(null);

  // Constants
  static const int itemsPerPage = 20;
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    loadClients();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  /// Load clients with optional search and pagination
  Future<void> loadClients({
    bool refresh = false,
    bool loadMore = false,
  }) async {
    try {
      // Set loading states
      if (refresh) {
        isRefreshing.value = true;
        currentPage.value = 0;
        hasMoreClients.value = true;
      } else if (loadMore) {
        if (!hasMoreClients.value || isLoadingMore.value) return;
        isLoadingMore.value = true;
      } else {
        if (isLoading.value) return;
        isLoading.value = true;
        currentPage.value = 0;
        hasMoreClients.value = true;
      }

      // Clear error message
      errorMessage.value = '';

      // Prepare parameters
      final params = GetClientsParams(
        page: loadMore ? currentPage.value + 1 : 0,
        limit: itemsPerPage,
        search: searchQuery.value.trim().isNotEmpty
            ? searchQuery.value.trim()
            : null,
      );

      // Execute use case
      final result = await getClientsUseCase.call(params);

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
        },
        (loadedClients) {
          if (loadMore) {
            clients.addAll(loadedClients);
            currentPage.value++;
          } else {
            clients.value = loadedClients;
            currentPage.value = 0;
          }

          // Check if there are more clients
          hasMoreClients.value = loadedClients.length >= itemsPerPage;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Search clients with debounce
  void searchClients(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      searchQuery.value = query;
      loadClients();
    });
  }

  /// Clear search
  void clearSearch() {
    searchQuery.value = '';
    loadClients();
  }

  /// Get client by ID
  Future<void> getClientById(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final params = GetClientByIdParams(id: id);
      final result = await getClientByIdUseCase.call(params);

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
        },
        (client) {
          selectedClient.value = client;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new client
  Future<bool> createClient({
    required String nombre,
    String? celular,
    String? email,
    String? direccion,
  }) async {
    try {
      isCreating.value = true;
      errorMessage.value = '';

      final params = CreateClientParams(
        nombre: nombre,
        celular: celular,
        email: email,
        direccion: direccion,
      );

      final result = await createClientUseCase.call(params);

      return result.fold(
        (failure) {
          print('🔴 Controller: Client creation failed: ${failure.message}');
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
          return false;
        },
        (client) {
          print('🟢 Controller: Client created successfully: ${client.nombre}');
          // Refresh list
          loadClients(refresh: true);
          print('🟢 Controller: Returning true');
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  /// Update an existing client
  Future<bool> updateClient({
    required String id,
    String? nombre,
    String? celular,
    String? email,
    String? direccion,
    bool? isActive,
  }) async {
    try {
      isUpdating.value = true;
      errorMessage.value = '';

      final params = UpdateClientParams(
        id: id,
        nombre: nombre,
        celular: celular,
        email: email,
        direccion: direccion,
        isActive: isActive,
      );

      final result = await updateClientUseCase.call(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
          return false;
        },
        (client) {
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Éxito',
              'Cliente actualizado exitosamente',
              snackPosition: SnackPosition.TOP,
            );
          }
          // Update selected client if it's the same
          if (selectedClient.value?.id == client.id) {
            selectedClient.value = client;
          }
          // Refresh list
          loadClients(refresh: true);
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Delete a client (soft delete)
  Future<bool> deleteClient(String id) async {
    try {
      isDeleting.value = true;
      errorMessage.value = '';

      final params = DeleteClientParams(id: id);
      final result = await deleteClientUseCase.call(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
          return false;
        },
        (_) {
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Éxito',
              'Cliente eliminado exitosamente',
              snackPosition: SnackPosition.TOP,
            );
          }
          // Clear selected client if it's the deleted one
          if (selectedClient.value?.id == id) {
            selectedClient.value = null;
          }
          // Refresh list
          loadClients(refresh: true);
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  /// Refresh clients list
  Future<void> refreshClients() async {
    await loadClients(refresh: true);
  }

  /// Load more clients (pagination)
  Future<void> loadMoreClients() async {
    await loadClients(loadMore: true);
  }

  /// Get clients count
  Future<void> getClientsCount() async {
    try {
      final result = await getClientsUseCase.getCount(
        searchQuery.value.trim().isNotEmpty ? searchQuery.value.trim() : null,
      );

      result.fold(
        (failure) {
          // Silently fail for count
        },
        (count) {
          totalClients.value = count;
        },
      );
    } catch (e) {
      // Silently fail for count
    }
  }

  /// Clear selected client data
  void clearSelectedClient() {
    selectedClient.value = null;
  }
}
