import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/model/ingredient_model.dart';

class IngredientRepository {
  final _client = Supabase.instance.client;

  // Mengambil daftar bahan baku berdasarkan ID Admin aktif
  Future<List<IngredientModel>> getIngredients({String? adminId}) async {
    final targetAdminId = adminId ?? _client.auth.currentUser?.id;
    if (targetAdminId == null || targetAdminId.isEmpty) {
      return [];
    }
    try {
      final response = await _client
          .from('ingredients')
          .select()
          .eq('admin_id', targetAdminId)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => IngredientModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat bahan baku: $e');
    }
  }

  // Menambahkan bahan baku baru
  Future<IngredientModel> addIngredient(IngredientModel item, {String? adminId}) async {
    try {
      final targetAdminId = adminId ?? _client.auth.currentUser?.id;
      final response = await _client.from('ingredients').insert({
        'name': item.name,
        'category': item.category,
        'stock': item.stock,
        'unit': item.unit,
        'min_stock': item.minStock,
        'admin_id': targetAdminId,
      }).select().single();
      return IngredientModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal menambah bahan baku: $e');
    }
  }

  // Mengubah bahan baku (termasuk update stok/restock)
  Future<void> updateIngredient(IngredientModel item) async {
    try {
      if (item.id == null) {
        throw Exception('ID bahan baku tidak boleh kosong untuk pembaruan.');
      }
      final targetAdminId = _client.auth.currentUser?.id;
      await _client.from('ingredients').update({
        'name': item.name,
        'category': item.category,
        'stock': item.stock,
        'unit': item.unit,
        'min_stock': item.minStock,
        'admin_id': targetAdminId,
      }).eq('id', item.id!);
    } catch (e) {
      throw Exception('Gagal memperbarui bahan baku: $e');
    }
  }

  // Menghapus bahan baku
  Future<void> deleteIngredient(String id) async {
    try {
      await _client.from('ingredients').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus bahan baku: $e');
    }
  }
}
