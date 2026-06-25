import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/model/category_model.dart';

class CategoryRepository {
  final _client = Supabase.instance.client;

  // Mengambil kategori berdasarkan ID Admin
  Future<List<CategoryModel>> getCategories({String? adminId}) async {
    final targetAdminId = adminId ?? _client.auth.currentUser?.id;
    if (targetAdminId == null || targetAdminId.isEmpty) {
      return [];
    }
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('admin_id', targetAdminId)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat kategori: $e');
    }
  }

  // Menambah kategori baru
  Future<CategoryModel> addCategory(String name, {String? adminId}) async {
    try {
      final targetAdminId = adminId ?? _client.auth.currentUser?.id;
      final response = await _client.from('categories').insert({
        'name': name,
        'admin_id': targetAdminId,
      }).select().single();
      return CategoryModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal menambah kategori: $e');
    }
  }

  // Menghapus kategori berdasarkan ID
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _client.from('categories').delete().eq('id', categoryId);
    } catch (e) {
      throw Exception('Gagal menghapus kategori: $e');
    }
  }

  // Mengubah nama kategori
  Future<void> updateCategory(String categoryId, String newName) async {
    try {
      await _client
          .from('categories')
          .update({'name': newName})
          .eq('id', categoryId);
    } catch (e) {
      throw Exception('Gagal memperbarui kategori: $e');
    }
  }
}
