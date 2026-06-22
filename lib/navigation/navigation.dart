import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maucoffee/home/admin_home_screen.dart';
import 'package:maucoffee/features/sales_transaction_screen.dart';
import 'package:maucoffee/features/catalog_inventory_screen.dart';
import 'package:maucoffee/features/history_screen.dart';
import 'package:maucoffee/features/attendance_screen.dart';
import 'package:maucoffee/features/finance_screen.dart';
import 'package:maucoffee/features/settings_screen.dart';
import 'package:maucoffee/data/history_manager.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 1});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Default to index 1 (Transaksi Penjualan)
  bool _isMenuOpen = false;
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
      const SettingsScreen(),
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
    _navigationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
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
              _hasInitializedPillPosition = false; // Reset position on shift stop
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

    // Initialize pill position to bottom right on first active frame
    if (_activeShiftStartTime != null && !_hasInitializedPillPosition) {
      _pillX = size.width - 135 - spacing4;
      _pillY = size.height - (bottomPadding > 0 ? bottomPadding : spacing5) - 56;
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

          // Dimmer overlay when menu is open
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isMenuOpen = false;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),
            ),

          // Expanded Menu Panel (displays above the floating button when open)
          if (_isMenuOpen)
            Positioned(
              left: spacing4,
              right: spacing4,
              bottom: (bottomPadding > 0 ? bottomPadding : spacing5) + 68,
              child: _expandedMenuPanel(),
            ),

          // Floating Toggle Button (Coffee -> Cross)
          Positioned(
            left: spacing4,
            bottom: bottomPadding > 0 ? bottomPadding : spacing5,
            child: _toggleButton(),
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
        ],
      ),
    );


  }

  // ── Private Navigation Widgets ──

  Widget _toggleButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() {
          _isMenuOpen = !_isMenuOpen;
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _isMenuOpen
                  ? primaryColor
                  : const Color(0xFF2A1A0A).withOpacity(0.85),
              border: Border.all(
                color: _isMenuOpen
                    ? primaryColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _isMenuOpen ? Icons.close_rounded : Icons.local_cafe_rounded,
              color: _isMenuOpen ? Colors.white : primaryColor,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _expandedMenuPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 170,
          padding: const EdgeInsets.symmetric(
            vertical: spacing3,
            horizontal: spacing2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF2A1A0A).withOpacity(0.85),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  _menuItem(0, Icons.home_rounded, "Beranda"),
                  _menuItem(1, Icons.coffee_rounded, "Item"),
                  _menuItem(6, Icons.inventory_2_outlined, "Katalog"),
                  _menuItem(2, Icons.history_rounded, "Histori"),
                ],
              ),
              Row(
                children: [
                  _menuItem(3, Icons.fingerprint_rounded, "Absensi"),
                  _menuItem(4, Icons.people_outline_rounded, "Manajemen"),
                  _menuItem(
                    5,
                    Icons.account_balance_wallet_rounded,
                    "Keuangan",
                  ),
                  _menuItem(7, Icons.settings_rounded, "Pengaturan"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(int index, IconData icon, String label) {
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
          if (_currentIndex != index) {
            HapticFeedback.lightImpact();
            setState(() {
              _currentIndex = index;
              _isMenuOpen = false;
            });
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: spacing1,
            vertical: spacing1,
          ),
          padding: const EdgeInsets.symmetric(vertical: spacing2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? const Color(0xFFE27D00).withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? const Color(0xFFE27D00).withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isLocked
                        ? Colors.white.withValues(alpha: 0.25)
                        : (isActive
                            ? const Color(0xFFE27D00)
                            : Colors.white.withValues(alpha: 0.45)),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: xxsBold.copyWith(
                      color: isLocked
                          ? Colors.white.withValues(alpha: 0.35)
                          : (isActive
                              ? const Color(0xFFE27D00)
                              : Colors.white.withValues(alpha: 0.65)),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (isLocked)
                Positioned(
                  top: -4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE27D00),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2A1A0A),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
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

          // Clamping bounds to keep the pill within the screen view
          final size = MediaQuery.of(context).size;
          final topPadding = MediaQuery.of(context).padding.top;
          final bottomPadding = MediaQuery.of(context).padding.bottom;

          _pillX = _pillX!.clamp(spacing4, size.width - 135 - spacing4);
          _pillY = _pillY!.clamp(topPadding + spacing4, size.height - bottomPadding - 56 - spacing4);
        });
      },
      onPanEnd: (_) {
        final size = MediaQuery.of(context).size;
        final topPadding = MediaQuery.of(context).padding.top;
        final bottomPadding = MediaQuery.of(context).padding.bottom;

        final leftBound = spacing4;
        final rightBound = size.width - 135 - spacing4;
        final topBound = topPadding + spacing4;
        final bottomBound = size.height - bottomPadding - 56 - spacing4;

        // Snap X to nearest horizontal edge (left or right)
        final midX = size.width / 2;
        final targetX = (_pillX! + (135 / 2) < midX) ? leftBound : rightBound;

        // Snap Y to nearest vertical edge (top or bottom)
        final midY = (topPadding + size.height - bottomPadding - 56) / 2;
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
            BoxShadow(
              color: Color(0xFF00C853),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
