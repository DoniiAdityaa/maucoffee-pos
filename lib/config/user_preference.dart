import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:maucoffee/model/user_model.dart';
import 'package:maucoffee/model/employee_model.dart'; // Import EmployeeModel
import 'package:shared_preferences/shared_preferences.dart';

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
    if (uuid == null) {
      // Membuat format ID unik sederhana dari timestamp + angka acak
      final random = DateTime.now().microsecondsSinceEpoch.toString();
      uuid = "emp-$random";
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
    prefs.clear();
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
}
