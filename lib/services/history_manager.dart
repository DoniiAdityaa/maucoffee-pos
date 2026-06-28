import 'package:shared_preferences/shared_preferences.dart';

class HistoryManager {
  static final HistoryManager _instance = HistoryManager._internal();
  factory HistoryManager() => _instance;

  HistoryManager._internal();

  // ── SharedPreferences Helpers untuk Shift Aktif (Timer Resiliensi) ──
  static const String _keyActiveShiftStart = "active_shift_start";
  static const String _keyActiveShiftName = "active_shift_name";
  static const String _keyActiveShiftRole = "active_shift_role";
  static const String _keyActiveShiftId = "active_shift_id";

  Future<void> saveActiveShift(String employeeName, String role, DateTime startTime, String? shiftId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveShiftName, employeeName);
    await prefs.setString(_keyActiveShiftRole, role);
    await prefs.setString(_keyActiveShiftStart, startTime.toIso8601String());
    if (shiftId != null) {
      await prefs.setString(_keyActiveShiftId, shiftId);
    }
  }

  Future<Map<String, dynamic>?> getActiveShift() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyActiveShiftName);
    final role = prefs.getString(_keyActiveShiftRole);
    final startStr = prefs.getString(_keyActiveShiftStart);
    final shiftId = prefs.getString(_keyActiveShiftId);

    if (name == null || role == null || startStr == null) {
      return null;
    }

    return {
      "name": name,
      "role": role,
      "startTime": DateTime.parse(startStr),
      "shiftId": shiftId,
    };
  }

  Future<void> clearActiveShift() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveShiftName);
    await prefs.remove(_keyActiveShiftRole);
    await prefs.remove(_keyActiveShiftStart);
    await prefs.remove(_keyActiveShiftId);
  }
}
