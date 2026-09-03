// lib/features/corresponsal/presentation/pages/corresponsal_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../expenses/presentation/widgets/custom_date_range_picker.dart';
import '../../domain/entities/corresponsal_entry.dart';
import '../../domain/usecases/corresponsal_usecases.dart';
import '../controllers/corresponsal_controller.dart';

/// Corresponsal bancario: registra rápido la comisión que se cobra cada
/// vez que alguien retira efectivo (ej. retira \$1.000.000, se cobran
/// \$1.000 - eso es lo que se registra acá como ingreso). Valores rápidos
/// + campo libre, con la sumatoria del día y un filtro por fecha igual al
/// de Gastos.
class CorresponsalPage extends StatefulWidget {
  const CorresponsalPage({super.key});

  @override
  State<CorresponsalPage> createState() => _CorresponsalPageState();
}

class _CorresponsalPageState extends State<CorresponsalPage> {
  static const _quickAmounts = [500.0, 1000.0, 2000.0, 3000.0, 4000.0];

  late final CorresponsalController controller;
  final _customAmountController = TextEditingController();
  final _noteController = TextEditingController();
  double? _selectedQuickAmount;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CorresponsalController>()) {
      controller = Get.find<CorresponsalController>();
    } else {
      controller = Get.put(
        CorresponsalController(
          getEntriesUseCase: getIt<GetCorresponsalEntriesUseCase>(),
          createEntryUseCase: getIt<CreateCorresponsalEntryUseCase>(),
          deleteEntryUseCase: getIt<DeleteCorresponsalEntryUseCase>(),
        ),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.loadEntries());
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _pickQuickAmount(double amount) {
    setState(() {
      _selectedQuickAmount = amount;
      _customAmountController.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _register() async {
    final amount = double.tryParse(_customAmountController.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido')),
      );
      return;
    }

    final note = _noteController.text.trim();
    final ok = await controller.createEntry(amount: amount, note: note.isEmpty ? null : note);
    if (ok && mounted) {
      setState(() {
        _selectedQuickAmount = null;
        _customAmountController.clear();
        _noteController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registrado: ${NumberFormatter.formatCurrency(amount)}')),
      );
    }
  }

  Future<void> _confirmDelete(CorresponsalEntry entry) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar registro?'),
        content: Text('Se eliminará el ingreso de ${NumberFormatter.formatCurrency(entry.amount)}.'),
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
    if (confirmed == true) await controller.deleteEntry(entry.id);
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
      appBar: AppBar(title: const Text('Corresponsal'), elevation: 0),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.loadEntries,
            child: ListView(
              padding: const EdgeInsets.all(AppConfig.paddingMedium),
              children: [
                _buildQuickEntryCard(),
                const SizedBox(height: AppConfig.paddingLarge),
                _buildTotalCard(),
                const SizedBox(height: AppConfig.paddingMedium),
                if (controller.filteredEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.compare_arrows, size: 40, color: Get.theme.disabledColor),
                          const SizedBox(height: 8),
                          Text('Sin registros en este período', style: Get.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  )
                else
                  ...controller.filteredEntries.map(_buildEntryTile),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickEntryCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrar comisión', style: Get.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((amount) {
                final selected = _selectedQuickAmount == amount;
                return ChoiceChip(
                  label: Text(NumberFormatter.formatCurrency(amount)),
                  selected: selected,
                  onSelected: (_) => _pickQuickAmount(amount),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            TextField(
              controller: _customAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _selectedQuickAmount = null),
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
              ),
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Ej: retiro de \$1.000.000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
              ),
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            Obx(() {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isSaving.value ? null : _register,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: controller.isSaving.value
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Registrar'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total ${controller.filterLabel.value}', style: Get.textTheme.bodyMedium),
                  Text(
                    NumberFormatter.formatCurrency(controller.filteredTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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

  Widget _buildEntryTile(CorresponsalEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.compare_arrows, color: Get.theme.colorScheme.primary),
        ),
        title: Text(NumberFormatter.formatCurrency(entry.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [entry.formattedTime, entry.userName, if (entry.note != null && entry.note!.isNotEmpty) entry.note!].join(' · '),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Get.theme.colorScheme.error),
          onPressed: () => _confirmDelete(entry),
        ),
      ),
    );
  }
}
