// lib/features/breb/presentation/pages/breb_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/breb_api.dart';

/// Gris neutro legible tanto en tema claro como oscuro.
const _kMuted = Color(0xFF8A8F98);
const _kBorder = Color(0x33888888);


/// Monto de prueba del botón "Probar QR" — no cobra nada.
const int _kQrTestAmount = 1000;
const _kBrebGreen = Color(0xFF32AF60);

class _LlaveEntry {
  final String id;
  final TextEditingController labelCtrl;
  final TextEditingController llaveCtrl;
  final TextEditingController qrTemplateCtrl;
  bool showInInvoices;
  bool showInVegetables;

  _LlaveEntry({
    required this.id,
    String label = '',
    String llave = '',
    String qrTemplate = '',
    this.showInInvoices = true,
    this.showInVegetables = true,
  })  : labelCtrl = TextEditingController(text: label),
        llaveCtrl = TextEditingController(text: llave),
        qrTemplateCtrl = TextEditingController(text: qrTemplate);

  void dispose() {
    labelCtrl.dispose();
    llaveCtrl.dispose();
    qrTemplateCtrl.dispose();
  }
}

/// Configuración de los cobros Bre-B (solo administrador):
///  1. La dirección de correo a la que se reenvían los avisos del banco.
///  2. Las llaves del negocio, cada una con su QR opcional, y en QUÉ módulo
///     se muestra (Facturación, Verduras o ambos).
class BrebSettingsPage extends StatefulWidget {
  const BrebSettingsPage({super.key});

  @override
  State<BrebSettingsPage> createState() => _BrebSettingsPageState();
}

class _BrebSettingsPageState extends State<BrebSettingsPage> {
  final _api = BrebApi();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _inboundEmail = '';
  List<_LlaveEntry> _llaves = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (final l in _llaves) {
      l.dispose();
    }
    super.dispose();
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getSettings();
      for (final l in _llaves) {
        l.dispose();
      }
      _inboundEmail = data['inboundEmail'] as String? ?? '';
      _llaves = ((data['llaves'] as List?) ?? []).map((raw) {
        final l = Map<String, dynamic>.from(raw as Map);
        return _LlaveEntry(
          id: l['id'] as String? ?? _newId(),
          label: l['label'] as String? ?? '',
          llave: l['llave'] as String? ?? '',
          qrTemplate: l['qr_template'] as String? ?? '',
          showInInvoices: l['show_in_invoices'] as bool? ?? true,
          showInVegetables: l['show_in_vegetables'] as bool? ?? true,
        );
      }).toList();
    } catch (e) {
      _error = BrebApi.errorMessage(e, 'No se pudo cargar la configuración');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _testQr(int i) async {
    final template = _llaves[i].qrTemplateCtrl.text.trim();
    if (template.isEmpty) {
      _toast('Pega primero el texto del QR.');
      return;
    }
    try {
      final payload = await _api.previewQr(template, _kQrTestAmount.toDouble());
      if (!mounted) return;
      showDialog(context: context, builder: (_) => _QrTestPreviewDialog(payload: payload));
    } catch (e) {
      _toast('Plantilla inválida: ${BrebApi.errorMessage(e)}');
    }
  }

  Future<void> _save() async {
    final filled = _llaves.where((l) => l.llaveCtrl.text.trim().isNotEmpty).toList();
    final orphan = filled.where((l) => !l.showInInvoices && !l.showInVegetables).toList();
    if (orphan.isNotEmpty) {
      _toast('La llave "${orphan.first.labelCtrl.text.trim()}" no está en ningún módulo. '
          'Marca Facturación o Verduras (o quítala).');
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = filled
          .map((l) => {
                'id': l.id,
                'label': l.labelCtrl.text.trim().isEmpty ? 'Llave' : l.labelCtrl.text.trim(),
                'llave': l.llaveCtrl.text.trim(),
                if (l.qrTemplateCtrl.text.trim().isNotEmpty) 'qr_template': l.qrTemplateCtrl.text.trim(),
                'show_in_invoices': l.showInInvoices,
                'show_in_vegetables': l.showInVegetables,
              })
          .toList();
      await _api.saveSettings(payload);
      _toast('Llaves Bre-B guardadas.');
      await _load();
    } catch (e) {
      _toast('Error al guardar: ${BrebApi.errorMessage(e)}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos Bre-B')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _buildForm(),
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: _kBrebGreen),
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
                ),
              ),
            ),
    );
  }

  Widget _buildForm() {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _infoBanner(),
            const SizedBox(height: 20),
            _sectionTitle('1. Reenvía los avisos de tu banco a esta dirección'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'En el correo del negocio (Gmail/Outlook) crea una regla que reenvíe automáticamente los '
                    'avisos de pago recibido a esta dirección. Funciona con Nequi '
                    '(nequinotificaciones@nequi.com.co) y Bancolombia '
                    '(alertasynotificaciones@an.notificacionesbancolombia.com).',
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _inboundEmail));
                      _toast('Dirección copiada');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Row(children: [
                        Expanded(
                            child: SelectableText(_inboundEmail,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                        const Icon(Icons.copy, size: 16, color: _kBrebGreen),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _RecentEmailsSheet(api: _api),
                    ),
                    icon: const Icon(Icons.mail_outline, size: 18),
                    label: const Text('Ver correos recibidos'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Útil para confirmar el reenvío de Gmail (la primera vez pide confirmar la dirección) '
                    'o para revisar por qué un pago no se concilió solo.',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('2. Llaves Bre-B y en qué módulo se muestran'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agrega una por cada cuenta (Nequi, Bancolombia...). Marca en qué caja aparece cada una: '
                    'al cobrar, se le muestran al cliente TODAS las llaves de ese módulo con su QR.',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  const SizedBox(height: 12),
                  if (_llaves.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Todavía no hay llaves. Agrega la primera.', style: TextStyle(color: muted)),
                    ),
                  for (int i = 0; i < _llaves.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _llaveRow(i),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _llaves.add(_LlaveEntry(id: _newId()))),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar llave'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _llaveRow(int index) {
    final e = _llaves[index];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: e.labelCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nombre (Nequi, Bancolombia...)', isDense: true, border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: e.llaveCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Llave',
                    hintText: 'Ej: 3001234567 o @labomba',
                    prefixIcon: Icon(Icons.bolt, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: e.qrTemplateCtrl,
                  maxLines: 3,
                  minLines: 1,
                  style: const TextStyle(fontSize: 11),
                  decoration: const InputDecoration(
                    labelText: 'Texto del QR del banco (opcional)',
                    hintText: 'Pega acá el texto que trae el QR que te dio el banco',
                    prefixIcon: Icon(Icons.qr_code_2, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _testQr(index),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Probar QR'),
                    ),
                    const Spacer(),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      avatar: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: const Text('Facturación'),
                      selected: e.showInInvoices,
                      onSelected: (v) => setState(() => e.showInInvoices = v),
                    ),
                    FilterChip(
                      avatar: const Icon(Icons.eco_outlined, size: 16),
                      label: const Text('Verduras'),
                      selected: e.showInVegetables,
                      onSelected: (v) => setState(() => e.showInVegetables = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _llaves[index].dispose();
              _llaves.removeAt(index);
            }),
            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            tooltip: 'Quitar llave',
          ),
        ],
      ),
    );
  }

  Widget _infoBanner() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kBrebGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBrebGreen.withValues(alpha: 0.35)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.bolt, color: _kBrebGreen, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Al cobrar con Bre-B el sistema detecta la transferencia solo y registra la venta — sin '
                'comisiones y sin dar acceso a tu correo, solo el reenvío que tú configuras.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: _kMuted)),
      );

  Widget _card({required Widget child}) => Card(
        margin: EdgeInsets.zero,
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      );
}

/// Últimos correos que llegaron a la dirección Bre-B y no se conciliaron
/// solos — incluye la confirmación de reenvío de Gmail.
class _RecentEmailsSheet extends StatefulWidget {
  final BrebApi api;
  const _RecentEmailsSheet({required this.api});

  @override
  State<_RecentEmailsSheet> createState() => _RecentEmailsSheetState();
}

class _RecentEmailsSheetState extends State<_RecentEmailsSheet> {
  late Future<List<Map<String, dynamic>>> _future;
  static final _urlRegex = RegExp(r'https?://[^\s<>"\)]+');

  @override
  void initState() {
    super.initState();
    _future = widget.api.recentEmails();
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'unknown_slug':
        return 'Dirección desconocida';
      case 'not_approved':
        return 'Remitente no reconocido (ej. confirmación de reenvío de Gmail)';
      case 'not_a_sale':
        return 'Es del banco, pero no es un aviso de pago recibido';
      case 'parse_error':
        return 'No se pudo leer el formato';
      case 'status_rejected':
        return 'Pago con estado rechazado/no aprobado';
      case 'no_pending_match':
        return 'No había ningún cobro esperando ese monto';
      case 'multiple_matches':
        return 'Ambiguo — varios cobros con el mismo monto';
      case 'registration_failed':
        return 'El pago llegó pero la venta no se pudo registrar sola — asignar a mano';
      case 'already_claimed':
        return 'Otro correo ya estaba confirmando ese cobro';
      default:
        return reason;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d/M/y h:mm a');
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(children: [
              const Expanded(
                  child: Text('Correos recibidos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
              IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() => _future = widget.api.recentEmails())),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text(BrebApi.errorMessage(snap.error!)));
                }
                final emails = snap.data ?? const [];
                if (emails.isEmpty) {
                  return const Center(child: Text('Todavía no llegó ningún correo a tu dirección Bre-B.'));
                }
                return ListView.separated(
                  controller: scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: emails.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final e = emails[i];
                    final body = e['rawBody'] as String? ?? '';
                    final created = DateTime.tryParse(e['createdAt'] as String? ?? '');
                    final links = _urlRegex
                        .allMatches(body)
                        .map((m) => m.group(0)!.replaceAll(RegExp(r'[.,;]+$'), ''))
                        .toSet()
                        .toList();
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_reasonLabel(e['reason'] as String? ?? ''),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          if (created != null)
                            Text(fmt.format(created.toLocal()),
                                style: const TextStyle(fontSize: 10, color: _kMuted)),
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SelectableText(body.length > 500 ? '${body.substring(0, 500)}…' : body,
                                style: const TextStyle(fontSize: 12, height: 1.4)),
                          ],
                          for (final url in links)
                            TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: url));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Enlace copiado: ábrelo en el navegador para confirmar')));
                              },
                              icon: const Icon(Icons.link, size: 16),
                              label: const Text('Copiar enlace de confirmación'),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.warning_amber, size: 56, color: Colors.orange),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ]),
        ),
      );
}

class _QrTestPreviewDialog extends StatelessWidget {
  final String payload;
  const _QrTestPreviewDialog({required this.payload});

  @override
  Widget build(BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('QR de prueba', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Monto de prueba: \$$_kQrTestAmount (no se cobra nada)',
                style: TextStyle(fontSize: 12, color: _kMuted)),
            const SizedBox(height: 16),
            QrImageView(data: payload, size: 220, backgroundColor: Colors.white),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
            ),
          ]),
        ),
      );
}
