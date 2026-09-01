// lib/features/vegetables/presentation/pages/vegetable_categories_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../domain/entities/vegetable_category.dart';
import '../../domain/repositories/vegetables_repository.dart';
import '../controllers/vegetables_controller.dart';

/// Manages the categories used to group the vegetables catalog
/// (e.g. "Verduras", "Frutas") - independent from the products themselves,
/// so the business can add/rename categories without touching any product.
class VegetableCategoriesPage extends StatefulWidget {
  const VegetableCategoriesPage({super.key});

  @override
  State<VegetableCategoriesPage> createState() => _VegetableCategoriesPageState();
}

class _VegetableCategoriesPageState extends State<VegetableCategoriesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<VegetablesController>().loadCategories(includeInactive: true);
    });
  }

  Future<void> _openCategoryDialog(VegetablesController controller, {VegetableCategory? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(existing == null ? 'Nueva categoría' : 'Editar categoría'),
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
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                Get.back(result: true);
              }
            },
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

    if (saved != true) return;

    await controller.saveCategory(
      id: existing?.id,
      params: VegetableCategoryParams(name: nameController.text.trim()),
    );
  }

  Future<void> _confirmDelete(VegetablesController controller, VegetableCategory category) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar categoría?'),
        content: Text(
          'Los productos que ya tienen la categoría "${category.name}" la conservan; '
          'solo dejará de aparecer para elegirla en productos nuevos.',
        ),
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
      await controller.deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías de Verduras'),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategoryDialog(controller),
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingCategories.value && controller.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConfig.paddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category_outlined, size: 48, color: Get.theme.disabledColor),
                    const SizedBox(height: 8),
                    const Text('Aún no hay categorías. Crea la primera, ej. "Verduras" o "Frutas".'),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadCategories(includeInactive: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConfig.paddingMedium),
              itemCount: controller.categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: category.isActive
                          ? Get.theme.colorScheme.primary.withValues(alpha: 0.1)
                          : Get.theme.disabledColor.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.category_outlined,
                        color: category.isActive ? Get.theme.colorScheme.primary : Get.theme.disabledColor,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: TextStyle(
                        decoration: category.isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openCategoryDialog(controller, existing: category),
                        ),
                        if (category.isActive)
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Get.theme.colorScheme.error),
                            onPressed: () => _confirmDelete(controller, category),
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
