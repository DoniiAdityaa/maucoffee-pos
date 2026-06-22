import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maucoffee/data/history_manager.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, bool> _expandedTransactions = {};
  DateTime _selectedDate = DateTime.now();

  bool get _isAdmin {
    final userPrefs = serviceLocator<UserPreference>();
    return userPrefs.getLoginRole() == 'admin';
  }

  bool _canGoToNextDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return current.isBefore(today);
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

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildDateSelector() {
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

  // Menghitung statistik dinamis dari HistoryManager
  Map<String, double> _calculateStats() {
    double totalRevenueToday = 0;
    final targetDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    int txCount = 0;
    for (var tx in HistoryManager().transactions) {
      final txDate = DateTime(tx.dateTime.year, tx.dateTime.month, tx.dateTime.day);
      if (txDate.isAtSameMomentAs(targetDate)) {
        totalRevenueToday += tx.totalAmount;
        txCount++;
      }
    }
    
    int logCount = 0;
    for (var log in HistoryManager().stockLogs) {
      final logDate = DateTime(log.dateTime.year, log.dateTime.month, log.dateTime.day);
      if (logDate.isAtSameMomentAs(targetDate)) {
        logCount++;
      }
    }

    return {
      "revenue": totalRevenueToday,
      "transactions": txCount.toDouble(),
      "stockLogs": logCount.toDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header utama
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: spacing6,
                vertical: spacing3,
              ),
              child: Text(
                "Histori Aktivitas",
                style: lgBold.copyWith(color: Colors.white),
              ),
            ),

            if (_isAdmin) _buildDateSelector(),

            // Ringkasan Statistik Dinamis (Glassmorphic Cards)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacing6),
              child: Row(
                children: [
                  _buildStatCard(
                    _isAdmin ? "Omzet Harian" : "Omzet Hari Ini",
                    currencyFormatter.format(stats["revenue"]),
                    primaryColor,
                    Icons.monetization_on_rounded,
                  ),
                  const SizedBox(width: spacing3),
                  _buildStatCard(
                    "Penjualan",
                    "${stats["transactions"]!.toInt()} Trx",
                    Colors.blueAccent,
                    Icons.shopping_bag_rounded,
                  ),
                  const SizedBox(width: spacing3),
                  _buildStatCard(
                    "Log Stok",
                    "${stats["stockLogs"]!.toInt()} Log",
                    const Color(0xFFFF9E22),
                    Icons.history_toggle_off_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: spacing4),

            // Tab Bar Switcher (Glassmorphic)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacing6),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
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
                    Tab(text: "Riwayat Penjualan"),
                    Tab(text: "Log Stok Bahan"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: spacing4),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionTab(),
                  _buildStockLogTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color accentColor, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(spacing3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: xxsBold.copyWith(color: Colors.white38),
                ),
                Icon(icon, color: accentColor.withOpacity(0.5), size: 14),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: smBold.copyWith(color: accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 1: RIWAYAT TRANSAKSI PENJUALAN ──
  Widget _buildTransactionTab() {
    final targetDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final transactions = HistoryManager().transactions.where((tx) {
      final txDate = DateTime(tx.dateTime.year, tx.dateTime.month, tx.dateTime.day);
      return txDate.isAtSameMomentAs(targetDate);
    }).toList();

    if (transactions.isEmpty) {
      return _buildEmptyState("Belum ada riwayat transaksi penjualan.");
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: spacing6, right: spacing6, bottom: 100),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isExpanded = _expandedTransactions[tx.id] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: spacing3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpanded ? primaryColor.withOpacity(0.3) : Colors.white.withOpacity(0.06),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Kartu (Dapat di-tap untuk Expand)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _expandedTransactions[tx.id] = !isExpanded;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(spacing4),
                  child: Row(
                    children: [
                      // Kolom kiri: Info Transaksi
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  tx.id,
                                  style: sBold.copyWith(color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tx.paymentMethod == "QRIS"
                                        ? Colors.blueAccent.withOpacity(0.12)
                                        : Colors.green.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: tx.paymentMethod == "QRIS"
                                          ? Colors.blueAccent.withOpacity(0.2)
                                          : Colors.green.withOpacity(0.2),
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
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Pembeli: ${tx.customerName}",
                              style: xsMedium.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormatter.format(tx.dateTime),
                              style: xxsRegular.copyWith(color: Colors.white38),
                            ),
                          ],
                        ),
                      ),
                      // Kolom kanan: Harga + Arrow
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormatter.format(tx.totalAmount),
                            style: sBold.copyWith(color: primaryColor),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: Colors.white30,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Detail Item (Jika Di-expand)
              if (isExpanded) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing4),
                  child: Divider(color: Colors.white10, height: 1),
                ),
                Padding(
                  padding: const EdgeInsets.all(spacing4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // List Item Belanjaan
                      ...tx.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: spacing2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "${item.name} (x${item.qty})",
                                    style: xsMedium.copyWith(color: Colors.white70),
                                  ),
                                ),
                                Text(
                                  currencyFormatter.format(item.price * item.qty),
                                  style: xsBold.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: spacing2),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: spacing2),

                      // Rincian Pembayaran
                      if (tx.paymentMethod == "Cash") ...[
                        _buildDetailRow("Jumlah Bayar", currencyFormatter.format(tx.paidAmount)),
                        const SizedBox(height: 4),
                        _buildDetailRow("Kembalian", currencyFormatter.format(tx.changeAmount)),
                      ],

                      // Bukti Transfer QRIS
                      if (tx.paymentMethod == "QRIS") ...[
                        const SizedBox(height: spacing2),
                        Text(
                          "Bukti Transfer:",
                          style: xxsBold.copyWith(color: Colors.white54),
                        ),
                        const SizedBox(height: spacing2),
                        if (tx.qrisProofPath != null && tx.qrisProofPath!.isNotEmpty)
                          GestureDetector(
                            onTap: () => _showFullImageDialog(context, tx.qrisProofPath!),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Image.file(
                                      File(tx.qrisProofPath!),
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildImageErrorPlaceholder();
                                      },
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.fullscreen_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "Perbesar",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          _buildImageErrorPlaceholder(text: "Bukti transfer tidak dilampirkan"),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: xxsMedium.copyWith(color: Colors.white54),
        ),
        Text(
          value,
          style: xxsBold.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildImageErrorPlaceholder({String text = "Gagal memuat gambar bukti transfer"}) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported_rounded, color: Colors.white24, size: 28),
          const SizedBox(height: 6),
          Text(
            text,
            style: xxsMedium.copyWith(color: Colors.white30),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: RIWAYAT LOG STOK BAHAN BAKU ──
  Widget _buildStockLogTab() {
    final targetDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final stockLogs = HistoryManager().stockLogs.where((log) {
      final logDate = DateTime(log.dateTime.year, log.dateTime.month, log.dateTime.day);
      return logDate.isAtSameMomentAs(targetDate);
    }).toList();

    if (stockLogs.isEmpty) {
      return _buildEmptyState("Belum ada log penyesuaian stok bahan.");
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: spacing6, right: spacing6, bottom: 100),
      itemCount: stockLogs.length,
      itemBuilder: (context, index) {
        final log = stockLogs[index];

        Color statusColor;
        IconData logIcon;
        String actionText;

        if (log.type == "Tambah") {
          statusColor = const Color(0xFF2D8A4E);
          logIcon = Icons.add_circle_outline_rounded;
          actionText = "Tambah Stok";
        } else if (log.type == "Kurang") {
          statusColor = Colors.redAccent;
          logIcon = Icons.remove_circle_outline_rounded;
          actionText = "Kurang Stok";
        } else {
          statusColor = Colors.blueAccent;
          logIcon = Icons.new_releases_outlined;
          actionText = "Bahan Baku Baru";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: spacing3),
          padding: const EdgeInsets.all(spacing4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              // Icon log
              Container(
                padding: const EdgeInsets.all(spacing2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(logIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: spacing4),

              // Info log
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.ingredientName.substring(0, 1).toUpperCase() + log.ingredientName.substring(1),
                      style: sBold.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.category,
                            style: xxxsMedium.copyWith(color: Colors.white60),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormatter.format(log.dateTime),
                          style: xxsRegular.copyWith(color: Colors.white30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Sebelum: ${log.stockBefore.toStringAsFixed(0)} pcs | Sesudah: ${log.stockAfter.toStringAsFixed(0)} pcs",
                      style: xxsMedium.copyWith(color: Colors.white38),
                    ),
                  ],
                ),
              ),

              // Badge nilai perubahan
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    log.type == "Tambah"
                        ? "+${log.adjustedAmount.toStringAsFixed(0)} pcs"
                        : log.type == "Kurang"
                            ? "-${log.adjustedAmount.toStringAsFixed(0)} pcs"
                            : "${log.adjustedAmount.toStringAsFixed(0)} pcs",
                    style: sBold.copyWith(color: statusColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    actionText,
                    style: xxxsBold.copyWith(color: statusColor),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history_rounded,
            color: Colors.white12,
            size: 48,
          ),
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

  void _showFullImageDialog(BuildContext context, String imagePath) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: spacing4,
          vertical: spacing6,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Backdrop Blur Effect
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.transparent),
              ),
            ),
            // Gambar interaktif dengan pinch-to-zoom
            GestureDetector(
              onTap: () {}, // Mencegah click pada gambar menutup dialog
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Tombol Tutup di pojok kanan atas
            Positioned(
              top: spacing2,
              right: spacing2,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
