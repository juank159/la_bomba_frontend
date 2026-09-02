// lib/features/vegetables/presentation/pages/vegetable_items_page.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../domain/entities/vegetable_category.dart';
import '../../domain/entities/vegetable_item.dart';
import '../../domain/repositories/vegetables_repository.dart';
import '../../data/services/vegetable_image_service.dart';
import '../controllers/vegetables_controller.dart';

/// Catalog management for the vegetables module: create/edit/deactivate
/// products, marking each as sold by weight (scale) or at a fixed price,
/// and grouped under a category (ej. Verduras, Frutas).
class VegetableItemsPage extends StatefulWidget {
  const VegetableItemsPage({super.key});

  @override
  State<VegetableItemsPage> createState() => _VegetableItemsPageState();
}

class _VegetableItemsPageState extends State<VegetableItemsPage> {
  late final TextEditingController searchController;
  final VegetableImageService _imageService = VegetableImageService();

  @override
  void initState() {
    super.initState();
    final controller = Get.find<VegetablesController>();
    searchController = TextEditingController(text: controller.itemsSearchQuery.value);
    searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadItems(includeInactive: true);
      controller.loadCategories();
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Get.find<VegetablesController>().searchItems(searchController.text);
  }

  void _clearSearch() {
    searchController.clear();
  }

  Future<void> _openItemDialog(VegetablesController controller, {VegetableItem? existing}) async {
    if (controller.categories.isEmpty) {
      await controller.loadCategories();
    }

    final nameController = TextEditingController(text: existing?.name ?? '');
    final priceController = TextEditingController(
      text: existing == null
          ? ''
          : (existing.pricingType.isWeight ? existing.pricePerKg : existing.fixedPrice)?.toStringAsFixed(0) ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final Rx<VegetablePricingType> pricingType = (existing?.pricingType ?? VegetablePricingType.weight).obs;
    final Rx<String?> selectedCategoryId = Rx<String?>(existing?.categoryId);
    final Rx<String?> imageBase64 = Rx<String?>(existing?.image);
    bool imageChanged = false;

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
                    Center(
                      child: Obx(() => _buildImagePicker(
                            imageBase64.value,
                            onPick: () async {
                              final picked = await _imageService.pickAndCompress();
                              if (picked != null) {
                                imageBase64.value = picked;
                                imageChanged = true;
                              }
                            },
                            onRemove: imageBase64.value == null
                                ? null
                                : () {
                                    imageBase64.value = null;
                                    imageChanged = true;
                                  },
                          )),
                    ),
                    const SizedBox(height: AppConfig.paddingMedium),
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
                    Obx(() {
                      final categories = controller.categories;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: categories.any((c) => c.id == selectedCategoryId.value)
                                  ? selectedCategoryId.value
                                  : null,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Categoría',
                                prefixIcon: const Icon(Icons.category_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                              ),
                              hint: const Text('Sin categoría'),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('Sin categoría')),
                                ...categories.map(
                                  (c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
                                ),
                              ],
                              onChanged: (value) => selectedCategoryId.value = value,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Nueva categoría',
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () async {
                              final created = await _createCategoryInline(controller);
                              if (created != null) selectedCategoryId.value = created.id;
                            },
                          ),
                        ],
                      );
                    }),
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
      categoryId: selectedCategoryId.value,
      pricingType: pricingType.value,
      pricePerKg: pricingType.value.isWeight ? price : null,
      fixedPrice: pricingType.value.isFixed ? price : null,
      // null = "deja la foto como está" (no se tocó); '' = se quitó.
      image: imageChanged ? (imageBase64.value ?? '') : null,
    );

    await controller.saveItem(id: existing?.id, params: params);
  }

  /// Círculo de foto del producto: toca para elegir/cambiar, con botón de
  /// quitar si ya hay una. Mismo tamaño siempre para que el diálogo no salte.
  Widget _buildImagePicker(
    String? imageBase64, {
    required VoidCallback onPick,
    VoidCallback? onRemove,
  }) {
    return Stack(
      children: [
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(48),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Get.theme.colorScheme.primary.withValues(alpha: 0.08),
              border: Border.all(color: Get.theme.dividerColor),
              image: (imageBase64 != null && imageBase64.isNotEmpty)
                  ? DecorationImage(image: MemoryImage(base64Decode(imageBase64)), fit: BoxFit.cover)
                  : null,
            ),
            child: (imageBase64 == null || imageBase64.isEmpty)
                ? Icon(Icons.add_a_photo_outlined, color: Get.theme.colorScheme.primary, size: 28)
                : null,
          ),
        ),
        if (onRemove != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Get.theme.colorScheme.error,
                  border: Border.all(color: Get.theme.colorScheme.surface, width: 2),
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  /// Diálogo rápido para crear una categoría sin salir del formulario de
  /// producto - evita el ir-y-volver de "necesito una categoría nueva".
  Future<VegetableCategory?> _createCategoryInline(VegetablesController controller) async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nueva categoría'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Verduras, Frutas',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa un nombre' : null,
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
      ),
    );

    if (saved != true) return null;

    final ok = await controller.saveCategory(
      params: VegetableCategoryParams(name: nameController.text.trim()),
    );
    if (!ok) return null;

    return controller.categories.firstWhere((c) => c.name == nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Verduras'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Categorías',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => Get.toNamed(AppRoutes.vegetableCategories),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openItemDialog(controller),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Obx(() {
              // No tiene sentido mostrar el buscador si aún no hay nada que buscar.
              if (controller.isLoadingItems.value && controller.items.isEmpty) {
                return const SizedBox.shrink();
              }
              if (controller.items.isEmpty) return const SizedBox.shrink();
              return _buildSearchBar(controller);
            }),
            Expanded(
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

                final filtered = controller.filteredItems;

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConfig.paddingLarge),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Get.theme.disabledColor),
                          const SizedBox(height: 8),
                          Text('Sin resultados para "${controller.itemsSearchQuery.value}"'),
                          const SizedBox(height: 8),
                          TextButton(onPressed: _clearSearch, child: const Text('Limpiar búsqueda')),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => controller.loadItems(includeInactive: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final priceLabel = item.pricingType.isWeight
                          ? '${NumberFormatter.formatCurrency(item.pricePerKg)} / kg'
                          : '${NumberFormatter.formatCurrency(item.fixedPrice)} c/u';
                      final subtitle = item.category != null ? '${item.category!.name} · $priceLabel' : priceLabel;

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.isActive
                                ? Get.theme.colorScheme.primary.withValues(alpha: 0.1)
                                : Get.theme.disabledColor.withValues(alpha: 0.1),
                            backgroundImage: item.hasImage ? MemoryImage(base64Decode(item.image!)) : null,
                            child: item.hasImage
                                ? null
                                : Icon(
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
                          subtitle: Text(subtitle),
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
          ],
        ),
      ),
    );
  }

  /// Buscador instantáneo por nombre o categoría - filtra en el cliente
  /// mientras se escribe, sin depender de la red, para encontrar un
  /// producto y cambiar su precio sin tener que hacer scroll.
  Widget _buildSearchBar(VegetablesController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConfig.paddingMedium,
        AppConfig.paddingMedium,
        AppConfig.paddingMedium,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomInput(
            controller: searchController,
            hintText: 'Buscar producto o categoría...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Obx(() {
              if (controller.itemsSearchQuery.value.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
              );
            }),
          ),
          Obx(() {
            final query = controller.itemsSearchQuery.value;
            if (query.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                '${controller.filteredItems.length} de ${controller.items.length} productos',
                style: Get.textTheme.bodySmall,
              ),
            );
          }),
        ],
      ),
    );
  }
}
