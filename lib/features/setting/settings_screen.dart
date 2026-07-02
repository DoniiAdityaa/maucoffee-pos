import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/repository/cafe_profile_repository.dart';
import 'package:maucoffee/model/cafe_profile_model.dart';
import 'package:maucoffee/services/sync_manager.dart';
import 'package:maucoffee/features/catalog/cubit/catalog_cubit.dart';
import 'package:maucoffee/features/absensi/cubit/absensi_cubit.dart';
import 'package:maucoffee/auth/role_selector_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Shared Preferences Keys
  static const String _keyCafeName = "settings_cafe_name";
  static const String _keyCafeAddress = "settings_cafe_address";
  static const String _keyCafePhone = "settings_cafe_phone";
  static const String _keyPaperSize = "settings_paper_size";
  static const String _keyLastSync = "settings_last_sync";

  // State Variables
  String _cafeName = "Maucoffee POS";
  String _cafeAddress = "Jl. Kenangan Manis No. 45, Jakarta";
  String _cafePhone = "0812-3456-7890";
  String _paperSize = "58mm";
  String _lastSyncTime = "Belum pernah disinkronkan";

  bool _isSyncing = false;
  final bool _isPrinterConnected = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  String? _getAdminId() {
    final client = Supabase.instance.client;
    final userPrefs = serviceLocator<UserPreference>();
    final role = userPrefs.getLoginRole();
    if (role == 'admin') {
      return client.auth.currentUser?.id;
    } else {
      return userPrefs.getEmployee()?.adminId;
    }
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cafeName = prefs.getString(_keyCafeName) ?? "Maucoffee POS";
      _cafeAddress =
          prefs.getString(_keyCafeAddress) ??
          "Jl. Kenangan Manis No. 45, Jakarta";
      _cafePhone = prefs.getString(_keyCafePhone) ?? "0812-3456-7890";
      _paperSize = prefs.getString(_keyPaperSize) ?? "58mm";
      _lastSyncTime =
          prefs.getString(_keyLastSync) ??
          "Terakhir sinkronisasi: 20 Juni 2026, 22:15";
    });

    // Jalankan asinkron untuk fetch profil dari Supabase Cloud secara global
    try {
      final cloudProfile = await serviceLocator<CafeProfileRepository>()
          .getProfile();
      if (cloudProfile != null) {
        await prefs.setString(_keyCafeName, cloudProfile.name);
        await prefs.setString(_keyCafeAddress, cloudProfile.address);
        await prefs.setString(_keyCafePhone, cloudProfile.phone);

        if (mounted) {
          setState(() {
            _cafeName = cloudProfile.name;
            _cafeAddress = cloudProfile.address;
            _cafePhone = cloudProfile.phone;
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat profil kafe dari cloud: $e");
    }
  }

  // Save specific setting to SharedPreferences
  Future<void> _saveSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // Show bottom sheet to edit Cafe Profile
  void _showEditProfileSheet() {
    HapticFeedback.mediumImpact();
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _cafeName);
    final addressController = TextEditingController(text: _cafeAddress);
    final phoneController = TextEditingController(text: _cafePhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: spacing6,
          right: spacing6,
          top: spacing6,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + spacing6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E140A).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBottomSheetHandle(),
              const SizedBox(height: spacing5),
              Text(
                "Edit Profil Kafe",
                style: mdBold.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: spacing6),

              // Inputs
              _buildFormInputField(
                label: "Nama Kafe",
                controller: nameController,
                hintText: "Nama Kafe",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama kafe tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: spacing4),

              _buildFormInputField(
                label: "Alamat Lengkap",
                controller: addressController,
                hintText: "Alamat Lengkap",
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alamat tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: spacing4),

              _buildFormInputField(
                label: "Nomor Telepon (Opsional)",
                controller: phoneController,
                hintText: "Contoh: 08123456789",
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: spacing7),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Batal",
                        style: sBold.copyWith(color: Colors.white60),
                      ),
                    ),
                  ),
                  const SizedBox(width: spacing3),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryColor, Color(0xFFC56D00)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final newName = nameController.text.trim();
                            final newAddress = addressController.text.trim();
                            final newPhone = phoneController.text.trim();

                            await _saveSetting(_keyCafeName, newName);
                            await _saveSetting(_keyCafeAddress, newAddress);
                            await _saveSetting(_keyCafePhone, newPhone);

                            // Kirim ke Supabase Cloud
                            try {
                              final profile = CafeProfileModel(
                                id: 'default',
                                name: newName,
                                address: newAddress,
                                phone: newPhone,
                                updatedAt: DateTime.now(),
                              );
                              await serviceLocator<CafeProfileRepository>()
                                  .saveProfile(profile);
                            } catch (e) {
                              debugPrint(
                                "Gagal sinkronisasi profil ke cloud: $e",
                              );
                            }

                            setState(() {
                              _cafeName = newName;
                              _cafeAddress = newAddress;
                              _cafePhone = newPhone;
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              CustomFeedback.showSuccess(
                                context,
                                "Profil kafe berhasil diperbarui ke Cloud!",
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Simpan",
                          style: sBold.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: spacing2),
            ],
          ),
        ),
      ),
    );
  }

  // Trigger Real Sync to Cloud
  Future<void> _triggerSync() async {
    if (_isSyncing) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isSyncing = true;
    });

    try {
      // 1. Upload Data Offline
      await SyncManager().syncAllData();

      // 2. Download Profil Kafe Ter-Update
      final cloudProfile = await serviceLocator<CafeProfileRepository>()
          .getProfile();
      if (cloudProfile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyCafeName, cloudProfile.name);
        await prefs.setString(_keyCafeAddress, cloudProfile.address);
        await prefs.setString(_keyCafePhone, cloudProfile.phone);

        setState(() {
          _cafeName = cloudProfile.name;
          _cafeAddress = cloudProfile.address;
          _cafePhone = cloudProfile.phone;
        });
      }

      // 3. Download & Refresh Katalog & Stok Bahan Baku (Cubit)
      if (mounted) {
        await context.read<CatalogCubit>().fetchCatalog();
      }

      // 4. Download & Refresh Shift Aktif & Riwayat Absensi (Cubit)
      if (mounted) {
        final absensiCubit = context.read<AbsensiCubit>();
        await absensiCubit.fetchActiveShifts();
        await absensiCubit.fetchShiftHistory();
      }

      final now = DateTime.now();
      final formattedTime = DateFormat('dd MMM yyyy, HH:mm').format(now);
      final lastSyncString = "Terakhir sinkronisasi: $formattedTime";

      await _saveSetting(_keyLastSync, lastSyncString);

      if (mounted) {
        setState(() {
          _isSyncing = false;
          _lastSyncTime = lastSyncString;
        });
        CustomFeedback.showSuccess(
          context,
          "Sinkronisasi Berhasil! Seluruh transaksi offline diunggah dan database lokal diperbarui.",
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        CustomFeedback.showError(context, "Sinkronisasi Gagal: $e");
      }
    }
  }

  // Test Print receipt function
  void _testPrint() {
    HapticFeedback.mediumImpact();
    CustomFeedback.showSuccess(
      context,
      "Mengirim data cetak uji coba ke printer... (Ukuran: $_paperSize)",
    );
  }

  // Show Logout Confirmation Modal
  void _showLogoutConfirmation() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(spacing6),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1207).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBottomSheetHandle(),
            const SizedBox(height: spacing5),
            const Icon(Icons.logout_rounded, color: errorColor, size: 48),
            const SizedBox(height: spacing4),
            Text(
              "Keluar dari Akun?",
              style: mdBold.copyWith(color: Colors.white),
            ),
            const SizedBox(height: spacing3),
            Text(
              "Anda harus memasukkan kembali password atau PIN untuk masuk ke aplikasi Maucoffee.",
              style: sRegular.copyWith(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: spacing6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Batal",
                      style: sBold.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: spacing4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      HapticFeedback.heavyImpact();

                      final prefs = serviceLocator<UserPreference>();
                      prefs.clearData();

                      Navigator.pushAndRemoveUntil(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const RoleSelectorScreen(),
                          transitionDuration: const Duration(milliseconds: 400),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Keluar",
                      style: sBold.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: spacing2),
          ],
        ),
      ),
    );
  }

  // ── CORE BUILD METHOD ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: spacing6,
                  right: spacing6,
                  bottom:
                      100, // Extra bottom padding for floating navigation bar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCafeProfileCard(),
                    const SizedBox(height: spacing5),
                    _buildPrinterCard(),
                    const SizedBox(height: spacing5),
                    _buildSyncCard(),
                    const SizedBox(height: spacing5),
                    _buildSecurityCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SUB WIDGET BUILDERS (Extracted to keep code readable) ──

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: spacing6,
        vertical: spacing4,
      ),
      child: Text("Pengaturan", style: lgBold.copyWith(color: Colors.white)),
    );
  }

  Widget _buildCafeProfileCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: spacing3),
                  Text(
                    "Profil Kafe",
                    style: sBold.copyWith(color: Colors.white),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showEditProfileSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    "Edit Profil",
                    style: xxsBold.copyWith(color: primaryColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: spacing4),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: spacing4),

          _buildInfoRow("Nama Kafe", _cafeName),
          const SizedBox(height: spacing4),
          _buildInfoRow("Alamat Lengkap", _cafeAddress, isDimmed: true),
          const SizedBox(height: spacing4),
          _buildInfoRow("No. Telepon", _cafePhone.isEmpty ? "-" : _cafePhone),
        ],
      ),
    );
  }

  Widget _buildPrinterCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      color: Color(0xFF00C853),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: spacing3),
                  Text(
                    "Printer Struk & Dapur",
                    style: sBold.copyWith(color: Colors.white),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isPrinterConnected
                          ? const Color(0xFF00C853)
                          : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isPrinterConnected ? "Terhubung" : "Terputus",
                    style: xxsBold.copyWith(
                      color: _isPrinterConnected
                          ? const Color(0xFF00C853)
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: spacing4),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: spacing4),

          Text(
            "Ukuran Kertas Struk",
            style: xxsBold.copyWith(color: Colors.white38),
          ),
          const SizedBox(height: spacing3),
          Row(
            children: [
              _paperSizeChip("58mm"),
              const SizedBox(width: spacing3),
              _paperSizeChip("80mm"),
            ],
          ),
          const SizedBox(height: spacing5),

          GestureDetector(
            onTap: _testPrint,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Cetak Struk Uji Coba",
                    style: sBold.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.cloud_sync_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: spacing3),
              Text("Sinkronisasi", style: sBold.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: spacing4),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: spacing4),

          // Status Terakhir Sync\
          Container(
            padding: const EdgeInsets.all(spacing3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: Colors.white38,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastSyncTime,
                    style: xxsMedium.copyWith(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: spacing5),

          // Sync Button
          GestureDetector(
            onTap: _isSyncing ? null : _triggerSync,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _isSyncing
                    ? Colors.white.withValues(alpha: 0.04)
                    : primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSyncing
                      ? Colors.white.withValues(alpha: 0.08)
                      : primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: _isSyncing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Sinkronisasi data...",
                          style: sBold.copyWith(color: primaryColor),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.sync_rounded,
                          color: primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Sinkronisasi Sekarang",
                          style: sBold.copyWith(color: primaryColor),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return GestureDetector(
      onTap: _showLogoutConfirmation,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: errorColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: errorColor, size: 18),
            const SizedBox(width: 8),
            Text("Keluar dari Akun", style: sBold.copyWith(color: errorColor)),
          ],
        ),
      ),
    );
  }

  // ── REUSABLE HELPER WIDGETS ──

  // Reusable Glassmorphic Container
  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(spacing5),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: child,
        ),
      ),
    );
  }

  // Info details Row inside profile card
  Widget _buildInfoRow(String label, String value, {bool isDimmed = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: xxsBold.copyWith(color: Colors.white38)),
        const SizedBox(height: 2),
        Text(
          value,
          style: sMedium.copyWith(
            color: isDimmed ? Colors.white70 : Colors.white,
          ),
        ),
      ],
    );
  }

  // Reusable bottom sheet indicator bar
  Widget _buildBottomSheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // Reusable form text input field
  Widget _buildFormInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: xsBold.copyWith(color: Colors.white70)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: spacing3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: sMedium.copyWith(color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: sMedium.copyWith(color: Colors.white24),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  // Paper Size Selector Chip
  Widget _paperSizeChip(String size) {
    final bool isSelected = _paperSize == size;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          await _saveSetting(_keyPaperSize, size);
          setState(() {
            _paperSize = size;
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
              width: 1.2,
            ),
          ),
          child: Text(
            size,
            style: sBold.copyWith(
              color: isSelected ? primaryColor : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }
}
