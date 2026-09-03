// lib/features/vegetable_expenses/presentation/pages/vegetable_expenses_list_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../expenses/presentation/widgets/custom_date_range_picker.dart';
import '../../domain/entities/vegetable_expense.dart';
import '../../domain/usecases/vegetable_expenses_usecases.dart';
import '../controllers/vegetable_expenses_controller.dart';

/// Gastos operativos del puesto de verduras (bolsas, hielo, transporte...).
/// Separado a propósito del módulo de Gastos general de la app - la compra
/// de mercancía para vender va en Compras (Verduras), no acá.
class VegetableExpensesListPage extends StatefulWidget {
  const VegetableExpensesListPage({super.key});

  @override
  State<VegetableExpensesListPage> createState() => _VegetableExpensesListPageState();
}

class _VegetableExpensesListPageState extends State<VegetableExpensesListPage> {
  late final VegetableExpensesController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<VegetableExpensesController>()) {
      controller = Get.find<VegetableExpensesController>();
    } else {
      controller = Get.put(
        VegetableExpensesController(
          getExpensesUseCase: getIt<GetVegetableExpensesUseCase>(),
          createExpenseUseCase: getIt<CreateVegetableExpenseUseCase>(),
          updateExpenseUseCase: getIt<UpdateVegetableExpenseUseCase>(),
          deleteExpenseUseCase: getIt<DeleteVegetableExpenseUseCase>(),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => controller.loadExpenses());
  }

  Future<void> _openExpenseDialog({VegetableExpense? existing}) async {
    final descriptionController = TextEditingController(text: existing?.description ?? '');
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(0) : '',
    );
    ExpenseFundingSource fundingSource = existing?.fundingSource ?? ExpenseFundingSource.external;
    String? errorText;

    final saved = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(existing == null ? 'Nuevo gasto' : 'Editar gasto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: descriptionController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Ej: bolsas, hielo, transporte',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: AppConfig.paddingMedium),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    ),
                  ),
                  const SizedBox(height: AppConfig.paddingMedium),
                  if (existing == null) ...[
                    Text('¿De dónde salió el dinero?', style: Get.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    SegmentedButton<ExpenseFundingSource>(
                      segments: const [
                        ButtonSegment(
                          value: ExpenseFundingSource.caja,
                          label: Text('Caja'),
                          icon: Icon(Icons.account_balance_wallet_outlined),
                        ),
                        ButtonSegment(
                          value: ExpenseFundingSource.external,
                          label: Text('Externo'),
                          icon: Icon(Icons.person_outline),
                        ),
                      ],
                      selected: {fundingSource},
                      onSelectionChanged: (selection) => setDialogState(() => fundingSource = selection.first),
                    ),
                  ] else
                    Text('Origen: ${existing.fundingSource.label}', style: Get.textTheme.bodySmall),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                child: const Text('Cancelar'),
              ),
              Obx(() {
                return ElevatedButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : () async {
                          final description = descriptionController.text.trim();
                          final amount = double.tryParse(amountController.text.trim().replaceAll(',', '.'));

                          if (description.isEmpty) {
                            setDialogState(() => errorText = 'Ingresa una descripción');
                            return;
                          }
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ingresa un monto válido')),
                            );
                            return;
                          }

                          final ok = existing == null
                              ? await controller.createExpense(
                                  description: description,
                                  amount: amount,
                                  fundingSource: fundingSource,
                                )
                              : await controller.updateExpense(id: existing.id, description: description, amount: amount);

                          if (ok && context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop(true);
                          }
                        },
                  child: controller.isSaving.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar'),
                );
              }),
            ],
          );
        },
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existing == null ? 'Gasto agregado' : 'Gasto actualizado')),
      );
    }
  }

  Future<void> _confirmDelete(VegetableExpense expense) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar gasto?'),
        content: Text('Se eliminará "${expense.description}" por ${NumberFormatter.formatCurrency(expense.amount)}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            style: TextButton.styleFrom(foregroundColor: Get.theme.colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteExpense(expense.id);
    }
  }

  void _showDateFilterDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
            child: CustomDateRangePicker(
              rangeStart: controller.filterStart.value,
              rangeEnd: controller.filterEnd.value,
              onApplyFilter: (start, end, label) {
                controller.applyFilter(start, end, label);
                Navigator.of(context, rootNavigator: true).pop();
              },
              onClearFilter: () => controller.clearFilter(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos de Verduras'), elevation: 0),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo gasto'),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.expenses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = controller.filteredExpenses;

          return Column(
            children: [
              _buildTotalCard(controller),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Get.theme.disabledColor),
                            const SizedBox(height: 8),
                            const Text('Sin gastos en este período'),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: controller.loadExpenses,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppConfig.paddingMedium),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final expense = filtered[index];
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                              child: ListTile(
                                onTap: () => _openExpenseDialog(existing: expense),
                                leading: CircleAvatar(
                                  backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
                                  child: Icon(Icons.receipt_long_outlined, color: Get.theme.colorScheme.error),
                                ),
                                title: Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${expense.formattedDate} · ${expense.userName} · ${expense.fundingSource.label}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      NumberFormatter.formatCurrency(expense.amount),
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, color: Get.theme.colorScheme.error),
                                      onPressed: () => _confirmDelete(expense),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTotalCard(VegetableExpensesController controller) {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        color: Get.theme.colorScheme.error.withValues(alpha: 0.06),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gastado ${controller.filterLabel.value} · ${controller.filteredExpenses.length} gasto(s)', style: Get.textTheme.bodyMedium),
                  Text(
                    NumberFormatter.formatCurrency(controller.filteredTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            if (controller.filterStart.value != null)
              IconButton(
                tooltip: 'Volver a hoy',
                icon: const Icon(Icons.close),
                onPressed: controller.clearFilter,
              ),
            IconButton(
              tooltip: 'Filtrar por fecha',
              icon: const Icon(Icons.date_range),
              onPressed: _showDateFilterDialog,
            ),
          ],
        ),
      );
    });
  }
}
