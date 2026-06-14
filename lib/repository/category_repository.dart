import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/model/category_model.dart';

class CategoryRepository {
  final _client = Supabase.instance.client;

  // Mengambil semua kategori dari database
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat kategori: $e');
    }
  }

  // Menambah kategori baru (jika dibutuhkan)
  Future<void> addCategory(String name) async {
    try {
      await _client.from('categories').insert({'name': name});
    } catch (e) {
      throw Exception('Gagal menambah kategori: $e');
    }
  }
}
