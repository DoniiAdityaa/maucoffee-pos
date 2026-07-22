import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/model/order_model.dart';
import 'package:maucoffee/model/order_item_model.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';

class OrderRepository {
  final _client = Supabase.instance.client;

  // 1. Mengambil riwayat transaksi (History) berdasarkan ID Admin
  Future<List<OrderModel>> getOrderHistory({String? adminId}) async {
    final targetAdminId = adminId ?? serviceLocator<UserPreference>().getActiveAdminId();
    if (targetAdminId == null || targetAdminId.isEmpty) {
      return [];
    }
    try {
      final response = await _client
          .from('orders')
          .select()
          .eq('admin_id', targetAdminId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat riwayat transaksi: $e');
    }
  }

  // 2. Mengambil detail item dari sebuah order
  Future<List<OrderItemModel>> getOrderItems(String orderId) async {
    try {
      final response = await _client
          .from('order_items')
          .select()
          .eq('order_id', orderId);

      return (response as List)
          .map((json) => OrderItemModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat detail item transaksi: $e');
    }
  }

  // 2b. Mengambil detail item dari beberapa order secara batch
  Future<List<OrderItemModel>> getOrderItemsForOrders(List<String> orderIds) async {
    if (orderIds.isEmpty) return [];
    try {
      final response = await _client
          .from('order_items')
          .select()
          .inFilter('order_id', orderIds);

      return (response as List)
          .map((json) => OrderItemModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat batch detail item transaksi: $e');
    }
  }

  // 3. Upload gambar bukti QRIS ke Supabase Storage
  Future<String> uploadQrisProof(File file, String fileName) async {
    try {
      final path = 'qris_proofs/$fileName';

      // Upload ke bucket 'qris-proofs'
      await _client.storage.from('qris-proofs').upload(path, file);

      // Ambil URL Publik gambar tersebut
      final publicUrl = _client.storage.from('qris-proofs').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Gagal mengupload bukti pembayaran QRIS: $e');
    }
  }

  // 4. Membuat Transaksi Baru (Simpan Order, Simpan Items, dan Potong Stok)
  Future<void> createOrder({
    required OrderModel order,
    required List<OrderItemModel> items,
  }) async {
    try {
      final orderJson = order.toJson();
      orderJson.remove('id');
      if (order.createdAt != null) {
        orderJson['created_at'] = order.createdAt!.toUtc().toIso8601String();
      } else {
        orderJson.remove('created_at');
      }
      // Set admin_id jika belum diset
      orderJson['admin_id'] ??= serviceLocator<UserPreference>().getActiveAdminId();

      final orderResponse = await _client
          .from('orders')
          .insert(orderJson)
          .select('id')
          .single();

      final newOrderId = orderResponse['id'] as String;

      // b. Insert item order & kurangi stok produk
      for (final item in items) {
        final itemJson = item.toJson();
        itemJson.remove('id');
        itemJson.remove('created_at');
        itemJson['order_id'] = newOrderId; // Pasang ID order yang baru dibuat

        // Simpan detail item pesanan
        await _client.from('order_items').insert(itemJson);

        // Potong stok barang di tabel products dinonaktifkan (stok unlimited)
      }
    } catch (e) {
      throw Exception('Gagal memproses transaksi: $e');
    }
  }

  // 5. Menghapus transaksi beserta semua item-nya
  Future<void> deleteOrder(String orderId) async {
    try {
      // Hapus order_items dulu (child records)
      await _client.from('order_items').delete().eq('order_id', orderId);
      // Lalu hapus order utama
      await _client.from('orders').delete().eq('id', orderId);
    } catch (e) {
      throw Exception('Gagal menghapus transaksi: $e');
    }
  }
}
