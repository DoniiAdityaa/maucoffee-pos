import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:maucoffee/model/user_model.dart';
import 'package:maucoffee/model/employee_model.dart'; // Import EmployeeModel
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserPreference {
  final SharedPreferences prefs;
  UserPreference(this.prefs);

  // Simpan & Get Token Supabase / API
  Future<void> setToken(String newToken) async {
    debugPrint("SAVED TOKEN => $newToken");
    await prefs.setString("token", newToken);
  }

  String? getToken() {
    return prefs.getString("token");
  }

  // Simpan status Role login saat ini (apakah 'admin' atau 'employee')
  Future<void> setLoginRole(String role) async {
    await prefs.setString("login_role", role);
  }

  String? getLoginRole() {
    return prefs.getString("login_role");
  }

  // Simpan sesi Karyawan
  Future<void> setEmployee(EmployeeModel employee) async {
    await prefs.setString("employee", json.encode(employee.toJson()));
  }

  EmployeeModel? getEmployee() {
    final raw = prefs.getString("employee");
    if (raw == null) return null;
    try {
      return EmployeeModel.fromJson(json.decode(raw));
    } catch (e) {
      return null;
    }
  }

  // Generate & Simpan ID Perangkat Unik (Untuk QR Handshake Karyawan Baru)
  String getDeviceUuid() {
    var uuid = prefs.getString("device_uuid");
    // Otomatis regenerasi ke format baru jika belum ada atau masih format lama (emp- angka)
    if (uuid == null || uuid.startsWith("emp-")) {
      final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final rand = Random();
      final code = List.generate(
        6,
        (index) => chars[rand.nextInt(chars.length)],
      ).join();
      uuid = "EMP-$code";
      prefs.setString("device_uuid", uuid);
    }
    return uuid;
  }

  Future<void> setUser(UserModel data) async {
    await prefs.setString("user", json.encode(data.toJson()));
  }

  UserModel getUser() {
    if (prefs.getString("user") != null) {
      try {
        return UserModel.fromJson(json.decode(prefs.getString("user") ?? ""));
      } catch (e) {
        return UserModel();
      }
    } else {
      return UserModel();
    }
  }

  void clearData() {
    // 1. Simpan sementara data penting yang tidak boleh hilang
    final deviceUuid = prefs.getString("device_uuid");
    final hasSeenOnboarding = prefs.getBool("has_seen_onboarding");
    final darkMode = prefs.getBool("dark_mode");

    // 2. Bersihkan seluruh session login
    prefs.clear();

    // 3. Kembalikan data penting ke penyimpanan
    if (deviceUuid != null) {
      prefs.setString("device_uuid", deviceUuid);
    }
    if (hasSeenOnboarding != null) {
      prefs.setBool("has_seen_onboarding", hasSeenOnboarding);
    }
    if (darkMode != null) {
      prefs.setBool("dark_mode", darkMode);
    }
  }

  bool isDarkMode() {
    return prefs.getBool("dark_mode") ?? false;
  }

  Future<void> setHasSeenOnboarding(bool hasSeen) async {
    await prefs.setBool("has_seen_onboarding", hasSeen);
  }

  bool hasSeenOnboarding() {
    return prefs.getBool("has_seen_onboarding") ?? false;
  }

  // Mengambil ID Admin pemilik toko secara dinamis berdasarkan role login aktif
  String? getActiveAdminId() {
    final role = getLoginRole();
    if (role == 'employee') {
      return getEmployee()?.adminId;
    }
    return Supabase.instance.client.auth.currentUser?.id;
  }

  // ── Preferensi Printer Thermal ──

  // MAC Address / Device Address printer yang terhubung
  Future<void> setPrinterAddress(String address) async {
    await prefs.setString("printer_address", address);
  }

  String? getPrinterAddress() {
    return prefs.getString("printer_address");
  }

  // Nama Printer (misal "PT-210")
  Future<void> setPrinterName(String name) async {
    await prefs.setString("printer_name", name);
  }

  String? getPrinterName() {
    return prefs.getString("printer_name");
  }

  // Ukuran Kertas: 58 (58mm) atau 80 (80mm)
  Future<void> setPrinterPaperSize(int size) async {
    await prefs.setInt("printer_paper_size", size);
  }

  int getPrinterPaperSize() {
    return prefs.getInt("printer_paper_size") ?? 58;
  }

  // Header Struk (Nama/Alamat Kafe)
  Future<void> setReceiptHeader(String header) async {
    await prefs.setString("receipt_header", header);
  }

  String getReceiptHeader() {
    return prefs.getString("receipt_header") ?? "Maucoffee Kafe";
  }

  // Footer Struk (Pesan Penutup)
  Future<void> setReceiptFooter(String footer) async {
    await prefs.setString("receipt_footer", footer);
  }

  String getReceiptFooter() {
    return prefs.getString("receipt_footer") ?? "Terima kasih atas kunjungan Anda!";
  }

  // Auto Print Setiap Transaksi Sukses (Checkout)
  Future<void> setAutoPrintOnCheckout(bool enabled) async {
    await prefs.setBool("auto_print_checkout", enabled);
  }

  bool isAutoPrintOnCheckout() {
    return prefs.getBool("auto_print_checkout") ?? false;
  }
}
