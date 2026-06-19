import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class TransactionSuccessDialog extends StatefulWidget {
  final String transactionNumber;
  final VoidCallback onFinish;

  const TransactionSuccessDialog({
    super.key,
    required this.transactionNumber,
    required this.onFinish,
  });

  @override
  State<TransactionSuccessDialog> createState() => _TransactionSuccessDialogState();
}

class _TransactionSuccessDialogState extends State<TransactionSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller animasi berdurasi 600ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Animasi membesar membal (elasticOut) untuk efek premium
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    // Mulai animasi
    _controller.forward();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(spacing6),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1A0A).withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: spacing2),

              // Animasi Centang Sukses Membal (Elastic)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D8A4E), // hijau cozy
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: spacing5),

              // Judul Sukses
              Text(
                "Transaksi Sukses!",
                style: mdBold.copyWith(color: Colors.white),
              ),
              const SizedBox(height: spacing2),

              // Nomor Transaksi
              Text(
                "No. Transaksi",
                style: xxsRegular.copyWith(color: Colors.white.withOpacity(0.5)),
              ),
              const SizedBox(height: 2),
              Text(
                widget.transactionNumber,
                style: smBold.copyWith(color: primaryColor, letterSpacing: 0.5),
              ),
              const SizedBox(height: spacing6),

              // Tombol Selesai
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context); // Tutup dialog
                    widget.onFinish();
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
                    "Selesai",
                    style: sBold.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: spacing1),
            ],
          ),
        ),
      ),
    );
  }
}
