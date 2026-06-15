import 'package:flutter/material.dart';
import 'package:maucoffee/auth/admin_scan_employee_screen.dart';
import 'package:maucoffee/auth/role_selector_screen.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = serviceLocator<UserPreference>();
    prefs.clearData();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(spacing4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius200),
        border: Border.all(color: black200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: xxsMedium.copyWith(color: textDarkSecondary),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: spacing2),
          Text(
            value,
            style: mdBold.copyWith(color: textDarkPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius300),
      child: Container(
        padding: const EdgeInsets.all(spacing5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius300),
          border: Border.all(color: black200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(borderRadius200),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: primaryColor,
                size: 26,
              ),
            ),
            const SizedBox(width: spacing4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: sBold.copyWith(color: textDarkPrimary),
                  ),
                  const SizedBox(height: spacing1),
                  Text(
                    description,
                    style: xsRegular.copyWith(color: textDarkSecondary, height: 1.2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: spacing2),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: black400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black50,
      appBar: AppBar(
        title: Text(
          "Mau Coffee Admin",
          style: mdBold.copyWith(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => _handleLogout(context),
            tooltip: "Logout",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Welcome Header Banner
            Container(
              color: primaryColor,
              padding: const EdgeInsets.only(
                left: spacing6,
                right: spacing6,
                bottom: spacing8,
                top: spacing2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, Business Owner! 👋",
                    style: lgBold.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: spacing2),
                  Text(
                    "Manage your shop products, staff members, and daily transactions report.",
                    style: sRegular.copyWith(color: Colors.white.withOpacity(0.9), height: 1.4),
                  ),
                ],
              ),
            ),

            // 2. Statistics Section (Visual Mockup)
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: spacing6),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Today's Sales",
                        "Rp 0",
                        Icons.monetization_on_rounded,
                        primaryColor,
                      ),
                    ),
                    const SizedBox(width: spacing4),
                    Expanded(
                      child: _buildStatCard(
                        "Registered Staff",
                        "-",
                        Icons.badge_rounded,
                        orange500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Menu Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacing6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Management Menu",
                    style: sBold.copyWith(color: textDarkPrimary),
                  ),
                  const SizedBox(height: spacing4),

                  // Menu: Kelola Karyawan
                  _buildMenuCard(
                    title: "Kelola Karyawan (Register)",
                    description: "Scan new staff QR code and assign their shop access roles.",
                    icon: Icons.people_alt_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminScanEmployeeScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: spacing4),

                  // Menu: Kelola Produk (Placeholder)
                  Opacity(
                    opacity: 0.6,
                    child: _buildMenuCard(
                      title: "Manage Catalog (Under Construction)",
                      description: "Edit categories, products items, and inventory stocks.",
                      icon: Icons.coffee_rounded,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Fitur Kelola Katalog akan segera hadir!"),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
