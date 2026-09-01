// lib/features/vegetables/presentation/pages/vegetable_items_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../domain/entities/vegetable_item.dart';
import '../../domain/repositories/vegetables_repository.dart';
import '../controllers/vegetables_controller.dart';

/// Catalog management for the vegetables module: create/edit/deactivate
/// products, marking each as sold by weight (scale) or at a fixed price.
class VegetableItemsPage extends StatefulWidget {
  const VegetableItemsPage({super.key});

  @override
  State<VegetableItemsPage> createState() => _VegetableItemsPageState();
}

class _VegetableItemsPageState extends State<VegetableItemsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<VegetablesController>().loadItems(includeInactive: true);
    });
  }

  Future<void> _openItemDialog(VegetablesController controller, {VegetableItem? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final priceController = TextEditingController(
      text: existing == null
          ? ''
          : (existing.pricingType.isWeight ? existing.pricePerKg : existing.fixedPrice)?.toStringAsFixed(0) ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final Rx<VegetablePricingType> pricingType = (existing?.pricingType ?? VegetablePricingType.weight).obs;

    final saved = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(existing == null ? 'Nuevo producto' : 'Editar producto'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej: Papa, Manzana',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa un nombre' : null,
                    ),
                    const SizedBox(height: AppConfig.paddingMedium),
                    Obx(() => SegmentedButton<VegetablePricingType>(
                          segments: const [
                            ButtonSegment(
                              value: VegetablePricingType.weight,
                              label: Text('Por peso'),
                              icon: Icon(Icons.scale_outlined),
                            ),
                            ButtonSegment(
                              value: VegetablePricingType.fixed,
                              label: Text('Precio fijo'),
                              icon: Icon(Icons.sell_outlined),
                            ),
                          ],
                          selected: {pricingType.value},
                          onSelectionChanged: (selection) => pricingType.value = selection.first,
                        )),
                    const SizedBox(height: AppConfig.paddingMedium),
                    Obx(() => TextFormField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: pricingType.value.isWeight ? 'Precio por kilo' : 'Precio fijo',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                          ),
                          validator: (value) {
                            final parsed = double.tryParse(value?.trim() ?? '');
                            if (parsed == null || parsed <= 0) return 'Ingresa un precio válido';
                            return null;
                          },
                        )),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context, rootNavigator: true).pop(true);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true) return;

    final price = double.parse(priceController.text.trim());
    final params = VegetableItemParams(
      name: nameController.text.trim(),
      pricingType: pricingType.value,
      pricePerKg: pricingType.value.isWeight ? price : null,
      fixedPrice: pricingType.value.isFixed ? price : null,
    );

    await controller.saveItem(id: existing?.id, params: params);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Verduras'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openItemDialog(controller),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingItems.value && controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConfig.paddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco_outlined, size: 48, color: Get.theme.disabledColor),
                    const SizedBox(height: 8),
                    const Text('Aún no hay productos en el catálogo'),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadItems(includeInactive: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConfig.paddingMedium),
              itemCount: controller.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = controller.items[index];
                final priceLabel = item.pricingType.isWeight
                    ? '${NumberFormatter.formatCurrency(item.pricePerKg)} / kg'
                    : '${NumberFormatter.formatCurrency(item.fixedPrice)} c/u';

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.isActive
                          ? Get.theme.colorScheme.primary.withValues(alpha: 0.1)
                          : Get.theme.disabledColor.withValues(alpha: 0.1),
                      child: Icon(
                        item.pricingType.isWeight ? Icons.scale_outlined : Icons.sell_outlined,
                        color: item.isActive ? Get.theme.colorScheme.primary : Get.theme.disabledColor,
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        decoration: item.isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Text(priceLabel),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openItemDialog(controller, existing: item),
                        ),
                        if (item.isActive)
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Get.theme.colorScheme.error),
                            onPressed: () => controller.deleteItem(item.id),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
