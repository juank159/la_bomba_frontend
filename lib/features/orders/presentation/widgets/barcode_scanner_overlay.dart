import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/config/app_config.dart';

/// Barcode scanner overlay widget with mobile_scanner
/// Optimized for PWA: reuses camera controller to avoid repeated permission prompts
class BarcodeScannerOverlay extends StatefulWidget {
  final Function(String) onBarcodeDetected;
  final VoidCallback onClose;

  const BarcodeScannerOverlay({
    super.key,
    required this.onBarcodeDetected,
    required this.onClose,
  });

  @override
  State<BarcodeScannerOverlay> createState() => _BarcodeScannerOverlayState();
}

class _BarcodeScannerOverlayState extends State<BarcodeScannerOverlay> {
  // Singleton controller - persists across widget instances to avoid
  // repeated camera permission prompts on PWA/web
  static MobileScannerController? _sharedController;
  static bool _controllerInUse = false;

  bool _hasDetected = false;
  String? _detectedCode;
  bool _isStarting = true;

  MobileScannerController get _controller {
    _sharedController ??= _createController();
    return _sharedController!;
  }

  static MobileScannerController _createController() {
    return MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      detectionTimeoutMs: 150,
      facing: CameraFacing.back,
      returnImage: false,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.codabar,
        BarcodeFormat.itf,
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _controllerInUse = true;
    _startScanner();
  }

  Future<void> _startScanner() async {
    try {
      await _controller.start();
    } catch (e) {
      // If the shared controller is in a bad state, recreate it
      _sharedController?.dispose();
      _sharedController = _createController();
      try {
        await _sharedController!.start();
      } catch (_) {
        // Camera permission denied or unavailable
      }
    }
    if (mounted) {
      setState(() => _isStarting = false);
    }
  }

  @override
  void dispose() {
    _controllerInUse = false;
    // Just stop, don't dispose - keeps permission alive for next use
    _controller.stop();
    super.dispose();
  }

  /// Call this to fully release camera resources when app doesn't need scanner anymore
  static void releaseCamera() {
    if (!_controllerInUse) {
      _sharedController?.dispose();
      _sharedController = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          // Scanner View
          if (!_isStarting)
            MobileScanner(
              controller: _controller,
              onDetect: _onBarcodeDetected,
              errorBuilder: (context, error) => _buildErrorView(error),
            )
          else
            _buildLoadingView(),

          // Overlay UI - lighter for better camera visibility
          _buildOverlayUI(),

          // Close Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: _buildCloseButton(),
          ),

          // Flashlight Toggle (only on non-web platforms)
          if (!kIsWeb)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: _buildFlashlightButton(),
            ),

          // Detected code feedback
          if (_detectedCode != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 32,
              left: 32,
              right: 32,
              child: _buildDetectedFeedback(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetectedFeedback() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppConfig.successColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              _detectedCode!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayUI() {
    return Container(
      decoration: ShapeDecoration(
        shape: _ScannerOverlayShape(),
      ),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const Expanded(flex: 3, child: SizedBox.expand()),
          const Spacer(flex: 1),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppConfig.paddingLarge),
            padding: const EdgeInsets.all(AppConfig.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
                const SizedBox(height: AppConfig.paddingSmall),
                const Text(
                  'Escanear Codigo de Barras',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConfig.paddingSmall),
                Text(
                  'Coloca el codigo de barras dentro del marco',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Container(
      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: IconButton(
        onPressed: widget.onClose,
        icon: const Icon(Icons.close, color: Colors.white, size: 28),
        tooltip: 'Cerrar escaner',
      ),
    );
  }

  Widget _buildFlashlightButton() {
    return Container(
      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: IconButton(
        onPressed: () => _controller.toggleTorch(),
        icon: const Icon(Icons.flash_on, color: Colors.white, size: 28),
        tooltip: 'Alternar linterna',
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: AppConfig.paddingMedium),
            Text('Iniciando camara...', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(MobileScannerException error) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: AppConfig.paddingMedium),
              const Text(
                'Error del escaner',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConfig.paddingSmall),
              Text(
                error.errorDetails?.message ?? 'No se pudo acceder a la camara. Verifica los permisos.',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConfig.paddingLarge),
              ElevatedButton(onPressed: widget.onClose, child: const Text('Cerrar')),
            ],
          ),
        ),
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasDetected) return;

    for (final barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        final cleanCode = code.trim();

        _hasDetected = true;
        _controller.stop();

        HapticFeedback.mediumImpact();

        if (mounted) {
          setState(() => _detectedCode = cleanCode);
        }

        Future.microtask(() {
          widget.onBarcodeDetected(cleanCode);
        });

        break;
      }
    }
  }
}

/// Custom shape for scanner overlay with transparent scanning area
class _ScannerOverlayShape extends ShapeBorder {
  const _ScannerOverlayShape();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final Path outerPath = Path()..addRect(rect);

    // Larger scan area for easier scanning
    final double scanWidth = rect.width * 0.85;
    final double scanHeight = scanWidth * 0.55;
    final Rect scanArea = Rect.fromCenter(
      center: rect.center,
      width: scanWidth,
      height: scanHeight,
    );

    final Path scanPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanArea, const Radius.circular(AppConfig.borderRadius)),
      );

    return Path.combine(PathOperation.difference, outerPath, scanPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // Much lighter overlay - 35% opacity instead of 60%
    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect), paint);

    // Scanner frame corners
    final double scanWidth = rect.width * 0.85;
    final double scanHeight = scanWidth * 0.55;
    final Rect scanArea = Rect.fromCenter(
      center: rect.center,
      width: scanWidth,
      height: scanHeight,
    );

    final Paint framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const double cornerLength = 30;

    // Top-left
    canvas.drawLine(Offset(scanArea.left, scanArea.top + cornerLength), Offset(scanArea.left, scanArea.top), framePaint);
    canvas.drawLine(Offset(scanArea.left, scanArea.top), Offset(scanArea.left + cornerLength, scanArea.top), framePaint);

    // Top-right
    canvas.drawLine(Offset(scanArea.right - cornerLength, scanArea.top), Offset(scanArea.right, scanArea.top), framePaint);
    canvas.drawLine(Offset(scanArea.right, scanArea.top), Offset(scanArea.right, scanArea.top + cornerLength), framePaint);

    // Bottom-left
    canvas.drawLine(Offset(scanArea.left, scanArea.bottom - cornerLength), Offset(scanArea.left, scanArea.bottom), framePaint);
    canvas.drawLine(Offset(scanArea.left, scanArea.bottom), Offset(scanArea.left + cornerLength, scanArea.bottom), framePaint);

    // Bottom-right
    canvas.drawLine(Offset(scanArea.right - cornerLength, scanArea.bottom), Offset(scanArea.right, scanArea.bottom), framePaint);
    canvas.drawLine(Offset(scanArea.right, scanArea.bottom), Offset(scanArea.right, scanArea.bottom - cornerLength), framePaint);
  }

  @override
  ShapeBorder scale(double t) => const _ScannerOverlayShape();
}
