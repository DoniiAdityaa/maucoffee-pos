import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/typography.dart';
import 'package:maucoffee/ui/dimension.dart';

class QrisPaymentBottomSheet extends StatefulWidget {
  final double totalPrice;
  final Function(String? imagePath) onConfirm;

  const QrisPaymentBottomSheet({
    super.key,
    required this.totalPrice,
    required this.onConfirm,
  });

  @override
  State<QrisPaymentBottomSheet> createState() => _QrisPaymentBottomSheetState();
}

class _QrisPaymentBottomSheetState extends State<QrisPaymentBottomSheet> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.lightImpact();
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Kompres kualitas gambar
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A1A0A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: primaryColor),
              title: Text("Ambil Foto dari Kamera", style: sMedium.copyWith(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: primaryColor),
              title: Text("Pilih Foto dari Galeri", style: sMedium.copyWith(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    "Pembayaran QRIS",
                    style: mdBold.copyWith(color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white60,
                    ),
                    onPressed: () => Navigator.pop(context),
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
              const SizedBox(height: spacing6),

              // Bukti Pembayaran Title
              Text(
                "Upload Bukti Pembayaran (Opsional)",
                style: xsBold.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: spacing3),

              // Area Upload Gambar
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: _imageFile == null
                    ? CustomPaint(
                        painter: DashedRectPainter(
                          color: Colors.white.withOpacity(0.2),
                          strokeWidth: 1.5,
                          gap: 4.0,
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 140,
                          color: Colors.white.withOpacity(0.02),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_rounded,
                                color: Colors.white.withOpacity(0.4),
                                size: 36,
                              ),
                              const SizedBox(height: spacing2),
                              Text(
                                "Tambah Foto Bukti TF",
                                style: sBold.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Ketuk untuk mengambil foto / galeri",
                                style: xxsRegular.copyWith(color: Colors.white30),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1.2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.file(
                                _imageFile!,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                width: double.infinity,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.6),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel_rounded,
                                  color: Colors.redAccent,
                                  size: 24,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _imageFile = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: spacing6),

              // Button Selesaikan Pembayaran
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context); // Close QRIS bottom sheet
                  widget.onConfirm(_imageFile?.path);
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

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    path.addRRect(rrect);

    final Path dashPath = Path();
    
    for (PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + 6.0),
          Offset.zero,
        );
        distance += 6.0 + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}
