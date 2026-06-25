import 'package:shared_preferences/shared_preferences.dart';
import 'package:maucoffee/model/expense_model.dart';

class TransactionItem {
  final String name;
  final int qty;
  final double price;

  TransactionItem({
    required this.name,
    required this.qty,
    required this.price,
  });
}

class TransactionHistory {
  final String id;
  final String customerName;
  final DateTime dateTime;
  final double totalAmount;
  final String paymentMethod;
  final List<TransactionItem> items;
  final double paidAmount;
  final double changeAmount;
  final String? qrisProofPath;

  TransactionHistory({
    required this.id,
    required this.customerName,
    required this.dateTime,
    required this.totalAmount,
    required this.paymentMethod,
    required this.items,
    this.paidAmount = 0.0,
    this.changeAmount = 0.0,
    this.qrisProofPath,
  });
}

class StockHistory {
  final String id;
  final String ingredientName;
  final String category;
  final double adjustedAmount;
  final double stockBefore;
  final double stockAfter;
  final String type; // "Tambah", "Kurang", atau "Baru"
  final DateTime dateTime;

  StockHistory({
    required this.id,
    required this.ingredientName,
    required this.category,
    required this.adjustedAmount,
    required this.stockBefore,
    required this.stockAfter,
    required this.type,
    required this.dateTime,
  });
}

class AttendanceHistory {
  final String id;
  final String employeeName;
  final String role;
  final DateTime startTime;
  final DateTime endTime;
  final String? note;

  AttendanceHistory({
    required this.id,
    required this.employeeName,
    required this.role,
    required this.startTime,
    required this.endTime,
    this.note,
  });
}

class HistoryManager {
  static final HistoryManager _instance = HistoryManager._internal();
  factory HistoryManager() => _instance;

  HistoryManager._internal() {
    initDummyData();
  }

  final List<TransactionHistory> _transactions = [];
  final List<StockHistory> _stockLogs = [];
  final List<AttendanceHistory> _attendanceLogs = [];
  final List<ExpenseModel> _expenses = [];

  List<TransactionHistory> get transactions => List.unmodifiable(_transactions);
  List<StockHistory> get stockLogs => List.unmodifiable(_stockLogs);
  List<AttendanceHistory> get attendanceLogs => List.unmodifiable(_attendanceLogs);
  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);

  void initDummyData() {
    // Dummy data removed as requested.
  }

  void addTransaction(TransactionHistory trx) {
    _transactions.insert(0, trx);
  }

  void addStockLog(StockHistory log) {
    _stockLogs.insert(0, log);
  }

  void addAttendance(AttendanceHistory attendance) {
    _attendanceLogs.insert(0, attendance);
  }

  void deleteAttendance(String id) {
    _attendanceLogs.removeWhere((log) => log.id == id);
  }

  void addExpense(ExpenseModel expense) {
    _expenses.insert(0, expense);
  }

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
