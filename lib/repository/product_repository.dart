import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/model/product_model.dart';

class ProductRepository {
  final _client = Supabase.instance.client;

  // Mengambil seluruh produk yang tersedia berdasarkan ID Admin
  Future<List<ProductModel>> getProducts({String? adminId}) async {
    final targetAdminId = adminId ?? _client.auth.currentUser?.id;
    if (targetAdminId == null || targetAdminId.isEmpty) {
      return [];
    }
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('admin_id', targetAdminId)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat produk: $e');
    }
  }

  // Menambah produk baru (Fitur Tambah Barang & Stok)
  Future<void> addProduct(ProductModel product) async {
    try {
      // Menghapus field ID agar Supabase yang generate UUID-nya otomatis
      final json = product.toJson();
      json.remove('id');
      json.remove('created_at');
      // Set admin_id jika belum diset
      json['admin_id'] ??= _client.auth.currentUser?.id;

      await _client.from('products').insert(json);
    } catch (e) {
      throw Exception('Gagal menambah produk: $e');
    }
  }

  // Mengupdate stok atau detail produk
  Future<void> updateProduct(ProductModel product) async {
    if (product.id == null) return;
    try {
      final json = product.toJson();
      json.remove('created_at');
      // Set admin_id jika belum diset agar tidak terupdate menjadi null
      json['admin_id'] ??= _client.auth.currentUser?.id;

      await _client.from('products').update(json).eq('id', product.id!);
    } catch (e) {
      throw Exception('Gagal mengupdate produk: $e');
    }
  }

  // Menghapus produk berdasarkan ID
  Future<void> deleteProduct(String productId) async {
    try {
      // 1. Hapus semua data transaksi di order_items yang mencatat produk ini
      await _client.from('order_items').delete().eq('product_id', productId);

      // 2. Baru hapus produk utama dari katalog
      await _client.from('products').delete().eq('id', productId);
    } catch (e) {
      throw Exception('Gagal menghapus produk: $e');
    }
  }

  // Mengunggah gambar produk ke Supabase Storage
  Future<String?> uploadProductImage(File imageFile, String fileName) async {
    try {
      final String uid = _client.auth.currentUser?.id ?? 'default';
      final String path = "$uid/$fileName";
      await _client.storage
          .from('product-images')
          .upload(path, imageFile, fileOptions: const FileOptions(upsert: true));

      final String publicUrl =
          _client.storage.from('product-images').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      throw Exception('Gagal mengunggah gambar: $e');
    }
  }
}
