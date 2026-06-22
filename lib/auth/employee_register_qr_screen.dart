import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/navigation/navigation.dart';
import 'package:maucoffee/repository/employee_repository.dart';
import 'package:maucoffee/model/employee_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Import Design System kita
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';

class EmployeeRegisterQrScreen extends StatefulWidget {
  const EmployeeRegisterQrScreen({super.key});

  @override
  State<EmployeeRegisterQrScreen> createState() =>
      _EmployeeRegisterQrScreenState();
}

class _EmployeeRegisterQrScreenState extends State<EmployeeRegisterQrScreen>
    with TickerProviderStateMixin {
  late final String _deviceUuid;
  Timer? _pollingTimer;
  bool _isChecking = false;

  // Animations
  late AnimationController _entryController;
  late AnimationController _pulseController;

  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _qrFade;
  late Animation<double> _qrScale;
  late Animation<double> _statusFade;
  late Animation<double> _codeFade;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Get device UUID
    final prefs = serviceLocator<UserPreference>();
    _deviceUuid = prefs.getDeviceUuid();

    // Entry animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    _qrFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.65, curve: Curves.easeOut),
      ),
    );
    _qrScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _statusFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
      ),
    );

    _codeFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    // Subtle pulse animation for the QR card glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entryController.forward();
    _registerDeviceIfNeeded();
    _startPolling();
  }

  Future<void> _registerDeviceIfNeeded() async {
    try {
      final employeeRepo = serviceLocator<EmployeeRepository>();
      final existing = await employeeRepo.getEmployeeById(_deviceUuid);
      if (existing == null) {
        final newEmployee = EmployeeModel(
          id: _deviceUuid,
          name: "Karyawan Baru",
          role: "Cashier",
          isActive: false,
        );
        await employeeRepo.addEmployee(newEmployee);
        debugPrint("Device registered successfully with isActive = false");
      }
    } catch (e) {
      debugPrint("Error registering device to Supabase: $e");
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isChecking) return;
      if (!mounted) return;

      setState(() => _isChecking = true);

      try {
        final employeeRepo = serviceLocator<EmployeeRepository>();
        final employee = await employeeRepo.getEmployeeById(_deviceUuid);

        if (employee != null && employee.isActive) {
          _pollingTimer?.cancel();

          final prefs = serviceLocator<UserPreference>();
          await prefs.setEmployee(employee);
          await prefs.setLoginRole('employee');

          if (mounted) {
            CustomFeedback.showSuccess(
              context,
              "Welcome, ${employee.name}! Registered as ${employee.role}.",
            );

            Navigator.pushAndRemoveUntil(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const MainNavigation(initialIndex: 0),
                transitionDuration: const Duration(milliseconds: 400),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
              (route) => false,
            );
          }
        }
      } catch (e) {
        debugPrint("Polling error: $e");
      } finally {
        if (mounted) {
          setState(() => _isChecking = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1C1207),
              Color(0xFF2A1A0A),
              Color(0xFF1A1008),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Back Button ──
              Padding(
                padding: const EdgeInsets.only(
                  left: spacing3,
                  top: spacing2,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: spacing6),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // ── Header Text ──
                      SlideTransition(
                        position: _headerSlide,
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: Column(
                            children: [
                              Text(
                                "Show this to your employer",
                                style: lgBold.copyWith(
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: spacing2),
                              Text(
                                "Ask the business owner to scan this\nQR code to register you",
                                style: xsRegular.copyWith(
                                  color: Colors.white.withOpacity(0.4),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: spacing8),

                      // ── QR Code Card (Glassmorphism with animated glow) ──
                      FadeTransition(
                        opacity: _qrFade,
                        child: ScaleTransition(
                          scale: _qrScale,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE27D00)
                                          .withOpacity(
                                              _pulseAnimation.value * 0.4),
                                      blurRadius: 40,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  padding: const EdgeInsets.all(spacing7),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.14),
                                        Colors.white.withOpacity(0.06),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.12),
                                      width: 1,
                                    ),
                                  ),
                                  child: QrImageView(
                                    data: _deviceUuid,
                                    version: QrVersions.auto,
                                    size: 220.0,
                                    gapless: false,
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape:
                                          QrDataModuleShape.square,
                                      color: Colors.white,
                                    ),
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Color(0xFFE27D00),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: spacing7),

                      // ── Waiting Status Indicator ──
                      FadeTransition(
                        opacity: _statusFade,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFFE27D00).withOpacity(0.7),
                                ),
                              ),
                            ),
                            const SizedBox(width: spacing3),
                            Text(
                              "Waiting for approval...",
                              style: xsMedium.copyWith(
                                color: Colors.white.withOpacity(0.45),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: spacing9),

                      // ── Manual Code Alternative ──
                      FadeTransition(
                        opacity: _codeFade,
                        child: Column(
                          children: [
                            Text(
                              "Or enter this code manually",
                              style: xsRegular.copyWith(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(height: spacing3),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: _deviceUuid));
                                CustomFeedback.showSuccess(context, "Code copied to clipboard");
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: spacing5,
                                  vertical: spacing3,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withOpacity(0.06),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _deviceUuid,
                                      style: smBold.copyWith(
                                        color: Colors.white.withOpacity(0.7),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(width: spacing3),
                                    Icon(
                                      Icons.copy_rounded,
                                      color: Colors.white.withOpacity(0.3),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 2),

                      // ── Footer ──
                      Padding(
                        padding:
                            EdgeInsets.only(bottom: bottomPadding + spacing6),
                        child: Text(
                          "Your employer needs to scan this QR code",
                          style: xsRegular.copyWith(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          textAlign: TextAlign.center,
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
    );
  }
}
