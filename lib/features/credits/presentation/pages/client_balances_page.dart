// lib/features/credits/presentation/pages/client_balances_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/client_balance_controller.dart';
import '../controllers/refund_history_controller.dart';
import '../controllers/payment_method_controller.dart';
import '../widgets/client_balances_tab.dart';
import '../widgets/refund_history_tab.dart';
import '../widgets/refund_dialog.dart';
import '../../domain/entities/client_balance.dart';

/// Página principal que muestra saldos a favor y devoluciones con tabs
class ClientBalancesPage extends StatefulWidget {
  const ClientBalancesPage({super.key});

  @override
  State<ClientBalancesPage> createState() => _ClientBalancesPageState();
}

class _ClientBalancesPageState extends State<ClientBalancesPage>
    with SingleTickerProviderStateMixin {
  late final ClientBalanceController balanceController;
  late final RefundHistoryController refundController;
  late final PaymentMethodController paymentMethodController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores
    balanceController = Get.put(ClientBalanceController());
    refundController = Get.put(RefundHistoryController());
    paymentMethodController = Get.put(PaymentMethodController());

    // Configurar TabController
    _tabController = TabController(length: 2, vsync: this);

    // Escuchar cambios de tab
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Recargar datos cuando cambie de tab
        if (_tabController.index == 0) {
          balanceController.loadAllBalances();
        } else if (_tabController.index == 1) {
          refundController.loadRefundHistory();
        }
      }
    });

    // 🔥 CARGAR DATOS AUTOMÁTICAMENTE AL ENTRAR
    // Cargar saldos a favor (tab por defecto)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      balanceController.loadAllBalances();
      refundController.loadRefundHistory(); // Precargar devoluciones también
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Saldos'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Builder(
            builder: (context) {
              // Obtener colores del tema - mismo patrón que product_detail_page
              final colorScheme = Theme.of(context).colorScheme;

              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: colorScheme.primary,
                  indicatorWeight: 4,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.primary,
                        width: 4,
                      ),
                    ),
                  ),
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.account_balance_wallet, size: 22),
                      text: 'Saldos a Favor',
                      height: 60,
                    ),
                    Tab(
                      icon: Icon(Icons.history, size: 22),
                      text: 'Devoluciones',
                      height: 60,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          // Botón de historial de transacciones (solo visible en tab de saldos)
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.toNamed('/balance-history');
            },
            tooltip: 'Historial de Transacciones',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_tabController.index == 0) {
                balanceController.loadAllBalances();
              } else {
                refundController.loadRefundHistory();
              }
            },
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Saldos a Favor
          ClientBalancesTab(
            controller: balanceController,
            onRefundPressed: (balance) => _showRefundDialog(context, balance),
          ),

          // Tab 2: Historial de Devoluciones
          RefundHistoryTab(
            controller: refundController,
          ),
        ],
      ),
    );
  }

  /// Muestra el diálogo para devolver dinero al cliente
  void _showRefundDialog(BuildContext context, ClientBalance balance) {
    showDialog(
      context: context,
      builder: (dialogContext) => RefundDialog(
        balance: balance,
        balanceController: balanceController,
        paymentMethodController: paymentMethodController,
        onRefundSuccess: () {
          // Recargar ambos tabs después de una devolución exitosa
          balanceController.loadAllBalances();
          refundController.loadRefundHistory();
        },
      ),
    );
  }
}
