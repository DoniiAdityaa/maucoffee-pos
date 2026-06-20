import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maucoffee/data/history_manager.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, bool> _expandedTransactions = {};

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

  // Menghitung statistik dinamis dari HistoryManager
  Map<String, double> _calculateStats() {
    double totalRevenueToday = 0;
    final now = DateTime.now();

    final txList = HistoryManager().transactions;
    for (var tx in txList) {
      // Saring transaksi untuk hari ini saja
      if (tx.dateTime.year == now.year &&
          tx.dateTime.month == now.month &&
          tx.dateTime.day == now.day) {
        totalRevenueToday += tx.totalAmount;
      }
    }

    return {
      "revenue": totalRevenueToday,
      "transactions": txList.length.toDouble(),
      "stockLogs": HistoryManager().stockLogs.length.toDouble(),
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

            // Ringkasan Statistik Dinamis (Glassmorphic Cards)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacing6),
              child: Row(
                children: [
                  _buildStatCard(
                    "Omzet Hari Ini",
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
    final transactions = HistoryManager().transactions;

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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(tx.qrisProofPath!),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildImageErrorPlaceholder();
                              },
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
    final stockLogs = HistoryManager().stockLogs;

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
}
