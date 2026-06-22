import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
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
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Future<File> _cropTo43(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) return imageFile;

    final int width = originalImage.width;
    final int height = originalImage.height;

    int cropWidth = width;
    int cropHeight = height;

    // Aspek rasio target adalah 4:3 (width / height = 4 / 3)
    if (width > height) {
      cropWidth = (height * 4) ~/ 3;
      if (cropWidth > width) {
        cropWidth = width;
        cropHeight = (width * 3) ~/ 4;
      }
    } else {
      // Portrait target 3:4
      cropHeight = (width * 4) ~/ 3;
      if (cropHeight > height) {
        cropHeight = height;
        cropWidth = (height * 3) ~/ 4;
      }
    }

    final int x = (width - cropWidth) ~/ 2;
    final int y = (height - cropHeight) ~/ 2;

    final img.Image croppedImage = img.copyCrop(
      originalImage,
      x: x,
      y: y,
      width: cropWidth,
      height: cropHeight,
    );

    final croppedBytes = img.encodeJpg(croppedImage, quality: 85);
    final directory = await getApplicationDocumentsDirectory();
    final String newPath =
        '${directory.path}/qris_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File newFile = File(newPath);
    await newFile.writeAsBytes(croppedBytes);

    try {
      await imageFile.delete();
    } catch (_) {}

    return newFile;
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.lightImpact();
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (pickedFile != null) {
        setState(() {
          _isProcessing = true;
        });

        final File croppedFile = await _cropTo43(File(pickedFile.path));

        setState(() {
          _imageFile = croppedFile;
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      debugPrint("Error picking/cropping image: $e");
    }
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

              // Area Upload Gambar (Aspect Ratio 4:3)
              AspectRatio(
                aspectRatio: 4 / 3,
                child: GestureDetector(
                  onTap: _isProcessing
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  child: _isProcessing
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1.2,
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          ),
                        )
                      : _imageFile == null
                          ? CustomPaint(
                              painter: DashedRectPainter(
                                color: Colors.white.withOpacity(0.2),
                                strokeWidth: 1.5,
                                gap: 4.0,
                              ),
                              child: Container(
                                width: double.infinity,
                                color: Colors.white.withOpacity(0.02),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_rounded,
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
                                      "Ketuk untuk membuka kamera",
                                      style: xxsRegular.copyWith(
                                        color: Colors.white30,
                                      ),
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
                                      height: double.infinity,
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
