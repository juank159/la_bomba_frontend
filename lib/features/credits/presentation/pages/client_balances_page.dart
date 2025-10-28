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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.account_balance_wallet_outlined),
              text: 'Saldos a Favor',
            ),
            Tab(
              icon: Icon(Icons.history_outlined),
              text: 'Devoluciones',
            ),
          ],
        ),
        actions: [
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
