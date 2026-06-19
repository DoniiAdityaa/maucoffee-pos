import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class CashPaymentBottomSheet extends StatefulWidget {
  final double totalPrice;
  final Function(double paidAmount, double change) onConfirm;

  const CashPaymentBottomSheet({
    super.key,
    required this.totalPrice,
    required this.onConfirm,
  });

  @override
  State<CashPaymentBottomSheet> createState() => _CashPaymentBottomSheetState();
}

class _CashPaymentBottomSheetState extends State<CashPaymentBottomSheet> {
  late TextEditingController _controller;
  double _paidAmount = 0;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _paidAmount = widget.totalPrice;
    _controller = TextEditingController(text: _formatNumber(widget.totalPrice));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(double amount) {
    final formatter = NumberFormat.decimalPattern('id');
    return formatter.format(amount);
  }

  void _updateAmount(double amount) {
    HapticFeedback.lightImpact();
    setState(() {
      _paidAmount = amount;
      _controller.text = _formatNumber(amount);
    });
  }

  List<double> _getSuggestions() {
    final double T = widget.totalPrice;
    final List<double> suggestions = [];

    // 1. Selalu sertakan uang pas
    suggestions.add(T);

    // Pecahan uang standar Rupiah
    final List<double> standardNotes = [
      2000,
      5000,
      10000,
      20000,
      50000,
      100000,
    ];

    // 2. Tambahkan pecahan standar yang lebih besar dari T
    for (var note in standardNotes) {
      if (note > T) {
        suggestions.add(note);
      }
    }

    // 3. Tambahkan kelipatan bulat terdekat ke atas secara cerdas
    if (T > 0) {
      // Kelipatan 5.000 terdekat ke atas (jika T > 5000)
      if (T > 5000) {
        double next5k = ((T / 5000).ceil() * 5000).toDouble();
        if (next5k > T) suggestions.add(next5k);
      }

      // Kelipatan 10.000 terdekat ke atas
      double next10k = ((T / 10000).ceil() * 10000).toDouble();
      if (next10k > T) suggestions.add(next10k);

      // Kelipatan 20.000 terdekat ke atas
      double next20k = ((T / 20000).ceil() * 20000).toDouble();
      if (next20k > T) suggestions.add(next20k);

      // Kelipatan 50.000 terdekat ke atas (jika T > 20000)
      if (T > 20000) {
        double next50k = ((T / 50000).ceil() * 50000).toDouble();
        if (next50k > T) suggestions.add(next50k);
      }

      // Kelipatan 100.000 terdekat ke atas (jika T > 50000)
      if (T > 50000) {
        double next100k = ((T / 100000).ceil() * 100000).toDouble();
        if (next100k > T) suggestions.add(next100k);
      }
    }

    // Hapus duplikat, filter hanya nilai >= T, dan urutkan
    final List<double> sorted = suggestions
        .toSet()
        .where((val) => val >= T)
        .toList();
    sorted.sort();

    // Batasi maksimal 5 saran nominal agar UI tetap rapi
    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _getSuggestions();
    final double change = _paidAmount - widget.totalPrice;
    final bool isInsufficient = _paidAmount < widget.totalPrice;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: spacing6,
            right: spacing6,
            top: spacing6,
            bottom: MediaQuery.of(context).viewInsets.bottom + spacing7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1A0A).withOpacity(0.95),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pembayaran Tunai",
                    style: mdBold.copyWith(color: Colors.white),
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: spacing2),

              // Total Tagihan Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Tagihan",
                    style: smMedium.copyWith(color: Colors.white70),
                  ),
                  Text(
                    currencyFormatter.format(widget.totalPrice),
                    style: mdBold.copyWith(color: primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: spacing5),

              // Pecahan cepat
              Text(
                "Uang Diterima (Pilihan Cepat)",
                style: xsBold.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: spacing2),
              Wrap(
                spacing: spacing2,
                runSpacing: spacing2,
                children: suggestions.map((amount) {
                  final bool isSelected = _paidAmount == amount;
                  final bool isExact = amount == widget.totalPrice;
                  final String label = isExact
                      ? "Uang Pas"
                      : currencyFormatter.format(amount);

                  return ChoiceChip(
                    label: Text(
                      label,
                      style: xxsBold.copyWith(
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: const Color(0xFF2A1A0A).withOpacity(0.50),
                    onSelected: (_) => _updateAmount(amount),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? primaryColor
                            : Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: spacing4),

              // Input nominal manual
              Text(
                "Jumlah Tunai Input Manual",
                style: xsBold.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: spacing2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: spacing3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.04),
                  border: Border.all(
                    color: isInsufficient
                        ? Colors.redAccent.withOpacity(0.5)
                        : Colors.white.withOpacity(0.08),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Text("Rp", style: smBold.copyWith(color: Colors.white60)),
                    const SizedBox(width: spacing2),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        style: smBold.copyWith(color: Colors.white),
                        onChanged: (val) {
                          final cleanVal = val.replaceAll('.', '');
                          final amount = double.tryParse(cleanVal) ?? 0;
                          setState(() {
                            _paidAmount = amount;
                          });
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Masukkan nominal tunai",
                          hintStyle: TextStyle(color: Colors.white30),
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: spacing4),

              // Info kembalian / uang kurang
              if (!isInsufficient)
                Container(
                  padding: const EdgeInsets.all(spacing3),
                  decoration: BoxDecoration(
                    color: change == 0
                        ? primaryColor.withOpacity(0.1)
                        : const Color(0xFF2D8A4E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: change == 0
                          ? primaryColor.withOpacity(0.3)
                          : const Color(0xFF2D8A4E).withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        change == 0
                            ? Icons.check_circle_rounded
                            : Icons.monetization_on_rounded,
                        color: change == 0
                            ? primaryColor
                            : const Color(0xFF2D8A4E),
                        size: 20,
                      ),
                      const SizedBox(width: spacing3),
                      Text(
                        change == 0
                            ? "Uang Pas (Tidak ada kembalian)"
                            : "Kembalian: ${currencyFormatter.format(change)}",
                        style: sBold.copyWith(
                          color: change == 0
                              ? primaryColor
                              : const Color(0xFF2D8A4E),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(spacing3),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: spacing3),
                      Text(
                        "Uang pembayaran kurang Rp ${currencyFormatter.format(widget.totalPrice - _paidAmount).replaceAll("Rp ", "")}",
                        style: sBold.copyWith(color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: spacing6),

              // Button Selesaikan Pembayaran
              ElevatedButton(
                onPressed: isInsufficient
                    ? null
                    : () {
                        Navigator.pop(context); // Close second bottom sheet
                        widget.onConfirm(_paidAmount, change);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: spacing4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "Selesaikan Pembayaran",
                  style: sBold.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hapus semua karakter non-digit
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanText.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    double? value = double.tryParse(cleanText);
    if (value == null) {
      return oldValue;
    }

    final formatter = NumberFormat.decimalPattern('id');
    String formatted = formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
