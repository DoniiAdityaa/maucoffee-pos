import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maucoffee/auth/admin_login_screen.dart';
import 'package:maucoffee/auth/employee_register_qr_screen.dart';
import 'package:maucoffee/ui/widget_sharing/page_route_helper.dart';

// Import Design System kita
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _cardsController;
  late AnimationController _footerController;

  // Animations
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _ownerCardFade;
  late Animation<Offset> _ownerCardSlide;
  late Animation<double> _staffCardFade;
  late Animation<Offset> _staffCardSlide;
  late Animation<double> _footerFade;

  // Interactive scale for tap effect
  double _ownerScale = 1.0;
  double _staffScale = 1.0;

  @override
  void initState() {
    super.initState();

    // Set status bar to light (white icons) for dark/gradient backgrounds
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // 1. Logo/Brand area animation (top section)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);
    _logoSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
        );

    // 2. Cards staggered animation
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _ownerCardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _ownerCardSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _cardsController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    _staffCardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
      ),
    );
    _staffCardSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _cardsController,
            curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    // 3. Footer animation
    _footerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _footerFade = CurvedAnimation(
      parent: _footerController,
      curve: Curves.easeOut,
    );

    // Stagger the animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _footerController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _cardsController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _onOwnerTapDown() {
    HapticFeedback.lightImpact();
    setState(() => _ownerScale = 0.96);
  }

  void _onOwnerTapUp() {
    setState(() => _ownerScale = 1.0);
  }

  void _onStaffTapDown() {
    HapticFeedback.lightImpact();
    setState(() => _staffScale = 0.96);
  }

  void _onStaffTapUp() {
    setState(() => _staffScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Warm amber gradient background — coffee-themed premium
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1C1207), // Very dark warm brown
              Color(0xFF2A1A0A), // Dark coffee brown
              Color(0xFF1A1008), // Near black with warm tint
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ─── TOP: Brand / Logo Area ───
              SlideTransition(
                position: _logoSlide,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: spacing9,
                      left: spacing6,
                      right: spacing6,
                    ),
                    child: Column(
                      children: [
                        // Coffee icon with warm glow
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFE27D00), Color(0xFFD06A00)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFE27D00,
                                ).withOpacity(0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.coffee_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: spacing5),
                        Text(
                          "Mau Coffee",
                          style: mlBold.copyWith(
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: spacing2),
                        Text(
                          "Select how you want to continue",
                          style: sMedium.copyWith(
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: spacing9),

              // ─── CENTER: Role Cards ───
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: spacing6),
                  child: Column(
                    children: [
                      // ── BUSINESS OWNER CARD (Primary / Prominent) ──
                      SlideTransition(
                        position: _ownerCardSlide,
                        child: FadeTransition(
                          opacity: _ownerCardFade,
                          child: GestureDetector(
                            onTapDown: (_) => _onOwnerTapDown(),
                            onTapUp: (_) {
                              _onOwnerTapUp();
                              AppNavigator.push(
                                context,
                                const AdminLoginScreen(),
                              );
                            },
                            onTapCancel: _onOwnerTapUp,
                            child: AnimatedScale(
                              scale: _ownerScale,
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              child: _buildOwnerCard(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: spacing5),

                      // ── STAFF MEMBER CARD (Secondary / Subtle) ──
                      SlideTransition(
                        position: _staffCardSlide,
                        child: FadeTransition(
                          opacity: _staffCardFade,
                          child: GestureDetector(
                            onTapDown: (_) => _onStaffTapDown(),
                            onTapUp: (_) {
                              _onStaffTapUp();
                              AppNavigator.push(
                                context,
                                const EmployeeRegisterQrScreen(),
                              );
                            },
                            onTapCancel: _onStaffTapUp,
                            child: AnimatedScale(
                              scale: _staffScale,
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              child: _buildStaffCard(),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),

              // ─── BOTTOM: Footer ───
              FadeTransition(
                opacity: _footerFade,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: bottomPadding + spacing6,
                    left: spacing6,
                    right: spacing6,
                  ),
                  child: Text(
                    "Powered by Mau Coffee POS",
                    style: xsRegular.copyWith(
                      color: Colors.white.withOpacity(0.25),
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════
  // BUSINESS OWNER CARD — Glassmorphism with warm amber accent
  // ═════════════════════════════════════════════════════
  Widget _buildOwnerCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(spacing6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // Warm frosted glass
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: icon + badge
              Row(
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE27D00), Color(0xFFCC6A00)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE27D00).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  // Recommended badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: spacing3,
                      vertical: spacing1 + 1,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: const Color(0xFFE27D00).withOpacity(0.15),
                      border: Border.all(
                        color: const Color(0xFFE27D00).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      "Owner",
                      style: xxsBold.copyWith(
                        color: const Color(0xFFE9A44C),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: spacing5),

              // Title
              Text(
                "Business Owner",
                style: lgBold.copyWith(
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: spacing2),

              // Subtitle
              Text(
                "Full control over your store — manage products,\nstaff, sales reports, and inventory.",
                style: xsRegular.copyWith(
                  color: Colors.white.withOpacity(0.5),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: spacing6),

              // CTA Button — iOS-style filled
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE27D00), Color(0xFFD06A00)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE27D00).withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Continue as Owner",
                      style: smBold.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: spacing2),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════
  // STAFF MEMBER CARD — Subtle frosted glass, secondary emphasis
  // ═════════════════════════════════════════════════════
  Widget _buildStaffCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(spacing5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.badge_rounded,
                  color: Colors.white.withOpacity(0.6),
                  size: 22,
                ),
              ),

              const SizedBox(width: spacing4),

              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Staff Member",
                      style: smBold.copyWith(
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Scan QR from your employer to access",
                      style: xsRegular.copyWith(
                        color: Colors.white.withOpacity(0.35),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: spacing3),

              // Chevron — iOS style
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
