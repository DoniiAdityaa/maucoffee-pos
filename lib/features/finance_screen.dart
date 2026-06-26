import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maucoffee/data/history_manager.dart';
import 'package:maucoffee/model/expense_model.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/ui/widget_sharing/custom_snackbar.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/repository/order_repository.dart';
import 'package:maucoffee/repository/expense_repository.dart';
import 'package:maucoffee/model/order_model.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  bool get _isAdmin {
    final userPrefs = serviceLocator<UserPreference>();
    return userPrefs.getLoginRole() == 'admin';
  }

  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

  DateTime _selectedDate = DateTime.now();
  int _activeTabIndex = 0;

  List<OrderModel> _orders = [];
  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _fetchFinanceData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderRepo = serviceLocator<OrderRepository>();
      final expenseRepo = serviceLocator<ExpenseRepository>();

      // Muat data orders & expenses secara paralel dari database Supabase
      final results = await Future.wait([
        orderRepo.getOrderHistory(),
        expenseRepo.getExpenses(),
      ]);

      if (!mounted) return;
      setState(() {
        _orders = results[0] as List<OrderModel>;
        _expenses = results[1] as List<ExpenseModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _activeTabIndex = _tabController.index;
        });
      } else {
        if (_activeTabIndex != _tabController.index) {
          setState(() {
            _activeTabIndex = _tabController.index;
          });
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFinanceData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isWithinDateRange(DateTime date) {
    final target = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final itemDate = DateTime(date.year, date.month, date.day);
    return itemDate.isAtSameMomentAs(target);
  }

  // Menghitung akumulasi statistik keuangan dari database Supabase
  Map<String, double> _calculateFinanceStats() {
    double totalIncome = 0;
    for (var tx in _orders) {
      if (tx.createdAt != null && _isWithinDateRange(tx.createdAt!)) {
        totalIncome += tx.totalAmount;
      }
    }

    double totalExpenses = 0;
    for (var exp in _expenses) {
      if (exp.createdAt != null && _isWithinDateRange(exp.createdAt!)) {
        totalExpenses += exp.amount;
      }
    }

    double netProfit = totalIncome - totalExpenses;

    return {
      "income": totalIncome,
      "expenses": totalExpenses,
      "profit": netProfit,
    };
  }

  String _getFriendlyDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    final dateStr = DateFormat('dd MMM yyyy').format(date);
    if (checkDate.isAtSameMomentAs(today)) {
      return "Hari Ini ($dateStr)";
    } else if (checkDate.isAtSameMomentAs(yesterday)) {
      return "Kemarin ($dateStr)";
    } else {
      final weekdays = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"];
      final dayName = weekdays[date.weekday - 1];
      return "$dayName, $dateStr";
    }
  }

  bool _canGoToNextDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return current.isBefore(today);
  }

  Widget _buildDateSelector() {
    if (!_isAdmin) {
      return Container(
        margin: const EdgeInsets.only(bottom: spacing5),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing6,
          vertical: spacing3,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.today_rounded,
              color: primaryColor,
              size: 16,
            ),
            const SizedBox(width: spacing2 + 2),
            Text(
              "Hari Ini: ${DateFormat('dd MMM yyyy').format(DateTime.now())}",
              style: sBold.copyWith(
                color: Colors.white,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      );
    }

    final canGoNext = _canGoToNextDay();
    return Container(
      margin: const EdgeInsets.only(bottom: spacing5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left arrow (Kemarin / Hari Sebelumnya)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _fetchFinanceData();
            },
            child: Container(
              padding: const EdgeInsets.all(spacing2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: spacing4),

          // Central Date Display
          GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(), // Membatasi tanggal maksimal adalah HARI INI
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: primaryColor,
                        onPrimary: Colors.white,
                        surface: Color(0xFF2A1A0A),
                        onSurface: Colors.white,
                      ),
                      dialogBackgroundColor: const Color(0xFF1C1207),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
                _fetchFinanceData();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: spacing5,
                vertical: spacing3,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: spacing2 + 2),
                  Text(
                    _getFriendlyDateLabel(_selectedDate),
                    style: sBold.copyWith(
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: spacing4),

          // Right arrow (Besok / Hari Setelahnya)
          GestureDetector(
            onTap: canGoNext
                ? () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                    _fetchFinanceData();
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(spacing2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: canGoNext ? 0.08 : 0.02,
                  ),
                ),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: canGoNext ? Colors.white70 : Colors.white10,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Membuka form tambah pengeluaran dalam bottom sheet glassmorphic
  void _showAddExpenseSheet() {
    HapticFeedback.mediumImpact();
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = 'Operational';
    DateTime selectedDate = DateTime.now();

    // Pilihan kategori dalam dropdown
    final List<Map<String, String>> categories = [
      {'value': 'Operational', 'label': 'Operasional'},
      {'value': 'Ingredients', 'label': 'Bahan Baku'},
      {'value': 'Salary', 'label': 'Gaji / Salary'},
      {'value': 'Rent', 'label': 'Sewa & Utilitas'},
      {'value': 'Others', 'label': 'Lain-lain'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: EdgeInsets.only(
                  left: spacing6,
                  right: spacing6,
                  top: spacing6,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + spacing6,
                ),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  color: const Color(0xFF2A1A0A).withValues(alpha: 0.95),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.2,
                    ),
                  ),
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Handlebar atas sheet
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: spacing5),

                        Text(
                          "Catat Pengeluaran Baru",
                          style: lgBold.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: spacing4),

                        // Input Judul Pengeluaran (Hanya jika BUKAN Gaji / Salary / Salary)
                        if (selectedCategory != 'Salary') ...[
                          Text(
                            "Judul Pengeluaran",
                            style: xsBold.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: spacing3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: TextFormField(
                              controller: titleController,
                              style: sMedium.copyWith(color: Colors.white),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Contoh: Beli es batu, air galon",
                                hintStyle: sMedium.copyWith(
                                  color: Colors.white24,
                                ),
                              ),
                              validator: (value) {
                                if (selectedCategory != 'Salary' &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'Judul pengeluaran tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: spacing4),
                        ],

                        // Input Nominal Pengeluaran
                        Text(
                          "Nominal (Rp)",
                          style: xsBold.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: spacing3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: TextFormField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: sMedium.copyWith(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Contoh: 15000",
                              hintStyle: sMedium.copyWith(
                                color: Colors.white24,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nominal pengeluaran tidak boleh kosong';
                              }
                              final parsed = double.tryParse(value);
                              if (parsed == null || parsed <= 0) {
                                return 'Masukkan nominal yang valid (> 0)';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: spacing4),

                        // Dropdown Kategori
                        Text(
                          "Kategori",
                          style: xsBold.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: spacing3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            dropdownColor: const Color(0xFF2A1A0A),
                            icon: const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: Colors.white54,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            style: sMedium.copyWith(color: Colors.white),
                            items: categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat['value'],
                                child: Text(
                                  cat['label']!,
                                  style: sMedium.copyWith(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() {
                                  selectedCategory = val;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: spacing4),

                        // Tanggal Pengeluaran Field
                        Text(
                          "Tanggal Pengeluaran",
                          style: xsBold.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: primaryColor,
                                      onPrimary: Colors.white,
                                      surface: Color(0xFF2A1A0A),
                                      onSurface: Colors.white,
                                    ),
                                    dialogBackgroundColor: const Color(0xFF1C1207),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setSheetState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: spacing3,
                              vertical: spacing4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd MMMM yyyy').format(selectedDate),
                                  style: sMedium.copyWith(color: Colors.white),
                                ),
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Colors.white30,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: spacing4),

                        // Catatan Tambahan (Opsional)
                        Text(
                          "Catatan Tambahan (Opsional)",
                          style: xsBold.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: spacing3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: TextFormField(
                            controller: notesController,
                            maxLines: 2,
                            style: sMedium.copyWith(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: selectedCategory == 'Salary'
                                  ? "Contoh: Gaji Barista Rian - Shift Sore"
                                  : "Contoh: Beli es kristal 2 pack",
                              hintStyle: sMedium.copyWith(
                                color: Colors.white24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: spacing6),

                        // Button Action
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(ctx);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white30),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: spacing4,
                                  ),
                                ),
                                child: Text(
                                  "Batal",
                                  style: sBold.copyWith(color: Colors.white70),
                                ),
                              ),
                            ),
                            const SizedBox(width: spacing4),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    final title = selectedCategory == 'Salary'
                                        ? 'Gaji / Salary'
                                        : titleController.text.trim();
                                    final amount = double.parse(
                                      amountController.text.trim(),
                                    );
                                    final notes = notesController.text.trim();

                                    final newExp = ExpenseModel(
                                      id: "EXP-${1000 + (DateTime.now().millisecond * 3) % 9000}",
                                      title: title,
                                      amount: amount,
                                      category: selectedCategory,
                                      notes: notes.isNotEmpty ? notes : null,
                                      createdAt: selectedDate,
                                    );

                                    HistoryManager().addExpense(newExp);

                                    Navigator.pop(ctx);
                                    CustomFeedback.showSuccess(
                                      context,
                                      "Pengeluaran '$title' berhasil dicatat!",
                                    );
                                    setState(() {});
                                  } else {
                                    HapticFeedback.heavyImpact();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: spacing4,
                                  ),
                                ),
                                child: Text(
                                  "Simpan",
                                  style: sBold.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: spacing4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Membuka form tambah pemasukan manual dalam bottom sheet glassmorphic
  void _showAddIncomeSheet() {
    HapticFeedback.mediumImpact();
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedPaymentMethod = 'Cash';
    DateTime selectedDate = DateTime.now();

    final List<String> paymentMethods = ['Cash', 'QRIS'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: EdgeInsets.only(
                  left: spacing6,
                  right: spacing6,
                  top: spacing6,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + spacing6,
                ),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  color: const Color(0xFF2A1A0A).withValues(alpha: 0.95),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.2,
                    ),
                  ),
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: spacing5),

                        Text(
                          "Catat Pemasukan Manual",
                          style: lgBold.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: spacing4),

                        // Title Field
                        Text(
                          "Judul Pemasukan",
                          style: xsBold.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: spacing3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: TextFormField(
                            controller: titleController,
                            style: sMedium.copyWith(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Contoh: Penjualan Kopi Bubuk, Event offline",
                              hintStyle: sMedium.copyWith(color: Colors.white24),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Judul pemasukan tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: spacing4),

                        // Amount Field
                        Text(
                          "Nominal (Rp)",
                          style: xsBold.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: spacing3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: TextFormField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: sMedium.copyWith(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Contoh: 50000",
                              hintStyle: sMedium.copyWith(color: Colors.white24),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nominal pemasukan tidak boleh kosong';
                              }
                              final parsed = double.tryParse(value);
                              if (parsed == null || parsed <= 0) {
                                return 'Masukkan nominal yang valid (> 0)';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: spacing4),

                        // Payment Method Field (Segmented look)
                        Text(
                          "Metode Pembayaran",
                          style: xsBold.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withValues(alpha: 0.03),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: paymentMethods.map((method) {
                              final isSelected = selectedPaymentMethod == method;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setSheetState(() {
                                      selectedPaymentMethod = method;
                                    });
                                  },
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(9),
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.transparent,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      method,
                                      style: sBold.copyWith(
                                        color: isSelected ? Colors.white : Colors.white38,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: spacing4),

                        // Date Field
                        Text(
                          "Tanggal Pemasukan",
                          style: xsBold.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: primaryColor,
                                      onPrimary: Colors.white,
                                      surface: Color(0xFF2A1A0A),
                                      onSurface: Colors.white,
                                    ),
                                    dialogBackgroundColor: const Color(0xFF1C1207),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setSheetState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: spacing3,
                              vertical: spacing4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd MMMM yyyy').format(selectedDate),
                                  style: sMedium.copyWith(color: Colors.white),
                                ),
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Colors.white30,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: spacing4),

                        // Notes Field
                        Text(
                          "Catatan Tambahan (Opsional)",
                          style: xsBold.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: spacing3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: TextFormField(
                            controller: notesController,
                            maxLines: 2,
                            style: sMedium.copyWith(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Contoh: Hasil penjualan sisa event bazaar kemerdekaan",
                              hintStyle: sMedium.copyWith(color: Colors.white24),
                            ),
                          ),
                        ),
                        const SizedBox(height: spacing6),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(ctx);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white30),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: spacing4),
                                ),
                                child: Text(
                                  "Batal",
                                  style: sBold.copyWith(color: Colors.white70),
                                ),
                              ),
                            ),
                            const SizedBox(width: spacing4),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    final title = titleController.text.trim();
                                    final amount = double.parse(amountController.text.trim());
                                    final notes = notesController.text.trim();

                                    final newTx = TransactionHistory(
                                      id: "TRX-MAN-${10000 + (DateTime.now().millisecond * 7) % 90000}",
                                      customerName: "Manual (Owner)",
                                      dateTime: selectedDate,
                                      totalAmount: amount,
                                      paymentMethod: selectedPaymentMethod,
                                      paidAmount: amount,
                                      changeAmount: 0,
                                      items: [
                                        TransactionItem(
                                          name: title + (notes.isNotEmpty ? " ($notes)" : ""),
                                          qty: 1,
                                          price: amount,
                                        ),
                                      ],
                                    );

                                    HistoryManager().addTransaction(newTx);

                                    Navigator.pop(ctx);
                                    CustomFeedback.showSuccess(
                                      context,
                                      "Pemasukan '$title' berhasil dicatat!",
                                    );
                                    setState(() {});
                                  } else {
                                    HapticFeedback.heavyImpact();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: spacing4),
                                ),
                                child: Text(
                                  "Simpan",
                                  style: sBold.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: spacing4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateFinanceStats();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Utama
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: spacing6,
                vertical: spacing3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Laporan Keuangan",
                    style: lgBold.copyWith(color: Colors.white),
                  ),
                  // Button Tambah Dinamis
                  GestureDetector(
                    onTap: _activeTabIndex == 0
                        ? _showAddExpenseSheet
                        : _showAddIncomeSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            color: primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _activeTabIndex == 0 ? "Pengeluaran" : "Pemasukan",
                            style: xxsBold.copyWith(color: primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Date Filter Horizontal Bar
            _buildDateSelector(),

            // Summary Card (Glassmorphic)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacing6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(spacing5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Keuntungan Bersih",
                          style: xxsBold.copyWith(color: Colors.white38),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currencyFormatter.format(stats["profit"]),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'poppins',
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: spacing4),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: spacing4),
                        Row(
                          children: [
                            // Pemasukan
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_downward_rounded,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Pemasukan",
                                          style: xxxsMedium.copyWith(
                                            color: Colors.white38,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            currencyFormatter.format(
                                              stats["income"],
                                            ),
                                            style: xsBold.copyWith(
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 32,
                              width: 1,
                              color: Colors.white10,
                            ),
                            const SizedBox(width: 12),
                            // Pengeluaran
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_upward_rounded,
                                      color: Colors.redAccent,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Pengeluaran",
                                          style: xxxsMedium.copyWith(
                                            color: Colors.white38,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            currencyFormatter.format(
                                              stats["expenses"],
                                            ),
                                            style: xsBold.copyWith(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: spacing4),

            // Tab Bar Switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacing6),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryColor, width: 1),
                  ),
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: sBold,
                  unselectedLabelStyle: sMedium,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: "Log Pengeluaran"),
                    Tab(text: "Log Pemasukan"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: spacing4),

            // Tab View Area dengan RefreshIndicator untuk Pull-to-refresh
            Expanded(
              child: RefreshIndicator(
                color: primaryColor,
                onRefresh: _fetchFinanceData,
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildExpensesTab(), _buildIncomeTab()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 1: DAFTAR LOG PENGELUARAN ──
  Widget _buildExpensesTab() {
    final expensesList = _expenses.where((exp) {
      return exp.createdAt != null && _isWithinDateRange(exp.createdAt!);
    }).toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(spacing6),
          child: Text(
            "Gagal memuat: $_errorMessage",
            style: sMedium.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (expensesList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_rounded,
        text: "Belum ada catatan pengeluaran.",
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: spacing6,
        right: spacing6,
        bottom: 100,
      ),
      itemCount: expensesList.length,
      itemBuilder: (context, index) {
        final exp = expensesList[index];

        Color categoryColor;
        String categoryLabel;

        switch (exp.category) {
          case 'Operational':
            categoryColor = Colors.blueAccent;
            categoryLabel = 'Operasional';
            break;
          case 'Ingredients':
            categoryColor = const Color(0xFFFF9E22);
            categoryLabel = 'Bahan Baku';
            break;
          case 'Salary':
            categoryColor = Colors.teal;
            categoryLabel = 'Gaji / Salary';
            break;
          case 'Rent':
            categoryColor = Colors.purpleAccent;
            categoryLabel = 'Sewa & Utilitas';
            break;
          default:
            categoryColor = Colors.grey;
            categoryLabel = 'Lain-lain';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: spacing3),
          padding: const EdgeInsets.all(spacing4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.title,
                          style: sBold.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: categoryColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                categoryLabel,
                                style: xxxsBold.copyWith(color: categoryColor),
                              ),
                            ),
                            if (exp.createdAt != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                dateFormatter.format(exp.createdAt!),
                                style: xxsRegular.copyWith(color: Colors.white30),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "- ${currencyFormatter.format(exp.amount)}",
                    style: sBold.copyWith(color: Colors.redAccent),
                  ),
                ],
              ),
              if (exp.notes != null && exp.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.description_rounded,
                      color: Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exp.notes!,
                        style: xxsRegular.copyWith(color: Colors.white60),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── TAB 2: DAFTAR LOG PEMASUKAN PENJUALAN ──
  Widget _buildIncomeTab() {
    final transactions = _orders.where((tx) {
      return tx.createdAt != null && _isWithinDateRange(tx.createdAt!);
    }).toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(spacing6),
          child: Text(
            "Gagal memuat: $_errorMessage",
            style: sMedium.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (transactions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.monetization_on_rounded,
        text: "Belum ada riwayat pemasukan penjualan.",
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: spacing6,
        right: spacing6,
        bottom: 100,
      ),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];

        return Container(
          margin: const EdgeInsets.only(bottom: spacing3),
          padding: const EdgeInsets.all(spacing4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.invoiceNumber, style: sBold.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tx.paymentMethod == "QRIS"
                                ? Colors.blueAccent.withValues(alpha: 0.12)
                                : Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: tx.paymentMethod == "QRIS"
                                  ? Colors.blueAccent.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            tx.paymentMethod,
                            style: xxxsBold.copyWith(
                              color: tx.paymentMethod == "QRIS"
                                  ? Colors.blueAccent
                                  : Colors.green,
                            ),
                          ),
                        ),
                        if (tx.createdAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            dateFormatter.format(tx.createdAt!),
                            style: xxsRegular.copyWith(color: Colors.white30),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Invoice: ${tx.invoiceNumber}",
                      style: xxsMedium.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Text(
                "+ ${currencyFormatter.format(tx.totalAmount)}",
                style: sBold.copyWith(color: Colors.green),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String text}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white12, size: 48),
          const SizedBox(height: spacing2),
          Text(
            text,
            style: sMedium.copyWith(color: Colors.white30),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
