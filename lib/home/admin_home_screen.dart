import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maucoffee/auth/admin_scan_employee_screen.dart';
import 'package:maucoffee/auth/role_selector_screen.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _statsFade;
  late Animation<double> _menuFade;
  late Animation<Offset> _menuSlide;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    _statsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _menuFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _menuSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
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
              children: [
                // Handle bar
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
                const SizedBox(height: spacing6),
                Icon(
                  Icons.logout_rounded,
                  color: const Color(0xFFFF6B6B),
                  size: 32,
                ),
                const SizedBox(height: spacing4),
                Text(
                  "Sign Out?",
                  style: lgBold.copyWith(
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: spacing2),
                Text(
                  "You'll need to sign in again to access\nyour dashboard",
                  style: xsRegular.copyWith(
                    color: Colors.white.withOpacity(0.4),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: spacing7),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
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
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          final prefs = serviceLocator<UserPreference>();
                          prefs.clearData();

                          Navigator.pushAndRemoveUntil(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const RoleSelectorScreen(),
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                            ),
                            (route) => false,
                          );
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(0xFFFF6B6B).withOpacity(0.15),
                            border: Border.all(
                              color: const Color(0xFFFF6B6B).withOpacity(0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Sign Out",
                            style: smBold.copyWith(
                              color: const Color(0xFFFF8A8A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                    height: MediaQuery.of(ctx).padding.bottom + spacing4),
              ],
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
              // ── Header ──
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: spacing6,
                      right: spacing5,
                      top: spacing5,
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE27D00),
                                Color(0xFFD06A00),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE27D00)
                                    .withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.coffee_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: spacing4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Mau Coffee",
                                style: mdBold.copyWith(
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                "Business Dashboard",
                                style: xsRegular.copyWith(
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Logout button
                        GestureDetector(
                          onTap: () => _handleLogout(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Icon(
                              Icons.logout_rounded,
                              color: Colors.white.withOpacity(0.4),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: spacing7),

              // ── Content ──
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: spacing6,
                    right: spacing6,
                    bottom: bottomPadding + 110,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Welcome Banner ──
                      SlideTransition(
                        position: _headerSlide,
                        child: FadeTransition(
                          opacity: _headerFade,
                          child: Text(
                            "Hello, Owner! 👋",
                            style: TextStyle(
                              fontFamily: 'poppins',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: spacing2),
                      FadeTransition(
                        opacity: _headerFade,
                        child: Text(
                          "Manage your shop and team from here",
                          style: sRegular.copyWith(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),

                      const SizedBox(height: spacing7),

                      // ── Stats Cards Row ──
                      FadeTransition(
                        opacity: _statsFade,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                "Today's Sales",
                                "Rp 0",
                                Icons.trending_up_rounded,
                                const Color(0xFF2D8A4E),
                              ),
                            ),
                            const SizedBox(width: spacing4),
                            Expanded(
                              child: _buildStatCard(
                                "Staff",
                                "-",
                                Icons.badge_rounded,
                                const Color(0xFFE27D00),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: spacing8),

                      // ── Menu Section ──
                      SlideTransition(
                        position: _menuSlide,
                        child: FadeTransition(
                          opacity: _menuFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "MANAGEMENT",
                                style: xsBold.copyWith(
                                  color: Colors.white.withOpacity(0.3),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: spacing4),

                              // Register Staff
                              _buildMenuCard(
                                title: "Register Staff",
                                description:
                                    "Scan QR code and assign access roles",
                                icon: Icons.person_add_rounded,
                                iconColor: const Color(0xFFE27D00),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          const AdminScanEmployeeScreen(),
                                      transitionDuration:
                                          const Duration(milliseconds: 400),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        final fade = CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOut,
                                        );
                                        return FadeTransition(
                                            opacity: fade, child: child);
                                      },
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: spacing4),

                              // Manage Catalog (Coming Soon)
                              _buildMenuCard(
                                title: "Manage Catalog",
                                description:
                                    "Edit products, categories, and stocks",
                                icon: Icons.coffee_rounded,
                                iconColor: Colors.white.withOpacity(0.3),
                                isDisabled: true,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Coming soon!",
                                        style: sMedium.copyWith(
                                            color: Colors.white),
                                      ),
                                      backgroundColor: const Color(0xFF3A3A3A),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.all(spacing6),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: spacing4),

                              // Sales Report (Coming Soon)
                              _buildMenuCard(
                                title: "Sales Report",
                                description:
                                    "View daily and monthly transaction reports",
                                icon: Icons.bar_chart_rounded,
                                iconColor: Colors.white.withOpacity(0.3),
                                isDisabled: true,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Coming soon!",
                                        style: sMedium.copyWith(
                                            color: Colors.white),
                                      ),
                                      backgroundColor: const Color(0xFF3A3A3A),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.all(spacing6),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
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

  // ── Stat Card Widget ──
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(spacing5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: xxsMedium.copyWith(
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: accentColor.withOpacity(0.15),
                    ),
                    child: Icon(icon, color: accentColor, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: spacing3),
              Text(
                value,
                style: xlBold.copyWith(
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Menu Card Widget ──
  Widget _buildMenuCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedOpacity(
            opacity: isDisabled ? 0.45 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(spacing5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: Colors.white.withOpacity(0.07),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color: iconColor.withOpacity(0.12),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: spacing4),
                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: smBold.copyWith(
                                color: Colors.white.withOpacity(0.85),
                                letterSpacing: -0.1,
                              ),
                            ),
                            if (isDisabled) ...[
                              const SizedBox(width: spacing2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: spacing2,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white.withOpacity(0.08),
                                ),
                                child: Text(
                                  "Soon",
                                  style: xxxsBold.copyWith(
                                    color: Colors.white.withOpacity(0.35),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: xsRegular.copyWith(
                            color: Colors.white.withOpacity(0.3),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: spacing2),
                  // Chevron
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.3),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
