import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/config/app_config.dart';

/// Barcode scanner overlay widget with mobile_scanner
/// Optimized for PWA performance with fast detection
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
  late MobileScannerController _controller;
  bool _hasDetected = false;
  String? _detectedCode;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          // Scanner View
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
            errorBuilder: (context, error) {
              return _buildErrorView(error);
            },
            placeholderBuilder: (context) {
              return _buildLoadingView();
            },
          ),

          // Overlay UI
          _buildOverlayUI(),

          // Close Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: _buildCloseButton(),
          ),

          // Flashlight Toggle
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

          // Scanning Frame Area
          const Expanded(
            flex: 3,
            child: SizedBox.expand(),
          ),

          const Spacer(flex: 1),

          // Instructions
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppConfig.paddingLarge),
            padding: const EdgeInsets.all(AppConfig.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: AppConfig.paddingSmall),
                Text(
                  'Escanear Código de Barras',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppConfig.bodyFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConfig.paddingSmall),
                Text(
                  'Coloca el código de barras del producto dentro del marco para escanearlo',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: AppConfig.captionFontSize,
                  ),
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
      decoration: const BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: widget.onClose,
        icon: const Icon(
          Icons.close,
          color: Colors.white,
          size: 28,
        ),
        tooltip: 'Cerrar escáner',
      ),
    );
  }

  Widget _buildFlashlightButton() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () => _controller.toggleTorch(),
        icon: const Icon(
          Icons.flash_on,
          color: Colors.white,
          size: 28,
        ),
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
            Text(
              'Iniciando cámara...',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppConfig.bodyFontSize,
              ),
            ),
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
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              Text(
                'Error del escáner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppConfig.headingFontSize,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConfig.paddingSmall),
              Text(
                error.errorDetails?.message ?? 'Error desconocido',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: AppConfig.bodyFontSize,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConfig.paddingLarge),
              ElevatedButton(
                onPressed: widget.onClose,
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasDetected) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        final cleanCode = code.trim();

        // Mark as detected and stop scanner immediately
        _hasDetected = true;
        _controller.stop();

        // Haptic feedback for instant response
        HapticFeedback.mediumImpact();

        // Show detected code visually
        if (mounted) {
          setState(() {
            _detectedCode = cleanCode;
          });
        }

        // Call callback immediately - no unnecessary delay
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

    // Calculate scanner frame size and position
    final double scanAreaSize = rect.width * 0.7;
    final Rect scanArea = Rect.fromCenter(
      center: rect.center,
      width: scanAreaSize,
      height: scanAreaSize * 0.7, // Rectangular scanner area
    );

    // Create rounded rectangle for scanning area
    final Path scanPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanArea,
          const Radius.circular(AppConfig.borderRadius),
        ),
      );

    return Path.combine(PathOperation.difference, outerPath, scanPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // Paint the overlay
    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect), paint);

    // Draw scanner frame corners
    final double scanAreaSize = rect.width * 0.7;
    final Rect scanArea = Rect.fromCenter(
      center: rect.center,
      width: scanAreaSize,
      height: scanAreaSize * 0.7,
    );

    final Paint framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw corner lines
    const double cornerLength = 30;

    // Top-left corner
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top + cornerLength),
      Offset(scanArea.left, scanArea.top),
      framePaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top),
      Offset(scanArea.left + cornerLength, scanArea.top),
      framePaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.top),
      Offset(scanArea.right, scanArea.top),
      framePaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.top),
      Offset(scanArea.right, scanArea.top + cornerLength),
      framePaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom - cornerLength),
      Offset(scanArea.left, scanArea.bottom),
      framePaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom),
      Offset(scanArea.left + cornerLength, scanArea.bottom),
      framePaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.bottom),
      Offset(scanArea.right, scanArea.bottom),
      framePaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.bottom),
      Offset(scanArea.right, scanArea.bottom - cornerLength),
      framePaint,
    );
  }

  @override
  ShapeBorder scale(double t) => const _ScannerOverlayShape();
}
