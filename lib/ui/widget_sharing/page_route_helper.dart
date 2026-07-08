import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppNavigator {
  // Membuat Route yang mendeteksi platform secara otomatis
  static Route<T> _buildRoute<T>(Widget page) {
    if (Platform.isIOS) {
      // iOS menggunakan transisi geser samping asli Apple (swipe-to-back aktif)
      return CupertinoPageRoute<T>(builder: (context) => page);
    } else {
      // Android tetap menggunakan efek memudar kustom yang elegan
      return PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    }
  }

  // Navigasi biasa: push halaman baru
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(context, _buildRoute<T>(page));
  }

  // Navigasi replace: menimpa halaman saat ini
  static Future<T?> pushReplacement<T, TO>(BuildContext context, Widget page) {
    return Navigator.pushReplacement<T, TO>(context, _buildRoute<T>(page));
  }

  // Navigasi pushAndRemoveUntil: mengosongkan stack (biasanya untuk Logout / Go to Home)
  static Future<T?> pushAndRemoveUntil<T>(BuildContext context, Widget page) {
    return Navigator.pushAndRemoveUntil<T>(
      context,
      _buildRoute<T>(page),
      (route) => false,
    );
  }
}
