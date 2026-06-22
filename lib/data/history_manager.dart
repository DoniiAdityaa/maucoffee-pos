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
    if (_transactions.isNotEmpty ||
        _stockLogs.isNotEmpty ||
        _attendanceLogs.isNotEmpty ||
        _expenses.isNotEmpty) {
      return;
    }

    final now = DateTime.now();

    // Dummy Transaksi Penjualan
    _transactions.addAll([
      TransactionHistory(
        id: "TRX-48201",
        customerName: "Rian",
        dateTime: now.subtract(const Duration(minutes: 15)),
        totalAmount: 38000,
        paymentMethod: "Cash",
        paidAmount: 50000,
        changeAmount: 12000,
        items: [
          TransactionItem(name: "Americano Ice 340 ml", qty: 1, price: 20000),
          TransactionItem(name: "Ayam Geprek 1 potong", qty: 1, price: 18000),
        ],
      ),
      TransactionHistory(
        id: "TRX-19302",
        customerName: "Adit",
        dateTime: now.subtract(const Duration(hours: 2)),
        totalAmount: 110000,
        paymentMethod: "QRIS",
        items: [
          TransactionItem(name: "Almond Crispy Cokelat", qty: 2, price: 55000),
        ],
      ),
      TransactionHistory(
        id: "TRX-85012",
        customerName: "Doni",
        dateTime: now.subtract(const Duration(days: 1)),
        totalAmount: 45500,
        paymentMethod: "QRIS",
        items: [
          TransactionItem(name: "Ayam Bakar 1 Ekor", qty: 1, price: 45500),
        ],
      ),
      TransactionHistory(
        id: "TRX-55391",
        customerName: "Budi",
        dateTime: now.subtract(const Duration(days: 3)),
        totalAmount: 65000,
        paymentMethod: "Cash",
        paidAmount: 100000,
        changeAmount: 35000,
        items: [
          TransactionItem(name: "Caramel Latte Ice", qty: 2, price: 25000),
          TransactionItem(name: "Roti Bakar Cokelat", qty: 1, price: 15000),
        ],
      ),
      TransactionHistory(
        id: "TRX-77402",
        customerName: "Citra",
        dateTime: now.subtract(const Duration(days: 5)),
        totalAmount: 90000,
        paymentMethod: "QRIS",
        items: [
          TransactionItem(name: "Espresso Single", qty: 3, price: 18000),
          TransactionItem(name: "Croissant Almond", qty: 1, price: 36000),
        ],
      ),
      TransactionHistory(
        id: "TRX-33129",
        customerName: "Eko",
        dateTime: now.subtract(const Duration(days: 10)),
        totalAmount: 40000,
        paymentMethod: "Cash",
        paidAmount: 50000,
        changeAmount: 10000,
        items: [
          TransactionItem(name: "Cappuccino Hot", qty: 2, price: 20000),
        ],
      ),
      TransactionHistory(
        id: "TRX-99881",
        customerName: "Fajar",
        dateTime: now.subtract(const Duration(days: 18)),
        totalAmount: 75000,
        paymentMethod: "QRIS",
        items: [
          TransactionItem(name: "Hazelnut Latte Ice", qty: 3, price: 25000),
        ],
      ),
    ]);

    // Dummy Log Stok
    _stockLogs.addAll([
      StockHistory(
        id: "LOG-1",
        ingredientName: "bubuk kopi",
        category: "Bubuk & Kopi",
        adjustedAmount: 5,
        stockBefore: 0,
        stockAfter: 5,
        type: "Baru",
        dateTime: now.subtract(const Duration(minutes: 45)),
      ),
      StockHistory(
        id: "LOG-2",
        ingredientName: "susu kaleng",
        category: "Susu & Creamer",
        adjustedAmount: 2,
        stockBefore: 2,
        stockAfter: 0,
        type: "Kurang",
        dateTime: now.subtract(const Duration(hours: 3)),
      ),
      StockHistory(
        id: "LOG-3",
        ingredientName: "susu uht",
        category: "Susu & Creamer",
        adjustedAmount: 4,
        stockBefore: 2,
        stockAfter: 6,
        type: "Tambah",
        dateTime: now.subtract(const Duration(days: 1)),
      ),
    ]);

    // Dummy Riwayat Absensi
    _attendanceLogs.addAll([
      AttendanceHistory(
        id: "ATT-481",
        employeeName: "Rian",
        role: "Barista",
        startTime: now.subtract(const Duration(days: 1, hours: 8)),
        endTime: now.subtract(const Duration(days: 1)),
        note: "Semua mesin kopi bersih, sisa cup kopi 50 pcs",
      ),
      AttendanceHistory(
        id: "ATT-192",
        employeeName: "Adit",
        role: "Cashier",
        startTime: now.subtract(const Duration(days: 2, hours: 9)),
        endTime: now.subtract(const Duration(days: 2, hours: 1)),
        note: "Pembukuan kasir balance, sisa uang kecil Rp 200.000",
      ),
    ]);

    // Dummy Pengeluaran
    _expenses.addAll([
      ExpenseModel(
        id: "EXP-8201",
        title: "Beli Es Batu Kristal 2 Pack",
        amount: 15000,
        category: "Ingredients",
        notes: "Dibeli di agen es batu dekat kafe",
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
      ExpenseModel(
        id: "EXP-1930",
        title: "Beli Air Galon Aqua 2 Pcs",
        amount: 20000,
        category: "Operational",
        notes: "Untuk kebutuhan dispenser bar",
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      ExpenseModel(
        id: "EXP-8501",
        title: "Beli Cup Plastik 16oz + Lid 100 Pcs",
        amount: 35000,
        category: "Operational",
        notes: "Stok mendesak untuk akhir pekan",
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ExpenseModel(
        id: "EXP-3321",
        title: "Beli Gas Elpiji 3kg",
        amount: 22000,
        category: "Operational",
        notes: "Untuk kompor dapur memasak makanan",
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ExpenseModel(
        id: "EXP-4490",
        title: "Perbaikan Gagang Pintu Belakang",
        amount: 45000,
        category: "Others",
        notes: "Gagang pintu rusak dol",
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      ExpenseModel(
        id: "EXP-5512",
        title: "Beli Susu Kaleng 1 Karton",
        amount: 180000,
        category: "Ingredients",
        notes: "Bahan creamer kopi susu manis",
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      ExpenseModel(
        id: "EXP-6677",
        title: "Beli Sedotan Kertas 5 Pack",
        amount: 25000,
        category: "Operational",
        notes: "Sedotan ramah lingkungan",
        createdAt: now.subtract(const Duration(days: 18)),
      ),
    ]);
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

  Future<void> saveActiveShift(String employeeName, String role, DateTime startTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveShiftName, employeeName);
    await prefs.setString(_keyActiveShiftRole, role);
    await prefs.setString(_keyActiveShiftStart, startTime.toIso8601String());
  }

  Future<Map<String, dynamic>?> getActiveShift() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyActiveShiftName);
    final role = prefs.getString(_keyActiveShiftRole);
    final startStr = prefs.getString(_keyActiveShiftStart);

    if (name == null || role == null || startStr == null) {
      return null;
    }

    return {
      "name": name,
      "role": role,
      "startTime": DateTime.parse(startStr),
    };
  }

  Future<void> clearActiveShift() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveShiftName);
    await prefs.remove(_keyActiveShiftRole);
    await prefs.remove(_keyActiveShiftStart);
  }
}
