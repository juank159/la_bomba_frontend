// lib/features/invoices/presentation/pages/printer_settings_page.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../../../app/core/services/preferences_service.dart';
import '../../../../app/core/services/printer_destination.dart';
import '../../../../app/core/services/thermal_printer_sender.dart';
import '../../data/services/printer_service.dart';

/// Lets an admin configure the thermal receipt printer shared by every
/// feature that prints a receipt (Facturación, Verduras): either a
/// network printer (IP + port) or a USB printer installed in Windows.
///
/// Network printing works on Android, iOS, macOS, Windows and Linux -
/// browsers cannot open raw TCP sockets, so it's unavailable on Flutter
/// Web. USB printing only works on Windows desktop (it's sent through the
/// Windows Print Spooler), since that's the only platform where this app
/// can talk to the OS print subsystem directly.
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
  final ThermalPrinterSender _sender = getIt<ThermalPrinterSender>();

  PrinterConnectionType _connectionType = PrinterConnectionType.network;
  List<String> _usbPrinters = [];
  String? _selectedUsbPrinter;
  bool _isLoadingUsbPrinters = false;
  bool _isTesting = false;

  bool get _usbSupported => _sender.isUsbSupported;

  @override
  void initState() {
    super.initState();
    _connectionType = _preferencesService.getPrinterConnectionType();
    _ipController.text = _preferencesService.getPrinterIp() ?? '';
    _portController.text = _preferencesService.getPrinterPort().toString();
    _selectedUsbPrinter = _preferencesService.getPrinterUsbName();

    if (_usbSupported) _loadUsbPrinters();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadUsbPrinters() async {
    setState(() => _isLoadingUsbPrinters = true);
    try {
      final printers = await _sender.listInstalledPrinters();
      if (!mounted) return;
      setState(() {
        _usbPrinters = printers;
        if (_selectedUsbPrinter != null && !printers.contains(_selectedUsbPrinter)) {
          // La impresora guardada ya no está instalada/conectada.
          _selectedUsbPrinter = null;
        }
      });
    } finally {
      if (mounted) setState(() => _isLoadingUsbPrinters = false);
    }
  }

  /// Construye el destino a partir de lo que hay ahora mismo en el
  /// formulario (no de lo ya guardado), para poder probar/guardar sin
  /// desincronizarse. Devuelve null y muestra el aviso correspondiente si
  /// falta algo.
  PrinterDestination? _destinationFromForm() {
    if (_connectionType == PrinterConnectionType.usb) {
      final name = _selectedUsbPrinter;
      if (name == null || name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una impresora USB de la lista')),
        );
        return null;
      }
      return PrinterDestination.usb(usbPrinterName: name);
    }

    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la dirección IP de la impresora')),
      );
      return null;
    }
    final port = int.tryParse(_portController.text.trim()) ?? 9100;
    return PrinterDestination.network(ip: ip, port: port);
  }

  Future<void> _save() async {
    final destination = _destinationFromForm();
    if (destination == null) return;

    await _preferencesService.setPrinterConnectionType(_connectionType);
    if (destination.isUsb) {
      await _preferencesService.setPrinterUsbName(destination.usbPrinterName);
    } else {
      await _preferencesService.setPrinterIp(destination.ip);
      await _preferencesService.setPrinterPort(destination.port);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración de impresora guardada')),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _testConnection() async {
    final destination = _destinationFromForm();
    if (destination == null) return;

    setState(() => _isTesting = true);
    try {
      final success = await _printerService.testConnection(destination: destination);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Conexión exitosa. Revisa la impresora.' : 'No se pudo conectar. Verifica la configuración.',
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
                'Esta configuración se usa en toda la app (Facturación y Verduras) '
                'para imprimir recibos en tu impresora térmica de 80mm.',
                style: Get.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConfig.paddingLarge),
              SegmentedButton<PrinterConnectionType>(
                segments: const [
                  ButtonSegment(
                    value: PrinterConnectionType.network,
                    label: Text('Red (WiFi/Ethernet)'),
                    icon: Icon(Icons.wifi),
                  ),
                  ButtonSegment(
                    value: PrinterConnectionType.usb,
                    label: Text('USB'),
                    icon: Icon(Icons.usb),
                  ),
                ],
                selected: {_connectionType},
                onSelectionChanged: (selection) {
                  setState(() => _connectionType = selection.first);
                },
              ),
              const SizedBox(height: AppConfig.paddingLarge),
              if (_connectionType == PrinterConnectionType.network)
                _buildNetworkFields()
              else
                _buildUsbFields(),
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
                      : const Icon(Icons.print_outlined),
                  label: const Text('Imprimir prueba'),
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

  Widget _buildNetworkFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configura la IP de tu impresora térmica conectada a la misma red. '
          'El puerto estándar ESC/POS es 9100.',
          style: Get.textTheme.bodySmall,
        ),
        const SizedBox(height: AppConfig.paddingMedium),
        TextField(
          controller: _ipController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Dirección IP',
            hintText: 'Ej: 192.168.1.50',
            prefixIcon: const Icon(Icons.print_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
          ),
        ),
      ],
    );
  }

  Widget _buildUsbFields() {
    if (!_usbSupported) {
      return Container(
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'La impresión por USB solo está disponible en la app de escritorio para '
                'Windows. En este dispositivo usa la opción de Red.',
                style: TextStyle(color: Colors.orange[900]),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conecta la impresora por USB e instálala en Windows (con el driver del '
          'fabricante o como "Generic / Text Only"); luego selecciónala aquí.',
          style: Get.textTheme.bodySmall,
        ),
        const SizedBox(height: AppConfig.paddingMedium),
        Row(
          children: [
            Expanded(
              child: _isLoadingUsbPrinters
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _usbPrinters.isEmpty
                      ? Text(
                          'No se encontraron impresoras instaladas en Windows.',
                          style: Get.textTheme.bodySmall,
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: _selectedUsbPrinter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Impresora USB',
                            prefixIcon: const Icon(Icons.print_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                          ),
                          items: _usbPrinters
                              .map((name) => DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedUsbPrinter = value),
                        ),
            ),
            IconButton(
              tooltip: 'Actualizar lista',
              icon: const Icon(Icons.refresh),
              onPressed: _isLoadingUsbPrinters ? null : _loadUsbPrinters,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConfig.paddingMedium),
      padding: const EdgeInsets.all(AppConfig.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'La impresión no funciona en la versión web. Usa la app móvil o de '
              'escritorio para imprimir.',
              style: TextStyle(color: Colors.orange[900]),
            ),
          ),
        ],
      ),
    );
  }
}
