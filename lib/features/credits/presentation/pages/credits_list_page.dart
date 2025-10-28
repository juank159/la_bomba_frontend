// lib/features/credits/presentation/pages/credits_list_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/core/utils/price_input_formatter.dart';
import '../controllers/credits_controller.dart';
import '../../domain/usecases/credits_usecases.dart';
import '../../domain/entities/credit.dart';
import '../../../../app/core/di/service_locator.dart';
import '../widgets/credit_card.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../clients/domain/usecases/get_clients_usecase.dart';
import '../controllers/client_balance_controller.dart';
import '../../domain/entities/client_balance.dart';

/// CreditsListPage - Main page showing list of credits with filtering
/// Features:
/// - Filter by status (all, pending, paid)
/// - Pull-to-refresh functionality
/// - Create new credit
/// - Empty and error states
/// - ADMIN ONLY access
class CreditsListPage extends StatefulWidget {
  const CreditsListPage({super.key});

  @override
  State<CreditsListPage> createState() => _CreditsListPageState();
}

class _CreditsListPageState extends State<CreditsListPage> {
  late CreditsController controller;
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize credits controller with dependencies
    Get.put(
      CreditsController(
        getCreditsUseCase: getIt<GetCreditsUseCase>(),
        getCreditByIdUseCase: getIt<GetCreditByIdUseCase>(),
        createCreditUseCase: getIt<CreateCreditUseCase>(),
        updateCreditUseCase: getIt<UpdateCreditUseCase>(),
        addPaymentUseCase: getIt<AddPaymentUseCase>(),
        removePaymentUseCase: getIt<RemovePaymentUseCase>(),
        deleteCreditUseCase: getIt<DeleteCreditUseCase>(),
        getPendingCreditByClientUseCase: getIt<GetPendingCreditByClientUseCase>(),
        addAmountToCreditUseCase: getIt<AddAmountToCreditUseCase>(),
      ),
      permanent: true,
    );
    controller = Get.find<CreditsController>();
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildSummaryCards(),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Build app bar with title and actions
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Créditos'),
      centerTitle: true,
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Actualizar'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build summary cards showing totals
  Widget _buildSummaryCards() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        child: Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Pendiente',
                NumberFormatter.formatCurrency(controller.totalPendingAmount),
                Icons.pending_outlined,
                Colors.orange,
              ),
            ),
            const SizedBox(width: AppConfig.paddingMedium),
            Expanded(
              child: _buildSummaryCard(
                'Total Pagado',
                NumberFormatter.formatCurrency(controller.totalPaidAmount),
                Icons.check_circle_outline,
                Colors.green,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConfig.paddingMedium,
        vertical: AppConfig.paddingSmall,
      ),
      child: StatefulBuilder(
        builder: (context, setSearchState) {
          return TextField(
            controller: searchController,
            onChanged: (value) {
              _onSearchChanged(value);
              setSearchState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Buscar por nombre de cliente...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        _onSearchChanged('');
                        setSearchState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConfig.paddingMedium,
                vertical: AppConfig.paddingSmall,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build individual summary card
  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build filter chips
  Widget _buildFilterChips() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConfig.paddingMedium,
        ),
        child: Row(
          children: [
            _buildFilterChip('Todos', 'all', controller.credits.length),
            const SizedBox(width: AppConfig.paddingSmall),
            _buildFilterChip(
              'Pendientes',
              'pending',
              controller.pendingCreditsCount,
            ),
            const SizedBox(width: AppConfig.paddingSmall),
            _buildFilterChip('Pagados', 'paid', controller.paidCreditsCount),
          ],
        ),
      );
    });
  }

  /// Build individual filter chip
  Widget _buildFilterChip(String label, String value, int count) {
    return Obx(() {
      final isSelected = controller.filterStatus.value == value;
      return FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            controller.setFilterStatus(value);
          }
        },
        selectedColor: Get.theme.colorScheme.primaryContainer,
        checkmarkColor: Get.theme.colorScheme.primary,
      );
    });
  }

  /// Build main body with credits list
  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value && controller.credits.isEmpty) {
        return const LoadingWidget(message: 'Cargando créditos...');
      }

      if (controller.errorMessage.value.isNotEmpty &&
          controller.credits.isEmpty) {
        return _buildErrorState();
      }

      if (controller.credits.isEmpty) {
        return _buildEmptyState();
      }

      // Apply status filter first
      var filteredCredits = controller.filteredCredits;

      // Apply search filter on top of status filter
      if (_searchQuery.isNotEmpty) {
        filteredCredits = filteredCredits.where((credit) {
          final clientName = credit.clientName.toLowerCase();
          return clientName.contains(_searchQuery);
        }).toList();
      }

      if (filteredCredits.isEmpty) {
        return _buildEmptyFilterState();
      }

      return RefreshIndicator(
        onRefresh: controller.refreshCredits,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: filteredCredits.length,
          itemBuilder: (context, index) {
            final credit = filteredCredits[index];
            return CreditCard(
              credit: credit,
              onTap: () => _navigateToCreditDetail(credit.id),
            );
          },
        ),
      );
    });
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Get.theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppConfig.paddingMedium),
          Text(
            'No hay créditos registrados',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppConfig.paddingSmall),
          Text(
            'Crea tu primer crédito usando el botón +',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Get.theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty filter state
  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 80,
            color: Get.theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppConfig.paddingMedium),
          Text(
            'No hay créditos con este filtro',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppConfig.paddingSmall),
          TextButton(
            onPressed: () => controller.setFilterStatus('all'),
            child: const Text('Ver todos'),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Get.theme.colorScheme.error,
          ),
          const SizedBox(height: AppConfig.paddingMedium),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConfig.paddingLarge,
            ),
            child: Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: AppConfig.paddingMedium),
          ElevatedButton.icon(
            onPressed: () => controller.loadCredits(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// Build floating action button
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showCreateCreditDialog,
      tooltip: 'Crear crédito',
      child: const Icon(Icons.add),
    );
  }

  /// Handle menu selection
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'refresh':
        controller.refreshCredits();
        break;
    }
  }

  /// Navigate to credit detail page
  void _navigateToCreditDetail(String creditId) {
    Get.toNamed('/credits/$creditId');
  }

  /// Show create credit dialog with improved UX
  void _showCreateCreditDialog() async {
    // Load clients first
    final getClientsUseCase = getIt<GetClientsUseCase>();
    final clientsResult = await getClientsUseCase();

    List<Client> allClients = [];
    clientsResult.fold(
      (failure) {
        Get.snackbar(
          'Error',
          'No se pudieron cargar los clientes',
          snackPosition: SnackPosition.TOP,
        );
        return;
      },
      (loadedClients) {
        allClients = loadedClients.where((c) => c.isActive).toList();
      },
    );

    if (allClients.isEmpty) {
      Get.snackbar(
        'Error',
        'No hay clientes activos. Por favor, registra un cliente primero.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    Client? selectedClient;
    Credit? pendingCredit;
    ClientBalance? clientBalance;
    bool isCheckingPendingCredit = false;
    bool isLoadingBalance = false;
    bool useClientBalance = false;
    final descriptionController = TextEditingController();
    final totalAmountController = TextEditingController();
    final searchController = TextEditingController();
    final priceFormatter = PriceInputFormatter();
    bool showClientList = false;

    // Get or create ClientBalanceController
    final balanceController = Get.isRegistered<ClientBalanceController>()
        ? Get.find<ClientBalanceController>()
        : Get.put(ClientBalanceController());

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          // Filter clients based on search
          final filteredClients = allClients.where((client) {
            if (searchController.text.isEmpty) return true;
            final searchLower = searchController.text.toLowerCase();
            return client.nombre.toLowerCase().contains(searchLower) ||
                (client.celular?.toLowerCase().contains(searchLower) ??
                    false) ||
                (client.email?.toLowerCase().contains(searchLower) ?? false);
          }).toList();

          return AlertDialog(
            title: Text(
              pendingCredit != null
                  ? 'Agregar Monto al Crédito'
                  : 'Crear Crédito',
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Client selection field with search
                    InkWell(
                      onTap: () {
                        setState(() {
                          showClientList = !showClientList;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedClient == null
                                ? Get.theme.colorScheme.outline
                                : Get.theme.colorScheme.primary,
                            width: selectedClient == null ? 1 : 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: selectedClient == null
                                  ? Get.theme.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    )
                                  : Get.theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cliente',
                                    style: Get.textTheme.bodySmall?.copyWith(
                                      color: selectedClient == null
                                          ? Get.theme.colorScheme.onSurface
                                                .withOpacity(0.6)
                                          : Get.theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedClient == null
                                        ? 'Selecciona un cliente *'
                                        : selectedClient!.nombre,
                                    style: Get.textTheme.bodyLarge?.copyWith(
                                      fontWeight: selectedClient == null
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  if (selectedClient != null &&
                                      selectedClient!.celular != null)
                                    Text(
                                      selectedClient!.celular!,
                                      style: Get.textTheme.bodySmall?.copyWith(
                                        color: Get.theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              showClientList
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Get.theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Client list (shown when expanded)
                    if (showClientList) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Get.theme.colorScheme.outline.withOpacity(
                              0.5,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // Search field inside the dropdown
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar cliente...',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 20,
                                  ),
                                  suffixIcon: searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              searchController.clear();
                                            });
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Get.theme.colorScheme.outline
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                            const Divider(height: 1),
                            // Client list
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: filteredClients.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'No se encontraron clientes',
                                        style: Get.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: Get
                                                  .theme
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.5),
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: filteredClients.length,
                                      itemBuilder: (context, index) {
                                        final client = filteredClients[index];
                                        final isSelected =
                                            selectedClient?.id == client.id;
                                        return ListTile(
                                          dense: true,
                                          selected: isSelected,
                                          leading: CircleAvatar(
                                            radius: 18,
                                            backgroundColor: isSelected
                                                ? Get.theme.colorScheme.primary
                                                : Get
                                                      .theme
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                            child: Text(
                                              client.nombre[0].toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Get
                                                          .theme
                                                          .colorScheme
                                                          .onPrimary
                                                    : Get
                                                          .theme
                                                          .colorScheme
                                                          .onSurface,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            client.nombre,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          subtitle: client.celular != null
                                              ? Text(
                                                  client.celular!,
                                                  style:
                                                      Get.textTheme.bodySmall,
                                                )
                                              : null,
                                          trailing: isSelected
                                              ? Icon(
                                                  Icons.check_circle,
                                                  color: Get
                                                      .theme
                                                      .colorScheme
                                                      .primary,
                                                  size: 24,
                                                )
                                              : null,
                                          onTap: () async {
                                            setState(() {
                                              selectedClient = client;
                                              showClientList = false;
                                              searchController.clear();
                                              isCheckingPendingCredit = true;
                                              isLoadingBalance = true;
                                              pendingCredit = null;
                                              clientBalance = null;
                                              useClientBalance = false;
                                            });

                                            // Check if client has pending credit and balance in parallel
                                            final results = await Future.wait([
                                              controller.getPendingCreditByClient(client.id),
                                              balanceController.getClientBalance(client.id),
                                            ]);

                                            setState(() {
                                              pendingCredit = results[0] as Credit?;
                                              clientBalance = results[1] as ClientBalance?;
                                              isCheckingPendingCredit = false;
                                              isLoadingBalance = false;
                                              // Clear description to allow user to enter what they're taking today
                                              descriptionController.clear();
                                            });
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppConfig.paddingMedium),

                    // Show existing credit info if client has pending credit
                    if (selectedClient != null && isCheckingPendingCredit)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    if (selectedClient != null &&
                        !isCheckingPendingCredit &&
                        pendingCredit != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Get.theme.colorScheme.primaryContainer
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Get.theme.colorScheme.primary.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Get.theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Crédito Pendiente Existente',
                                  style: Get.textTheme.titleSmall?.copyWith(
                                    color: Get.theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pendingCredit!.description,
                              style: Get.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total del crédito:',
                                      style: Get.textTheme.bodySmall?.copyWith(
                                        color: Get.theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                    Text(
                                      NumberFormatter.formatCurrency(
                                        pendingCredit!.totalAmount,
                                      ),
                                      style: Get.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Saldo pendiente:',
                                      style: Get.textTheme.bodySmall?.copyWith(
                                        color: Get.theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                    Text(
                                      NumberFormatter.formatCurrency(
                                        pendingCredit!.remainingAmount,
                                      ),
                                      style: Get.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Get.theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConfig.paddingMedium),
                    ],

                    // Show loading balance indicator
                    if (selectedClient != null && isLoadingBalance)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text('Verificando saldo disponible...'),
                            ],
                          ),
                        ),
                      ),

                    // Show client balance if available
                    if (selectedClient != null &&
                        !isLoadingBalance &&
                        clientBalance != null &&
                        clientBalance!.balance > 0 &&
                        pendingCredit == null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.green[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Saldo a Favor Disponible',
                                  style: Get.textTheme.titleSmall?.copyWith(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              NumberFormatter.formatCurrency(clientBalance!.balance),
                              style: Get.textTheme.titleLarge?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: useClientBalance,
                                  onChanged: (value) {
                                    setState(() {
                                      useClientBalance = value ?? false;
                                    });
                                  },
                                  activeColor: Colors.green[700],
                                ),
                                Expanded(
                                  child: Text(
                                    'Usar saldo a favor automáticamente',
                                    style: Get.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (useClientBalance &&
                                totalAmountController.text.isNotEmpty) ...[
                              const Divider(height: 16),
                              Builder(
                                builder: (context) {
                                  final creditAmount = PriceFormatter.parse(
                                    totalAmountController.text.trim(),
                                  );
                                  final balanceToUse = creditAmount > 0
                                      ? (creditAmount <= clientBalance!.balance
                                          ? creditAmount
                                          : clientBalance!.balance)
                                      : 0.0;
                                  final remaining = creditAmount - balanceToUse;

                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Monto del crédito:',
                                              style: Get.textTheme.bodySmall),
                                          Text(
                                            NumberFormatter.formatCurrency(
                                              creditAmount,
                                            ),
                                            style: Get.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Saldo aplicado:',
                                              style: Get.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: Colors.green[700],
                                              )),
                                          Text(
                                            '- ${NumberFormatter.formatCurrency(balanceToUse)}',
                                            style: Get.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Saldo pendiente:',
                                            style:
                                                Get.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            NumberFormatter.formatCurrency(
                                              remaining,
                                            ),
                                            style:
                                                Get.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: remaining > 0
                                                  ? Colors.orange[700]
                                                  : Colors.green[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConfig.paddingMedium),
                    ],

                    // Show separate description field based on context
                    if (pendingCredit == null)
                      CustomInput(
                        controller: descriptionController,
                        hintText: 'Descripción del crédito *',
                        prefixIcon: const Icon(Icons.description),
                        maxLines: 2,
                      )
                    else
                      CustomInput(
                        controller: descriptionController,
                        hintText: '¿Qué está llevando hoy? *',
                        prefixIcon: const Icon(Icons.description),
                        maxLines: 2,
                      ),
                    const SizedBox(height: AppConfig.paddingMedium),
                    CustomInput(
                      controller: totalAmountController,
                      hintText: pendingCredit != null
                          ? 'Monto a agregar *'
                          : 'Monto total *',
                      prefixIcon: const Icon(Icons.attach_money),
                      keyboardType: TextInputType.number,
                      inputFormatters: [priceFormatter],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isCreating.value
                      ? null
                      : () async {
                          if (selectedClient == null) {
                            Get.snackbar(
                              'Error',
                              'Por favor selecciona un cliente',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor:
                                  Get.theme.colorScheme.errorContainer,
                              colorText: Get.theme.colorScheme.onErrorContainer,
                            );
                            return;
                          }

                          // Parse the formatted price
                          final amount = PriceFormatter.parse(
                            totalAmountController.text.trim(),
                          );
                          if (amount <= 0) {
                            Get.snackbar(
                              'Error',
                              'El monto debe ser mayor a cero',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor:
                                  Get.theme.colorScheme.errorContainer,
                              colorText: Get.theme.colorScheme.onErrorContainer,
                            );
                            return;
                          }

                          bool success = false;

                          // If client has pending credit, add amount to it
                          if (pendingCredit != null) {
                            if (descriptionController.text.trim().isEmpty) {
                              Get.snackbar(
                                'Error',
                                'La descripción es obligatoria',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor:
                                    Get.theme.colorScheme.errorContainer,
                                colorText:
                                    Get.theme.colorScheme.onErrorContainer,
                              );
                              return;
                            }

                            success = await controller.addAmountToCredit(
                              creditId: pendingCredit!.id,
                              amount: amount,
                              description: descriptionController.text.trim(),
                            );

                            if (success) {
                              Get.back();
                              // Wait a bit to ensure dialog closes before showing snackbar
                              await Future.delayed(
                                const Duration(milliseconds: 100),
                              );
                              Get.snackbar(
                                'Éxito',
                                'Monto agregado al crédito de ${selectedClient!.nombre}',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor:
                                    Get.theme.colorScheme.primaryContainer,
                                colorText:
                                    Get.theme.colorScheme.onPrimaryContainer,
                                icon: Icon(
                                  Icons.check_circle,
                                  color: Get.theme.colorScheme.primary,
                                ),
                              );
                            }
                          } else {
                            // Create new credit
                            if (descriptionController.text.trim().isEmpty) {
                              Get.snackbar(
                                'Error',
                                'La descripción es obligatoria',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor:
                                    Get.theme.colorScheme.errorContainer,
                                colorText:
                                    Get.theme.colorScheme.onErrorContainer,
                              );
                              return;
                            }

                            success = await controller.createCredit(
                              clientId: selectedClient!.id,
                              description: descriptionController.text.trim(),
                              totalAmount: amount,
                              useClientBalance: useClientBalance,
                            );

                            if (success) {
                              Get.back();
                              // Wait a bit to ensure dialog closes before showing snackbar
                              await Future.delayed(
                                const Duration(milliseconds: 100),
                              );
                              Get.snackbar(
                                'Éxito',
                                'Crédito creado para ${selectedClient!.nombre}',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor:
                                    Get.theme.colorScheme.primaryContainer,
                                colorText:
                                    Get.theme.colorScheme.onPrimaryContainer,
                                icon: Icon(
                                  Icons.check_circle,
                                  color: Get.theme.colorScheme.primary,
                                ),
                              );
                            }
                          }
                        },
                  child: controller.isCreating.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          pendingCredit != null
                              ? 'Agregar Monto'
                              : 'Crear Crédito',
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
