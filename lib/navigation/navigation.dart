import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/features/absensi/attendance_screen.dart';
import 'package:maucoffee/home/admin_home_screen.dart';
import 'package:maucoffee/features/sales_transaction_screen.dart';
import 'package:maucoffee/features/catalog/catalog_inventory_screen.dart';
import 'package:maucoffee/features/history_screen.dart';
import 'package:maucoffee/features/finance_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maucoffee/features/setting/settings_screen.dart';
import 'package:maucoffee/features/setting/cubit/setting_cubit.dart';
import 'package:maucoffee/services/history_manager.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 1});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Default to index 1 (Transaksi Penjualan)
  bool _isMenuOpen = false;

  void setIndex(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _currentIndex = index;
        _isMenuOpen = false;
      });
    }
  }

  late final List<Widget> _pages;

  // Active Shift State
  Timer? _navigationTimer;
  DateTime? _activeShiftStartTime;
  String _activeShiftFormattedDuration = "00:00:00";

  // Draggable Pill Position
  double? _pillX;
  double? _pillY;
  bool _hasInitializedPillPosition = false;
  Duration _animationDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const AdminHomeScreen(),
      const SalesTransactionScreen(),
      const HistoryScreen(),
      const AttendanceScreen(),
      _placeholder("Manajemen"),
      const FinanceScreen(),
      const CatalogInventoryScreen(),
      BlocProvider<SettingCubit>(
        create: (context) => serviceLocator<SettingCubit>(),
        child: const SettingsScreen(),
      ),
    ];
    _startNavigationTimer();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _startNavigationTimer() {
    _navigationTimer?.cancel();
    _navigationTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      final activeShift = await HistoryManager().getActiveShift();
      if (activeShift != null) {
        final startTime = activeShift["startTime"] as DateTime;
        final duration = DateTime.now().difference(startTime);

        if (mounted) {
          setState(() {
            _activeShiftStartTime = startTime;
            _activeShiftFormattedDuration = _formatDuration(duration);
          });
        }
      } else {
        if (_activeShiftStartTime != null) {
          if (mounted) {
            setState(() {
              _activeShiftStartTime = null;
              _activeShiftFormattedDuration = "00:00:00";
              _hasInitializedPillPosition =
                  false; // Reset position on shift stop
            });
          }
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final size = MediaQuery.of(context).size;

    // Initialize pill position to bottom right on first active frame, snapping above the new bottom bar
    if (_activeShiftStartTime != null && !_hasInitializedPillPosition) {
      final bottomBarHeight =
          64 + (bottomPadding > 0 ? bottomPadding : spacing4) + spacing2;
      _pillX = size.width - 135 - spacing4;
      _pillY = size.height - bottomBarHeight - 56 - spacing2;
      _hasInitializedPillPosition = true;
    }

    return Scaffold(
      extendBody: true, // Let content flow behind floating glass bar
      body: Stack(
        children: [
          // Background Gradient matching other screens
          Container(
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
          ),

          // Switch between screens with iOS-like slide+fade transition
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _pages[_currentIndex],
              ),
            ),
          ),

          // Persistent Floating Shift Pill (Draggable & Snapping)
          if (_activeShiftStartTime != null && !_isMenuOpen)
            AnimatedPositioned(
              duration: _animationDuration,
              curve: Curves.easeOutBack, // Bouncy curve for premium feel
              left: _pillX,
              top: _pillY,
              child: _buildActiveShiftPill(),
            ),

          // Full Screen Blur Menu Overlay
          if (_isMenuOpen) _buildFullScreenMenu(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ── Private Navigation Widgets ──

  // ── New Navigation & Menu Layout ──

  Widget _buildBottomNavigationBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.only(
        left: spacing4,
        right: spacing4,
        bottom: bottomPadding > 0 ? bottomPadding : spacing4,
      ),
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A0A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navTab(0, Icons.home_rounded, "Beranda"),
              _navTab(1, Icons.coffee_rounded, "Item"),
              _navTab(-1, Icons.grid_view_rounded, "Menu", isMenuButton: true),
              _navTab(7, Icons.settings_rounded, "Pengaturan"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navTab(
    int index,
    IconData icon,
    String label, {
    bool isMenuButton = false,
  }) {
    final bool isActive = isMenuButton
        ? _isMenuOpen
        : (!_isMenuOpen && _currentIndex == index);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (isMenuButton) {
            setState(() {
              _isMenuOpen = !_isMenuOpen;
            });
          } else {
            setState(() {
              _currentIndex = index;
              _isMenuOpen = false;
            });
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? primaryColor : Colors.white.withOpacity(0.4),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: xxsBold.copyWith(
                color: isActive ? primaryColor : Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenMenu() {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.black.withOpacity(0.65),
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  // Header Akses Cepat tepat di atas grid
                  Padding(
                    padding: const EdgeInsets.only(
                      left: spacing5,
                      right: spacing5,
                      bottom: spacing3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Text(
                        //   "Akses Cepat",
                        //   style: smBold.copyWith(color: Colors.white70),
                        // ),
                        // GestureDetector(
                        //   onTap: () {
                        //     HapticFeedback.mediumImpact();
                        //     setState(() {
                        //       _isMenuOpen = false;
                        //     });
                        //   },
                        //   child: Text(
                        //     "Tutup",
                        //     style: xsRegular.copyWith(color: primaryColor),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  // Grid Menu Vertikal (4 Baris x 2 Kolom)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: spacing4),
                    child: Column(
                      children: [
                        // Baris 1: Beranda & Item
                        Row(
                          children: [
                            _gridMenuItem(0, Icons.home_rounded, "Beranda"),
                            _gridMenuItem(1, Icons.coffee_rounded, "Item"),
                          ],
                        ),
                        const SizedBox(height: spacing2),
                        // Baris 2: Katalog & Histori
                        Row(
                          children: [
                            _gridMenuItem(
                              6,
                              Icons.inventory_2_outlined,
                              "Katalog",
                            ),
                            _gridMenuItem(2, Icons.history_rounded, "Histori"),
                          ],
                        ),
                        const SizedBox(height: spacing2),
                        // Baris 3: Absensi & Manajemen
                        Row(
                          children: [
                            _gridMenuItem(
                              3,
                              Icons.fingerprint_rounded,
                              "Absensi",
                            ),
                            _gridMenuItem(
                              4,
                              Icons.people_outline_rounded,
                              "Manajemen",
                            ),
                          ],
                        ),
                        const SizedBox(height: spacing2),
                        // Baris 4: Keuangan & Pengaturan
                        Row(
                          children: [
                            _gridMenuItem(
                              5,
                              Icons.account_balance_wallet_rounded,
                              "Keuangan",
                            ),
                            _gridMenuItem(
                              7,
                              Icons.settings_rounded,
                              "Pengaturan",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Menyesuaikan jarak bawah agar pas di atas Bottom Navigation Bar
                  SizedBox(
                    height:
                        64 +
                        (MediaQuery.of(context).padding.bottom > 0
                            ? MediaQuery.of(context).padding.bottom
                            : spacing4) +
                        spacing3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gridMenuItem(int index, IconData icon, String label) {
    final bool isLocked = index == 4; // Manajemen is locked
    final bool isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isLocked) {
            HapticFeedback.heavyImpact();
            CustomFeedback.showInfo(
              context,
              "Fitur Manajemen Toko terkunci (Sedang dalam pengembangan).",
            );
            return;
          }
          HapticFeedback.lightImpact();
          setState(() {
            _currentIndex = index;
            _isMenuOpen = false;
          });
        },
        child: Container(
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1A0A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? primaryColor : Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isLocked
                        ? Colors.white.withOpacity(0.25)
                        : (isActive ? primaryColor : Colors.white70),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: xxsBold.copyWith(
                      color: isLocked
                          ? Colors.white.withOpacity(0.3)
                          : (isActive ? primaryColor : Colors.white),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (isLocked)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.lock_rounded, color: iconWhite, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(String title) {
    return Center(
      child: Text(title, style: lgBold.copyWith(color: Colors.white)),
    );
  }

  Widget _buildActiveShiftPill() {
    return GestureDetector(
      onPanStart: (_) {
        setState(() {
          _animationDuration = Duration.zero; // Drag response is immediate
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _pillX = (_pillX ?? 0) + details.delta.dx;
          _pillY = (_pillY ?? 0) + details.delta.dy;

          // Clamping bounds to keep the pill within the screen view, snapping above bottom bar
          final size = MediaQuery.of(context).size;
          final topPadding = MediaQuery.of(context).padding.top;
          final bottomPadding = MediaQuery.of(context).padding.bottom;
          final bottomBarHeight =
              64 + (bottomPadding > 0 ? bottomPadding : spacing4) + spacing2;

          _pillX = _pillX!.clamp(spacing4, size.width - 135 - spacing4);
          _pillY = _pillY!.clamp(
            topPadding + spacing4,
            size.height - bottomBarHeight - 56,
          );
        });
      },
      onPanEnd: (_) {
        final size = MediaQuery.of(context).size;
        final topPadding = MediaQuery.of(context).padding.top;
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        final bottomBarHeight =
            64 + (bottomPadding > 0 ? bottomPadding : spacing4) + spacing2;

        final leftBound = spacing4;
        final rightBound = size.width - 135 - spacing4;
        final topBound = topPadding + spacing4;
        final bottomBound = size.height - bottomBarHeight - 56;

        // Snap X to nearest horizontal edge (left or right)
        final midX = size.width / 2;
        final targetX = (_pillX! + (135 / 2) < midX) ? leftBound : rightBound;

        // Snap Y to nearest vertical edge (top or bottom)
        final midY = (topPadding + size.height - bottomBarHeight - 56) / 2;
        final targetY = (_pillY! + (56 / 2) < midY) ? topBound : bottomBound;

        setState(() {
          _animationDuration = const Duration(milliseconds: 350);
          _pillX = targetX;
          _pillY = targetY;
        });
      },
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() {
          _currentIndex = 3; // Buka tab Absensi
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 135, // Fixed width for precise clamping
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF2A1A0A).withValues(alpha: 0.85),
              border: Border.all(
                color: const Color(0xFFE27D00).withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PulseDot(),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Shift Kerja",
                      style: xxxsBold.copyWith(color: Colors.white38),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _activeShiftFormattedDuration,
                      style: xsBold.copyWith(
                        color: const Color(0xFFE27D00),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF00C853),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0xFF00C853), blurRadius: 4, spreadRadius: 1),
          ],
        ),
      ),
    );
  }
}
