import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/core/utils/date_formatter.dart';
import '../../../../app/core/utils/price_input_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/core/di/service_locator.dart';
import '../controllers/incomes_controller.dart';
import '../../domain/usecases/incomes_usecases.dart';
import '../../domain/entities/income.dart';
import '../../../../app/shared/widgets/custom_date_range_picker.dart';
import '../../../../app/core/services/password_gate_service.dart';

class IncomesListPage extends StatefulWidget {
  const IncomesListPage({super.key});

  @override
  State<IncomesListPage> createState() => _IncomesListPageState();
}

class _IncomesListPageState extends State<IncomesListPage> {
  late IncomesController controller;
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterLabel = '';
  bool _accessGranted = false;

  @override
  void initState() {
    super.initState();
    Get.put(
      IncomesController(
        getIncomesUseCase: getIt<GetIncomesUseCase>(),
        getIncomeByIdUseCase: getIt<GetIncomeByIdUseCase>(),
        createIncomeUseCase: getIt<CreateIncomeUseCase>(),
        updateIncomeUseCase: getIt<UpdateIncomeUseCase>(),
        deleteIncomeUseCase: getIt<DeleteIncomeUseCase>(),
      ),
      permanent: true,
    );
    controller = Get.find<IncomesController>();

    // Request password on entry
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAccess());
  }

  Future<void> _checkAccess() async {
    final granted = await PasswordGateService().requestAccess(
      gateId: 'incomes_screen',
      title: 'Acceso Restringido',
      message: 'Ingresa tu contraseña para acceder a Ingresos',
    );
    if (granted) {
      setState(() => _accessGranted = true);
    } else {
      Get.back();
    }
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
      setState(() { _searchQuery = query.toLowerCase(); });
    });
  }

  void _showCreateIncomeDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: const Text('Nuevo Ingreso'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripcion',
                    hintText: 'Ej: Venta del dia',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'La descripcion es requerida';
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
                    if (value == null || value.trim().isEmpty) return 'El monto es requerido';
                    final amount = PriceFormatter.parse(value.trim());
                    if (amount <= 0) return 'Ingrese un monto valido';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await controller.createIncome(
                  description: descriptionController.text.trim(),
                  amount: PriceFormatter.parse(amountController.text.trim()),
                );
                if (success) {
                  Get.back();
                  await Future.delayed(const Duration(milliseconds: 100));
                  Get.snackbar('Exito', 'Ingreso creado exitosamente', snackPosition: SnackPosition.TOP, backgroundColor: Colors.green, colorText: Colors.white);
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEditIncomeDialog(Income income) {
    final descriptionController = TextEditingController(text: income.description);
    final amountController = TextEditingController(text: PriceFormatter.formatForEditing(income.amount));
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: const Text('Editar Ingreso'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripcion', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'La descripcion es requerida';
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Monto', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                  keyboardType: TextInputType.number,
                  inputFormatters: [PriceInputFormatter()],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'El monto es requerido';
                    final amount = PriceFormatter.parse(value.trim());
                    if (amount <= 0) return 'Ingrese un monto valido';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await controller.updateIncome(
                  id: income.id,
                  description: descriptionController.text.trim(),
                  amount: PriceFormatter.parse(amountController.text.trim()),
                );
                if (success) {
                  Get.back();
                  await Future.delayed(const Duration(milliseconds: 100));
                  Get.snackbar('Exito', 'Ingreso actualizado exitosamente', snackPosition: SnackPosition.TOP, backgroundColor: Colors.green, colorText: Colors.white);
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showIncomeDetails(Income income) {
    final bool wasUpdated = income.updatedAt.isAfter(income.createdAt.add(const Duration(seconds: 1)));

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              radius: 20,
              child: const Icon(Icons.trending_up, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Detalle del Ingreso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Descripcion', income.description, Icons.description, Colors.blue),
              const SizedBox(height: 16),
              _buildDetailRow('Monto', NumberFormatter.formatCurrency(income.amount), Icons.attach_money, Colors.green),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Trazabilidad', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTraceRow('Creado por', income.createdBy ?? 'Usuario desconocido', DateFormatter.formatDateTime(income.createdAt), Icons.person_add, Colors.blue),
              if (wasUpdated) ...[
                const SizedBox(height: 12),
                _buildTraceRow('Actualizado por', income.updatedBy ?? 'Usuario desconocido', DateFormatter.formatDateTime(income.updatedAt), Icons.edit, Colors.orange),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
          TextButton.icon(
            onPressed: () { Get.back(); _showDeleteConfirmation(income); },
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Eliminar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
          ElevatedButton.icon(
            onPressed: () { Get.back(); _showEditIncomeDialog(income); },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ],
    );
  }

  Widget _buildTraceRow(String label, String username, String datetime, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(username, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(datetime, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ])),
      ]),
    );
  }

  void _showDeleteConfirmation(Income income) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar eliminacion'),
        content: Text('Esta seguro que desea eliminar el ingreso "${income.description}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final success = await controller.deleteIncome(income.id);
              if (success) {
                Get.back();
                await Future.delayed(const Duration(milliseconds: 100));
                Get.snackbar('Exito', 'Ingreso eliminado exitosamente', snackPosition: SnackPosition.TOP, backgroundColor: Colors.green, colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
            child: CustomDateRangePicker(
              rangeStart: _startDate,
              rangeEnd: _endDate,
              onApplyFilter: (start, end, label) {
                setState(() { _startDate = start; _endDate = end; _filterLabel = label; });
                Get.back();
              },
              onClearFilter: () {
                setState(() { _startDate = null; _endDate = null; _filterLabel = ''; });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilter(double totalAmount, int count) {
    if (_startDate == null || _endDate == null) return const SizedBox.shrink();
    final theme = Get.theme;
    final filterColor = theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: filterColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: filterColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(children: [
        Icon(Icons.filter_list, color: filterColor, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Filtro activo:', style: TextStyle(fontSize: 11, color: filterColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(_filterLabel, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.attach_money, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(NumberFormatter.formatCurrency(totalAmount), style: TextStyle(fontSize: 15, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: filterColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text('$count ingreso${count != 1 ? 's' : ''}', style: TextStyle(fontSize: 10, color: filterColor, fontWeight: FontWeight.w600)),
            ),
          ]),
        ])),
        IconButton(
          icon: Icon(Icons.close, color: filterColor, size: 20),
          onPressed: () { setState(() { _startDate = null; _endDate = null; _filterLabel = ''; }); },
          tooltip: 'Limpiar filtro',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_accessGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ingresos')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final controller = Get.find<IncomesController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: _startDate != null || _endDate != null ? Get.theme.colorScheme.primary : null),
            onPressed: _showDateFilterDialog,
            tooltip: 'Filtrar por fecha',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => controller.refreshIncomes()),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Obx(() {
          List<Income> filteredIncomes = controller.incomes.toList();
          if (_searchQuery.isNotEmpty) {
            filteredIncomes = filteredIncomes.where((i) => i.description.toLowerCase().contains(_searchQuery)).toList();
          }
          if (_startDate != null && _endDate != null) {
            final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
            filteredIncomes = filteredIncomes.where((i) =>
              i.createdAt.isAfter(_startDate!.subtract(const Duration(seconds: 1))) &&
              i.createdAt.isBefore(endOfDay.add(const Duration(seconds: 1)))
            ).toList();
          }
          final totalAmount = filteredIncomes.fold<double>(0.0, (sum, i) => sum + i.amount);
          return Column(children: [
            _buildStatsCard(controller),
            _buildSearchBar(),
            _buildActiveFilter(totalAmount, filteredIncomes.length),
            Expanded(child: _buildBody(controller)),
          ]);
        }),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showCreateIncomeDialog, child: const Icon(Icons.add)),
    );
  }

  Widget _buildStatsCard(IncomesController controller) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Expanded(child: _buildSummaryCard('Total', NumberFormatter.formatCurrency(controller.totalIncomesAmount), Icons.account_balance_wallet, Colors.green, '${controller.incomesCount} ingresos')),
          const SizedBox(width: 12),
          Expanded(child: _buildSummaryCard('Hoy', NumberFormatter.formatCurrency(controller.todayTotalAmount), Icons.today, Colors.teal, '${controller.todayIncomes.length}')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildSummaryCard('Semanal', NumberFormatter.formatCurrency(controller.weekTotalAmount), Icons.date_range, Colors.orange, '${controller.weekIncomes.length}')),
          const SizedBox(width: 12),
          Expanded(child: _buildSummaryCard('Mensual', NumberFormatter.formatCurrency(controller.monthTotalAmount), Icons.calendar_month, Colors.purple, '${controller.monthIncomes.length}')),
        ]),
      ]),
    ));
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String count) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(count, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
        ]),
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
          hintText: 'Buscar por descripcion...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () { searchController.clear(); setState(() { _searchQuery = ''; }); })
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildBody(IncomesController controller) {
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      if (controller.errorMessage.value.isNotEmpty && controller.incomes.isEmpty) {
        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(controller.errorMessage.value),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => controller.loadIncomes(), child: const Text('Reintentar')),
        ]));
      }

      List<Income> filteredIncomes = controller.incomes.toList();
      if (_searchQuery.isNotEmpty) {
        filteredIncomes = filteredIncomes.where((i) => i.description.toLowerCase().contains(_searchQuery)).toList();
      }
      if (_startDate != null && _endDate != null) {
        final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        filteredIncomes = filteredIncomes.where((i) =>
          i.createdAt.isAfter(_startDate!.subtract(const Duration(seconds: 1))) &&
          i.createdAt.isBefore(endOfDay.add(const Duration(seconds: 1)))
        ).toList();
      }

      if (filteredIncomes.isEmpty) {
        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_searchQuery.isNotEmpty ? Icons.search_off : Icons.trending_up_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_searchQuery.isNotEmpty ? 'No se encontraron ingresos' : 'No hay ingresos registrados', style: const TextStyle(fontSize: 18, color: Colors.grey)),
        ]));
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshIncomes(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredIncomes.length,
          itemBuilder: (context, index) => _buildIncomeCard(filteredIncomes[index]),
        ),
      );
    });
  }

  Widget _buildIncomeCard(Income income) {
    final bool wasUpdated = income.updatedAt.isAfter(income.createdAt.add(const Duration(seconds: 1)));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              child: const Icon(Icons.trending_up, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(income.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(child: Text(income.userName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(NumberFormatter.formatCurrency(income.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
              const SizedBox(height: 4),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 20),
                onSelected: (value) {
                  if (value == 'details') _showIncomeDetails(income);
                  else if (value == 'edit') _showEditIncomeDialog(income);
                  else if (value == 'delete') _showDeleteConfirmation(income);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'details', child: Row(children: [Icon(Icons.info_outline, color: Colors.green, size: 18), SizedBox(width: 8), Text('Ver detalles')])),
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 18), SizedBox(width: 8), Text('Editar')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Eliminar')])),
                ],
              ),
            ]),
          ]),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.calendar_today, size: 13, color: Colors.blue.shade700),
            const SizedBox(width: 4),
            Expanded(child: Text('Creado: ${DateFormatter.formatDateTime(income.createdAt)}', style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.w500))),
          ]),
          if (wasUpdated) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.edit_calendar, size: 13, color: Colors.orange.shade700),
              const SizedBox(width: 4),
              Expanded(child: Text('Actualizado: ${DateFormatter.formatDateTime(income.updatedAt)}${income.updatedBy != null ? ' por ${income.updatedBy}' : ''}', style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.w500))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit, size: 9, color: Colors.orange.shade700),
                  const SizedBox(width: 3),
                  Text('Editado', style: TextStyle(color: Colors.orange.shade700, fontSize: 9, fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
