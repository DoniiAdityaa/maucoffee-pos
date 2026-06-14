import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/model/order_model.dart';
import 'package:maucoffee/model/order_item_model.dart';

class OrderRepository {
  final _client = Supabase.instance.client;

  // 1. Mengambil riwayat transaksi (History)
  Future<List<OrderModel>> getOrderHistory() async {
    try {
      final response = await _client
          .from('orders')
          .select()
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
      // a. Insert data order utama
      final orderJson = order.toJson();
      orderJson.remove('id');
      orderJson.remove('created_at');

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

        // Potong stok barang di tabel products
        // Dapatkan data produk untuk cek stok saat ini
        final productResponse = await _client
            .from('products')
            .select('stock')
            .eq('id', item.productId)
            .single();

        final currentStock = productResponse['stock'] as int;
        final newStock = currentStock - item.quantity;

        // Update stok baru
        await _client
            .from('products')
            .update({'stock': newStock})
            .eq('id', item.productId);
      }
    } catch (e) {
      throw Exception('Gagal memproses transaksi: $e');
    }
  }
}
