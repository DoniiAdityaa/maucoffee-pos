import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maucoffee/home/admin_home_screen.dart';
import 'package:maucoffee/features/sales_transaction_screen.dart';
import 'package:maucoffee/features/catalog_inventory_screen.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Default to index 1 (Transaksi Penjualan)
  bool _isMenuOpen = false;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const AdminHomeScreen(),
      const SalesTransactionScreen(),
      _placeholder("Shift Kerja"),
      _placeholder("Absensi"),
      _placeholder("Manajemen"),
      _placeholder("Keuangan"),
      const CatalogInventoryScreen(),
      _placeholder("Pengaturan"),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
                  _menuItem(2, Icons.hourglass_bottom_rounded, "Shift Kerja"),
                ],
              ),
              Row(
                children: [
                  _menuItem(3, Icons.fingerprint_rounded, "Absensi"),
                  _menuItem(4, Icons.people_outline_rounded, "Manajemen"),
                  _menuItem(5, Icons.account_balance_wallet_rounded, "Keuangan"),
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
    final bool isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
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
                ? const Color(0xFFE27D00).withOpacity(0.15)
                : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? const Color(0xFFE27D00).withOpacity(0.3)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive
                    ? const Color(0xFFE27D00)
                    : Colors.white.withOpacity(0.45),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: xxsBold.copyWith(
                  color: isActive
                      ? const Color(0xFFE27D00)
                      : Colors.white.withOpacity(0.65),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
}
