// lib/features/supervisor/presentation/pages/supervisor_main_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/supervisor_controller.dart';
import '../widgets/stats_card_widget.dart';
import '../widgets/task_filter_widget.dart';
import '../../domain/entities/product_update_task.dart';
import '../../../admin_tasks/domain/entities/temporary_product.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SupervisorMainPage extends StatefulWidget {
  const SupervisorMainPage({super.key});

  @override
  State<SupervisorMainPage> createState() => _SupervisorMainPageState();
}

class _SupervisorMainPageState extends State<SupervisorMainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isAdmin = authController.isAdmin;

    return GetBuilder<SupervisorController>(
      init: Get.find<SupervisorController>(),
      builder: (controller) => Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAdmin ? 'Tareas del Supervisor' : 'Mis Tareas',
                style: const TextStyle(fontSize: 18),
              ),
              if (isAdmin)
                Text(
                  'Vista de administrador',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
          actions: [
            if (isAdmin)
              Container(
                margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'ADMIN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.refreshData(),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.pending_actions), text: 'Pendientes'),
              Tab(icon: Icon(Icons.check_circle), text: 'Completadas'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPendingTasksTab(controller),
            _buildCompletedTasksTab(controller),
          ],
        ),
      ),
    );
  }

  // Dashboard Tab
  Widget _buildDashboardTab(SupervisorController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            _buildStatsSection(controller),

            const SizedBox(height: 24),

            // Recent Tasks Section
            const Text(
              'Tareas Recientes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Recent Pending Tasks (limited to 5)
            Obx(() {
              final recentTasks = controller.pendingTasks.take(5).toList();
              if (recentTasks.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('No hay tareas pendientes')),
                  ),
                );
              }

              return Column(
                children: recentTasks
                    .map(
                      (task) =>
                          _buildTaskCard(task, controller, showActions: false),
                    )
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Pending Tasks Tab - Includes both regular tasks and temporary products
  Widget _buildPendingTasksTab(SupervisorController controller) {
    return RefreshIndicator(
      onRefresh: () async {
        await controller.loadPendingTasks();
        await controller.loadPendingTemporaryProducts();
      },
      child: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            child: TaskFilterWidget(controller: controller),
          ),

          // Combined Tasks List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingPending || controller.isLoadingTemporaryProducts) {
                return const Center(child: CircularProgressIndicator());
              }

              // Determine what to show based on filter
              final showRegularTasks = controller.selectedFilter != 'new_product';
              final showTempProducts = controller.selectedFilter == 'all' ||
                                       controller.selectedFilter == 'new_product';

              final hasRegularTasks = showRegularTasks && controller.filteredPendingTasks.isNotEmpty;
              final hasTempProducts = showTempProducts && controller.pendingTemporaryProducts.isNotEmpty;

              if (!hasRegularTasks && !hasTempProducts) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pending_actions,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay tareas pendientes',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Regular pending tasks (only if filter allows)
                  if (showRegularTasks)
                    ...controller.filteredPendingTasks.map((task) =>
                      _buildTaskCard(task, controller, showActions: true)
                    ),
                  // Temporary products pending (only if filter allows)
                  if (showTempProducts)
                    ...controller.pendingTemporaryProducts.map((product) =>
                      _buildTemporaryProductCard(product, controller)
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // Completed Tasks Tab - Includes both regular tasks and temporary products
  Widget _buildCompletedTasksTab(SupervisorController controller) {
    // Load completed tasks and products when tab is accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.completedTasks.isEmpty && !controller.isLoadingCompleted) {
        controller.loadCompletedTasks();
      }
      if (controller.completedTemporaryProducts.isEmpty) {
        controller.loadCompletedTemporaryProducts();
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        await controller.loadCompletedTasks();
        await controller.loadCompletedTemporaryProducts();
      },
      child: Obx(() {
        if (controller.isLoadingCompleted || controller.isLoadingTemporaryProducts) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasRegularTasks = controller.completedTasks.isNotEmpty;
        final hasTempProducts = controller.completedTemporaryProducts.isNotEmpty;

        if (!hasRegularTasks && !hasTempProducts) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay tareas completadas',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Combine and sort all completed items by completion date
        final completedItems = <_CompletedItem>[];

        // Add regular tasks
        for (final task in controller.completedTasks) {
          completedItems.add(_CompletedItem(
            completedAt: task.completedAt ?? task.createdAt,
            isTask: true,
            task: task,
          ));
        }

        // Add temporary products
        for (final product in controller.completedTemporaryProducts) {
          completedItems.add(_CompletedItem(
            completedAt: product.completedBySupervisorAt ?? product.createdAt,
            isTask: false,
            product: product,
          ));
        }

        // Sort by completion date (most recent first)
        completedItems.sort((a, b) => b.completedAt.compareTo(a.completedAt));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: completedItems.map((item) {
            if (item.isTask) {
              return _buildCompletedTaskCard(item.task!);
            } else {
              return _buildCompletedTemporaryProductCard(item.product!);
            }
          }).toList(),
        );
      }),
    );
  }

  Widget _buildStatsSection(SupervisorController controller) {
    return Obx(() {
      final stats = controller.taskStats;

      if (controller.isLoadingStats) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      if (stats == null) {
        return const SizedBox.shrink();
      }

      return Row(
        children: [
          Expanded(
            child: StatsCardWidget(
              title: 'Pendientes',
              value: stats.pendingCount.toString(),
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCardWidget(
              title: 'Completadas',
              value: stats.completedCount.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCardWidget(
              title: 'Total',
              value: stats.totalCount.toString(),
              icon: Icons.assignment,
              color: Colors.blue,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTaskCard(
    ProductUpdateTask task,
    SupervisorController controller, {
    required bool showActions,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTaskDetails(Get.context!, task, controller),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with status
              Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.product.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Código: ${task.product.barcode}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildChangeTypeChip(task.changeType),
                ],
              ),

              const SizedBox(height: 12),

              // Task details
              if (task.description != null && task.description!.isNotEmpty) ...[
                Text(
                  'Descripción: ${task.formattedDescription}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 8),
              ],

              // Admin notes
              if (task.adminNotes != null && task.adminNotes!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Nota del admin: ${task.adminNotes!}',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Creado por: ${task.createdBy.username}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    task.formattedTimeSinceCreation,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

              if (showActions) ...[
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: TextButton.icon(
                        onPressed: () =>
                            _showTaskDetails(Get.context!, task, controller),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Ver detalles'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCompleteTaskDialog(
                          Get.context!,
                          controller,
                          task.id,
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Completar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedTaskCard(ProductUpdateTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCompletedTaskDetails(Get.context!, task),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with completion status
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.product.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Código: ${task.product.barcode}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildChangeTypeChip(task.changeType),
                ],
              ),

              const SizedBox(height: 12),

              // Completion details
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Completada por: ${task.completedBy?.username ?? 'Desconocido'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Completada: ${_formatCompletionTime(task.completedAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

              if (task.notes != null && task.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notas:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.notes!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        _showCompletedTaskDetails(Get.context!, task),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Ver detalles'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeTypeChip(ChangeType changeType) {
    Color chipColor;
    switch (changeType) {
      case ChangeType.price:
        chipColor = Colors.green;
        break;
      case ChangeType.info:
        chipColor = Colors.blue;
        break;
      case ChangeType.inventory:
        chipColor = Colors.orange;
        break;
      case ChangeType.arrival:
        chipColor = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIconForChangeType(changeType), size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            changeType.displayName,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForChangeType(ChangeType changeType) {
    switch (changeType) {
      case ChangeType.price:
        return Icons.monetization_on;
      case ChangeType.info:
        return Icons.info;
      case ChangeType.inventory:
        return Icons.inventory;
      case ChangeType.arrival:
        return Icons.local_shipping;
    }
  }

  String _formatCompletionTime(DateTime? completedAt) {
    if (completedAt == null) return 'Fecha desconocida';

    final now = DateTime.now();
    final difference = now.difference(completedAt);

    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'hace unos segundos';
    }
  }

  void _switchToTab(int tabIndex) {
    _tabController.animateTo(tabIndex);
  }

  void _showTaskDetails(
    BuildContext context,
    ProductUpdateTask task,
    SupervisorController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de la Tarea'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Producto:', task.product.description),
              _buildDetailRow('Código:', task.product.barcode),
              _buildDetailRow('Tipo de cambio:', task.changeType.displayName),
              _buildDetailRow('Estado:', task.status.displayName),
              if (task.description != null)
                _buildDetailRow('Descripción:', task.formattedDescription),
              if (task.adminNotes != null && task.adminNotes!.isNotEmpty)
                _buildNoteRow('Nota del Admin:', task.adminNotes!),
              _buildDetailRow('Creado:', task.formattedTimeSinceCreation),
              _buildDetailRow('Creado por:', task.createdBy.username),
              if (task.oldValue != null && task.newValue != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Cambios:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildChangesWidget(task),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (task.isPending)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showCompleteTaskDialog(context, controller, task.id);
              },
              child: const Text('Completar'),
            ),
        ],
      ),
    );
  }

  void _showCompletedTaskDetails(BuildContext context, ProductUpdateTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de la Tarea Completada'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Producto:', task.product.description),
              _buildDetailRow('Código:', task.product.barcode),
              _buildDetailRow('Tipo de cambio:', task.changeType.displayName),
              _buildDetailRow('Estado:', task.status.displayName),
              if (task.description != null)
                _buildDetailRow('Descripción:', task.formattedDescription),
              _buildDetailRow('Creado:', task.formattedTimeSinceCreation),
              _buildDetailRow('Creado por:', task.createdBy.username),
              if (task.completedBy != null)
                _buildDetailRow('Completado por:', task.completedBy!.username),
              if (task.completedAt != null)
                _buildDetailRow(
                  'Completado:',
                  _formatCompletionTime(task.completedAt),
                ),
              if (task.notes != null && task.notes!.isNotEmpty)
                _buildDetailRow('Notas:', task.notes!),
              if (task.oldValue != null && task.newValue != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Cambios:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildChangesWidget(task),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildNoteRow(String label, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note, size: 18, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note,
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangesWidget(ProductUpdateTask task) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.oldValue != null) ...[
            const Text(
              'Valor anterior:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              task.formattedOldValues,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],
          if (task.newValue != null) ...[
            const Text(
              'Valor nuevo:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              task.formattedNewValues,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCompleteTaskDialog(
    BuildContext context,
    SupervisorController controller,
    String taskId,
  ) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Tarea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Estás seguro de que quieres marcar esta tarea como completada?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Agrega cualquier comentario sobre la tarea...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isCompletingTask
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      controller.completeTask(
                        taskId,
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      );
                    },
              child: controller.isCompletingTask
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Completar'),
            ),
          ),
        ],
      ),
    );
  }

  // Build completed temporary product card (matches regular task card style)
  Widget _buildCompletedTemporaryProductCard(TemporaryProduct product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCompletedTemporaryProductDetails(Get.context!, product),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with completion status
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Producto Nuevo',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'Nuevo',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Dates details
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Creado ${_formatCompletionTime(product.createdAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Completado ${_formatCompletionTime(product.completedBySupervisorAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Completado por: ${product.completedBySupervisorUser?.username ?? 'Desconocido'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

              if (product.notes != null && product.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notas:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.notes!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        _showCompletedTemporaryProductDetails(Get.context!, product),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Ver detalles'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletedTemporaryProductDetails(
    BuildContext context,
    TemporaryProduct product,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Producto Completado'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre:', product.name),
              _buildDetailRow('Estado:', 'Completado'),
              _buildDetailRow('Creado:', _formatCompletionTime(product.createdAt)),
              if (product.completedBySupervisorAt != null)
                _buildDetailRow(
                  'Completado:',
                  _formatCompletionTime(product.completedBySupervisorAt),
                ),
              if (product.completedBySupervisorUser != null)
                _buildDetailRow(
                  'Completado por:',
                  product.completedBySupervisorUser!.username,
                ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow('Precio A:', product.precioA != null ? NumberFormatter.formatCurrency(product.precioA) : 'N/A'),
              if (product.precioB != null)
                _buildDetailRow('Precio B:', NumberFormatter.formatCurrency(product.precioB)),
              if (product.precioC != null)
                _buildDetailRow('Precio C:', NumberFormatter.formatCurrency(product.precioC)),
              if (product.costo != null)
                _buildDetailRow('Costo:', NumberFormatter.formatCurrency(product.costo)),
              if (product.iva != null)
                _buildDetailRow('IVA:', NumberFormatter.formatPercentage(product.iva)),
              if (product.notes != null && product.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _buildDetailRow('Notas:', product.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ===== Temporary Products Tab Methods =====

  Widget _buildTemporaryProductsTab(SupervisorController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.loadPendingTemporaryProducts(),
      child: Obx(() {
        if (controller.isLoadingTemporaryProducts) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.pendingTemporaryProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.new_releases, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay productos nuevos pendientes',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.pendingTemporaryProducts.length,
          itemBuilder: (context, index) {
            final product = controller.pendingTemporaryProducts[index];
            return _buildTemporaryProductCard(product, controller);
          },
        );
      }),
    );
  }

  // Build temporary product card with same style as regular task cards
  Widget _buildTemporaryProductCard(
    TemporaryProduct product,
    SupervisorController controller,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTemporaryProductDetails(Get.context!, product, controller),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with status
              Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Producto Nuevo',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.new_releases, size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text(
                          'Nuevo',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Product creation date and status
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Creado ${_formatCompletionTime(product.createdAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pendiente',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: TextButton.icon(
                      onPressed: () =>
                          _showTemporaryProductDetails(Get.context!, product, controller),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Ver detalles'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: () => _showCompleteTemporaryProductDialog(
                        Get.context!,
                        controller,
                        product.id,
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Completar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double? price) {
    if (price == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showTemporaryProductDetails(
    BuildContext context,
    TemporaryProduct product,
    SupervisorController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Producto Nuevo'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre:', product.name),
              _buildDetailRow('Creado:', _formatCompletionTime(product.createdAt)),
              _buildDetailRow('Estado:', 'Pendiente de aplicar'),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow('Precio A:', product.precioA != null ? NumberFormatter.formatCurrency(product.precioA) : 'N/A'),
              if (product.precioB != null)
                _buildDetailRow('Precio B:', NumberFormatter.formatCurrency(product.precioB)),
              if (product.precioC != null)
                _buildDetailRow('Precio C:', NumberFormatter.formatCurrency(product.precioC)),
              if (product.costo != null)
                _buildDetailRow('Costo:', NumberFormatter.formatCurrency(product.costo)),
              if (product.iva != null)
                _buildDetailRow('IVA:', NumberFormatter.formatPercentage(product.iva)),
              if (product.notes != null && product.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _buildDetailRow('Notas:', product.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCompleteTemporaryProductDialog(context, controller, product.id);
            },
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }

  void _showCompleteTemporaryProductDialog(
    BuildContext context,
    SupervisorController controller,
    String productId,
  ) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Has aplicado este producto en el sistema externo?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Agrega cualquier comentario...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isCompletingTemporaryProduct
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      controller.completeTemporaryProductWithBarcodeCheck(
                        productId,
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      );
                    },
              child: controller.isCompletingTemporaryProduct
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Completar'),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class to combine and sort completed tasks and products
class _CompletedItem {
  final DateTime completedAt;
  final bool isTask;
  final ProductUpdateTask? task;
  final TemporaryProduct? product;

  _CompletedItem({
    required this.completedAt,
    required this.isTask,
    this.task,
    this.product,
  });
}
