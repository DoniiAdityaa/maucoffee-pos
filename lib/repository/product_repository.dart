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

      await _client.from('products').update(json).eq('id', product.id!);
    } catch (e) {
      throw Exception('Gagal mengupdate produk: $e');
    }
  }
}
