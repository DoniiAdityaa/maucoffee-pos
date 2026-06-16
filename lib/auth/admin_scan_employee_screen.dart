import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _AdminScanEmployeeScreenState extends State<AdminScanEmployeeScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessed = false;

  late AnimationController _overlayController;
  late Animation<double> _overlayFade;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _overlayFade = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOut,
    );
    _overlayController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessed) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        HapticFeedback.heavyImpact();
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
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AdminAddEmployeeScreen(deviceUuid: deviceUuid),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    ).then((registered) {
      if (registered == true) {
        Navigator.pop(context);
      } else {
        setState(() {
          _isProcessed = false;
        });
        _controller.start();
      }
    });
  }

  void _showManualEntryDialog() {
    final TextEditingController textController = TextEditingController();
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.all(spacing7),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                color: const Color(0xFF2A1A0A).withOpacity(0.95),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ),
                  const SizedBox(height: spacing6),
                  Text(
                    "Enter Code Manually",
                    style: lgBold.copyWith(
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: spacing2),
                  Text(
                    "Type the code shown on the employee's screen",
                    style: xsRegular.copyWith(
                      color: Colors.white.withOpacity(0.4),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: spacing6),
                  // Input field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: TextField(
                      controller: textController,
                      style: smMedium.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: "emp-xxxxxxxxxxxxxx",
                        hintStyle: smRegular.copyWith(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: spacing5,
                          vertical: spacing4,
                        ),
                        prefixIcon: Icon(
                          Icons.tag_rounded,
                          color: const Color(0xFFE27D00).withOpacity(0.6),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: spacing5),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white.withOpacity(0.06),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Cancel",
                              style: smBold.copyWith(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: spacing4),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            final String val = textController.text.trim();
                            if (val.isNotEmpty) {
                              Navigator.pop(context);
                              _navigateToRegisterForm(val);
                            }
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE27D00),
                                  Color(0xFFD06A00),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFE27D00).withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Continue",
                              style: smBold.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + spacing4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Scanner Camera (full-screen)
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // 2. Custom Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: const Color(0xFFE27D00),
                borderRadius: 20,
                borderLength: 28,
                borderWidth: 4,
                cutOutSize: 260,
              ),
            ),
          ),

          // 3. Top section — blurred header
          FadeTransition(
            opacity: _overlayFade,
            child: Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: spacing3,
                          right: spacing5,
                          top: spacing2,
                          bottom: spacing5,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: spacing4),
                            Expanded(
                              child: Text(
                                "Scan Employee QR",
                                style: mdBold.copyWith(
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _controller.toggleTorch(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.12),
                                ),
                                child: const Icon(
                                  Icons.flash_on_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Bottom section — instructions & manual entry
          FadeTransition(
            opacity: _overlayFade,
            child: Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    padding: EdgeInsets.only(
                      top: spacing6,
                      bottom: bottomPadding + spacing6,
                      left: spacing6,
                      right: spacing6,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Align the QR code within the frame",
                          style: sMedium.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: spacing5),
                        GestureDetector(
                          onTap: _showManualEntryDialog,
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.keyboard_alt_outlined,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 18,
                                ),
                                const SizedBox(width: spacing3),
                                Text(
                                  "Enter Code Manually",
                                  style: smBold.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
                cutoutRect, Radius.circular(borderRadius)),
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
    final halfSize = cutOutSize / 2;
    final center = rect.center;

    final left = center.dx - halfSize;
    final right = center.dx + halfSize;
    final top = center.dy - halfSize;
    final bottom = center.dy + halfSize;

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
