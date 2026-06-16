import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maucoffee/home/admin_home_screen.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const AdminHomeScreen(),
      _placeholder("Sales"),
      _placeholder("Staff"),
      _placeholder("Catalog"),
      _placeholder("Profile"),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
      bottomNavigationBar: _nav(),
    );
  }

  // ── Private Navigation Widgets ──
  Widget _nav() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: spacing4,
        right: spacing4,
        bottom: bottomPadding > 0 ? bottomPadding : spacing5,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: spacing3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0xFF2A1A0A).withOpacity(0.80),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, "Home"),
                _navItem(1, Icons.receipt_long_rounded, "Sales"),
                _navItem(2, Icons.people_outline_rounded, "Staff"),
                _navItem(3, Icons.inventory_2_outlined, "Catalog"),
                _navItem(4, Icons.person_outline_rounded, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.lightImpact();
          setState(() {
            _currentIndex = index;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          minWidth: 48,
          maxWidth: isActive ? 160 : 48,
          minHeight: 48,
          maxHeight: 48,
        ),
        padding: isActive
            ? const EdgeInsets.symmetric(horizontal: spacing3)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isActive
              ? const Color(0xFFE27D00).withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: isActive
                ? const Color(0xFFE27D00).withOpacity(0.3)
                : Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        alignment: isActive ? null : Alignment.center,
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xFFE27D00)
                  : Colors.white.withOpacity(0.45),
              size: 22,
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  clipBehavior: Clip.hardEdge,
                  child: isActive
                      ? Padding(
                          padding: const EdgeInsets.only(left: spacing2),
                          child: Text(
                            label,
                            style: xsBold.copyWith(
                              color: const Color(0xFFE27D00),
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
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
