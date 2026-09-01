// lib/features/vegetables/presentation/pages/scale_settings_page.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../../../app/core/services/preferences_service.dart';
import '../../data/services/scale_service.dart';
import '../controllers/vegetables_controller.dart';

/// Lets the verdulero/admin pick the COM port and baud rate the Rochi
/// RC-A01E scale is connected to, and verify it's reading weight live.
///
/// Desktop-only: the scale connects by USB/serial cable to the same
/// computer running the app - not available on Web or mobile.
class ScaleSettingsPage extends StatefulWidget {
  const ScaleSettingsPage({super.key});

  @override
  State<ScaleSettingsPage> createState() => _ScaleSettingsPageState();
}

class _ScaleSettingsPageState extends State<ScaleSettingsPage> {
  final PreferencesService _preferencesService = getIt<PreferencesService>();
  final ScaleService _scaleService = getIt<ScaleService>();

  List<String> _availablePorts = [];
  String? _selectedPort;
  final TextEditingController _baudRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPort = _preferencesService.getScalePort();
    _baudRateController.text = _preferencesService.getScaleBaudRate().toString();
    _refreshPorts();
  }

  @override
  void dispose() {
    _baudRateController.dispose();
    super.dispose();
  }

  void _refreshPorts() {
    if (kIsWeb) return;
    try {
      setState(() => _availablePorts = _scaleService.listAvailablePorts());
    } catch (_) {
      setState(() => _availablePorts = []);
    }
  }

  Future<void> _save() async {
    if (_selectedPort == null || _selectedPort!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el puerto de la báscula')),
      );
      return;
    }
    final baudRate = int.tryParse(_baudRateController.text.trim()) ?? 9600;

    await _preferencesService.setScalePort(_selectedPort!);
    await _preferencesService.setScaleBaudRate(baudRate);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración de báscula guardada')),
    );

    // Reconectar con la nueva configuración para que se refleje de inmediato.
    final controller = Get.find<VegetablesController>();
    controller.disconnectScale();
    await controller.connectScale();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Báscula Electrónica'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConfig.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kIsWeb) _buildWebWarning(),
              Text(
                'Configura el puerto serial (COM) al que está conectada la báscula '
                'Rochi RC-A01E por cable USB. El valor por defecto de velocidad '
                '(baud rate) para este tipo de báscula es 9600.',
                style: Get.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConfig.paddingLarge),
              DropdownButtonFormField<String>(
                initialValue: _availablePorts.contains(_selectedPort) ? _selectedPort : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Puerto serial',
                  prefixIcon: const Icon(Icons.usb),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                ),
                items: _availablePorts
                    .map((port) => DropdownMenuItem(value: port, child: Text(port)))
                    .toList(),
                onChanged: kIsWeb ? null : (value) => setState(() => _selectedPort = value),
                hint: Text(_availablePorts.isEmpty ? 'No se detectaron puertos' : 'Selecciona un puerto'),
              ),
              TextButton.icon(
                onPressed: kIsWeb ? null : _refreshPorts,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar lista de puertos'),
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              TextField(
                controller: _baudRateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Baud rate',
                  hintText: '9600',
                  prefixIcon: const Icon(Icons.speed_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                ),
              ),
              const SizedBox(height: AppConfig.paddingLarge),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: kIsWeb ? null : _save,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Guardar y conectar'),
                ),
              ),
              const SizedBox(height: AppConfig.paddingLarge),
              _buildLiveReading(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveReading(VegetablesController controller) {
    return Obx(() {
      final connected = controller.isScaleConnected.value;
      final weight = controller.liveWeight.value;
      final error = controller.scaleError.value;

      return Container(
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        decoration: BoxDecoration(
          color: (connected ? Get.theme.colorScheme.primary : Get.theme.disabledColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  connected ? Icons.scale : Icons.scale_outlined,
                  color: connected ? Get.theme.colorScheme.primary : Get.theme.disabledColor,
                ),
                const SizedBox(width: 8),
                Text(connected ? 'Báscula conectada' : 'Báscula desconectada', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              connected
                  ? (weight != null ? 'Lectura actual: ${weight.toStringAsFixed(3)} kg' : 'Esperando lectura de la báscula...')
                  : 'Guarda un puerto para conectar la báscula',
              style: Get.textTheme.bodyMedium,
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(error, style: TextStyle(color: Get.theme.colorScheme.error, fontSize: 12)),
            ],
          ],
        ),
      );
    });
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
              'La conexión con la báscula no funciona en la versión web. Usa la '
              'app de escritorio (Windows/macOS) donde está conectada la báscula.',
              style: TextStyle(color: Colors.orange[900]),
            ),
          ),
        ],
      ),
    );
  }
}
