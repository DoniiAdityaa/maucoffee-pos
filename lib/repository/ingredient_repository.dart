import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maucoffee/model/ingredient_model.dart';
import 'package:maucoffee/model/stock_log_model.dart';
import 'package:maucoffee/config/service_locator.dart';
import 'package:maucoffee/config/user_preference.dart';

class IngredientRepository {
  final _client = Supabase.instance.client;

  // Mengambil daftar bahan baku berdasarkan ID Admin aktif
  Future<List<IngredientModel>> getIngredients({String? adminId}) async {
    final targetAdminId = adminId ?? serviceLocator<UserPreference>().getActiveAdminId();
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
      final targetAdminId = adminId ?? serviceLocator<UserPreference>().getActiveAdminId();
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
      final targetAdminId = serviceLocator<UserPreference>().getActiveAdminId();
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

  // Menambahkan log penyesuaian stok baru
  Future<void> addStockLog(StockLogModel log) async {
    try {
      final json = log.toJson();
      json.remove('id');
      json.remove('created_at');
      json['admin_id'] ??= serviceLocator<UserPreference>().getActiveAdminId();

      await _client.from('stock_logs').insert(json);
    } catch (e) {
      // Supaya tangguh jika tabel stock_logs belum di-create oleh user di dashboard
      debugPrint('Gagal mencatat log stok ke Supabase: $e');
    }
  }

  // Mengambil daftar log penyesuaian stok dari Supabase
  Future<List<StockLogModel>> getStockLogs({String? adminId}) async {
    final targetAdminId = adminId ?? serviceLocator<UserPreference>().getActiveAdminId();
    if (targetAdminId == null || targetAdminId.isEmpty) {
      return [];
    }
    try {
      final response = await _client
          .from('stock_logs')
          .select()
          .eq('admin_id', targetAdminId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => StockLogModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Gagal memuat log stok dari Supabase: $e');
      // Kembalikan empty list agar tidak crash
      return [];
    }
  }
}
