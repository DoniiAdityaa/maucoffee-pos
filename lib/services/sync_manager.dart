import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/repository/absensi_repository.dart';
import 'package:maucoffee/repository/order_repository.dart';
import 'package:maucoffee/model/order_model.dart';
import 'package:maucoffee/model/order_item_model.dart';
import 'offline_storage_service.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;

  SyncManager._internal();

  final _offlineStorage = serviceLocator<OfflineStorageService>();
  final _absensiRepository = serviceLocator<AbsensiRepository>();

  bool _isSyncing = false;

  // Broadcast controller to notify listeners when sync finishes
  final StreamController<void> _syncCompletedController = StreamController<void>.broadcast();
  Stream<void> get onSyncCompleted => _syncCompletedController.stream;

  // Inisialisasi pendengar perubahan internet
  void initialize() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        debugPrint("📶 Internet terhubung! Memicu sinkronisasi data...");
        syncAllData();
      }
    });
  }

  // Melakukan sinkronisasi untuk semua antrean data offline
  Future<void> syncAllData() async {
    if (_isSyncing) return;

    // Cek koneksi internet saat ini
    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (!isOnline) return;

    _isSyncing = true;

    try {
      await _syncAttendance();
      await _syncOrders();
      await _syncStock();
    } catch (e) {
      debugPrint("❌ Gagal melakukan sinkronisasi data: $e");
    } finally {
      _isSyncing = false;
    }
  }

  // 1. Sinkronisasi Data Absensi (Mulai & Selesai Shift)
  Future<void> _syncAttendance() async {
    final startQueue = await _offlineStorage.getAttendanceStartQueue();
    final endQueue = await _offlineStorage.getAttendanceEndQueue();

    if (startQueue.isEmpty && endQueue.isEmpty) return;

    debugPrint("⏳ Mensinkronkan data absensi offline...");

    // a. Sinkronkan Clock In
    for (var startData in startQueue) {
      final localId = startData['id'] as String;
      final employeeId = startData['employee_id'] as String;
      final clockInTime = DateTime.parse(startData['clock_in'] as String);

      try {
        // Kirim clock-in ke Supabase
        final realShiftId = await _absensiRepository.startShift(
          employeeId: employeeId,
          clockIn: clockInTime,
        );

        // Hapus dari antrean start di HP
        await _offlineStorage.removeAttendanceStartQueue(localId);

        // Cek apakah ada antrean clock-out terkait start ini
        final endDataIndex = endQueue.indexWhere((e) => e['id'] == localId);
        if (endDataIndex != -1) {
          final endData = endQueue[endDataIndex];
          final note = endData['note'] as String?;
          final clockOutTime = DateTime.parse(endData['clock_out'] as String);

          // Kirim clock-out menggunakan realShiftId asli dari server
          await _absensiRepository.endShift(
            shiftId: realShiftId,
            note: note,
            clockOut: clockOutTime,
          );

          // Hapus dari antrean end di HP
          await _offlineStorage.removeAttendanceEndQueue(localId);
        }
      } catch (e) {
        debugPrint("Gagal sinkronisasi clock-in $localId: $e");
      }
    }

    // b. Sinkronkan Clock Out sisa (yang start-nya online tapi end-nya offline)
    final remainingEndQueue = await _offlineStorage.getAttendanceEndQueue();
    for (var endData in remainingEndQueue) {
      final shiftId = endData['id'] as String;

      // Lewati jika ID-nya masih format local 'offline-' (masih diproses di langkah a)
      if (shiftId.startsWith('offline-')) continue;

      final note = endData['note'] as String?;
      final clockOutTime = DateTime.parse(endData['clock_out'] as String);

      try {
        await _absensiRepository.endShift(
          shiftId: shiftId,
          note: note,
          clockOut: clockOutTime,
        );
        await _offlineStorage.removeAttendanceEndQueue(shiftId);
      } catch (e) {
        debugPrint("Gagal sinkronisasi clock-out $shiftId: $e");
      }
    }

    // Notify listeners (e.g. AbsensiCubit) that sync has finished
    _syncCompletedController.add(null);
  }

  // 2. Sinkronisasi Pesanan / Orderan
  Future<void> _syncOrders() async {
    final orderQueue = await _offlineStorage.getOrderQueue();
    if (orderQueue.isEmpty) return;
    
    debugPrint("⏳ Mensinkronkan data orderan offline... (Ditemukan ${orderQueue.length} transaksi)");
    final orderRepo = serviceLocator<OrderRepository>();

    for (var orderData in orderQueue) {
      final localId = orderData['id'] as String;
      try {
        final orderMap = orderData['order'] as Map<String, dynamic>;
        final itemsList = orderData['items'] as List<dynamic>;

        final order = OrderModel.fromJson(orderMap);
        final items = itemsList
            .map((itemJson) => OrderItemModel.fromJson(itemJson as Map<String, dynamic>))
            .toList();

        await orderRepo.createOrder(order: order, items: items);
        await _offlineStorage.removeOrderQueue(localId);
        debugPrint("✅ Sinkronisasi transaksi offline $localId sukses.");
      } catch (e) {
        debugPrint("❌ Gagal sinkronisasi transaksi offline $localId: $e");
      }
    }
  }

  // 3. Sinkronisasi Bahan Baku / Stok (placeholder masa depan)
  Future<void> _syncStock() async {
    final stockQueue = await _offlineStorage.getStockQueue();
    if (stockQueue.isEmpty) return;
    debugPrint("⏳ Mensinkronkan data stok offline... (Staging)");
    // TODO: implementasi repository stok offline di masa depan
  }
}
