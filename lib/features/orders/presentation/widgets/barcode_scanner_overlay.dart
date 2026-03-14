import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Barcode scanner optimized for PWA - native-like camera experience
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

class _BarcodeScannerOverlayState extends State<BarcodeScannerOverlay>
    with SingleTickerProviderStateMixin {
  static MobileScannerController? _sharedController;
  static bool _controllerInUse = false;

  bool _hasDetected = false;
  String? _detectedCode;
  bool _isStarting = true;
  late AnimationController _animController;
  late Animation<double> _scanLineAnimation;

  MobileScannerController get _controller {
    if (_sharedController == null || _sharedController!.value.error != null) {
      _sharedController?.dispose();
      _sharedController = _createController();
    }
    return _sharedController!;
  }

  static MobileScannerController _createController() {
    return MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
      detectionTimeoutMs: 100,
      facing: CameraFacing.back,
      returnImage: false,
      // HD resolution for sharp barcode reading
      cameraResolution: const Size(1280, 720),
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

    // Animated scan line
    _animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _startScanner();
  }

  Future<void> _startScanner() async {
    try {
      await _controller.start();
    } catch (e) {
      _sharedController?.dispose();
      _sharedController = _createController();
      try {
        await _sharedController!.start();
      } catch (_) {}
    }
    if (mounted) setState(() => _isStarting = false);
  }

  @override
  void dispose() {
    _controllerInUse = false;
    _animController.dispose();
    _controller.stop();
    super.dispose();
  }

  static void releaseCamera() {
    if (!_controllerInUse) {
      _sharedController?.dispose();
      _sharedController = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Material(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen camera - no dark overlay, just raw camera feed
          if (!_isStarting)
            Positioned.fill(
              child: MobileScanner(
                controller: _controller,
                onDetect: _onBarcodeDetected,
                fit: BoxFit.cover,
                errorBuilder: (context, error) => _buildErrorView(error),
              ),
            )
          else
            _buildLoadingView(),

          // Minimal overlay - just a subtle vignette at edges, NOT covering scan area
          if (!_isStarting)
            Positioned.fill(
              child: CustomPaint(
                painter: _MinimalOverlayPainter(
                  scanAreaWidth: size.width * 0.88,
                  scanAreaHeight: size.width * 0.88 * 0.45,
                  screenSize: size,
                ),
              ),
            ),

          // Animated scan line
          if (!_isStarting && _detectedCode == null)
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                final scanH = size.width * 0.88 * 0.45;
                final centerY = size.height / 2;
                final top = centerY - scanH / 2;
                final lineY = top + (_scanLineAnimation.value * scanH);
                return Positioned(
                  left: size.width * 0.06 + 4,
                  right: size.width * 0.06 + 4,
                  top: lineY,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.0),
                          Colors.green.withOpacity(0.8),
                          Colors.green,
                          Colors.green.withOpacity(0.8),
                          Colors.green.withOpacity(0.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Top bar with close button
          Positioned(
            top: padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flashlight (native only)
                if (!kIsWeb)
                  _buildCircleButton(
                    Icons.flash_on,
                    () => _controller.toggleTorch(),
                  )
                else
                  const SizedBox(width: 44),
                // Title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Escanear Codigo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Close
                _buildCircleButton(Icons.close, widget.onClose),
              ],
            ),
          ),

          // Bottom hint
          if (_detectedCode == null && !_isStarting)
            Positioned(
              bottom: padding.bottom + 40,
              left: 40,
              right: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Apunta al codigo de barras',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // Detected feedback
          if (_detectedCode != null)
            Positioned(
              bottom: padding.bottom + 40,
              left: 32,
              right: 32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Iniciando camara...', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorView(MobileScannerException error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 72),
            const SizedBox(height: 16),
            const Text(
              'No se pudo acceder a la camara',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.errorDetails?.message ?? 'Verifica que hayas dado permiso de camara',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onClose,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
            ),
          ],
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
        _animController.stop();

        HapticFeedback.mediumImpact();

        if (mounted) setState(() => _detectedCode = cleanCode);

        Future.microtask(() => widget.onBarcodeDetected(cleanCode));
        break;
      }
    }
  }
}

/// Minimal overlay - only thin edges and corner brackets, keeps camera bright
class _MinimalOverlayPainter extends CustomPainter {
  final double scanAreaWidth;
  final double scanAreaHeight;
  final Size screenSize;

  _MinimalOverlayPainter({
    required this.scanAreaWidth,
    required this.scanAreaHeight,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaWidth,
      height: scanAreaHeight,
    );

    // Very subtle edge darkening - only at the very edges, not the center
    final edgePaint = Paint()..style = PaintingStyle.fill;

    // Top edge
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, scanArea.top - 20),
      edgePaint..color = Colors.black.withOpacity(0.15),
    );
    // Bottom edge
    canvas.drawRect(
      Rect.fromLTRB(0, scanArea.bottom + 20, size.width, size.height),
      edgePaint..color = Colors.black.withOpacity(0.15),
    );

    // Corner brackets - thick and visible
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const double cLen = 35;

    // Top-left
    canvas.drawLine(Offset(scanArea.left, scanArea.top + cLen), Offset(scanArea.left, scanArea.top), cornerPaint);
    canvas.drawLine(Offset(scanArea.left, scanArea.top), Offset(scanArea.left + cLen, scanArea.top), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(scanArea.right - cLen, scanArea.top), Offset(scanArea.right, scanArea.top), cornerPaint);
    canvas.drawLine(Offset(scanArea.right, scanArea.top), Offset(scanArea.right, scanArea.top + cLen), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(scanArea.left, scanArea.bottom - cLen), Offset(scanArea.left, scanArea.bottom), cornerPaint);
    canvas.drawLine(Offset(scanArea.left, scanArea.bottom), Offset(scanArea.left + cLen, scanArea.bottom), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(scanArea.right - cLen, scanArea.bottom), Offset(scanArea.right, scanArea.bottom), cornerPaint);
    canvas.drawLine(Offset(scanArea.right, scanArea.bottom), Offset(scanArea.right, scanArea.bottom - cLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
