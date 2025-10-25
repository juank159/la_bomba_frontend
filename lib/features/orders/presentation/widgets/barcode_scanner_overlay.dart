import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/config/app_config.dart';

/// Barcode scanner overlay widget with mobile_scanner
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

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
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
    if (_hasDetected) return; // Prevent multiple detections
    
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() {
          _hasDetected = true;
        });
        
        // Show feedback
        _showDetectionFeedback();
        
        // Call callback after a short delay to show feedback
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onBarcodeDetected(code);
        });
        
        break; // Only process the first valid barcode
      }
    }
  }

  void _showDetectionFeedback() {
    // Visual feedback for successful detection
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppConfig.successColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: AppConfig.paddingSmall),
            Text(
              '¡Código detectado!',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppConfig.bodyFontSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // Auto-close the dialog
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
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