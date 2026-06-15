import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:maucoffee/auth/admin_add_employee_screen.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class AdminScanEmployeeScreen extends StatefulWidget {
  const AdminScanEmployeeScreen({super.key});

  @override
  State<AdminScanEmployeeScreen> createState() =>
      _AdminScanEmployeeScreenState();
}

class _AdminScanEmployeeScreenState extends State<AdminScanEmployeeScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessed = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessed) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() {
          _isProcessed = true;
        });
        _controller.stop();
        _navigateToRegisterForm(code);
      }
    }
  }

  void _navigateToRegisterForm(String deviceUuid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAddEmployeeScreen(deviceUuid: deviceUuid),
      ),
    ).then((registered) {
      if (registered == true) {
        // Jika registrasi sukses, kembali ke halaman dashboard admin
        Navigator.pop(context);
      } else {
        // Jika batal, nyalakan kembali scan
        setState(() {
          _isProcessed = false;
        });
        _controller.start();
      }
    });
  }

  void _showManualEntryDialog() {
    final TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius300),
        ),
        title: Text(
          "Enter Device ID Manually",
          style: mdBold.copyWith(color: textDarkPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Type the code shown on the employee's screen (e.g. emp-1781...)",
              style: xsRegular.copyWith(color: textDarkSecondary),
            ),
            const SizedBox(height: spacing4),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: "emp-xxxxxxxxxxxxxx",
                hintStyle: sRegular.copyWith(color: textDarkTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius200),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
              ),
              style: sMedium.copyWith(color: textDarkPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: sMedium.copyWith(color: textDarkSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final String val = textController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(context); // Tutup dialog
                _navigateToRegisterForm(val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius200),
              ),
            ),
            child: Text("Continue", style: sBold.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Scan Employee QR",
          style: mdBold.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.camera),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Scanner Camera
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // 2. Custom Overlay Frame (Scanner cutout)
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: primaryColor,
                borderRadius: 16,
                borderLength: 30,
                borderWidth: 6,
                cutOutSize: 260,
              ),
            ),
          ),

          // 3. Instructions & Manual Entry Button
          Positioned(
            bottom: spacing8,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Align the QR code within the frame",
                  style: sMedium.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: spacing4),
                ElevatedButton.icon(
                  onPressed: _showManualEntryDialog,
                  icon: const Icon(
                    Icons.keyboard_alt_outlined,
                    color: Colors.white,
                  ),
                  label: Text(
                    "Enter Code Manually",
                    style: sBold.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.25),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: spacing6,
                      vertical: spacing4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius300),
                      side: const BorderSide(color: Colors.white38),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for scanner overlay
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = primaryColor,
    this.borderWidth = 4.0,
    this.borderLength = 20.0,
    this.borderRadius = 8.0,
    this.cutOutSize = 250.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addOval(Rect.fromCircle(center: rect.center, radius: cutOutSize / 2));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final cutoutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // Draw dark background with cutout hole
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(
          RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius)),
        ),
      ),
      backgroundPaint,
    );

    // Border paint
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final halfWidth = cutOutSize / 2;
    final halfHeight = cutOutSize / 2;
    final center = rect.center;

    final left = center.dx - halfWidth;
    final right = center.dx + halfWidth;
    final top = center.dy - halfHeight;
    final bottom = center.dy + halfHeight;

    // Top Left Corner
    path.moveTo(left + borderRadius, top);
    path.lineTo(left, top);
    path.lineTo(left, top + borderRadius);
    path.moveTo(left, top + borderRadius + borderLength);
    path.lineTo(left, top + borderRadius);
    path.lineTo(left + borderLength + borderRadius, top);

    // Top Right Corner
    path.moveTo(right - borderRadius, top);
    path.lineTo(right, top);
    path.lineTo(right, top + borderRadius);
    path.moveTo(right, top + borderRadius + borderLength);
    path.lineTo(right, top + borderRadius);
    path.lineTo(right - borderLength - borderRadius, top);

    // Bottom Left Corner
    path.moveTo(left + borderRadius, bottom);
    path.lineTo(left, bottom);
    path.lineTo(left, bottom - borderRadius);
    path.moveTo(left, bottom - borderRadius - borderLength);
    path.lineTo(left, bottom - borderRadius);
    path.lineTo(left + borderLength + borderRadius, bottom);

    // Bottom Right Corner
    path.moveTo(right - borderRadius, bottom);
    path.lineTo(right, bottom);
    path.lineTo(right, bottom - borderRadius);
    path.moveTo(right, bottom - borderRadius - borderLength);
    path.lineTo(right, bottom - borderRadius);
    path.lineTo(right - borderLength - borderRadius, bottom);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      borderLength: borderLength * t,
      borderRadius: borderRadius * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
