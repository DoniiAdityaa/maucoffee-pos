import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/home/employee_home_screen.dart';
import 'package:maucoffee/repository/employee_repository.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Import Design System kita
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class EmployeeRegisterQrScreen extends StatefulWidget {
  const EmployeeRegisterQrScreen({super.key});

  @override
  State<EmployeeRegisterQrScreen> createState() =>
      _EmployeeRegisterQrScreenState();
}

class _EmployeeRegisterQrScreenState extends State<EmployeeRegisterQrScreen> {
  late final String _deviceUuid;
  Timer? _pollingTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // 1. Dapatkan device UUID yang unik
    final prefs = serviceLocator<UserPreference>();
    _deviceUuid = prefs.getDeviceUuid();

    // 2. Mulai polling status registrasi dari Supabase setiap 3 detik
    _startPolling();
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
          // Handshake berhasil! Matikan timer
          _pollingTimer?.cancel();

          // Simpan data karyawan dan role login ke Local Preferences
          final prefs = serviceLocator<UserPreference>();
          await prefs.setEmployee(employee);
          await prefs.setLoginRole('employee');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Selamat datang, ${employee.name}! Registrasi berhasil sebagai ${employee.role}.",
                  style: sMedium.copyWith(color: Colors.white),
                ),
                backgroundColor: successColor,
              ),
            );

            // Masuk ke Halaman Utama Karyawan
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const EmployeeHomeScreen(),
              ),
              (route) => false,
            );
          }
        }
      } catch (e) {
        debugPrint("Error saat polling registrasi: $e");
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor, // Latar belakang warna hijau tosca penuh
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: spacing6,
            vertical: spacing4,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // 1. Teks Panduan Atas
              Text(
                "Ask business owner to scan this QR code",
                style: sMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: spacing6),

              // 2. Kartu QR Code Putih (Rounded)
              Container(
                padding: const EdgeInsets.all(spacing6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(borderRadius400),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _deviceUuid,
                  version: QrVersions.auto,
                  size: 240.0,
                  gapless: false,
                  foregroundColor: Colors.black54,
                ),
              ),

              const SizedBox(height: spacing6),

              // 3. Status Indicator (Premium look)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
                  const SizedBox(width: spacing3),
                  Text(
                    "Waiting for owner approval...",
                    style: xsMedium.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: spacing8),

              // 4. Teks Alternatif di Bawah
              Text(
                "Or enter this code manually on owner's device",
                style: xsRegular.copyWith(color: Colors.white.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: spacing2),

              // 5. Kode Alternatif (Device UUID)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: spacing4,
                  vertical: spacing2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(borderRadius100),
                ),
                child: Text(
                  _deviceUuid,
                  style: lgBold.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
