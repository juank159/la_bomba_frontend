// lib/features/invoices/presentation/pages/printer_settings_page.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../../../app/core/services/preferences_service.dart';
import '../../data/services/printer_service.dart';

/// Lets the admin configure the network (IP + port) thermal receipt
/// printer used to print invoices, and send a test ticket.
///
/// Note: network TCP printing only works on Android, iOS, macOS, Windows
/// and Linux builds - browsers cannot open raw TCP sockets, so this
/// feature is unavailable when running as Flutter Web.
class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final PreferencesService _preferencesService = getIt<PreferencesService>();
  final PrinterService _printerService = getIt<PrinterService>();

  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _ipController.text = _preferencesService.getPrinterIp() ?? '';
    _portController.text = _preferencesService.getPrinterPort().toString();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9100;

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la dirección IP de la impresora')),
      );
      return;
    }

    await _preferencesService.setPrinterIp(ip);
    await _preferencesService.setPrinterPort(port);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración de impresora guardada')),
    );
  }

  Future<void> _testConnection() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9100;

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la dirección IP de la impresora')),
      );
      return;
    }

    setState(() => _isTesting = true);

    try {
      final success = await _printerService.testConnection(ip: ip, port: port);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Conexión exitosa. Revisa la impresora.'
                : 'No se pudo conectar. Verifica la IP, el puerto y la red.',
          ),
        ),
      );
    } on PrinterException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impresora Térmica'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConfig.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kIsWeb) _buildWebWarning(),
              Text(
                'Configura la IP de tu impresora térmica de 80mm conectada a la '
                'misma red WiFi. El puerto estándar ESC/POS es 9100.',
                style: Get.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConfig.paddingLarge),
              TextField(
                controller: _ipController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Dirección IP',
                  hintText: 'Ej: 192.168.1.50',
                  prefixIcon: const Icon(Icons.print_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  ),
                ),
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Puerto',
                  hintText: '9100',
                  prefixIcon: const Icon(Icons.settings_ethernet),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  ),
                ),
              ),
              const SizedBox(height: AppConfig.paddingLarge),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Guardar'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (kIsWeb || _isTesting) ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: const Text('Probar conexión'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConfig.paddingMedium),
      padding: const EdgeInsets.all(AppConfig.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'La impresión por red no funciona en la versión web. Usa la app '
              'móvil o de escritorio para imprimir.',
              style: TextStyle(color: Colors.orange[900]),
            ),
          ),
        ],
      ),
    );
  }
}
