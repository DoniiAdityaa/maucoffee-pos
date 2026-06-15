import 'package:flutter/material.dart';
import 'package:maucoffee/auth/admin_login_screen.dart';
import 'package:maucoffee/auth/employee_register_qr_screen.dart';

// Import Design System kita
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          black50, // Menggunakan warna abu-abu sangat muda dari color.dart
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: spacing6,
              vertical: spacing8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Text
                Text(
                  "Select your role to continue",
                  style: sMedium.copyWith(color: textDarkSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: spacing8),

                // 1. KARTU BUSINESS OWNER
                Container(
                  padding: const EdgeInsets.all(spacing6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius300),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar Icon Box
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(borderRadius300),
                        ),
                        child: const Icon(
                          Icons.business_center_rounded,
                          size: 44,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: spacing6),
                      // Title
                      Text(
                        "Business Owner",
                        style: mdBold.copyWith(color: textDarkPrimary),
                      ),
                      const SizedBox(height: spacing3),
                      // Description
                      Text(
                        "Manage your business, sales, inventory, and reports",
                        style: sRegular.copyWith(
                          color: textDarkSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: spacing6),
                      // Button "I am Owner"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminLoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: spacing5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                borderRadius300,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "I am Owner",
                                style: smBold.copyWith(color: Colors.white),
                              ),
                              const SizedBox(width: spacing2),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: spacing6),

                // Separator "or"
                Text(
                  "or",
                  style: sRegular.copyWith(color: textDarkSecondary),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: spacing6),

                // 2. KARTU STAFF MEMBER
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmployeeRegisterQrScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(borderRadius300),
                  child: Container(
                    padding: const EdgeInsets.all(spacing5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(borderRadius300),
                      border: Border.all(color: black200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar Icon Box
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: black100,
                            borderRadius: BorderRadius.circular(
                              borderRadius300,
                            ),
                          ),
                          child: const Icon(
                            Icons.people_alt_rounded,
                            size: 30,
                            color: textDarkSecondary,
                          ),
                        ),
                        const SizedBox(width: spacing5),
                        // Text Column (Title & Subtitle)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Staff Member",
                                style: sBold.copyWith(color: textDarkPrimary),
                              ),
                              const SizedBox(height: spacing1),
                              Text(
                                "Access your workplace by scanning QR code from your employer",
                                style: xsRegular.copyWith(
                                  color: textDarkSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: spacing2),
                        // Arrow Icon
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: black400,
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
    );
  }
}
