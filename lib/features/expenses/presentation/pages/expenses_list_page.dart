// lib/features/expenses/presentation/pages/expenses_list_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/core/utils/date_formatter.dart';
import '../../../../app/core/utils/price_input_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/core/di/service_locator.dart';
import '../controllers/expenses_controller.dart';
import '../../domain/usecases/expenses_usecases.dart';
import '../../domain/entities/expense.dart';
import '../widgets/custom_date_range_picker.dart';

class ExpensesListPage extends StatefulWidget {
  const ExpensesListPage({super.key});

  @override
  State<ExpensesListPage> createState() => _ExpensesListPageState();
}

class _ExpensesListPageState extends State<ExpensesListPage> {
  late ExpensesController controller;
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterLabel = '';

  @override
  void initState() {
    super.initState();
    // Initialize expenses controller with dependencies
    Get.put(
      ExpensesController(
        getExpensesUseCase: getIt<GetExpensesUseCase>(),
        getExpenseByIdUseCase: getIt<GetExpenseByIdUseCase>(),
        createExpenseUseCase: getIt<CreateExpenseUseCase>(),
        updateExpenseUseCase: getIt<UpdateExpenseUseCase>(),
        deleteExpenseUseCase: getIt<DeleteExpenseUseCase>(),
      ),
      permanent: true,
    );
    controller = Get.find<ExpensesController>();
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

  void _showCreateExpenseDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: const Text('Nuevo Gasto'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej: Compra de materiales',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción es requerida';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    hintText: '0',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [PriceInputFormatter()],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El monto es requerido';
                    }
                    final amount = PriceFormatter.parse(value.trim());
                    if (amount <= 0) {
                      return 'Ingrese un monto válido';
                    }
                    return null;
                  },
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
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await controller.createExpense(
                  description: descriptionController.text.trim(),
                  amount: PriceFormatter.parse(amountController.text.trim()),
                );

                if (success) {
                  Get.back();
                  await Future.delayed(const Duration(milliseconds: 100));
                  Get.snackbar(
                    'Éxito',
                    'Gasto creado exitosamente',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEditExpenseDialog(Expense expense) {
    final descriptionController = TextEditingController(
      text: expense.description,
    );
    final amountController = TextEditingController(
      text: PriceFormatter.formatForEditing(expense.amount),
    );
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: const Text('Editar Gasto'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción es requerida';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Monto',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [PriceInputFormatter()],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El monto es requerido';
                    }
                    final amount = PriceFormatter.parse(value.trim());
                    if (amount <= 0) {
                      return 'Ingrese un monto válido';
                    }
                    return null;
                  },
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
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await controller.updateExpense(
                  id: expense.id,
                  description: descriptionController.text.trim(),
                  amount: PriceFormatter.parse(amountController.text.trim()),
                );

                if (success) {
                  Get.back();
                  await Future.delayed(const Duration(milliseconds: 100));
                  Get.snackbar(
                    'Éxito',
                    'Gasto actualizado exitosamente',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showExpenseDetails(Expense expense) {
    final bool wasUpdated = expense.updatedAt.isAfter(
      expense.createdAt.add(const Duration(seconds: 1)),
    );

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              radius: 20,
              child: const Icon(
                Icons.receipt_long,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Detalle del Gasto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              _buildDetailRow(
                'Descripción',
                expense.description,
                Icons.description,
                Colors.blue,
              ),
              const SizedBox(height: 16),
              // Amount
              _buildDetailRow(
                'Monto',
                NumberFormatter.formatCurrency(expense.amount),
                Icons.attach_money,
                Colors.green,
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              // Traceability section
              const Text(
                'Trazabilidad',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Created by - ALWAYS show
              _buildTraceRow(
                'Creado por',
                expense.createdBy ?? 'Usuario desconocido',
                DateFormatter.formatDateTime(expense.createdAt),
                Icons.person_add,
                Colors.blue,
              ),
              // Updated by - show if was updated
              if (wasUpdated) ...[
                const SizedBox(height: 12),
                _buildTraceRow(
                  'Actualizado por',
                  expense.updatedBy ?? 'Usuario desconocido',
                  DateFormatter.formatDateTime(expense.updatedAt),
                  Icons.edit,
                  Colors.orange,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
          TextButton.icon(
            onPressed: () {
              Get.back();
              _showDeleteConfirmation(expense);
            },
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Eliminar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              _showEditExpenseDialog(expense);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTraceRow(
    String label,
    String username,
    String datetime,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  datetime,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Expense expense) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Está seguro que desea eliminar el gasto "${expense.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await controller.deleteExpense(expense.id);
              if (success) {
                Get.back();
                await Future.delayed(const Duration(milliseconds: 100));
                Get.snackbar(
                  'Éxito',
                  'Gasto eliminado exitosamente',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showDateFilterDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 650,
            ),
            child: CustomDateRangePicker(
              rangeStart: _startDate,
              rangeEnd: _endDate,
              onApplyFilter: (start, end, label) {
                setState(() {
                  _startDate = start;
                  _endDate = end;
                  _filterLabel = label;
                });
                Get.back();
              },
              onClearFilter: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _filterLabel = '';
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(
    String label,
    IconData icon,
    Color color,
    DateTime start,
    DateTime end,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: () {
        setState(() {
          _startDate = start;
          _endDate = end;
          _filterLabel = label;
        });
        Get.back();
      },
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildActiveFilter(double totalAmount, int expenseCount) {
    if (_startDate == null || _endDate == null) {
      return const SizedBox.shrink();
    }

    final theme = Get.theme;
    final filterColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: filterColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filterColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: filterColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtro activo:',
                  style: TextStyle(
                    fontSize: 11,
                    color: filterColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _filterLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Text(
                      NumberFormatter.formatCurrency(totalAmount),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: filterColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$expenseCount gasto${expenseCount != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 10,
                          color: filterColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: filterColor, size: 20),
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
                _filterLabel = '';
              });
            },
            tooltip: 'Limpiar filtro',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpensesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _startDate != null || _endDate != null
                  ? Get.theme.colorScheme.primary
                  : null,
            ),
            onPressed: _showDateFilterDialog,
            tooltip: 'Filtrar por fecha',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshExpenses(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Obx(() {
          // Calculate filtered expenses for the active filter badge
          List<Expense> filteredExpenses = controller.expenses.toList();

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          filteredExpenses = filteredExpenses.where((expense) {
            return expense.description.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        // Apply date range filter
        if (_startDate != null && _endDate != null) {
          final endOfDay = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
            23,
            59,
            59,
          );
          filteredExpenses = filteredExpenses.where((expense) {
            return expense.createdAt.isAfter(_startDate!.subtract(const Duration(seconds: 1))) &&
                   expense.createdAt.isBefore(endOfDay.add(const Duration(seconds: 1)));
          }).toList();
        }

        // Calculate total amount
        final totalAmount = filteredExpenses.fold<double>(
          0.0,
          (sum, expense) => sum + expense.amount,
        );

          return Column(
            children: [
              _buildStatsCard(controller),
              _buildSearchBar(),
              _buildActiveFilter(totalAmount, filteredExpenses.length),
              Expanded(child: _buildBody(controller)),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateExpenseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(ExpensesController controller) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Total and Today in first row
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total',
                    NumberFormatter.formatCurrency(controller.totalExpensesAmount),
                    Icons.account_balance_wallet,
                    Colors.blue,
                    '${controller.expensesCount} gastos',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Hoy',
                    NumberFormatter.formatCurrency(controller.todayTotalAmount),
                    Icons.today,
                    Colors.green,
                    '${controller.todayExpenses.length}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Week and Month in second row
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Semanal',
                    NumberFormatter.formatCurrency(controller.weekTotalAmount),
                    Icons.date_range,
                    Colors.orange,
                    '${controller.weekExpenses.length}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Mensual',
                    NumberFormatter.formatCurrency(controller.monthTotalAmount),
                    Icons.calendar_month,
                    Colors.purple,
                    '${controller.monthExpenses.length}',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String count,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              count,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar por descripción...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildBody(ExpensesController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.errorMessage.value.isNotEmpty &&
          controller.expenses.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(controller.errorMessage.value),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.loadExpenses(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      }

      // Apply search filter
      List<Expense> filteredExpenses = controller.expenses.toList();
      if (_searchQuery.isNotEmpty) {
        filteredExpenses = filteredExpenses.where((expense) {
          return expense.description.toLowerCase().contains(_searchQuery);
        }).toList();
      }

      // Apply date range filter
      if (_startDate != null && _endDate != null) {
        final endOfDay = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
          59,
        );
        filteredExpenses = filteredExpenses.where((expense) {
          return expense.createdAt.isAfter(_startDate!.subtract(const Duration(seconds: 1))) &&
                 expense.createdAt.isBefore(endOfDay.add(const Duration(seconds: 1)));
        }).toList();
      }

      if (filteredExpenses.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchQuery.isNotEmpty
                    ? Icons.search_off
                    : Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No se encontraron gastos'
                    : 'No hay gastos registrados',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshExpenses(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredExpenses.length,
          itemBuilder: (context, index) {
            final expense = filteredExpenses[index];
            return _buildExpenseCard(expense);
          },
        ),
      );
    });
  }

  Widget _buildExpenseCard(Expense expense) {
    final bool wasUpdated = expense.updatedAt.isAfter(
      expense.createdAt.add(const Duration(seconds: 1)),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  child: const Icon(Icons.money_off, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              expense.userName,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormatter.formatCurrency(expense.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      onSelected: (value) {
                        if (value == 'details') {
                          _showExpenseDetails(expense);
                        } else if (value == 'edit') {
                          _showEditExpenseDialog(expense);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(expense);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('Ver detalles'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue, size: 18),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            // Always show created
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 13,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Creado: ${DateFormatter.formatDateTime(expense.createdAt)}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            // Show updated if it was modified
            if (wasUpdated) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.edit_calendar,
                    size: 13,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Actualizado: ${DateFormatter.formatDateTime(expense.updatedAt)}${expense.updatedBy != null ? ' por ${expense.updatedBy}' : ''}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          size: 9,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Editado',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
