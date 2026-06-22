import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:maucoffee/auth/admin_add_employee_screen.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/repository/employee_repository.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';
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
    with TickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessed = false;
  bool _isTorchOn = false;
  String _statusMessage = "Memindai...";

  // Scanning line animation
  late AnimationController _scanLineController;
  late Animation<double> _scanLinePosition;

  // Corner pulse animation
  late AnimationController _cornerPulseController;
  late Animation<double> _cornerPulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // Scan line animation — bouncing up and down
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _scanLinePosition = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
    _scanLineController.repeat(reverse: true);

    // Corner pulse glow
    _cornerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _cornerPulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _cornerPulseController,
        curve: Curves.easeInOut,
      ),
    );
    _cornerPulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanLineController.dispose();
    _cornerPulseController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessed) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        HapticFeedback.heavyImpact();
        setState(() {
          _isProcessed = true;
          _statusMessage = "Memverifikasi...";
        });
        _controller.stop();
        _scanLineController.stop();

        try {
          final employeeRepo = serviceLocator<EmployeeRepository>();
          final employee = await employeeRepo.getEmployeeById(code);

          if (employee == null) {
            if (mounted) {
              CustomFeedback.showError(
                context,
                "Kode tidak ditemukan. Pastikan staf sudah membuka pendaftaran QR.",
              );
              HapticFeedback.vibrate();
              setState(() {
                _isProcessed = false;
                _statusMessage = "Memindai...";
              });
              _controller.start();
              _scanLineController.repeat(reverse: true);
            }
          } else {
            if (mounted) {
              _navigateToRegisterForm(code);
            }
          }
        } catch (e) {
          if (mounted) {
            CustomFeedback.showError(
              context,
              "Koneksi bermasalah: $e",
            );
            HapticFeedback.vibrate();
            setState(() {
              _isProcessed = false;
              _statusMessage = "Memindai...";
            });
            _controller.start();
            _scanLineController.repeat(reverse: true);
          }
        }
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
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    ).then((registered) {
      if (!mounted) return;
      if (registered == true) {
        Navigator.pop(context);
      } else {
        setState(() => _isProcessed = false);
        _controller.start();
        _scanLineController.repeat(reverse: true);
      }
    });
  }

  void _toggleTorch() {
    HapticFeedback.lightImpact();
    _controller.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  void _showManualEntryDialog() {
    final TextEditingController textController = TextEditingController();
    HapticFeedback.lightImpact();

    bool isValidating = false;
    String? errorMessage;

    // Matikan kamera sebelum modal input dibuka agar menghemat CPU/baterai
    _controller.stop();
    _scanLineController.stop();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.all(spacing7),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  color: const Color(0xFF1C1207).withValues(alpha: 0.97),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFE27D00).withValues(alpha: 0.15),
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
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.2),
                              Colors.white.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: spacing7),

                    // Icon header
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFE27D00).withValues(alpha: 0.2),
                              const Color(0xFFE27D00).withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFE27D00).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.keyboard_alt_rounded,
                          color: const Color(0xFFE27D00).withValues(alpha: 0.8),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: spacing5),
                    Text(
                      "Masukkan Kode Manual",
                      style: lgBold.copyWith(
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: spacing2),
                    Text(
                      "Ketik kode yang tertera di layar perangkat karyawan",
                      style: xsRegular.copyWith(
                        color: Colors.white.withValues(alpha: 0.4),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: spacing7),

                    // Input field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: TextField(
                        controller: textController,
                        autofocus: true,
                        enabled: !isValidating,
                        style: smMedium.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                        decoration: InputDecoration(
                          hintText: "EMP-XXXXXX",
                          hintStyle: smRegular.copyWith(
                            color: Colors.white.withValues(alpha: 0.15),
                            letterSpacing: 1.0,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: spacing5,
                            vertical: spacing5,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(
                              left: spacing4,
                              right: spacing2,
                            ),
                            child: Icon(
                              Icons.tag_rounded,
                              color: const Color(0xFFE27D00).withValues(alpha: 0.5),
                              size: 20,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 0,
                          ),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: spacing2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: spacing2),
                        child: Text(
                          errorMessage!,
                          style: xsRegular.copyWith(
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: spacing6),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: isValidating
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(context);
                                  },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Batal",
                                style: smBold.copyWith(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: spacing4),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: isValidating
                                ? null
                                : () async {
                                    final String val = textController.text.trim();
                                    if (val.isNotEmpty) {
                                      HapticFeedback.mediumImpact();
                                      setDialogState(() {
                                        isValidating = true;
                                        errorMessage = null;
                                      });

                                      try {
                                        final employeeRepo = serviceLocator<EmployeeRepository>();
                                        final employee = await employeeRepo.getEmployeeById(val);

                                        if (employee == null) {
                                          setDialogState(() {
                                            isValidating = false;
                                            errorMessage = "Kode tidak ditemukan. Pastikan staf sudah membuka pendaftaran QR.";
                                          });
                                          HapticFeedback.vibrate();
                                        } else {
                                          setDialogState(() {
                                            isValidating = false;
                                          });
                                          setState(() {
                                            _isProcessed = true;
                                          });
                                          Navigator.pop(context);
                                          _navigateToRegisterForm(val);
                                        }
                                      } catch (e) {
                                        setDialogState(() {
                                          isValidating = false;
                                          errorMessage = "Koneksi bermasalah: $e";
                                        });
                                        HapticFeedback.vibrate();
                                      }
                                    }
                                  },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: isValidating
                                      ? [
                                          const Color(0xFFE27D00).withValues(alpha: 0.5),
                                          const Color(0xFFD06A00).withValues(alpha: 0.5)
                                        ]
                                      : [const Color(0xFFE27D00), const Color(0xFFD06A00)],
                                ),
                                boxShadow: isValidating
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: const Color(0xFFE27D00)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isValidating) ...[
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: spacing2),
                                    Text(
                                      "Memeriksa...",
                                      style: smBold.copyWith(color: Colors.white),
                                    ),
                                  ] else ...[
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: spacing2),
                                    Text(
                                      "Lanjutkan",
                                      style: smBold.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + spacing4,
                    ),
                  ],
                ),
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
    // cutout size relative to camera view (will be drawn inside the Expanded area)
    const double cutOutSize = 240;

    return Scaffold(
      backgroundColor: Colors.black,
      // ── AppBar ──────────────────────────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1207),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFE27D00).withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: spacing4,
                vertical: spacing3,
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: spacing4),

                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Pindai QR Karyawan",
                          style: mdBold.copyWith(
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Arahkan kamera ke kode QR perangkat",
                          style: xxsRegular.copyWith(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Flash toggle button
                  GestureDetector(
                    onTap: _toggleTorch,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isTorchOn
                            ? const Color(0xFFE27D00).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: _isTorchOn
                              ? const Color(0xFFE27D00).withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _isTorchOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: _isTorchOn
                            ? const Color(0xFFE27D00)
                            : Colors.white.withValues(alpha: 0.6),
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

      // ── Body: Camera + Overlay + Bottom panel ────────────────────────────
      body: Column(
        children: [
          // Camera view — fills the remaining space above the bottom panel
          Expanded(
            child: Stack(
              children: [
                // 1. Live Camera
                Positioned.fill(
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                ),

                // 2. Dark overlay with square cutout
                Positioned.fill(
                  child: Container(
                    decoration: ShapeDecoration(
                      shape: QrScannerOverlayShape(
                        borderColor: const Color(0xFFE27D00),
                        borderRadius: 22,
                        borderLength: 30,
                        borderWidth: 3.5,
                        cutOutSize: cutOutSize,
                      ),
                    ),
                  ),
                ),

                // 3. Animated scan line inside the cutout
                AnimatedBuilder(
                  animation: Listenable.merge(
                    [_scanLinePosition, _cornerPulse],
                  ),
                  builder: (context, child) {
                    final box = context.findRenderObject() as RenderBox?;
                    final areaH = box?.size.height ?? 400;
                    final areaW = box?.size.width ?? 300;
                    final centerY = areaH / 2;
                    final centerX = areaW / 2;

                    final topOfCutout = centerY - cutOutSize / 2 + 14;
                    final lineY =
                        topOfCutout +
                        _scanLinePosition.value * (cutOutSize - 28);

                    return Positioned(
                      top: lineY,
                      left: centerX - cutOutSize / 2 + 10,
                      right: centerX - cutOutSize / 2 + 10,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFE27D00).withValues(alpha: 0.0),
                              const Color(0xFFE27D00).withValues(
                                alpha: 0.75 * _cornerPulse.value,
                              ),
                              const Color(0xFFFFAA44).withValues(
                                alpha: 0.95 * _cornerPulse.value,
                              ),
                              const Color(0xFFE27D00).withValues(
                                alpha: 0.75 * _cornerPulse.value,
                              ),
                              const Color(0xFFE27D00).withValues(alpha: 0.0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE27D00).withValues(
                                alpha: 0.35 * _cornerPulse.value,
                              ),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // 4. "Hint" label at top of camera area
                Positioned(
                  top: spacing7,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: spacing5,
                        vertical: spacing2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                      child: Text(
                        "Posisikan QR dalam bingkai",
                        style: xxsRegular.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom panel ────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1207),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFE27D00).withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              top: spacing6,
              bottom: bottomPadding + spacing6,
              left: spacing6,
              right: spacing6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status indicator (pulsing dot)
                AnimatedBuilder(
                  animation: _cornerPulse,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: spacing5,
                        vertical: spacing3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: const Color(0xFFE27D00).withValues(alpha: 0.08),
                        border: Border.all(
                          color: const Color(0xFFE27D00).withValues(
                            alpha: 0.12 * _cornerPulse.value,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE27D00).withValues(
                                alpha: _cornerPulse.value,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE27D00).withValues(
                                    alpha: 0.4 * _cornerPulse.value,
                                  ),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: spacing3),
                          Text(
                            _statusMessage,
                            style: xsSemiBold.copyWith(
                              color: const Color(0xFFE27D00)
                                  .withValues(alpha: 0.8),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: spacing5),

                // Divider with "atau"
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: spacing4),
                      child: Text(
                        "atau",
                        style: xxsRegular.copyWith(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: spacing5),

                // Manual entry button
                GestureDetector(
                  onTap: _showManualEntryDialog,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.keyboard_alt_outlined,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 18,
                        ),
                        const SizedBox(width: spacing3),
                        Text(
                          "Masukkan Kode Manual",
                          style: smBold.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
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
        ],
      ),
    );
  }
}

// ── Custom Overlay Shape ──────────────────────────────────────────────────────
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
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // Dark dimmed background
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.68)
      ..style = PaintingStyle.fill;

    final cutoutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              cutoutRect,
              Radius.circular(borderRadius),
            ),
          ),
      ),
      bgPaint,
    );

    // Subtle glow behind corners
    final glowPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius)),
      glowPaint,
    );

    // Corner brackets
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final hs = cutOutSize / 2;
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    final l = cx - hs;
    final r = cx + hs;
    final t = cy - hs;
    final b = cy + hs;
    final br = borderRadius;
    final bl = borderLength;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(l + br + bl, t)
        ..lineTo(l + br, t)
        ..arcToPoint(Offset(l, t + br),
            radius: Radius.circular(br))
        ..lineTo(l, t + br + bl),
      borderPaint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(r - br - bl, t)
        ..lineTo(r - br, t)
        ..arcToPoint(Offset(r, t + br),
            radius: Radius.circular(br), clockwise: true)
        ..lineTo(r, t + br + bl),
      borderPaint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(l, b - br - bl)
        ..lineTo(l, b - br)
        ..arcToPoint(Offset(l + br, b),
            radius: Radius.circular(br))
        ..lineTo(l + br + bl, b),
      borderPaint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(r, b - br - bl)
        ..lineTo(r, b - br)
        ..arcToPoint(Offset(r - br, b),
            radius: Radius.circular(br), clockwise: false)
        ..lineTo(r - br - bl, b),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
        borderColor: borderColor,
        borderWidth: borderWidth * t,
        borderLength: borderLength * t,
        borderRadius: borderRadius * t,
        cutOutSize: cutOutSize * t,
      );
}
